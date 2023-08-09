# Github Windows IaC

terraform workflow files for use with the LE windows based pipelines

## Requirements

Each repo needs to have the following variables set
repository variables required - settings/actions/variables

- OSVARS ( Valid variables below )
  - WIN10
  - WIN11
  - WIN2016
  - WIN2019
  - WIN2022

- BENCHMARK_TYPE ( Valid variables below )
  - CIS
  - STIG

eg.

```shell
OSVARS WIN2019
BENCHMARK_TYPE CIS
```

## Overview

This is called by the repository workflow to pull in this content.
This enables us to manage the workflow and IAC centrally, enabling us to quickly change anything for improvements of issues with a certain region.

```mermaid
   graph TD;
    A[Benchmark Pipeline] -->|Starts the github workflow|B[Loads  the windows_benchmark_testing]
    B --> C[Imports variables set in repo]
    C --> D[STEP - Welcome Message]
    D --> E[Sends welcome if first PR and invite to discord]
    C --> F[STEP - Build testing pipeline]
    F --> G[Starts runner based on ubuntu latest]
    G --> H[Imports Variables for usage across workflow]
    H --> I[Git Clone in repo and source branch PR is requested from]
    I --> J[Git Clone this content for IaC portion of pipeline]
    J --> K[Imports Username & Password For Windows]
    K --> L[Runs terraform steps]
    L -->|terraform init|M[Initiates terraform]
    M -->|terraform validate|N[Validates config]
    N -->|terraform apply|O[Runs terraform and sets up host]
    O -->|sleep 60 seconds|P[If Debug variable set output ansible hosts]
    P --> Q[Runs ansible playbook] --> |terraform destroy|R[Destroys all the IaC config]
```

# Run locally

```shell
$ export BENCHMARK_TYPE="CIS"
$ export OSVAR="WIN2019"
$ export TF_VAR_repository="${OSVAR}-${benchmark_type}"
$ export TF_VAR_BENCHMARK_TYPE="${benchmark_type}"

$ terraform apply -var-file "${OSVAR}.tfvars" --auto-approve
$ terraform destroy -var-file "${OSVAR}.tfvars" --auto-approve
```
