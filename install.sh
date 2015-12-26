#!/usr/bin/env bash

########################################################################################

NORM=0
BOLD=1
UNLN=4
RED=31
GREEN=32
BROWN=33
BLUE=34
MAG=35
CYAN=36
GREY=37

CL_NORM="\e[${NORM}m"
CL_BOLD="\e[${BOLD}m"
CL_UNLN="\e[${UNLN}m"
CL_RED="\e[${RED}m"
CL_GREEN="\e[${GREEN}m"
CL_BROWN="\e[${BROWN}m"
CL_BLUE="\e[${BLUE}m"
CL_MAG="\e[${MAG}m"
CL_CYAN="\e[${CYAN}m"
CL_GREY="\e[${GREY}m"
CL_BL_RED="\e[${RED};1m"
CL_BL_GREEN="\e[${GREEN};1m"
CL_BL_BROWN="\e[${BROWN};1m"
CL_BL_BLUE="\e[${BLUE};1m"
CL_BL_MAG="\e[${MAG};1m"
CL_BL_CYAN="\e[${CYAN};1m"
CL_BL_GREY="\e[${GREY};1m"
CL_UL_RED="\e[${RED};4m"
CL_UL_GREEN="\e[${GREEN};4m"
CL_UL_BROWN="\e[${BROWN};4m"
CL_UL_BLUE="\e[${BLUE};4m"
CL_UL_MAG="\e[${MAG};4m"
CL_UL_CYAN="\e[${CYAN};4m"
CL_UL_GREY="\e[${GREY};4m"
CL_BG_RED="\e[${RED};7m"
CL_BG_GREEN="\e[${GREEN};7m"
CL_BG_BROWN="\e[${BROWN};7m"
CL_BG_BLUE="\e[${BLUE};7m"
CL_BG_MAG="\e[${MAG};7m"
CL_BG_CYAN="\e[${CYAN};7m"
CL_BG_GREY="\e[${GREY};7m"

########################################################################################

# List of supported command line arguments (String)
SUPPORTED_ARGS="debug yes"

# List of supported short command line arguments (String)
SHORT_ARGS="D:!debug y:!yes"

########################################################################################

# Flag will be set to true if some required apps is not installed (Boolean)
requireFailed=""

# Script directory (String)
script_dir=$(dirname "$0")

########################################################################################

# Main func
#
# *: All arguments passed to script
#
# Code: No
# Echo: No
main() {
  pushd $script_dir &> /dev/null

    doInstall

  popd &> /dev/null
}

# Install app
#
# Code: No
# Echo: No
doInstall() {
  requireRoot

  confirmInstall "RBInstall"

  require "go"
  require "p7zip"
  require "ca-certificates"

  if [[ $requireFailed ]] ; then
    exit 1
  fi

  local install_dir="$GOPATH/src/github.com/essentialkaos/rbinstall"

  action "Creating directory for sources in \$GOPATH" \
         "mkdir" "-p" "$install_dir"

  action "Copying sources to \$GOPATH src directory" \
         "cp" "-r" "*" "$install_dir/"

  action "Installing go dependencies" \
         "go" "get" "-t" "-v" "$install_dir/..."

  action "Building app" \
         "go" "build" "$install_dir/rbinstall.go"

  action "Copying app to /usr/bin" \
         "install" "-pm 755" "$install_dir/rbinstall" "/usr/bin/rbinstall"

  action "Removing builded app from src directory" \
         "rm" "-f" "$install_dir/rbinstall"

  action "Copying config file to /etc" \
         "install" "-pm 644" "rbinstall.conf" "/etc/rbinstall.conf"

  congratulate "RBInstall"
}

# Do some install action
#
# 1: Description (String)
# *: Command
#
# Code: No
# Echo: No
action() {
  local desc="$1"

  shift 1

  if [[ $debug ]] ; then
    $@
  else
    $@ &> /dev/null
  fi
  
  if [[ $? -ne 0 ]] ; then
    show "${CL_RED}+${CL_NORM} $desc"
    show "\nError occured with last action. Install process will be interrupted.\n" $RED
    exit 1
  else
    show "${CL_GREEN}+${CL_NORM} $desc"
  fi
}

# Check required app
#
# 1: App binary name (String)
#
# Code: No
# Echo: No
require() {
  local app="$1"

  type -p $app &> /dev/null

  if [[ $? -ne 0 ]] ; then
    show "$app is required please install it before this app install" $BROWN
    requireFailed=true
  fi
}

# Require root priveleges
#
# Code: No
# Echo: No
requireRoot() {
  if [[ $(id -u) != "0" ]] ; then
    show "Superuser priveleges is required for install" $RED
    exit 1
  fi
}

# Confirm install
#
# 1: App name (String)
#
# Code: Yes
# Echo: No
confirmInstall() {
  if [[ $yes ]] ; then
    show "Argument --yes/-y passed to script, install forced" $GREY
    return 0
  fi

  show ""
  show "You really want install latest version of $1? (y/N):" $CYAN

  if ! readAnswer "N" ; then
    return 1
  fi
}

# Congratulate with success install
#
# 1: App name (String)
#
# Code: No
# Echo: No
congratulate() {
  show "\nYay! $1 is succefully installed!\n" $GREEN
}

# Read user yes/no answer
#
# 1: Default value (String)
#
# Code: Yes
# Echo: No
readAnswer() {
  local defval="$1"
  local answer

  read -e -p "> " answer

  show ""

  answer=$(echo "$answer" | tr "[:lower:]" "[:upper:]")

  [[ -z $answer ]] && answer="$defval"

  if [[ ${answer:0:1} == "Y" ]] ; then
    return 0
  else
    return 1
  fi
}

# Show message
#
# 1: Message (String)
# 2: Color code (Number) [Optional]
#
# Code: No
# Echo: No
show() {
  if [[ -n "$2" ]] ; then
    echo -e "\e[${2}m${1}${CL_NORM}"
  else
    echo -e "$@"
  fi
}

# Show error message about unsupported argument
#
# 1: Argument (String)
#
# Code: No
# Echo: No
showArgWarn() {
  show "Unknown argument $1." $RED
  exit 1
}

## ARGUMENTS PARSING 2 #################################################################

[[ $# -eq 0 ]] && main && exit $?

unset arg argn argm argv argt argk

argv="$*" ; argt=""

while [[ -n "$1" ]] ; do
  if [[ "$1" =~ \  && -n "$argn" ]] ; then
    declare $argn="$1"

    unset argn && shift && continue
  elif [[ $1 =~ ^-{1}[a-zA-Z0-9]{1,2}+.*$ ]] ; then
    argm=${1:1}

    if [[ \ $SHORT_ARGS\  =~ \ $argm:!?([a-zA-Z0-9_]*) ]] ; then
      arg="${BASH_REMATCH[1]}"
    else
      showArgWarn "-$argm" 2> /dev/null || :
      shift && continue
    fi

    if [[ -z "$argn" ]] ; then
      argn=$arg
    else
      [[ -z "$argk" ]] && ( showArgValWarn "--$argn" 2> /dev/null || : ) || declare $argn=true
      argn=$arg
    fi

    if [[ ! $SUPPORTED_ARGS\  =~ !?$argn\  ]] ; then
      showArgWarn "-$argm" 2> /dev/null || :
      shift && continue
    fi

    if [[ ${BASH_REMATCH[0]:0:1} == "!" ]] ; then
      declare $argn=true ; unset argn ; argk=true
    else
      unset argk
    fi

    shift && continue
  elif [[ "$1" =~ ^-{2}[a-zA-Z]{1}[a-zA-Z0-9_-]+.*$ ]] ; then
    arg=${1:2}

    if [[ $arg == *=* ]] ; then
      IFS="=" read -ra arg <<< "$arg"

      argm="${arg[0]}" ; argm=${argm//-/_}

      if [[ ! $SUPPORTED_ARGS\  =~ $argm\  ]] ; then
        showArgWarn "--${arg[0]//_/-}" 2> /dev/null || :
        shift && continue
      fi

      [[ -n "${!argm}" && $MERGEABLE_ARGS\  =~ $argm\  ]] && declare $argm="${!argm} ${arg[@]:1:99}" || declare $argm="${arg[@]:1:99}"

      unset argm && shift && continue
    else
      arg=${arg//-/_}

      if [[ -z "$argn" ]] ; then
        argn=$arg
      else
        [[ -z "$argk" ]] && ( showArgValWarn "--$argn" 2> /dev/null || : ) || declare $argn=true
        argn=$arg
      fi

      if [[ ! $SUPPORTED_ARGS\  =~ !?$argn\  ]] ; then
        showArgWarn "--${argn//_/-}" 2> /dev/null || :
        shift && continue
      fi

      if [[ ${BASH_REMATCH[0]:0:1} == "!" ]] ; then
        declare $argn=true ; unset argn ; argk=true
      else
        unset argk
      fi

      shift && continue
    fi
  else
    if [[ -n "$argn" ]] ; then
      [[ -n "${!argn}" && $MERGEABLE_ARGS\  =~ $argn\  ]] && declare $argn="${!argn} $1" || declare $argn="$1"

      unset argn && shift && continue
    fi
  fi

  argt="$argt $1" ; shift

done

[[ -n "$argn" ]] && declare $argn=true

unset arg argn argm argk

[[ -n "$KEEP_ARGS" ]] && main $argv || main ${argt:1:9999}

########################################################################################
