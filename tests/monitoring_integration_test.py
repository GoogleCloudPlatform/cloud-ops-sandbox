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
        str -- the project name
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
    def checkForDashboard(self, dashboard_display_name):
        client = v1.DashboardsServiceClient()
        dashboards = client.list_dashboards(project_name)
        for dashboard in dashboards:
            if dashboard.display_name == dashboard_display_name:
                return True
        return False

    def testUserExpDashboard(self):
        """ Test that the User Experience Dashboard gets created. """
        found_dashboard = self.checkForDashboard('User Experience Dashboard')
        self.assertTrue(found_dashboard)

    def testAdServiceDashboard(self):
        """" Test that the Ad Service Dashboard gets created. """
        found_dashboard = self.checkForDashboard('Ad Service Dashboard')
        self.assertTrue(found_dashboard)

    def testRecommendationServiceDashboard(self):
        """" Test that the Recommendation Service Dashboard gets created. """
        found_dashboard = self.checkForDashboard(
            'Recommendation Service Dashboard')
        self.assertTrue(found_dashboard)

    def testAdServiceDashboard(self):
        """" Test that the Ad Service Dashboard gets created. """
        found_dash = self.checkForDashboard('Ad Service Dashboard')
        self.assertTrue(found_dash)

    def testFrontendServiceDashboard(self):
        """ Test that the Frontend Service Dashboard gets created. """
        found_dashboard = self.checkForDashboard('Frontend Service Dashboard')
        self.assertTrue(found_dashboard)

    def testEmailServiceDashboard(self):
        """ Test that the Email Service Dashboard gets created. """
        found_dashboard = self.checkForDashboard('Email Service Dashboard')
        self.assertTrue(found_dashboard)

    def testPaymentServiceDashboard(self):
        """ Test that the Payment Service Dashboard gets created. """
        found_dashboard = self.checkForDashboard('Payment Service Dashboard')
        self.assertTrue(found_dashboard)

    def testShippingServiceDashboard(self):
        """ Test that the Shipping Service Dashboard gets created. """
        found_dashboard = self.checkForDashboard('Shipping Service Dashboard')
        self.assertTrue(found_dashboard)

    def testCartServiceDashboard(self):
        """ Test that the Cart Service Dashboard gets created. """
        found_dashboard = self.checkForDashboard('Cart Service Dashboard')
        self.assertTrue(found_dashboard)

    def testCheckoutServiceDashboard(self):
        """ Test that the Checkout Service Dashboard gets created. """
        found_dashboard = self.checkForDashboard('Checkout Service Dashboard')
        self.assertTrue(found_dashboard)

    def testCurrencyServiceDashboard(self):
        """ Test that the Currency Service Dashboard gets created. """
        found_dashboard = self.checkForDashboard('Currency Service Dashboard')
        self.assertTrue(found_dashboard)

    def testProductCatalogServiceDashboard(self):
        """ Test that the Product Catalog Service Dashboard gets created. """
        found_dashboard = self.checkForDashboard(
            'Product Catalog Service Dashboard')
        self.assertTrue(found_dashboard)

    def testRatingServiceDashboard(self):
        """ Test that the Rating Service Dashboard gets created. """
        found_dashboard = self.checkForDashboard('Rating Service Dashboard')
        self.assertTrue(found_dashboard)


class TestLogBasedMetric(unittest.TestCase):
    def setUp(self):
        self.project_id = getProjectId()

    def testCheckoutServiceLogMetric(self):
        """ Test that the log based metric for the Checkout Service gets created. """
        client = logging_v2.Client()
        metric = client.metric("checkoutservice_log_metric")
        self.assertTrue(metric.exists())


class TestServiceSlo(unittest.TestCase):
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

    def testFrontendServiceSloExists(self):
        """ Test that for Frontend Service that two SLOs (availability, latency) get created. """
        serice_name = 'frontend'
        service_id = self.getIstioService(serice_name)
        found_availability_slo = self.checkForSlo(
            service_id, f'{serice_name}-availability-slo')
        self.assertTrue(found_availability_slo)
        found_latency_slo = self.checkForSlo(
            service_id, f'{serice_name}-latency-slo')
        self.assertTrue(found_latency_slo)

    def testCheckoutServiceSloExists(self):
        """ Test that for Checkout Service that two SLOs (availability, latency) get created. """
        serice_name = 'checkoutservice'
        service_id = self.getIstioService(serice_name)
        found_availability_slo = self.checkForSlo(
            service_id, f'{serice_name}-availability-slo')
        self.assertTrue(found_availability_slo)
        found_latency_slo = self.checkForSlo(
            service_id, f'{serice_name}-latency-slo')
        self.assertTrue(found_latency_slo)

    def testPaymentServiceSloExists(self):
        """ Test that for Payment Service that two SLOs (availability, latency) get created. """
        serice_name = 'paymentservice'
        service_id = self.getIstioService(serice_name)
        found_availability_slo = self.checkForSlo(
            service_id, f'{serice_name}-availability-slo')
        self.assertTrue(found_availability_slo)
        found_latency_slo = self.checkForSlo(
            service_id, f'{serice_name}-latency-slo')
        self.assertTrue(found_latency_slo)

    def testEmailServiceSloExists(self):
        """ Test that for Email Service that two SLOs (availability, latency) get created. """
        serice_name = 'emailservice'
        service_id = self.getIstioService(serice_name)
        found_availability_slo = self.checkForSlo(
            service_id, f'{serice_name}-availability-slo')
        self.assertTrue(found_availability_slo)
        found_latency_slo = self.checkForSlo(
            service_id, f'{serice_name}-latency-slo')
        self.assertTrue(found_latency_slo)

    def testShippingServiceSloExists(self):
        """ Test that for Shipping Service that two SLOs (availability, latency) get created. """
        serice_name = 'shippingservice'
        service_id = self.getIstioService(serice_name)
        found_availability_slo = self.checkForSlo(
            service_id, f'{serice_name}-availability-slo')
        self.assertTrue(found_availability_slo)
        found_latency_slo = self.checkForSlo(
            service_id, f'{serice_name}-latency-slo')
        self.assertTrue(found_latency_slo)

    def testCartServiceSloExists(self):
        """ Test that for each service that two SLOs (availability, latency) get created. """
        serice_name = 'cartservice'
        service_id = self.getIstioService(serice_name)
        found_availability_slo = self.checkForSlo(
            service_id, f'{serice_name}-availability-slo')
        self.assertTrue(found_availability_slo)
        found_latency_slo = self.checkForSlo(
            service_id, f'{serice_name}-latency-slo')
        self.assertTrue(found_latency_slo)

    def testProductCatalogServiceSloExists(self):
        """ Test that for each service that two SLOs (availability, latency) get created. """
        productcatalogservice_id = self.getIstioService(
            'productcatalogservice')
        found_availability_slo = self.checkForSlo(
            productcatalogservice_id, 'productcatalogservice-availability-slo')
        self.assertTrue(found_availability_slo)
        found_latency_slo = self.checkForSlo(
            productcatalogservice_id, 'productcatalogservice-latency-slo')
        self.assertTrue(found_latency_slo)

    def testCurrencyServiceSloExists(self):
        """ Test that for each service that two SLOs (availability, latency) get created. """
        currencyservice_id = self.getIstioService('currencyservice')
        found_availability_slo = self.checkForSlo(
            currencyservice_id, 'currencyservice-availability-slo')
        self.assertTrue(found_availability_slo)
        found_latency_slo = self.checkForSlo(currencyservice_id, 'currencyservice-latency-slo')
        self.assertTrue(found_latency_slo)

    def testRecommendationServiceSloExists(self):
        """ Test that for each service that two SLOs (availability, latency) get created. """
        recommendationservice_id = self.getIstioService(
            'recommendationservice')
        found_availability_slo = self.checkForSlo(
            recommendationservice_id, 'recommendationservice-availability-slo')
        self.assertTrue(found_availability_slo)
        found_latency_slo = self.checkForSlo(
            recommendationservice_id, 'recommendationservice-latency-slo')
        self.assertTrue(found_latency_slo)

    def testAdServiceSloExists(self):
        """ Test that for each service that two SLOs (availability, latency) get created. """
        adservice_id = self.getIstioService('adservice')
        found_availability_slo = self.checkForSlo(
            adservice_id, 'adservice-availability-slo')
        self.assertTrue(found_availability_slo)
        found_latency_slo = self.checkForSlo(adservice_id, 'adservice-latency-slo')
        self.assertTrue(found_latency_slo)

    def testRatingServiceSloExists(self):
        """ Test the rating service for having two SLOs (availability, latency) get created. """
        service_id = 'gae:' + project_id + '_ratingservice'
        found_availability_slo = self.checkForSlo(
            service_id, 'ratingservice-availability-slo')
        self.assertTrue(found_availability_slo)
        found_latency_slo = self.checkForSlo(service_id, 'ratingservice-latency-slo')
        self.assertTrue(found_latency_slo)


class TestSloAlertPolicy(unittest.TestCase):
    def setUp(self):
        self.client = monitoring_v3.AlertPolicyServiceClient()

    def checkForAlertingPolicy(self, policy_display_name):
        policies = self.client.list_alert_policies(project_name)
        for policy in policies:
            if policy.display_name == policy_display_name:
                return True
        return False

    def testFrontendServiceSloAlertExists(self):
        """ Test that the Alerting Policies for the Frontend Service SLO get created. """
        found_availability_alert = self.checkForAlertingPolicy(
            'Frontend Service Availability Alert Policy')
        self.assertTrue(found_availability_alert)
        found_latency_alert = self.checkForAlertingPolicy(
            'Frontend Service Latency Alert Policy')
        self.assertTrue(found_latency_alert)

    def testCheckoutServiceSloAlertExists(self):
        """ Test that the Alerting Policies for the Checkout Service SLO get created. """
        found_availability_alert = self.checkForAlertingPolicy(
            'Checkout Service Availability Alert Policy')
        self.assertTrue(found_availability_alert)
        found_latency_alert = self.checkForAlertingPolicy(
            'Checkout Service Latency Alert Policy')
        self.assertTrue(found_latency_alert)

    def testPaymentServiceSloAlertExists(self):
        """ Test that the Alerting Policies for the Payment Service SLO get created. """
        found_availability_alert = self.checkForAlertingPolicy(
            'Payment Service Availability Alert Policy')
        self.assertTrue(found_availability_alert)
        found_latency_alert = self.checkForAlertingPolicy(
            'Payment Service Latency Alert Policy')
        self.assertTrue(found_latency_alert)

    def testEmailServiceSloAlertExists(self):
        """ Test that the Alerting Policies for the Email Service SLO get created. """
        found_availability_alert = self.checkForAlertingPolicy(
            'Email Service Availability Alert Policy')
        self.assertTrue(found_availability_alert)
        found_latency_alert = self.checkForAlertingPolicy(
            'Email Service Latency Alert Policy')
        self.assertTrue(found_latency_alert)

    def testShippingServiceSloAlertExists(self):
        """ Test that the Alerting Policies for the Shipping Service SLO get created. """
        found_availability_alert = self.checkForAlertingPolicy(
            'Shipping Service Availability Alert Policy')
        self.assertTrue(found_availability_alert)
        found_latency_alert = self.checkForAlertingPolicy(
            'Shipping Service Latency Alert Policy')
        self.assertTrue(found_latency_alert)

    def testCartServiceSloAlertExists(self):
        """ Test that the Alerting Policies for the Cart Service SLO get created. """
        found_availability_alert = self.checkForAlertingPolicy(
            'Cart Service Availability Alert Policy')
        self.assertTrue(found_availability_alert)
        found_latency_alert = self.checkForAlertingPolicy(
            'Cart Service Latency Alert Policy')
        self.assertTrue(found_latency_alert)

    def testProductCatalogServiceSloAlertExists(self):
        """ Test that the Alerting Policies for the Product Catalog Service SLO get created. """
        found_availability_alert = self.checkForAlertingPolicy(
            'Product Catalog Service Availability Alert Policy')
        self.assertTrue(found_availability_alert)
        found_latency_alert = self.checkForAlertingPolicy(
            'Product Catalog Service Latency Alert Policy')
        self.assertTrue(found_latency_alert)

    def testCurrencyServiceSloAlertExists(self):
        """ Test that the Alerting Policies for the Currency Service SLO get created. """
        found_availability_alert = self.checkForAlertingPolicy(
            'Currency Service Availability Alert Policy')
        self.assertTrue(found_availability_alert)
        found_latency_alert = self.checkForAlertingPolicy(
            'Currency Service Latency Alert Policy')
        self.assertTrue(found_latency_alert)

    def testRecommendationServiceSloAlertExists(self):
        """ Test that the Alerting Policies for the Recommendation Service SLO get created. """
        found_availability_alert = self.checkForAlertingPolicy(
            'Recommendation Service Availability Alert Policy')
        self.assertTrue(found_availability_alert)
        found_latency_alert = self.checkForAlertingPolicy(
            'Recommendation Service Latency Alert Policy')
        self.assertTrue(found_latency_alert)

    def testAdServiceSloAlertExists(self):
        """ Test that the Alerting Policies for the Frontend Service SLO get created. """
        found_availability_alert = self.checkForAlertingPolicy(
            'Ad Service Availability Alert Policy')
        self.assertTrue(found_availability_alert)
        found_latency_alert = self.checkForAlertingPolicy(
            'Ad Service Latency Alert Policy')
        self.assertTrue(found_latency_alert)


if __name__ == '__main__':
    project_id = getProjectId()
    project_name = project_name + project_id
    unittest.main(argv=['first-arg-is-ignored'])
