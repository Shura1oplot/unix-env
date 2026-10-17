#!/usr/bin/env bash

# zemlekop: users-managed

set -euo pipefail


git config --global credential.helper store
git config --global pull.rebase false


# prefer ipv4
# shellcheck disable=SC2028
if [[ -f /etc/gai.conf ]]; then
    echo -e "\n\nprecedence ::ffff:0:0/96  100\n" \
        | sudo tee -a /etc/gai.conf
fi


if [[ $(id -un) == pi ]]; then
    echo 'pi ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/010_pi-nopasswd >/dev/null
    sudo chmod 0440 /etc/sudoers.d/010_pi-nopasswd
    sudo visudo -cf /etc/sudoers.d/010_pi-nopasswd
fi
