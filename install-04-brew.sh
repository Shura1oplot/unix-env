#!/usr/bin/env bash

set -euo pipefail


if [[ $(id -u) == 0 ]]; then
    touch /.dockerenv
fi

if command -v brew >/dev/null 2>&1; then
    brew update
    brew upgrade --yes

else
    # https://brew.sh/
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

fi

case $(uname) in
    Darwin) brew_home=/opt/homebrew ;;
    Linux)  brew_home=/home/linuxbrew/.linuxbrew ;;
esac

eval "$("$brew_home/bin/brew" shellenv)"


brew install \
    jq yq \
    neovim \
    uv \
    shellcheck \
    ripgrep fzf zoxide eza bat bat-extras fd duf dust procs \
    yazi sevenzip font-symbols-only-nerd-font

if [[ $(id -u) == 0 && -f /.dockerenv ]]; then
    rm /.dockerenv
fi
