---
title: "Destroying your cluster"
linkTitle: "Destroying your cluster"
weight: 40
---

Once you have finished exploring the Cloud Operations Sandbox project, don't forget to destroy it to avoid incurring additional billing.

Destroy your Sandbox project by opening the Cloud Shell and running sandboxctl destroy:
```
$ sandboxctl destroy
```

This script destroys the current Cloud Operations Sandbox project. If `sandboxctl create` were run again, a Cloud Operations Sandbox project with a new project id would be created.