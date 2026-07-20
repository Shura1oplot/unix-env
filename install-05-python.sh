#!/usr/bin/env bash

set -euo pipefail

THIS_SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

source "$THIS_SCRIPT_DIR/.env"

uv python install --preview-features python-install-default \
    --default --upgrade "$PYTHON_VERSION"

for tool in black ruff basedpyright pylint markitdown; do
    uv tool install "$tool"
done
