# Rating Service terraform Module

This folder includes files for provisioning a rating microservice on App Engine Standard Edition and CloudSQL Postgres database.
The provisioning is invoked from the `/terraform/03_ratingservice.tf` as part of the Hipster Shop application setup.
Rating service provisions Cloud SQL Instance with a "rating-db" database to be used with the rating microservice that is deployed to App Engine.
The App Engine application in the provided GCP project is created only if there is none.
The App Engine application requires having a service with the name "default" in order to be able to deploy any other service.
The module deploys "default" App Engine service if such service does not exist. For this matter a simple Python application that returns "pong" on GET / request is deployed. See [/src/ratingservice/README.me](GoogleCloudPlatform/cloud-ops-sandbox/blob/master/src/ratingservice/README.md) for more details.
Since terraform does not provide means for discovering App Engine Application or its services, the "external" data provider is used to execute "setup_app_engine.sh". See its description below.
In addition, a Cloud Scheduler job is configured to call the rating microservice `/ratings:recollect` endpoint each 2 minutes. The endpoint represents a custom "recollect" method following the Google Custom Methods [guidelines](https://cloud.google.com/apis/design/custom_methods). It is done to follow the rating service TDD which requires recollection of the recently posted new votes in order to provide the up to date average rate values.

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
