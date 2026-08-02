#!/usr/bin/env bash

set -euo pipefail

THIS_SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

source "$THIS_SCRIPT_DIR/.env"



if [[ $(uname) == Linux ]]; then
    sudo apt-get update
    sudo apt-get dist-upgrade -y
    sudo apt-get autoremove -y

    command -v snap &>/dev/null \
        && sudo snap refresh
fi

if command -v brew &>/dev/null; then
    [[ $(id -u) == 0 ]] \
        && touch /.dockerenv
    brew update
    brew upgrade --yes
    [[ $(id -u) == 0 && -f /.dockerenv ]] \
        && rm /.dockerenv
fi

if command -v uv &>/dev/null; then
    uv self update || true
    uv python install --preview-features python-install-default \
        --default --upgrade "$PYTHON_VERSION"
    uv tool upgrade --all \
        || uv tool upgrade --reinstall --all
fi

if command -v fnm &>/dev/null; then
    mkdir -p "$THIS_SCRIPT_DIR/tmp"

    set +eo pipefail

    npm ls --global --depth=0 --json 2>/dev/null \
        | jq -r '.dependencies // {} | keys[] | select(. != "npm" and . != "corepack")' \
        > "$THIS_SCRIPT_DIR/tmp/npm.list"

    set -eo pipefail

    fnm install "$NODE_VERSION"
    fnm default "$NODE_VERSION"
    fnm use "$NODE_VERSION"
    eval "$(fnm env --shell bash)"

    npm_list=$(cat "$THIS_SCRIPT_DIR/tmp/npm.list")

    if [[ -n $npm_list ]]; then
        # shellcheck disable=SC2086
        npm install --global $npm_list
    fi

    unset npm_list
fi


if command -v npm &>/dev/null; then
    npm update --global
fi

if command -v codex &>/dev/null; then
    codex update
fi

if command -v claude &>/dev/null; then
    claude update
fi

if command -v pi &>/dev/null; then
    pi update
    pi update --extensions
fi

if command -v hermes &>/dev/null; then
    hermes update
fi

if command -v openclaw &>/dev/null; then
    openclaw update
fi

if command -v skills &>/dev/null; then
    skills update --global --yes
fi

if command -v cloakbrowser &>/dev/null; then
    cloakbrowser update
fi

"$THIS_SCRIPT_DIR/sync-agent-env.sh"
