#!/usr/bin/env bash

set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

function fail() {
    printf 'test-sync-agent-env: %s\n' "$1" >&2
    exit 1
}

function run_in_container() {
    local user_file=/home/tedo/projects/user-project/.claude/settings.local.json
    local root_file=/root/agents/root-project/.claude/settings.local.json
    local before_hash before_metadata

    [[ $HOME == /root ]] \
        || fail 'container HOME is not /root'

    install -d -o 1000 -g 1000 \
        /home/tedo/projects/user-project/.claude \
        /home/tedo/projects/user-project/.venv
    printf '%s\n' '{"sentinel":"user"}' >"$user_file"
    chown -R 1000:1000 /home/tedo/projects/user-project
    chmod 600 "$user_file"

    install -d /root/agents/root-project/.venv

    before_hash=$(sha256sum "$user_file")
    before_metadata=$(stat -c '%u:%g:%a' "$user_file")

    PATH=/repo/tests/fixtures:/usr/bin:/bin /repo/sync-agent-env.sh

    [[ $(sha256sum "$user_file") == "$before_hash" ]] \
        || fail 'content of the other user project changed'
    [[ $(stat -c '%u:%g:%a' "$user_file") == "$before_metadata" ]] \
        || fail 'ownership or mode of the other user project changed'
    [[ -s /root/.claude/settings.json ]] \
        || fail 'root user settings were not updated'
    [[ -s $root_file ]] \
        || fail 'root project settings were not updated'
}

if [[ ${1:-} == --inside-container ]]; then
    run_in_container
    exit 0
fi

command -v docker >/dev/null \
    || fail 'docker is required for the ownership test'

docker run --rm \
    --volume "$repo_dir:/repo:ro" \
    --entrypoint /usr/bin/bash \
    debian:trixie-slim \
    /repo/tests/test-sync-agent-env.sh --inside-container
