#!/usr/bin/env bash

# zemlekop: users-managed

set -euo pipefail

THIS_SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

# shellcheck source=.env
source "$THIS_SCRIPT_DIR/.env"


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


if command -v fnm &>/dev/null; then
    npm_packages=

    if command -v npm &>/dev/null; then
        npm_packages=$(npm ls --global --depth=0 --json |
            jq -r '.dependencies // {} | keys[] | select(. != "npm" and . != "corepack")')
    fi

    fnm_env=$(fnm env --shell bash)
    eval "$fnm_env"
    fnm install "$NODE_VERSION"
    fnm default "$NODE_VERSION"
    fnm use "$NODE_VERSION"

    if [[ -n $npm_packages ]]; then
        mapfile -t npm_list <<<"$npm_packages"
        npm install --global "${npm_list[@]}"
        npm rebuild --global --dangerously-allow-all-scripts "${npm_list[@]}"
        npm cache clean --force
    fi

    unset npm_packages npm_list fnm_env
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

if command -v openclaw &>/dev/null; then
    openclaw gateway stop --force || true
    openclaw update --yes --accept-capabilities || true
    OPENCLAW_SERVICE_REPAIR_POLICY=external \
        openclaw doctor --fix --force --non-interactive || true
    openclaw update repair --yes || true
    OPENCLAW_SERVICE_REPAIR_POLICY=external \
        openclaw doctor --fix --force --non-interactive || true
    openclaw gateway install --force
    openclaw gateway start
    openclaw gateway status --require-rpc --deep

    if command -v systemctl &>/dev/null; then
        systemctl --user daemon-reload
        systemctl --user restart openclaw-gateway.service || true
    fi

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
