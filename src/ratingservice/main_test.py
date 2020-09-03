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
import subprocess
from shlex import split
import json
import urllib.request

class TestEndpoints(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        """ Get the location of GKE cluster for later queries """
        cls.name = 'projects/{0}/locations/{1}/clusters/cloud-ops-sandbox'.format(getProjectId(), getClusterZone())

    def testRate(self):
        """ Test if rating a product returns success """
        products = ['OLJCESPC7Z','66VCHSJNUP','1YMWWN1N4O','L9ECAV7KIM','2ZYFJ3GM2N','0PUK6V6EV0','LS4PSXUNUM','9SIQT8TOJO', '6E92ZMYYFZ']
        for product in products:
            url = "https://{0}.wl.r.appspot.com/rate/{1}".format(getProjectId(), product)
            res = urllib.request.urlopen(url)
            self.assertEqual(res, 'success')

    def testGetRating(self):
        """ Test if getting the rating of a product returns a correct number """
        url_get = "https://{0}.wl.r.appspot.com/getRating/{1}".format(getProjectId(), "OLJCESPC7Z")
        url_post = "https://{0}.wl.r.appspot.com/rate/{1}/{2}".format(getProjectId(), "OLJCESPC7Z", 5)
        rating, count = urllib.request.urlopen(url_get)
        urllib.request.urlopen(url_post)
        rating2, count2 = urllib.request.urlopen(url_get)
        self.assertEqual(rating * count + 5, rating2 * count2)

def getProjectId():
    return os.environ['GOOGLE_CLOUD_PROJECT']

if __name__ == '__main__':  
    unittest.main(verbosity=2)