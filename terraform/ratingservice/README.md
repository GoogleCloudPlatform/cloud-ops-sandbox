# Rating Service terraform Module

This folder includes files for provisioning a rating microservice on App Engine Standard Edition and CloudSQL Postgres database.
The provisioning is invoked from the `/terraform/03_ratingservice.tf` as part of the Hipster Shop application setup.

## File content breakdown

The files in the folder include bash scripts (*.sh), terraform (*.tf) and templates (*.tpl).

### Terraform files

| Filename | Description |
|---|---|
| main.tf | Describes all resources relevant to the rating service. |
| variables.tf | Describes module input variables. |
| output.tf | Describes rating service URL output variable. |

The module provision additional Google APIs that in use by the rating service: `sql-component.googleapis.com` and `sqladmin.googleapis.com` to provision and configure the Postgres DB and `cloudscheduler.googleapis.com` to provision Cloud Scheduler task.

### Bash scripts

| Filename | Description |
|---|---|
| configure_rating_db.sh | Creates a DB schema in the Postgres DB and populates the DB with random generated data. In order to perform these operations from the local host, it temporarly adds the public IP of the host to the list of allowed IP of the CloudSQL instance. |
| setup_app_engine.sh | Retrieves configuration of the App Engine application of the Google Cloud project. It is used to optimize provisioning of the App Engine application and its default service in the `main.tf`. |

Each script accepts a single parameter which is the Google Cloud project id. See the scripts for additional documentation.

### Deploy rating service without terraform

The terraform module uses Google provider to deploy the rating service to the App Engine application. Another method would be using Cloud SDK e.g. `gcloud app deploy`.
For this a manifest file `app.yaml` has to be generated and then deployed with the service [source files](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/src/ratingservice).
The app.yaml.tpl can be used to generate the file.

