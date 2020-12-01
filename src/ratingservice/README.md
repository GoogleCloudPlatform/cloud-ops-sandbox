# Rating Service

Rating Service is a microservice in Python developed to run on App Engine Standard Environment.
It manages ratings of the Hipster shop products graded in scale from 1 to 5.
The collection of pairs {entity id, rating} are stored in Postgres database managed by Cloud SQL.
The service exposes GET APIs to get a collection of all managed ratings or to get a rating of the specific product.
It is possible to submit a new vote for the product's rating. New vote get recollected on demand and the new product rating is calculated as an average of the current rating and all submitted votes.
The vote recollection is implemented as a scheduled task (using Cloud Schedule) which is triggered each two minutes.

## Deployment

The service is deployed using Terraform module [ratingservice](../../terraform/ratingservice).
To deploy the service during development you should generate `app.yaml` file with the following parameters:

```yaml
```

A template of the file can be found in the [ratingservice](../../terraform/ratingservice) folder.

## Testing

Rating service [e2e test](../../tests/ratingservice) verifies API correctness. To launch it manually, use the following command:

```bash
python3 main_test.py $SERVICE_URL $PATH_TO_PRODUCTS_JSON
```

where `SERVICE_URL` is a root URL of the rating service and `PATH_TO_PRODUCTS_YAML` is a local path to `product.json` file location.
