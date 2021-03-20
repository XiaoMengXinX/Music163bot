#!/bin/bash
BOT_TOKEN=""
MUSIC_U=""
tgAPI='https://api.telegram.org'
botName=Music163bot

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

function answerCallbackQuery() {
    curl -s -X POST "${tgAPI}/bot${BOT_TOKEN}/answerCallbackQuery" -d "callback_query_id=${1}&url=${2}"
}

# sendMusicFromFile id ext name artist duration album songInfo chatID
function sendMusicFromFile() {
    curl -s -X POST "${tgAPI}/bot${BOT_TOKEN}/sendChatAction" -d "chat_id=$8&action=upload_audio" >/dev/null 2>&1
    curl ${tgAPI}/bot"${BOT_TOKEN}"/sendAudio -s -X POST -F chat_id="$8" -F audio="@${1}.${2}" -F title="${3}" -F performer="${4}" -F duration="${5}" -F thumb="@${1}.jpg" -F parse_mode="Markdown" -F caption="「$(echo "${3}" | sed 's/[_*`[\]/\\&/g')」 - $(echo "${4}" | sed 's/[_*`[\]/\\&/g')
	专辑: $(echo "${6}" | sed 's/[_*`[\]/\\&/g')
	#网易云音乐 #${2}
	via @$botName " -F reply_markup="{\"inline_keyboard\":[[{\"text\":\"$(echo "${7}" | sed 's/["\]/\\&/g')\",\"url\": \"https://music.163.com/song/${1}/\"}],[{\"text\":\"Send me to...\",\"switch_inline_query\": \"music.163.com/song/${1}/\"}]]}"
}

# sendMusicFromID id ext name artist duration album songInfo chatID fileID
function sendMusicFromID() {
    curl -s -X POST "${tgAPI}/bot${BOT_TOKEN}/sendChatAction" -d "chat_id=$8&action=upload_audio" >/dev/null 2>&1
    curl ${tgAPI}/bot"${BOT_TOKEN}"/sendAudio -s -X POST -F chat_id="$8" -F audio="$9" -F title="${3}" -F performer="${4}" -F duration="${5}" -F thumb="@${1}.jpg" -F parse_mode="Markdown" -F caption="「$(echo "${3}" | sed 's/[_*`[\]/\\&/g')」 - $(echo "${4}" | sed 's/[_*`[\]/\\&/g')
	专辑: $(echo "${6}" | sed 's/[_*`[\]/\\&/g')
	#网易云音乐 #${2}
	via @$botName " -F reply_markup="{\"inline_keyboard\":[[{\"text\":\"$(echo "${7}" | sed 's/["\]/\\&/g')\",\"url\": \"https://music.163.com/song/${1}/\"}],[{\"text\":\"Send me to...\",\"switch_inline_query\": \"music.163.com/song/${1}/\"}]]}"
}

# processMusic musicID chatID
function processMusic() {
    local i musicData musicName musicUrlData musicUrl musicExt musicSize musicSizeMB musicAlbum musicPicUrl musicArtistLen musicArtists musicInfo msgID musicDuration musicSendingData musicFileID
    musicData=$(getSongDetail "$1")
    musicName=$(echo "$musicData" | jq -r .songs[0].name)
    if [ "$musicName" = null ]; then
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
    musicInfo=$(echo -n "${musicName} - ${musicArtists}" | tr -d "\n" | tr -d '[:cntrl:]')
    if [ ! -f "./cache/${1}.json" ] || [ ! -f "./cache/${1}.txt" ]; then
        if [ ! -d "./cache" ]; then mkdir "./cache"; fi
        echo "{\"name\":${musicName},\"album\":${musicAlbum},\"artist\":\"${musicArtists}\",\"ext\":\"${musicExt}\",\"size\":\"${musicSize}\"}" >"./cache/${id}.json"
        if [ -f ./cache/"${1}" ]; then
            sendTextMessage "$2" "${musicName}%0A专辑:+${musicAlbum}%0A${musicExt}  ${musicSizeMB}MB%0A正在下载中，请稍后再试。" >/dev/null 2>&1
            return 1
        fi
        touch ./cache/"${1}"
        msgID=$(sendTextMessage "$2" "${musicName}%0A专辑:+${musicAlbum}%0A${musicExt}  ${musicSizeMB}MB%0A下载中..." | jq .result.message_id)
        curl -s -X GET -H "User-Agent:NeteaseMusic/7.3.28.1604408871(7003028);Dalvik/2.1.0 (Linux; U; Android 9; MIX 2 MIUI/V12.0.1.0.PDECNXM)" -H 'X-Real-IP:175.167.152.57' -H "Referer:http://music.163.com/api/" -H "Range:bytes=0-${musicSize}" -H "Host:$(echo "${musicUrl%%.*}" | sed 's:\(.*\)/::').music.126.net" -H "Connection:Keep-Alive" "$musicUrl" -o ./cache/"${1}.${musicExt}" >/dev/null 2>&1
        if [ "$(ls -l ./cache/"${1}.${musicExt}" | awk '{print $5}')" -lt 800 ]; then
            sendTextMessage "$2" "${musicName}%%0A专辑:++${musicAlbum}%0A${musicExt}  ${musicSizeMB}MB%0A下载失败" >/dev/null 2>&1
            rm ./cache/"${1}.${musicExt}"
            return 1
        fi
        musicDuration=$(soxi -D ./cache/"${1}.${musicExt}")
        curl "$musicPicUrl" -o ./cache/"${1}"_0.jpg >/dev/null 2>&1
        ffmpeg -i ./cache/"${1}"_0.jpg -vf "scale=1024:-1" ./cache/"${1}".jpg >/dev/null 2>&1
        if [ -f ./SongInfoAdder ]; then
            ./SongInfoAdder -i "cache/${1}.${musicExt}"
        fi
        editMessage "$2" "$msgID" "$musicName%0A专辑: ${musicAlbum}%0A${musicExt}++${musicSizeMB}MB%0A下载完成，发送中..." >/dev/null 2>&1
        cd cache || return 1
        musicSendingData=$(sendMusicFromFile "$1" "$musicExt" "$musicName" "$musicArtists" "$musicDuration" "$musicAlbum" "$musicInfo" "$2")
        musicFileID=$(echo "$musicSendingData" | jq -r .result.audio.file_id)
        rm ./"${1}"_0.jpg ./"${1}" ./"${1}"."${musicExt}"
        if [ "$musicFileID" != 'null' ]; then
            echo -n "$musicFileID" >"${1}.txt"
        else
            editMessage "$2" "$msgID" "${musicName}%0A专辑:  ${musicAlbum}%0A${musicExt}  ${musicSizeMB}MB%0A发送失败" >/dev/null 2>&1
            return 1
        fi
        sleep 2
        deleteMessage "$2" "$msgID" >/dev/null 2>&1
        return 0
    else
        msgID=$(sendTextMessage "$2" "${musicName}%0A专辑:+${musicAlbum}%0A${musicExt}  ${musicSizeMB}MB%0A命中缓存，发送中..." | jq .result.message_id)
        musicFileID=$(cat "./cache/${1}.txt")
        cd cache || return 1
        sendMusicFromID "$1" "$musicExt" "$musicName" "$musicArtists" "$musicDuration" "$musicAlbum" "$musicInfo" "$2" "$musicFileID" >/dev/null 2>&1
        sleep 2
        deleteMessage "$2" "$msgID" >/dev/null 2>&1
        return 0
    fi
}

function processSearch() {
    local a i searchResult msgID searchResultNum musicArtistLen musicArtists musicName searchReport inlineMarkup inlineKeyboard
    searchResult=$(getSearchResult "${1}" | jq .result.songs)
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
            inlineMarkup="${inlineMarkup}{\"text\":\"$((i + 1))\",\"callback_data\":\"musicid $(echo "$searchResult" | jq -r .[$i].id)\"},"
        else
            searchReport="${searchReport}$((i + 1)).「${musicName}」- ${musicArtists}"
            inlineMarkup="${inlineMarkup}{\"text\":\"$((i + 1))\",\"callback_data\":\"musicid $(echo "$searchResult" | jq -r .[$i].id)\"}"
        fi
    done
    inlineKeyboard="{\"inline_keyboard\":[[${inlineMarkup}]]}"
    editMessage "$2" "${msgID}" "搜索结果:%0A${searchReport}" "${inlineKeyboard}"
}

for (( ; ; )); do
    updateData=$(updateMessage "$updateID")
    while [ "$(echo "$updateData" | jq -r .result[0].update_id)" == null ]; do
        updateData=$(curl -s ${tgAPI}/bot"$BOT_TOKEN"/getUpdates)
        sleep 5
    done
    messageNumber=$(($(echo "$updateData" | jq '.result|length') - 1))
    for ((i = 0; i <= messageNumber; i++)); do
        if [ "$updateID" ] && [ "$(echo "$updateData" | jq -r .result[$i].update_id)" -gt "$updateID" ]; then
            message=$(echo "$updateData" | jq -r .result[$i].message.text)
            callback=$(echo $updateData | jq -r .result[$i].callback_query)
            chatID=$(echo "$updateData" | jq -r .result[$i].message.chat.id)
            if [[ "$message" =~ /musicid ]] || [[ "$message" =~ music.163.com ]] || [[ "$message" =~ /netease ]]; then
                if [[ "$message" =~ music.163.com ]]; then
                    id=$(echo "$message" | tr -d "\n" | sed 's:\(.*\)song?id=::' | sed 's:\(.*\)song/::' | sed 's:/\(.*\)::' | sed 's:&\(.*\)::' | sed 's:?user\(.*\)::')
                else
                    id=$(echo "$message" | sed 's:/musicid::' | sed 's:/netease::' | sed 's:@Music163bot::' | sed s/[[:space:]]//g)
                fi
                if echo "$id" | grep -q '^[Z0-9 ]\+$'; then
                    processMusic "$id" "$chatID" &
                fi
            fi
            if [[ "$message" =~ '/search' ]]; then
                processSearch "$(echo "$message" | sed 's:/search::' | sed 's:@Music163bot::' | sed s/[[:space:]]// | sed 's/["\]/\\&/g')" "$chatID" &
            fi
            if [ "$callback" != "null" ]; then
                callbackMessage=$(echo "$callback" | jq -r .data)
                callbackChatID=$(echo "$callback" | jq -r .message.chat.id)
                callbackQueryID=$(echo "$callback" | jq -r .id)
                id=$(echo $callbackMessage | sed 's:/musicid::' | sed s/[[:space:]]//g)
                if echo "$id" | grep -q '^[Z0-9 ]\+$'; then
                    processMusic "$id" "$callbackChatID" &
                fi
                answerCallbackQuery "$callbackQueryID" "t.me/${botName}?start=${callbackMessage}" &
            fi
        fi
    done
    updateID=$(echo "$updateData" | jq -r .result["$(($(echo "$updateData" | jq '.result|length') - 1))"].update_id)
    sleep 1
done
