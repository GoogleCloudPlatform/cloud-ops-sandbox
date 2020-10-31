# Rating Service

Rating Service is a microservice developed in Python3 to run on App Engine Standard Environment. It supports a rating management functionality based on abstract entity ids and votes to rate the entity from 1 to 5. The service is used in the Hipster Shop application to simulate rating system of the shop's products.

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

Tests are in `tests/ratingservice` and they should also be integrated to the CI system.
