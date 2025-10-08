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

get_git_branch() {
    branch=$(git branch 2>/dev/null | grep "^*" | sed "s/* \(.*\)/\1/")
    if [ ! -z "$branch" ]; then
        echo " ($branch)"
    fi
}

# Define Colors
TIME_COLOR='\[\e[0;36m\]'         # Cyan for time
USERHOST_COLOR='\[\e[1;32m\]'     # Bright green for user@host
DIR_COLOR='\[\e[1;34m\]'          # Bright blue for directory
GIT_BRANCH_COLOR='\[\e[1;33m\]'   # Yellow for Git branch
ARROW_COLOR=$DIR_COLOR        # Bright red for arrow
#ARROW_COLOR='\[\e[1;31m\]'        # Bright red for arrow
RESET='\[\e[0m\]'                 # Reset to default color

# Define Formats
DATE_FORMAT='$(date +"%d %b")'
TIME_FORMAT='$(date +"%H:%M")'

# Construct PS1 Prompt first line
PS1="${ARROW_COLOR}┌─ ${TIME_COLOR}\u${RESET}@${USERHOST_COLOR}\h${RESET} ${DIR_COLOR} \w${RESET}"


# If IS_GIT is true, add the git branch information
GIT_BRANCH=$(get_git_branch)
if [ -n "$GIT_BRANCH" ]; then
    PS1+=" \n${ARROW_COLOR}├─${RESET_COLOR}${GIT_BRANCH_COLOR}$GIT_BRANCH${RESET_COLOR}"
fi
# Last line with arrow
PS1+="\n${ARROW_COLOR}└──\$ ${RESET}"

unset rc

export EDITOR="nvim"
export VISUAL="nvim"
export PATH=$PATH:/home/rajko/.flutter/flutter/bin
export PATH=$PATH:'/home/rajko/Documents/Test/quickemu'
. "$HOME/.cargo/env"
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools

alias azurite='azurite -l /home/rajko/.azurite/ '
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias ldf='lazygit --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias cointop='flatpak run --branch=stable --arch=x86_64 --command=cointop com.github.miguelmota.Cointop'

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

