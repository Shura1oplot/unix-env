# .zprofile is sourced by login shells, after /etc/zprofile. On macOS
# /etc/zprofile runs path_helper, which moves the system directories back to
# the front of PATH, so the sorter defined in .zshenv runs once more here.

(( $+functions[zsh_sort_path] )) \
    && zsh_sort_path

if [[ $- =~ i && -t 0 && -t 1 && -z $TMUX && -n $SSH_TTY \
        && -z $LC_NO_TMUX ]]; then
    if [[ -n $ZED_TERM && -n $ZED_ENVIRONMENT && $USER == tedo \
            && -x "$HOME/zemlekop/tools/zed/agent-terminal.sh" ]]; then
        "$HOME/zemlekop/tools/zed/agent-terminal.sh" && exit
    fi

    if command -v tmux >/dev/null 2>&1; then
        exec tmux new-session -A -s ssh_tmux
    fi
fi
