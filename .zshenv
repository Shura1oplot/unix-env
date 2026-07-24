# .zshenv is always sourced: interactive, non-interactive, login, and agent
# shells. Everything that only sets environment variables, PATH included, lives
# here, so that non-interactive agent sessions get the same environment as a
# terminal.
#
# .zshrc is sourced by interactive shells only. Prompts, themes, aliases,
# completions, keybindings, and shell functions stay there.

export PATH=$HOME/.local/bin:$HOME/bin:$PATH

export EDITOR=nvim

# shellcheck disable=SC1091
[[ -f $HOME/.cargo/env ]] \
    && source "$HOME/.cargo/env"

[[ $OSTYPE == darwin* && -d $HOME/.orbstack ]] \
    && export DOCKER_HOST=unix://$HOME/.orbstack/run/docker.sock


# Brew: gnubin
#
# $OSTYPE instead of $(uname), and the HOMEBREW_PREFIX guard, keep this file
# fork-free for child shells: .zshenv runs for every zsh, scripts included.

brew_path=

case $OSTYPE in
    darwin*) brew_path=/opt/homebrew ;;
    linux*)  brew_path=/home/linuxbrew/.linuxbrew ;;
esac

if [[ -e $brew_path/bin/brew ]] \
    && [[ -z $HOMEBREW_PREFIX || :$PATH: != *:$brew_path/bin:* ]]; then
    eval "$("$brew_path/bin/brew" shellenv)"
fi


if [[ $OSTYPE == darwin* && -n $HOMEBREW_PREFIX ]]; then
    # Shadow-prefixed
    export PATH=$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH
    export PATH=$HOMEBREW_PREFIX/opt/findutils/libexec/gnubin:$PATH
    export PATH=$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin:$PATH
    export PATH=$HOMEBREW_PREFIX/opt/grep/libexec/gnubin:$PATH
    export PATH=$HOMEBREW_PREFIX/opt/gnu-which/libexec/gnubin:$PATH
    export PATH=$HOMEBREW_PREFIX/opt/make/libexec/gnubin:$PATH

    # keg-only
    export PATH=$HOMEBREW_PREFIX/opt/curl/bin:$PATH
    export PATH=$HOMEBREW_PREFIX/opt/gnu-getopt/bin:$PATH
fi

# How to find:
# brew info --installed --json=v1 | jq -r '.[] | select(.keg_only == true) | .name'
# brew info --installed --json=v1 | jq -r '.[] | select(.keg_only == true) | "\(.name): \(.keg_only_reason.reason)"'
# brew info --installed --json=v1 | jq -r '
#   .[] | select(
#     .keg_only == true or
#     (.caveats != null and (.caveats | contains("gnubin") or contains("libexec")))
#   ) | .name'

unset brew_path


# Node.js
#
# The default alias holds every globally installed Node CLI. Its bin directory
# goes on PATH here, so those CLIs are available in non-interactive shells
# without calling `fnm env`, which allocates a multishell directory per call.
# `fnm env` stays in .zshrc for interactive `fnm use` switching.

export FNM_DIR=${FNM_DIR:-$HOME/.local/share/fnm}

[[ -d $FNM_DIR/aliases/default/bin ]] \
    && export PATH=$FNM_DIR/aliases/default/bin:$PATH


# pnpm

export PNPM_HOME=$HOME/Library/pnpm
export PATH=$PNPM_HOME/bin:$PATH


# orbstack

# shellcheck disable=SC1091
[[ -f $HOME/.orbstack/shell/init.zsh ]] \
    && source "$HOME/.orbstack/shell/init.zsh"


# acme.sh

# shellcheck disable=SC1091
[[ -f $HOME/.acme.sh/acme.sh.env ]] \
    && source "$HOME/.acme.sh/acme.sh.env"


# browser-use

export PATH=$HOME/.browser-use/bin:$HOME/.browser-use-env/bin:$PATH


# bun

if [[ -d $HOME/.bun ]]; then
    export BUN_INSTALL=$HOME/.bun
    export PATH=$BUN_INSTALL/bin:$PATH
fi


# Android SDK

export ANDROID_HOME=$HOME/Library/Android/sdk
export SDKMAN_DIR=$HOME/.sdkman

export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin


# gcloud

# shellcheck disable=SC1091
[[ -f $HOME/.google-cloud-sdk/path.zsh.inc ]] \
    && source "$HOME/.google-cloud-sdk/path.zsh.inc"


# =============================================================================
# Project environment
# =============================================================================

# Walks up from the current directory to the project root and activates what
# the project provides: the uv environment and the local Node binaries. Lives
# here rather than in .zshrc so that agent sessions, which are non-interactive,
# get the project interpreter without activating it themselves.

typeset -ga ZSH_PROJECT_ROOTS=(
    "$HOME/Documents/GitHub"
    "$HOME/Documents/Projects"
    "/Volumes/T7/Projects"
    "/home/tedo/projects"
    "/root/agents"
)

function zsh_project_env() {
    local root dir venv

    venv=${UV_PROJECT_ENVIRONMENT:-.venv}

    for root in $ZSH_PROJECT_ROOTS; do
        [[ -d $root && $PWD == $root/* ]] || continue

        dir=$PWD

        while [[ $dir != $root ]]; do
            if [[ -z $VIRTUAL_ENV && -f $dir/$venv/bin/activate ]]; then
                # shellcheck disable=SC1091
                source "$dir/$venv/bin/activate"
                break
            fi

            dir=${dir:h}
        done

        dir=$PWD

        while [[ $dir != $root ]]; do
            if [[ -d $dir/node_modules/.bin ]]; then
                typeset -g ZSH_PROJECT_BIN=$dir/node_modules/.bin
                export PATH=$ZSH_PROJECT_BIN:$PATH
                break
            fi

            dir=${dir:h}
        done

        break
    done
}

zsh_project_env


# =============================================================================
# PATH sorter
# =============================================================================

# Called at the end of this file, and again from .zprofile, because macOS
# /etc/zprofile runs path_helper after .zshenv and moves the system directories
# back to the front.

function zsh_sort_path() {
    # -g because a function-local `path` would shadow the global one and empty PATH
    typeset -gaU path
    local -a priority new_path current_path matches
    local pat
    current_path=($path)

    # The project environment outranks everything, including $HOME/.local/bin,
    # because it may sit above the current directory and would otherwise lose
    # to the user-wide interpreter.
    priority=(
        "${VIRTUAL_ENV:-/nonexistent}/bin"
        "${ZSH_PROJECT_BIN:-/nonexistent}"
        "$PWD/.*/**"
        "$PWD/**"
        "$HOME/.local/bin"
        "$HOME/.*/**"
        "$HOME/**"
    )

    if [[ -n $HOMEBREW_PREFIX ]]; then
        priority+=(
            "$HOMEBREW_PREFIX/opt/**/gnubin"
            "$HOMEBREW_PREFIX/opt/**/libexec/**"
            "$HOMEBREW_PREFIX/opt/**"
            "$HOMEBREW_PREFIX/**/gnubin"
            "$HOMEBREW_PREFIX/**/libexec/**"
            "$HOMEBREW_PREFIX/**/sbin"
            "$HOMEBREW_PREFIX/**/bin"
            "$HOMEBREW_PREFIX/**"
        )
    fi

    case $OSTYPE in
        darwin*) priority+=("/Applications/**"
                            "/Library/**"
                            "/System/**") ;;
        linux*)  priority+=("/snap/**"
                            "/opt/**"
                            "/usr/local/sbin"
                            "/usr/local/bin"
                            "/usr/local/**") ;;
    esac

    priority+=("/**/sbin" "/**/bin")

    for pat in $priority; do
        # shellcheck disable=SC2296
        matches=(${(M)current_path:#$~pat})
        new_path+=($matches)
        current_path=(${current_path:|matches})
    done

    new_path+=($current_path)
    # shellcheck disable=SC1036
    path=($^new_path(N-/))
}

zsh_sort_path
