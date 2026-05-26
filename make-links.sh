#!/usr/bin/env bash

set -euo pipefail

files=(.zshrc .zshenv .zprofile .tmux.conf .config/nvim/init.lua)

for fname in "${files[@]}"; do
    mkdir -p "$(dirname "$HOME/$fname")"
    [[ -e "$HOME/$fname" ]] && mv -f -- "$HOME/$fname" "$HOME/$fname.bak"
    ln -s -- "$(pwd)/$fname" "$HOME/$fname"
done
