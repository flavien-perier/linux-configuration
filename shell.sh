#!/bin/sh
# Flavien PERIER <perier@flavien.io>
# Install user profiles

set -e

OK="[\033[0;32mOK\033[0m]"
KO="[\033[0;31mKO\033[0m]"

LSC_USER_BIN=$(mktemp -dt lsc-XXXXXXX)
LSC_ZNAP=$(mktemp -dt znap-XXXXXXX)

print_bashrc() {
    echo '#!/bin/bash

shopt -s checkwinsize
command_not_found_handle() {
    printf "%s: command not found\n" "$1" >&2
}

export HISTSIZE=5000
export HISTFILESIZE=5000
export HISTIGNORE="ls:ll:pwd:clear"
export HISTCONTROL="ignoredups"
export HISTFILE="$HOME/.bash_history"

PREEXEC_TIME=0

function git_prompt() {
    local BRANCH=""
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ $? -eq 0 ]]
    then
        if git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null && [ -z "$(git ls-files --others --exclude-standard 2>/dev/null)" ]
        then
            printf " \e[m[\e[32m$BRANCH\e[m]\e[34m"
        else
            printf " \e[m[\e[31m$BRANCH\e[m]\e[34m"
        fi
    else
        printf ""
    fi
}

function exit_status_prompt() {
    local OLD_EXIT_STATUS=$1

    if [[ $OLD_EXIT_STATUS -ne 0 ]]
    then
        printf " \e[m(\e[31m$OLD_EXIT_STATUS\e[m)"
    else
        printf ""
    fi
}

function time_prompt() {
    local POSTEXEC_TIME="$1"

    if [[ $PREEXEC_TIME -ne 0 ]]
    then
        local DURATION="$(($POSTEXEC_TIME - PREEXEC_TIME))"

        if [[ $DURATION -ge 600000 ]]
        then
            local MIN="$(( DURATION / 60000 ))"
            local SEC="$(( DURATION / 1000 ))"
            printf " \e[90m%s m (%s s)" "$MIN" "$SEC"
        elif [[ $DURATION -ge 10000 ]]
        then
            local SEC="$(( DURATION / 1000 ))"
            local MS="$DURATION"
            printf " \e[90m%s s (%s ms)" "$SEC" "$MS"
        elif [[ $DURATION -ge 250 ]]
        then
            printf " \e[90m$DURATION ms"
        else
            printf ""
        fi
    else
        printf ""
    fi
}

function preexec() {
    if [[ $PREEXEC_TIME -eq 0 ]]
    then
        PREEXEC_TIME="$(date +%s%3N)"
    fi
}
trap "preexec" DEBUG

function precmd() {
    local OLD_EXIT_STATUS=$?
    local POSTEXEC_TIME="$(date +%s%3N)"

    local USER_COLOR="32"
    local USER_SYMBOL="%"

    if [[ $UID -eq 0 ]]
    then
        USER_COLOR="31"
        USER_SYMBOL="#"
    fi

    export PS1="\[\e[m\]\$(date +"%H:%M:%S") \e[1mB\e[m \[\e[${USER_COLOR}m\]\u@\H \[\e[34m\]\w\$(git_prompt)$(exit_status_prompt $OLD_EXIT_STATUS)$(time_prompt $POSTEXEC_TIME)\n\[\e[${USER_COLOR}m\]${USER_SYMBOL}\[\e[m\] > "

    PREEXEC_TIME=0
}

PROMPT_COMMAND=precmd

source $HOME/.alias'
}

print_zshrc() {
    echo '#!/usr/bin/env zsh

autoload -U compinit
compinit
zstyle ":completion:*:*:*:*:*" menu select
zstyle ":completion:*" auto-description "specify: %d"
zstyle ":completion:*" completer _expand _complete
zstyle ":completion:*" format "Completing %d"
zstyle ":completion:*" group-name ""
zstyle ":completion:*" list-colors ""
zstyle ":completion:*" list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ":completion:*" matcher-list "m:{a-zA-Z}={A-Za-z}"
zstyle ":completion:*" rehash true
zstyle ":completion:*" select-prompt %SScrolling active: current selection at %p%s
zstyle ":completion:*" use-compctl false
zstyle ":completion:*" verbose true
zstyle ":completion:*:kill:*" command "ps -u $USER -o pid,%cpu,tty,cputime,cmd"

export HISTSIZE=5000
export HISTFILESIZE=5000
export HISTIGNORE="ls:ll:pwd:clear"
export HISTCONTROL="ignoredups"
export HISTFILE="$HOME/.bash_history"

zmodload zsh/complist
setopt extendedglob
setopt promptsubst
zstyle ":completion:*:*:kill:*:processes" list-colors "=(#b) #([0-9]#)*=36=31"

source ~/.znap/znap/znap.zsh
znap source zsh-users/zsh-autosuggestions
znap source zsh-users/zsh-syntax-highlighting

setopt correctall

PREEXEC_TIME=0

function git_prompt() {
    local BRANCH=""
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ $? -eq 0 ]]
    then
        if git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null && [ -z "$(git ls-files --others --exclude-standard 2>/dev/null)" ]
        then
            print -Pn " %f[%F{green}$BRANCH%f]%F{blue}"
        else
            print -Pn " %f[%F{red}$BRANCH%f]%F{blue}"
        fi
    else
        print -Pn ""
    fi
}

function exit_status_prompt() {
    local OLD_EXIT_STATUS=$1

    if [[ $OLD_EXIT_STATUS -ne 0 ]]
    then
        print -Pn " %f(%F{red}$OLD_EXIT_STATUS%f)"
    else
        print -Pn ""
    fi
}

function time_prompt() {
    local POSTEXEC_TIME="$1"

    if [[ $PREEXEC_TIME -ne 0 ]]
    then
        local DURATION="$(($POSTEXEC_TIME - PREEXEC_TIME))"

        if [[ $DURATION -ge 600000 ]]
        then
            local MIN="$(( DURATION / 60000 ))"
            local SEC="$(( DURATION / 1000 ))"
            printf " \e[90m%s m (%s s)" "$MIN" "$SEC"
        elif [[ $DURATION -ge 10000 ]]
        then
            local SEC="$(( DURATION / 1000 ))"
            local MS="$DURATION"
            printf " \e[90m%s s (%s ms)" "$SEC" "$MS"
        elif [[ $DURATION -ge 250 ]]
        then
            printf " \e[90m$DURATION ms"
        else
            printf ""
        fi
    else
        printf ""
    fi
}

function preexec() {
    if [[ $PREEXEC_TIME -eq 0 ]]
    then
        PREEXEC_TIME="$(date +%s%3N)"
    fi
}

function precmd() {
    local OLD_EXIT_STATUS=$?
    local POSTEXEC_TIME="$(date +%s%3N)"

    local USER_COLOR="green"
    local USER_SYMBOL="%"

    if [[ $UID -eq 0 ]]
    then
        USER_COLOR="red"
        USER_SYMBOL="#"
    fi

    export PROMPT="%f%* %BZ%b %F{$USER_COLOR}%n@%m %F{blue}%~\$(git_prompt)$(exit_status_prompt $OLD_EXIT_STATUS)$(time_prompt $POSTEXEC_TIME)
%F{$USER_COLOR}%${USER_SYMBOL}%f > "

    PREEXEC_TIME=0
}

source $HOME/.alias'
}

print_fishrc() {
    echo '#!/usr/bin/env fish

set --universal fish_greeting ""
set -g fish_prompt_pwd_dir_length 10

function git_prompt
    set BRANCH (git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ $status -eq 0 ]
        set -l UNTRACKED (git ls-files --others --exclude-standard 2>/dev/null)
        if git diff --quiet 2>/dev/null; and git diff --cached --quiet 2>/dev/null; and test -z "$UNTRACKED"
            set_color normal
            echo -n " ["
            set_color green
            echo -n $BRANCH
            set_color normal
            echo -n "]"
            set_color blue
        else
            set_color normal
            echo -n " ["
            set_color red
            echo -n $BRANCH
            set_color normal
            echo -n "]"
            set_color blue
        end
    else
        echo -n ""
    end
end

function exit_status_prompt
    set OLD_EXIT_STATUS $argv

    if [ $OLD_EXIT_STATUS -ne 0 ]
        set_color normal
        echo -n " ("
        set_color red
        echo -n $OLD_EXIT_STATUS
        set_color normal
        echo -n ")"
    else
        echo -n ""
    end
end

function time_prompt
    if set -q CMD_DURATION
        if test $CMD_DURATION -ge 600000
            set min (math -s0 "$CMD_DURATION / 60000")
            set sec (math -s0 "$CMD_DURATION / 1000")
            set_color brblack
            echo -n " $min m ($sec s)"
            set_color normal
        else if test $CMD_DURATION -ge 10000
            set sec (math -s0 "$CMD_DURATION / 1000")
            set ms $CMD_DURATION
            set_color brblack
            echo -n " $sec s ($ms ms)"
            set_color normal
        else if test $CMD_DURATION -ge 250
            set_color brblack
            echo -n " $CMD_DURATION ms"
            set_color normal
        else
            echo -n ""
        end
    else
        echo -n ""
    end
end

function fish_prompt
    set OLD_EXIT_STATUS $status

    set_color normal
    echo -n (date +"%H:%M:%S")
    
    set_color --bold
    echo -n " F "
    set_color normal

    if [ $USER = "root" ]
        set_color red
    else
        set_color green
    end

    echo -n $(id -un)
    echo -n @
    echo -n (hostname)

    set_color blue

    echo -n " "
    echo -n (prompt_pwd)

    git_prompt
    exit_status_prompt $OLD_EXIT_STATUS
    time_prompt

    echo ""

    if [ $USER = "root" ]
        set_color red
        echo -n "#"
    else
        set_color green
        echo -n "%"
    end

    set_color normal

    echo -n " > "
end

source $HOME/.alias'
}

print_neovim() {
    echo 'set number
set mouse=a
set tabstop=4
set expandtab
set shiftwidth=4
set autoindent
setl linebreak
filetype plugin indent on
syntax on
'
}

print_profile() {
    echo '
# linux-shell-configuration
if [ $USER = "root" ]
then
    export PATH="$PATH:/sbin"
    export PATH="$PATH:/usr/sbin"
fi
if [ -d $HOME/bin ]
then
    export PATH="$PATH:$HOME/bin"
fi'
}

print_alias_list() {
    echo "# Alias list"

echo "## ls aliases"
if command_exists eza
then
    echo 'alias ls="eza"
alias ll="eza -aalgM --time-style=long-iso --git --color-scale"
alias dir="eza"'
else
    echo 'alias ls="ls --color=auto"
alias ll="ls -alh --time-style=\"+%Y-%m-%d %H:%M\""
alias dir="dir --color=auto"'
fi

echo "## vi aliases"
if command_exists nvim
then
    echo 'alias vi="nvim"'
else
    echo 'alias vi="vim"'
fi

if command_exists batcat
then
    echo "## bat aliases"
    echo 'alias bat="batcat"'
fi

echo '## grep coloration
alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"
alias rg="rg --color=auto"'

echo '## Human readable aliases
alias df="df -h"
alias du="du -hs"
alias free="free -h"'

echo '## Change shell
alias use-bash="exec bash"
alias use-fish="exec fish"
alias use-zsh="exec zsh"'
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

securise_location() {
    local USER_NAME="$1"
    local USER_GROUP="$2"
    local LOCATION="$3"

    if [ -f $LOCATION ]
    then
        chown -R $USER_NAME:$USER_GROUP "$LOCATION"
        chmod 400 $LOCATION
    elif [ -d $LOCATION ]
    then
        chown -R $USER_NAME:$USER_GROUP "$LOCATION"
        find $LOCATION -type f -exec chmod 400 {} \;
        find $LOCATION -type d -exec chmod 700 {} \;
    fi

}

install_packages() {
    local PACKAGE_INSTALLER="printf 'Installation $KO\n' && exit 1"
    command_exists "apt-get" && apt-get update -qq && PACKAGE_INSTALLER="apt-get install -qq -y"
    command_exists "yum" && PACKAGE_INSTALLER="yum install -q -y"
    command_exists "dnf" && PACKAGE_INSTALLER="dnf install -q -y"
    command_exists "apk" && PACKAGE_INSTALLER="apk add --update --no-cache"
    command_exists "pacman" && PACKAGE_INSTALLER="pacman -q --noconfirm -S"

    install_package() {
        local PCKAGE_NAME="$1"
        local PCKAGE_REPO_NAME="$2"

        if command_exists "$PCKAGE_NAME" || $PACKAGE_INSTALLER $PCKAGE_REPO_NAME 1>/dev/null
        then
            printf "$PCKAGE_REPO_NAME $OK\n"
        else
            printf "$PCKAGE_REPO_NAME $KO\n"
        fi
    }

    install_package "bash" "bash"
    install_package "zsh" "zsh"
    install_package "fish" "fish"
    install_package "git" "git"
    install_package "curl" "curl"
    install_package "wget" "wget"
    install_package "htop" "htop"
    install_package "nvim" "neovim"
    install_package "gawk" "gawk"
    install_package "tree" "tree"
    install_package "eza" "eza"
    install_package "rg" "ripgrep"
    install_package "fd" "fd"
    install_package "bat" "bat"
    install_package "dust" "dust"
}

download_scripts() {
    local KUBECTL_VSERSION=$(curl -Lqs https://storage.googleapis.com/kubernetes-release/release/stable.txt)
    local KOMPOSE_VERSION=$(curl -Lqs https://api.github.com/repos/kubernetes/kompose/releases/latest | grep "tag_name" | awk '{match($0,"\"tag_name\": \"(.+)\",",a)}END{print a[1]}')

    local KUBECTL_ARCH="amd64"
    local KOMPOSE_ARCH="amd64"

    case $(uname -m) in
    x86_64)
        KUBECTL_ARCH="amd64"
        KOMPOSE_ARCH="amd64"
        ;;
    aarch64)
        KUBECTL_ARCH="arm64"
        KOMPOSE_ARCH="arm64"
        ;;
    armv7l)
        KUBECTL_ARCH="arm"
        KOMPOSE_ARCH="arm"
        ;;
    esac

    git clone -q --depth 1 -- https://github.com/marlonrichert/zsh-snap.git $LSC_ZNAP
    printf "zsh-snap $OK\n"

    curl -Lqs https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VSERSION/bin/linux/$KUBECTL_ARCH/kubectl -o $LSC_USER_BIN/kubectl
    printf "kubectl $OK\n"

    curl -Lqs https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx -o $LSC_USER_BIN/kubectx
    printf "kubectx $OK\n"

    curl -Lqs https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens -o $LSC_USER_BIN/kubens
    printf "kubens $OK\n"

    curl -Lqs https://github.com/kubernetes/kompose/releases/download/$KOMPOSE_VERSION/kompose-linux-$KOMPOSE_ARCH -o $LSC_USER_BIN/kompose
    printf "kompose $OK\n"
}

install_conf() {
    local USER_NAME=$1
    local USER_GROUP=$2
    local USER_HOME=$3

    local BASHRC_PATH="$USER_HOME/.bashrc"
    local ZSHRC_PATH="$USER_HOME/.zshrc"
    local CONFIG_DIR="$USER_HOME/.config"
    local FISH_DIR="$CONFIG_DIR/fish"
    local NEOVIM_DIR="$CONFIG_DIR/nvim"
    local ZNAP_DIR="$USER_HOME/.znap"
    local ALIAS_PATH="$USER_HOME/.alias"
    local USER_BIN_DIR="$USER_HOME/bin"

    if [ ! -d $USER_HOME ]
    then
        mkdir -p $USER_HOME
        securise_location $USER_NAME $USER_GROUP $USER_HOME
    fi

    if [ ! -d $CONFIG_DIR ]
    then
        mkdir -p $CONFIG_DIR
        securise_location $USER_NAME $USER_GROUP $CONFIG_DIR
    fi

    touch $BASHRC_PATH
    chmod u+w $BASHRC_PATH
    print_bashrc > $BASHRC_PATH
    securise_location $USER_NAME $USER_GROUP $BASHRC_PATH

    touch $ZSHRC_PATH
    chmod u+w $ZSHRC_PATH
    print_zshrc > $ZSHRC_PATH
    securise_location $USER_NAME $USER_GROUP $ZSHRC_PATH

    mkdir -p $FISH_DIR
    chmod -R u+w $FISH_DIR
    print_fishrc > $FISH_DIR/config.fish
    securise_location $USER_NAME $USER_GROUP $FISH_DIR

    mkdir -p $NEOVIM_DIR
    chmod -R u+w $NEOVIM_DIR
    print_neovim > $NEOVIM_DIR/init.vim
    securise_location $USER_NAME $USER_GROUP $NEOVIM_DIR

    if [ -f $ZNAP_DIR ]
    then
        chmod -R u+w $ZNAP_DIR
        rm -Rf $ZNAP_DIR
    fi
    mkdir -p $ZNAP_DIR
    cp -r $LSC_ZNAP $ZNAP_DIR/znap
    securise_location $USER_NAME $USER_GROUP $ZNAP_DIR

    if [ ! -f $ALIAS_PATH ]
    then
        touch $ALIAS_PATH
        print_alias_list > $ALIAS_PATH
        securise_location $USER_NAME $USER_GROUP $ALIAS_PATH
    fi

    mkdir -p $USER_BIN_DIR
    if [ -d $LSC_USER_BIN ] && [ $USER_NAME != "root" ]
    then
        chmod -R u+w $USER_BIN_DIR
        cp -R $LSC_USER_BIN/* $USER_BIN_DIR/
        securise_location $USER_NAME $USER_GROUP $USER_BIN_DIR
        chmod u+x $USER_BIN_DIR/*
    fi

    local PROFILE_PATH="no_profile"
    if [ -f $USER_HOME/.profile ]
    then
        PROFILE_PATH="$USER_HOME/.profile"
    elif [ -f $USER_HOME/.bash_profile ]
    then
        PROFILE_PATH="$USER_HOME/.bash_profile"
    fi

    if [ $PROFILE_PATH != "no_profile" ]
    then
        if ! grep -q "# linux-shell-configuration" $PROFILE_PATH
        then
            chmod u+w $PROFILE_PATH
            print_profile >> $PROFILE_PATH
            securise_location $USER_NAME $USER_GROUP $PROFILE_PATH
        fi
    fi

    printf "Configure user \033[0;36m$USER_NAME\033[0m with home \033[0;36m$USER_HOME\033[0m $OK\n"
}

main() {
    if [ $(id -u) -eq 0 ]
    then
        install_packages
        download_scripts

    if [ -f /etc/bash.bashrc ]
    then
        print_bashrc > /etc/bash.bashrc
    elif [ -f /etc/bashrc ]
    then
        print_bashrc > /etc/bashrc
    fi

        for USER_INFOS in $(cat /etc/passwd | grep -v ":/usr/sbin/nologin$" | cut -f1,6 -d: | grep ":/home/")
        do
            USER_NAME="$(echo $USER_INFOS | cut -f1 -d:)"
            install_conf "$USER_NAME" "$USER_NAME" "$(echo $USER_INFOS | cut -f2 -d:)"

            if command_exists chsh && command_exists fish
            then
                chsh -s $(which fish) "$USER_NAME"
            elif command_exists chsh && command_exists zsh
            then
                chsh -s $(which zsh) "$USER_NAME"
            fi
        done

        install_conf root root ~
        command_exists chsh && chsh -s /bin/bash

        mkdir -p /etc/skel/
        install_conf root root /etc/skel
    else
        if ! command_exists curl || ! command_exists git || ! command_exists gawk
        then
            printf "To run without root privileges, the script requires \033[0;36mcurl\033[0m, \033[0;36mgit\033[0m, and \033[0;36mawk\033[0m.\n"
            exit 1
        fi

        download_scripts

        local USER_NAME="$(id -u -n)"
        local USER_NAME_ID="$(id -u)"
        local USER_GROUP_ID="$(id -g)"

        install_conf "$USER_NAME_ID" "$USER_GROUP_ID" "$HOME"

        if command_exists chsh && command_exists fish
        then
            chsh -s $(which fish) "$USER_NAME"
        elif command_exists chsh && command_exists zsh
        then
            chsh -s $(which zsh) "$USER_NAME"
        fi
    fi

    rm -Rf $LSC_USER_BIN
    rm -Rf $LSC_ZNAP

    printf "Installation $OK\n"
}

main
