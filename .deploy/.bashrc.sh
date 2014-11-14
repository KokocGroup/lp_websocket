# If not running interactively, don't do anything
[ -z "$PS1" ] && return

shopt -s cdspell
shopt -s histappend
PROMPT_COMMAND='history -a;history -n'

# don't put duplicate lines in the history. See bash(1) for more options
export HISTCONTROL=ignoredups:ignorespace
export HISTIGNORE="&:ls:[bf]g:exit"
export HISTSIZE=100500
export HISTFILESIZE=100500
export PROMPT_DIRTRIM=3
export PIP_DOWNLOAD_CACHE=~/.pip-cache

shopt -s autocd cdspell checkjobs cmdhist dirspell globstar

if [ ! -f "~/.inputrc" ]; then
    echo 'set completion-ignore-case on' >> ~/.inputrc
    echo '"\e[A": history-search-backward' >> ~/.inputrc
    echo '"\e[B": history-search-forward' >> ~/.inputrc
    echo '"\eOA": history-search-backward' >> ~/.inputrc
    echo '"\eOB": history-search-forward' >> ~/.inputrc
fi

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

shopt -u mailwarn
unset MAILCHECK

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" -a -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
xterm-color)
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    ;;
*)
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
    ;;
esac

# Comment in the above and uncomment this below for a color prompt
WHITE='\[\033[1;37m\]'
LIGHTGRAY='\[\033[0;37m\]'
GRAY='\[\033[1;30m\]'
BLACK='\[\033[0;30m\]'
RED='\[\033[0;31m\]'
LIGHTRED='\[\033[1;31m\]'
GREEN='\[\033[0;32m\]'
LIGHTGREEN='\[\033[1;32m\]'
BROWN='\[\033[0;33m\]'
YELLOW='\[\033[1;33m\]'
BLUE='\[\033[0;34m\]'
LIGHTBLUE='\[\033[1;34m\]'
PURPLE='\[\033[0;35m\]'
PINK='\[\033[1;35m\]'
CYAN='\[\033[0;36m\]'
LIGHTCYAN='\[\033[1;36m\]'
NORMAL='\[\033[0m\]'
NNORMAL='\[\033[0;33m\]'

SMILEY="${LIGHTBLUE}:o)${NORMAL}"
FROWNY="${RED}:o(${NORMAL}"

source /etc/bash_completion.d/git

SELECT="if [ \$? = 0 ]; then echo -n \"${SMILEY}\"; else echo -n \"${FROWNY}\"; fi; if [ -w '${PWD}' ]; then echo -n \" ${LIGHTGREEN}\w\"; else echo -n \" ${LIGHTRED}\w\"; fi ;"

GIT="__git_ps1 \" (%s)\";"
PS1="${RESET}${LIGHTGRAY}\u${GRAY}@${WHITE}\h${GRAY}:\`${SELECT}\`${RED}\`${GIT}\`# ${WHITE}"

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD/$HOME/~}\007"'
    ;;
*)
    ;;
esac

function _exit()
{
    echo -e "Goodbye `whoami`!"
}
trap _exit EXIT

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable color support of ls and also add handy aliases
if [ "$TERM" != "dumb" ]; then
    eval "`dircolors -b`"
    alias ls='ls --color=auto'
fi

alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'
alias la='ls -Al'
alias ls='ls -hF --color'
alias grep='grep --color=auto'
alias lx='ls -lXB'
alias lk='ls -lSr'
alias lc='ls -lcr'
alias lu='ls -lur'
alias lr='ls -lR'
alias lt='ls -ltr'
alias lm='ls -al |more'
alias tree='tree -Csu'
alias xs='cd'
alias vf='cd'
alias moer='more'
alias moew='more'
alias kk='ll'
alias scp="scp -r"
alias rsync="rsync -P"
alias wget='wget -c --connect-timeout=5 --random-wait --no-check-certificate --retry-connrefused -t 0'

ex () {
if [ -f $1 ] ; then
    case $1 in
    *.tar.bz2) tar xjf $1 ;;
    *.tar.gz) tar xzf $1 ;;
    *.bz2) bunzip2 $1 ;;
    *.rar) rar x $1 ;;
    *.gz) gunzip $1 ;;
    *.tar) tar xf $1 ;;
    *.tbz2) tar xjf $1 ;;
    *.tgz) tar xzf $1 ;;
    *.zip) unzip $1 ;;
    *.Z) uncompress $1 ;;
    *.7z) 7z x $1 ;;
    *) echo "'$1' cannot be extracted via extract()" ;;
    esac
    else
    echo "'$1' is not a valid file"
    fi
}

pk () {
 if [ $1 ] ; then
 case $1 in
 tbz)       tar cjvf $2.tar.bz2 $2      ;;
 tgz)       tar czvf $2.tar.gz  $2       ;;
 tar)      tar cpvf $2.tar  $2       ;;
 bz2)    bzip $2 ;;
 gz)        gzip -c -9 -n $2 > $2.gz ;;
 zip)       zip -r $2.zip $2   ;;
 7z)        7z a $2.7z $2    ;;
 *)         echo "'$1' cannot be packed via pk()" ;;
 esac
 else
 echo "'$1' is not a valid file"
 fi
}

if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

function activate_venv {
    git rev-parse --git-dir >& /dev/null
    if [ $? == 0 ]; then
        if [ -d "../venv" ]; then
            . ../venv/bin/activate
        fi
    fi
}

function venv_cd {
    cd "$@" && activate_venv
}

alias cd='venv_cd'


function cd_lpg {
    cd "/srv/projects/notify.lpgenerator.ru"
}
alias lpg_logs='tailf /var/log/nginx/lpg.access.log'

function lpg_update {
    cd /srv/projects/lpgenerator.ru/www
    git pull origin master
    lpgpy ./manage.py syncdb
    lpgpy ./manage.py migrate
    touch touch.reload
}

function lpg_top {
    filename="/var/log/nginx/access.log"
    if [ -f "/var/log/nginx/lpg.access.log" ]; then
        filename="/var/log/nginx/lpg.access.log"
    fi
    tail -f $filename|cut -d ' ' -f6|logtop
}


if [ -z "$WINDOW" ]; then
    if $(screen -ls | grep -q pts); then screen -x; else screen -R; fi
else
    cd_lpg
fi
