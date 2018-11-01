# Blockchain Operations

This repository contains all operational code for Kin blockchain.
This includes infrastructure automation and orchestration to launch and manage the Kin blockchain.

## Directory Structure

- [images/](images) - Docker images for running all the various apps in the Kin network i.e. Validator, HTTP API Frontend, etc.
Also includes automation for running a test network on your local machine for testing purposes.
- [deploy/terraform/](deploy/terraform) - Automation code for launching Kin network infrastructure.
- [deploy/ansible/](deploy/ansible) - Orchestration for deploying and managing Kin blockchain apps in production.

## Stack

The Kin network is made up of the following applications:

### Core

Core is a validator and history archiver. This is the primary app that operates the network and takes part in consensus.
Its primary responsibilities are:

1. **Participate** in consensus, **validate** and add new ledgers and transactions.
1. **Submit** and **relay** transactions to other nodes.
1. **Store** and **archive** ledger information. This allows other nodes to catch-up on ledger information and join the network.

A core node can be configured to participate only in part of the above actions.
If it participates in all of these - it is considered a Full node.

### Horizon

Horizon is an HTTP API frontend app that makes it easier on clients to access the network.
It abstracts the asynchronous nature of the blockchain from clients wishing to submit transactions or fetch account information.

### Laboratory

Laboratory is a web application that allows to construct and submit transactions on the network.

### Testnet Applications

The following are applications only available on a test network, and are irrelevant for a production environment.

#### Friendbot (XLM Faucet)

Friendbot is a web application that creates and funds accounts with native (XLM) tokens.

#### [Kin Faucet](https://github.com/kinecosystem/stellar-faucet)

Kin Faucet, similar to friendbot, is a web application the funds accounts with KIN tokens.

## Launch a Network

1. Read the [installation guide](INSTALL.md).
1. Go through the [security checklist](SECURITY.md).
