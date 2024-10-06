#!/bin/sh

if [ -z "$LST_CONTRACT_ADDRESS" ]; then
  echo "Error: LST_CONTRACT_ADDRESS is not set in the environment variables."
  exit 1
fi
if [ -z "$DELEGATION_MANAGER_ADDRESS" ]; then
  echo "Error: DELEGATION_MANAGER_ADDRESS is not set in the environment variables."
  exit 1
fi
if [ -z "$LST_STRATEGY_ADDRESS" ]; then
  echo "Error: LST_STRATEGY_ADDRESS is not set in the environment variables."
  exit 1
fi
if [ -z "$STRATEGY_MANAGER_ADDRESS" ]; then
  echo "Error: STRATEGY_MANAGER_ADDRESS is not set in the environment variables."
  exit 1
fi
if [ -z "$RPC_URL" ]; then
  echo "Error: RPC_URL is not set in the environment variables."
  exit 1
fi
sleep 10
# Create a new account
ACCOUNT_INFO=$(cast wallet new --json)
PRIVATE_KEY=$(echo "$ACCOUNT_INFO" | jq -r '.[0].private_key')
ADDRESS=$(echo "$ACCOUNT_INFO" | jq -r '.[0].address')

cast rpc anvil_setBalance $ADDRESS 0x1000000000000000000000000000  -r $RPC_URL> /dev/null 2>&1
MINT_FUNCTION="submit(address _referral)"
cast send $LST_CONTRACT_ADDRESS "$MINT_FUNCTION" $ADDRESS "0x0000000000000000000000000000000000000000" --private-key $PRIVATE_KEY --value 110000000000000000000000  -r $RPC_URL> /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to mint tokens to the account."
    exit 1
fi
cast send $LST_CONTRACT_ADDRESS "approve(address,uint256)" $STRATEGY_MANAGER_ADDRESS 1000000000000000000000000 --private-key $PRIVATE_KEY   -r $RPC_URL> /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to approve tokens for the strategy manager."
    exit 1
fi
cast send $STRATEGY_MANAGER_ADDRESS "depositIntoStrategy(address,address,uint256)" $LST_STRATEGY_ADDRESS $LST_CONTRACT_ADDRESS 10000000000000000000000 --private-key $PRIVATE_KEY  -r $RPC_URL> /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to deposit tokens into the strategy."
    exit 1
fi
cast send $DELEGATION_MANAGER_ADDRESS "registerAsOperator((address,address,uint32), string)" "($ADDRESS,`cast az`,0)" "foo.bar" --private-key $PRIVATE_KEY  -r $RPC_URL> /dev/null 2>&1


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
password="Testacc${new_num}Testacc${new_num}"

echo $password | eigenlayer keys import --insecure --key-type ecdsa $new_account $PRIVATE_KEY  >  /dev/null 2>&1
echo $password |  eigenlayer keys create --key-type bls --insecure $new_account >  /dev/null 2>&1
echo "Private key for the eigenlayer operator test account: $PRIVATE_KEY"
echo "ECDSA keystore path: $ecdsa_keystore_path"
echo "BLS keystore path: $ecdsa_keystore_path"
echo "Password: $password"

# Check for TEST_ACCOUNTS environment variable
if [ -n "$TEST_ACCOUNTS" ]; then
    num_accounts=$TEST_ACCOUNTS
else
    num_accounts=3
fi

# Run register.sh the specified number of times
for i in $(seq 1 $num_accounts); do
    echo "Creating test account $i of $num_accounts"
    ./register.sh
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create test account $i"
        exit 1
    fi
done

