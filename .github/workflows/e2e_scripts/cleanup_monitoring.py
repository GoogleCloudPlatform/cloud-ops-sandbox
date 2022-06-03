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
import os
import sys

from google.cloud import monitoring_v3
from google.cloud import logging_v2
from google.cloud.monitoring_dashboard import v1

def cleanupDashboards(project_name):
    """ Deletes all dashboards. """
    client = v1.DashboardsServiceClient()
    dashboards = True
    while dashboards:
        dashboards = list(client.list_dashboards(project_name))
        for dashboard in dashboards:
            try:
                client.delete_dashboard(dashboard.name)
            except:
                print('Could not delete dashboard: ' + dashboard.name)

def cleanupLogBasedMetrics(project_name):
    """ Deletes all log-based metrics. """
    client = logging_v2.Client()
    for metric in client.list_metrics():
        try:
            metric.delete(metric)
        except:
            print(f'Could not delete metric: {metric}')

def cleanupPolicies(project_name):
    """ Delete all alerting policies for both uptime checks and SLOs. """
    client = monitoring_v3.AlertPolicyServiceClient()
    policies = True
    while policies:
        policies = list(client.list_alert_policies(project_name))
        for policy in policies:
            try:
                client.delete_alert_policy(policy.name)
            except:
                print('Could not delete alerting policy: ' + policy.name)

def cleanupNotificationChannels(project_name):
    """ Deletes all notification channels. """
    client = monitoring_v3.NotificationChannelServiceClient()
    channels = True
    while channels:
        channels = list(client.list_notification_channels(project_name))
        for channel in channels:
            try:
                client.delete_notification_channel(channel.name)
            except:
                print('Could not delete notification channel: ' + channel.name)

def cleanupServices(project_name):
    """ Deletes only custom services that are identified by a trailing 'srv' in the name. """
    client = monitoring_v3.ServiceMonitoringServiceClient()
    # only delete custom services
    custom_services = True
    while custom_services:
        custom_services = [s for s in client.list_services(project_name) if s.name.endswith("srv")]
        for service in custom_services:
            try:
                client.delete_service(service.name)
            except:
                print('Could not delete service: ' + service.name)

def cleanupSlos(project_name):
    """ Deletes every SLO associated with every service. """
    client = monitoring_v3.ServiceMonitoringServiceClient()
    slos = True
    while slos:
        slos = [slo for service in client.list_services(project_name) 
                    for slo in client.list_service_level_objectives(service.name)]
        for slo in slos:
            try:
                client.delete_service_level_objective(slo.name)
            except:
                print('Could not delete SLO: ' + slo.name)

def cleanupUptimeCheck(project_name):
    """ Deletes every uptime check. """
    client = monitoring_v3.UptimeCheckServiceClient()
    uptime_checks = True
    while uptime_checks:
        uptime_checks = list(client.list_uptime_check_configs(project_name))
        for check in uptime_checks:
            try:
                client.delete_uptime_check_config(check.name)
            except:
                print('Could not delete uptime check: ' + check.name)
        

def doCleanup(project_name):
    """ Ensures that resources are deleted in the proper order so no exceptions are thrown. """
    cleanupDashboards(project_name)
    cleanupLogBasedMetrics(project_name)
    cleanupPolicies(project_name)
    cleanupNotificationChannels(project_name)
    cleanupSlos(project_name)
    cleanupServices(project_name)
    cleanupUptimeCheck(project_name)

if __name__ == '__main__':
    project_name = ''
    try:
        project_name = sys.argv[1]
    except:
        exit('Missing Project Name. Usage: python3 cleanup_monitoring.py $project_name')
    doCleanup(project_name)
