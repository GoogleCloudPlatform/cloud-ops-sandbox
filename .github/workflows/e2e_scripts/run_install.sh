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

if [[ -n "$release_repo" ]]; then
  # pull down repo in the same way the Open in Cloud Shell button would
  git clone $release_repo /sandbox
  cd /sandbox
  if [[ -n "$release_branch" ]]; then git checkout $release_branch; fi
  if [[ -n "$release_dir" ]]; then cd $release_dir; fi
else
  # use latest code
  mkdir /sandbox
  cp -r /sandbox-shared/. /sandbox
  cd /sandbox/terraform
fi


# enable debug mode
export DEBUG=1

# trigger install script through cloudshell_open function
# environment variables project_id and skip_workspace_prompt
# must be set properly to run in headless mode
echo "running install.sh"
source /google/devshell/bashrc.google.d/cloudshell_open.sh
cloudshell_open
