#!/bin/sh
address=0x$(cat /opacity-avs-node/config/opacity.ecdsa.key.json | jq -r '.address')
yq -i -Y ".operator_address = \"$address\"" /opacity-avs-node/config/opacity.config.yaml
yq -i -Y ".node_public_ip = \"$NODE_IP\"" /opacity-avs-node/config/opacity.config.yaml
/opacity-avs-node/target/release/register /opacity-avs-node/config/opacity.config.yaml 
/opacity-avs-node/target/release/opacity-avs-node --config-file /opacity-avs-node/config/config.yaml