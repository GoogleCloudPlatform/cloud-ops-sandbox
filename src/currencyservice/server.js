/*
 * Copyright 2018 Google LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

require('@google-cloud/profiler').start({
  serviceContext: {
    service: 'currencyservice',
  }
});
require('@google-cloud/debug-agent').start({
  serviceContext: {
    service: 'currencyservice',
  }
});

const opentelemetry = require('@opentelemetry/api');
const {NodeTracerProvider} = require('@opentelemetry/node');
const {BatchSpanProcessor} = require('@opentelemetry/tracing');
const {TraceExporter} = require('@google-cloud/opentelemetry-cloud-trace-exporter');
const { registerInstrumentations } = require('@opentelemetry/instrumentation');
const { GrpcInstrumentation } = require('@opentelemetry/instrumentation-grpc');

// OpenTelemetry tracing with exporter to Google Cloud Trace
const provider = new NodeTracerProvider();
provider.register();

registerInstrumentations({
  instrumentations: [new GrpcInstrumentation()]
});

// Enable OpenTelemetry exporters to export traces to Google Cloud Trace.
// Exporters use Application Default Credentials (ADCs) to authenticate.
// See https://developers.google.com/identity/protocols/application-default-credentials
// for more details. When your application is running on GCP,
// you don't need to provide auth credentials or a project id.
const exporter = new TraceExporter();
provider.addSpanProcessor(new BatchSpanProcessor(exporter));
const tracer = opentelemetry.trace.getTracer('currency');

const path = require('path');
const grpc = require('grpc');
const request = require('request');
const xml2js = require('xml2js');
const pino = require('pino');
const protoLoader = require('@grpc/proto-loader');

const MAIN_PROTO_PATH = path.join(__dirname, './proto/demo.proto');
const HEALTH_PROTO_PATH = path.join(__dirname, './proto/grpc/health/v1/health.proto');

const PORT = 7000;
const DATA_URL = 'http://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml';

const shopProto = _loadProto(MAIN_PROTO_PATH).hipstershop;
const healthProto = _loadProto(HEALTH_PROTO_PATH).grpc.health.v1;

const logger = pino({
  name: 'currencyservice-server',
  messageKey: 'message',
  levelKey: 'severity',
  useLevelLabels: true
});

/**
 * Helper function that loads a protobuf file.
 */
function _loadProto (path) {
  const packageDefinition = protoLoader.loadSync(
    path,
    {
      keepCase: true,
      longs: String,
      enums: String,
      defaults: true,
      oneofs: true
    }
  );
  return grpc.loadPackageDefinition(packageDefinition);
}

/**
 * Helper function that gets currency data from an XML webpage
 * Uses public data from European Central Bank
 */
let _data;
function _getCurrencyData (callback) {
  if (!_data) {
    logger.info('Fetching currency data...');
    request(DATA_URL, (err, res) => {
      if (err) {
        throw new Error(`Error getting data: ${err}`);
      }

      const body = res.body.split('\n').slice(7, -2).join('\n');
      xml2js.parseString(body, (err, resJs) => {
        if (err) {
          throw new Error(`Error parsing HTML: ${err}`);
        }

        const array = resJs['Cube']['Cube'].map(x => x['$']);
        const results = array.reduce((acc, x) => {
          acc[x['currency']] = x['rate'];
          return acc;
        }, { 'EUR': '1.0' });
        _data = results;
        callback(_data);
      });
    });
  } else {
    callback(_data);
  }
}

/**
 * Helper function that handles decimal/fractional carrying
 */
function _carry (amount) {
  const fractionSize = Math.pow(10, 9);
  amount.nanos += (amount.units % 1) * fractionSize;
  amount.units = Math.floor(amount.units) + Math.floor(amount.nanos / fractionSize);
  amount.nanos = amount.nanos % fractionSize;
  return amount;
}

/**
 * Lists the supported currencies
 */
function getSupportedCurrencies (call, callback) {
  // Extract the span context received from the gRPC client.
  // Create a child span and add an event.
  const span = tracer.startSpan('currencyservice:GetSupportedCurrencies()', {
    kind: 1, // server
  });
  span.addEvent('Get Supported Currencies');
  logger.info('Getting supported currencies...');
  _getCurrencyData((data) => {
    callback(null, {currency_codes: Object.keys(data)});
    span.end();
  });
}

/**
 * Converts between currencies
 */
function convert (call, callback) {
  // Extract the span context received from the gRPC client.
  // Create a child span and add an event.
  const span = tracer.startSpan('currencyservice:Convert()', {
    kind: 1, // server
  });
  logger.info('received conversion request');
  try {
    _getCurrencyData((data) => {
      const request = call.request;

      // Convert: from_currency --> EUR
      const from = request.from;
      const euros = _carry({
        units: from.units / data[from.currency_code],
        nanos: from.nanos / data[from.currency_code]
      });

      euros.nanos = Math.round(euros.nanos);

      // Convert: EUR --> to_currency
      const result = _carry({
        units: euros.units * data[request.to_code],
        nanos: euros.nanos * data[request.to_code]
      });

      result.units = Math.floor(result.units);
      result.nanos = Math.floor(result.nanos);
      result.currency_code = request.to_code;

      logger.info(`conversion request successful`);
      span.addEvent(`Convert Currency from ${request.from.currency_code} to ${request.to_code}`);
      callback(null, result);
      span.end();
    });
  } catch (err) {
    logger.error(`conversion request failed: ${err}`);
    callback(err.message);
  }
}

/**
 * Endpoint for health checks
 */
function check (call, callback) {
  callback(null, { status: 'SERVING' });
}

/**
 * Starts an RPC server that receives requests for the
 * CurrencyConverter service at the sample server port
 */
function main () {
  logger.info(`Starting gRPC server on port ${PORT}...`);
  const server = new grpc.Server();
  server.addService(shopProto.CurrencyService.service, {getSupportedCurrencies, convert});
  server.addService(healthProto.Health.service, {check});
  server.bind(`0.0.0.0:${PORT}`, grpc.ServerCredentials.createInsecure());
  server.start();
}

main();
// Flush all traces and shut down the Cloud Trace exporter.
exporter.shutdown();
