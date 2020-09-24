#!/usr/bin/env python3
# Copyright 2020 Google LLC
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

# set base image (host OS)
FROM google/cloud-sdk:latest

# set the working directory in the container
WORKDIR /code

# copy the dependencies file to the working directory
COPY . .

# install dependencies
RUN pip3 install -r requirements.txt

# command to run on container start
CMD [ "python3", "test_runner.py" ]
