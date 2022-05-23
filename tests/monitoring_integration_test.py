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
        exit('Missing Project ID. Usage: python3 monitoring_integration_test.py $PROJECT_ID $PROJECT_NUMBER')

    return project_id


def getProjectNumber():
    """Retrieves the project number from the script arguments.
    Returns:
        str -- the project number
    Exits when project number is not set
    """
    try:
        project_num = sys.argv[2]
    except:
        exit('Missing Project Number. Usage: python3 monitoring_integration_test.py $PROJECT_ID $PROJECT_NUMBER')

    return project_num

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
    def checkForDashboard(self, dashboard_display_name):
        client = v1.DashboardsServiceClient()
        dashboards = client.list_dashboards(project_name)
        for dashboard in dashboards:
            if dashboard.display_name == dashboard_display_name:
                return True
        return False

    def testDashboardsExist(self):
        """
        Test to ensure dashboards were set up
        """
        expected_dashboards = [
            'User Experience Dashboard',
            'Log Based Metric Dashboard',
            'Ad Service Dashboard',
            'Cart Service Dashboard',
            'Checkout Service Dashboard',
            'Currency Service Dashboard',
            'Email Service Dashboard',
            'Frontend Service Dashboard',
            'Payment Service Dashboard',
            'Product Catalog Service Dashboard',
            'Recommendation Service Dashboard',
            'Shipping Service Dashboard',
        ]
        client = v1.DashboardsServiceClient()
        found_dashboards = client.list_dashboards(project_name)
        found_dashboiard_names = [dash.display_name for dash in found_dashboards]
        for expected_dash in expected_dashboards:
            self.assertIn(expected_dash, found_dashboiard_names)

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

    def checkForSlo(self, service, slo):
        name = self.client.service_level_objective_path(
            self.project_id, service, slo)
        return self.client.get_service_level_objective(name)

    def getIstioService(self, service_name):
        project_num = getProjectNumber()
        return 'canonical-ist:proj-' + project_num + '-default-' + service_name

    def test_services_created(self):
        """
        Ensure that hipstersop Istio services have been picked up by Cloud Monitoring
        """
        services = [
            'adservice',
            'cartservice',
            'checkoutservice',
            'currencyservice',
            'emailservice',
            'frontend',
            'paymentservice',
            'productcatalogservice',
            'recommendationservice',
            'shippingservice',
        ]
        for service_name in services:
            istio_service_name = self.getIstioService(service_name)
            full_name = self.client.service_path(self.project_id, istio_service_name)
            result = self.client.get_service(full_name)
            self.assertEqual(result.display_name, service_name)

    def test_slos_created(self):
        """
        Ensure that SLOs have been added to Istio services
        """
        services = [
            'adservice',
            'cartservice',
            'checkoutservice',
            'currencyservice',
            'emailservice',
            'frontend',
            'paymentservice',
            'productcatalogservice',
            'recommendationservice',
            'shippingservice',
        ]
        for service_name in services:
            istio_service_name = self.getIstioService(service_name)
            for slo_type in ['latency', 'availability']:
                slo_id = f"{service_name}-{slo_type}-slo"
                slo_name_full = self.client.service_level_objective_path(
                    self.project_id, istio_service_name, slo_id)
                result = self.client.get_service_level_objective(slo_name_full)
                self.assertIsNotNone(result)


class TestSloAlertPolicy(unittest.TestCase):
    """
    Ensure SLO Alert Policies are set up for each Hipstershop service
    """
    def setUp(self):
        self.client = monitoring_v3.AlertPolicyServiceClient()

    def checkForAlertingPolicy(self, policy_display_name):
        policies = self.client.list_alert_policies(project_name)
        for policy in policies:
            if policy.display_name == policy_display_name:
                return True
        return False

    def testAlertsExist(self):
        services = [
            'Ad Service',
            'Cart Service',
            'Checkout Service',
            'Currency Service',
            'Email Service',
            'Frontend Service',
            'Payment Service',
            'Product Catalog Service',
            'Recommendation Service',
            'Shipping Service',
        ]

        found_policies = self.client.list_alert_policies(project_name)
        found_policy_names = [policy.display_name for policy in found_policies]
        for service_name in services:
            latency_alert_name = f"{service_name} Latency Alert Policy"
            self.assertIn(latency_alert_name, found_policy_names)
            availability_alert_name = f"{service_name} Availability Alert Policy"
            self.assertIn(availability_alert_name, found_policy_names)

if __name__ == '__main__':
    project_id = getProjectId()
    project_name = project_name + project_id
    unittest.main(argv=['first-arg-is-ignored'])
