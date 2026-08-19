#!/usr/bin/env bash

set -euo pipefail

THIS_SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

source "$THIS_SCRIPT_DIR/.env"

if [[ $(id -u) == 0 ]] || id -nG | grep -qw sudo; then
    IS_SUDOER=true
else
    IS_SUDOER=false
fi


IS_BREW=true

if [[ $(uname) == Linux && $(id -u) == 0 ]]; then
    brew_group=$(stat -c '%G' /home/linuxbrew/.linuxbrew/Cellar)

    if ! id -nG | grep -qw "$brew_group"; then
        IS_BREW=false
    fi
fi


if [[ $(uname) == Linux && $IS_SUDOER ]]; then
    sudo apt-get update
    sudo apt-get dist-upgrade -y
    sudo apt-get autoremove --purge -y
    sudo apt-get autoclean -y

    if command -v snap &>/dev/null; then
        sudo snap refresh

        snap list --all | awk '/disabled/{print $1, $3}' \
                | while read -r snapname revision; do
            sudo snap remove "$snapname" --revision="$revision"
        done

        sudo bash -c "rm -f /var/lib/snapd/cache/*"
    fi
fi

if command -v brew &>/dev/null && $IS_BREW; then
    if [[ $(id -u) == 0 ]]; then
        touch /.dockerenv
    fi

    brew update
    brew upgrade --yes

    if [[ $(id -u) == 0 && -f /.dockerenv ]]; then
        rm /.dockerenv
    fi
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

# if command -v cloakbrowser &>/dev/null; then
#     cloakbrowser update
# fi

"$THIS_SCRIPT_DIR/sync-agent-env.sh"
