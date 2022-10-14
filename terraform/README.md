# Terraform configuration files and templates

All Terraform (TF) configuration files and TF template files of the project are
stored in `/terraform` and `/terraform/templates` directories.
TF configuration stores its state in the "[gcs][tf-gcs]".
It assumes that the GCS bucket exists. A user has to provide the bucket name
and Google Cloud project id as input parameters when applying TF configuration.
The following command can be used to initiate TF:

```bash
terraform init -lockfile=false \
    -backend-config="bucket=<your-gcs-bucket-name>" \
    -backend-config="prefix=terraform/sandbox_state_<your-custom-suffix-here>"
```

Once initialization is complete, Sandbox can be provisioned with the following
command:

```bash
terrafor apply -auto-approve \
    -var="project_id=<your-gcp-project-id-here>" \
    -var="state_bucket_name=<your-gcs-bucket-name>" \
    -var="state_suffix=<your-custom-suffix-here>" \
    -var="cfg_file_location=<path-to-application-config-files-here>"
```

Use `<your-custom-suffix-here>` only if you plan to reuse the same GCS bucket
for provisioning provision more than one Sandbox instance.
Otherwise, you can omit this parameter or pass empty string instead.
This optional parameter is mainly used in the end-to-end testing environment.
It allows reusing the same GCS bucket for provisioning multiple Sandboxes
in parallel.

Use `<path-to-application-config-files-here>` to provide absolute or relative
path to a directory where application configurations are stored.
The repository maintains all application configurations under `apps/`.
The test configurations used for end-to-end testing are stored under
`tests/test-app`.

## Terraform templates

Current implementation uses `dashboard.tftpl` template to compose values for
the `dashboard_json` argument of the "[google_monitoring_dashboard][]" TF
resource.
Using the template, TF configuration (in `03_dashboards.tf`) generates a
[JSON configuration][json-config] that describes Cloud Monitoring dashboards.
**Important caveat:** inside the template a TF function `jsonencode()` is
called to generate Json array.
It is not possible to generate the valid Json using ["for" directive][for-doc].
It is because the directive does not allow eliminating the comma after the
last element of the array. The embedded call to `jsonencode()` allows to
resolve this problem.
However, it leads to the mixed syntax in the template where the text outside
the call to `jsonencode()` is in Json syntax while the text passed as the
argument to `jsonencode()` is in the Terraform object syntax.

[tf-gcs]: https://www.terraform.io/language/settings/backends/gcs
[google_monitoring_dashboard]: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_dashboard
[json-config]: https://cloud.google.com/monitoring/api/ref_v3/rest/v1/projects.dashboards
[for-doc]: https://www.terraform.io/language/expressions/strings#directives
