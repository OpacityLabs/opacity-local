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

rm -rf $HOME/.nodes/operator_keys/*
rm -rf $HOME/.nodes/configs/*
rm -rf $HOME/.eigenlayer/operator_keys/*

if [ -n "$TEST_ACCOUNTS" ]; then
    num_accounts=$TEST_ACCOUNTS
else
    num_accounts=3
fi

for i in $(seq 1 $num_accounts); do
    echo "Creating test account $i of $num_accounts"
    ./register.sh
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create test account $i"
        exit 1
    fi
done
./eject.sh