#!/usr/bin/env bash

set -euo pipefail

THIS_SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

source "$THIS_SCRIPT_DIR/.env"

brew install fnm

fnm install "$NODE_VERSION"
