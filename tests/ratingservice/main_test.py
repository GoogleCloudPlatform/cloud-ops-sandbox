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
import sys
import unittest
import requests
import json
import decimal


service_url = ''
products = []


class TestEndpoints(unittest.TestCase):

    def composeUrl(self, resource, eid=""):
        if not eid:
            return "{0}/{1}".format(service_url, resource)
        else:
            return "{0}/{1}/{2}".format(service_url, resource, eid)

    def testGetRating(self):
        """ test getting ratings for all shop products """
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

        data = result1.json()
        prev_vote = data['votes']
        prev_rating = decimal.Decimal(data['rating'])
        data = result2.json()
        new_vote = data['votes']
        new_rating = decimal.Decimal(data['rating'])
        self.assertEqual(new_vote, prev_vote + 1)
        expected_rating = prev_rating + \
            ((new_rating_vote-prev_rating)/(prev_vote+1))
        # compare expected result rounded to 4 decimal places
        QUANTIZE_VALUE = decimal.Decimal("0.0001")
        self.assertEqual(new_rating.quantize(QUANTIZE_VALUE),
                         expected_rating.quantize(QUANTIZE_VALUE))


def getServiceUrl():
    if len(sys.argv) > 1:
        url = sys.argv[1]
        return url.rstrip('/')
    return None


def getProducts():
    path = os.getcwd().rstrip('/') + '/src/productcatalogservice/products.json'
    if len(sys.argv) > 2:
        path = sys.argv[2]
    ids = []
    try:
        with open(path) as f:
            data = json.load(f)
            for product in data['products']:
                ids.append(product['id'])
    except:
        print("failed to load product ids from ", path)
        return []
    return ids


if __name__ == '__main__':
    service_url = getServiceUrl()
    products = getProducts()
    unittest.main(argv=['first-arg-is-ignored'], verbosity=2)
