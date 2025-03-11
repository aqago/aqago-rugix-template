#!/bin/bash

set -euo pipefail

ENV_FILE="${RUGIX_PROJECT_DIR}/.env"

if [ ! -e "$ENV_FILE" ]; then
    exit 0
fi

# Inject public SSH key from local environment file.
echo ".env" >> "${LAYER_REBUILD_IF_CHANGED}"
. "${ENV_FILE}"
echo "${DEV_SSH_KEY:-""}" >>"${RUGIX_ROOT_DIR}/root/.ssh/authorized_keys"
