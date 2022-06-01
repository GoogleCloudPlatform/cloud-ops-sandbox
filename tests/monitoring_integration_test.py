# Copyright 2020 Google LLC
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

from __future__ import print_function

import argparse
import os
import pprint
import unittest
import tabulate
import subprocess
import sys
import json
import time

from collections import namedtuple

from google.cloud import monitoring_v3
from google.cloud import logging_v2
from google.cloud.monitoring_dashboard import v1
from googleapiclient import discovery
from oauth2client.client import GoogleCredentials

project_name = 'projects/'
project_id = ''
zone = '-'


def getProjectId():
    """Retrieves the project id from the script arguments.
    Returns:
        str -- the project id
    Exits when project id is not set
    """
    try:
        project_id = sys.argv[1]
    except:
        exit('Missing Project ID. Usage: python3 monitoring_integration_test.py $PROJECT_ID')

    return project_id


def getZone():
    """Retrieves the zone of the Kubernetes cluster hosted on GKE.
    Raises:
    MissingZoneError -- When no cluster is found.
    Returns:
        str -- the zone
    """
    credentials = GoogleCredentials.get_application_default()

    service = discovery.build('container', 'v1', credentials=credentials)

    zone = '-'  # query for all zones

    request = service.projects().zones().clusters().list(
        projectId=project_id, zone=zone)
    response = request.execute()

    # Retrieve the cluster for cloud-ops-sandbox and its zone
    clusters = response['clusters']
    for cluster in clusters:
        if cluster['name'] == 'cloud-ops-sandbox':
            zone = cluster['zone']

    if zone == '-':
        raise MissingZoneError(
            'No zone for the cloud-ops-sandbox cluster was detected')

    return zone

ServiceName = namedtuple("ServiceName", "short long")
_services = [
    ServiceName(short='adservice', long='Ad Service'),
    ServiceName(short='cartservice', long='Cart Service'),
    ServiceName(short='checkoutservice', long='Checkout Service'),
    ServiceName(short='currencyservice', long='Currency Service'),
    ServiceName(short='emailservice', long='Email Service'),
    ServiceName(short='frontend', long='Frontend Service'),
    ServiceName(short='paymentservice', long='Payment Service'),
    ServiceName(short='productcatalogservice', long='Product Catalog Service')
    ServiceName(short='recommendationservice', long='Recommendation Service'),
    ServiceName(short='shippingservice', long='Shipping Service'),
]


class TestUptimeCheck(unittest.TestCase):

    external_ip = ''

    @classmethod
    def setUpClass(cls):
        """ Retrieve the external IP of the cluster """
        with open('out.txt', 'w+') as fout:
            out = subprocess.run(["kubectl", "-n", "istio-system", "get", "service", "istio-ingressgateway",
                                  "-o", "jsonpath='{.status.loadBalancer.ingress[0].ip}'"], stdout=fout)
            fout.seek(0)
            cls.external_ip = fout.read().replace('\'', '')

    def testNumberOfUptimeChecks(self):
        """" Test that ensures there is an uptime check created """
        client = monitoring_v3.UptimeCheckServiceClient()
        configs = client.list_uptime_check_configs(project_name)
        config_list = []
        for config in configs:
            config_list.append(config)

        self.assertTrue(len(config_list) >= 1)

    def testUptimeCheckName(self):
        """ Verifies the configured IP address of the uptime check matches the external IP
                address of the cluster """
        client = monitoring_v3.UptimeCheckServiceClient()
        configs = client.list_uptime_check_configs(project_name)
        config_list = []
        for config in configs:
            config_list.append(config)

        config = config_list[0]
        self.assertEqual(
            config.monitored_resource.labels["host"], self.external_ip)

    def testUptimeCheckAlertingPolicy(self):
        """ Test that an alerting policy was created. """
        client = monitoring_v3.AlertPolicyServiceClient()
        policies = client.list_alert_policies(project_name)
        found_uptime_alert = False
        for policy in policies:
            if policy.display_name == 'HTTP Uptime Check Alerting Policy':
                found_uptime_alert = True

        self.assertTrue(found_uptime_alert)

    def testUptimeCheckAlertingPolicyNotificationChannel(self):
        """ Test that a notification channel was created. """
        client = monitoring_v3.NotificationChannelServiceClient()
        channels = client.list_notification_channels(project_name)
        channel_list = []
        for channel in channels:
            channel_list.append(channel)

        self.assertTrue(len(channel_list) >= 1)


class TestMonitoringDashboard(unittest.TestCase):
    """
    Ensure Dashboards are set up for all Hipstershop Services,
    Plust a User Experience Dashboard and a Log Based Metric Dashboard
    """

    def testDashboardsExist(self):
        """
        Test to ensure dashboards were set up
        """
        expected_dashboards = [f"{service.long} Dashboard" for service in _services]
        expected_dashboards += ['User Experience Dashboard', 'Log Based Metric Dashboard']

        client = v1.DashboardsServiceClient()
        found_dashboards = client.list_dashboards(project_name)
        found_dashboard_names = [dash.display_name for dash in found_dashboards]
        for expected_dash in expected_dashboards:
            self.assertIn(expected_dash, found_dashboard_names, f"{expected_dash} not found")
            print(f"✅  {expected_dash} created")

class TestLogBasedMetric(unittest.TestCase):

    def testCheckoutServiceLogMetric(self):
        """ Test that the log based metric for the Checkout Service gets created. """
        client = logging_v2.Client()
        metric = client.metric("checkoutservice_log_metric")
        self.assertTrue(metric.exists())

class TestServiceSlo(unittest.TestCase):
    """
    Check to make sure Istio services and SLOs are created properly
    """
    def setUp(self):
        self.client = monitoring_v3.ServiceMonitoringServiceClient()
        self.project_id = getProjectId()

    def getIstioService(self, service_name):
        return 'ist:' + project_id + '-zone-' + zone + '-cloud-ops-sandbox-default-' + service_name

    def _get_metric_data(self, filter_, aggregation, period_seconds=1200):
        """
        Helper function to query metric data for a service

        Args:
            service_name (str): the name of the service to query
            period_seconds: the number of seconds back to read metrics for
        Returns:
            a list of results from the API
        """
        client = monitoring_v3.MetricServiceClient()
        now = time.time()
        now_seconds = int(now)
        now_nanos = int((now - now_seconds) * 10 ** 9)
        interval = {
                "end_time": {"seconds": now_seconds, "nanos": now_nanos},
                "start_time": {"seconds": (now_seconds - period_seconds), "nanos": now_nanos},
        }
        results = client.list_time_series(
            name=project_name,
            filter_=filter_,
            interval=interval,
            view=monitoring_v3.types.ListTimeSeriesRequest.TimeSeriesView.FULL,
            aggregation=aggregation,
        )
        return results

    def get_service_availability(self, service_name, period_seconds=1200):
        """
        Calculates the availability ratio for a service

        Args:
            service_name (str): the name of the service to query
            period_seconds: the number of seconds back to read metrics for
        Returns:
            the availability % as a float
        """
        filter_ = f'metric.type = "istio.io/service/server/request_count" AND resource.labels.canonical_service_name = "{service_name}"'
        aggregation = {
            "alignment_period": {"seconds": period_seconds},
            "per_series_aligner": monitoring_v3.types.Aggregation.Aligner.ALIGN_MEAN,
            "cross_series_reducer": monitoring_v3.types.Aggregation.Reducer.REDUCE_MEAN,
            "group_by_fields": ["metric.labels.response_code"],
        }
        results = self._get_metric_data(filter_, aggregation, period_seconds)
        # count up the percentage of successful calls
        # 200s are successes, 500s are errors. 300-400s are excluded, as they are caused by client-side errors
        ratio = None
        try:
            success_total, fail_total = 0, 0
            for response in results:
                status_code = int(response.metric.labels['response_code'])
                request_count = response.points[0].value.double_value
                if status_code < 300:
                    success_total += request_count
                elif status_code >= 500:
                    fail_total += request_count
            ratio = success_total/(fail_total+success_total)
        except (IndexError, ZeroDivisionError) as e:
            # data not found. Return None
            pass
        return ratio

    def get_service_latency(self, service_name, period_seconds=1200):
        """
        Calculates the latency data for a service

        Args:
            service_name (str): the name of the service to query
            period_seconds (int): the number of seconds back to read metrics for
        Returns:
            the calculated average latency of the service in miliseconds as a float
        """
        filter_ = f'metric.type = "istio.io/service/server/response_latencies" AND resource.labels.canonical_service_name = "{service_name}"'
        aggregation = {
            "alignment_period": {"seconds": period_seconds},
            "per_series_aligner": monitoring_v3.types.Aggregation.Aligner.ALIGN_DELTA,
            "cross_series_reducer": monitoring_v3.types.Aggregation.Reducer.REDUCE_MEAN,
        }
        results = self._get_metric_data(filter_, aggregation, period_seconds)
        results = list(results)
        latency = None
        try:
            latency = results[0].points[0].value.double_value
        except IndexError:
            # data not found. Return None
            pass
        return latency

    def test_services_created(self):
        """
        Ensure that hipstersop Istio services have been picked up by Cloud Monitoring
        """
        services = [service.short for service in _services]
        for service_name in services:
            istio_service_name = self.getIstioService(service_name)
            full_name = self.client.service_path(self.project_id, istio_service_name)
            result = self.client.get_service(full_name)
            self.assertEqual(result.display_name, service_name, f"{service_name} not found")
            print(f"✅  {service_name} canonical service created")

    def test_slos_created(self):
        """
        Ensure that SLOs have been added to Istio services
        """
        services = [service.short for service in _services]
        for service_name in services:
            istio_service_name = self.getIstioService(service_name)
            for slo_type in ['latency', 'availability']:
                slo_id = f"{service_name}-{slo_type}-slo"
                slo_name_full = self.client.service_level_objective_path(
                    self.project_id, istio_service_name, slo_id)
                result = self.client.get_service_level_objective(slo_name_full)
                self.assertIsNotNone(result, f"{service_name} {slo_type} SLO not found")
                print(f"✅  {service_name} {slo_type} SLO created")

    def test_availability_slos_passing(self):
        """
        Ensure that availability is at expected levels to pass the SLO
        """
        services = [service.short for service in _services]
        for service_name in services:
            # get SLO
            istio_service_name = self.getIstioService(service_name)
            slo_id = f"{service_name}-availability-slo"
            slo_name_full = self.client.service_level_objective_path(
                self.project_id, istio_service_name, slo_id)
            slo = self.client.get_service_level_objective(slo_name_full)
            # get metric data
            availability = self.get_service_availability(service_name)
            self.assertIsNotNone(availability, f"{service_name} availability data not found")
            SLO_status_text = f"({int(availability * 100)}% availibility, SLO={int(slo.goal * 100)}%)"
            self.assertGreater(availability, slo.goal, f"{service_name} failed availability SLO {SLO_status_text}")
            print(f"✅  {service_name} Availability SLO passed: {SLO_status_text}")

    def test_latency_slos_passing(self):
        """
        Ensure that service latency is at expected levels to pass the SLO
        """
        services = [service.short for service in _services]
        for service_name in services:
            # get SLO
            istio_service_name = self.getIstioService(service_name)
            slo_id = f"{service_name}-latency-slo"
            slo_name_full = self.client.service_level_objective_path(
                self.project_id, istio_service_name, slo_id)
            slo = self.client.get_service_level_objective(slo_name_full)
            max_latency = slo.service_level_indicator.request_based.distribution_cut.range.max
            # get metric data
            latency = self.get_service_latency(service_name)
            self.assertIsNotNone(latency, f"{service_name} latency data not found")
            SLO_status_text = f"({latency:.2f}ms latency, SLO={max_latency:.2f}ms)"
            self.assertLess(latency, max_latency, f"{service_name} failed latency SLO {SLO_status_text}")
            print(f"✅  {service_name} Latency SLO passed: {SLO_status_text}")

class TestSloAlertPolicy(unittest.TestCase):
    """
    Ensure SLO Alert Policies are set up for each Hipstershop service
    """
    def setUp(self):
        self.client = monitoring_v3.AlertPolicyServiceClient()

    def testAlertsExist(self):
        found_policies = self.client.list_alert_policies(project_name)
        found_policy_names = [policy.display_name for policy in found_policies]
        services = [service.long for service in _services]
        for service_name in services:
            latency_alert_name = f"{service_name} Latency Alert Policy"
            self.assertIn(latency_alert_name, found_policy_names, f"{latency_alert_name} not found")
            availability_alert_name = f"{service_name} Availability Alert Policy"
            self.assertIn(availability_alert_name, found_policy_names, f"{availability_alert_name} not found")
            print(f"✅  {service_name} Alerts created")

class TestServiceLogs(unittest.TestCase):
    """
    Make sure logs are sent to Cloud Logging and readable for each service
    """
    def setUp(self):
        self.client = logging_v2.Client()

    def testLogsExist(self):
        services = [service.short for service in _services]
        for service_name in services:
            log_filter = f'labels."k8s-pod/service_istio_io/canonical-name"="{service_name}"'
            results = self.client.list_entries(filter_=log_filter)
            first_result = next(results, None)
            self.assertIsNotNone(first_result, f"{service_name} logs not found")
            print(f"✅  {service_name} logs found")

if __name__ == '__main__':
    project_id = getProjectId()
    project_name = project_name + project_id
    zone = getZone()
    unittest.main(argv=['first-arg-is-ignored'])
