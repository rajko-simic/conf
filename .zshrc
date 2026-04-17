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

alias azurite='azurite -l $HOME/.azurite/'
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias ldf='lazygit --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias ldn='dotnet Lazydotnet'

# yazi — stay in folder after quit
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}
