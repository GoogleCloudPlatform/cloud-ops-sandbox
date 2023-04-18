# Monitoring Terraform Module

This folder includes Terraform configuration files that implement the Monitoring module for Cloud Ops Sandbox.

> **Note:** The module uses [Google][] terraform provider (~> 4.54.0) and assumes that the provider is _ALREADY_ configured in the calling configuration.

## Module arguments

The following table describes all input arguments the module accepts:

| Name | Type | Is required | Description |
| --- | --- | -+- | --- |
| filepath_configuration | `string` | | A path to the root folder storing configuration files and templates. The relative path should be defined relative to the root terraform folder |
| frontend_external_ip | `string` | ✔️ | A valid IPv4 address of the publicly available endpoint of the frontend service |
| gcp_project_id | `string` | ✔️ | A project id of the GCP project that hosts Cloud Ops Sandbox |
| notification_channel_email | `string` || A valid email address to be used as a destination for alert notifications |

## What's included

The module provisions Cloud Monitoring dashboards, uptime checks and alerts based on the provided configuration.
Additionally it provisions log-based metrics and configures SLOs for auto-detected and custom services.

> **Note**
> The module creates an opinionated observability artifacts to demonstrate best
> practices in capturing various observability signals using Cloud Operations
> suite of services.

[Google]: https://registry.terraform.io/providers/hashicorp/google/latest/docs
