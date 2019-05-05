#!/bin/bash

function installOhMyZsh() {
    local scriptFileName="`date +%Y%m%d%H%M%S`.sh"
    [ -f "$scriptFileName" ] && rm "$scriptFileName"

    curl -fsSL -o "$scriptFileName" https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh || exit 1
    
    local lineNumber=`grep "env zsh -l" -n $scriptFileName | awk -F: '{print $1}'`
    if [ "$osType" == "Darwin" ] ; then
        gsed -i "${lineNumber}d" $scriptFileName
    else 
        sed -i "${lineNumber}d" $scriptFileName
    fi

    (source $scriptFileName && rm $scriptFileName) || exit 1
    
    local pluginsDir=~/.oh-my-zsh/plugins
    
    if [ -d "$pluginsDir" ] ; then
        #这里不使用-C参数的因为是，CentOS里的git命令的版本比较低，没有此参数
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $pluginsDir/zsh-syntax-highlighting && \
        git clone https://github.com/zsh-users/zsh-autosuggestions.git $pluginsDir/zsh-autosuggestions  && \
        git clone https://github.com/zsh-users/zsh-completions.git $pluginsDir/zsh-completions && {
            #更新插件列表
            local lineNumber=`grep "^plugins=(" -n ~/.zshrc | awk -F: '{print $1}'`
            local plugins=`grep "^plugins=(" -n ~/.zshrc | sed 's/.*plugins=(\(.*\)).*/\1/'`
            plugins="plugins=(${plugins} zsh-syntax-highlighting zsh-autosuggestions zsh-completions)"
            if [ "$osType" == "Darwin" ] ; then
                gsed -i "${lineNumber}c ${plugins}" ~/.zshrc
            else
                sed -i "${lineNumber}c ${plugins}" ~/.zshrc
            fi

            local lineNumbers=`grep "compinit" -n ~/.zshrc | awk -F: '{print $1}'`
            for lineNumber in $lineNumbers
            do
                if [ "$osType" == "Darwin" ] ; then
                    gsed -i "${lineNumber}d" ~/.zshrc
                else
                    sed -i "${lineNumber}d" ~/.zshrc
                fi
            done
            echo "autoload -U compinit && compinit" >> ~/.zshrc
            env zsh -l
        }
    fi
}

function main() {
    local sudo=`command -v sudo 2> /dev/null`;
    osType=`uname -s`;

    if [ "$osType" == "Linux" ] ; then
        # 如果是ArchLinux或ManjaroLinux系统
        if [ -f "/etc/arch-release" ] || [ -f "/etc/manjaro-release" ] ; then
            $sudo pacman -Syy && \
            command -v curl &> /dev/null || $sudo pacman -S curl --noconfirm && \
            command -v git  &> /dev/null || $sudo pacman -S git  --noconfirm && \
            command -v zsh  &> /dev/null || $sudo pacman -S zsh  --noconfirm && \
            command -v sed  &> /dev/null || $sudo pacman -S sed  --noconfirm && \
            installOhMyZsh
        # 如果是Ubuntu或Debian GNU/Linux系统
        elif [ -f "/etc/lsb-release" ] || [ -f "/etc/debian_version" ] ; then
            $sudo apt-get -y update && \
            $sudo apt-get -y install curl git zsh sed && \
            installOhMyZsh
        # 如果是CentOS或Fedora系统
        elif [ -f "/etc/redhat-release" ] || [ -f "/etc/fedora-release" ] ; then
            $sudo yum -y update && \
            $sudo yum -y install curl git zsh sed && \
            installOhMyZsh
        # 如果是AlpineLinux系统
        elif [ -f "/etc/alpine-release" ] ; then
            $sudo apk update && \
            $sudo apk add curl git zsh sed && \
            installOhMyZsh
        else
            echo "your os is unrecognized!!"
            exit 1
        fi
    elif [ "$osType" == "Darwin" ] ; then
        command -v brew &> /dev/null || (echo -e "\n" | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" && brew update)
        command -v curl &> /dev/null || brew install curl
        command -v git  &> /dev/null || brew install git
        command -v gsed &> /dev/null || brew install gnu-sed
        installOhMyZsh
    else
        echo "your os is unrecognized!!"
        exit 1
    fi
}

main
