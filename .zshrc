# shellcheck disable=SC2034,SC2168,SC2128,SC2206

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

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
# DISABLE_MAGIC_FUNCTIONS="true"

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

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi
export EDITOR=nvim

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias git-rm-ignored='git rm --cached $(git ls-files -i -c -X .gitignore)'

# .zshrc is for interactive shells


# Hack for PuTTY (outdated?)
# printf "\e[?1004l"  # FocusIn/ FocusOut


# Node.js

NODE_VERSION=24

command -v fnm &>/dev/null \
    && eval "$(fnm env --shell zsh)" \
    && fnm use "$NODE_VERSION" &>/dev/null \
    || true


# pnpm
export PNPM_HOME=$HOME/Library/pnpm
export PATH=$PNPM_HOME/bin:$PATH
# pnpm end


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


# other

# shellcheck disable=SC1091
[[ -f $HOME/.orbstack/shell/init.zsh ]] \
    && source "$HOME/.orbstack/shell/init.zsh"

# shellcheck disable=SC1091
[[ -f $HOME/.acme.sh/acme.sh.env ]] \
    && source "$HOME/.acme.sh/acme.sh.env"

export PATH=$HOME/.browser-use/bin:$HOME/.browser-use-env/bin:$PATH

command -v direnv &>/dev/null \
    && eval "$(direnv hook zsh)"


# PATH sorter
# Must be in the end of .zshrc

typeset -aU path
local -a priority new_path current_path
current_path=($path)

priority=(
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

case $(uname) in
    Darwin) priority+=("/Applications/**"
                       "/Library/**"
                       "/System/**") ;;
    Linux)  priority+=("/snap/**"
                       "/opt/**"
                       "/usr/local/sbin"
                       "/usr/local/bin"
                       "/usr/local/**") ;;
esac

priority+=("/**/sbin" "/**/bin")

for pat in $priority; do
    local -a matches
    # shellcheck disable=SC2296
    matches=(${(M)current_path:#$~pat})
    new_path+=($matches)
    current_path=(${current_path:|matches})
done

new_path+=($current_path)
# shellcheck disable=SC1036
path=($^new_path(N-/))


# agents

project_roots=(
    "/Users/alexandergordeev/Documents/GitHub"
    "/Users/alexandergordeev/Documents/Projects"
    "/home/tedo/projects"
    "/root/agents"
)

for root in "${project_roots[@]}"; do
    [[ -d $root ]] || continue

    case $PWD in
        $root/*)
            dir=$PWD

            # shellcheck disable=SC2053
            while [[ $dir != $root ]]; do
                if [[ -f $dir/${UV_PROJECT_ENVIRONMENT:-.venv}/bin/activate ]]; then
                    old_pwd=$PWD
                    # shellcheck disable=SC1091
                    cd "$dir" \
                        && source "${UV_PROJECT_ENVIRONMENT:-.venv}/bin/activate"
                    cd "$old_pwd" || true
                    break
                fi

                dir=${dir:h}
            done

            dir=$PWD

            # shellcheck disable=SC2053
            while [[ $dir != $root ]]; do
                if [[ -d $dir/node_modules/.bin ]]; then
                    path=("$dir/node_modules/.bin" "${path[@]}")
                    break
                fi

                dir=${dir:h}
            done

            break
        ;;
    esac
done
