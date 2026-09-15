#!/usr/bin/env bash

set -euo pipefail


if [[ $(id -u) == 0 ]]; then
    touch /.dockerenv
fi

brew install --yes go rustup

if [[ $(id -u) == 0 && -f /.dockerenv ]]; then
    rm /.dockerenv
fi

rustup default stable
rustup update
