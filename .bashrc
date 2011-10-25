. ~/.bash_prompt
. ~/.bash_commands

PATH=${PATH}:~/bin
MANPATH=${MANPATH}:~/bin/man:~/bin/share/man

# Make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
PAGER=less

if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi
bind 'set match-hidden-files off'

set -b

shopt -s extglob
shopt -s checkwinsize

# Space-triggered completion for '!'
bind Space:magic-space

HISTIGNORE="clear:reset:history:exit:pd:up:down:..:cd..:cd ..:cd:ls:lsf:lsr:lsrf:lsd:[bf]g"
HISTCONTROL=erasedups:ignoreboth
HISTSIZE=2000
shopt -s histappend

# make bash autocomplete with up arrow  
bind '"\e[A":history-search-backward'  
bind '"\e[B":history-search-forward' 

export `grep -e ^[[:alnum:]]*_*[[:alnum:]]*= /home/rob/.bashrc | sed 's/=.*//g' |xargs`
