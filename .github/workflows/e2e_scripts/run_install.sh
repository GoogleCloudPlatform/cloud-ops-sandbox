#!/bin/bash

mkdir /sandbox
cp -r /sandbox-shared/. /sandbox
ls /sandbox
/sandbox/terraform/install.sh $*
