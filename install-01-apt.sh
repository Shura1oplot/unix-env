#!/usr/bin/env bash

# zemlekop: users-managed

set -euo pipefail

command -v apt-get &>/dev/null \
    || exit

sudo apt-get update
sudo apt-get dist-upgrade -y

sudo apt-get install -y \
    zsh \
    tmux \
    htop \
    lsof \
    wget curl \
    ca-certificates \
    zip unzip unar 7zip 7zip-rar unrar \
    git \
    build-essential

echo 'run `sudo shutdown -r now`'
