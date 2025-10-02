#!/bin/sh

NAMESPACE="test-deploy"

DEFAULT_MAX=3
MAX="${NODES:-$DEFAULT_MAX}"

echo "Looping nodes from 1 to $MAX..."

AGGREGATOR_CONTENT=""

for i in $(seq 1 $MAX); do
  NODE="testacc${i}"
  CONFIGMAP_NAME="node${i}-config"

  BLS_KEY="/root/.nodes/operator_keys/${NODE}.bls.key.json"
  ECDSA_KEY="/root/.nodes/operator_keys/${NODE}.ecdsa.key.json"
  BLS_ID="/root/.nodes/operator_keys/${NODE}.bls.identifier"
  CONFIG_FILE="/root/.nodes/configs/${NODE}.config.yaml"

  if [ ! -f "$BLS_KEY" ] || [ ! -f "$ECDSA_KEY" ] || [ ! -f "$BLS_ID" ] || [ ! -f "$CONFIG_FILE" ]; then
    echo "Skipping $NODE because one or more files are missing."
    continue
  fi

  echo "Creating ConfigMap for $NODE..."

  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${CONFIGMAP_NAME}
  namespace: ${NAMESPACE}
data:
  ${NODE}.bls.key.json: |
$(sed 's/^/    /' "$BLS_KEY")
  ${NODE}.ecdsa.key.json: |
$(sed 's/^/    /' "$ECDSA_KEY")
  ${NODE}.bls.identifier: |
$(sed 's/^/    /' "$BLS_ID")
  ${NODE}.config.yaml: |
$(sed 's/^/    /' "$CONFIG_FILE")
EOF

  AGGREGATOR_CONTENT="$AGGREGATOR_CONTENT

  ${NODE}.bls.key.json: |
$(sed 's/^/    /' "$BLS_KEY")
  ${NODE}.ecdsa.key.json: |
$(sed 's/^/    /' "$ECDSA_KEY")
  ${NODE}.bls.identifier: |
$(sed 's/^/    /' "$BLS_ID")
"
done

if [ -n "$AGGREGATOR_CONTENT" ]; then
  echo "Creating aggregator Prover ConfigMap (prover-config) with all operator_keys..."
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: prover-config
  namespace: ${NAMESPACE}
data:$AGGREGATOR_CONTENT
EOF
fi

echo "All ConfigMaps created!"
wait

