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

FROM gcr.io/cloudshell-images/cloudshell:latest

# install Terraform 0.12.29
RUN sudo apt-get install unzip && \
  wget -q https://releases.hashicorp.com/terraform/0.12.29/terraform_0.12.29_linux_amd64.zip -O ./terraform.zip && \
  unzip -o terraform.zip && \
  sudo install terraform /usr/local/bin

# Change "Open in Cloudshell" script to run ./install.sh using local file and changing it
COPY cloudshell_open_cp.sh cloudshell_open.sh

RUN sed -i '$i\
    ./install.sh' cloudshell_open.sh

RUN cp cloudshell_open.sh /google/devshell/bashrc.google.d/cloudshell_open.sh