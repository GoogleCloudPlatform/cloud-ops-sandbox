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

from google.cloud import monitoring_v3
from google.cloud.monitoring_dashboard import v1

project_id = ''
project_name = 'projects/'

def getProjectId():
    """Retrieves the project id from the environment variable.
    Raises:
        MissingProjectIdError -- When not set.
    Returns:
        str -- the project name
    """
    project_id = os.environ['GOOGLE_CLOUD_PROJECT']

    if not project_id:
        raise MissingProjectIdError(
            'Set the environment variable ' +
            'GOOGLE_CLOUD_PROJECT to your Google Cloud Project Id.')
    return project_id

def cleanupDashboards():
    """ Deletes all dashboards. """
    client = v1.DashboardsServiceClient()
    dashboards = client.list_dashboards(project_name)
    for dashboard in dashboards:
        try:
            client.delete_dashboard(dashboard.name)
        except:
            print('Could not delete dashboard: ' + dashboard.name)

def cleanupPolicies():
    """ Delete all alerting policies for both uptime checks and SLOs. """
    client = monitoring_v3.AlertPolicyServiceClient()
    policies = client.list_alert_policies(project_name)
    for policy in policies:
        try:
            client.delete_alert_policy(policy.name)
        except:
            print('Could not delete alerting policy: ' + policy.name)

def cleanupNotificationChannels():
    """ Deletes all notification channels. """
    client = monitoring_v3.NotificationChannelServiceClient()
    channels = client.list_notification_channels(project_name)
    for channel in channels:
        client.delete_notification_channel(channel.name)

def cleanupServices():
    """ Deletes only custom services that are identified by a trailing 'srv' in the name. """
    client = monitoring_v3.ServiceMonitoringServiceClient()
    services = client.list_services(project_name)
    for service in services:
        if service.name.endswith("srv"): # Only delete the custom services
            try:
                client.delete_service(service.name)
            except:
                print('Could not delete service: ' + service.name)

def cleanupSlos():
    """ Deletes every SLO associated with every service. """
    client = monitoring_v3.ServiceMonitoringServiceClient()
    services = client.list_services(project_name)
    for service in services:
        slos = client.list_service_level_objectives(service.name)
        for slo in slos:
            try:
                client.delete_service_level_objective(slo.name)
            except:
                print('Could not delete SLO: ' + slo.name)

def cleanupUptimeCheck():
    """ Deletes every uptime check. """
    client = monitoring_v3.UptimeCheckServiceClient()
    uptime_checks = client.list_uptime_check_configs(project_name)
    for check in uptime_checks:
        try:
            client.delete_uptime_check_config(check.name)
        except:
            print('Could not delete uptime check: ' + check.name)

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
