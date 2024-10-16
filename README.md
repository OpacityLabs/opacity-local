# Opacity Local 

This repository contains the configuration and setup for running the Opacity AVS (Actively Validated Service) infrastructure using Docker Compose.

## Prerequisites

- Docker
- Docker Compose

## Setup

1. Clone this repository:
   ```
   git clone https://github.com/your-repo/opacity-avs-node.git
   cd opacity-avs-node
   ```

2. Create a `.env` file in the root directory and add the following environment variables:
   ```
   cp example.env .env
   ```
   Make sure you have filled in all the variables 
   ```
    DELEGATION_MANAGER_ADDRESS= # Depends on the desired ENV 
    STRATEGY_MANAGER_ADDRESS=
    REGISTRY_COORDINATOR_ADDRESS=
    LST_CONTRACT_ADDRESS=
    LST_STRATEGY_ADDRESS=
    FORK_URL=
    RPC_URL=http://ethereum:8545
    WEBSOCKET_RPC_URL=ws://ethereum:8545
    ENVIRONMENT= # Depends on the desired ENV 
    MAX_OPERATOR_RETRY_ATTEMPTS=10
    SERVER_PRIVATE_KEY= 
   ```

3. Build and start the services:
   ```
   docker-compose up --build
   ```
Note that the nodes and node selector only start up after the eigenlayer setup container has exited  

## Services

The Docker Compose setup includes the following services:

1. `ethereum`: An Ethereum node for local development and testing.
2. `eigenlayer`: Sets up EigenLayer and registers operators.
3. `nodeselector`: A node selector service for the Opacity AVS.
4. `node1`, `node2`, `node3`: Opacity AVS nodes.

## Configuration

- The `docker/eigenlayer/register.sh` script creates test accounts and registers them as operators.
- Node configurations are stored in `.nodes/configs/`.
- Operator keys are stored in `.nodes/operator_keys/`.

## Accessing the Services

- Ethereum RPC: http://localhost:8545
- Node Selector: http://localhost:8080
- Opacity AVS Nodes:
  - Node 1: http://localhost:7047
  - Node 2: http://localhost:7048
  - Node 3: http://localhost:7049

## Notes

- The `.gitignore` file is set up to exclude sensitive information like operator keys and test account configs.
- Make sure to keep your `.env` file secure and do not commit it to version control.

For more detailed information about each component, refer to the individual Dockerfile and configuration files in the `docker/` directory.
