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

from concurrent import futures
import argparse
import os
import sys
import time
import grpc
import base64
from jinja2 import Environment, FileSystemLoader, select_autoescape, TemplateError
from google.api_core.exceptions import GoogleAPICallError
from google.auth.exceptions import DefaultCredentialsError

import demo_pb2
import demo_pb2_grpc
from grpc_health.v1 import health_pb2
from grpc_health.v1 import health_pb2_grpc

from opencensus.ext.stackdriver import trace_exporter as stackdriver_exporter
from opencensus.ext.grpc import server_interceptor as oc_server_interceptor
from opencensus.common.transports.async_ import AsyncTransport
from opencensus.trace import samplers

from opentelemetry import trace
from opentelemetry.exporter.cloud_trace import CloudTraceSpanExporter
from opentelemetry.ext.grpc import server_interceptor
from opentelemetry.ext.grpc.grpcext import intercept_server
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import SimpleExportSpanProcessor

# import googleclouddebugger
import googlecloudprofiler

from logger import getJSONLogger
logger = getJSONLogger('emailservice-server')

# try:
#     googleclouddebugger.enable(
#         module='emailserver',
#         version='1.0.0'
#     )
# except:
#     pass

# Loads confirmation email template from file
env = Environment(
    loader=FileSystemLoader('templates'),
    autoescape=select_autoescape(['html', 'xml'])
)
template = env.get_template('confirmation.html')

class BaseEmailService(demo_pb2_grpc.EmailServiceServicer):
  def Check(self, request, context):
    return health_pb2.HealthCheckResponse(
      status=health_pb2.HealthCheckResponse.SERVING)
  def Watch(self, request, context):
    return health_pb2.HealthCheckResponse(
      status=health_pb2.HealthCheckResponse.UNIMPLEMENTED)

class EmailService(BaseEmailService):
  def __init__(self):
    raise Exception('cloud mail client not implemented')
    super().__init__()

  @staticmethod
  def send_email(client, email_address, content):
    response = client.send_message(
      sender = client.sender_path(project_id, region, sender_id),
      envelope_from_authority = '',
      header_from_authority = '',
      envelope_from_address = from_address,
      simple_message = {
        "from": {
          "address_spec": from_address,
        },
        "to": [{
          "address_spec": email_address
        }],
        "subject": "Your Confirmation Email",
        "html_body": content
      }
    )
    logger.info("Message sent: {}".format(response.rfc822_message_id))

  def SendOrderConfirmation(self, request, context):
    email = request.email
    order = request.order

    try:
      confirmation = template.render(order = order)
    except TemplateError as err:
      context.set_details("An error occurred when preparing the confirmation mail.")
      logger.error(err.message)
      context.set_code(grpc.StatusCode.INTERNAL)
      return demo_pb2.Empty()

    try:
      EmailService.send_email(self.client, email, confirmation)
    except GoogleAPICallError as err:
      context.set_details("An error occurred when sending the email.")
      print(err.message)
      context.set_code(grpc.StatusCode.INTERNAL)
      return demo_pb2.Empty()

    return demo_pb2.Empty()

class DummyEmailService(BaseEmailService):
  def SendOrderConfirmation(self, request, context):
    logger.info('A request to send order confirmation email to {} has been received.'.format(request.email))
    if os.getenv('ENCODE_EMAIL', 'false').lower() == 'true':
      try:
        encoded_email = self.EncodeEmail(request.email)
        request.email = encoded_email
      except:
        logger.error('Err: Could not encode email')
        context.set_code(grpc.StatusCode.INTERNAL)
    return demo_pb2.Empty()

  def EncodeEmail(self, email):
    """ 
    Encodes the email address to base64 encoding
    Input: 
      email - (string) the email address
    Output:
      string - the encoded email as base64
    """
    byte_rep = email.encode('ascii')
    b64_bytes = base64.b64encode(email)
    return b64_bytes.decode('ascii')

class HealthCheck():
  def Check(self, request, context):
    return health_pb2.HealthCheckResponse(
      status=health_pb2.HealthCheckResponse.SERVING)

def start(dummy_mode):
  # Create gRPC server channel to receive requests from checkout (client).
  server = grpc.server(futures.ThreadPoolExecutor(max_workers=10),
                       interceptors=(oc_tracer_interceptor,)) # TODO: remove OpenCensus interceptor
  # OpenTelemetry interceptor receives trace contexts from clients.
  server = intercept_server(server, server_interceptor(trace.get_tracer_provider()))

  service = None
  if dummy_mode:
    service = DummyEmailService()
  else:
    raise Exception('non-dummy mode not implemented yet')

  demo_pb2_grpc.add_EmailServiceServicer_to_server(service, server)
  health_pb2_grpc.add_HealthServicer_to_server(service, server)

  port = os.environ.get('PORT', "8080")
  logger.info("listening on port: "+port)
  server.add_insecure_port('[::]:'+port)
  server.start()
  try:
    while True:
      time.sleep(3600)
  except KeyboardInterrupt:
    server.stop(0)

def initStackdriverProfiling():
  project_id = None
  try:
    project_id = os.environ["GCP_PROJECT_ID"]
  except KeyError:
    # Environment variable not set
    pass

  for retry in range(1,4):
    try:
      if project_id:
        googlecloudprofiler.start(service='email_server', service_version='1.0.0', verbose=0, project_id=project_id)
      else:
        googlecloudprofiler.start(service='email_server', service_version='1.0.0', verbose=0)
      logger.info("Successfully started Stackdriver Profiler.")
      return
    except (BaseException) as exc:
      logger.info("Unable to start Stackdriver Profiler Python agent. " + str(exc))
      if (retry < 4):
        logger.info("Sleeping %d to retry initializing Stackdriver Profiler"%(retry*10))
        time.sleep (1)
      else:
        logger.warning("Could not initialize Stackdriver Profiler after retrying, giving up")
  return


if __name__ == '__main__':
  logger.info('starting the email service in dummy mode.')

  # Profiler
  try:
    if "DISABLE_PROFILER" in os.environ:
      raise KeyError()
    else:
      logger.info("Profiler enabled.")
      initStackdriverProfiling()
  except KeyError:
      logger.info("Profiler disabled.")

  # TODO: remove OpenCensus after conversion to OpenTelemetry
  try:
    if "DISABLE_TRACING" in os.environ:
      raise KeyError()
    else:
      logger.info("Tracing enabled.")
      sampler = samplers.AlwaysOnSampler()
      exporter = stackdriver_exporter.StackdriverExporter(
        project_id=os.environ.get('GCP_PROJECT_ID'),
        transport=AsyncTransport)
      oc_tracer_interceptor = oc_server_interceptor.OpenCensusServerInterceptor(sampler, exporter)
  except (KeyError, DefaultCredentialsError):
      logger.info("Tracing disabled.")
      oc_tracer_interceptor = oc_server_interceptor.OpenCensusServerInterceptor()
  
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

  start(dummy_mode = True)
