#!/bin/bash
#
# Copyright 2019 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Clones the given git repository and then cd's into the git directory.
#
# NOTE: this file is a copy of cloudshell_open.sh script usually stored
# at /google/devshell/bashrc.google.d/ in GCP. It should be updated if that
# script changes.
# The only change from the original script is the addition of "install.sh"
# right before the end.

function cloudshell_open {
  valid_param_chars=^[a-zA-Z0-9~_,\.\/\:@\-]*$

  short_options=r:,p:,d:
  long_options=repo_url:,git_repo:,go_get:,git_branch:,print_file:,dir:,open_in_editor:,page:,tutorial:,create_custom_image:
  PARSED=$(getopt --options $short_options --long $long_options --name "$0" -- "$@")
  eval set -- "$PARSED"

  idx=0
  for var in "$@"; do
    if [[ ! "$var" =~ $valid_param_chars ]]; then
      echo "Invalid characters in argument $var"
      return
    fi
  done

  function try_chdir() {
    if [[ ! "$1" =~ ^CMD_CHDIR\: ]]; then
      return
    fi
    chdir=$(echo "$1" | sed "s/^CMD_CHDIR://")
    if [ ! -z "$chdir" ]; then
      cd -- "$chdir"
    fi
  }

  function try_envset() {
    if [[ ! "$1" =~ ^CMD_ENVVAR\: ]]; then
      return
    fi
    envset=$(echo "$1" | sed "s/^CMD_ENVVAR://")
    if [ ! -z "$envset" ]; then
      if [[ "$envset" =~ ^CUSTOM_ENV_PROJECT_ID= ]]; then
        envvar=$(echo "$envset" | sed "s/^CUSTOM_ENV_PROJECT_ID=//")
        if [ ! -z $envvar ]; then
          export CUSTOM_ENV_PROJECT_ID="$envvar"
          return
        fi
      elif [[ "$envset" =~ ^CUSTOM_ENV_REPO_ID= ]]; then
        envvar=$(echo "$envset" | sed "s/^CUSTOM_ENV_REPO_ID=//")
        if [ ! -z $envvar ]; then
          export CUSTOM_ENV_REPO_ID="$envvar"
          return
        fi
      fi
    fi
  }

  # Mercurial vulnerability fix for go_get
  sudo chmod a-x /usr/bin/hg
  trap "sudo chmod a+x /usr/bin/hg" EXIT
  output=$(/google/devshell/bin/cloudshell_open_go "$@")
  csgoret=$?
  if [ $csgoret -ne 0 ]; then
    echo "Error occured"
  else
    while read -r line; do
      try_chdir "$line"
      try_envset "$line"
    done <<< "$output"
  fi
  # add sandboxctl to path
  # the repo was previouly called stackdriver-sandbox. Now it's cloud-ops-sandbox
  # we will add both directories to the path to support forks with either name
  export PATH="~/cloudshell_open/cloud-ops-sandbox/sre-recipes:$PATH"
  export PATH="~/cloudshell_open/stackdriver-sandbox/sre-recipes:$PATH"
  # add terraform directory to path
  export PATH="~/cloudshell_open/cloud-ops-sandbox/terraform:$PATH"
  export PATH="~/cloudshell_open/stackdriver-sandbox/terraform:$PATH"
  ./terraform/install.sh # This line automatically runs the install script when cloudshell button is pressed
}
