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
This module contains a Locust app running in library mode.
"""
import sys
import gevent
import traceback

from locust import HttpUser
from locust import task
from locust.stats import stats_history
from locust.env import Environment

from absl import app
from absl import flags
FLAGS = flags.FLAGS

from init import initialize
from sre_recipe_utils import init_sre_recipe_api
from locust_tasks import get_user_classes
from locust_tasks import get_load_shape

from logger import getJSONLogger
logger = getJSONLogger('locust-server')

try:
    import googleclouddebugger
    googleclouddebugger.enable(
        module='locust-server',
        version='1.0.0'
    )
except ImportError:
    logger.warning("Could not enable cloud debugger")
    logger.warning(traceback.print_exc())
    pass


def setup_locust_environment(host_target,
                             user_classes,
                             shape_class,
                             headless,
                             web_host,
                             web_port,
                             is_master,
                             master_bind_host,
                             master_bind_port,
                             is_worker,
                             master_host,
                             master_port,
                             start_web_ui_now):
    # Create a Locust Environment
    env = Environment(
        host=host_target, user_classes=user_classes, shape_class=shape_class)

    # Setup Locust Runner
    if is_master:
        if is_worker:
            logger.error(
                "Locust cannot be started as both a master and a worker")
            sys.exit(-1)
        env.create_master_runner(master_bind_host, master_bind_port)
        logger.info("Created master locust runner")
    elif is_worker:
        env.create_worker_runner(master_host, master_port)
        logger.info("Created worker locust runner")
    else:
        env.create_local_runner()
        logger.info("Created local locust runner")

    # Start a greenlet that periodically saves runner's stats to its history
    gevent.spawn(stats_history, env.runner)

    # Only start web UI if it is not headless and not in worker mode
    if not headless and not is_worker:
        env.create_web_ui(host=web_host, port=web_port,
                          delayed_start=(not start_web_ui_now))

    return env


def main(argv):
    logger.info("Initialing locust in library mode")

    # Setup User Facing Locust Environment
    logger.info(
        f"Setting up user facing Locust server with {FLAGS.task} tasks")

    env = setup_locust_environment(
        host_target=FLAGS.host,
        user_classes=get_user_classes(FLAGS.task),
        shape_class=get_load_shape(FLAGS.task),
        headless=FLAGS.headless,
        web_host=FLAGS.web_host,
        web_port=FLAGS.web_port,
        is_master=FLAGS.master,
        master_bind_host=FLAGS.master_bind_host,
        master_bind_port=FLAGS.master_bind_port,
        is_worker=FLAGS.worker,
        master_host=FLAGS.master_host,
        master_port=FLAGS.master_port,
        start_web_ui_now=True)

    if env.web_ui is not None:
        user_facing_web_address = f"http://{FLAGS.web_host}:{FLAGS.web_port}"
        logger.info(
            f"User facing Locust listening on {user_facing_web_address}")

    # Setup SRE Recipe Facing Locust Environment
    logger.info("Setting up SRE Recipe facing Locust server")
    env_sre_recipe = setup_locust_environment(
        host_target=FLAGS.host,
        user_classes=[],
        shape_class=None,
        # we always need a flask app for SRE Recipe in order to have a functional API
        headless=False,
        web_host=FLAGS.web_host_sre_recipe,
        web_port=FLAGS.web_port_sre_recipe,
        is_master=FLAGS.master_sre_recipe,
        master_bind_host=FLAGS.master_bind_host_sre_recipe,
        master_bind_port=FLAGS.master_bind_port_sre_recipe,
        is_worker=FLAGS.worker_sre_recipe,
        master_host=FLAGS.master_host_sre_recipe,
        master_port=FLAGS.master_port_sre_recipe,
        # delay staring the web UI, so we can inject new request handlers
        start_web_ui_now=False)

    if env_sre_recipe.web_ui is not None:
        init_sre_recipe_api(env_sre_recipe.web_ui)

        env_sre_recipe.web_ui.start()

        sre_recipe_web_address = (
            f"http://{FLAGS.web_host_sre_recipe}:{FLAGS.web_port_sre_recipe}"
        )
        logger.info(
            f"SRE Recipe facing Locust listening on {sre_recipe_web_address}")

    # wait for the web app to shutdown
    env.runner.greenlet.join()
    env_sre_recipe.runner.greenlet.join()


if __name__ == '__main__':
    initialize()
    app.run(main)
