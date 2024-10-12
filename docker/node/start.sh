#!/bin/sh
address=0x$(cat /opacity-avs-node/config/opacity.ecdsa.key.json | jq -r '.address')
sed -i "s/^operator_address:.*/operator_address: \"$address\"/" /opacity-avs-node/config/opacity.config.yaml
sed -i "s/^node_public_ip:.*/node_public_ip: \$NODE_IP\"/" /opacity-avs-node/config/opacity.config.yaml
cargo run --bin register /opacity-avs-node/config/opacity.config.yaml 
cargo run --bin opacity-avs-node --release -- --config-file /opacity-avs-node/config/config.yaml