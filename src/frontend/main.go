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
	"net/http"
	"os"
	"time"

	"cloud.google.com/go/profiler"
	"contrib.go.opencensus.io/exporter/stackdriver"
	"github.com/gorilla/mux"
	"github.com/pkg/errors"
	"github.com/sirupsen/logrus"
	"go.opencensus.io/plugin/ocgrpc"
	"go.opencensus.io/plugin/ochttp"
	"go.opencensus.io/plugin/ochttp/propagation/b3"
	"go.opencensus.io/stats/view"
	"go.opencensus.io/trace"

	// OTel Metric
	"go.opentelemetry.io/otel/api/metric"
	metricstdout "go.opentelemetry.io/otel/exporters/metric/stdout"
	"go.opentelemetry.io/otel/instrumentation/othttp"
	"go.opentelemetry.io/otel/sdk/metric/controller/push"

	// OTel Trace
	// OTel -> GCP Trace direct exporter for go
	texporter "github.com/GoogleCloudPlatform/opentelemetry-operations-go/exporter/trace"
	"go.opentelemetry.io/otel/api/global"
	"go.opentelemetry.io/otel/api/standard"
	"go.opentelemetry.io/otel/instrumentation/grpctrace"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"

	"google.golang.org/grpc"
)

const (
	port            = "8080"
	defaultCurrency = "USD"
	cookieMaxAge    = 60 * 60 * 48

	cookiePrefix    = "shop_"
	cookieSessionID = cookiePrefix + "session-id"
	cookieCurrency  = cookiePrefix + "currency"
)

var (
	whitelistedCurrencies = map[string]bool{
		"USD": true,
		"EUR": true,
		"CAD": true,
		"JPY": true,
		"GBP": true,
		"TRY": true}
	// Custom Metrics for User Dashboard
	// TODO: use automatic metrics collection when Views API available in OpenTelemetry
	// TODO: remove these after automatically collected
	http_request_count   metric.Int64Counter
	http_response_errors metric.Int64Counter
	http_request_latency metric.Int64ValueRecorder
)

type ctxKeySessionID struct{}

type frontendServer struct {
	productCatalogSvcAddr string
	productCatalogSvcConn *grpc.ClientConn

	currencySvcAddr string
	currencySvcConn *grpc.ClientConn

	cartSvcAddr string
	cartSvcConn *grpc.ClientConn

	recommendationSvcAddr string
	recommendationSvcConn *grpc.ClientConn

	checkoutSvcAddr string
	checkoutSvcConn *grpc.ClientConn

	shippingSvcAddr string
	shippingSvcConn *grpc.ClientConn

	adSvcAddr string
	adSvcConn *grpc.ClientConn

	ratingSvcAddr string
}

func main() {
	ctx := context.Background()
	log := logrus.New()
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

	controller := initMetricsExporter(log)
	defer controller.Stop()

	go initProfiling(log, "frontend", "1.0.0")
	go initTelemetry(log)

	// TODO: register views when OpenTelemetry Views API is available
	meter := controller.Provider().Meter("hipstershop/frontend")
	// TODO: use automatic default metrics collection and remove custom metrics
	http_request_count = metric.Must(meter).NewInt64Counter("http_request_count")
	http_response_errors = metric.Must(meter).NewInt64Counter("http_response_errors")
	http_request_latency = metric.Must(meter).NewInt64ValueRecorder("http_request_latency")
	tracer := global.TraceProvider().Tracer("hipstershop/frontend")
	ctx, span := tracer.Start(ctx, "root")
	defer span.End()

	srvPort := port
	if os.Getenv("PORT") != "" {
		srvPort = os.Getenv("PORT")
	}
	addr := os.Getenv("LISTEN_ADDR")
	svc := new(frontendServer)
	mustMapEnv(&svc.productCatalogSvcAddr, "PRODUCT_CATALOG_SERVICE_ADDR")
	mustMapEnv(&svc.currencySvcAddr, "CURRENCY_SERVICE_ADDR")
	mustMapEnv(&svc.cartSvcAddr, "CART_SERVICE_ADDR")
	mustMapEnv(&svc.recommendationSvcAddr, "RECOMMENDATION_SERVICE_ADDR")
	mustMapEnv(&svc.checkoutSvcAddr, "CHECKOUT_SERVICE_ADDR")
	mustMapEnv(&svc.shippingSvcAddr, "SHIPPING_SERVICE_ADDR")
	mustMapEnv(&svc.adSvcAddr, "AD_SERVICE_ADDR")
	mustMapEnv(&svc.ratingSvcAddr, "RATING_SERVICE_ADDR")

	mustConnGRPC(ctx, &svc.currencySvcConn, svc.currencySvcAddr)
	mustConnGRPC(ctx, &svc.productCatalogSvcConn, svc.productCatalogSvcAddr)
	mustConnGRPC(ctx, &svc.cartSvcConn, svc.cartSvcAddr)
	mustConnGRPC(ctx, &svc.recommendationSvcConn, svc.recommendationSvcAddr)
	mustConnGRPC(ctx, &svc.shippingSvcConn, svc.shippingSvcAddr)
	mustConnGRPC(ctx, &svc.checkoutSvcConn, svc.checkoutSvcAddr)
	mustConnGRPC(ctx, &svc.adSvcConn, svc.adSvcAddr)

	r := mux.NewRouter()
	r.HandleFunc("/", svc.homeHandler).Methods(http.MethodGet, http.MethodHead)
	r.HandleFunc("/product/{id}", svc.productHandler).Methods(http.MethodGet, http.MethodHead)
	r.HandleFunc("/cart", svc.viewCartHandler).Methods(http.MethodGet, http.MethodHead)
	r.HandleFunc("/cart", svc.addToCartHandler).Methods(http.MethodPost)
	r.HandleFunc("/cart/empty", svc.emptyCartHandler).Methods(http.MethodPost)
	r.HandleFunc("/setCurrency", svc.setCurrencyHandler).Methods(http.MethodPost)
	r.HandleFunc("/logout", svc.logoutHandler).Methods(http.MethodGet)
	r.HandleFunc("/cart/checkout", svc.placeOrderHandler).Methods(http.MethodPost)
	r.HandleFunc("/product/{id}/rating", svc.submitRatingHandler).Methods(http.MethodPost)
	r.PathPrefix("/static/").Handler(http.StripPrefix("/static/", http.FileServer(http.Dir("./static/"))))
	r.HandleFunc("/robots.txt", func(w http.ResponseWriter, _ *http.Request) { fmt.Fprint(w, "User-agent: *\nDisallow: /") })
	r.HandleFunc("/_healthz", func(w http.ResponseWriter, _ *http.Request) { fmt.Fprint(w, "ok") })

	var handler http.Handler = othttp.NewHandler(r, "frontend", // OpenTelemetry HTTP wrapper
		othttp.WithMessageEvents(othttp.ReadEvents, othttp.WriteEvents)) // Uses global meter and tracer
	handler = &logHandler{log: log, next: handler} // add logging
	handler = ensureSessionID(handler)             // add session ID
	handler = &ochttp.Handler{                     // add opencensus instrumentation
		Handler:     handler,
		Propagation: &b3.HTTPFormat{}}

	log.Infof("starting server on " + addr + ":" + srvPort)
	log.Fatal(http.ListenAndServe(addr+":"+srvPort, handler))
}

// Initialize OpenTelemetry Metrics exporter
func initMetricsExporter(log logrus.FieldLogger) *push.Controller {
	// TODO: export to Cloud Monitoring instead of stdout
	pusher, err := metricstdout.InstallNewPipeline(metricstdout.Config{
		PrettyPrint: false,
	})
	if err != nil {
		log.Panicf("failed to initialize metric stdout exporter %v", err)
	}
	return pusher
}

// TODO: remove this after full conversion to OpenTelemetry
func initOpenCensus(log logrus.FieldLogger) {
	// TODO(ahmetb) this method is duplicated in other microservices using Go
	// since they are not sharing packages.
	for i := 1; i <= 3; i++ {
		log = log.WithField("retry", i)
		exporter, err := stackdriver.NewExporter(stackdriver.Options{})
		if err != nil {
			log.Warnf("failed to initialize stackdriver exporter: %+v", err)
		} else {
			// Register the views to collect server stats.
			view.SetReportingPeriod(60 * time.Second)
			view.RegisterExporter(exporter)
			if err := view.Register(ochttp.DefaultServerViews...); err != nil {
				log.Warn("Error registering http default server views")
			} else {
				log.Info("Registered http default server views")
			}
			if err := view.Register(ocgrpc.DefaultClientViews...); err != nil {
				log.Warn("Error registering grpc default client views")
			} else {
				log.Info("Registered grpc default client views")
			}
			return
		}
		d := time.Second * 20 * time.Duration(i)
		log.Debugf("sleeping %v to retry initializing stackdriver exporter", d)
		time.Sleep(d)
	}
	log.Warn("could not initialize stackdriver exporter after retrying, giving up")
}

// Initialize Telemetry collection (Tracing, Metrics/Stats) with OpenCensus and OpenTelemetry
func initTelemetry(log logrus.FieldLogger) {
	// This is a demo app with low QPS. trace.AlwaysSample() is used here
	// to make sure traces are available for observation and analysis.
	// In a production environment or high QPS setup please use
	// trace.ProbabilitySampler set at the desired probability.
	// TODO: Remove OpenCensus after full conversion to OpenTelemetry
	trace.ApplyConfig(trace.Config{DefaultSampler: trace.AlwaysSample()})
	initOpenCensus(log)

	// When running on GCP, authentication is handled automatically
	// using default credentials. This environment variable check
	// is to help debug projects running locally. It's possible for this
	// warning to be printed while the exporter works normally. See
	// https://developers.google.com/identity/protocols/application-default-credentials
	// for more details.
	// Initialize exporter OTel Trace -> Google Cloud Trace
	projectID := os.Getenv("GOOGLE_CLOUD_PROJECT")
	if len(projectID) == 0 {
		log.Warn("GOOGLE_CLOUD_PROJECT not set")
	}
	// Initialize exporter OTel Trace -> GCP Trace
	exporter, err := texporter.NewExporter(texporter.WithProjectID(projectID))
	if err != nil {
		log.Fatalf("failed to initialize exporter: %v", err)
	}

	// Create trace provider with the exporter.
	tp, err := sdktrace.NewProvider(sdktrace.WithConfig(
		// This is a demo app with low QPS. AlwaysSample() is used here
		// to make sure traces are available for observation and analysis.
		// It should not be used in production environments.
		sdktrace.Config{DefaultSampler: sdktrace.AlwaysSample()}),
		sdktrace.WithSyncer(exporter),
		// TODO: replace with predefined constant for GKE or autodetection when available
		sdktrace.WithResource(resource.New(standard.ServiceNameKey.String("GKE"))))
	if err != nil {
		log.Fatal("failed to initialize trace provider: %v", err)
	}
	global.SetTraceProvider(tp)
}

func initProfiling(log logrus.FieldLogger, service, version string) {
	// TODO(ahmetb) this method is duplicated in other microservices using Go
	// since they are not sharing packages.
	for i := 1; i <= 3; i++ {
		log = log.WithField("retry", i)
		if err := profiler.Start(profiler.Config{
			Service:        service,
			ServiceVersion: version,
			// ProjectID must be set if not running on GCP.
			// ProjectID: "my-project",
		}); err != nil {
			log.Warnf("warn: failed to start profiler: %+v", err)
		} else {
			log.Info("started stackdriver profiler")
			return
		}
		d := time.Second * 10 * time.Duration(i)
		log.Debugf("sleeping %v to retry initializing stackdriver profiler", d)
		time.Sleep(d)
	}
	log.Warn("warning: could not initialize stackdriver profiler after retrying, giving up")
}

func mustMapEnv(target *string, envKey string) {
	v := os.Getenv(envKey)
	if v == "" {
		panic(fmt.Sprintf("environment variable %q not set", envKey))
	}
	*target = v
}

func mustConnGRPC(ctx context.Context, conn **grpc.ClientConn, addr string) {
	var err error
	*conn, err = grpc.DialContext(ctx, addr,
		grpc.WithInsecure(),
		grpc.WithTimeout(time.Second*3),
		grpc.WithStatsHandler(&ocgrpc.ClientHandler{}), // TODO: replace with OT equivalent when available.
		// OpenTelemetry gRPC client channel interceptors pass trace contexts to the server.
		grpc.WithUnaryInterceptor(grpctrace.UnaryClientInterceptor(global.TraceProvider().Tracer("frontend"))),
		grpc.WithStreamInterceptor(grpctrace.StreamClientInterceptor(global.TraceProvider().Tracer("frontend"))))
	if err != nil {
		panic(errors.Wrapf(err, "grpc: failed to connect %s", addr))
	}
}
