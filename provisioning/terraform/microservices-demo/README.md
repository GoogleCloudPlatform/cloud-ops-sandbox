# Module microservices-demo

This is a terraform module for provisioning infrastructure for and installation
of the [Online Boutique][ob] microservices demo application.
The deployed version of Online Boutique uses a non-default setup that allows:

* to run the microservices using Anthos Service Mesh (ASM)
* to customize the configuration of the node workpool
* to opt-out use of the Oline Boutique load generator

[ob]: https://github.com/GoogleCloudPlatform/microservices-demo

## Input parameters

| Name | Required | Default value | Description |
| --- | --- | --- | --- |
| gcp_project_id | Yes | None | The GCP project ID to use in this module's resources |
| gke_cluster_name | No | "cloud-ops-sandbox" | Name of the GKE standard cluster hosting Online Boutique |
| gke_cluster_location | No | "us-central1" | Supports regions and zones. When the location is a zone, the zone cluster is provisioned. |
| gke_node_pool | No | | See [Node pool configuration](#node-pool-configuration) for the details. |
| enable_asm | No | true | Controls the provisioning and configuration of ASM for the Online Boutique microservices. |
| asm_channel | No | stable | If `enable_asm` is `true`, allows to define the release channel (version) of ASM. |
| name_suffix | No | Empty string | Custom suffix allowing provisioning multiple copies of the resource within the same GCP project. |
| sandbox_version | No | "unknown" | The version of the Cloud Ops Sandbox that provisions the module. Use /provisioning/version.txt for the version source. |

## Output variables

| Name | Description |
| --- | --- |
| frontend_external_ip | A public IP that is used to access the Web front-end application of the Online Boutique. |

## Node pool configuration

Some environments have resource constraints.
The `gke_node_pool` configuration allows to customize VM instances used in the GKE node pool.
The configuration is defined as a dictionary following this schema:

```json
{
    "initial_node_count": number,
    "labels": map(string),
    "machine_type": string,
    "autoscaling": {
      "max_node_count": number,
      "min_node_count": number
    }
}
```

The default configuration uses the default node pool values:

```json
{
    "initial_node_count": 4,
    "labels": {},
    "machine_type": "e2-standard-4",
    "autoscaling": null
}
```
