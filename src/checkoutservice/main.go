// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"context"
	"fmt"
	"net"
	"os"
	"time"

	"cloud.google.com/go/profiler"
	"contrib.go.opencensus.io/exporter/stackdriver"
	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
	"go.opencensus.io/plugin/ocgrpc"
	"go.opencensus.io/stats/view"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	pb "github.com/GoogleCloudPlatform/microservices-demo/src/checkoutservice/genproto"
	money "github.com/GoogleCloudPlatform/microservices-demo/src/checkoutservice/money"
	healthpb "google.golang.org/grpc/health/grpc_health_v1"

	// OpenTelemetry
	// OTel traces -> GCP Trace direct exporter
	texporter "github.com/GoogleCloudPlatform/opentelemetry-operations-go/exporter/trace"
	"go.opentelemetry.io/otel/api/global"
	"go.opentelemetry.io/otel/api/standard"
	"go.opentelemetry.io/otel/instrumentation/grpctrace"
	apitrace "go.opentelemetry.io/otel/api/trace"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	"go.opentelemetry.io/otel/sdk/resource"
)

const (
	listenPort  = "5050"
	usdCurrency = "USD"
)

var log *logrus.Logger

func init() {
	log = logrus.New()
	log.Level = logrus.DebugLevel
	log.Formatter = &logrus.JSONFormatter{
		FieldMap: logrus.FieldMap{
			logrus.FieldKeyTime:  "timestamp",
			logrus.FieldKeyLevel: "severity",
			logrus.FieldKeyMsg:   "message",
		},
		TimestampFormat: time.RFC3339Nano,
	}
	log.Out = os.Stdout
}

type checkoutService struct {
	productCatalogSvcAddr string
	productCatalogSvcConn *grpc.ClientConn

	cartSvcAddr           string
	cartSvcConn *grpc.ClientConn

	currencySvcAddr       string
	currencySvcConn *grpc.ClientConn

	shippingSvcAddr       string
	shippingSvcConn *grpc.ClientConn

	emailSvcAddr          string
	emailSvcConn *grpc.ClientConn

	paymentSvcAddr        string
	paymentSvcConn *grpc.ClientConn
}

func main() {
	ctx := context.Background()
	go initOpenCensusStats()
	initTraceProvider()
	go initProfiling("checkoutservice", "1.0.0")

	port := listenPort
	if os.Getenv("PORT") != "" {
		port = os.Getenv("PORT")
	}

	svc := new(checkoutService)
	mustMapEnv(&svc.shippingSvcAddr, "SHIPPING_SERVICE_ADDR")
	mustMapEnv(&svc.productCatalogSvcAddr, "PRODUCT_CATALOG_SERVICE_ADDR")
	mustMapEnv(&svc.cartSvcAddr, "CART_SERVICE_ADDR")
	mustMapEnv(&svc.currencySvcAddr, "CURRENCY_SERVICE_ADDR")
	mustMapEnv(&svc.emailSvcAddr, "EMAIL_SERVICE_ADDR")
	mustMapEnv(&svc.paymentSvcAddr, "PAYMENT_SERVICE_ADDR")

	mustConnGRPC(ctx, &svc.shippingSvcConn, svc.shippingSvcAddr)
	mustConnGRPC(ctx, &svc.productCatalogSvcConn, svc.productCatalogSvcAddr)
	mustConnGRPC(ctx, &svc.cartSvcConn, svc.cartSvcAddr)
	mustConnGRPC(ctx, &svc.currencySvcConn, svc.currencySvcAddr)
	mustConnGRPC(ctx, &svc.emailSvcConn, svc.emailSvcAddr)
	mustConnGRPC(ctx, &svc.paymentSvcConn, svc.paymentSvcAddr)

	log.Infof("service config: %+v", svc)

	lis, err := net.Listen("tcp", fmt.Sprintf(":%s", port))
	if err != nil {
		log.Fatal(err)
	}
	srv := grpc.NewServer(
		grpc.StatsHandler(&ocgrpc.ServerHandler{}), // TODO: replace with OTel grpc metrics collector
		// OpenTelemetry gRPC server channel interceptors receive trace contexts from clients.
		grpc.UnaryInterceptor(grpctrace.UnaryServerInterceptor(global.TraceProvider().Tracer("checkout"))),
		grpc.StreamInterceptor(grpctrace.StreamServerInterceptor(global.TraceProvider().Tracer("checkout"))),
	)
	pb.RegisterCheckoutServiceServer(srv, svc)
	healthpb.RegisterHealthServer(srv, svc)
	log.Infof("starting to listen on tcp: %q", lis.Addr().String())
	err = srv.Serve(lis)
	log.Fatal(err)
}

// Initialize Stats collection using OpenCensus
// TOOD: remove this after conversion to OpenTelemetry Metrics
func initOpenCensusStats() {
	for i := 1; i <= 3; i++ {
		exporter, err := stackdriver.NewExporter(stackdriver.Options{})
		if err != nil {
			log.Infof("failed to initialize stackdriver exporter: %+v", err)
		} else {
			// Register the views to collect server stats.
			view.SetReportingPeriod(60 * time.Second)
			view.RegisterExporter(exporter)
			if err := view.Register(ocgrpc.DefaultServerViews...); err != nil {
				log.Warn("Error registering default server views")
			} else {
				log.Info("Registered default server views")
			}
			return
		}
		d := time.Second * 10 * time.Duration(i)
		log.Infof("sleeping %v to retry initializing stackdriver exporter", d)
		time.Sleep(d)
	}
	log.Warn("could not initialize stackdriver exporter after retrying, giving up")
}

// Initialize OTel trace provider that exports to Cloud Trace
func initTraceProvider() {
	// When running on GCP, authentication is handled automatically
	// using default credentials. This environment variable check
	// is to help debug projects running locally. It's possible for this
	// warning to be printed while the exporter works normally. See
	// https://developers.google.com/identity/protocols/application-default-credentials
	// for more details.
	projectID := os.Getenv("GOOGLE_CLOUD_PROJECT")
	if len(projectID) == 0 {
		log.Warn("GOOGLE_CLOUD_PROJECT not set")
	}
	for i := 1; i <= 3; i++ {
		exporter, err := texporter.NewExporter(texporter.WithProjectID(projectID))
		if err != nil {
			log.Infof("failed to initialize exporter: %v", err)
		} else {
			// Create trace provider with the exporter.
			// This is a demo app with low QPS. AlwaysSample() is used here
			// to make sure traces are available for observation and analysis.
			// It should not be used in production environments.
			tp, err := sdktrace.NewProvider(sdktrace.WithConfig(
				sdktrace.Config{DefaultSampler: sdktrace.AlwaysSample()}),
				sdktrace.WithSyncer(exporter),
				// TODO: replace with predefined constant for GKE or autodetection when available
				sdktrace.WithResource(resource.New(standard.ServiceNameKey.String("GKE"))))
			if err == nil {
				log.Info("initialized trace provider")
				global.SetTraceProvider(tp)
				return
			} else {
				d := time.Second * 10 * time.Duration(i)
				log.Infof("sleeping %v to retry initializing trace provider", d)
				time.Sleep(d)
			}
		}
	}
	log.Warn("failed to initialize trace provider")
}

func initProfiling(service, version string) {
	// TODO(ahmetb) this method is duplicated in other microservices using Go
	// since they are not sharing packages.
	for i := 1; i <= 3; i++ {
		if err := profiler.Start(profiler.Config{
			Service:        service,
			ServiceVersion: version,
			// ProjectID must be set if not running on GCP.
			// ProjectID: "my-project",
		}); err != nil {
			log.Warnf("failed to start profiler: %+v", err)
		} else {
			log.Info("started stackdriver profiler")
			return
		}
		d := time.Second * 10 * time.Duration(i)
		log.Infof("sleeping %v to retry initializing stackdriver profiler", d)
		time.Sleep(d)
	}
	log.Warn("could not initialize stackdriver profiler after retrying, giving up")
}

func mustMapEnv(target *string, envKey string) {
	v := os.Getenv(envKey)
	if v == "" {
		panic(fmt.Sprintf("environment variable %q not set", envKey))
	}
	*target = v
}

func (cs *checkoutService) Check(ctx context.Context, req *healthpb.HealthCheckRequest) (*healthpb.HealthCheckResponse, error) {
	return &healthpb.HealthCheckResponse{Status: healthpb.HealthCheckResponse_SERVING}, nil
}

// Acting as gRPC server, handling PlaceOrder request from Frontend.
func (cs *checkoutService) PlaceOrder(ctx context.Context, req *pb.PlaceOrderRequest) (*pb.PlaceOrderResponse, error) {
	span := apitrace.SpanFromContext(ctx)
	span.AddEvent(ctx, fmt.Sprintf("Place Order for user %q", req.UserId))
	log.Infof("[PlaceOrder] user_id=%q user_currency=%q", req.UserId, req.UserCurrency)

	orderID, err := uuid.NewUUID()
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to generate order uuid")
	}

	// Dispatch subtasks (as gRPC client)
	span.AddEvent(ctx, "Prepare Items from Cart")
	prep, err := cs.prepareOrderItemsAndShippingQuoteFromCart(ctx, req.UserId, req.UserCurrency, req.Address)
	if err != nil {
		return nil, status.Errorf(codes.Internal, err.Error())
	}

	total := pb.Money{CurrencyCode: req.UserCurrency,
		Units: 0,
		Nanos: 0}
	total = money.Must(money.Sum(total, *prep.shippingCostLocalized))
	for _, it := range prep.orderItems {
		total = money.Must(money.Sum(total, *it.Cost))
	}

	span.AddEvent(ctx, "Charge Credit Card")
	txID, err := cs.chargeCard(ctx, &total, req.CreditCard)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to charge card: %+v", err)
	}
	log.Infof("payment went through (transaction_id: %s)", txID)

	span.AddEvent(ctx, "Prepare Shipment")
	shippingTrackingID, err := cs.shipOrder(ctx, req.Address, prep.cartItems)
	if err != nil {
		return nil, status.Errorf(codes.Unavailable, "shipping error: %+v", err)
	}

	span.AddEvent(ctx, "Empty Cart")
	_ = cs.emptyUserCart(ctx, req.UserId)

	orderResult := &pb.OrderResult{
		OrderId:            orderID.String(),
		ShippingTrackingId: shippingTrackingID,
		ShippingCost:       prep.shippingCostLocalized,
		ShippingAddress:    req.Address,
		Items:              prep.orderItems,
	}

	span.AddEvent(ctx, "Send Confirmation Email")
	if err := cs.sendOrderConfirmation(ctx, req.Email, orderResult); err != nil {
		log.Warnf("failed to send order confirmation to %q: %+v", req.Email, err)
	} else {
		log.Infof("order confirmation email sent to %q", req.Email)
	}
	resp := &pb.PlaceOrderResponse{Order: orderResult}
	return resp, nil
}

type orderPrep struct {
	orderItems            []*pb.OrderItem
	cartItems             []*pb.CartItem
	shippingCostLocalized *pb.Money
}

func (cs *checkoutService) prepareOrderItemsAndShippingQuoteFromCart(ctx context.Context, userID, userCurrency string, address *pb.Address) (orderPrep, error) {
	var out orderPrep
	cartItems, err := cs.getUserCart(ctx, userID)
	if err != nil {
		return out, fmt.Errorf("cart failure: %+v", err)
	}
	orderItems, err := cs.prepOrderItems(ctx, cartItems, userCurrency)
	if err != nil {
		return out, fmt.Errorf("failed to prepare order: %+v", err)
	}
	shippingUSD, err := cs.quoteShipping(ctx, address, cartItems)
	if err != nil {
		return out, fmt.Errorf("shipping quote failure: %+v", err)
	}
	shippingPrice, err := cs.convertCurrency(ctx, shippingUSD, userCurrency)
	if err != nil {
		return out, fmt.Errorf("failed to convert shipping cost to currency: %+v", err)
	}

	out.shippingCostLocalized = shippingPrice
	out.cartItems = cartItems
	out.orderItems = orderItems
	return out, nil
}

// Acting as gRPC client
func (cs *checkoutService) quoteShipping(ctx context.Context, address *pb.Address, items []*pb.CartItem) (*pb.Money, error) {
	shippingQuote, err := pb.NewShippingServiceClient(cs.shippingSvcConn).
		GetQuote(ctx, &pb.GetQuoteRequest{
			Address: address,
			Items:   items})
	if err != nil {
		return nil, fmt.Errorf("failed to get shipping quote: %+v", err)
	}
	return shippingQuote.GetCostUsd(), nil
}

// Acting as gPRC client
func (cs *checkoutService) getUserCart(ctx context.Context, userID string) ([]*pb.CartItem, error) {
	cart, err := pb.NewCartServiceClient(cs.cartSvcConn).GetCart(ctx, &pb.GetCartRequest{UserId: userID})
	if err != nil {
		return nil, fmt.Errorf("failed to get user cart during checkout: %+v", err)
	}
	return cart.GetItems(), nil
}

// Acting as gPRC client
func (cs *checkoutService) emptyUserCart(ctx context.Context, userID string) error {
	if _, err := pb.NewCartServiceClient(cs.cartSvcConn).EmptyCart(ctx, &pb.EmptyCartRequest{UserId: userID}); err != nil {
		return fmt.Errorf("failed to empty user cart during checkout: %+v", err)
	}
	return nil
}

// Acting as gPRC client
func (cs *checkoutService) prepOrderItems(ctx context.Context, items []*pb.CartItem, userCurrency string) ([]*pb.OrderItem, error) {
	out := make([]*pb.OrderItem, len(items))

	cl := pb.NewProductCatalogServiceClient(cs.productCatalogSvcConn)

	for i, item := range items {
		product, err := cl.GetProduct(ctx, &pb.GetProductRequest{Id: item.GetProductId()})
		if err != nil {
			return nil, fmt.Errorf("failed to get product #%q", item.GetProductId())
		}
		price, err := cs.convertCurrency(ctx, product.GetPriceUsd(), userCurrency)
		if err != nil {
			return nil, fmt.Errorf("failed to convert price of %q to %s", item.GetProductId(), userCurrency)
		}
		out[i] = &pb.OrderItem{
			Item: item,
			Cost: price}
	}
	return out, nil
}

// Acting as gPRC client
func (cs *checkoutService) convertCurrency(ctx context.Context, from *pb.Money, toCurrency string) (*pb.Money, error) {
	result, err := pb.NewCurrencyServiceClient(cs.currencySvcConn).Convert(ctx, &pb.CurrencyConversionRequest{
		From:   from,
		ToCode: toCurrency})
	if err != nil {
		return nil, fmt.Errorf("failed to convert currency: %+v", err)
	}
	return result, err
}

// Acting as gPRC client
func (cs *checkoutService) chargeCard(ctx context.Context, amount *pb.Money, paymentInfo *pb.CreditCardInfo) (string, error) {
	paymentResp, err := pb.NewPaymentServiceClient(cs.paymentSvcConn).Charge(ctx, &pb.ChargeRequest{
		Amount:     amount,
		CreditCard: paymentInfo})
	if err != nil {
		return "", fmt.Errorf("could not charge the card: %+v", err)
	}
	return paymentResp.GetTransactionId(), nil
}

func (cs *checkoutService) sendOrderConfirmation(ctx context.Context, email string, order *pb.OrderResult) error {
	_, err := pb.NewEmailServiceClient(cs.emailSvcConn).SendOrderConfirmation(ctx, &pb.SendOrderConfirmationRequest{
		Email: email,
		Order: order})
	return err
}

// Acting as gPRC client
func (cs *checkoutService) shipOrder(ctx context.Context, address *pb.Address, items []*pb.CartItem) (string, error) {
	resp, err := pb.NewShippingServiceClient(cs.shippingSvcConn).ShipOrder(ctx, &pb.ShipOrderRequest{
		Address: address,
		Items:   items})
	if err != nil {
		return "", fmt.Errorf("shipment failed: %+v", err)
	}
	return resp.GetTrackingId(), nil
}

// Helper function for gRPC connections: Dial and create client once, reuse.
func mustConnGRPC(ctx context.Context, conn **grpc.ClientConn, addr string) {
	var err error
	*conn, err = grpc.DialContext(ctx, addr,
		grpc.WithInsecure(),
		grpc.WithTimeout(time.Second*3),
		grpc.WithStatsHandler(&ocgrpc.ClientHandler{}), // TODO: replace with OTel grpc metrics collector
		// OpenTelemetry gRPC client channel interceptors pass trace contexts to the server.
		grpc.WithUnaryInterceptor(grpctrace.UnaryClientInterceptor(global.TraceProvider().Tracer("checkout"))),
		grpc.WithStreamInterceptor(grpctrace.StreamClientInterceptor(global.TraceProvider().Tracer("checkout"))))
	if err != nil {
		panic(fmt.Sprintf("Error %s grpc: failed to connect %s", err, addr))
	}
}