#!/usr/bin/env bash

# zemlekop: users-managed

set -euo pipefail


if [[ $(id -u) == 0 ]]; then
    touch /.dockerenv
fi

if command -v brew >/dev/null 2>&1; then
    brew update
    brew upgrade --yes

else
    # https://brew.sh/
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

fi

case $(uname) in
    Darwin) brew_home=/opt/homebrew ;;
    Linux)  brew_home=/home/linuxbrew/.linuxbrew ;;
esac

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

if [[ $(id -u) == 0 && -f /.dockerenv ]]; then
    rm /.dockerenv
fi

ya pkg add KKV9/compress
