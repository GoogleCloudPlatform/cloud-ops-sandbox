# Rating Service

Rating Service is a new microservice deployed on App Engine. We'd like this microservice to demonstrate the observability of Cloud Ops on serverless platforms.
The current state of this service is still self-contained. Later we will integrate it to our Hipster Shop app.

## Deploy

To deploy the service, first go to the directory.
```
$ cd terraform/serverless
```

Then run the installation script where "tag" is the tag of the source code you will upload to GCS.

```
$ ./install_serverless.sh ${project_id} ${tag}
```

Note that this script is currently not idempotent, so running it multiple times will cause re-provisioning of the infrastructure.

## Integration

To integrate the provisioning later on, we need to first move the Terraform files to the Terraform directory.
```
$ mv 04_cloudsql.tf ../04_cloudsql.tf && mv 05_app_engine.tf ../05_app_engine.tf
```

Then move the functions in the installation script to install.sh. The install_serverless.sh does 3 things: create an App Engine app, upload the source code, then apply Terraform.

