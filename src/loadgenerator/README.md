# Microservices Demo Load Generator

The load generation infrastructure for this microservices application.
Generates fake user HTTP requests to the frontend of a running demo application.

## Quick Start

```sh
./loadgen.sh
```

## Run a User Scenario

The configuration file defines a number of different user scenarios. By default
the generator uses every scenario, but it is possible to run only specific
scenarios.

```sh
# Runs only the specified user scenarios.
./loadgen.sh BrowsingUser WishlistUser
```
