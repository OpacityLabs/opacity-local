#!/bin/sh

NAMESPACE="test-deploy"

# Wait until we can communicate with the Kubernetes API
until kubectl version --short >/dev/null 2>&1; do
  echo "Waiting for access to Kubernetes..."
  sleep 5
done

for i in 1 2 3; do
  NODE="testacc${i}"
  CONFIGMAP_NAME="node${i}-config"

  BLS_KEY="/root/.nodes/operator_keys/${NODE}.bls.key.json"
  ECDSA_KEY="/root/.nodes/operator_keys/${NODE}.ecdsa.key.json"
  BLS_ID="/root/.nodes/operator_keys/${NODE}.bls.identifier"
  CONFIG_FILE="/root/.nodes/configs/${NODE}.config.yaml"

  # Check if files exist before creating the ConfigMap
  if [ ! -f "$BLS_KEY" ] || [ ! -f "$ECDSA_KEY" ] || [ ! -f "$BLS_ID" ] || [ ! -f "$CONFIG_FILE" ]; then
    echo "Skipping $NODE because one or more files are missing."
    continue
  fi

  echo "Creating ConfigMap for $NODE..."

  # Create a dynamic ConfigMap embedding each file's contents
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

done

echo "All ConfigMaps created!"
wait
