#!/bin/sh
if [ -z "$LST_CONTRACT_ADDRESS" ]; then
  echo "Error: LST_CONTRACT_ADDRESS is not set in the environment variables."
  exit 1
fi
if [ -z "$LST_STRATEGY_ADDRESS" ]; then
  echo "Error: LST_CONTRACT_ADDRESS is not set in the environment variables."
  exit 1
fi
if [ -z "$DELEGATION_MANAGER_ADDRESS" ]; then
  echo "Error: DELEGATION_MANAGER_ADDRESS is not set in the environment variables."
  exit 1
fi
if [ -z "$RPC_URL" ]; then
  echo "Error: RPC_URL is not set in the environment variables."
  exit 1
fi



ACCOUNT_INFO=$(cast wallet new --json)
PRIVATE_KEY=$(echo "$ACCOUNT_INFO" | jq -r '.[0].private_key')
ADDRESS=$(echo "$ACCOUNT_INFO" | jq -r '.[0].address')

cast rpc anvil_setBalance $ADDRESS 0x10000000000000000000 --rpc-url $RPC_URL > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to set balance for $ADDRESS"
    exit 1
fi
MINT_FUNCTION="submit(address _referral)"
cast send $LST_CONTRACT_ADDRESS "$MINT_FUNCTION" $ADDRESS "0x0000000000000000000000000000000000000000" --private-key $PRIVATE_KEY --value 110000000000000000000 --rpc-url $RPC_URL > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to mint LST for $ADDRESS"
    exit 1
fi
cast send $LST_CONTRACT_ADDRESS "approve(address,uint256)" $STRATEGY_MANAGER_ADDRESS 100000000000000000000000 --private-key $PRIVATE_KEY --rpc-url $RPC_URL > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to approve LST for $STRATEGY_MANAGER_ADDRESS"
    exit 1
fi
cast send $STRATEGY_MANAGER_ADDRESS "depositIntoStrategy(address,address,uint256)" $LST_STRATEGY_ADDRESS $LST_CONTRACT_ADDRESS 100000000000000000000 --private-key $PRIVATE_KEY --rpc-url $RPC_URL > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to deposit into strategy for $LST_STRATEGY_ADDRESS"
    exit 1
fi
cast send $DELEGATION_MANAGER_ADDRESS "registerAsOperator((address,address,uint32), string)" "($ADDRESS,`cast az`,0)" "foo.bar" --private-key $PRIVATE_KEY --rpc-url $RPC_URL > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to register as operator for $DELEGATION_MANAGER_ADDRESS"
    exit 1
fi

# Find the highest numbered test account
highest_num=$(ls $HOME/.nodes/operator_keys/testacc*.ecdsa.key.json 2>/dev/null | grep -oE 'testacc[0-9]+' | sed 's/testacc//' | sort -n | tail -1)

if [ -z "$highest_num" ]; then
    new_num=1
else
    new_num=$((highest_num + 1))
fi

new_account="testacc${new_num}"
ecdsa_keystore_path="${HOME}/.nodes/operator_keys/${new_account}.ecdsa.key.json"
bls_keystore_path="${HOME}/.nodes/operator_keys/${new_account}.bls.key.json"
password="Testacc1Testacc1"

echo $password | eigenlayer keys import --insecure --key-type ecdsa $new_account $PRIVATE_KEY  >  /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to import ecdsa key for $new_account"
    exit 1
fi
cp $HOME/.eigenlayer/operator_keys/${new_account}.ecdsa.key.json $HOME/.nodes/operator_keys/${new_account}.ecdsa.key.json
echo $password |  eigenlayer keys create --key-type bls --insecure $new_account >  /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to create bls key for $new_account"
    exit 1
fi
private_bls_key=$(./get_bls_key.sh $password $new_account  | grep "Private key:" | awk '{print $3}')
if [ $? -ne 0 ]; then
    echo "Error: Failed to get bls key for $new_account"
    exit 1
fi
result=$(grpcurl -plaintext -d '{"privateKey": "'"$private_bls_key"'", "password": "'"$password"'"}' signer:50051  keymanager.v1.KeyManager/ImportKey | jq -r '.publicKey' | tr -d '\n')
if [ $? -ne 0 ]; then
    echo "Error: Failed to import bls key for $new_account"
    echo $result
    exit 1
fi
echo -n $result > $HOME/.nodes/operator_keys/${new_account}.bls.identifier
cp $HOME/.eigenlayer/operator_keys/${new_account}.bls.key.json $HOME/.nodes/operator_keys/${new_account}.bls.key.json

# Create the config file for the new account
config_file="${HOME}/.nodes/configs/${new_account}.config.yaml"

# Set the node public IP based on the account number
node_public_ip="http://node${new_num}"

# Create the config file with the correct values
cat << EOF > "$config_file"
production: false
opacity_node_selector_address: 0x8a2c56230E89C4636e5b7878541e66aBA2091FcD
registry_coordinator_address: "0xeCd099fA5048c3738a5544347D8cBc8076E76494"
opacity_avs_address: "0xCE06c5fe42d22fF827A519396583Fd9f5176E3D3"
avs_directory_address: "0x135DDa560e946695d6f155dACaFC6f1F25C1F5AF"
eigenlayer_delegation_manager: "0x39053D51B77DC0d36036Fc1fCc8Cb819df8Ef37A"
chain_id: 1
eth_rpc_url: http://ethereum:8545
operator_address: '${ADDRESS}'
node_public_ip: ${node_public_ip}
operator_bls_keystore_path: /opacity-avs-node/config/opacity.bls.key.json
EOF

