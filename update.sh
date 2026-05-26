#!/usr/bin/env bash

set -euo pipefail

THIS_SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

. "$THIS_SCRIPT_DIR/.env"

sudo apt-get update
sudo apt-get dist-upgrade -y
sudo apt-get autoremove -y

command -v snap &>/dev/null \
    && sudo snap refresh

if command -v brew &>/dev/null; then
    brew update
    brew upgrade
fi

if command -v uv &>/dev/null; then
    uv self update || true
    uv python install --global "$PYTHON_VERSION"
    uv python upgrade
    uv tool upgrade --all
fi

if command -v fnm &>/dev/null; then
    fnm install "$NODE_VERSION"
    fnm use "$NODE_VERSION"
fi

if command -v npm &>/dev/null; then
    npm update -g
fi
