# shellcheck disable=SC2034,SC2168,SC2128,SC2206

# .zshrc is sourced by interactive shells only.
#
# Environment variables and PATH live in .zshenv, so that non-interactive
# shells, including the ones agents create, get the same environment. Keep only
# interactive configuration here: Oh My Zsh, themes, aliases, completions,
# keybindings, and shell functions.

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="eastwood"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="dd.mm.yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    sudo ssh
    brew
    docker docker-compose
    git gh
    procs
    rsync rclone
    uv
    fnm npm
    fzf zoxide eza
)

case $(uname) in
    Darwin) plugins+=(macos sublime sublime-merge) ;;
    Linux)
        plugins+=(systemd)

        if [[ -f /etc/lsb-release ]]; then
            linux_distrib=$(cat /etc/lsb-release | grep DISTRIB_ID | cut -d= -f2)

            case $linux_distrib in
                *Ubuntu*) plugins+=(ubuntu snap ufw) ;;
                *Debian*) plugins+=(debian) ;;
            esac
        fi
        ;;
esac

zstyle ':omz:plugins:eza' 'dirs-first' yes
zstyle ':omz:plugins:eza' 'git-status' yes
zstyle ':omz:plugins:eza' 'header' yes
zstyle ':omz:plugins:eza' 'icons' no
zstyle ':omz:plugins:eza' 'color-scale' size

# shellcheck disable=SC1091
source "$ZSH/oh-my-zsh.sh"

# User configuration

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.

alias git-rm-ignored='git rm --cached $(git ls-files -i -c -X .gitignore)'
alias sshl='ssh -L localhost:8000:localhost:8000 -L localhost:8080:localhost:8080'

# =============================================================================

# fnm, Node.js

NODE_VERSION=24

command -v fnm &>/dev/null \
    && eval "$(fnm env --shell zsh)" \
    && fnm use "$NODE_VERSION" &>/dev/null \
    || true

# Ghostty

if [[ $TERM_PROGRAM = ghostty || $TERM = xterm-ghostty ]]; then
    command -v mc &>/dev/null \
        && alias mc="TERM=xterm-256color mc"
    alias ssh="TERM=xterm-256color ssh"
fi

# yazi

function y() {
    local tmp
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# SDKMAN

# shellcheck disable=SC1091
[[ -s $SDKMAN_DIR/bin/sdkman-init.sh ]] \
    && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# gcloud

# shellcheck disable=SC1091
[[ -f $HOME/.google-cloud-sdk/completion.zsh.inc ]] \
    && source "$HOME/.google-cloud-sdk/completion.zsh.inc"

# direnv

command -v direnv &>/dev/null \
    && eval "$(direnv hook zsh)"

# =============================================================================
# Hints
# =============================================================================

unalias du df ls grep find 2>/dev/null || true

function du() {
    if [[ -t 1 ]]; then
        echo 'Hint: use `dust` or `ncdu` instead of `du`' >&2
    fi

    command du "$@"
}

function df() {
    if [[ -t 1 ]]; then
        echo 'Hint: use `duf` instead of `df`' >&2
    fi

    command df "$@"
}

function ls() {
    if [[ -t 1 ]]; then
        echo 'Hint: use `eza` instead of `ls`' >&2
    fi

    command ls "$@"
}

function grep() {
    if [[ -t 1 ]]; then
        echo 'Hint: use `rg` instead of `grep`' >&2
    fi

    command grep "$@"
}

function find() {
    if [[ -t 1 ]]; then
        echo 'Hint: use `fd` instead of `find`' >&2
    fi

    command find "$@"
}

function cat() {
    if [[ -t 1 ]]; then
        echo 'Hint: use `bat` instead of `cat`' >&2
    fi

    command cat "$@"
}

function ps() {
    if [[ -t 1 ]]; then
        echo 'Hint: use `procs` instead of `ps`' >&2
    fi

    command ps "$@"
}

function remind() {
    echo "ls -lah"
    echo "curl -fsSL"
    echo "ps aux"
    echo "ss -ntlp"
    echo "journalctl -u nginx -f"
}

# =============================================================================
# PATH sorter
# =============================================================================

(( $+functions[zsh_sort_path] )) \
    && zsh_sort_path

# =============================================================================

# echo ".zshrc ok"
