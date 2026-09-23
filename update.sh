#!/usr/bin/env bash

# zemlekop: users-managed

set -euo pipefail

THIS_SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

# shellcheck source=.env
source "$THIS_SCRIPT_DIR/.env"


fnm_node=
openclaw_command=

if command -v openclaw &>/dev/null; then
    openclaw_command=$(command -v openclaw)
    openclaw_command=$(realpath "$(dirname "$openclaw_command")")/$(basename "$openclaw_command")
fi


if [[ $(id -u) == 0 ]] || id -nG | grep -qw sudo; then
    IS_SUDOER=true
else
    IS_SUDOER=false
fi


IS_BREW=true

if [[ $(uname) == Linux && $(id -u) != 0 ]]; then
    brew_group=$(stat -c '%G' /home/linuxbrew/.linuxbrew/Cellar)

    if ! id -nG | grep -qw "$brew_group"; then
        IS_BREW=false
    fi
fi


if [[ $(uname) == Linux ]] && $IS_SUDOER; then
    sudo apt-get update
    sudo apt-get dist-upgrade -y
    sudo apt-get autoremove --purge -y
    sudo apt-get autoclean -y
    sudo apt-get clean -y

    if command -v snap &>/dev/null; then
        sudo snap refresh

        snap list --all \
            | awk '/disabled/{print $1, $3}' \
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

    brew update || true
    brew upgrade --yes
    brew cleanup

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
    uv cache prune
fi


if [[ -n $openclaw_command ]]; then
    "$openclaw_command" gateway stop --force
fi


if command -v fnm &>/dev/null; then
    npm_packages=

    if command -v npm &>/dev/null; then
        npm_packages=$(npm ls --global --depth=0 --json |
            jq -r '.dependencies // {} | keys[] | select(. != "npm" and . != "corepack")')
    fi

    eval "$(fnm env --shell bash)"
    fnm install "$NODE_VERSION"
    fnm default "$NODE_VERSION"
    fnm use "$NODE_VERSION"

    fnm_node=$(node -p 'process.execPath')
    NPM_CONFIG_PREFIX=$(dirname "$(dirname "$fnm_node")")
    export NPM_CONFIG_PREFIX

    if [[ -n $npm_packages ]]; then
        mapfile -t npm_list <<<"$npm_packages"
        npm install --global "${npm_list[@]}"
        npm rebuild --global --dangerously-allow-all-scripts "${npm_list[@]}"
        npm cache clean --force
    fi

    unset npm_packages npm_list
fi


if [[ -n $openclaw_command ]]; then
    (
        openclaw_previous=$openclaw_command
        openclaw_node=$fnm_node

        if [[ -n $fnm_node ]]; then
            openclaw_command=$(dirname "$fnm_node")/openclaw

            if [[ ! -e $openclaw_command ]]; then
                npm install --global openclaw --dangerously-allow-all-scripts --engine-strict
            fi
        elif command -v npm &>/dev/null; then
            openclaw_npm=$(npm prefix --global)/bin/openclaw

            if [[ -e $openclaw_npm && $(realpath "$openclaw_npm") == "$(realpath "$openclaw_command")" ]]; then
                openclaw_node=$(node -p 'process.execPath')
            fi
        fi

        if [[ -n $openclaw_node ]]; then
            OPENCLAW_SERVICE_REPAIR_POLICY=external \
                "$openclaw_command" doctor --fix --non-interactive
            "$openclaw_command" gateway install --force --runtime-path "$openclaw_node"
        else
            "$openclaw_command" update --yes --accept-capabilities --no-restart
            "$openclaw_command" gateway start
        fi

        "$openclaw_command" gateway status --require-rpc

        if [[ $openclaw_previous != "$openclaw_command" ]]; then
            rm -- "$openclaw_previous"
        fi

    )
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
    hermes update || true
fi

if command -v skills &>/dev/null; then
    skills update --global --yes
fi

if command -v cloakbrowser &>/dev/null; then
    cloakbrowser update
fi

if command -v agent-browser &>/dev/null; then
    agent_browser_args=

    if [[ $(uname) == Linux ]]; then
        if sudo -n yes; then
            agent_browser_args=--with-deps
        fi
    fi

    while ! agent-browser install $agent_browser_args; do
        :
    done
fi

"$THIS_SCRIPT_DIR/sync-agent-env.sh"

echo "./update.sh done!"
