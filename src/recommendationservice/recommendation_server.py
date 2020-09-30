#!/usr/bin/python
#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import random
import time
import traceback
from concurrent import futures

import googleclouddebugger
import grpc
from opencensus.ext.stackdriver import trace_exporter as stackdriver_exporter
from opencensus.ext.grpc import server_interceptor as oc_server_interceptor
from opencensus.trace import samplers

from opentelemetry import trace
from opentelemetry.exporter.cloud_trace import CloudTraceSpanExporter
from opentelemetry.ext.grpc import client_interceptor, server_interceptor
from opentelemetry.ext.grpc.grpcext import intercept_server, intercept_channel
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import SimpleExportSpanProcessor

import demo_pb2
import demo_pb2_grpc
from grpc_health.v1 import health_pb2
from grpc_health.v1 import health_pb2_grpc

from logger import getJSONLogger
logger = getJSONLogger('recommendationservice-server')


class RecommendationService(demo_pb2_grpc.RecommendationServiceServicer):
    def ListRecommendations(self, request, context):
        max_responses = 5
        # fetch list of products from product catalog stub
        cat_response = product_catalog_stub.ListProducts(demo_pb2.Empty())
        product_ids = [x.id for x in cat_response.products]
        filtered_products = list(set(product_ids)-set(request.product_ids))
        num_products = len(filtered_products)
        num_return = min(max_responses, num_products)
        # sample list of indicies to return
        indices = random.sample(range(num_products), num_return)
        # fetch product ids from indices
        prod_list = [filtered_products[i] for i in indices]
        logger.info("[Recv ListRecommendations] product_ids={}".format(prod_list))
        # build and return response
        response = demo_pb2.ListRecommendationsResponse()
        response.product_ids.extend(prod_list)
        return response

    def Check(self, request, context):
        return health_pb2.HealthCheckResponse(
            status=health_pb2.HealthCheckResponse.SERVING)
    def Watch(self, request, context):
        return health_pb2.HealthCheckResponse(
            status=health_pb2.HealthCheckResponse.UNIMPLEMENTED)

if __name__ == "__main__":
    logger.info("initializing recommendationservice")

    # OpenTelemetry Tracing
    # TracerProvider provides global state and access to tracers.
    trace.set_tracer_provider(TracerProvider())

    # Export traces to Google Cloud Trace
    # When running on GCP, the exporter handles authentication
    # using automatically default application credentials.
    # When running locally, credentials may need to be set explicitly.
    cloud_trace_exporter = CloudTraceSpanExporter()
    trace.get_tracer_provider().add_span_processor(
        SimpleExportSpanProcessor(cloud_trace_exporter)
    )

    # TODO: remove OpenCensus after conversion to OpenTelemetry
    try:
        sampler = samplers.AlwaysOnSampler()
        exporter = stackdriver_exporter.StackdriverExporter()
        oc_interceptor = oc_server_interceptor.OpenCensusServerInterceptor(sampler, exporter)
    except:
        oc_interceptor = oc_server_interceptor.OpenCensusServerInterceptor()

    try:
        googleclouddebugger.enable(
            module='recommendationservice',
        )
    except (Exception, err):
        logger.error("could not enable debugger")
        logger.error(traceback.print_exc())
        pass

    port = os.environ.get('PORT', "8080")
    catalog_addr = os.environ.get('PRODUCT_CATALOG_SERVICE_ADDR', '')
    if catalog_addr == "":
        raise Exception('PRODUCT_CATALOG_SERVICE_ADDR environment variable not set')
    logger.info("product catalog address: " + catalog_addr)

    # Create the gRPC client channel to ProductCatalog (server).
    channel = grpc.insecure_channel(catalog_addr)
    
    # OpenTelemetry client interceptor passes trace contexts to the server.
    channel = intercept_channel(channel, client_interceptor(trace.get_tracer_provider()))
    product_catalog_stub = demo_pb2_grpc.ProductCatalogServiceStub(channel)

    # Create the gRPC server for accepting ListRecommendations Requests from frontend (client).
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))

    # OpenTelemetry interceptor receives trace contexts from clients.
    server = intercept_server(server, server_interceptor(trace.get_tracer_provider()))

    # Add RecommendationService class to gRPC server.
    service = RecommendationService()
    demo_pb2_grpc.add_RecommendationServiceServicer_to_server(service, server)
    health_pb2_grpc.add_HealthServicer_to_server(service, server)

    # start server
    logger.info("listening on port: " + port)
    server.add_insecure_port('[::]:'+port)
    server.start()

    # keep alive
    try:
         while True:
            time.sleep(10000)
    except KeyboardInterrupt:
            server.stop(0)
