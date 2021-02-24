module github.com/GoogleCloudPlatform/cloud-ops-sandbox/src/productcatalogservice

go 1.16

require (
	cloud.google.com/go v0.78.0
	contrib.go.opencensus.io/exporter/stackdriver v0.13.5
	github.com/GoogleCloudPlatform/microservices-demo/src/productcatalogservice v0.0.0-20210219170230-3a1850d65f8c
	github.com/GoogleCloudPlatform/opentelemetry-operations-go/exporter/trace v0.16.0
	github.com/golang/protobuf v1.4.3
	github.com/google/go-cmp v0.5.4
	github.com/sirupsen/logrus v1.8.0
	go.opencensus.io v0.22.6
	go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc v0.17.0
	go.opentelemetry.io/otel v0.17.0
	go.opentelemetry.io/otel/sdk v0.17.0
	go.opentelemetry.io/otel/trace v0.17.0
	golang.org/x/net v0.0.0-20210222171744-9060382bd457 // indirect
	google.golang.org/grpc v1.35.0
	google.golang.org/protobuf v1.25.0
)
