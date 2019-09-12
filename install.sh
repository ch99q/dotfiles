#!/bin/bash

# Section: Used from https://medium.com/@Drew_Stokes/bash-argument-parsing-54f3b81a6a8f all credit goes to Drew Stokes<https://medium.com/@Drew_Stokes>
PARAMS=""
while (( "$#" )); do
  case "$1" in
    -p|--profile)
      PROFILE=$2
      shift 2
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done
# set positional arguments in their proper place
eval set -- "${PARAMS:1}"
unset PARAMS
# End Section

# Section: Used from https://stackoverflow.com/a/246128 all credit goes to Dave Dopson<https://stackoverflow.com/users/407731>
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
PATH="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
unset DIR
unset SOURCE
# End Section

bool(){ return "$((!${#1}))"; }

PROFILE_PATH=$PATH/profiles/$PROFILE/settings.conf
if test -f "$PROFILE_PATH"; then
    source $PROFILE_PATH
    echo "[INFO] Loaded profile: $PROFILE from $PROFILE_PATH"
fi

OS=
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
  OS="windows"
else
  OS="linux"
fi

if [[ -z $CONF_INSTALL_VSCODE ]]; then
    echo -n "[INFO] Installing VSCode... "

    case $OS in
      macos)
        brew cask install vscode
        ;;
      windows)
        choco install vscode
        ;;
      *)
        echo "NOT SUPPORTED"
        ;;
    esac

    echo "SUCCESS"
else
    echo "[INFO] Installing VSCode... Skipping"
fi

read