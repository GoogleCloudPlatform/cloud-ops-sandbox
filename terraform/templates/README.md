# Terraform templates

This folder contains Terraform template files used to configure Monitoring,
Tracing and Logging resources in Cloud Operations suite.

## Monitoring Dashboards template: `dashboard.tftpl`

The resource "[google_monitoring_dashboard][1]" uses [JSON configuration][2]
to provision Cloud Monitoring dashboards.
The template file is used to generate this JSON based on the [YAML config][3]
that stores configurations for dashboards _and_ log-based metrics.

The templates generates (using `templatefile()`) a valid JSON string.
To generate JSON arrays in this string the template calls `jsonencode()`.
Using "for" [directive][4] is not possible because does not allow eliminating
the comma after the last element. Use of `jsonencode()` allows to resolve this.
> **Warning**
> The syntax of the argument passed to `jsonencode()` is the Terraform object syntax.

[1]: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_dashboard
[2]: https://cloud.google.com/monitoring/api/ref_v3/rest/v1/projects.dashboards
[3]: https://google.com/not-very+found
[4]: https://www.terraform.io/language/expressions/strings#directives
