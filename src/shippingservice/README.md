# Shipping Service

The Shipping service provides price quote, tracking IDs, and the impression of order fulfillment & shipping processes.

## Local

Run the following command to restore dependencies to `vendor/` directory:

    go mod vendor -v

## Build

From repository root, run:

```
docker build --file src/shippingservice/Dockerfile .
```

## Test

```
go test .
```
