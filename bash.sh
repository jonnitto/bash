#!/bin/zsh

# wget -qN https://raw.githubusercontent.com/jonnitto/bash/master/bash.sh -O syncBashScript.sh; source syncBashScript.sh

{  # make sure whole file is loaded

# COLORS
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[2;37m'
WHITE="\033[1;37m"
NC='\033[0m'

# USER
USER=$(whoami)
GROUP=$(id -g -n)

_BASH_SCRIPT_LOCATION='https://raw.githubusercontent.com/jonnitto/bash/master/bash.sh'


export CLICOLOR=1

# ================================
#       SERVER
# ================================

## Get server type
_hostname=""
_servername="h"
case $(hostname -f) in
    (*.uberspace.de) server="Uberspace"; _hostname="$server "; _servername="u" ;;
    (*.punkt.de) server="PunktDe"; _hostname="$server "; _servername="u@\h" ;;
    (*.mynet.at) server="myNET"; _hostname="$server " ;;
    (*.local) server="Local" ;;
    (*) server="NONE" ;;
esac

if [[ $USER == "beach" ]]
    then server="Beach"; _servername="u"
fi

## Read ssh key
readKey() { echo; cat ~/.ssh/id_rsa.pub; echo; }

## Generate ssh key
case $server in
    (Uberspace|myNET|PunktDe)
        generateKey() { ssh-keygen -t rsa -b 4096 -C "$(hostname -f)"; readKey; }
    ;;
esac

## Set paths
case $server in
    (Uberspace)
        WEB_ROOT="/var/www/virtual/${USER}"
        NEOS_ROOT="/var/www/virtual/${USER}/Neos"
        NEOS_DEPLOYER="/var/www/virtual/${USER}/Neos/current"
        SHOPWARE_DEPLOYER="/var/www/virtual/${USER}/Shopware/current"
        alias readSQLConfig='cat ~/.my.cnf'
        alias installImgOptimizer='npm install -g jpegtran-bin optipng-bin gifsicle svgo'
    ;;
    (PunktDe)
        WEB_ROOT="/var/www/"
        NEOS_ROOT="/var/www/Neos/current"
        NEOS_DEPLOYER="/var/www/Neos/current"
        SHOPWARE_DEPLOYER="/var/www/Shopware/current"
    ;;
    (myNET)
        WEB_ROOT="/web/${USER}/web/"
        NEOS_ROOT="/web/${USER}/Neos/releases/current"
        NEOS_DEPLOYER="/web/${USER}/Neos/current"
        SHOPWARE_DEPLOYER="/web/${USER}/Shopware/current"
    ;;
esac

# ================================
#    HELPER FUNCTIONS
# ================================

_isNeos() {      if [ -f "flow" ] || [ -f "flow.php" ] || [ -f "flow.bat" ]; then echo true; fi }
_isShopware() {  if [ -f "shopware.php" ]; then echo true; fi }
_isMice() {      if [ -d "mice" ]; then echo true; fi }
_isWordpress() { if [ -f "wp-login.php" ]; then echo true; fi }
_isSystem() {
    if [ $(_isNeos) ]; then printf "Neos"
    elif [ $(_isShopware) ]; then printf "Shopware"
    elif [ $(_isWordpress) ]; then printf "Wordpress"
    elif [ $(_isMice) ]; then printf "Mice"
    fi
}
_available() { command -v $1 >/dev/null 2>&1; }
_msgError() { printf "\n    ${RED}${1}${NC} ${2}\n\n"; }
_msgInfo() { printf "\n    ${CYAN}${1}${GREEN} ${2}${NC}\n\n"; }
_msgSuccess() { printf "\n    ${GREEN}${1}${NC}\n\n"; }
_checkGitPull() {
    if [ -d ".git" ]; then git pull
        if [ $? -ne 0 ]; then
            _msgError "Couldn't pull newest changes. Please check the output above"
            return 1
        fi
    fi
}
_checkNeos() {
    if [ ! $(_isNeos) ]; then
        _msgError "You're not in a Neos folder"
        return 1
    fi
}
_checkShopware() {
    if [ ! $(_isShopware) ]; then
        _msgError "You're not in a Shopware folder"
        return 1
    fi
}
_checkMice() {
    if [ ! $(_isMice) ]; then
        _msgError "You're not in a Mice folder"
        return 1
    fi
}
_checkWordpress() {
    if [ ! $(_isWordpress) ]; then
        _msgError "You're not in a Wordpress folder"
        return 1
    fi
}

## go 2 specifc folder funtions

if [ ! -z "$WEB_ROOT" ]; then
    go2www() {
        if [ "$WEB_ROOT" ] && [ -d "$WEB_ROOT" ]; then cd $WEB_ROOT; fi
    }
fi


if [ ! -z "$NEOS_ROOT" ] || [ ! -z "$NEOS_DEPLOYER" ]; then
    go2Neos() {
        if [ "$NEOS_DEPLOYER" ] && [ -d "$NEOS_DEPLOYER" ] && [ -f "$NEOS_DEPLOYER/flow" ]
            then cd $NEOS_DEPLOYER
        elif [ "$NEOS_ROOT" ] && [ -d "$NEOS_ROOT" ] && [ -f "$NEOS_ROOT/flow" ]
            then cd $NEOS_ROOT
        elif [ "$WEB_ROOT" ] && [ -f "${WEB_ROOT}/flow" ]
            then type go2www &>/dev/null && go2www; 
        fi
    }
fi

if [ ! -z "$SHOPWARE_DEPLOYER" ]; then
    go2Shopware() {
        if [ "$SHOPWARE_DEPLOYER" ] && [ -d "$SHOPWARE_DEPLOYER" ] && [ -f "$SHOPWARE_DEPLOYER/shopware.php" ]
            then cd $SHOPWARE_DEPLOYER
        elif [ "$WEB_ROOT" ] && [ -f "${WEB_ROOT}/shopware.php" ]
            then type go2www &>/dev/null && go2www; 
        fi
    }
fi

if [ ! -z "$WEB_ROOT" ] || [ ! -z "$NEOS_ROOT" ] || [ ! -z "$NEOS_DEPLOYER" ] || [ ! -z "$SHOPWARE_DEPLOYER" ]; then
    go2() {
        type go2Shopware &>/dev/null && go2Shopware;
        type go2Neos &>/dev/null && go2Neos;
    }
fi

# ================================
#    SHOPWARE
# ================================

updateShopware() {
    _checkShopware; [ $? -ne 0 ] && return 1
    _msgInfo "Update your Shopware Template ..."
    _checkGitPull; [ $? -ne 0 ] && return 1
    ./var/cache/clear_cache.sh
    php bin/console sw:cache:clear
    php bin/console sw:theme:cache:generate
    if [ $? -eq 0 ]
        then _msgSuccess "Update completed"
        else _msgError "Something went wrong. Please check the output above"
    fi
}

# ================================
#       NEOS
# ================================

flow() {
    _checkNeos; [ $? -ne 0 ] && return 1
    if [ $# -eq 0 ]; then 
        ./flow
        return 0;
    fi
    typeset -A flowCommands;
    typeset -A shellCommands;
    typeset -A functionCommands;
    flowCommands=(
        flushCache 'flow:cache:flush'
        flushContentCache 'cache:flushone --identifier Neos_Fusion_Content'
        warmup 'flow:cache:warmup'
        publishResource 'resource:publish'
        migratedb 'doctrine:migrate'
        noderepair 'node:repair'
        setcharset 'database:setcharset'
        prunesite 'site:prune'
        importsite 'site:import --package-key $(basename Packages/Sites/*)'
        exportsite 'site:export --package-key $(basename Packages/Sites/*) --tidy'
        clonesite 'clone:preset'
        createAdmin 'user:create --roles Administrator'
        run 'server:run --host neos.local'
    );
    shellCommands=(
        setuppwd 'cat Data/SetupPassword.txt'
    );
    functionCommands=(
        recreateThumbnails 'Remove thumbnails, publish resources, create and render thumbnails'
        repairpermission 'Adjust file permissions for CLI and web server access'
        deployContext 'Set the FLOW_CONTEXT by reading deploy.yaml'
        switchContext 'Switch between Production and Development context'
    );

    if [[ $1 == 'helpme' ]]; then
        for key val in ${(kv)flowCommands}; do
            printf "\n${CYAN}%20s${NC} %-70s" \
            $key $val
        done
        for key val in ${(kv)shellCommands}; do
            printf "\n${CYAN}%20s${NC} %-70s" \
            $key $val
        done
        for key val in ${(kv)functionCommands}; do
            printf "\n${CYAN}%20s${NC} %-70s" \
            $key $val
        done
        return 0;
    fi

    local cmd=$1;
    shift;
    if [ ${flowCommands[$cmd]} ]; then
        if [ $# -eq 0 ]; then
            echo "./flow ${flowCommands[$cmd]}" | bash
        else
            echo "./flow ${flowCommands[$cmd]} $@" | bash
        fi
        return 0;
    fi
    if [ ${shellCommands[$cmd]} ]; then
        if [ $# -eq 0 ]; then
            echo "${shellCommands[$cmd]}" | bash
        else
            echo "./flow ${flowCommands[$cmd]} $@" | bash
        fi
        return 0;
    fi
    if [[ $cmd == 'recreateThumbnails' ]]; then
        _msgInfo "Recreate thumbnails, this might take a while ..."
        ./flow media:clearthumbnails
        ./flow resource:publish
        ./flow media:createthumbnails
        ./flow media:renderthumbnails
        _msgSuccess "Done"
        return 0;
    fi
    if [[ $cmd == 'repairpermission' ]]; then
        _msgInfo "Setting file permissions per file, this might take a while ..."
        chown -R $USER:$GROUP .
        find . -type d -exec chmod 775 {} \;
        find . -type f \! \( -name commit-msg -or -name '*.sh' \) -exec chmod 664 {} \;
        chmod 770 flow
        chmod 755 Web
        chmod 644 Web/index.php
        chmod 644 Web/.htaccess
        chown -R $USER:$GROUP Web/_Resources
        chmod 775 Web/_Resources
        _msgSuccess "Done"
        return 0;
    fi
    if [[ $cmd == 'deployContext' ]]; then
        local newContext='Production'
        if [ -f deploy.yaml ]; then
            flowContext=$(cat deploy.yaml | grep ' flow_context' | awk '{print $2}')
            subContext=$(cat deploy.yaml | grep ' sub_context' | awk '{print $2}')
            if [ $flowContext ]
                then newContext=$flowContext;
            elif [ $subContext ]
                then newContext="Production/$subContext";
            else
                newContext='Production/Live';
            fi
        fi
        export FLOW_CONTEXT=$newContext
        _msgInfo "Set Flow Context to" $FLOW_CONTEXT
        return 0;
    fi
    if [[ $cmd == 'switchContext' ]]; then
        if [[ $FLOW_CONTEXT == "Development" ]]
            then 
                flow deployContext
            else
                export FLOW_CONTEXT=Development
                _msgInfo "Set Flow Context to" $FLOW_CONTEXT
        fi
        return 0;
    fi
    ./flow $cmd $@;
}

## Set context
case $server in
    (NONE|Local)
        export FLOW_CONTEXT=Development
    ;;
    (*)
        flow deployContext
    ;;
esac

## Run tests

case $server in
    (Beach|Local)
        alias runUnitTest='./Packages/Libraries/phpunit/phpunit/phpunit -c Build/BuildEssentials/PhpUnit/UnitTests.xml --colors=always'
        alias runFunctionalTest='./Packages/Libraries/phpunit/phpunit/phpunit -c Build/BuildEssentials/PhpUnit/FunctionalTests.xml --colors=always'
    ;;
esac


# ================================
#    SERVER SPECIFIC
# ================================


case $server in
    (Uberspace)
        writeNeosSettings() {
            _checkNeos; [ $? -ne 0 ] && return 1
            _msgInfo "Write configuration file for Neos ..."
            cat > Configuration/Settings.yaml <<__EOF__
Neos: &settings
  Imagine:
    driver: Imagick
  Flow:
    core:
        phpBinaryPathAndFilename: '/usr/bin/php'
      subRequestIniEntries:
        memory_limit: 2048M
    persistence:
      backendOptions:
        driver: pdo_mysql
        dbname: ${USER}
        user: ${USER}
        password: '$(grep -Po -m 1 "password=\K(\S)*" ~/.my.cnf)'
        host: localhost

TYPO3: *settings
__EOF__
            _msgInfo "Following configuration was written"
            cat Configuration/Settings.yaml
            echo
        }
    ;;
    (Local)
        alias h='cd ~/'
        alias r='cd ~/Repos'
        alias n='cd ~/Repos/Neos.Plugins'
        alias p='cd ~/Repos/_Jonnitto/'
        alias copyKey='_msgSuccess "SSH Key copied to clipboard";pbcopy < ~/.ssh/id_rsa.pub'
        alias copyBashInstall='_msgSuccess "Install command for bash script copied to clipboard";echo "wget -qN ${_BASH_SCRIPT_LOCATION} -O syncBashScript.sh; source syncBashScript.sh" | pbcopy'
        alias startserver='http-server -a localhost -p 8000 -c-1'
        alias webpack-dev-server='node ./node_modules/webpack-dev-server/bin/webpack-dev-server.js --port 8073'
        alias installGoogleFonts='_msgSuccess "Install all Google Fonts ...";curl https://raw.githubusercontent.com/qrpike/Web-Font-Load/master/install.sh | sh'
        alias ios='open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app'
        alias sshConnect='ssh $(basename "$PWD")'
        alias editConnect='code ~/.ssh/config'
        alias yui='yarn upgrade-interactive --latest'
        alias initCarbon='git init;git add .;git commit -m ":tada: Initial commit";git remote add origin git@github.com:CarbonPackages/$(basename "$PWD").git;git push -u origin master'
        alias gulpfileDiff='ksdiff ~/Repos/Neos.Plugins/Carbon.Gulp Build/Gulp'
        alias openNeosPlugins='code ~/Repos/Neos.Plugins'

        alias gl="git log --graph --pretty=format:'%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
        alias gp='git push origin HEAD'
        alias gd='git diff'
        alias gco='git checkout'
        alias gcb='git copy-branch-name'
        alias gb='git branch'
        alias gs='git status'
        alias ga='git add'
        alias gap='git add -p'
        alias gfr='git stash && git fetch && git rebase && git stash pop'
        neosPluginsDiff() {
            if [ $1 ]
                then
                    if [ $1 == Carbon.* ]
                        then ksdiff ~/Repos/Neos.Plugins/$1 Packages/Carbon/$1
                        else ksdiff ~/Repos/Neos.Plugins/$1 Packages/Plugins/$1
                    fi
                else ksdiff ~/Repos/Neos.Plugins Packages/Plugins Packages/Carbon
            fi
        }
        gc() {
            if [ -z ${1+x} ]
                then _msgError "Please set a commit message"
                else git commit -m "$1"
            fi
        }
        gca() {
            if [ -z ${1+x} ]
                then git commit -a
                else git commit -a -m "$1"
            fi
        }
        deleteGitTag() {
            if [ -z ${1+x} ]
                then _msgError "Please set a tag as first argument"
                else
                    _msgError "Delete Git tag" "'$1'"
                    git tag -d $1
                    git push origin :refs/tags/$1
                    echo
            fi
        }

        sshList() {
            # list hosts defined in ssh config

            awk '$1 ~ /Host$/ {for (i=2; i<=NF; i++) print $i}' ~/.ssh/config
        }

        # With the command `NeosProject` you get the site package folder and available folders definded in `ADDITIONAL_FOLDER`
        # With `codeProject` you open your project in Visual Studio Code
        # With `atomProject` you open your project in Atom
        # With `pstormProject` you open your project in PHP Storm
        # To disable the fallback (open current folder), change the fallback variable to ""

        NeosProject() {
            # Places where site packages could are stored
            local SITE_FOLDER=("DistributionPackages" "src" ".src" "Packages/Sites")

            # Additional folder to open
            local ADDITIONAL_FOLDER=("Packages/Carbon" "Packages/Plugins" "Web")

            local FOLDER_ARRAY=()

            local fallback="."

            # Get the site folder
            for f in "${SITE_FOLDER[@]}"
                do
                if [ -d "$f" ] && [[ ${#FOLDER_ARRAY[@]} == 0 ]]
                    then FOLDER_ARRAY+=("${f}/$([ $(echo ${f}/* | wc -w) = 1 ] && basename ${f}/*)");
                fi
            done

            # Get additional folder
            for f in "${ADDITIONAL_FOLDER[@]}"
                do
                if [ -d "${f}" ]
                    then FOLDER_ARRAY+=($f)
                fi
            done

            # Fallback
            if [ -n "$fallback" ] && [[ ${#FOLDER_ARRAY[@]} == 0 ]]
                then FOLDER_ARRAY=($fallback)
            fi;
            echo "${FOLDER_ARRAY[@]}"
        }

        codeProject() {
            # If we have a code workspace, open this instead
            if [[ -f *.code-workspace ]]
                then for f in *.code-workspace; do open "$f"; done;
                else code $(NeosProject)
            fi;
        }

        atomProject() {
            atom $(NeosProject)
        }

        pstormProject() {
            pstorm $(NeosProject)
        }

        # Generate the DB and the 'Settings.yaml' file
        writeNeosSettings() {
            _checkNeos; [ $? -ne 0 ] && return 1
            _msgInfo "Write configuration file for Neos ..."
            dbName=$(echo ${PWD##*/} | perl -ne 'print lc(join("_", split(/(?=[A-Z])/)))')
            dbName="${dbName}_neos"
            _msgInfo "Create Database" $dbName
            mysql -uroot -proot -e "create database ${dbName}"
            cat > Configuration/Settings.yaml <<__EOF__
Neos: &settings
  Imagine:
    driver: Imagick
  Flow:
    core:
      subRequestIniEntries:
        memory_limit: 2048M
    persistence:
      backendOptions:
        driver: pdo_mysql
        dbname: ${dbName}
        user: root
        password: root
        host: 127.0.0.1

TYPO3: *settings
__EOF__

            _msgInfo "Following configuration was written"
            cat Configuration/Settings.yaml
            echo
        }
    ;;
esac

# ================================
#      HELPME
# ================================
helpme() {
    _Headline() {
        if _available $1; then
            _printHeadline $2
        fi
    }

    _printHeadline() {
        printf "\n\n                     ${GREEN}$1\n----------------------------------------------------------------------------${NC}\n"
    }

    _Entry() {
        if _available $1; then
            printf "\n${CYAN}%20s${NC} %-50s\n" \
            $1 "$2"
        fi
    }

    _Lines() {
        if _available $1; then
        printf "${CYAN}%20s${NC} %-50s\n" \
        "" "$2"
        fi
    }

    _Headline go2 System
    _Entry go2www "Go to the www folder"
    _Entry go2 "Try to go to the Neos or Shopware folder"
    _Entry readKey "Output the ssh public key"
    _Entry copyKey "Copy the ssh public key to the clipboard"
    _Entry generateKey "Create a ssh key and output the public key"
    _Entry startserver "Start local server, listen to port 8000"
    _Entry installGoogleFonts "Install all Google Fonts to your system"
    _Entry sshConnect "Open SSH connection based on the folder name"
    _Entry ios "Open the iOS Simulator"
    _Entry sshConnect "Open SSH connection based on the folder name"
    _Entry editConnect "Edit the SSH connection presets"
    _Entry deleteGitTag "Delete a git tag and push it to origin"
    _Entry yui "Update the dependencies with yarn"
    _Entry readSQLConfig "Read the SQL configuration"
    _Entry installImgOptimizer "Install jpegtran-bin, optipng-bin,"
    _Lines installImgOptimizer "gifsicle and svgo globally with npm"

    _Headline deleteGitTag Git
    _Entry gl "Output the git log"
    _Entry gp "Push to origin"
    _Entry gd "git diff"
    _Entry gc "Commit with a message"
    _Entry gca "Commit automatically stage files that have been,"
    _Lines gca "modified and deleted but new files you have not"
    _Lines gca "told Git about are not affected"
    _Entry gco "git checkout"
    _Entry gcb "git copy-branch-name"
    _Entry gb "git branch"
    _Entry gs "git status"
    _Entry ga "git add"
    _Entry gap "git add with patch mode"
    _Entry gfr "git stash && git fetch && git rebase && git stash pop"
    _Entry deleteGitTag "Delete a git tag and push it to origin"

    _Headline updateShopware Shopware
    _Entry go2Shopware "Go to the Shopware Folder"
    _Entry updateShopware "Pulls newest changes, clear the cache"
    _Lines updateShopware "and generate the theme cache"

    _Headline flowhelp Neos
    _Entry go2Neos "Go to the Neos Folder"
    _Entry writeNeosSettings "Generate the 'Settings.yaml' file"
    printf "\n\n\n"
    unset _Headline
    unset __printHeadline
    unset _Entry
    unset _Lines
}

# ================================
#    SET PROMT AND ALIAS
# ================================

alias df='df -h'
alias du='du -h --max-depth=1'
alias grep='grep --color=auto'
alias mkdir='mkdir -pv'
alias head='head -n 50'
alias tail='tail -n 50'

alias ..='cd ..'         # Go up one directory
alias cd..='cd ..'       # Common misspelling for going up one directory
alias ...='cd ../..'     # Go up two directories
alias ....='cd ../../..' # Go up three directories
alias -- -='cd -'        # Go back

# Shell History
alias h='history'

# Display whatever file is regular file or folder
catt() {
  for i in "$@"; do
    if [ -d "$i" ]; then
      ls "$i"
    else
      cat "$i"
    fi
  done
}


# List directory contents
if ls --color -d . &> /dev/null
    then alias ls="ls --color=auto"
elif ls -G -d . &> /dev/null
    then alias ls='ls -G'          # Compact view, show colors
fi

alias sl=ls
alias l='ls -a'
alias ll='ls -lh'
alias la='ls -lsha'
alias l1='ls -1'

alias q='exit'
alias c='clear'

alias cu='composer update'
alias ci='composer install'
alias co='composer outdated'
alias cr='composer require'
alias crnu='composer require --no-update'

function commitUpdate() {
    git add *.lock
    git commit -m ":arrow_up: Update dependencies"
    git push
}

printf "\n\n    ${GREEN}Synchronized shell scripts from GitHub for ${WHITE}${server}${GREEN} successfully loaded${NC}\n\n    For an overview of the commands type ${CYAN}helpme${NC}\n\n"
if [[ -f "syncBashScript.sh" ]]; then rm syncBashScript.sh; fi

}