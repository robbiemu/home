. ~/.bash_prompt
. ~/.bash_commands

PATH=${PATH}:~/bin
MANPATH=${MANPATH}:~/bin/man:~/bin/share/man

# Make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
PAGER=less

if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi
bind 'set match-hidden-files off'

set -b
set echo-control-characters off

shopt -s extglob

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Space-triggered completion for '!'
bind Space:magic-space

HISTTIMEFORMAT='[%T] '
HISTIGNORE="clear:reset:history:exit:pd:up:down:..:cd..:cd ..:cd:ls:lsf:lsr:lsrf:lsd:[bf]g"
HISTCONTROL=erasedups:ignoreboth
HISTSIZE=2000
shopt -s histappend

# make bash autocomplete with up arrow  
bind '"\e[A":history-search-backward'  
bind '"\e[B":history-search-forward' 

#load rvm if present
if [[ -d "$HOME/.rvm" ]]; then
    [[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
RBXOPT="-X19 bin/rbx -v"
fi

export `grep -P '^[^\=:space:]*?\=' $HOME/.bashrc | sed 's/=.*//g' |xargs`
