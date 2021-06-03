# Copyright 2021 Google LLC
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

# -*- coding: utf-8 -*-
"""
This module contains code for initialization logics such as defining command
line flags and arguments.
"""

from absl import flags


def define_user_locust_flags():
    """Flags for user facing Locust server"""
    flags.DEFINE_enum('task', 'basic', ['basic', 'step'],
                      'The default locust tasks, user types, and load shapes to'
                      'spawn for user-facing Locust. It needs to be implemented'
                      'in the "locust_tasks" folder. Defaults to basic.')
    flags.DEFINE_boolean(
        'headless', False, 'Start user facing Locust without web interface')
    flags.DEFINE_string('web_host', "0.0.0.0",
                        'Hostname/IP for user facing locust web UI. '
                        'Defaults to 0.0.0.0')
    flags.DEFINE_integer('web_port', 8089,
                         'Port number that the user facing locust web UI '
                         'will listen to. Defaults to 8089')

    # Redefine command line flags for running locust in distributed mode:
    # https://docs.locust.io/en/stable/running-locust-distributed.html
    flags.DEFINE_boolean(
        'master', False, 'Running user facing locust as a master runner')
    flags.DEFINE_string('master_bind_host', "*",
                        'What network interface that the master node will bind '
                        'to for user facing locust server. '
                        'Defaults to *: all available interfaces.')
    flags.DEFINE_integer('master_bind_port', 5557,
                         'Port number that the master node will listen to for '
                         'user facing locust server. Defaults to 5557.')

    flags.DEFINE_boolean(
        'worker', False, 'Running user facing locust as a worker runner')
    flags.DEFINE_string('master_host', "127.0.0.1",
                        'Hostname of the master node for user facing locust.'
                        'Defaults to 127.0.0.1')
    flags.DEFINE_integer('master_port', 5557,
                         'Port number of the master for user facing locust.'
                         'Defaults to 5557.')


def define_sre_recipe_locust_flags():
    """Flags for SRE Recipe facing Locust server"""
    flags.DEFINE_string('web_host_sre_recipe', "0.0.0.0",
                        'Hostname/IP for SRE Recipe facing locust web UI. '
                        'Defaults to 0.0.0.0')
    flags.DEFINE_integer('web_port_sre_recipe', 8090,
                         'Port number that the SRE Recipe facing locust web UI '
                         'will listen to. Defaults to 8090')

    # Redefine command line flags for running locust in distributed mode:
    # https://docs.locust.io/en/stable/running-locust-distributed.html
    flags.DEFINE_boolean(
        'master_sre_recipe', False,
        'Running SRE Recipe facing locust as a master runner')
    flags.DEFINE_string('master_bind_host_sre_recipe', "*",
                        'What network interface that the master node will bind '
                        'to for SRE Recipe facing locust server. '
                        'Defaults to *: all available interfaces.')
    flags.DEFINE_integer('master_bind_port_sre_recipe', 5558,
                         'Port number that the master node will listen to for '
                         'SRE Recipe facing locust server. Defaults to 5558.')

    flags.DEFINE_boolean(
        'worker_sre_recipe', False,
        'Running SRE Recipe facing locust as a worker runner')
    flags.DEFINE_string('master_host_sre_recipe', "127.0.0.1",
                        'Hostname of the master for SRE Recipe facing locust.'
                        'Defaults to 127.0.0.1')
    flags.DEFINE_integer('master_port_sre_recipe', 5558,
                         'Port of the master for SRE Recipe facing locust.'
                         'Defaults to 5558.')


def initialize():
    """Initialize flags supported by our Locust instance in library mode"""
    flags.DEFINE_string('host', None,
                        'Base URL of the target system to send load to')
    flags.mark_flag_as_required("host")

    define_user_locust_flags()
    define_sre_recipe_locust_flags()
