#!/bin/bash
function usage() {
  cat <<-EOT
  Usage :  bash $0 [options] [--] 

  Options: 
  -h                                     Display this message
  -c                                     Set config file (default "./config.ini")
  -l [debug|info|warn|error|fatal|off]   Set log level (default: info)
EOT
}

function internalCommands() {
  cat <<-EOT
  Commands :
    help      Display this message
    exit      Exit the script safely.
EOT
}

function readConfig() {
  [ -f ./"$configFile" ] || return 1
  export BOT_TOKEN MUSIC_U tgAPI
  BOT_TOKEN=$(awk -F '=' '/\[default\]/{a=1}a==1&&$1~/BOT_TOKEN/{print $2;exit}' "$configFile")
  MUSIC_U=$(awk -F '=' '/\[default\]/{a=1}a==1&&$1~/MUSIC_U/{print $2;exit}' "$configFile")
  tgAPI=$(awk -F '=' '/\[default\]/{a=1}a==1&&$1~/tgAPI/{print $2;exit}' "$configFile")
  if [ "$BOT_TOKEN" = "" ] || [ "$MUSIC_U" = "" ] || [ "$tgAPI" = "" ]; then
    return 1
  fi
  return 0
}

function writeConfig() {
  cat <<-EOF >"$configFile"
[default]
BOT_TOKEN=$BOT_TOKEN
MUSIC_U=$MUSIC_U
tgAPI=$tgAPI
EOF
}

function Configuration() {
  read -r -p "输入BOT_TOKEN: " BOT_TOKEN
  read -r -p "输入MUSIC_U: " MUSIC_U
  read -r -p "输入tgAPI (留空则为默认官方api): " tgAPI
  if [ "$tgAPI" = "" ]; then
    tgAPI="https://api.telegram.org"
  fi
  if [ "$BOT_TOKEN" != "" ] && [ "$MUSIC_U" != "" ] && [ "$tgAPI" != "" ]; then
    writeConfig
    if ! readConfig; then
      Configuration
    else
      return 0
    fi
  else
    return 1
  fi
}

function exitFunc() {
  unset BOT_TOKEN MUSIC_U tgAPI
  if [ "${logLevel}" != "off" ]; then
    printf "\r%s \033[32mSee you next time!\033[0m\n" "$(date +["%Y/%m/%d %T"])"
    mv ./latest.log ./"$(date +"%Y-%m-%d-%T")".log >/dev/null 2>&1
  fi
  rm ./cache/*.temp >/dev/null 2>&1
  kill 0
}

configFile="config.ini"

while getopts "l:c:h" opt; do
  case $opt in
  h)
    usage
    exit 0
    ;;
  l)
    logLevel="$OPTARG"
    ;;
  c)
    [ "$OPTARG" = "" ] || configFile="$OPTARG"
    ;;
  ?)
    usage
    exit 1
    ;;
  esac
done

readConfig
if ! readConfig; then
  echo "配置文件不存在"
  Configuration
  while ! readConfig; do
    Configuration
  done
fi

trap "exitFunc" SIGINT

if [ "${logLevel}" != "off" ]; then
  [ -f ./latest.log ] || touch latest.log
  tail -f ./latest.log &
fi

case "${logLevel}" in
debug)
  sed <main.sh -e 's:#LogDebug::' -e 's:>/dev/null:>>./latest.log:' -e 's:#LogInfo::' -e 's:#LogWarn::' -e 's:#LogError::' -e 's:#logFatal::' | bash - >./latest.log 2>&1 &
  ;;
info)
  sed <main.sh -e 's:#LogInfo::' -e 's:#LogWarn::' -e 's:#LogError::' -e 's:#logFatal::' | bash - >./latest.log 2>&1 &
  ;;
warn)
  sed <main.sh -e 's:#LogWarn::' -e 's:#LogError::' -e 's:#logFatal::' | bash - >./latest.log 2>&1 &
  ;;
error)
  sed <main.sh -e 's:#LogError::' -e 's:#logFatal::' | bash - >./latest.log 2>&1 &
  ;;
fatal)
  sed <main.sh -e 's:#logFatal::' | bash - >./latest.log 2>&1 &
  ;;
off)
  bash main.sh &
  ;;
*)
  sed <main.sh -e 's:#LogInfo::' -e 's:#LogWarn::' -e 's:#LogError::' -e 's:#logFatal::' | bash - >./latest.log 2>&1 &
  ;;
esac

while read -r -p "" input; do
  case "${input}" in
  exit)
    exitFunc
    ;;
  help)
    internalCommands
    ;;
  *)
    echo -n ""
    ;;
  esac
done
