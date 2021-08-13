#!/usr/bin/env python

# Copyright 2021 Google Inc. All rights reserved.
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

import random
from locust import task, between, HttpUser


PRODUCTS = [
    '0PUK6V6EV0',  # Vintage Record Player
    '1YMWWN1N4O',  # Home Barista Kit
    '2ZYFJ3GM2N',  # Film Camera
    '66VCHSJNUP',  # Vintage Camera Lens
    '6E92ZMYYFZ',  # Air Plant
    '9SIQT8TOJO',  # City Bike
    'L9ECAV7KIM',  # Terrarium
    'LS4PSXUNUM',  # Metal Camping Mug
    'OLJCESPC7Z',  # Vintage Typewriter
]


class BasicHomePageViewingUser(HttpUser):
    """
    A user that simply visits the home page.
    This load pattern is useful for SRE Recipes that want to expose
    potential bugs or high page load latency in the frontend.
    """
    sre_recipe_user_identifier = "BasicHomePageViewingUser"

    # wait between 1 and 10 seconds after each task
    wait_time = between(1, 10)

    @task
    def visit_home_page(self):
        self.client.get("/")


class BasicPurchasingUser(HttpUser):
    """
    A user behavior flow that generates loads to simulate the minimal set
    of behaviors needed for checkout. This load pattern is useful for SRE
    Recipes that want to expose potential bugs in cart and checkout services.
    """
    # User Identifier for use by SRE Recipes
    sre_recipe_user_identifier = "BasicPurchasingUser"

    # wait between 1 and 10 seconds after each task
    wait_time = between(1, 10)

    @task
    def buy_random_product_and_checkout(self):
        # visit home page
        self.client.get("/")

        # add a random product with a random quality to shopping cart
        self.client.post("/cart", {
            'product_id': random.choice(PRODUCTS),
            'quantity': random.randint(1, 10)
        })

        # check out
        self.client.post("/cart/checkout", {
            'email': 'someone@example.com',
            'street_address': '1600 Amphitheatre Parkway',
            'zip_code': '94043',
            'city': 'Mountain View',
            'state': 'CA',
            'country': 'United States',
            'credit_card_number': '1111-1111-1111-1111',
            'credit_card_expiration_month': '1',
            'credit_card_expiration_year': '2039',
            'credit_card_cvv': '672',
        })
