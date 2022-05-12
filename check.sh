#!/bin/sh

gen_img() {
    [ "$2" -eq 0 ] && convert -fill white -background darkred -pointsize 72 -font "$font" label:"\ ✗ No link returned " images/$1.jpg || convert -fill white -background darkgreen -pointsize 72 -font "$font" label:"\ ✓ $2 link(s) returned " images/$1.jpg
    printf "\n\033[1;32m$1 image geneated"
}

#intializing
base_url="https://animixplay.to"
font="font/iosevka-regular.ttf"
agent="Mozilla/5.0 (Linux; Android 11; moto g(9) power) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.41 Mobile Safari/537.36"
url=$(curl -s "$base_url" -A "$agent" | sed -nE 's_.*href="(/v1.*)" title.*_\1_p' | tail -15 | shuf | sed -n '5p')
[ -z "$url" ] && exit 0 || printf "\033[1;35mSelected $url\n\033[1;36mLoading Episode.."
data=$(curl -A "$agent" -s "${base_url}${url}")

ext_id=$(printf "%s" "$data" | sed -nE "s/.*malid = '(.*)';/\1/p")
data=$(printf "%s" "$data" | sed -nE 's_.*epslistplace.*>(.*)</div>_\1_p')
ep=$(printf "%s" "$data" | jq -r '."eptotal"') && ep=$((ep - 1))
refr=$(printf "%s" "$data" | jq -r ".\"$ep\"")
resp="$(curl -s "https:$refr")"
links=$(printf "%s" "$resp" | sed -nE 's/.*data-status="1".*data-video="(.*)">.*/\1/p')

[ -z "$links" ] || printf "\33[2K\r\033[1;32m link providers (GOGO)>>\033[0m\n%s\n" "$links"

#scraping goload direct links
id=$(printf "%s" "$refr" | sed -nE 's/.*id=(.*)&title.*/\1/p')
printf "\n\033[1;34mFetching goload links < $id"
secret_key=$(printf "%s" "$resp" | sed -nE 's/.*class="container-(.*)">/\1/p' | tr -d "\n" | od -A n -t x1 | tr -d " |\n")
iv=$(printf "%s" "$resp" | sed -nE 's/.*class="wrapper container-(.*)">/\1/p' | tr -d "\n" | od -A n -t x1 | tr -d " |\n")
second_key=$(printf "%s" "$resp" | sed -nE 's/.*class=".*videocontent-(.*)">/\1/p' | tr -d "\n" | od -A n -t x1 | tr -d " |\n")
token=$(printf "%s" "$resp" | sed -nE 's/.*data-value="(.*)">.*/\1/p' | base64 -d | openssl enc -d -aes256 -K "$secret_key" -iv "$iv" | sed -nE 's/.*&(token.*)/\1/p')
ajax=$(printf '%s' "$id" |openssl enc -e -aes256 -K "$secret_key" -iv "$iv" -a)
go_video=$(curl -s -H "X-Requested-With:XMLHttpRequest" "https://goload.pro/encrypt-ajax.php?id=${ajax}&alias=${id}&${token}" | sed -e 's/{"data":"//' -e 's/"}/\n/' -e 's/\\//g' | base64 -d | openssl enc -d -aes256 -K "$second_key" -iv "$iv" | sed -e 's/\].*/\]/' -e 's/\\//g' | grep -Eo 'https:\/\/[-a-zA-Z0-9@:%._\+~#=][a-zA-Z0-9][-a-zA-Z0-9@:%_\+.~#?&\/\/=]*') && [ -z "$go_video" ] && gen_img "gogoplay" "0" || gen_img "gogoplay" "$(printf "%s\n" "$go_video" | wc -l)" &

#xstreamcdn(fembed) links
fb_id=$(printf "%s" "$links" | sed -n "s_.*fembed.*/v/__p")
printf "\n\033[1;34mFetching xstreamcdn links < $fb_id"
[ -z "$fb_id" ] || fb_video=$(curl -s -X POST "https://fembed-hd.com/api/source/$fb_id" -H "x-requested-with:XMLHttpRequest" | sed -e 's/\\//g' -e 's/.*data"://' | tr "}" "\n" | sed -nE 's/.*file":"(.*)","label":"(.*)",.*type.*/\2 > \1/p') && [ -z "$fb_video" ] && gen_img "xstreamcdn" "0" || gen_img "xstreamcdn" "$(printf "%s\n" "$fb_video" | wc -l)" &

#doodstream link
dood_id=$(printf "%s" "$links" | sed -n "s_.*dood.*/e/__p")
[ -z "$dood_id" ] || printf "\n\033[1;34mFetching doodstream links < $dood_id"
dood_link=$(curl -A "$agent" -s "https://dood.ws/d/$dood_id" | sed -nE 's/<a href="(.*)" class="btn.*justify.*/\1/p') && [ -z "$dood_link" ] && gen_img "doodstream" "0" || gen_img "doodstream" "$(printf "%s\n" "$dood_link" | wc -l)" &

#mp4upload link
mp4up_link=$(printf "%s" "$links" | grep "mp4upload")
[ -z "$mp4up_link" ] || printf "\n\033[1;34mFetching mp4upload links < $mp4up_link"
mp4up_video=$(curl -A "$agent" -s "$mp4up_link" -H "DNT: 1" -e "https:$refr" | sed -nE 's_.*embed\|(.*)\|.*blank.*\|(.*)\|(.*)\|(.*)\|(.*)\|src.*_https://\1.mp4upload.com:\5/d/\4/\3.\2_p') && [ -z "$mp4up_video" ] && gen_img "mp4upload" "0" || gen_img "mp4upload" "$(printf "%s\n" "$mp4up_video" | wc -l)" &

#ping to get rush, al link
tmp=$(curl -s -H "x-requested-with:XMLHttpRequest" -X POST https://animixplay.to/api/search -d "recomended=$ext_id" -A "$agent")

#fetching rush stream links
rush=$(printf "%s" "$tmp" | jq -r '.data[] | select(.type == "RUSH").items[].url' | head -1)
[ -z "$rush" ] || rush_data=$(curl -s "${base_url}${rush}" -A "$agent" | sed -nE 's_.*epslistplace.*>(.*)</div>_\1_p')
[ -z "$rush_data" ] || rush_ep=$(printf "%s" "$rush_data" | jq -r '."eptotal"') && rush_ep=$((rush_ep - 1))
[ -z "$rush_ep" ] || rush_links=$(printf "%s" "$rush_data" | jq -r ".\"${rush_ep}\"[].vid")
[ -z "$rush_links" ] || printf "\n\033[1;32m link providers (RUSH)>>\033[0m\n%s\n" "$rush_links"

#mixdrop link
mix_id=$(printf "%s" "$rush_links" | sed -nE 's_.*mixdrop.*/e/(.*)_\1_p')
[ -z "$mix_id" ] || printf "\n\033[1;34mFetching mixdrop links < $mix_id"
mix_data=$(curl -s -A "$agent" "https://mixdrop.bz/e/$mix_id") 
mix_video=$(printf "%s" "$mix_data" | sed -nE "s_.*\|MDCore\|(.*)\|(.*)\|(.*)\|(.*)\|(.*)\|(.*)\|referrer\|(.*)\|thumbs.*\|v\|\_t\|(.*)\|(.*)\|vfile.*_https://\1-\2.\5.\6/v/\3.\4?\1=\7\&e=\8\&\_t=\9_p") && [ -z "$mix_video" ] && mix_video=$(printf "%s" "$mix_data" | sed -nE "s_.*'\|MDCore\|(.*)\|(.*)\|(.*)\|(.*)\|(.*)\|referrer\|(.*)\|thumbs.*\|\_t\|(.*)\|(.*)\|vfile.*_https://a-\1.\3.\5/v/\2.\4?s=\6\&e=\7\&\_t=\8_p") && [ -z "$mix_video" ] && gen_img "mixdrop" "0" || gen_img "mixdrop" "$(printf "%s\n" "$mix_video" | wc -l)"

#fetching al stream links
al=$(printf "%s" "$tmp" | jq -r '.data[] | select(.type == "AL").items[].url' | head -1)
[ -z "$al" ] || al_data=$(curl -s "${base_url}${al}" -A "$agent" | sed -nE 's_.*epslistplace.*>(.*)</div>_\1_p')
[ -z "$al_data" ] || al_ep=$(printf "%s" "$al_data" | jq -r '."eptotal"') && al_ep=$((al_ep - 1))
[ -z "$al_ep" ] || al_links=$(printf "%s" "$al_data" | jq -r ".\"${al_ep}\"[]")
[ -z "$al_links" ] || printf "\n\033[1;32m link providers (AL)>>\033[0m\n%s\n" "$al_links"

#streamlare
lare_id=$(printf "%s" "$al_links" | sed -nE 's_.*streamlare.*/e/(.*)_\1_p')
[ -z "$lare_id" ] || printf "\n\033[1;34mFetching streamlare links < $lare_id"
lare_token=$(curl -s -A "$agent" "https://streamlare.com/e/$lare_id" | sed -nE 's/.*csrf-token.*content="(.*)">/\1/p')
lare_video=$(curl -s -A "$agent" -H "x-requested-with:XMLHttpRequest" -X POST "https://streamlare.com/api/video/download/get" -d "{\"id\":\"$lare_id\"}" -H "x-csrf-token:$lare_token" -H "content-type:application/json;charset=UTF-8" | tr -d '\\' | sed -nE 's/.*label":"([^"]*)",.*url":"([^"]*)".*/\1 >\2/p') && [ -z "$lare_video" ] && gen_img "streamlare" "0" || gen_img "streamlare" "$(printf "%s\n" "$lare_video" | wc -l)"

#odnoklassniki (okru) links
ok_id=$(printf "%s" "$al_links" | sed -nE 's_.*ok.*videoembed/(.*)_\1_p')
[ -z "$ok_id" ] || printf "\n\033[1;34mFetching okru links < $ok_id"
ok_video=$(curl -s "https://odnoklassniki.ru/videoembed/$ok_id" -A "$agent" | sed -nE 's_.*data-options="([^"]*)".*_\1_p' | sed -e 's/&quot;/"/g' -e 's/\u0026/\&/g' -e 's/amp;//g' | tr -d '\\' | sed -nE 's/.*videos":(.*),"metadataE.*/\1/p' | jq -r '.[].url') && [ -z "$ok_video" ] && gen_img "okru" "0" || gen_img "okru" "$(printf "%s\n" "$ok_video" | wc -l)"

wait
