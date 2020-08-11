#!/bin/bash
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


# This file sets up and executes an installation inside the
# custom Cloud Shell container

# copy sandbox files into a new directory outside the
# docker volume, to avoid persisting tfstate between runs
mkdir /sandbox
cp -r /sandbox-shared/. /sandbox
cd /sandbox/terraform
# trigger install script through cloudshell_open function
# environment variables project_id and skip_workspace_prompt
# must be set properly to run in headless mode
echo "running install.sh"
source /google/devshell/bashrc.google.d/cloudshell_open.sh
bash -x cloudshell_open
