# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
        for rc in ~/.bashrc.d/*; do
                if [ -f "$rc" ]; then
                        . "$rc"
                fi
        done
fi

export EDITOR="nvim"
export VISUAL="nvim"
export PATH=$PATH:/home/rajko/.flutter/flutter/bin
export PATH=$PATH:'/home/rajko/Documents/Test/quickemu'
. "$HOME/.cargo/env"
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$(go env GOPATH)/bin
export PATH=/home/rajko/.opencode/bin:$PATH
export PATH="$PATH:$HOME/.dotnet/tools"
export PATH="$PATH:$HOME/.local/bin"

alias azurite='azurite -l /home/rajko/.azurite/ '
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias ldn='dotnet Lazydotnet'
alias ldf='lazygit --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias cointop='flatpak run --branch=stable --arch=x86_64 --command=cointop com.github.miguelmota.Cointop'

#yazi stay in folder after quit (q)
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# install bash-preexec if missing
if [[ ! -f ~/.bash-preexec.sh ]]; then
    curl -o ~/.bash-preexec.sh https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh
fi
source ~/.bash-preexec.sh

eval "$(starship init bash)"
eval "$(atuin init bash --disable-up-arrow)"
export PATH=$PATH:$HOME/.local/bin
