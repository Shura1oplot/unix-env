#!/usr/bin/env bash

set -euo pipefail

THIS_SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

. "$THIS_SCRIPT_DIR/.env"

uv python install --default "$PYTHON_VERSION"

uv tool install black
uv tool install ruff
uv tool install basedpyright
uv tool install pylint

uv tool install markitdown
