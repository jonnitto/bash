#!/usr/bin/env bash

# wget -qN https://raw.githubusercontent.com/jonnitto/bash/master/bash.sh -O syncBashScript.sh; source syncBashScript.sh

{  # make sure whole file is loaded

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[2;37m'
WHITE="\033[1;37m"
NC='\033[0m'

USER=$(whoami)
GROUP=$(id -g -n)

_BASH_SCRIPT_LOCATION='https://raw.githubusercontent.com/jonnitto/bash/master/bash.sh'

export CLICOLOR=1


# Get server type
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

# ================================
#    SET CONTEXT
# ================================
case $server in
    (Beach)
        SERVER_CONTEXT=$FLOW_CONTEXT
    ;;
    (NONE|Local)
        SERVER_CONTEXT=Development
        export FLOW_CONTEXT=Development
    ;;
    (*)
        SERVER_CONTEXT=Production
        export FLOW_CONTEXT=Development
    ;;
esac

# ================================
#    SERVER SPECIFIC
# ================================

case $server in
    (Uberspace|myNET|PunktDe)
        generateKey() { ssh-keygen -t rsa -b 4096 -C "$(hostname -f)"; readKey; }
    ;;
    (Beach|Local)
        alias runUnitTest='./Packages/Libraries/phpunit/phpunit/phpunit -c Build/BuildEssentials/PhpUnit/UnitTests.xml --colors=always'
        alias runFunctionalTest='./Packages/Libraries/phpunit/phpunit/phpunit -c Build/BuildEssentials/PhpUnit/FunctionalTests.xml --colors=always'
    ;;
esac
case $server in
    (Uberspace)
        WEB_ROOT="/var/www/virtual/${USER}"
        NEOS_ROOT="/var/www/virtual/${USER}/Neos"
        NEOS_DEPLOYER="/var/www/virtual/${USER}/Neos/current"
        SHOPWARE_DEPLOYER="/var/www/virtual/${USER}/Shopware/current"
        alias readSQLConfig='cat ~/.my.cnf'
        alias installImgOptimizer='npm install -g jpegtran-bin optipng-bin gifsicle svgo'

        writeNeosSettings() {
            _checkNeos; [[ $? -ne 0 ]] && return 1
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
        alias neospluginsDiff='ksdiff ~/Repos/Neos.Plugins Packages/Plugins Packages/Carbon'
        alias gulpfileDiff='ksdiff ~/Repos/Neos.Plugins/Carbon.Gulp Build/Gulp'
        alias openNeosPlugins='code ~/Repos/Neos.Plugins'
        alias runFlow='./flow server:run --host neos.local'

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
        gc() {
            if [[ -z ${1+x} ]]
                then _msgError "Please set a commit message"
                else git commit -m "$1"
            fi
        }
        gca() {
            if [[ -z ${1+x} ]]
                then git commit -a
                else git commit -a -m "$1"
            fi
        }
        deleteGitTag() {
            if [[ -z ${1+x} ]]
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
                if [[ -d $f ]] && [[ ${#FOLDER_ARRAY[@]} == 0 ]]
                    then FOLDER_ARRAY+=("${f}/$([[ $(echo ${f}/* | wc -w) == 1 ]] && basename ${f}/*)");
                fi
            done

            # Get additional folder
            for f in "${ADDITIONAL_FOLDER[@]}"
                do
                if [[ -d "${f}" ]]
                    then FOLDER_ARRAY+=($f)
                fi
            done

            # Fallback
            if [[ -n "$fallback" ]] && [[ ${#FOLDER_ARRAY[@]} == 0 ]]
                then FOLDER_ARRAY=($fallback)
            fi;
            echo "${FOLDER_ARRAY[@]}"
        }

        codeProject() {
            # If we have a code workspace, open this instead
            if [ -f *.code-workspace ]
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
            _checkNeos; [[ $? -ne 0 ]] && return 1
            _msgInfo "Write configuration file for Neos ..."
            dbName=$(echo ${PWD##*/} | perl -ne 'print lc(join("_", split(/(?=[A-Z])/)))')
            dbName="neos_${dbName}"
            _msgInfo "Create Database" $dbName
            mysql -uroot -proot -e "create database ${dbName}"
            cat > Configuration/Settings.yaml <<__EOF__
Neos: &settings
  Imagine:
    driver: Gd
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
        host:  127.0.0.1

TYPO3: *settings
__EOF__

            _msgInfo "Following configuration was written"
            cat Configuration/Settings.yaml
            echo
        }
    ;;
esac

# ================================
#    HELPER FUNCTIONS
# ================================
_isNeos() {      if [[ -f "flow" ]] || [[ -f "flow.php" ]] || [[ -f "flow.bat" ]]; then echo true; fi }
_isShopware() {  if [[ -f "shopware.php" ]]; then echo true; fi }
_isMice() {      if [[ -d "mice" ]]; then echo true; fi }
_isWordpress() { if [[ -f "wp-login.php" ]]; then echo true; fi }
_isSystem() {
    if [[ $(_isNeos) ]]; then printf "Neos"
    elif [[ $(_isShopware) ]]; then printf "Shopware"
    elif [[ $(_isWordpress) ]]; then printf "Wordpress"
    elif [[ $(_isMice) ]]; then printf "Mice"
    fi
}
_available() { command -v $1 >/dev/null 2>&1; }
_msgError() { printf "\n    ${RED}${1}${NC} ${2}\n\n"; }
_msgInfo() { printf "\n    ${CYAN}${1}${GREEN} ${2}${NC}\n\n"; }
_msgSuccess() { printf "\n    ${GREEN}${1}${NC}\n\n"; }
_checkGitPull() {
    if [[ -d ".git" ]]; then git pull
        if [[ $? -ne 0 ]]; then
            _msgError "Couldn't pull newest changes. Please check the output above"
            return 1
        fi
    fi
}
_checkNeos() {
    if [[ ! $(_isNeos) ]]; then
        _msgError "You're not in a Neos folder"
        return 1
    fi
}
_checkShopware() {
    if [[ ! $(_isShopware) ]]; then
        _msgError "You're not in a Shopware folder"
        return 1
    fi
}
_checkMice() {
    if [[ ! $(_isMice) ]]; then
        _msgError "You're not in a Mice folder"
        return 1
    fi
}
_checkWordpress() {
    if [[ ! $(_isWordpress) ]]; then
        _msgError "You're not in a Wordpress folder"
        return 1
    fi
}

# ================================
#    GENERAL STUFF
# ================================

if [[ ! -z "$WEB_ROOT" ]]; then
    go2www() {
        if [ "$WEB_ROOT" ] && [[ -d "$WEB_ROOT" ]]; then cd $WEB_ROOT; fi
    }
fi

if [[ ! -z "$NEOS_ROOT" ]] || [[ ! -z "$NEOS_DEPLOYER" ]]; then
    go2Neos() {
        if [[ "$NEOS_DEPLOYER" ]] && [[ -d "$NEOS_DEPLOYER" ]] && [[ -f "$NEOS_DEPLOYER/flow" ]]
            then cd $NEOS_DEPLOYER
        elif [[ "$NEOS_ROOT" ]] && [[ -d "$NEOS_ROOT" ]] && [[ -f "$NEOS_ROOT/flow" ]]
            then cd $NEOS_ROOT
        elif [[ "$WEB_ROOT" ]] && [[ -f "${WEB_ROOT}/flow" ]]
            then type go2www &>/dev/null && go2www; 
        fi
    }
fi

if [[ ! -z "$SHOPWARE_DEPLOYER" ]]; then
    go2Shopware() {
        if [[ "$SHOPWARE_DEPLOYER" ]] && [[ -d "$SHOPWARE_DEPLOYER" ]] && [[ -f "$SHOPWARE_DEPLOYER/shopware.php" ]]
            then cd $SHOPWARE_DEPLOYER
        elif [[ "$WEB_ROOT" ]] && [[ -f "${WEB_ROOT}/shopware.php" ]]
            then type go2www &>/dev/null && go2www; 
        fi
    }
fi

if [[ ! -z "$WEB_ROOT" ]] || [[ ! -z "$NEOS_ROOT" ]] || [[ ! -z "$NEOS_DEPLOYER" ]] || [[ ! -z "$SHOPWARE_DEPLOYER" ]]; then
    go2() {
        type go2Shopware &>/dev/null && go2Shopware;
        type go2Neos &>/dev/null && go2Neos;
    }
fi

readKey() { echo; cat ~/.ssh/id_rsa.pub; echo; }

# Run this command to update your Neos/Shopware project
update() {
  if [[ $(_isNeos) ]]; then updateNeos
  elif [[ $(_isShopware) ]]; then updateShopware
  elif type go2 &>/dev/null; then
    go2
    if [[ $(_isNeos) ]]; then updateNeos
    elif [[ $(_isShopware) ]]; then updateShopware
    fi
  fi
}

# ================================
#    SHOPWARE
# ================================

updateShopware() {
    _checkShopware; [[ $? -ne 0 ]] && return 1
    _msgInfo "Update your Shopware Template ..."
    _checkGitPull; [[ $? -ne 0 ]] && return 1
    ./var/cache/clear_cache.sh
    php bin/console sw:cache:clear
    php bin/console sw:theme:cache:generate
    if [[ $? -eq 0 ]]
        then _msgSuccess "Update completed"
        else _msgError "Something went wrong. Please check the output above"
    fi
}

# ================================
#      NEOS
# ================================

# Display help for a Neos command
alias flowhelp="./flow help"
# Flush all caches
alias flushcache='FLOW_CONTEXT=${SERVER_CONTEXT} ./flow flow:cache:flush'
# Warm up caches
alias warmup='FLOW_CONTEXT=${SERVER_CONTEXT} ./flow flow:cache:warmup'
# Publish resources
alias publishResource='FLOW_CONTEXT=${SERVER_CONTEXT} ./flow resource:publish'
# Migrate the database schema
alias migratedb='FLOW_CONTEXT=${SERVER_CONTEXT} ./flow doctrine:migrate'
# Repair inconsistent nodes
alias noderepair='FLOW_CONTEXT=${SERVER_CONTEXT} ./flow node:repair'
# Output the setup password
alias getsetuppassword='cat Data/SetupPassword.txt'
# Convert the database schema to use the given character set and collation
alias setcharset='FLOW_CONTEXT=${SERVER_CONTEXT} ./flow database:setcharset'
alias prunesite='FLOW_CONTEXT=${SERVER_CONTEXT} ./flow site:prune'
alias importsite='FLOW_CONTEXT=${SERVER_CONTEXT} ./flow site:import --package-key $(basename Packages/Sites/*)'
alias exportsite='FLOW_CONTEXT=${SERVER_CONTEXT} ./flow site:export --package-key $(basename Packages/Sites/*) --tidy'
alias clonesite='FLOW_CONTEXT=${SERVER_CONTEXT} ./flow clone:preset'
alias createAdmin='./flow user:create --roles Administrator'

# Switch context between Development and Production
if [[ $FLOW_CONTEXT == "Development" ]] || [[ $FLOW_CONTEXT == "Production" ]]
    then
        switchContext() {
            if [[ $FLOW_CONTEXT == "Development" ]]
                then export FLOW_CONTEXT=Production
                else export FLOW_CONTEXT=Development
            fi
            _msgInfo "Set Flow Context to" $FLOW_CONTEXT
        }
fi

killcache() {
    _checkNeos; [[ $? -ne 0 ]] && return 1
    _msgInfo "Flush cache ..."
    sleep 2
    if _available setopt
        then setopt localoptions rmstarsilent
    fi
    FLOW_CONTEXT=${SERVER_CONTEXT} ./flow flow:cache:flush
    if [[ $? -ne 0 ]]; then
        sleep 10
        _msgInfo "Delete temporary folder ..."
        mv Data/Temporary Data/Temporary_OLD
        rm -rf Data/Temporary_OLD
    fi
    _msgInfo "Warmup caches ..."
    FLOW_CONTEXT=${SERVER_CONTEXT} ./flow flow:cache:warmup
}

# Remove thumbnails, publish resources, create and render thumbnails
recreateThumbnails() {
    _checkNeos; [[ $? -ne 0 ]] && return 1
    _msgInfo "Recreate thumbnails, this might take a while ..."
    FLOW_CONTEXT=${SERVER_CONTEXT} ./flow media:clearthumbnails
    FLOW_CONTEXT=${SERVER_CONTEXT} ./flow resource:publish
    FLOW_CONTEXT=${SERVER_CONTEXT} ./flow media:createthumbnails
    FLOW_CONTEXT=${SERVER_CONTEXT} ./flow media:renderthumbnails
    _msgSuccess "Done"
}

# Adjust file permissions for CLI and web server access
repairpermission() {
    _checkNeos; [[ $? -ne 0 ]] && return 1
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
}

updateNeos() {
    _checkNeos; [[ $? -ne 0 ]] && return 1
    _msgInfo "Update your Neos installation ..."
    _checkGitPull; [[ $? -ne 0 ]] && return 1
    if ! [[ $(git ls-files composer.lock) ]]
        then rm -f composer.lock
    fi
    local command="install --prefer-dist"
    if ! [[ $SERVER_CONTEXT == 'Development' ]]; then
        command="install --no-dev --prefer-dist"
    fi
    if [[ -f "composer.phar" ]]
        then eval php composer.phar $command
        else eval composer $command
    fi
    [[ $? -ne 0 ]] && _msgError "Something went wrong with composer." "Please check the output above" && return 1;
    killcache
    if [[ $? -ne 0 ]]; then
        _msgInfo "Please wait 90 seconds"
        sleep 90
    fi
    FLOW_CONTEXT=${SERVER_CONTEXT} ./flow doctrine:migrate
    [[ $? -ne 0 ]] && _msgError "Something went wrong with the database migration." "Please check the output above" && return 1;
    FLOW_CONTEXT=${SERVER_CONTEXT} ./flow resource:publish
    [[ $? -ne 0 ]] && _msgError "Something went wrong with on publishing the resources." "Please check the output above" && return 1;
    _msgSuccess "Update completed"
}

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

    _Headline update Update
    _Entry update "Update your Neos or Shopware instance"

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
    _Entry switchContext "Switch context between Development and Production"
    _Entry flowhelp "Display help for a Neos command"
    _Entry setcharset "Convert the database schema to use the given"
    _Lines setcharset "character set and collation"
    _Entry flushcache "Flush all caches"
    _Entry killcache "Try to flush all caches"
    _Entry publishResource "Publish resources"
    _Entry recreateThumbnails "Remove thumbnails, publish resources,"
    _Lines recreateThumbnails "create and render thumbnails"
    _Entry repairpermission "Adjust file permissions for CLI"
    _Lines repairpermission "and web server access"
    _Entry warmup "Warm up caches"
    _Entry migratedb "Migrate the database schema"
    _Entry noderepair "Repair inconsistent nodes"
    _Entry getsetuppassword "Output the setup password"
    _Entry updateNeos "Run this command to update your Neos project"
    _Lines updateNeos ""
    _Lines updateNeos "The command do the following steps:"
    _Lines go2Neos "* Go to the Neos folder"
    _Lines updateNeos "* Check if we are in a Neos folder"
    _Lines updateNeos "* Check if the installation is a monorepo"
    _Lines updateNeos "* Pull newest changes"
    _Lines updateNeos "* Remove the composer.lock file"
    _Lines updateNeos "* Install the composer dependencies"
    _Lines updateNeos "* Rescan package availability"
    _Lines updateNeos "* Recreates the PackageStates configuration"
    _Lines updateNeos "* Force-flush all caches"
    _Lines updateNeos "* Migrate the database schema"
    _Lines updateNeos "* Publish resources"
    printf "\n\n\n"
    unset _Headline
    unset __printHeadline
    unset _Entry
    unset _Lines
}

# ================================
#    AUTOMATIC INSTALL
# ================================
_installSyncBash() {
    if ! grep -sFq "$_BASH_SCRIPT_LOCATION" ~/.bash_sync; then
        _msgInfo "Install synchronized bash script ..."
        cat > ~/.bash_sync <<__EOF__
wget -qN ${_BASH_SCRIPT_LOCATION} -O syncBashScript.sh; source syncBashScript.sh
__EOF__
        case $server in
            (NONE) return 0 ;;
            (*) TARGET=~/.bash_profile ;;
        esac
        if ! grep -sFq "~/.bash_sync" $TARGET; then
            cat >> ${TARGET} <<__EOF__
# Load sync bash script
if [[ -f ~/.bash_sync ]]
  then source ~/.bash_sync
fi
__EOF__
        fi
    fi
}

_installSyncBash

_updateSyncBash() {
    wget -qN --no-cache $_BASH_SCRIPT_LOCATION -O syncBashScript.sh; source syncBashScript.sh
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

# colored grep
# Need to check an existing file for a pattern that will be found to ensure
# that the check works when on an OS that supports the color option
if grep --color=auto "a" "${BASH_IT}/"*.md &> /dev/null
then
  alias grep='grep --color=auto'
  export GREP_COLOR='1;33'
fi

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

_parse_git_branch() {
    local BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
    if [[ ! "${BRANCH}" == "" ]]; then
        local STAT=`_parse_git_dirty`
        printf "[${BRANCH}${STAT}]"
    fi
}

_parse_git_dirty() {
    local status=`LC_ALL=C git status 2>&1 | tee`
    local dirty=`echo -n "${status}" 2> /dev/null | grep "modified:" &> /dev/null; echo "$?"`
    local untracked=`echo -n "${status}" 2> /dev/null | grep "Untracked files" &> /dev/null; echo "$?"`
    local ahead=`echo -n "${status}" 2> /dev/null | grep "Your branch is ahead of" &> /dev/null; echo "$?"`
    local newfile=`echo -n "${status}" 2> /dev/null | grep "new file:" &> /dev/null; echo "$?"`
    local renamed=`echo -n "${status}" 2> /dev/null | grep "renamed:" &> /dev/null; echo "$?"`
    local deleted=`echo -n "${status}" 2> /dev/null | grep "deleted:" &> /dev/null; echo "$?"`
    local bits=''
    if [ "${renamed}" == "0" ]; then bits="→${bits}"; fi
    if [ "${ahead}" == "0" ]; then bits="↑${bits}"; fi
    if [ "${newfile}" == "0" ]; then bits="✚${bits}"; fi
    if [ "${untracked}" == "0" ]; then bits="⚑${bits}"; fi
    if [ "${deleted}" == "0" ]; then bits="✖${bits}"; fi
    if [ "${dirty}" == "0" ]; then bits="✱${bits}"; fi
    if [ ! "${bits}" == "" ]; then printf " ${bits}"; fi
}
_parse_git_color() {
  if [[ "$(_parse_git_dirty)" != "" ]] ; then printf $RED; else printf $GREEN; fi
}
_parse_system() {
    local system=$(_isSystem)
    if [ ! "${system}" == "" ]; then printf " (${system})"; fi
}

_parse_return() {
    if [[ $? -ne 0 ]]; then printf "$RED\xe2\x9c\x98$NC "; fi
}


PS1="\$(_parse_return)\[$GRAY\]\${_hostname}\\${_servername} \[$MAGENTA\]$(printf '\xe2\x9e\x9c') \[$CYAN\]\w \$([[ -n \$(git branch 2> /dev/null) ]])\[$MAGENTA\]\$(_parse_system) \[\$(_parse_git_color)\]\$(_parse_git_branch)\[$WHITE\]\n$ \[$NC\]"

printf "\n\n    ${GREEN}Synchronized bash scripts from GitHub for ${WHITE}${server}${GREEN} successfully loaded${NC}\n\n    For an overview of the commands type ${CYAN}helpme${NC}\n\n"
if [[ -f "syncBashScript.sh" ]]; then rm syncBashScript.sh; fi
}  # make sure whole file is loaded
