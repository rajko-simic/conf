# Source global definitions (macOS equivalent)
if [ -f /etc/zshrc ]; then
        . /etc/zshrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Source additional config files (equivalent of .bashrc.d)
if [ -d ~/.zshrc.d ]; then
        for rc in ~/.zshrc.d/*; do
                if [ -f "$rc" ]; then
                        . "$rc"
                fi
        done
fi

TIME_COLOR=$'\e[0;36m'
USERHOST_COLOR=$'\e[1;32m'
DIR_COLOR=$'\e[1;34m'
GIT_BRANCH_COLOR=$'\e[1;33m'
ARROW_COLOR=$DIR_COLOR
RESET=$'\e[0m'

setopt PROMPT_SUBST

git_prompt() {
    local branch
    branch=$(git branch 2>/dev/null | grep "^*" | sed "s/* \(.*\)/\1/")
    [ -n "$branch" ] && echo " %{${GIT_BRANCH_COLOR}%}($branch)%{${RESET}%}"
}

PROMPT="%{${ARROW_COLOR}%}┌─ %{${TIME_COLOR}%}%n%{${RESET}%}@%{${USERHOST_COLOR}%}%m%{${RESET}%} %{${DIR_COLOR}%}%~%{${RESET}%}"'$(git_prompt)'"
%{${ARROW_COLOR}%}└──%% %{${RESET}%}"

unset rc
export EDITOR="nvim"
export VISUAL="nvim"

# .NET tools
export PATH="$HOME/.dotnet/tools:$PATH"

# Cargo (macOS path is the same)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Android SDK
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools

export PATH=$PATH:$HOME/.flutter/flutter/bin
export PATH=$PATH:$HOME/Documents/Test/quickemu
command -v go &> /dev/null && export PATH=$PATH:$(go env GOPATH)/bin
export PATH=$HOME/.opencode/bin:$PATH

alias azurite='azurite -l $HOME/.azurite/'
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias ldf='lazygit --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias ldn='dotnet Lazydotnet'
alias cointop='flatpak run --branch=stable --arch=x86_64 --command=cointop com.github.miguelmota.Cointop'
alias ls='eza -lh --group-directories-first --icons=auto --octal-permissions'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons=auto --group-directories-first --git --octal-permissions'
alias lta='lt -a'
alias ..='cd ..'

# cd noargs go home, else to dir
if command -v zoxide &> /dev/null; then
  alias cd="zd"
  zd() {
    if [ $# -eq 0 ]; then
      builtin cd ~ && return
    elif [ -d "$1" ]; then
      builtin cd "$1"
    else
      z "$@" && printf "\U000F17A9 " && pwd || echo "Error: Directory not found"
    fi
  }
fi

# yazi — stay in folder after quit
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# Report cwd to the terminal (OSC 7) so new Konsole tabs/windows inherit it,
# and so Konsole's reported url doesn't stay stuck on Yazi's last directory.
# zsh has precmd hooks natively, so no bash-preexec equivalent is needed.
__osc7_cwd() {
    if [[ -x /usr/libexec/vte-urlencode-cwd ]]; then
        printf '\e]7;file://%s\e\\' "$(/usr/libexec/vte-urlencode-cwd)"
    else
        local LC_ALL=C url="" ch
        for ch in ${(s::)PWD}; do
            case $ch in
                [-_.~/A-Za-z0-9]) url+=$ch ;;
                *) url+=$(printf '%%%02X' "'$ch") ;;
            esac
        done
        printf '\e]7;file://%s\e\\' "$url"
    fi
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd __osc7_cwd

# ---- Terminal-following colors ----
# Everything below references the terminal's 16 ANSI slots, never hex, so the
# whole CLI stack retints when the Konsole colorscheme changes.
[ -f ~/.dircolors ] && eval "$(dircolors -b ~/.dircolors)"

export FZF_DEFAULT_OPTS="--color=16 \
--color=fg:-1,bg:-1,gutter:-1,query:-1 \
--color=fg+:15,bg+:8,hl:4,hl+:6 \
--color=info:5,prompt:1,pointer:1,marker:2,spinner:3 \
--color=header:8,border:8,disabled:8,scrollbar:8"
# ---- end terminal-following colors ----

eval "$(starship init zsh)"
eval "$(atuin init zsh --disable-up-arrow)"
eval "$(zoxide init zsh)"

