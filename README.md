# Blockchain Operations

This repository contains all operational code and guides for the Kin blockchain.
This includes infrastructure automation and orchestration to launch and manage the Kin blockchain.

## Quickstart

A Docker image that provides a default, non-validating, ephemeral configuration that should work for most cases.
Check out [apps/docker-quickstart/](apps/docker-quickstart) for more information.

### Directory Structure

- [apps/docker-quickstart/](apps/docker-quickstart) - Simple way to incorporate Core and Horizon into your private infrastructure.
- [images/](images) - Docker images for running all the various apps in the Kin network i.e. Validator, HTTP API Frontend, etc.
Also includes automation for running a test network on your local machine for testing purposes.
- [deploy/terraform/](deploy/terraform) - Automation code for launching Kin network infrastructure.
- [deploy/ansible/](deploy/ansible) - Orchestration for deploying and managing Kin blockchain apps in production.

## Stack

The Kin network is made up of the following applications:

### Core

[Core](https://github.com/kinecosystem/core) is a validator and history archiver. This is the primary app that operates the network and takes part in consensus.
Its primary responsibilities are:

1. **Participate** in consensus, **validate** and add new ledgers and transactions.
1. **Submit** and **relay** transactions to other nodes.
1. **Store** and **archive** ledger information. This allows other nodes to catch-up on ledger information and join the network.

A core node can be configured to participate only in part of the above actions.
If it participates in all of these - it is considered a Full node.

### Horizon

[Horizon](https://github.com/kinecosystem/go) is an HTTP API frontend app that makes it easier on clients to access the network.
It abstracts the asynchronous nature of the blockchain from clients wishing to submit transactions or fetch account information.

### Laboratory

[Laboratory](https://github.com/kinecosystem/laboratory/) is a web application that allows to construct and submit transactions on the network.

### Testnet Applications

The following are applications only available on a test network, and are irrelevant for a production environment.

#### [Friendbot (Kin Faucet)]((https://github.com/kinecosystem/go))

Friendbot is a web application that creates and funds accounts with Kin.

# Differences from Stellar

The Kin blockchain currently differs from Stellar in the following aspects:

## Whitelist

Cores must be aware of a unique account in the network called a “Whitelist” account. This is configured in the Core app’s configuration file (See the example in this document). This is a required configuration, and without this your Core node will fail to successfully perform a complete catchup with the network.

## Decimal Precision

The decimal precision in the Kin blockchain is 5 decimals, e.g. the smallest value available is 0.00001 Kin. This is in contrast to Stellar’s network where the decimal precision is 7.

**NOTE** that Kin SDKs account for this feature, while Stellar’s SDKs do not.

## Transaction Memo

Our SDKs prepend a text to every submitted transaction. Please keep this in mind if you’re implementation relies on transaction memos. For more information please see the following sections in each SDK documentation:

- [Python SDK: Accessing the Kin blockchain](https://kinecosystem.github.io/kin-website-docs/docs/documentation/python-sdk#accessing-the-kin-blockchain)
- [iOS: Kin Client](https://kinecosystem.github.io/kin-website-docs/docs/documentation/ios-sdk#kinclient)
- [Android SDK: Accessing the Kin blockchain](https://kinecosystem.github.io/kin-website-docs/docs/documentation/android-sdk#accessing-the-kin-blockchain)

## HD Wallet Derivation Path

Kin HD wallet derivation path is `44'/2017'/0'`. Note that currently the underlying cryptographic implementation is similar to Stellar, but we still use a different path for the sake of being explicit.

# Guides

The following are instructions on setting up a group of Core validators in order to setup a new or join an existing network.

The Kin Foundation is currently using AWS for managing its infrastructure, though other cloud providers are possible as well.

## Network Topology

Before launching a single node or more, it is important to decide on the following:

1. How many nodes to run, keeping in mind high-availabiltiy considerations. Specifically, multiple nodes should be deployed on different cloud regions e.g. AWS us-east-1 and us-west-1. Prefer a separate region for each node.
1. Decide on your [quorum set and safety threshold percentage](https://www.stellar.org/developers/stellar-core/software/admin.html#crafting-a-quorum-set).

## Install and Run Core

1. [Configure Core](https://www.stellar.org/developers/stellar-core/software/admin.html).
    - See [Kin Mainnet example configuration](apps/docker-quickstart/pubnet/core/etc/stellar-core.cfg) from our [Docker quickstart image](https://hub.docker.com/r/kinecosystem/blockchain-quickstart/).
    - See [Stellar's generic configuration example](https://github.com/stellar/stellar-core/blob/master/docs/stellar-core_example.cfg).
1. See how to [install and run Core](https://github.com/kinecosystem/core/blob/master/INSTALL.md).
    - Kin Foundation runs Core using Docker.
    - See [our Dockerfile](ansible/playbooks/roles/dockerfiles/Dockerfile.stellar-core) and the [additional build image](ansible/playbooks/roles/dockerfiles/Dockerfile.stellar-core-build) for an example on how to build and run on Ubuntu.
    - See the [Docker Compose template file](deploy/ansible/playbooks/roles/stellar-core/templates/docker-compose.yml.j2) for an exampe on how to run Core.
1. Read on [hardware requirements](https://www.stellar.org/developers/guides/hardware.html) and launch the required infrastructure:
    1. Launch a cloud instance such as AWS EC2, used for running the Core application.
    1. Launch a PostgreSQL database instance such as AWS RDS, used for storing ledger state and other operational information by the Core application.
    1. Create an AWS S3 bucket, used for storing the history archive.
1. Repeat the above process for other Core nodes on your system.
1. Finally, see Core's [Administration Guide](https://www.stellar.org/developers/stellar-core/software/admin.html).

## Horizon

1. Launch an EC2 and RDS instance, similar to the above.
1. [Configure Horizon](https://www.stellar.org/developers/horizon/reference/admin.html#configuring)
    - Similar to Core, we run Horizon using Docker.
    - See [images/Dockerfile.Horizon](images/Dockerfile.horizon) and the [additional build image](images/Dockerfile.horizon-build) for an example on how to build and run Horizon on Ubuntu.
    - See the [Docker Compose template file](deploy/ansible/playbooks/roles/horizon-setup/templates/docker-compose.yml.j2) for an example on how to build and configure Horizon on Ubuntu.
1. Finally, see Horizon's [Administration Guide](https://www.stellar.org/developers/horizon/reference/admin.html).

## Automation

At Kin Foundation we use [Ansible](https://www.ansible.com/) for orchestration and provisioning, and [Terraform](https://www.terraform.io/) for infrastructure automation.

### Ansible

Ansible playbooks and roles can serve as specific step-by-step guide to deploying Core and Horizon on production.
Specific points of interest include:

1. [Core deploy role](deploy/ansible/playbooks/roles/stellar-core).
1. Horizon [init](deploy/ansible/playbooks/roles/stellar-core),
[setup](deploy/ansible/playbooks/roles/horizon-setup),
and [start](deploy/ansible/playbooks/roles/horizon-start) roles.
1. [Kernel network parameter optimization role](deploy/ansible/playbooks/roles/optimize-network).

See [deploy/ansible/](deploy/ansible) directory for further resources.

### Terraform

Similar to Ansible, our Terraform code can serve as a guidelines to properly configure the cloud infrastructure on your preferred provider.

See [deploy/terraform/](deploy/terraform) directory for more information.
Please keep the [security concerns guide](#security-concerns) in mind when launching infrastructure.

# Security Concerns

The following is a security checklist of issues that should be taken into account when managing Core and Horizon nodes.

## Stellar Security Guide

Start by reading through Stellar's [security guide](https://www.stellar.org/developers/guides/security.html).

## Seed Management

### Core

The seed of every core node is the most critical information to secure.
If a seed is compromised, an attacker could impersonate the Core node whose seed belongs to.

1. Secure and limit access to all copies of the seed:
    1. Core configuration file containing the seed should have limited user read access on the Core node instance.
    1. Backups should have very limited access.
        - At Kin we store the seed backups using AWS [SSM Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html)
using very limited permissions.

## Network Access

### Core Ports

Core exposes two ports: P2P (11625) and control (11626).

1. The P2P port should be publicly open.
1. The control port should be private and accessible only to Core's related Horizon.
    - At Kin we manage access to EC2 and RDS instances using AWS EC2 security groups. Refer to [our terraform code](deploy/terraform) for examples.

### RDS

1. Databases should not be exposed, and given access only to the Core and related Horizon apps.

#### User Setup

Core's RDS should have two users set up:

1. User for Core access with read/write permissions to the "core" database.
1. User for Horizon access with read-only permissions to the "core" database.
1. RDS admin user should not be used in production.

Horizon's RDS should have a single user set up:

1. User for Horizon access with read/write permissions to the "horizon" database.
1. RDS admin user should not be used in production.

### History Archive - S3

1. The history archive should be publicly readable globally, and specifically available for other nodes to catch up.
1. Write access should only be given to the Core instance managing the archive.
    - At Kin we manage access to history archives using AWS [IAM](https://aws.amazon.com/iam/) roles.

## Resources

- [Core](https://github.com/kinecosystem/core)
- [Horizon and Friendbot](https://github.com/kinecosystem/go)
- [Laboratory](https://github.com/kinecosystem/laboratory/)

### External

- [Core Administration](https://www.stellar.org/developers/stellar-core/software/admin.html)
- [Hardware Requirements](https://www.stellar.org/developers/guides/hardware.html)
- [Security](https://www.stellar.org/developers/guides/security.html)
- [Horizon Administration](https://www.stellar.org/developers/horizon/reference/admin.html)
- [Stellar Node Performance Tips](https://galactictalk.org/d/279-effectively-run-your-stellar-validator-node-performance-tips)

