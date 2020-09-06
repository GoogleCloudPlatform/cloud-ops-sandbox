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

class TestEndpoints(unittest.TestCase):

    def testRate(self):
        """ Test if rating a product returns success """
        products = ['OLJCESPC7Z','66VCHSJNUP','1YMWWN1N4O','L9ECAV7KIM','2ZYFJ3GM2N','0PUK6V6EV0','LS4PSXUNUM','9SIQT8TOJO', '6E92ZMYYFZ']
        for product in products:
            url = "https://{0}.wl.r.appspot.com/rate/{1}/{2}".format(getProjectId(), product, 5)
            res = requests.get(url)
            self.assertEqual(res.json()['status'], 'success')
    
    def testGetRating(self):
        """ Test if getting the rating of a product returns success """
        products = ['OLJCESPC7Z','66VCHSJNUP','1YMWWN1N4O','L9ECAV7KIM','2ZYFJ3GM2N','0PUK6V6EV0','LS4PSXUNUM','9SIQT8TOJO', '6E92ZMYYFZ']
        for product in products:
            url = "https://{0}.wl.r.appspot.com/getRating/{1}".format(getProjectId(), product)
            res = requests.get(url)
            self.assertEqual(res.json()['status'], 'success')

    
    def testGetRatingCorrect(self):
        """ Test if getting the rating of a product returns a correct number """
        url_get = "https://{0}.wl.r.appspot.com/getRating/{1}".format(getProjectId(), "OLJCESPC7Z")
        url_post = "https://{0}.wl.r.appspot.com/rate/{1}/{2}".format(getProjectId(), "OLJCESPC7Z", 5)
        res1 = requests.get(url_get).json()
        requests.get(url_post)
        res2 = requests.get(url_get).json()
        self.assertTrue(abs(float(res1['rating']) * float(res1['count']) + 5 
                        - float(res2['rating']) * float(res2['count'])) < 1e-5)
    
def getProjectId():
    return os.environ['GOOGLE_CLOUD_PROJECT']

if __name__ == '__main__':
    unittest.main(verbosity=2)