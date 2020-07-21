# Tests for the Stackdriver Sandbox

## This directory is currently under construction

To run the integration test for monitoring examples, please ensure that you have already created the monitoring examples via running a `terraform apply` command in the `terraform/monitoring` directory.

1. In order to run the tests first install all necessary components for python 3
```bash
pip3 install -r requirements.txt
```

2. Run the tests
```bash
python3 monitoring_integration_test.py
```