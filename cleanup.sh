#!/usr/bin/env bash

# zemlekop: users-managed

set -euo pipefail

declare -A latest=() python_remove=()

node_remove=()
python_inventory=$(uv python list --only-installed --managed-python --color never | sort -Vr)
node_inventory=$(FNM_LOGLEVEL=info NO_COLOR=1 fnm list | sort -Vr)

# Inventories are newest first; retain the first version in each group.

while read -r key _; do
    IFS=- read -r implementation version platform <<<"$key"
    IFS=+ read -r version variant <<<"$version"
    IFS=. read -r major minor patch <<<"$version"
    [[ $implementation == cpython && $major == 3 ]] \
        || continue

    case $minor$patch in
        *[!0-9]*) continue ;;
    esac

    group=python-$major.$minor-$variant-$platform
    latest[$group]=${latest[$group]:-$key}
    [[ $key != "${latest[$group]}" ]] \
        || continue
    python_remove[$key]=1
done <<<"$python_inventory"


while read -r marker key _; do
    IFS=. read -r major minor patch <<<"${key#v}"
    [[ $marker == '*' && $key == v* ]] \
        || continue

    case $major$minor$patch in
        *[!0-9]*) continue ;;
    esac

    group=node-$major
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
