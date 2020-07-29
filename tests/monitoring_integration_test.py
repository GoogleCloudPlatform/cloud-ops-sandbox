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

from google.cloud import monitoring_v3
from google.cloud.monitoring_dashboard import v1

project_name = 'projects/'

def getProjectId():
  """Retreieves the project id from the environment variable.
  Raises:
      MissingProjectIdError -- When not set.
  Returns:
      str -- the project name
  """
  project_id = os.environ['GOOGLE_CLOUD_PROJECT']

  if not project_id:
      raise MissingProjectIdError(
          'Set the environment variable ' +
          'GCLOUD_PROJECT to your Google Cloud Project Id.')
  return project_id

class TestUptimeCheck(unittest.TestCase):

	external_ip = ''

	@classmethod
	def setUpClass(cls):
		""" Retrieve the external IP of the cluster """
		process = subprocess.run(["kubectl", "-n", "istio-system", "get", "service", "istio-ingressgateway", "-o", "jsonpath='{.status.loadBalancer.ingress[0].ip}'"], encoding='utf-8', capture_output=True)
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
		found_dash = self.checkForDashboard('User Experience Dashboard')
		self.assertTrue(found_dash)

	def testAdServiceDashboard(self):
		"""" Test that the Ad Service Dashboard gets created. """
		found_dash = self.checkForDashboard('Ad Service Dashboard')
		self.assertTrue(found_dash)

	def testRecommendationServiceDashboard(self):
		"""" Test that the Recommendation Service Dashboard gets created. """
		found_dash = self.checkForDashboard('Recommendation Service Dashboard')

  def testFrontendServiceDashboard(self):
		""" Test that the Frontend Service Dashboard gets created. """
		found_dash = self.checkForDashboard('Frontend Service Dashboard')
		self.assertTrue(found_dash)

if __name__ == '__main__':
	project_name = project_name + getProjectId()
	unittest.main()
