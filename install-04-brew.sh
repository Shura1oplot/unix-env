#!/usr/bin/env bash

# zemlekop: users-managed

set -euo pipefail

case $(uname) in
    Darwin) brew_home=/opt/homebrew ;;
    Linux) brew_home=/home/linuxbrew/.linuxbrew ;;
esac

as_brew=()

if [[ $(uname) == Linux && $(id -u) == 0 ]]; then
    if ! id brew &>/dev/null; then
        useradd -m brew
        mkdir -p "$brew_home"
        chown -R brew "$brew_home"
    fi

    as_brew=(runuser -u brew --)
    cd /
fi

function brew() {
    "${as_brew[@]}" "$brew_home/bin/brew" "$@"
}

if [[ -x $brew_home/bin/brew ]]; then
    brew update
    brew upgrade --yes
else
    # https://brew.sh/
    "${as_brew[@]}" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$("$brew_home/bin/brew" shellenv)"

brew install --yes \
    jq yq \
    neovim \
    gum \
    ripgrep fzf zoxide eza bat bat-extras fd procs \
    duf dust ncdu \
    yazi sevenzip font-symbols-only-nerd-font \
    just \
    btop \
    shellcheck shfmt \
    ast-grep \
    glow

ya pkg add KKV9/compress
