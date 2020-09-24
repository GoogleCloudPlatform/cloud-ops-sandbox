// Copyright 2020 Google LLC
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

// Initialize OpenTelemetry tracing for the payment service.
// This tracer is needed in both server.js and index.js
const opentelemetry = require('@opentelemetry/api');
const {NodeTracerProvider} = require('@opentelemetry/node');
const {BatchSpanProcessor} = require('@opentelemetry/tracing');

// Enable OpenTelemetry exporters to export traces to Google Cloud Trace.
// Exporters use Application Default Credentials (ADCs) to authenticate.
// See https://developers.google.com/identity/protocols/application-default-credentials
// for more details. When your application is running on GCP,
// you don't need to provide auth credentials or a project id.
const {TraceExporter} = require('@google-cloud/opentelemetry-cloud-trace-exporter');

module.exports = () => {
    const provider = new NodeTracerProvider({
        // Use grpc plugin to receive trace contexts from client (checkout)
        plugins: {
            grpc: {
                enabled: true,
                path: '@opentelemetry/plugin-grpc',
            }
        }
    });
    provider.addSpanProcessor(new BatchSpanProcessor(new TraceExporter()));

    // Initialize the OpenTelemetry APIs to use the NodeTracerProvider bindings
    provider.register();

    return opentelemetry.trace.getTracer('payment');
}
