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
from google.cloud.monitoring_dashboard import v1

project_id = ''
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
        exit('Missing Project ID. Usage: python3 cleanup_monitoring.py $PROJECT_ID')

    return project_id

def cleanupDashboards():
    """ Deletes all dashboards. """
    client = v1.DashboardsServiceClient()
    dashboards = list(client.list_dashboards(project_name))
    while (len(dashboards) != 0):
        for dashboard in dashboards:
            try:
                client.delete_dashboard(dashboard.name)
            except:
                print('Could not delete dashboard: ' + dashboard.name)
        dashboards = list(client.list_dashboards(project_name))

def cleanupPolicies():
    """ Delete all alerting policies for both uptime checks and SLOs. """
    client = monitoring_v3.AlertPolicyServiceClient()
    policies = list(client.list_alert_policies(project_name))
    while (len(policies) != 0):
        for policy in policies:
            try:
                client.delete_alert_policy(policy.name)
            except:
                print('Could not delete alerting policy: ' + policy.name)
        policies = list(client.list_alert_policies(project_name))

def cleanupNotificationChannels():
    """ Deletes all notification channels. """
    client = monitoring_v3.NotificationChannelServiceClient()
    channels = list(client.list_notification_channels(project_name))
    while (len(channels) != 0):
        for channel in channels:
            try:
                client.delete_notification_channel(channel.name)
            except:
                print('Could not delete notification channel: ' + channel.name)
        channels = list(client.list_notification_channels(project_name))

def cleanupServices():
    """ Deletes only custom services that are identified by a trailing 'srv' in the name. """
    client = monitoring_v3.ServiceMonitoringServiceClient()
    # only delete custom services
    custom_services = [s for s in client.list_services(project_name) if s.name.endswith("srv")]
    while (len(custom_services) != 0):
        for service in custom_services:
            try:
                client.delete_service(service.name)
            except:
                print('Could not delete service: ' + service.name)
        custom_services = [s for s in client.list_services(project_name) if s.name.endswith("srv")]

def cleanupSlos():
    """ Deletes every SLO associated with every service. """
    client = monitoring_v3.ServiceMonitoringServiceClient()
    slos = [slo for service in client.list_services(project_name) for slo in client.list_service_level_objectives(service.name)]
    while (len(slos) != 0):
        for slo in slos:
            try:
                client.delete_service_level_objective(slo.name)
            except:
                print('Could not delete SLO: ' + slo.name)
        slos = [slo for service in client.list_services(project_name) for slo in client.list_service_level_objectives(service.name)]

def cleanupUptimeCheck():
    """ Deletes every uptime check. """
    client = monitoring_v3.UptimeCheckServiceClient()
    uptime_checks = list(client.list_uptime_check_configs(project_name))
    while (len(uptime_checks) != 0):
        for check in uptime_checks:
            try:
                client.delete_uptime_check_config(check.name)
            except:
                print('Could not delete uptime check: ' + check.name)
        uptime_checks = list(client.list_uptime_check_configs(project_name))

def doCleanup():
    """ Ensures that resources are deleted in the proper order so no exceptions are thrown. """
    cleanupDashboards()
    cleanupPolicies()
    cleanupNotificationChannels()
    cleanupSlos()
    cleanupServices()
    cleanupUptimeCheck()

if __name__ == '__main__':
    project_id = getProjectId()
    project_name = project_name + project_id
    doCleanup()
