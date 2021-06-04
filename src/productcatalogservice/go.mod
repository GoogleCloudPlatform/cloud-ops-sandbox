module github.com/GoogleCloudPlatform/cloud-ops-sandbox/src/productcatalogservice

go 1.16

require (
	cloud.google.com/go v0.61.0
	contrib.go.opencensus.io/exporter/stackdriver v0.13.0
	github.com/GoogleCloudPlatform/opentelemetry-operations-go/exporter/trace v0.20.0
	github.com/aws/aws-sdk-go v1.29.25 // indirect
	github.com/golang/protobuf v1.5.2
	github.com/google/go-cmp v0.5.5
	github.com/konsorten/go-windows-terminal-sequences v1.0.2 // indirect
	github.com/sirupsen/logrus v1.4.2
	go.opencensus.io v0.22.4
	go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc v0.20.0
	go.opentelemetry.io/otel v0.20.0
	go.opentelemetry.io/otel/sdk v0.20.0
	go.opentelemetry.io/otel/trace v0.20.0
	golang.org/x/net v0.0.0-20200707034311-ab3426394381
	golang.org/x/sys v0.0.0-20200615200032-f1bc736245b1 // indirect
	google.golang.org/grpc v1.38.0
	google.golang.org/grpc/cmd/protoc-gen-go-grpc v1.1.0
	google.golang.org/protobuf v1.26.0
)
