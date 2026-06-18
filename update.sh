#!/usr/bin/env bash

set -euo pipefail

THIS_SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

. "$THIS_SCRIPT_DIR/.env"


if [[ $(uname) == Linux ]]; then
    sudo apt-get update
    sudo apt-get dist-upgrade -y
    sudo apt-get autoremove -y

    command -v snap &>/dev/null \
        && sudo snap refresh
fi

if command -v brew &>/dev/null; then
    brew update
    brew upgrade --yes
fi

if command -v uv &>/dev/null; then
    uv self update || true
    uv python install --preview-features python-install-default \
        --default --upgrade "$PYTHON_VERSION"
    uv tool upgrade --all ||
        uv tool upgrade --reinstall --all
fi

if command -v fnm &>/dev/null; then
    fnm install "$NODE_VERSION"
    fnm use "$NODE_VERSION"
fi

command -v npm &>/dev/null \
    && npm update -g

command -v codex &>/dev/null \
    && codex update

command -v claude &>/dev/null \
    && claude update

command -v pi &>/dev/null \
    && pi update

command -v hermes &>/dev/null \
    && hermes update

command -v openclaw &>/dev/null \
    && openclaw update

command -v skills &>/dev/null \
    && skills update --global --yes
