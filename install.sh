#!/bin/bash

# Section: Used from https://medium.com/@Drew_Stokes/bash-argument-parsing-54f3b81a6a8f all credit goes to Drew Stokes<https://medium.com/@Drew_Stokes>
PROFILE=default
PARAMS=""
while (("$#")); do
  case "$1" in
  -p | --profile)
    PROFILE=$2
    shift 2
    ;;
  --) # end argument parsing
    shift
    break
    ;;
  -* | --*=) # unsupported flags
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
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
ROOT_PATH="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
unset DIR
unset SOURCE
# End Section

if test -f "$ROOT_PATH/profiles/default/settings.conf"; then
  source $ROOT_PATH/profiles/default/settings.conf
fi

PROFILE_PATH=$ROOT_PATH/profiles/$PROFILE/settings.conf
if test -f "$PROFILE_PATH"; then
  source $PROFILE_PATH
  echo "[INFO] Loaded profile: $PROFILE from $PROFILE_PATH"
else
  echo "[WARN] Unable to find profile: $PROFILE"
  echo "[INFO] Loaded profile: default from $ROOT_PATH/profiles/default/settings.conf"
fi

OS=
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
  OS="windows"
else
  OS="linux"
fi

if [[ $OS -ne "windows" ]]; then
  if [[ $CONF_INSTALL_VSCODE ]]; then
    echo -n "[INFO] Installing VSCode... "

    case $OS in
    macos)
      brew cask install vscode
      ;;
    *)
      echo "NOT SUPPORTED"
      ;;
    esac

    echo "SUCCESS"
  else
    echo "[INFO] Installing VSCode... Skipping"
  fi
fi

echo "[INFO] Successful all software installed!"

echo "[INFO] Cloning repository to ~/.dotfiles"

# git clone https://github.com/mrcrille/dotfiles ~/.dotfiles

echo "[INFO] Finished cloning repository!"

cd ~/.dotfiles

if [[ "$OSTYPE" == "cygwin" ]]; then
  echo -n "[INFO] Installing apt-cyg..."
  install ~/.dotfiles/bin/apt-cyg /bin >/dev/null 2>&1
  if [ $? ]; then
    echo "SUCCESS"
  else
    echo "FAILED"
  fi

  echo -n "[INFO] Installing dig..."
  apt-cyg install bind >/dev/null 2>&1
  if [ $? ]; then
    echo "SUCCESS"
  else
    echo "FAILED"
  fi
fi

if [ $CONF_INSTALL_VSCODE -eq 1 ]; then
  echo -n "[INFO] Writing VSCode Settings... "

  __CONF_VSCODE_SETTINGS=
  __CONF_VSCODE_SETTINGS_TARGET=
  case $OS in
  windows)
    __CONF_VSCODE_SETTINGS=$CONF_VSCODE_SETTINGS_WIN32
    __CONF_VSCODE_SETTINGS_TARGET=$(cygpath $CONF_VSCODE_SETTINGS_TARGET_WIN32)
    ;;
  linux)
    __CONF_VSCODE_SETTINGS=$CONF_VSCODE_SETTINGS_LINUX
    __CONF_VSCODE_SETTINGS_TARGET=$CONF_VSCODE_SETTINGS_TARGET_LINUX
    ;;
  macos)
    __CONF_VSCODE_SETTINGS=$CONF_VSCODE_SETTINGS_MACOS
    __CONF_VSCODE_SETTINGS_TARGET=$CONF_VSCODE_SETTINGS_TARGET_MACOS
    ;;
  *)
    echo "NOT SUPPORTED"
    ;;
  esac

  if test -f $CONF_VSCODE_SETTINGS_SHARE; then
    if test -f $__CONF_VSCODE_SETTINGS; then

      jq -S -s '.[0] * .[1]' $CONF_VSCODE_SETTINGS_SHARE $__CONF_VSCODE_SETTINGS >$__CONF_VSCODE_SETTINGS_TARGET

      if [ $? ]; then
        echo "SUCCESS"
      else
        echo "FAILED"
      fi
    fi
  fi

  echo "[INFO] Installing VSCode extensions... "

  CONF_VSCODE_EXTENSIONS=
  case $OS in
  windows)
    CONF_VSCODE_EXTENSIONS=$CONF_VSCODE_EXTENSIONS_WIN32
    ;;
  linux)
    CONF_VSCODE_EXTENSIONS=$CONF_VSCODE_EXTENSIONS_LINUX
    ;;
  macos)
    CONF_VSCODE_EXTENSIONS=$CONF_VSCODE_EXTENSIONS_MACOS
    ;;
  *)
    echo "NOT SUPPORTED"
    ;;
  esac

  for f in $CONF_VSCODE_EXTENSIONS_SHARE; do
    if [[ ! $f == *\*\* ]]; then
      EXT=$(basename $f)
      if [ ! "$EXT" == ".gitkeep" ]; then
        echo -n "[INFO] Installing extension '$EXT'... "
        if ERROR=$(code --force --install-extension $EXT); then
          echo "SUCCESS"
        else
          echo "FAILED"
          echo $ERROR
        fi
      fi
    fi
  done

  for f in $CONF_VSCODE_EXTENSIONS; do
    if [[ ! $f == *\*\* ]]; then
      EXT=$(basename $f)
      if [ ! "$EXT" -ne ".gitkeep" ]; then
        echo -n "[INFO] Installing extension '$EXT'... "
        if ERROR=$(code --force --install-extension $EXT); then
          echo "SUCCESS"
        else
          echo "FAILED"
          echo $ERROR
        fi
      fi
    fi
  done

  echo "[INFO] Finished installing VSCode extensions!"
fi

BACKUP=0
while true; do
    read -p "[INFO] Do you wish to backup existing files? (y/N) " yn
    case $yn in
        [Yy]* ) BACKUP=1; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

if [ $CONF_SYSTEM -eq 1 ]; then
  echo "[INFO] Writing System files"

  for f in $CONF_SYSTEM_PATH; do
    if test -f $f; then
      N=$(basename $f)
      H=~
      if test -f $H/$N && [ $BACKUP -eq 1 ]; then
        mv $H/$N $H/$N.bak
        echo "[INFO] Created backup of $H/$N"
      fi
      rm -rf $H/$N
      ln -s $f $H/$N
    fi
  done
fi

if [ $CONF_PROFILE -eq 1 ]; then
  echo "[INFO] Writing Profile files"

  for f in $CONF_PROFILE_PATH; do
    if test -f $f; then
      N=$(basename $f)
      H=~
      if test -f $H/$N && [ $BACKUP -eq 1 ]; then
        mv $H/$N $H/$N.bak
        echo "[INFO] Created backup of $H/$N"
      fi
      rm -rf $H/$N
      ln -s $f $H/$N
    fi
  done
fi
