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
)

for fname in "${files[@]}"; do
    mkdir -p "$(dirname "$HOME/$fname")"
    [[ -e "$HOME/$fname" ]] && mv -f -- "$HOME/$fname" "$HOME/$fname.bak"
    ln -s -- "$(pwd)/$fname" "$HOME/$fname"
done
