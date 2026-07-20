#!/usr/bin/env bash

set -euo pipefail

command -v apt-get &>/dev/null \
    || exit

sudo apt-get update
sudo apt-get dist-upgrade -y

sudo apt-get install -y \
    zsh \
    tmux \
    htop \
    wget curl \
    ca-certificates \
    zip unzip p7zip-full unar unrar \
    neovim \
    git \
    build-essential \
    jq shellcheck ripgrep
