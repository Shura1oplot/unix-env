#!/usr/bin/env bash

# zemlekop: users-managed

set -euo pipefail

THIS_SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

source "$THIS_SCRIPT_DIR/.env"


openclaw gateway stop --force || true
openclaw update --yes --accept-capabilities || true
OPENCLAW_SERVICE_REPAIR_POLICY=external \
    openclaw doctor --fix --force --non-interactive || true
openclaw update repair --yes || true
OPENCLAW_SERVICE_REPAIR_POLICY=external \
    openclaw doctor --fix --force --non-interactive || true
openclaw gateway install --force || true
openclaw gateway start || true
sleep 10
openclaw gateway status --require-rpc --deep || true
openclaw gateway status --require-rpc || true

if command -v systemctl &>/dev/null; then
    systemctl --user daemon-reload
    systemctl --user restart openclaw-gateway.service || true
fi


echo "./update-openclaw.sh done!"
