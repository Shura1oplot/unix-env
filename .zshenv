# .zshenv is always sourced: interactive, non-interactive, login, and agent shells.

export PATH=$HOME/.local/bin:$HOME/bin:$PATH

export EDITOR=nvim

# shellcheck disable=SC1091

set -a

if [[ -f $HOME/.env ]]; then
    source "$HOME/.env"
fi

# shellcheck disable=SC1091
if [[ -f $HOME/.cargo/env ]]; then
    source "$HOME/.cargo/env"
fi

set +a

if [[ $OSTYPE == darwin* && -d $HOME/.orbstack ]]; then
    export DOCKER_HOST=unix://$HOME/.orbstack/run/docker.sock
fi

# Brew: gnubin

brew_path=

case $OSTYPE in
    darwin*) brew_path=/opt/homebrew ;;
    linux*)  brew_path=/home/linuxbrew/.linuxbrew ;;
esac

if [[ -e $brew_path/bin/brew ]]; then
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
    export PATH=$HOMEBREW_PREFIX/opt/gpatch/libexec/gnubin:$PATH

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

if [[ -d $FNM_DIR/aliases/default/bin ]]; then
    export PATH=$FNM_DIR/aliases/default/bin:$PATH
fi

# pnpm

export PNPM_HOME=$HOME/Library/pnpm
export PATH=$PNPM_HOME/bin:$PATH


# bun

if [[ -d $HOME/.bun ]]; then
    export BUN_INSTALL=$HOME/.bun
    export PATH=$BUN_INSTALL/bin:$PATH
fi


# orbstack

# shellcheck disable=SC1091
if [[ -f $HOME/.orbstack/shell/init.zsh ]]; then
    source "$HOME/.orbstack/shell/init.zsh"
fi

# acme.sh

# shellcheck disable=SC1091
if [[ -f $HOME/.acme.sh/acme.sh.env ]]; then
    source "$HOME/.acme.sh/acme.sh.env"
fi

# browser-use

export PATH=$HOME/.browser-use/bin:$HOME/.browser-use-env/bin:$PATH


# Android SDK

export ANDROID_HOME=$HOME/Library/Android/sdk
export SDKMAN_DIR=$HOME/.sdkman

export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin


# gcloud

# shellcheck disable=SC1091
if [[ -f $HOME/.google-cloud-sdk/path.zsh.inc ]]; then
    source "$HOME/.google-cloud-sdk/path.zsh.inc"
fi


# =============================================================================
# Project environment
# =============================================================================

autoload -Uz add-zsh-hook

typeset -ga ZSH_PROJECT_ROOTS=(
    "$HOME/Documents/GitHub"
    "$HOME/Documents/Projects"
    "/Volumes/T7/Projects"
    "/home/tedo/projects"
    "/root/agents"
)

function zsh_project_env() {
    local root dir venv_name
    local target_venv=
    local target_bin=

    venv_name=${UV_PROJECT_ENVIRONMENT:-.venv}

    for root in $ZSH_PROJECT_ROOTS; do
        [[ $PWD == $root/* ]] || continue

        dir=$PWD

        while [[ $dir != $root ]]; do
            [[ -z $target_venv && -f $dir/$venv_name/bin/activate ]] \
                && target_venv=$dir/$venv_name

            [[ -z $target_bin && -d $dir/node_modules/.bin ]] \
                && target_bin=$dir/node_modules/.bin

            [[ -n $target_venv && -n $target_bin ]] \
                && break

            dir=${dir:h}
        done

        break
    done

    [[ -n $ZSH_PROJECT_BIN && $ZSH_PROJECT_BIN != $target_bin ]] \
        && path=(${path:#$ZSH_PROJECT_BIN})

    typeset -g ZSH_PROJECT_BIN=$target_bin

    [[ -n $target_bin && ${path[(Ie)$target_bin]} -eq 0 ]] \
        && path=($target_bin $path)

    return 0
}

zsh_project_env
add-zsh-hook chpwd zsh_project_env


# =============================================================================
# PATH sorter
# =============================================================================

function zsh_sort_path() {
    # -g because a function-local `path` would shadow the global one and empty PATH
    typeset -gaU path
    local -a priority new_path current_path matches
    local pat
    current_path=($path)

    priority=(
        "${VIRTUAL_ENV:-/nonexistent}/bin"
        "${ZSH_PROJECT_BIN:-/nonexistent}"
        "$PWD/.*/**"
        "$PWD/**"
    )

    priority+=(
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
