#!/bin/sh
# address=0x$(cat /opacity-avs-node//opacity.bls.key.local.json | jq -r '.address')
# yq -i ".operator_address = \"$address\"" opacity.config.yaml 
cargo run --bin register /opacity-avs-node/config/opacity.config.yaml 
cargo run --bin opacity-avs-node --release -- --config-file /opacity-avs-node/config/config.yaml