#!/usr/bin/env bash

set -euo pipefail

THIS_SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

source "$THIS_SCRIPT_DIR/.env"

if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

uv python install --preview-features python-install-default \
    --default --upgrade "$PYTHON_VERSION"

for tool in black ruff basedpyright pylint markitdown; do
    uv tool install "$tool"
done
