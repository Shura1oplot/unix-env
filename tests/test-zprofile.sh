#!/usr/bin/env bash

set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
fixture_dir=$repo_dir/tests/fixtures
profile=$repo_dir/.zprofile
zsh_bin=$(command -v zsh)
tmux_bin=$(command -v tmux)
temp_dir=$(mktemp -d)
socket_name=test-zprofile-$$

function cleanup() {
    rm -rf -- "$temp_dir"
}

function fail() {
    printf 'test-zprofile: %s\n' "$1" >&2
    exit 1
}

trap cleanup EXIT

non_terminal_log=$temp_dir/non-terminal.log
: >"$non_terminal_log"

TMUX='' \
    SSH_TTY=/dev/pts/test \
    LC_NO_TMUX='' \
    TMUX_CALL_LOG=$non_terminal_log \
    PATH=$fixture_dir:/usr/bin:/bin \
    "$zsh_bin" -fi "$profile" </dev/null

[[ ! -s $non_terminal_log ]] \
    || fail 'tmux was invoked without a real terminal'

terminal_log=$temp_dir/terminal.log
: >"$terminal_log"

"$tmux_bin" -L "$socket_name" -f /dev/null new-session -d -s terminal-check \
    env \
    TMUX='' \
    SSH_TTY=/dev/pts/test \
    LC_NO_TMUX='' \
    TMUX_CALL_LOG="$terminal_log" \
    PATH="$fixture_dir:/usr/bin:/bin" \
    "$zsh_bin" -fi "$profile"

for ((attempt = 0; attempt < 100; attempt++)); do
    [[ -s $terminal_log ]] \
        && break
    sleep 0.05
done

[[ $(<"$terminal_log") == 'new-session -A -s ssh_tmux' ]] \
    || fail 'interactive SSH did not make one atomic tmux invocation'
