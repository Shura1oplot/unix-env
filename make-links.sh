#!/usr/bin/env bash

# zemlekop: users-managed

set -euo pipefail

files=(
    .zshrc
    .zshenv
    .zprofile
    .tmux.conf
    .config/nvim/init.lua
    .config/yazi/yazi.toml
    .config/yazi/keymap.toml
    .config/herdr/config.toml
    .config/ghostty/config
)

for fname in "${files[@]}"; do
    mkdir -p "$(dirname "$HOME/$fname")"

    if [[ -e "$HOME/$fname" ]]; then
        mv -f -- "$HOME/$fname" "$HOME/$fname.bak"
    fi

    ln -s -- "$(pwd)/$fname" "$HOME/$fname"
done
