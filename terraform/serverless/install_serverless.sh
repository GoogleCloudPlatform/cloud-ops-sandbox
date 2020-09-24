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
#!/bin/bash

# step1: create an App Engine app and deploy the first 'default' version
create_app(){
    gcloud app create --region="us-west2"
    (cd ../../src/ratingservice && gcloud app deploy --quiet)
}

# step2: zip the source code and upload it to GCS
upload_source_code(){
    if [[ -n "$code_tag" ]]; then
        source_name="ratingservice_code:${code_tag}.zip"
    else
        source_name="ratingservice_code:latest.zip"
    fi
    zip -j ${source_name} ../../src/ratingservice/main.py ../../src/ratingservice/requirements.txt ../../src/productcatalogservice/products.json
    gsutil cp ${source_name} "gs://${bucket_name}/${source_name}"
}

# step3: deploy the rating service with Terraform
deploy_ratingservice() {
  # get parameters
  project_id=$1
  bucket_name="${project_id}-bucket"
  code_tag=$2
  # upload the source code
  upload_source_code
  # remove states and apply terraform
  rm -f .terraform/terraform.tfstate
  rm -f *.tfstate
  terraform init -lock=false
  terraform apply --auto-approve -var="project_id=${project_id}" -var="bucket_name=${bucket_name}" -var="code_tag=${code_tag}"
}

create_app;
deploy_ratingservice $1 $2;
