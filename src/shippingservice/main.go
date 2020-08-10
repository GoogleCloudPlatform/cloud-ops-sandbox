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
	"fmt"
	"net"
	"os"
	"time"

	"cloud.google.com/go/profiler"
	"contrib.go.opencensus.io/exporter/stackdriver"
	"github.com/sirupsen/logrus"
	"go.opencensus.io/plugin/ocgrpc"
	"go.opencensus.io/stats/view"
	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
	
	// OpenTelemetry
	// OTel traces -> GCP Trace direct exporter
	texporter "github.com/GoogleCloudPlatform/opentelemetry-operations-go/exporter/trace"
	"go.opentelemetry.io/otel/api/global"
	"go.opentelemetry.io/otel/api/standard"
	"go.opentelemetry.io/otel/instrumentation/grpctrace"
	apitrace "go.opentelemetry.io/otel/api/trace"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	"go.opentelemetry.io/otel/sdk/resource"

	pb "github.com/GoogleCloudPlatform/microservices-demo/src/shippingservice/genproto"
	healthpb "google.golang.org/grpc/health/grpc_health_v1"
)

const (
	defaultPort = "50051"
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

func main() {
	go initOpenCensusStats()
	initTraceProvider()
	go initProfiling("shippingservice", "1.0.0")

	port := defaultPort
	if value, ok := os.LookupEnv("APP_PORT"); ok {
		port = value
	}
	port = fmt.Sprintf(":%s", port)

	lis, err := net.Listen("tcp", port)
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	// TOOD: replace ocgrpc with automatic OpenTelemetry grpc metrics collector
	srv := grpc.NewServer(grpc.StatsHandler(
		&ocgrpc.ServerHandler{}), // TODO: replace with automatic OTel grpc metrics collector when available
		grpc.UnaryInterceptor(grpctrace.UnaryServerInterceptor(global.TraceProvider().Tracer("shipping"))),
		grpc.StreamInterceptor(grpctrace.StreamServerInterceptor(global.TraceProvider().Tracer("shipping"))),
	)
	svc := &server{}
	pb.RegisterShippingServiceServer(srv, svc)
	healthpb.RegisterHealthServer(srv, svc)
	log.Infof("Shipping Service listening on port %s", port)

	// Register reflection service on gRPC server.
	reflection.Register(srv)
	if err := srv.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}

// server controls RPC service responses.
type server struct{}

// Check is for health checking.
func (s *server) Check(ctx context.Context, req *healthpb.HealthCheckRequest) (*healthpb.HealthCheckResponse, error) {
	return &healthpb.HealthCheckResponse{Status: healthpb.HealthCheckResponse_SERVING}, nil
}

// GetQuote produces a shipping quote (cost) in USD.
func (s *server) GetQuote(ctx context.Context, in *pb.GetQuoteRequest) (*pb.GetQuoteResponse, error) {
	span := apitrace.SpanFromContext(ctx)
	span.AddEvent(ctx, "Get Shipping Quote")
	log.Info("[GetQuote] received request")
	defer log.Info("[GetQuote] completed request")

	// 1. Our quote system requires the total number of items to be shipped.
	count := 0
	for _, item := range in.Items {
		count += int(item.Quantity)
	}

	// 2. Generate a quote based on the total number of items to be shipped.
	quote := CreateQuoteFromCount(count)

	// 3. Generate a response.
	return &pb.GetQuoteResponse{
		CostUsd: &pb.Money{
			CurrencyCode: "USD",
			Units:        int64(quote.Dollars),
			Nanos:        int32(quote.Cents * 10000000)},
	}, nil

}

// ShipOrder mocks that the requested items will be shipped.
// It supplies a tracking ID for notional lookup of shipment delivery status.
func (s *server) ShipOrder(ctx context.Context, in *pb.ShipOrderRequest) (*pb.ShipOrderResponse, error) {
	span := apitrace.SpanFromContext(ctx)
	span.AddEvent(ctx, "Ship Order")
	log.Info("[ShipOrder] received request")
	defer log.Info("[ShipOrder] completed request")
	// 1. Create a Tracking ID
	baseAddress := fmt.Sprintf("%s, %s, %s", in.Address.StreetAddress, in.Address.City, in.Address.State)
	id := CreateTrackingId(baseAddress)

	// 2. Generate a response.
	return &pb.ShipOrderResponse{
		TrackingId: id,
	}, nil
}

// Initialize Stats using OpenCensus
// TODO: remove this after conversion to OpenTelemetry Metrics
func initOpenCensusStats() {
	for i := 1; i <= 3; i++ {
		exporter, err := stackdriver.NewExporter(stackdriver.Options{})
		if err != nil {
			log.Warnf("failed to initialize stackdriver exporter: %+v", err)
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
			// The AlwaysSample sampling policy is used here for demonstration
			// purposes and should not be used in production environments.
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
