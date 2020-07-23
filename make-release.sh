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

set -euxo pipefail

# move to repo root
SCRIPT_DIR=$(dirname $(realpath -s $0))
REPO_ROOT=$SCRIPT_DIR
cd $REPO_ROOT

# validate version number (format: v0.0.0)
if [[ ! "${NEW_VERSION}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "${NEW_VERSION} argument must conform to regex string:  ^v[0-9]+\.[0-9]+\.[0-9]+$ "
    echo "ex. v1.0.1"
    exit 1
fi

# update manifest versions
find "${REPO_ROOT}/kubernetes-manifests" -name '*.yaml' -exec sed -i -e "s/:latest/:${NEW_VERSION}/g" {} \;

# update website tag
sed -i -e "s/cloudshell_git_branch=v\([0-9\.]\+\)/cloudshell_git_branch=v0.2.0/g" ${REPO_ROOT}/docs/index.html;

if [[ "$*" == *dryrun*  ]]; then
    echo "dryrun finished"
    exit 0
else

    # push release PR
    git checkout -b "release/${NEW_VERSION}"
    git add "${REPO_ROOT}/kubernetes-manifests/*.yaml"
    git add "${REPO_ROOT}/docs/index.html"
    git commit -m "release/${NEW_VERSION}"

    # add tag
    git tag "${NEW_VERSION}"

    # change back to latest tag
    find "${REPO_ROOT}/kubernetes-manifests" -name '*.yaml' -exec sed -i -e "s/:${NEW_VERSION}/:latest/g" {} \;
    git add "${REPO_ROOT}/kubernetes-manifests/*.yaml"
    git commit -m "revert to latest images"

    if [[ "$*" == *no-push*  ]]; then
        exit 0
    else
        # push to repo
        git push --set-upstream origin "release/${NEW_VERSION}"
        git push --tags
        echo "Release branch created. Please open PR manually in GitHub to finalize release"
    fi
fi
