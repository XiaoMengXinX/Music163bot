#!/bin/bash
function checkCommand() {
    if [ "$(which "$1")" ]; then
        return 0
    else
        return 1
    fi
}

function encryptData() {
    openssl enc -aes-128-ecb -K 653832636b656e683864696368656e38 -nosalt | od -An -t xC | xargs | sed 's/[[:space:]]//g' | tr '[:upper:]' '[:lower:]'
}

function requestUtil() {
    local url api json text md5 encrypt length
    url=$1
    api=$2
    json=$3
    text="nobody${url}use${json}md5forencrypt"
    md5=$(echo -n "$text" | md5sum | cut -d ' ' -f1)
    data=$url-36cd479b6b5-$json-36cd479b6b5-$md5
    encrypt=$(echo -n "$data" | encryptData)
    length=$(echo -n "params=$encrypt" | wc -c)
    curl -s -X POST --output - \
        -H "User-Agent:NeteaseMusic/6.5.0.1575377963(164);Dalvik/2.1.0 (Linux; U; Android 9; MIX 2 MIUI/V12.0.1.0.PDECNXM)" \
        -H "Content-Type:application/x-www-form-urlencoded" \
        -H 'X-Real-IP:175.167.152.57' \
        -H "Content-Length:$length" \
        -H "Host:music.163.com" \
        -H "Connection:Keep-Alive" \
        -H "Cookie:buildver=1575377963; resolution=2030x1080; __csrf=f0983a1387968e3f5486bbdc26e5c864; osver=9;deviceId=bnVsbAkwMjowMDowMDowMDowMDowMAllM2UyNWQ0MjdlYmJmMmNjCXVua25vd24%3D; appver=6.5.0; MUSIC_U=984e8c072dc9c670f40d019a3699f326b07414de7fe3522d93c1dd4fdb7286b833a649814e309366;ntes_kaola_ad=1; NMTID=00OlgXBCAwajfc_u0Stkc-dAEdAvFoAAAF1njLDGQ; versioncode=164; mobilename=MIX2; os=android; channel=shenmasem202016; MUSIC_U=$MUSIC_U" \
        -d "params=$encrypt" \
        "https://music.163.com/eapi/$api" | openssl enc -aes-128-ecb -K 653832636b656e683864696368656e38 -nosalt -d

}

function getSongDetail() {
    requestUtil "/api/v3/song/detail" "/api/v3/song/detail" "{\"c\":\"[{\\\"id\\\":$1,\\\"v\\\":0}]\",\"e_r\":\"true\",\"header\":\"{}\"}"
}

function getSongUrl() {
    requestUtil "/api/song/enhance/player/url/v1" "/song/enhance/player/url/v1" "{\"e_r\":\"true\",\"encodeType\":\"mp3\",\"header\":\"{}\",\"ids\":\"[\\\"${1}_0\\\"]\",\"level\":\"lossless\"}"
}

function getSearchResult() {
    requestUtil "/api/v1/search/song/get" "/v1/search/song/get" "{\"sub\":\"false\",\"s\":\"$(echo "$1" | sed 's/["\]/\\&/g')\",\"offset\":\"0\",\"limit\":\"8\",\"queryCorrect\":\"true\",\"strategy\":\"10\",\"header\":\"{}\",\"e_r\":\"true\"}"
}

function getMe() {
    curl -s "${tgAPI}/bot$BOT_TOKEN/getMe"
}

function updateMessage() {
    curl -s "${tgAPI}/bot$BOT_TOKEN/getUpdates?offset=${1}"
}

function sendTextMessage() {
    if [ "$3" ]; then
        curl -s -X POST "${tgAPI}/bot${BOT_TOKEN}/sendMessage" -d "chat_id=${1}&parse_mode=Markdown&text=$(echo "$2" | sed 's/[_*`[\]/\\&/g')&reply_markup=${3}"
    else
        curl -s -X POST "${tgAPI}/bot${BOT_TOKEN}/sendMessage" -d "chat_id=${1}&parse_mode=Markdown&text=$(echo "$2" | sed 's/[_*`[\]/\\&/g')"
    fi
}

function editMessage() {
    if [ "$4" ]; then
        curl -s -X POST "${tgAPI}/bot${BOT_TOKEN}/editMessageText" -d "chat_id=${1}&message_id=${2}&parse_mode=Markdown&text=$(echo "$3" | sed 's/[_*`[\]/\\&/g')&reply_markup=${4}"
    else
        curl -s -X POST "${tgAPI}/bot${BOT_TOKEN}/editMessageText" -d "chat_id=${1}&message_id=${2}&parse_mode=Markdown&text=$(echo "$3" | sed 's/[_*`[\]/\\&/g')"
    fi
}

function deleteMessage() {
    curl -s -X POST "${tgAPI}/bot${BOT_TOKEN}/deleteMessage" -d "chat_id=${1}&message_id=${2}"
}

function answerCallbackQueryUrl() {
    curl -s -X POST "${tgAPI}/bot${BOT_TOKEN}/answerCallbackQuery" -d "callback_query_id=${1}&url=${2}"
}

function answerCallbackQueryText() {
    curl -s -X POST "${tgAPI}/bot${BOT_TOKEN}/answerCallbackQuery" -d "callback_query_id=${1}&text=${2}"
}

function answerInlineQuery() {
    curl -s -X POST "${tgAPI}/bot${BOT_TOKEN}/answerInlineQuery" -d "inline_query_id=${1}&results=${2}"
}

# sendMusicFromFile id ext name artist duration album songInfo chatID
function sendMusic() {
    curl -s -X POST "${tgAPI}/bot${BOT_TOKEN}/sendChatAction" -d "chat_id=$2&action=upload_audio" >/dev/null 2>&1
    curl "${tgAPI}/bot${BOT_TOKEN}/sendAudio" -s -X POST -F chat_id="$2" -F audio="${3}" -F title="$(echo "${4}" | sed 's/[@]/ &/')" -F performer="$(echo "${5}" | sed 's/[@]/ &/')" -F duration="${6}" -F thumb="@${7}" -F parse_mode="Markdown" -F caption="$(echo "${8}" | sed 's/[_*`[\]/\\&/g')" -F reply_markup="{\"inline_keyboard\":[[{\"text\":\"$(echo "${9}" | sed 's/["\]/\\&/g')\",\"url\": \"https://music.163.com/song/${1}/\"}],[{\"text\":\"Send me to...\",\"switch_inline_query\": \"music.163.com/song/${1}/\"}]]}"
}

function timeNow() {
    date +["%Y/%m/%d %T"]
}

# processMusic musicID chatID
function processMusic() {
    local i musicData musicName musicUrlData musicUrl musicExt musicSize musicSizeMB musicAlbum musicPicUrl musicArtistLen musicArtists msgID musicDuration musicSendingData musicFileID
    if [ ! -f "./cache/${1}.json" ] || [ ! -f "./cache/${1}.txt" ]; then
        [ -d "./cache" ] || mkdir "./cache"
        musicData=$(getSongDetail "$1")
        #LogDebug echo "[DEBUG] musicData: $musicData"
        musicName=$(echo "$musicData" | jq -r .songs[0].name)
        if [ "$musicName" = "null" ] || [ "$1" = "" ]; then
            sendTextMessage "$2" "错误的 MusicID : $id" >/dev/null 2>&1
            return 1
        fi
        musicUrlData=$(getSongUrl "$1")
        musicUrl=$(echo "$musicUrlData" | jq -r .data[0].url)
        musicExt="${musicUrl##*.}"
        musicSize=$(echo "$musicUrlData" | jq .data[0].size)
        musicSizeMB=$(echo "scale=2;${musicSize} / 1048576" | bc)
        musicAlbum=$(echo "$musicData" | jq -r .songs[0].al.name | tr -d "\n" | tr -d '[:cntrl:]')
        musicPicUrl=$(echo "$musicData" | jq -r .songs[0].al.picUrl)
        if [ "${musicExt}" != mp3 ] && [ "${musicExt}" != m4a ] && [ "${musicExt}" != flac ]; then
            musicExt=mp3
        fi
        musicArtistLen=$(echo "$musicData" | jq '.songs[0].ar|length')
        for ((i = 0; i < musicArtistLen; i++)); do
            if [ "$i" != $((musicArtistLen - 1)) ]; then
                musicArtists="${musicArtists}$(echo "$musicData" | jq -r .songs[0].ar[$i].name), "
            else
                musicArtists="${musicArtists}$(echo "$musicData" | jq -r .songs[0].ar[$i].name)"
            fi
        done
        if [ -f ./cache/"${1}.temp" ]; then
            sendTextMessage "$2" "${musicName}%0A专辑:+${musicAlbum}%0A${musicExt}  ${musicSizeMB}MB%0A正在下载中，请稍后再试。" >/dev/null 2>&1
            return 1
        fi
        touch ./cache/"${1}.temp"
        msgID=$(sendTextMessage "$2" "${musicName}%0A专辑:+${musicAlbum}%0A${musicExt}  ${musicSizeMB}MB%0A下载中..." | jq .result.message_id)
        #LogInfo printf "%s \033[32m[INFO]\033[0m ChatID: %s 开始下载 MusicID: %s (%s)\n" "$(timeNow)" "$2" "$1" "$(printf "%s - %s" "${musicName}" "${musicArtists}")"
        if checkCommand axel; then
            axel -n 8 -o ./cache/"${1}.${musicExt}" "$musicUrl" >/dev/null 2>&1
        #LogError returnCode="$?"
        else
            curl -s -X GET -H "User-Agent:NeteaseMusic/7.3.28.1604408871(7003028);Dalvik/2.1.0 (Linux; U; Android 9; MIX 2 MIUI/V12.0.1.0.PDECNXM)" -H 'X-Real-IP:175.167.152.57' -H "Referer:http://music.163.com/api/" -H "Range:bytes=0-${musicSize}" -H "Host:$(echo "${musicUrl%%.*}" | sed 's:\(.*\)/::').music.126.net" -H "Connection:Keep-Alive" "$musicUrl" -o ./cache/"${1}.${musicExt}" >/dev/null 2>&1
        #LogError returnCode="$?"
        fi
        if [ "$(ls -l ./cache/"${1}.${musicExt}" | awk '{print $5}')" -lt 800 ]; then
            sendTextMessage "$2" "${musicName}%%0A专辑:++${musicAlbum}%0A${musicExt}  ${musicSizeMB}MB%0A下载失败" >/dev/null 2>&1
            rm ./cache/"${1}.${musicExt}"
            #LogError printf "%s \033[31m[ERROR] ChatID: %s 下载 MusicID: %s (%s) 失败 (curl: %s)\033[0m\n" "$(timeNow)" "$2" "$1" "$(printf "%s - %s" "${musicName}" "${musicArtists}")" "returnCode: $returnCode"
            return 1
        fi
        musicDuration=$(soxi -D ./cache/"${1}.${musicExt}")
        echo "{\"name\":\"$(echo "${musicName}" | sed 's/["\]/\\&/g')\",\"album\":\"$(echo "${musicAlbum}" | sed 's/["\]/\\&/g')\",\"artist\":\"$(echo "${musicArtists}" | sed 's/["\]/\\&/g')\",\"ext\":\"${musicExt}\",\"size\":\"${musicSize}\",\"duration\":\"${musicDuration}\"}" >"./cache/${id}.json"
        curl "$musicPicUrl" -o ./cache/"${1}"_0.jpg >/dev/null 2>&1
        ffmpeg -i ./cache/"${1}"_0.jpg -vf "scale=1024:-1" ./cache/"${1}".jpg >/dev/null 2>&1
        #LogError returnCode="$?"
        #LogError [ "$returnCode" = 0 ] || printf "%s \033[31m[ERROR] ChatID: %s 压缩 MusicID: %s (%s) 专辑封面失败 (ffmpeg: %s)\033[0m\n" "$(timeNow)" "$2" "$1" "$(printf "%s - %s" "${musicName}" "${musicArtists}")" "$returnCode"
        if [ -f ./SongInfoAdder ]; then
            ./SongInfoAdder -i "cache/${1}.${musicExt}"
        fi
        editMessage "$2" "$msgID" "$musicName%0A专辑: ${musicAlbum}%0A${musicExt}++${musicSizeMB}MB%0A下载完成，发送中..." >/dev/null 2>&1
        cd cache || return 1
        #LogInfo printf "%s \033[32m[INFO]\033[0m ChatID: %s 下载 MusicID: %s (%s) 成功，正在上传\n" "$(timeNow)" "$2" "$1" "$(printf "%s - %s" "${musicName}" "${musicArtists}")"
        musicSendingData=$(sendMusic "$1" "$2" "@${1}.${musicExt}" "${musicName}" "${musicArtists}" "${musicDuration}" "${1}.jpg" "$(printf "「%s」 - %s\n专辑: %s\n#网易云音乐 #%s\nvia @%s" "${musicName}" "${musicArtists}" "${musicAlbum}" "${musicExt}" "${botName}")" "$(printf "%s - %s" "${musicName}" "${musicArtists}")")
        #LogDebug echo "[DEBUG] musicSendingData: $musicSendingData"
        musicFileID=$(echo "$musicSendingData" | jq -r .result.audio.file_id)
        rm ./"${1}"_0.jpg ./"${1}.temp" ./"${1}"."${musicExt}"
        if [ "$musicFileID" != 'null' ] && [ "$musicFileID" != '' ]; then
            echo -n "$musicFileID" >"${1}.txt"
            #LogInfo printf "%s \033[32m[INFO]\033[0m ChatID: %s 上传 MusicID: %s (%s) 成功\n" "$(timeNow)" "$2" "$1" "$(printf "%s - %s" "${musicName}" "${musicArtists}")"
        else
            editMessage "$2" "$msgID" "${musicName}%0A专辑:  ${musicAlbum}%0A${musicExt}  ${musicSizeMB}MB%0A发送失败" >/dev/null 2>&1
            #LogError printf "%s \033[31m[ERROR] ChatID: %s 上传 MusicID: %s (%s) 失败，请开启 debug 并检查日志\033[0m\n" "$(timeNow)" "$2" "$1" "$(printf "%s - %s" "${musicName}" "${musicArtists}")"
            return 1
        fi
        sleep 2
        deleteMessage "$2" "$msgID" >/dev/null 2>&1
        return 0
    else
        musicData=$(cat "./cache/${1}.json")
        musicExt=$(echo "$musicData" | jq -r .ext)
        musicName=$(echo "$musicData" | jq -r .name)
        musicArtists=$(echo "$musicData" | jq -r .artist)
        musicDuration=$(echo "$musicData" | jq -r .duration)
        musicAlbum=$(echo "$musicData" | jq -r .album)
        musicFileID=$(cat "./cache/${1}.txt")
        musicSize=$(echo "$musicData" | jq -r .size)
        musicSizeMB=$(echo "scale=2;${musicSize} / 1048576" | bc)
        msgID=$(sendTextMessage "$2" "${musicName}%0A专辑:+${musicAlbum}%0A${musicExt}  ${musicSizeMB}MB%0A命中缓存，发送中..." | jq .result.message_id)
        musicFileID=$(cat "./cache/${1}.txt")
        cd cache || return 1
        sendMusic "$1" "$2" "$musicFileID" "${musicName}" "${musicArtists}" "${musicDuration}" "${1}.jpg" "$(printf "「%s」 - %s\n专辑: %s\n#网易云音乐 #%s\nvia @%s" "${musicName}" "${musicArtists}" "${musicAlbum}" "${musicExt}" "${botName}")" "$(printf "%s - %s" "${musicName}" "${musicArtists}")" >/dev/null 2>&1
        #LogInfo printf "%s \033[32m[INFO]\033[0m ChatID: %s 上传 MusicID: %s (%s) 命中缓存\n" "$(timeNow)" "$2" "$1" "$(printf "%s - %s" "${musicName}" "${musicArtists}")"
        sleep 2
        deleteMessage "$2" "$msgID" >/dev/null 2>&1
        return 0
    fi
}

function processSearch() {
    local a i searchResult msgID searchResultNum musicArtistLen musicArtists musicName searchReport inlineMarkup inlineKeyboard
    searchResult=$(getSearchResult "${1}" | jq .result.songs)
    #LogDebug echo "[DEBUG] searchResult: $searchResult"
    if [ "$searchResult" = "null" ]; then
        sendTextMessage "$2" "未找到结果" >/dev/null 2>&1
        return 1
    fi
    msgID=$(sendTextMessage "$2" "搜索中..." | jq .result.message_id)
    searchResultNum=$(echo "$searchResult" | jq '.|length')
    for ((i = 0; i < searchResultNum; i++)); do
        musicName=$(echo "$searchResult" | jq -r .[$i].name)
        musicArtistLen=$(echo "$searchResult" | jq ".[$i].ar|length")
        musicArtists=""
        for ((a = 0; a < musicArtistLen; a++)); do
            if [ "$a" != $((musicArtistLen - 1)) ]; then
                musicArtists="${musicArtists}$(echo "$searchResult" | jq -r .[$i].ar[$a].name), "
            else
                musicArtists="${musicArtists}$(echo "$searchResult" | jq -r .[$i].ar[$a].name)"
            fi
        done
        if [ "$i" != $((searchResultNum - 1)) ]; then
            searchReport="${searchReport}$((i + 1)).「${musicName}」- ${musicArtists}%0A"
            inlineMarkup="${inlineMarkup}{\"text\":\"$((i + 1))\",\"callback_data\":\"musicid$(echo "$searchResult" | jq -r .[$i].id)\"},"
        else
            searchReport="${searchReport}$((i + 1)).「${musicName}」- ${musicArtists}"
            inlineMarkup="${inlineMarkup}{\"text\":\"$((i + 1))\",\"callback_data\":\"musicid$(echo "$searchResult" | jq -r .[$i].id)\"}"
        fi
    done
    inlineKeyboard="{\"inline_keyboard\":[[${inlineMarkup}]]}"
    #LogDebug echo "[DEBUG] inlineKeyboard:$inlineKeyboard"
    editMessage "$2" "${msgID}" "搜索结果:%0A${searchReport}" "${inlineKeyboard}" >/dev/null 2>&1
}

function processInlineQuery() {
    local musicData musicName musicExt musicAlbum musicArtists musicFileID replyMarkup inlineQueryResults
    if [ -f "./cache/${1}.json" ] && [ -f "./cache/${1}.txt" ]; then
        musicData=$(cat "./cache/${1}.json")
        musicName=$(echo "$musicData" | jq -r .name)
        musicAlbum=$(echo "$musicData" | jq -r .album)
        musicArtists=$(echo "$musicData" | jq -r .artist)
        musicExt=$(echo "$musicData" | jq -r .ext)
        musicFileID=$(cat "./cache/${1}.txt")
        replyMarkup="{\"inline_keyboard\":[[{\"text\":\"$(printf "%s - %s" "${musicName}" "${musicArtists}" | sed 's/["\]/\\&/g')\",\"url\": \"https://music.163.com/song/${1}/\"}],[{\"text\":\"Send me to...\",\"switch_inline_query\": \"music.163.com/song/${1}/\"}]]}"
        inlineQueryResults="[{\"type\":\"document\",\"id\":\"${2}\",\"title\":\"$(printf "%s - %s" "${musicName}" "${musicArtists}" | sed 's/["\]/\\&/g')\",\"document_file_id\":\"${musicFileID}\",\"caption\":\"$(printf "%s - %s" "${musicName}" "${musicArtists}" | sed 's/[_*`["\]/\\&/g')\n专辑: $(echo "${musicAlbum}" | sed 's/[_*`["\]/\\&/g')\n#网易云音乐 #${musicExt} \nvia @${botName} \",\"parse_mode\":\"Markdown\",\"reply_markup\":${replyMarkup},\"description\":\"$(echo "${musicAlbum}" | sed 's/["\]/\\&/g')\"}]"
        answerInlineQuery "${2}" "${inlineQueryResults}" >/dev/null 2>&1 &
    else
        inlineQueryResults="[{\"type\":\"article\",\"id\":\"${2}\",\"title\":\"歌曲未缓存\",\"input_message_content\":{\"message_text\":\"null\"},\"description\":\"点击上方按钮缓存歌曲\"}]"
        inlineQueryExt="&switch_pm_text=点我缓存歌曲&switch_pm_parameter=musicid${1}"
        answerInlineQuery "${2}" "${inlineQueryResults}${inlineQueryExt}" >/dev/null 2>&1 &
    fi
}

if ! checkCommand jq || ! checkCommand ffmpeg || ! checkCommand soxi || ! checkCommand curl || ! checkCommand openssl; then
    #logFatal checkCommand jq || printf "%s \033[31m[FATAL] 软件依赖: jq 缺失\033[0m\n" "$(timeNow)"
    #logFatal checkCommand ffmpeg || printf "%s \033[31m[FATAL] 软件依赖: ffmpeg 缺失\033[0m\n" "$(timeNow)"
    #logFatal checkCommand soxi || printf "%s \033[31m[FATAL] 软件依赖: sox 缺失\033[0m\n" "$(timeNow)"
    #logFatal checkCommand curl || printf "%s \033[31m[FATAL] 软件依赖: curl 缺失\033[0m\n" "$(timeNow)"
    #logFatal checkCommand openssl || printf "%s \033[31m[FATAL] 软件依赖: openssl 缺失\033[0m\n" "$(timeNow)"
    sleep 1 && kill 0
fi

#LogInfo printf "%s \033[32m[INFO]\033[0m 正在验证botToken...\n" "$(timeNow)"
botInfo=$(getMe)
#LogDebug echo "$botInfo"
if [ ! "$(echo "$botInfo" | jq .ok)" == true ]; then
    #logFatal printf "%s \033[31m[FATAL] 无法获取bot信息，请检查你的token\033[0m\n" "$(timeNow)"
    sleep 1 && kill 0
else
    #LogWarn [ "$(echo "$botInfo" | jq .result.can_read_all_group_messages)" = true ] || printf "%s \033[33m[WARN] 您的 bot 无法访问群组消息\033[0m\n" "$(timeNow)"
    #LogWarn [ "$(echo "$botInfo" | jq .result.supports_inline_queries)" = true ] || printf "%s \033[33m[WARN] 您的 bot 未开启 inline 功能\033[0m\n" "$(timeNow)"
    botName=$(echo "$botInfo" | jq -r .result.username)
    #LogInfo printf "%s \033[32m[INFO] Bot: %s 验证成功\033[0m\n" "$(timeNow)" "$botName"
fi

for (( ; ; )); do
    updateData=$(updateMessage "$updateID")
    while [ "$(echo "$updateData" | jq -r .result[0].update_id)" == null ]; do
        updateData=$(curl -s "${tgAPI}/bot$BOT_TOKEN/getUpdates")
        sleep 5
    done
    messageNumber=$(($(echo "$updateData" | jq '.result|length') - 1))
    for ((i = 0; i <= messageNumber; i++)); do
        if [ "$updateID" ] && [ "$(echo "$updateData" | jq -r .result[$i].update_id)" -gt "$updateID" ]; then
            #LogDebug echo "[DEBUG] updateData: $(echo "$updateData" | jq -r .result[$i])"
            message=$(echo "$updateData" | jq -r .result[$i].message.text)
            callback=$(echo "$updateData" | jq -r .result[$i].callback_query)
            chatID=$(echo "$updateData" | jq -r .result[$i].message.chat.id)
            chatType=$(echo "$updateData" | jq -r .result[$i].message.chat.type)
            inlineID=$(echo "$updateData" | jq -r .result[$i].inline_query.id)
            if [ "$callback" != "null" ]; then
                callbackMessage=$(echo "$callback" | jq -r .data)
                callbackQueryID=$(echo "$callback" | jq -r .id)
                if [ "$(echo "$callback" | jq -r .message.chat.type)" != "private" ]; then
                    answerCallbackQueryUrl "$callbackQueryID" "t.me/${botName}?start=${callbackMessage}" >/dev/null 2>&1 &
                else
                    callbackChatID=$(echo "$callback" | jq -r .message.chat.id)
                    id=$(echo "$callbackMessage" | sed 's:musicid::' | sed s/[[:space:]]//g)
                    if echo "$id" | grep -q '^[Z0-9 ]\+$'; then
                        answerCallbackQueryText "$callbackQueryID" "Success" >/dev/null 2>&1 &
                        processMusic "$id" "$callbackChatID" &
                        #LogInfo printf "%s \033[32m[INFO]\033[0m ChatID: %s (private) 通过 inlineKeyboard 请求 MusicID: %s\n" "$(timeNow)" "$callbackChatID" "$id"
                    fi
                fi
            fi
            if [ "$inlineID" ] && [ "$inlineID" != "null" ]; then
                inlineQuery=$(echo "$updateData" | jq -r .result[$i].inline_query.query)
                if echo "${inlineQuery}" | grep -q '^[Z0-9 ]\+$'; then
                    processInlineQuery "${inlineQuery}" "${inlineID}" >/dev/null 2>&1 &
                    #LogInfo printf "%s \033[32m[INFO]\033[0m inlineID: %s (From user %s) 请求 MusicID: %s\n" "$(timeNow)" "$inlineID" "$(echo "${updateData}" | jq -r .result[$i].inline_query.from.id)" "$inlineQuery"
                else
                    case "${inlineQuery}" in
                    help)
                        inlineQueryResults="[{\"type\":\"article\",\"id\":\"${inlineID}\",\"title\":\"\①在此粘贴网易云分享url\",\"input_message_content\":{\"message_text\":\"@Music163bot \"},\"description\":\"/help \"},{\"type\":\"article\",\"id\":\"$((inlineID - 233))\",\"title\":\"\②直接输入音乐id\",\"input_message_content\":{\"message_text\":\"@$botName \"},\"description\":\"/help \"}]"
                        answerInlineQuery "${inlineID}" "${inlineQueryResults}" >/dev/null 2>&1 &
                        ;;
                    *music.163.com*)
                        id=$(echo "${inlineQuery}" | tr -d "\n" | sed -e 's/[[:space:]]//g' -e 's:\(.*\)song?id=::' -e 's:\(.*\)song/::' -e 's:/\(.*\)::' -e 's:&\(.*\)::' -e 's:?user\(.*\)::')
                        if echo "${id}" | grep -q '^[Z0-9 ]\+$'; then
                            processInlineQuery "${id}" "${inlineID}" >/dev/null 2>&1 &
                            #LogInfo printf "%s \033[32m[INFO]\033[0m inlineID: %s (From user %s) 请求 MusicID: %s\n" "$(timeNow)" "$inlineID" "$(echo "${updateData}" | jq -r .result[$i].inline_query.from.id)" "$inlineQuery"
                        fi
                        ;;
                    esac
                fi
            fi
            case "${message}" in
            "/musicid"* | "/netease"* | *"music.163.com"* | "/start musicid"*)
                case "${message}" in
                *"music.163.com"*)
                    id=$(echo "$message" | tr -d "\n" | sed -e 's/[[:space:]]//g' -e 's:\(.*\)song?id=::' -e 's:\(.*\)song/::' -e 's:/\(.*\)::' -e 's:&\(.*\)::' -e 's:?user\(.*\)::')
                    ;;
                *)
                    id=$(echo "$message" | sed -e 's:/musicid::' -e 's:/netease::' -e "s:@${botName}::" -e 's:/start musicid::' -e s/[[:space:]]//g)
                    ;;
                esac
                [[ "$id" =~ [^0-9]+$ ]] || processMusic "$id" "$chatID" &
                #LogInfo printf "%s \033[32m[INFO]\033[0m ChatID: %s (%s) 请求 MusicID: %s\n" "$(timeNow)" "$chatID" "$chatType" "$id"
                ;;
            "/search"*)
                processSearch "$(echo "$message" | tr -d "\n" | sed -e 's:/search::' -e "s:@${botName}::" -e s/[[:space:]]// -e 's/["\]/\\&/g')" "$chatID" &
                #LogInfo printf "%s \033[32m[INFO]\033[0m ChatID: %s (%s) 请求 Search: %s\n" "$(timeNow)" "$chatID" "$chatType" "$(echo "$message" | sed -e 's:/search::' -e "s:@${botName}::" -e s/[[:space:]]// -e 's/["\]/\\&/g')"
                ;;
            esac
        fi
    done
    updateID=$(echo "$updateData" | jq -r .result["$(($(echo "$updateData" | jq '.result|length') - 1))"].update_id)
done
