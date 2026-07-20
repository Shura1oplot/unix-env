if [[ $- =~ i && -z "$TMUX" && -n "$SSH_TTY" ]]; then
    if command -v tmux >/dev/null 2>&1; then
        tmux attach-session -t ssh_tmux 2>/dev/null || exec tmux new-session -s ssh_tmux
        exec tmux attach-session -t ssh_tmux
    fi
fi
