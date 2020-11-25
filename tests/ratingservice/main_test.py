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
from requests.adapters import HTTPAdapter
import json
import decimal


service_url = ''
products = []
TIMEOUT = 5.0


def composeUrl(resource, eid=""):
    if not eid:
        return "{0}/{1}".format(service_url, resource)
    else:
        return "{0}/{1}/{2}".format(service_url, resource, eid)


class TestEndpoints(unittest.TestCase):

    def setUp(self):
        self.session = requests.Session()
        adapter = HTTPAdapter(max_retries=3)
        self.session.mount('https://', adapter)

    def tearDown(self):
        self.session.close()

    def testGetAllRatings(self):
        """ test getting all ratings """
        url = composeUrl("ratings")
        res = self.session.get(url, timeout=TIMEOUT)
        self.assertEqual(res.status_code, 200)
        ratings = res.json().get('ratings')
        self.assertTrue(type(ratings) == list)
        ids = [r['id'] for r in ratings]
        self.assertEqual(set(ids), set(products))

    def testGetProductRating(self):
        """ test getting ratings for a shop product """
        # use products[0] in "get product rating" test
        test_product_id = products[0]
        url = composeUrl("rating", test_product_id)
        res = self.session.get(url, timeout=TIMEOUT)
        self.assertEqual(res.status_code, 200)

    def testGetRatingNotExist(self):
        """ test getting rating for non-exist product """
        url = composeUrl("rating", "random")
        res = self.session.get(url, timeout=TIMEOUT)
        self.assertEqual(res.status_code, 404)

    def testPostNewRating(self):
        """ test posting new rating to a product """
        # use products[1] in "post new vote" test
        test_product_id = products[1]
        url = composeUrl("rating")
        res = self.session.post(url, timeout=TIMEOUT, json={
            'rating': 5,
            'id': test_product_id
        })
        self.assertEqual(res.status_code, 200)

    def testNewRatingCalculation(self):
        """ test rating calculation after recollection """
        # use products[2] to avoid counting new vote from testRate() test
        test_product_id = products[2]
        new_rating_vote = 5
        url_get = composeUrl("rating", test_product_id)
        url_post = composeUrl("rating")
        url_put = composeUrl("recollect")

        # get current rating / post new vote / recollect / get updated rating
        result1 = self.session.get(url_get, timeout=TIMEOUT)
        self.assertEqual(result1.status_code, 200)
        result2 = self.session.post(url_post, timeout=1.0, json={
            'rating': new_rating_vote,
            'id': test_product_id
        })
        self.assertEqual(result2.status_code, 200)
        result2 = self.session.put(url_put, timeout=TIMEOUT)
        self.assertEqual(result2.status_code, 200)
        result2 = self.session.get(url_get, timeout=TIMEOUT)
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
    unittest.main(argv=['first-arg-is-ignored'])
