#!/usr/bin/env bash

set -euo pipefail

git config --global credential.helper store

# prefer ipv4
# shellcheck disable=SC2028
if [[ -f /etc/gai.conf ]]; then
    echo -e "\n\nprecedence ::ffff:0:0/96  100\n" \
        | sudo tee -a /etc/gai.conf
fi
