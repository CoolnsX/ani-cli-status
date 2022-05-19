#!/bin/sh

gen_img() {
    convert -fill white -background "$4" -pointsize 72 -font "$font" label:"\ $2 $3 " images/$1.jpg
    printf "\n\033[1;32m$1 image generated!!"
}

#intializing
base_url="https://animixplay.to"
font="font/iosevka-regular.ttf"
agent="Mozilla/5.0 (Linux; Android 11; moto g(9) power) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.41 Mobile Safari/537.36"
[ -z "$*" ] && url=$(curl -s "$base_url" -A "$agent" | sed -nE 's_.*href="(/v1.*)" title.*_\1_p' | shuf | head -1) || url=$*
[ -z "$url" ] && exit 0 || printf "\033[1;35mSelected $url\n\033[1;36mLoading Episode.."
sed -i -E "s_Episode Name: (.*)_Episode Name: $(printf "$url" | cut -d"/" -f3- | tr "[:punct:]" " ")_g ; s_${base_url}(.*)_${base_url}${url}_g" README.md &
data=$(curl -A "$agent" -s "${base_url}${url}" | sed -nE "s/.*malid = '(.*)';/\1/p ; s_.*epslistplace.*>(.*)</div>_\1_p")

ext_id=$(printf "%s" "$data" | tail -1)
data=$(printf "%s" "$data" | head -1)
ep=$(printf "%s" "$data" | jq -r '."eptotal"') && ep=$((ep - 1))
id=$(printf "%s" "$data" | jq -r ".\"$ep\"" | sed -nE 's/.*id=(.*)&title.*/\1/p')
resp="$(curl -A "$agent" -s "https://goload.pro/streaming.php?id=$id" | sed -nE 's/.*class="container-(.*)">/\1/p ; s/.*class="wrapper container-(.*)">/\1/p ; s/.*class=".*videocontent-(.*)">/\1/p ; s/.*data-value="(.*)">.*/\1/p ; s/.*data-status="1".*data-video="(.*)">.*/\1/p')"
links=$(printf "%s" "$resp" | sed -n '5,$ p')
[ -z "$links" ] || printf "\33[2K\r\033[1;32m link providers (GOGO)>>\033[0m\n%s\n" "$links"

#scraping goload direct links
[ -z "$id" ] && gen_img "gogoplay" "! No" "embed link" "#a26b03" || printf "\n\033[1;34mFetching goload links < $id"
secret_key=$(printf "%s" "$resp" | sed -n '2p' | tr -d "\n" | od -A n -t x1 | tr -d " |\n")
iv=$(printf "%s" "$resp" | sed -n '3p' | tr -d "\n" | od -A n -t x1 | tr -d " |\n")
second_key=$(printf "%s" "$resp" | sed -n '4p' | tr -d "\n" | od -A n -t x1 | tr -d " |\n")
token=$(printf "%s" "$resp" | head -1 | base64 -d | openssl enc -d -aes256 -K "$secret_key" -iv "$iv" | sed -nE 's/.*&(token.*)/\1/p')
ajax=$(printf '%s' "$id" | openssl enc -e -aes256 -K "$secret_key" -iv "$iv" -a)
[ -z "$id" ] || go_video=$(curl -s -H "X-Requested-With:XMLHttpRequest" "https://goload.pro/encrypt-ajax.php?id=${ajax}&alias=${id}&${token}" | sed -e 's/{"data":"//' -e 's/"}/\n/' -e 's/\\//g' | base64 -d | openssl enc -d -aes256 -K "$second_key" -iv "$iv" | sed -e 's/\].*/\]/' -e 's/\\//g' | grep -Eo 'https:\/\/[-a-zA-Z0-9@:%._\+~#=][a-zA-Z0-9][-a-zA-Z0-9@:%_\+.~#?&\/\/=]*')
[ -z "$id" ] || ([ -z "$go_video" ] && gen_img "gogoplay" "✗ No" "link returned" "darkred" || gen_img "gogoplay" "✓ $(printf "%s\n" "$go_video" | wc -l)" "link(s) returned" "darkgreen") &

#xstreamcdn(fembed) links
fb_id=$(printf "%s" "$links" | sed -n "s_.*fembed.*/v/__p")
[ -z "$fb_id" ] && gen_img "xstreamcdn" "! No" "embed link" "#a26b03" || printf "\n\033[1;34mFetching xstreamcdn links < $fb_id"
[ -z "$fb_id" ] || (fb_video=$(curl -s -X POST "https://fembed-hd.com/api/source/$fb_id" -H "x-requested-with:XMLHttpRequest" | sed -e 's/\\//g' -e 's/.*data"://' | tr "}" "\n" | sed -nE 's/.*file":"(.*)","label":"(.*)",.*type.*/\2 > \1/p') && [ -z "$fb_video" ] && gen_img "xstreamcdn" "✗ No" "link returned" "darkred" || gen_img "xstreamcdn" "✓ $(printf "%s\n" "$fb_video" | wc -l)" "links returned" "darkgreen") &

#doodstream link
dood_id=$(printf "%s" "$links" | sed -n "s_.*dood.*/e/__p")
[ -z "$dood_id" ] && gen_img "doodstream" "! No" "embed link" "#a26b03" || printf "\n\033[1;34mFetching doodstream links < $dood_id"
[ -z "$dood_id" ] || (dood_link=$(curl -A "$agent" -s "https://dood.ws/d/$dood_id" | sed -nE 's/<a href="(.*)" class="btn.*justify.*/\1/p') && [ -z "$dood_link" ] && gen_img "doodstream" "✗ No" "link returned" "darkred" || gen_img "doodstream" "✓ $(printf "%s\n" "$dood_link" | wc -l)" "link returned" "darkgreen") &

#mp4upload (gogo) link
mp4up_link=$(printf "%s" "$links" | grep "mp4upload")
[ -z "$mp4up_link" ] && gen_img "mp4upload" "! No" "embed link" "#a26b03" || printf "\n\033[1;34mFetching mp4upload links < $mp4up_link"
[ -z "$mp4up_link" ] || (mp4up_video=$(curl -A "$agent" -s "$mp4up_link" -H "DNT: 1" | sed -nE 's_.*embed\|(.*)\|.*blank.*\|(.*)\|(.*)\|(.*)\|(.*)\|src.*_https://\1.mp4upload.com:\5/d/\4/\3.\2_p') && [ -z "$mp4up_video" ] && gen_img "mp4upload" "✗ No" "link returned" "darkred" || gen_img "mp4upload" "✓ $(printf "%s\n" "$mp4up_link" | wc -l)" "link returned" "darkgreen") &

#fetching al stream links
al=$(curl -s -H "x-requested-with:XMLHttpRequest" -X POST "https://animixplay.to/api/search" -d "recomended=$ext_id" -A "$agent" | jq -r '.data[] | select(.type == "AL").items[0].url')
[ -z "$al" ] || al_data=$(curl -s "${base_url}${al}" -A "$agent" | sed -nE 's_.*epslistplace.*>(.*)</div>_\1_p')
[ -z "$al_data" ] || al_ep=$(printf "%s" "$al_data" | jq -r '."eptotal"') && al_ep=$((al_ep - 1))
[ -z "$al_ep" ] || al_links=$(printf "%s" "$al_data" | jq -r ".\"${al_ep}\"[]")
[ -z "$al_links" ] || printf "\n\n\033[1;32m link providers (AL)>>\033[0m\n%s\n" "$al_links"

#mp4upload (al) link
mp4up_al_link=$(printf "%s" "$al_links" | grep "mp4upload")
[ -z "$mp4up_al_link" ] && gen_img "mp4upload_al" "! No" "embed link" "#a26b03" || printf "\n\033[1;34mFetching mp4upload (al) links < $mp4up_al_link"
[ -z "$mp4up_al_link" ] || (mp4up_al_video=$(curl -A "$agent" -s "$mp4up_al_link" -H "DNT: 1" -L | sed -nE 's_.*embed\|(.*)\|.*blank.*\|(.*)\|(.*)\|(.*)\|(.*)\|src.*_https://\1.mp4upload.com:\5/d/\4/\3.\2_p') && [ -z "$mp4up_al_video" ]  && gen_img "mp4upload_al" "✗ No" "link returned" "darkred" || gen_img "mp4upload_al" "✓ $(printf "%s\n" "$mp4up_al_link" | wc -l)" "link returned" "darkgreen") &

#streamlare
lare_id=$(printf "%s" "$al_links" | sed -nE 's_.*streamlare.*/e/(.*)_\1_p')
[ -z "$lare_id" ] && gen_img "streamlare" "! No" "embed link" "#a26b03" || printf "\n\033[1;34mFetching streamlare links < $lare_id"
[ -z "$lare_id" ] || lare_token=$(curl -s -A "$agent" "https://streamlare.com/e/$lare_id" | sed -nE 's/.*csrf-token.*content="(.*)">/\1/p')
[ -z "$lare_id" ] || (lare_video=$(curl -s -A "$agent" -H "x-requested-with:XMLHttpRequest" -X POST "https://streamlare.com/api/video/download/get" -d "{\"id\":\"$lare_id\"}" -H "x-csrf-token:$lare_token" -H "content-type:application/json;charset=UTF-8" | tr -d '\\' | sed -nE 's/.*label":"([^"]*)",.*url":"([^"]*)".*/\1 >\2/p') && [ -z "$lare_video" ] && gen_img "streamlare" "✗ No" "link returned" "darkred" || gen_img "streamlare" "✓ $(printf "%s\n" "$lare_video" | wc -l)" "link returned" "darkgreen") &

#odnoklassniki (okru) links
ok_id=$(printf "%s" "$al_links" | sed -nE 's_.*ok.*videoembed/(.*)_\1_p')
[ -z "$ok_id" ] && gen_img "okru" "! No" "embed link" "#a26b03" || printf "\n\033[1;34mFetching odnoklassniki(okru) links < $ok_id"
[ -z "$ok_id" ] || (ok_video=$(curl -s "https://odnoklassniki.ru/videoembed/$ok_id" -A "$agent" | sed -nE 's_.*data-options="([^"]*)".*_\1_p' | sed -e 's/&quot;/"/g' -e 's/\u0026/\&/g' -e 's/amp;//g' | tr -d '\\' | sed -nE 's/.*videos":(.*),"metadataE.*/\1/p' | jq -r '.[].url') && [ -z "$ok_video" ] && gen_img "okru" "✗ No" "link returned" "darkred" || gen_img "okru" "✓ $(printf "%s\n" "$ok_video" | wc -l)" "links returned" "darkgreen") &

wait
