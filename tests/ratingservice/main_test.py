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
from requests.exceptions import RequestException
from urllib3.exceptions import ReadTimeoutError
import json
import decimal


class TestEndpoints(unittest.TestCase):

    @classmethod
    def composeUrl(cls, resource, eid=""):
        if not eid:
            return "{0}/{1}".format(cls.service_url, resource)
        else:
            return "{0}/{1}/{2}".format(cls.service_url, resource, eid)

    @classmethod
    def setUpClass(cls):
        cls.TIMEOUT = 5.0

        cls.service_url = ''
        if len(sys.argv) > 1:
            cls.service_url = sys.argv[1].rstrip('/')

        cls.products = []
        path = os.getcwd().rstrip('/') + '/src/productcatalogservice/products.json'
        if len(sys.argv) > 2:
            path = sys.argv[2]
        try:
            with open(path) as f:
                data = json.load(f)
                for product in data['products']:
                    cls.products.append(product['id'])
        except:
            print("failed to load product ids from ", path)
            cls.products = []

    def setUp(self):
        if not TestEndpoints.service_url:
            self.fail("Rating service URL is not set for the test")
        if not TestEndpoints.products:
            self.fail("Test data about products is missing")

        self.session = requests.Session()
        # adapter = HTTPAdapter(max_retries=3)
        # self.session.mount('https://', adapter)

    def tearDown(self):
        self.session.close()

    def sendRequest(self, method, url, **kwargs):
        headers = {'Accept': 'application/json',
                   'Accept-Encoding': '', 'User-Agent': None}
        lastError = None
        retries = 3
        while retries > 0:
            try:
                if method == "GET":
                    kwargs.setdefault('allow_redirects', True)
                return self.session.request(method, url, timeout=TestEndpoints.TIMEOUT, headers=headers, **kwargs)
            except (RequestException, ReadTimeoutError) as err:
                lastError = err
                time.sleep(1)
            retries -= 1
        raise lastError

    def testGetAllRatings(self):
        """ test getting all ratings """
        url = TestEndpoints.composeUrl("ratings")
        res = self.sendRequest("GET", url)
        self.assertEqual(res.status_code, 200)
        ratings = res.json().get('ratings')
        self.assertTrue(type(ratings) == list)
        ids = [r['id'] for r in ratings]
        self.assertEqual(set(ids), set(TestEndpoints.products))

    def testGetProductRating(self):
        """ test getting ratings for a shop product """
        # use products[0] in "get product rating" test
        test_product_id = TestEndpoints.products[0]
        url = TestEndpoints.composeUrl("rating", test_product_id)
        res = self.sendRequest("GET", url)
        self.assertEqual(res.status_code, 200)

    def testGetRatingNotExist(self):
        """ test getting rating for non-exist product """
        url = TestEndpoints.composeUrl("rating", "random")
        res = self.sendRequest("GET", url)
        self.assertEqual(res.status_code, 404)

    def testPostNewRating(self):
        """ test posting new rating to a product """
        # use products[1] in "post new vote" test
        test_product_id = TestEndpoints.products[1]
        url = TestEndpoints.composeUrl("rating")
        res = self.sendRequest("POST", url, json={
            'rating': 5,
            'id': test_product_id
        })
        self.assertEqual(res.status_code, 200)

    def testNewRatingCalculation(self):
        """ test rating calculation after recollection """
        # use products[2] to avoid counting new vote from testRate() test
        test_product_id = TestEndpoints.products[2]
        new_rating_vote = 5
        url_get = TestEndpoints.composeUrl("rating", test_product_id)
        url_post = TestEndpoints.composeUrl("rating")
        url_recollect = TestEndpoints.composeUrl("ratings:recollect")

        # get current rating / post new vote / recollect / get updated rating
        result1 = self.sendRequest("GET", url_get)
        self.assertEqual(result1.status_code, 200)
        result2 = self.sendRequest("POST", url_post, json={
            'rating': new_rating_vote,
            'id': test_product_id
        })
        self.assertEqual(result2.status_code, 200)
        result2 = self.sendRequest("POST", url_recollect)
        self.assertEqual(result2.status_code, 200)
        result2 = self.sendRequest("GET", url_get)
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


if __name__ == '__main__':
    unittest.main(argv=['first-arg-is-ignored'])
