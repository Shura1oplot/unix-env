#!/usr/bin/env bash

set -euo pipefail

git config --global credential.helper store

# prefer ipv4
# shellcheck disable=SC2028
[[ -f /etc/gai.conf ]] \
    && echo -e "\n\nprecedence ::ffff:0:0/96  100\n" \
        | sudo tee -a /etc/gai.conf

git clone https://github.com/Shura1oplot/unix-env
