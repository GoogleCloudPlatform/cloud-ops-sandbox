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

import os
import unittest
import requests
import json
import math


class TestEndpoints(unittest.TestCase):

    def __init__(self, *args, **kwargs):
        self.service_host_url = os.environ.get('RATING_SERVICE_URL')
        if not self.service_host_url:
            self.service_host_url = "https://ratingservice-dot-{0}.wl.r.appspot.com".format(
                os.environ['GOOGLE_CLOUD_PROJECT'])
        self.service_host_url = self.service_host_url.rstrip('/')
        super(TestEndpoints, self).__init__(*args, **kwargs)

    def composeUrl(self, request, arg1=""):
        if arg1 != "":
            return "{0}/{1}/{2}".format(self.service_host_url, request, arg1)
        else:
            return "{0}/{1}".format(self.service_host_url, request)

    def testGetRating(self):
        """ test getting ratings for all shop products """
        products = read_products()
        for product in products:
            url = self.composeUrl("rating", product)
            res = requests.get(url)
            self.assertEqual(res.status_code, 200)

    def testGetRatingNotExist(self):
        """ test getting rating for non-exist product """
        url = self.composeUrl("rating", "random")
        res = requests.get(url)
        self.assertEqual(res.status_code, 404)

    def testPostNewRating(self):
        """ test posting new rating to a product """
        products = read_products()
        # use products[0] in "post new vote" test
        test_product_id = products[0]
        url = self.composeUrl("rating")
        res = requests.post(url, json={
            'rating': 5,
            'id': test_product_id
        })
        self.assertEqual(res.status_code, 200)

    def testNewRatingCalculation(self):
        """ test rating calculation after recollection """
        products = read_products()
        # use products[1] to avoid counting new vote from testRate() test
        test_product_id = products[1]
        new_rating_vote = 5
        url_get = self.composeUrl("rating", test_product_id)
        url_post = self.composeUrl("rating")
        url_put = self.composeUrl("recollect")

        # get current rating / post new vote / recollect / get updated rating
        result1 = requests.get(url_get)
        self.assertEqual(result1.status_code, 200)
        result2 = requests.post(url_post, json={
            'rating': new_rating_vote,
            'id': test_product_id
        })
        self.assertEqual(result2.status_code, 200)
        result2 = requests.put(url_put)
        self.assertEqual(result2.status_code, 200)
        result2 = requests.get(url_get)
        self.assertEqual(result2.status_code, 200)

        result1_data = result1.json()
        result2_data = result2.json()
        self.assertEqual(result2_data['votes'],
                         result1_data['votes'] + 1)

        # new rating should be: old_rating+((5.0-old_rating)/(old_num_of_votes+1))
        new_rating = result1_data['rating'] + \
            ((new_rating_vote - result1_data['rating']) /
             (result1_data['votes'] + 1))
        # compare new rating vs. expected which was rounded to 4 digits after floating point
        self.assertEqual(math.ceil(result2_data['rating']*10000)/10000,
                         math.ceil(new_rating*10000)/10000)


def read_products():
    """ read shop products from json file """
    res = []
    with open('../../src/productcatalogservice/products.json') as f:
        data = json.load(f)
        for product in data['products']:
            res.append(product['id'])
    return res


if __name__ == '__main__':
    unittest.main(verbosity=2)
