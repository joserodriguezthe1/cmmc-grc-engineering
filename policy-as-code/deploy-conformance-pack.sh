#!/usr/bin/env bash
# Deploy the CMMC L2 AWS Config conformance pack.
# PREREQUISITE: AWS Config must be enabled (terraform apply -var="enable_config=true").
# COST WARNING: AWS Config charges per configuration item and rule evaluation.
set -euo pipefail

PACK_NAME="${1:-CMMC-L2}"
TEMPLATE="$(dirname "$0")/conformance-packs/cmmc-l2-conformance-pack.yaml"

echo "Checking that AWS Config is recording..."
if ! aws configservice describe-configuration-recorder-status \
      --query 'ConfigurationRecordersStatus[0].recording' --output text 2>/dev/null | grep -qi true; then
  echo "ERROR: AWS Config recorder is not running."
  echo "Run: (cd terraform/environments/dev && terraform apply -var=enable_config=true)"
  exit 1
fi

echo "Deploying conformance pack '${PACK_NAME}'..."
aws configservice put-conformance-pack \
  --conformance-pack-name "${PACK_NAME}" \
  --template-body "file://${TEMPLATE}"

echo "Done. Check compliance with:"
echo "  aws configservice describe-conformance-pack-compliance --conformance-pack-name ${PACK_NAME}"
