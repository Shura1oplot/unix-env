# .zprofile is sourced by login shells, after /etc/zprofile. On macOS
# /etc/zprofile runs path_helper, which moves the system directories back to
# the front of PATH, so the sorter defined in .zshenv runs once more here.

(( $+functions[zsh_sort_path] )) \
    && zsh_sort_path

if [[ $- =~ i && -z "$TMUX" && -n "$SSH_TTY" ]]; then
    if command -v tmux >/dev/null 2>&1; then
        tmux attach-session -t ssh_tmux 2>/dev/null || exec tmux new-session -s ssh_tmux
        exec tmux attach-session -t ssh_tmux
    fi
fi
