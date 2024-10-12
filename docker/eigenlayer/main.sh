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

# Find the highest numbered test account
highest_num=$(ls $HOME/.eigenlayer/operator_keys/testacc*.ecdsa.key.json 2>/dev/null | grep -oE 'testacc[0-9]+' | sed 's/testacc//' | sort -n | tail -1)

if [ -z "$highest_num" ]; then
    new_num=1
fi
if [ "$highest_num" -ge 4 ]; then
    echo "Using existing accounts"
    exit 0
fi

# Check for TEST_ACCOUNTS environment variable
if [ -n "$TEST_ACCOUNTS" ]; then
    num_accounts=$TEST_ACCOUNTS
else
    num_accounts=4
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
echo "Ejecting"
./eject.sh