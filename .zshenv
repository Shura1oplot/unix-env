# .zshenv is always sourced

export PATH=$HOME/.local/bin:$HOME/bin:$PATH

export EDITOR=nvim

# shellcheck disable=SC1091
[[ -f $HOME/.cargo/env ]] \
    && source "$HOME/.cargo/env"

[[ $(uname) == Darwin && -d $HOME/.orbstack ]] \
    && export DOCKER_HOST=unix://$HOME/.orbstack/run/docker.sock


# Brew: gnubin

brew_path=

case $(uname) in
    Darwin) brew_path=/opt/homebrew ;;
    Linux)  brew_path=/home/linuxbrew/.linuxbrew ;;
esac

[[ -e $brew_path/bin/brew ]] \
    && eval "$("$brew_path/bin/brew" shellenv)"


if [[ $(uname) = Darwin && -n $HOMEBREW_PREFIX ]]; then
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
