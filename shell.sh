#!/bin/sh
# Flavien PERIER <perier@flavien.io>
# Install user profiles

set -e

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

function git_prompt() {
    local BRANCH=""
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ $? -eq 0 ]
    then
        if git diff --cached --exit-code > /dev/null
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

    if [ $OLD_EXIT_STATUS -ne 0 ]
    then
        printf " \e[m(\e[31m$OLD_EXIT_STATUS\e[m)"
    else
        printf ""
    fi
}

function precmd() {
    local OLD_EXIT_STATUS=$?

    if [ $UID -eq 0 ]
    then
        export PS1="\[\e[m\]\$(date +"%H:%M:%S") \e[1mB\e[m \[\e[31m\]\u@\H \[\e[34m\]\w\$(exit_status_prompt $OLD_EXIT_STATUS)$(git_prompt)\n\[\e[31m\]#\[\e[m\] > "
    else
        export PS1="\[\e[m\]\$(date +"%H:%M:%S") \e[1mB\e[m \[\e[32m\]\u@\H \[\e[34m\]\w\$(exit_status_prompt $OLD_EXIT_STATUS)$(git_prompt)\n\[\e[32m\]%\[\e[m\] > "
    fi
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
znap source marlonrichert/zsh-autocomplete
znap source zsh-users/zsh-autosuggestions
znap source zsh-users/zsh-syntax-highlighting

setopt correctall

function git_prompt() {
    local BRANCH=""
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ $? -eq 0 ]
    then
        if git diff --cached --exit-code > /dev/null
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

    if [ $OLD_EXIT_STATUS -ne 0 ]
    then
        print -Pn " %f(%F{red}$OLD_EXIT_STATUS%f)"
    else
        print -Pn ""
    fi
}

function precmd() {
    local OLD_EXIT_STATUS=$?

    if [ $UID -eq 0 ]
    then
        export PROMPT="%f%* %BZ%b %F{red}%n@%m %F{blue}%~\$(exit_status_prompt $OLD_EXIT_STATUS)$(git_prompt)
%F{red}%#%f > "
    else
        export PROMPT="%f%* %BZ%b %F{green}%n@%m %F{blue}%~\$(exit_status_prompt $OLD_EXIT_STATUS)$(git_prompt)
%F{green}%#%f > "
    fi
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
        if git diff --cached --exit-code > /dev/null
            set_color normal
            echo -n " ["
            set_color green
            echo -n $BRANCH
            set_color normal
            echo -n "]"
            set_color blue
            echo -n " "
        else
            set_color normal
            echo -n " ["
            set_color red
            echo -n $BRANCH
            set_color normal
            echo -n "]"
            set_color blue
            echo -n " "
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

    echo -n $LOGNAME
    echo -n @
    echo -n (hostname)

    set_color blue

    echo -n " "
    echo -n (prompt_pwd)

    exit_status_prompt $OLD_EXIT_STATUS
    git_prompt

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
    echo '# Alias list

alias ls="ls --color=auto"
alias dir="dir --color=auto"
alias vdir="vdir --color=auto"
alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"

alias df="df -h"
alias du="du -hs"
alias free="free -h"
alias ll="ls -alh --time-style=\"+%Y-%m-%d %H:%M\""
alias vi="nvim"

alias use-bash="exec bash"
alias use-fish="exec fish"
alias use-zsh="exec zsh"'
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

securise_location() {
    local OWNER="$1"
    local LOCATION="$2"

    if [ -f $LOCATION ]
    then
        chown -R $OWNER:$OWNER "$LOCATION"
        chmod 400 $LOCATION
    elif [ -d $LOCATION ]
    then
        chown -R $OWNER:$OWNER "$LOCATION"
        find $LOCATION -type f -exec chmod 400 {} \;
        find $LOCATION -type d -exec chmod 700 {} \;
    fi

}

download_scripts() {
    local KUBECTL_VSERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
    local DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep "tag_name" | awk '{match($0,"\"tag_name\": \"(.+)\",",a)}END{print a[1]}')
    local KOMPOSE_VERSION=$(curl -s https://api.github.com/repos/kubernetes/kompose/releases/latest | grep "tag_name" | awk '{match($0,"\"tag_name\": \"(.+)\",",a)}END{print a[1]}')

    local KUBECTL_ARCH="amd64"
    local DOCKER_COMPOSE_ARCH="x86_64"
    local KOMPOSE_ARCH="amd64"

    case $(uname -m) in
    x86_64)
        KUBECTL_ARCH="amd64"
        DOCKER_COMPOSE_ARCH="x86_64"
        KOMPOSE_ARCH="amd64"
        ;;
    aarch64)
        KUBECTL_ARCH="arm64"
        DOCKER_COMPOSE_ARCH="armv7"
        KOMPOSE_ARCH="arm64"
        ;;
    armv7l)
        KUBECTL_ARCH="arm"
        DOCKER_COMPOSE_ARCH="armv7"
        KOMPOSE_ARCH="arm"
        ;;
    esac

    git clone -q --depth 1 -- https://github.com/marlonrichert/zsh-snap.git $LSC_ZNAP
    printf "zsh-snap [\033[0;32mOK\033[0m]\n"

    curl -Lqs https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VSERSION/bin/linux/$KUBECTL_ARCH/kubectl -o $LSC_USER_BIN/kubectl
    printf "kubectl [\033[0;32mOK\033[0m]\n"

    curl -Lqs https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx -o $LSC_USER_BIN/kubectx
    printf "kubectx [\033[0;32mOK\033[0m]\n"

    curl -Lqs https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens -o $LSC_USER_BIN/kubens
    printf "kubens [\033[0;32mOK\033[0m]\n"

    curl -Lqs https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-linux-$DOCKER_COMPOSE_ARCH -o $LSC_USER_BIN/docker-compose
    printf "docker-compose [\033[0;32mOK\033[0m]\n"

    curl -Lqs https://github.com/kubernetes/kompose/releases/download/$KOMPOSE_VERSION/kompose-linux-$KOMPOSE_ARCH -o $LSC_USER_BIN/kompose
    printf "kompose [\033[0;32mOK\033[0m]\n"
}

install_conf() {
    local USER_NAME=$1
    local USER_HOME=$2

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
        securise_location $USER_NAME $USER_HOME
    fi

    if [ ! -d $CONFIG_DIR ]
    then
        mkdir -p $CONFIG_DIR
        securise_location $USER_NAME $CONFIG_DIR
    fi

    print_bashrc > $BASHRC_PATH
    securise_location $USER_NAME $BASHRC_PATH

    print_zshrc > $ZSHRC_PATH
    securise_location $USER_NAME $ZSHRC_PATH

    mkdir -p $FISH_DIR
    print_fishrc > $FISH_DIR/config.fish
    securise_location $USER_NAME $FISH_DIR

    mkdir -p $NEOVIM_DIR
    print_neovim > $NEOVIM_DIR/init.vim
    securise_location $USER_NAME $NEOVIM_DIR

    if [ -f $ZNAP_DIR ]
    then
        chmod -R u+w $ZNAP_DIR
        rm -Rf $ZNAP_DIR
    fi
    mkdir -p $ZNAP_DIR
    cp -r $LSC_ZNAP $ZNAP_DIR/znap
    securise_location $USER_NAME $ZNAP_DIR

    if [ ! -f $ALIAS_PATH ]
    then
        touch $ALIAS_PATH
        print_alias_list > $ALIAS_PATH
        securise_location $USER_NAME $ALIAS_PATH
    fi

    mkdir -p $USER_BIN_DIR
    if [ -d $LSC_USER_BIN ] && [ $USER_NAME != "root" ]
    then
        cp -R $LSC_USER_BIN/* $USER_BIN_DIR/
        securise_location $USER_NAME $USER_BIN_DIR
        chmod u+x $USER_BIN_DIR/*
    fi

    local PROFILE_FILE="no_profile"
    if [ -f $USER_HOME/.profile ]
    then
        PROFILE_FILE="$USER_HOME/.profile"
    elif [ -f $USER_HOME/.bash_profile ]
    then
        PROFILE_FILE="$USER_HOME/.bash_profile"
    fi

    if [ $PROFILE_FILE != "no_profile" ]
    then
        if ! grep -q "# linux-shell-configuration" $PROFILE_FILE
        then
            print_profile >> $PROFILE_FILE
            securise_location $USER_NAME $PROFILE_FILE
        fi
    fi

    printf "Configure user \033[0;36m$USER_NAME\033[0m with home \033[0;36m$USER_HOME\033[0m [\033[0;32mOK\033[0m]\n"
}

main() {
    if [ $(id -u) -eq 0 ]
    then
        local PACKAGE_INSTALLER="printf 'Installation [\033[0;31mKO\033[0m]\n' && exit 1"
        command_exists "apt-get" && apt-get update -qq && PACKAGE_INSTALLER="apt-get install -qq -y"
        command_exists "yum" && PACKAGE_INSTALLER="yum install -q -y"
        command_exists "dnf" && PACKAGE_INSTALLER="dnf install -q -y"
        command_exists "apk" && PACKAGE_INSTALLER="apk add --update --no-cache"
        command_exists "pacman" && PACKAGE_INSTALLER="pacman -q --noconfirm -S"

        command_exists "bash" || $PACKAGE_INSTALLER bash 1>/dev/null && \
            printf "bash [\033[0;32mOK\033[0m]\n" || \
            printf "bash [\033[0;31mKO\033[0m]\n"

        command_exists "zsh" || $PACKAGE_INSTALLER zsh 1>/dev/null && \
            printf "zsh [\033[0;32mOK\033[0m]\n" || \
            printf "zsh [\033[0;31mKO\033[0m]\n"

        command_exists "fish" || $PACKAGE_INSTALLER fish 1>/dev/null && \
            printf "fish [\033[0;32mOK\033[0m]\n" || \
            printf "fish [\033[0;31mKO\033[0m]\n"

        command_exists "nvim" || $PACKAGE_INSTALLER neovim 1>/dev/null && \
            printf "neovim [\033[0;32mOK\033[0m]\n" || \
            printf "neovim [\033[0;31mKO\033[0m]\n"

        command_exists "git" || $PACKAGE_INSTALLER git 1>/dev/null && \
            printf "git [\033[0;32mOK\033[0m]\n" || \
            printf "git [\033[0;31mKO\033[0m]\n"

        command_exists "htop" || $PACKAGE_INSTALLER htop 1>/dev/null && \
            printf "htop [\033[0;32mOK\033[0m]\n" || \
            printf "htop [\033[0;31mKO\033[0m]\n"

        command_exists "curl" || $PACKAGE_INSTALLER curl 1>/dev/null && \
            printf "curl [\033[0;32mOK\033[0m]\n" || \
            printf "curl [\033[0;31mKO\033[0m]\n"

        command_exists "wget" || $PACKAGE_INSTALLER wget 1>/dev/null && \
            printf "wget [\033[0;32mOK\033[0m]\n" || \
            printf "wget [\033[0;31mKO\033[0m]\n"

        command_exists "tree" || $PACKAGE_INSTALLER tree 1>/dev/null && \
            printf "tree [\033[0;32mOK\033[0m]\n" || \
            printf "tree [\033[0;31mKO\033[0m]\n"

        command_exists "gawk" || $PACKAGE_INSTALLER gawk 1>/dev/null && \
            printf "gawk [\033[0;32mOK\033[0m]\n" || \
            printf "gawk [\033[0;31mKO\033[0m]\n"

        download_scripts

        print_bashrc > /etc/bash.bashrc

        for USER_INFOS in $(cat /etc/passwd | grep -v ":/usr/sbin/nologin$" | cut -f1,6 -d: | grep ":/home/")
        do
            install_conf "$(echo $USER_INFOS | cut -f1 -d:)" "$(echo $USER_INFOS | cut -f2 -d:)"
            command_exists chsh && chsh -s $(which fish) $USER_NAME
        done

        install_conf root ~
        command_exists chsh && chsh -s /bin/bash

        mkdir -p /etc/skel/
        install_conf root /etc/skel
    else
        download_scripts

        install_conf $USER ~
        command_exists chsh && chsh -s $(which fish) $USER
    fi

    rm -Rf $LSC_USER_BIN
    rm -Rf $LSC_ZNAP

    printf "Installation [\033[0;32mOK\033[0m]\n"
}

main
