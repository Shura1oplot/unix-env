#!/usr/bin/env bash

# zemlekop: users-managed
set -euo pipefail

IS_BREW=true

if [[ $(uname) == Linux && $(id -u) != 0 ]]; then
    brew_group=$(stat -c '%G' /home/linuxbrew/.linuxbrew/Cellar)

    if ! id -nG | grep -qw "$brew_group"; then
        IS_BREW=false
    fi
fi

declare -A latest=() python_remove=()

node_remove=()
python_inventory=$(uv python list --only-installed --managed-python --color never | sort -Vr)
node_inventory=$(FNM_LOGLEVEL=info NO_COLOR=1 fnm list | sort -Vr)

while read -r key _; do
    [[ $key =~ ^cpython-(3\.[0-9]+)\.[0-9]+(\+[^-]+)?-(.+)$ ]] \
        || continue
    group=${BASH_REMATCH[1]}${BASH_REMATCH[2]}-${BASH_REMATCH[3]}
    latest[$group]=${latest[$group]:-$key}
    [[ $key != "${latest[$group]}" ]] \
        || continue
    python_remove[$key]=1
done <<<"$python_inventory"

while read -r marker key _; do
    [[ $marker == '*' && $key =~ ^v([0-9]+)\.[0-9]+\.[0-9]+$ ]] \
        || continue
    group=node${BASH_REMATCH[1]}
    latest[$group]=${latest[$group]:-$key}
    [[ $key != "${latest[$group]}" ]] \
        || continue
    node_remove+=("$key")
done <<<"$node_inventory"


for key in "${!python_remove[@]}"; do
    uv python uninstall "$key"
done


for key in "${node_remove[@]}"; do
    fnm uninstall "$key"
done
