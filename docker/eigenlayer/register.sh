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
highest_num=$(ls $HOME/.eigenlayer/operator_keys/testacc*.ecdsa.key.json 2>/dev/null | grep -oE 'testacc[0-9]+' | sed 's/testacc//' | sort -n | tail -1)

if [ -z "$highest_num" ]; then
    new_num=1
else
    new_num=$((highest_num + 1))
fi

new_account="testacc${new_num}"
ecdsa_keystore_path="${HOME}/.eigenlayer/operator_keys/${new_account}.ecdsa.key.json"
bls_keystore_path="${HOME}/.eigenlayer/operator_keys/${new_account}.bls.key.json"
password="Testacc1Testacc1"

echo $password | eigenlayer keys import --insecure --key-type ecdsa $new_account $PRIVATE_KEY  >  /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to import ecdsa key for $new_account"
    exit 1
fi
echo $password |  eigenlayer keys create --key-type bls --insecure $new_account >  /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to create bls key for $new_account"
    exit 1
fi