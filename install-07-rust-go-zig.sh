#!/usr/bin/env bash

# zemlekop: users-managed

set -euo pipefail

if [[ $(id -u) == 0 ]]; then
    touch /.dockerenv
fi

brew install --yes go rustup zig

if [[ $(id -u) == 0 && -f /.dockerenv ]]; then
    rm /.dockerenv
fi

rustup default stable
rustup update
