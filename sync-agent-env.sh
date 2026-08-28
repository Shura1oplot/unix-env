#!/usr/bin/env bash

# Claude Code overwrites PATH in the shells it creates, after .zshenv has run,
# so PATH changes made in dotfiles never reach agent sessions. This script
# renders the login-shell PATH and stores it in Claude Code settings, which are
# applied to every new session:
#
# - ~/.claude/settings.json gets the user-wide PATH;
# - <project>/.claude/settings.local.json gets the same PATH with the project
#   uv environment in front, for every project that has one.
#
# Run it after changing PATH in .zshenv, or let the SessionStart hook run it.

set -euo pipefail

user_settings=$HOME/.claude/settings.json
zsh_bin=$(command -v zsh)

# Renders a variable in a login zsh started from $HOME, with the environment
# this script inherited discarded, so the result does not depend on the caller.
function render() {
    local expression=$1

    (
        cd "$HOME" \
            && env -i HOME="$HOME" TERM=xterm-256color "$zsh_bin" -lc "$expression"
    )
}

# Writes .env.PATH and .env.VIRTUAL_ENV into a settings file, creating the file
# when it is absent and leaving every other key untouched. Writes only when the
# values change, so that the SessionStart hook stays quiet.
function write_settings() {
    local file=$1 new_path=$2 venv=${3:-}
    local tmp

    [[ -f $file ]] || {
        mkdir -p -- "$(dirname -- "$file")"
        echo '{}' >"$file"
    }

    if [[ $(jq -r '.env.PATH // ""' "$file") == "$new_path"
            && $(jq -r '.env.VIRTUAL_ENV // ""' "$file") == "$venv" ]]; then
        return 0
    fi

    tmp=$(mktemp)

    if [[ -n $venv ]]; then
        jq --arg p "$new_path" --arg v "$venv" \
            '.env.PATH = $p | .env.VIRTUAL_ENV = $v' "$file" >"$tmp"
    else
        jq --arg p "$new_path" '.env.PATH = $p' "$file" >"$tmp"
    fi

    mv -- "$tmp" "$file"
    echo "sync-agent-env: updated $file"
}

# shellcheck disable=SC2016 # expanded by the zsh child, not by this script
base_path=$(render 'print -rn -- $PATH')

[[ -n $base_path ]] || {
    echo "sync-agent-env: rendered PATH is empty" >&2
    exit 1
}

write_settings "$user_settings" "$base_path"

# The project roots are declared once, in .zshenv.
# shellcheck disable=SC2016 # expanded by the zsh child, not by this script

while read -r root; do
    [[ -d $root ]] \
        || continue

    while read -r venv; do
        if [[ $venv == */_archive/* ]]; then
            continue
        fi

        project=${venv%/.venv}
        [[ -O $project ]] \
            || continue

        write_settings \
            "$project/.claude/settings.local.json" \
            "$venv/bin:$base_path" \
            "$venv"
    done < <(find "$root" -maxdepth 2 -type d -name .venv 2>/dev/null)
done < <(render 'print -l -- $ZSH_PROJECT_ROOTS')
