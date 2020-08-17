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

const opentelemetry = require('@opentelemetry/api');
const {NodeTracerProvider} = require('@opentelemetry/node');
const {BatchSpanProcessor} = require('@opentelemetry/tracing');
const {TraceExporter} = require('@google-cloud/opentelemetry-cloud-trace-exporter');

module.exports = () => {
    // OpenTelemetry tracing with exporter to Google Cloud Trace
    const provider = new NodeTracerProvider({
        // Use grpc plugin to receive trace contexts from client
        plugins: {
            grpc: {
                enabled: true,
                path: '@opentelemetry/plugin-grpc',
            }
        }
    });
    // Cloud Trace Exporter handles credentials.
    provider.addSpanProcessor(new BatchSpanProcessor(new TraceExporter()));

    // Initialize the OpenTelemetry APIs to use the NodeTracerProvider bindings
    provider.register();

    return opentelemetry.trace.getTracer('payment');
}
