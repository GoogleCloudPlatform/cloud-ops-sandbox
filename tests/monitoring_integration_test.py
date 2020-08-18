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

from google.cloud import monitoring_v3
from google.cloud.monitoring_dashboard import v1

project_name = 'projects/'

def getProjectId():
    """Retrieves the project id from the script arguments.
    Returns:
        str -- the project name
    Exits when project id is not set
    """
    try:
        project_id = sys.argv[1]
    except:
        exit('Missing Project ID. Usage: python3 monitoring_integration_test.py $PROJECT_ID')

    return project_id

class TestUptimeCheck(unittest.TestCase):

	external_ip = ''

	@classmethod
	def setUpClass(cls):
		""" Retrieve the external IP of the cluster """
		process = subprocess.run(["kubectl", "-n", "istio-system", "get", "service", "istio-ingressgateway", "-o", "jsonpath='{.status.loadBalancer.ingress[0].ip}'"], capture_output=True)
		cls.external_ip = process.stdout.replace('\'', '')

	def testNumberOfUptimeChecks(self):
		"""" Test that ensures there is only one uptime check created """
		client = monitoring_v3.UptimeCheckServiceClient()
		configs = client.list_uptime_check_configs(project_name)
		config_list = []
		for config in configs:
			config_list.append(config)

		self.assertEqual(len(config_list), 1)

	def testUptimeCheckName(self):
		""" Verifies the configured IP address of the uptime check matches the external IP
				address of the cluster """
		client = monitoring_v3.UptimeCheckServiceClient()
		configs = client.list_uptime_check_configs(project_name)
		config_list = []
		for config in configs:
			config_list.append(config)

		config = config_list[0]
		self.assertEqual(config.monitored_resource.labels["host"], self.__class__.external_ip)

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
		""" Test that our single notification channel was created. """
		client = monitoring_v3.NotificationChannelServiceClient()
		channels = client.list_notification_channels(project_name)
		channel_list = []
		for channel in channels:
			channel_list.append(channel)

		self.assertEqual(len(channel_list), 1)

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
		found_dashboard = self.checkForDashboard('Recommendation Service Dashboard')
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

class TestCustomService(unittest.TestCase):
	def setUp(self):
		self.client = monitoring_v3.ServiceMonitoringServiceClient()
		self.project_id = getProjectId()

	def checkForService(self, service_name):
		name = self.client.service_path(self.project_id, service_name)
		return self.client.get_service(name)

	def testFrontendServiceExists(self):
		""" Test that the Frontend Custom Service gets created. """
		response = self.checkForService('frontend-srv')
		# check that we found an object
		self.assertTrue(response)

class TestServiceSlo(unittest.TestCase):
	def setUp(self):
		self.client = monitoring_v3.ServiceMonitoringServiceClient()
		self.project_id = getProjectId()

	def checkForSlo(self, service, slo):
		name = self.client.service_level_objective_path(self.project_id, service, slo)
		return self.client.get_service_level_objective(name)

	def testFrontendServiceSloExists(self):
		""" Test that for each service that two SLOs (availability, latency) get created. """
		found_availability_slo = self.checkForSlo('frontend-srv', 'availability-slo')
		self.assertTrue(found_availability_slo)
		found_latency_slo = self.checkForSlo('frontend-srv', 'latency-slo')
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
		found_availability_alert = self.checkForAlertingPolicy('Frontend Service Availability Alert Policy')
		self.assertTrue(found_availability_alert)
		found_latency_alert = self.checkForAlertingPolicy('Frontend Service Latency Alert Policy')
		self.assertTrue(found_latency_alert)

if __name__ == '__main__':
	project_name = project_name + getProjectId()
	unittest.main(argv=['first-arg-is-ignored'])
