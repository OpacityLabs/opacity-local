#!/bin/sh
set -e  # Exit on any error

# Generate SGX enclave key if it doesn't exist
if [ ! -f "/opacity-avs-node/sgx/enclave-key.pem" ]; then
    echo "Generating SGX enclave key..."
    mkdir -p /root/.config/gramine
    gramine-sgx-gen-private-key -f /opacity-avs-node/sgx/enclave-key.pem
    cp /opacity-avs-node/sgx/enclave-key.pem /root/.config/gramine/enclave-key.pem
fi

# Re-sign the manifest with the runtime key
gramine-sgx-sign \
    --key /opacity-avs-node/sgx/enclave-key.pem \
    --manifest opacity-avs-node.manifest \
    --output opacity-avs-node.manifest.sgx

# Run registration if needed
echo "Starting registration process..."
/opacity-avs-node/target/release/register /opacity-avs-node/config/opacity.config.yaml 
if [ $? -ne 0 ]; then
    echo "Registration failed"
    exit 1
fi
echo "Registration completed successfully"

# Start the node with SGX
gramine-sgx opacity-avs-node --config-file /opacity-avs-node/config/config.yaml