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

# temporarily pin manifests to :$NEW_VERSION
find "${REPO_ROOT}/kubernetes-manifests" -name '*.yaml' -exec sed -i -e "s/:latest/:${NEW_VERSION}/g" {} \;
find "${REPO_ROOT}/kubernetes-manifests/loadgenerator" -name '*.yaml' -exec sed -i -e "s/:latest/:${NEW_VERSION}/g" {} \;

# update README
sed -i -e "s/cloudshell_git_branch=v\([0-9\.]\+\)/cloudshell_git_branch=${NEW_VERSION}/g" ${REPO_ROOT}/README.md;
sed -i -e "s/uncertified:v\([0-9\.]\+\)/uncertified:${NEW_VERSION}/g" ${REPO_ROOT}/README.md;

# update website deployment tag
sed -i -e "s/cloudshell_git_branch=v\([0-9\.]\+\)/cloudshell_git_branch=${NEW_VERSION}/g" ${REPO_ROOT}/website/index.html;
sed -i -e "s/cloudshell-image:v\([0-9\.]\+\)/cloudshell-image:${NEW_VERSION}/g" ${REPO_ROOT}/website/index.html;

# update custom Cloud Shell image variable
sed -i -e "s/VERSION=v\([0-9\.]\+\)/VERSION=${NEW_VERSION}/g" ${REPO_ROOT}/cloud-shell/Dockerfile;

# update telemetry Pub/Sub topic in telemetry.py from "Test" topic to "Production" topic
PROD_TOPIC="telemetry_prod"
TEST_TOPIC="telemetry_test"
sed -i -e "s/topic_id = \"${TEST_TOPIC}\"/topic_id = \"${PROD_TOPIC}\"/g" ${REPO_ROOT}/terraform/telemetry.py;

# if dry-run mode, exit directly after modifying files
if [[ "$*" == *dryrun*  || "$*" == *dry-run* ]]; then
    exit 0
else

    # create release commit
    git checkout -b "release/${NEW_VERSION}"
    git add "${REPO_ROOT}/kubernetes-manifests/*.yaml"
    git add "${REPO_ROOT}/kubernetes-manifests/loadgenerator/*.yaml"
    git add "${REPO_ROOT}/website/index.html"
    git add "${REPO_ROOT}/README.md"
    git add "${REPO_ROOT}/cloud-shell/Dockerfile"
    git add "${REPO_ROOT}/terraform/telemetry.py"
    git commit -m "release/${NEW_VERSION}"

    # add git tag
    git tag "${NEW_VERSION}"

    # change back manifests to :latest
    find "${REPO_ROOT}/kubernetes-manifests" -name '*.yaml' -exec sed -i -e "s/:${NEW_VERSION}/:latest/g" {} \;
    git add "${REPO_ROOT}/kubernetes-manifests/*.yaml"
    git add "${REPO_ROOT}/kubernetes-manifests/loadgenerator/*.yaml"

    # change back telemetry Pub/Sub topic to "Test" topic
    sed -i -e "s/topic_id = \"${PROD_TOPIC}\"/topic_id = \"${TEST_TOPIC}\"/g" ${REPO_ROOT}/terraform/telemetry.py;
    git add "${REPO_ROOT}/terraform/telemetry.py"
    
    git commit -m "revert images to latest and telemetry pipeline to 'test'"

    # if no-push mode, exit without pushing git branch or tags to origin
    if [[ "$*" == *nopush* || "$*" == *no-push* ]]; then
        exit 0
    else
        # push release branch to origin
        git push --set-upstream origin "release/${NEW_VERSION}"
        git push --tags
        echo "Release branch created. Please open PR manually in GitHub to finalize release"
    fi
fi
