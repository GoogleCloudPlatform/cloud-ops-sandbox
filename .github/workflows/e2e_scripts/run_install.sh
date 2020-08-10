#!/bin/bash

# This file sets up and executes an installation inside the
# custom Cloud Shell container

# copy sandbox files into a new directory outside the
# docker volume, to avoid persisting tfstate between runs
mkdir /sandbox
cp -r /sandbox-shared/. /sandbox
# run install script
/sandbox/terraform/install.sh $*
