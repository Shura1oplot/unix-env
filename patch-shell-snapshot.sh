#!/usr/bin/env bash

# Claude Code appends its own process PATH to the end of every shell snapshot,
# after .zshenv has already run, so the PATH built in dotfiles never reaches
# agent shells (anthropics/claude-code#42639, #43800). The Bash tool re-sources
# the snapshot on every call, so a restore line appended to the snapshot repairs
# PATH for all subsequent calls in that session.
#
# Hooked to PreToolUse(Bash), not SessionStart: the snapshot is created a few
# seconds after the session starts, and further snapshots appear later on, so
# SessionStart has nothing to patch yet.
#
# Re-sourcing .zshenv instead of exporting a rendered PATH keeps the dotfiles
# the single source of truth and lets zsh_project_env pick up the .venv and
# node_modules/.bin of the current project. Repeated sourcing is safe:
# zsh_sort_path declares `path` with typeset -gaU, which drops duplicates.

set -euo pipefail
shopt -s nullglob

marker='# sync-agent-env: PATH restored'

# Only zsh snapshots: .zshenv is zsh syntax and would break a bash snapshot.
for snapshot in "$HOME"/.claude/shell-snapshots/snapshot-zsh-*.sh; do
    grep -qF "$marker" "$snapshot" && continue

    # shellcheck disable=SC2016 # expanded by the snapshot shell, not by this script
    printf '\n%s\n[[ -f $HOME/.zshenv ]] && source "$HOME/.zshenv"\n' \
        "$marker" >> "$snapshot"
done

exit 0
