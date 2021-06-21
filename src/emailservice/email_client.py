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

import grpc
from opentelemetry import propagate, trace
from opentelemetry.exporter.cloud_trace import CloudTraceSpanExporter
from opentelemetry.instrumentation.grpc import client_interceptor
from opentelemetry.propagators.cloud_trace_propagator import CloudTraceFormatPropagator
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import SimpleSpanProcessor

import demo_pb2
import demo_pb2_grpc
from logger import get_json_logger

logger = get_json_logger("emailservice-client")


try:
    trace.set_tracer_provider(TracerProvider())
    trace.get_tracer_provider().add_span_processor(
        SimpleSpanProcessor(CloudTraceSpanExporter())
    )
    propagate.set_global_textmap(CloudTraceFormatPropagator())
    tracer_interceptor = client_interceptor(trace.get_tracer_provider())
except Exception as e:
    raise Exception("{}".format(e))


def send_confirmation_email(email, order):
    channel = grpc.insecure_channel("0.0.0.0:8080")
    channel = grpc.intercept_channel(channel, tracer_interceptor)
    stub = demo_pb2_grpc.EmailServiceStub(channel)
    try:
        response = stub.SendOrderConfirmation(
            demo_pb2.SendOrderConfirmationRequest(email=email, order=order)
        )
        logger.info("Request sent. response: {}".format(response))
    except grpc.RpcError as err:
        logger.error(err.details())
        logger.error("{}, {}".format(err.code().name, err.code().value))


if __name__ == "__main__":
    logger.info("Client for email service.")
