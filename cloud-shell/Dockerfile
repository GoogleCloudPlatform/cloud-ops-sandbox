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

# install Terraform 0.13.1
RUN sudo apt-get install unzip && \
  wget -q https://releases.hashicorp.com/terraform/0.13.1/terraform_0.13.1_linux_amd64.zip -O ./terraform.zip && \
  unzip -o terraform.zip && \
  sudo install terraform /usr/local/bin

# install python libraries
RUN python3 -m pip install google-cloud-pubsub
RUN python3 -m pip install click
RUN python3 -m pip install google-cloud-monitoring

# set env var
RUN echo "VERSION=v0.3.0" >> /etc/environment

# add sre-recipe CLI to PATH
ENV PATH="/cloud-ops-sandbox/sre-recipes/sandboxctl:${PATH}"

# Change "Open in Cloudshell" script to run ./install.sh using local file and changing it
COPY cloudshell_open_cp.sh /google/devshell/bashrc.google.d/cloudshell_open.sh
