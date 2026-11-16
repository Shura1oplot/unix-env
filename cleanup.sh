#!/usr/bin/env bash

set -euo pipefail


IS_BREW=true

if [[ $(uname) == Linux && $(id -u) != 0 ]]; then
    brew_group=$(stat -c '%G' /home/linuxbrew/.linuxbrew/Cellar)

    if ! id -nG | grep -qw "$brew_group"; then
        IS_BREW=false
    fi
fi

if [[ $(uname) == Linux ]] \
        && command -v brew &>/dev/null \
        && [[ $(id -u) == 0 ]]; then
    unalias brew &>/dev/null || true

    function brew() {
        (
            # runuser -u brew -- test -r . \
            #     || cd /
            cd /
            runuser -u brew -- "$HOMEBREW_PREFIX/bin/brew" "$@"
        )
    }
fi


declare -A latest=() python_remove=()

node_remove=()
python_inventory=$(uv python list --only-installed --managed-python --color never | sort -Vr)
node_inventory=$(FNM_LOGLEVEL=info NO_COLOR=1 fnm list | sort -Vr)

# Inventories are newest first; retain the first version in each group.

while read -r key _; do
    IFS=- read -r implementation version platform <<<"$key"
    IFS=+ read -r version variant <<<"$version"
    IFS=. read -r major minor patch <<<"$version"
    [[ $implementation == cpython && $major == 3 ]] \
        || continue

    case $minor$patch in
        *[!0-9]*) continue ;;
    esac

    group=python-$major.$minor-$variant-$platform
    latest[$group]=${latest[$group]:-$key}
    [[ $key != "${latest[$group]}" ]] \
        || continue
    python_remove[$key]=1
done <<<"$python_inventory"


while read -r marker key _; do
    IFS=. read -r major minor patch <<<"${key#v}"
    [[ $marker == '*' && $key == v* ]] \
        || continue

    case $major$minor$patch in
        *[!0-9]*) continue ;;
    esac

    group=node-$major
    latest[$group]=${latest[$group]:-$key}
    [[ $key != "${latest[$group]}" ]] \
        || continue
    node_remove+=("$key")
done <<<"$node_inventory"


for key in "${!python_remove[@]}"; do
    uv python uninstall "$key"
done

uv cache clean --force
npm cache clean --force

if command -v brew &>/dev/null && $IS_BREW; then
    brew cleanup --prune=all
fi

rm -rf -- "$HOME/.cache/node-gyp" "$HOME/Library/Caches/node-gyp" "$HOME/.cache/zig" \
    "$HOME/.local/share/Trash"

for key in "${node_remove[@]}"; do
    fnm uninstall "$key"
done

# Retain the newest browser build of each tool and the newest Node.js of OpenClaw.

for pattern in \
        "$HOME/.cloakbrowser/chromium-*-pro" \
        "$HOME/.agent-browser/browsers/chrome-*" \
        "$HOME/.cache/puppeteer/chrome/*" \
        "$HOME/.cache/puppeteer/chrome-headless-shell/*" \
        "$HOME/.openclaw/tools/node-v*"; do
    mapfile -t dirs < <(compgen -G "$pattern" | sort -Vr)
    rm -rf -- "${dirs[@]:1}"
done
