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

class TestEndpoints(unittest.TestCase):    
    def testGetRating(self):
        """ Test if getting the rating of a product returns success """
        products = read_products()
        for product in products:
            url = "https://ratingservice-dot-{0}.wl.r.appspot.com/rating/{1}".format(getProjectId(), product)
            res = requests.get(url)
            self.assertEqual(res.status_code, 200)

    def testGetRatingNotExist(self):
        """ Test if getting non-existing product returns 404 """
        url = "https://ratingservice-dot-{0}.wl.r.appspot.com/rating/{1}".format(getProjectId(), "random")
        res = requests.get(url)
        self.assertEqual(res.status_code, 404)
    
    def testRate(self):
        """ Test if rating a product returns success """
        products = read_products()
        for product in products:
            url = "https://ratingservice-dot-{}.wl.r.appspot.com/rating".format(getProjectId())
            res = requests.post(url, data={
                'score' : 5,
                'id' : product
            })
            self.assertEqual(res.status_code, 200)
    
    def testGetRatingCorrect(self):
        """ Test if getting the rating of a product returns a correct number """
        products = read_products()
        url_get = "https://ratingservice-dot-{0}.wl.r.appspot.com/rating/{1}".format(getProjectId(), products[0])
        url_post = "https://ratingservice-dot-{0}.wl.r.appspot.com/rating".format(getProjectId())
        res1 = requests.get(url_get).json()
        requests.post(url_post, data={
            'score' : 5,
            'id' : products[0]
        })
        res2 = requests.get(url_get).json()
        # The original total score (count * rating) plus the current score 5 must equal to the current total score
        self.assertTrue(abs(float(res1['rating']) * float(res1['count']) + 5 
                        - float(res2['rating']) * float(res2['count'])) < 1e-5)
    

def getProjectId():
    return os.environ['GOOGLE_CLOUD_PROJECT']

# read product ids
def read_products():
    res = []
    with open('../../src/productcatalogservice/products.json') as f:
        data = json.load(f)
        for product in data['products']:
            res.append(product['id'])
    return res

if __name__ == '__main__':
    unittest.main(verbosity=2)