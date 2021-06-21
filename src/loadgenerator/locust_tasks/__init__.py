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

from . import basic_locustfile as basic_locust_tasks
from . import step_locustfile as step_locust_tasks
from . import sre_recipe_load_tasks

USER_FACING_LOCUST_USER_CLASSES = {
    "basic": [
        basic_locust_tasks.PurchasingUser,
        basic_locust_tasks.WishlistUser,
        basic_locust_tasks.BrowsingUser,
    ],
    "step": [
        step_locust_tasks.PurchasingUser,
        step_locust_tasks.WishlistUser,
        step_locust_tasks.BrowsingUser,
    ]
}

SRE_RECIPE_USER_CLASSES = {
    x.sre_recipe_user_identifier: x
    for x in [
        sre_recipe_load_tasks.BasicHomePageViewingUser,
        sre_recipe_load_tasks.BasicPurchasingUser,
    ]
}

USER_FACING_LOCUST_LOAD_SHAPE = {
    "basic": None,  # use default locust shape class
    "step": step_locust_tasks.StepLoadShape()
}


def get_user_classes(task_type):
    return USER_FACING_LOCUST_USER_CLASSES.get(task_type, [])


def get_sre_recipe_user_class(user_identifier):
    return SRE_RECIPE_USER_CLASSES.get(user_identifier, None)


def get_load_shape(task_type):
    return USER_FACING_LOCUST_LOAD_SHAPE.get(task_type, None)
