#!/usr/bin/env bash

# zemlekop: users-managed

set -euo pipefail

THIS_SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

source "$THIS_SCRIPT_DIR/.env"


set +e

set +o pipefail

openclaw gateway stop --force
curl -fsSL https://openclaw.ai/install-cli.sh \
    | bash -s -- --runtime-only --no-onboard
OPENCLAW_SERVICE_REPAIR_POLICY=external \
    openclaw doctor --fix --force --non-interactive
openclaw update repair --yes --accept-capabilities
OPENCLAW_SERVICE_REPAIR_POLICY=external \
    openclaw doctor --fix --force --non-interactive
openclaw gateway install --force \
    --runtime-path "$HOME/.openclaw/tools/node/bin/node"

set -e

set -o pipefail

deadline=$((SECONDS + 120))

until openclaw gateway status --require-rpc; do
    (( SECONDS < deadline )) \
        || exit 1
    sleep 5
done

echo "./update-openclaw.sh done!"
