#!/bin/sh

gen_img() {
    convert -fill white -background "$4" -pointsize 72 -font "iosevka-regular.ttf" label:"\ $2 $3 " images/$1.jpg
    printf "$1 : $2 $3\n" >> results
    printf "\n\033[1;32m$1 image generated!!"
}

#intializing
printf "" > results
base_url="https://animixplay.to"
agent="Mozilla/5.0 (Linux; Android 11; moto g(9) power) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.41 Mobile Safari/537.36"
[ -z "$*" ] && url=$(curl -s "$base_url" -A "$agent" | sed -nE 's_.*href="(/v1.*)" title.*_\1_p' | shuf | head -1) || url=$*
[ -z "$url" ] && exit 0 || printf "\033[1;35mSelected $url\n\033[1;36mLoading Episode.."
sed -i -E "s_Episode Name: (.*)_Episode Name: $(printf "$url" | cut -d"/" -f3- | tr "[:punct:]" " ")_g ; s_${base_url}(.*)_${base_url}${url}_g" README.md &
data=$(curl -A "$agent" -s "${base_url}${url}" | sed -nE "s/.*malid = '(.*)';/\1/p ; s_.*epslistplace.*>(.*)</div>_\1_p")

ext_id=$(printf "%s" "$data" | tail -1 | tr -d "[:alpha:]|[:punct:]")
id=$(printf "%s" "$data" | head -1 | tr "," "\n" | sed '/extra/d' | sed -nE 's_".*":"(.*)".*_\1_p' | tail -1 | sed -nE 's/.*id=([^&]*).*/\1/p')
resp="$(curl -A "$agent" -sL "https://gogohd.net/streaming.php?id=$id" | sed -nE 's/.*class="container-(.*)">/\1/p ; s/.*class="wrapper container-(.*)">/\1/p ; s/.*class=".*videocontent-(.*)">/\1/p ; s/.*data-value="(.*)">.*/\1/p ; s/.*data-status="1".*data-video="(.*)">.*/\1/p')"
[ -z "$resp" ] || printf "\33[2K\r\033[1;32m link providers (GOGO)>>\033[0m\n%s\n" "$resp"

#scraping animixplay direct links
[ -z "$id" ] && gen_img "animixplay" "! No" "embed link" "#a26b03" || printf "\n\033[1;34mFetching animixplay links < $id"
[ -z "$id" ] || (ani_video="$(curl -s "https://animixplay.to/api/cW9$(printf "%sLTXs3GrU8we9O%s" "$id" "$(printf "$id" | base64)" | base64)" -A "uwu" -I | sed -nE 's_location: (.*)_\1_p' | cut -d"#" -f2 | base64 -d)" && [ -z "$ani_video" ] && gen_img "animixplay" "✗ No" "link returned" "darkred" || gen_img "animixplay" "✓ $(printf "%s\n" "$fb_video" | wc -l)" "link returned" "darkgreen")

#scraping goload direct links
[ -z "$id" ] && gen_img "gogoplay" "! No" "embed link" "#a26b03" || printf "\n\033[1;34mFetching goload links < $id"
secret_key=$(printf "%s" "$resp" | sed -n '2p' | tr -d "\n" | od -A n -t x1 | tr -d " |\n")
iv=$(printf "%s" "$resp" | sed -n '3p' | tr -d "\n" | od -A n -t x1 | tr -d " |\n")
second_key=$(printf "%s" "$resp" | sed -n '4p' | tr -d "\n" | od -A n -t x1 | tr -d " |\n")
token=$(printf "%s" "$resp" | head -1 | base64 -d | openssl enc -d -aes256 -K "$secret_key" -iv "$iv" | sed -nE 's/.*&(token.*)/\1/p')
ajax=$(printf '%s' "$id" | openssl enc -e -aes256 -K "$secret_key" -iv "$iv" -a)
[ -z "$id" ] || go_video=$(curl -sL -H "X-Requested-With:XMLHttpRequest" "https://gogohd.net/encrypt-ajax.php?id=${ajax}&alias=${id}&${token}" | sed -e 's/{"data":"//' -e 's/"}/\n/' -e 's/\\//g' | base64 -d | openssl enc -d -aes256 -K "$second_key" -iv "$iv" | sed -e 's/\].*/\]/' -e 's/\\//g' | grep -Eo 'https:\/\/[-a-zA-Z0-9@:%._\+~#=][a-zA-Z0-9][-a-zA-Z0-9@:%_\+.~#?&\/\/=]*')
[ -z "$id" ] || ([ -z "$go_video" ] && gen_img "gogoplay" "✗ No" "link returned" "darkred" || gen_img "gogoplay" "✓ $(printf "%s\n" "$go_video" | wc -l)" "link returned" "darkgreen")

#xstreamcdn(fembed) links
fb_id=$(printf "%s" "$resp" | sed -n "s_.*fembed.*/v/__p")
[ -z "$fb_id" ] && gen_img "xstreamcdn" "! No" "embed link" "#a26b03" || printf "\n\033[1;34mFetching xstreamcdn links < $fb_id"
[ -z "$fb_id" ] || (fb_video=$(curl -s -X POST "https://fembed-hd.com/api/source/$fb_id" -H "x-requested-with:XMLHttpRequest" | sed -e 's/\\//g' -e 's/.*data"://' | tr "}" "\n" | sed -nE 's/.*file":"(.*)","label":"(.*)",.*type.*/\2 > \1/p') && [ -z "$fb_video" ] && gen_img "xstreamcdn" "✗ No" "link returned" "darkred" || gen_img "xstreamcdn" "✓ $(printf "%s\n" "$fb_video" | wc -l)" "links returned" "darkgreen")

#doodstream link
dood_id=$(printf "%s" "$resp" | sed -n "s_.*dood.*/e/__p")
[ -z "$dood_id" ] && gen_img "doodstream" "! No" "embed link" "#a26b03" || printf "\n\033[1;34mFetching doodstream links < $dood_id"
[ -z "$dood_id" ] || (dood_link=$(curl --cipher AES256-SHA256 --tls-max 1.2 -A "$agent" -sL "https://dood.wf/d/$dood_id" | sed -nE 's_.*a href="(/download[^"]*)".*_\1_p') && [ -z "$dood_link" ] && gen_img "doodstream" "✗ No" "link returned" "darkred" || gen_img "doodstream" "✓ $(printf "%s\n" "$dood_link" | wc -l)" "link returned" "darkgreen") &

#mp4upload (gogo) link
mp4up_link=$(printf "%s" "$resp" | grep "mp4upload")
[ -z "$mp4up_link" ] && gen_img "mp4upload" "! No" "embed link" "#a26b03" || printf "\n\033[1;34mFetching mp4upload links < $mp4up_link"
[ -z "$mp4up_link" ] || (mp4up_video=$(curl -A "$agent" -s "$mp4up_link" -H "DNT: 1" | sed -nE 's_.*embed\|(.*)\|.*blank.*\|(.*)\|(.*)\|(.*)\|(.*)\|src.*_https://\1.mp4upload.com:\5/d/\4/\3.\2_p') && [ -z "$mp4up_video" ] && gen_img "mp4upload" "✗ No" "link returned" "darkred" || gen_img "mp4upload" "✓ $(printf "%s\n" "$mp4up_link" | wc -l)" "link returned" "darkgreen") &

wait

#fetching al stream links
al=$(curl -s -H "x-requested-with:XMLHttpRequest" -X POST "https://animixplay.to/api/search" -d "recomended=$ext_id" -A "$agent" | sed -nE 's_.*"AL","items":\[(.*)\]\},.*_\1_p' | tr '{|}' '\n' | sed -nE 's_"url":"(.*)",.*title.*_\1_p' | sed 's/-dub//' | head -1)
[ -z "$al" ] || al_data=$(curl -s "${base_url}${al}" -A "$agent" | sed -nE 's_.*epslistplace.*>(.*)</div>_\1_p')
[ -z "$al_data" ] || al_links=$(printf "%s" "$al_data" | sed -e 's_:\[_\n_g' -e 's_:"_\n"_g' | sed -e 's/].*//g' -e '1,2d' | tail -1 | tr -d '"' | tr "," "\n")
[ -z "$al_links" ] || printf "\n\n\033[1;32m link providers (AL)>>\033[0m\n%s\n" "$al_links"

#mp4upload (al) link
mp4up_al_link=$(printf "%s" "$al_links" | grep "mp4upload")
[ -z "$mp4up_al_link" ] && gen_img "mp4upload_al" "! No" "embed link" "#a26b03" || printf "\n\033[1;34mFetching mp4upload (al) links < $mp4up_al_link"
[ -z "$mp4up_al_link" ] || (mp4up_al_video=$(curl -A "$agent" -s "$mp4up_al_link" -H "DNT: 1" -L | sed -nE 's_.*embed\|(.*)\|.*blank.*\|(.*)\|(.*)\|(.*)\|(.*)\|src.*_https://\1.mp4upload.com:\5/d/\4/\3.\2_p') && [ -z "$mp4up_al_video" ]  && gen_img "mp4upload_al" "✗ No" "link returned" "darkred" || gen_img "mp4upload_al" "✓ $(printf "%s\n" "$mp4up_al_link" | wc -l)" "link returned" "darkgreen") &

#streamlare
lare_id=$(printf "%s" "$al_links" | sed -nE 's_.*streamlare.*/e/(.*)_\1_p')
[ -z "$lare_id" ] && gen_img "streamlare" "! No" "embed link" "#a26b03" || printf "\n\033[1;34mFetching streamlare links < $lare_id"
[ -z "$lare_id" ] || lare_token=$(curl -s -A "$agent" "https://streamlare.com/e/$lare_id" -L | sed -nE 's/.*csrf-token.*content="(.*)">/\1/p')
[ -z "$lare_id" ] || (lare_video=$(curl -s -A "$agent" -H "x-requested-with:XMLHttpRequest" -X POST "https://streamlare.com/api/video/download/get" -d "{\"id\":\"$lare_id\"}" -H "x-csrf-token:$lare_token" -H "content-type:application/json;charset=UTF-8" | tr -d '\\' | sed -nE 's/.*label":"([^"]*)",.*url":"([^"]*)".*/\1 >\2/p') && [ -z "$lare_video" ] && gen_img "streamlare" "✗ No" "link returned" "darkred" || gen_img "streamlare" "✓ $(printf "%s\n" "$lare_video" | wc -l)" "link returned" "darkgreen") &

#odnoklassniki (okru) links
ok_id=$(printf "%s" "$al_links" | sed -nE 's_.*ok.*videoembed/(.*)_\1_p')
[ -z "$ok_id" ] && gen_img "okru" "! No" "embed link" "#a26b03" || printf "\n\033[1;34mFetching odnoklassniki(okru) links < $ok_id"
[ -z "$ok_id" ] || (ok_video=$(curl -s "https://odnoklassniki.ru/videoembed/$ok_id" -A "$agent" | sed -nE 's_.*data-options="([^"]*)".*_\1_p' | sed -e 's/&quot;/"/g' -e 's/\u0026/\&/g' -e 's/amp;//g' | tr -d '\\' | sed -nE 's/.*videos":(.*),"metadataE.*/\1/p' | tr '{|}' '\n' | sed -nE 's/"name":"mobile","url":"(.*)",.*/144p >\1/p ; s/"name":"lowest","url":"(.*)",.*/240p >\1/p ; s/"name":"low","url":"(.*)",.*/360p >\1/p ; s/"name":"sd","url":"(.*)",.*/480p >\1/p ; s/"name":"hd","url":"(.*)",.*/720p >\1/p ; s/"name":"full","url":"(.*)",.*/1080p >\1/p') && [ -z "$ok_video" ] && gen_img "okru" "✗ No" "link returned" "darkred" || gen_img "okru" "✓ $(printf "%s\n" "$ok_video" | wc -l)" "links returned" "darkgreen") &

wait

#scraping hentaimama
hent_video=$(curl -s https://hentaimama.io/wp-admin/admin-ajax.php -d "action=get_player_contents&a=$(curl -s "https://hentaimama.io" | sed -nE 's_.*id="post-hot-([^"]*)".*_\1_p' | shuf | head -1)" -H X-Requested-With:XMLHttpRequest | tr -d '\\' | tr ',' '\n' | sed -nE 's/.*src="(.*)" width.*/\1/p') && [ -z "$hent_video" ] && gen_img "hentaimama" "✗ No" "link returned" "darkred" || gen_img "hentaimama" "✓ $(printf "%s\n" "$hent_video" | wc -l)" "links returned" "darkgreen" &

#scraping theflix
flix_video=$(curl -s "https://theflix.to:5679/movies/videos/$(curl -s "https://theflix.to" | sed -nE 's|.*id="__NEXT_DATA__" type="application/json">(.*)</script><script nomodule="".*|\1|p' | jq -r '.props.pageProps.moviesListTrending.docs[].videos[]' | shuf | head -1)/request-access?contentUsageType=Viewing" -b "theflix.ipiid=$(curl -X POST -sc - -o /dev/null 'https://theflix.to:5679/authorization/session/continue?contentUsageType=Viewing' -A "$agent" | sed -n 's/.*ipiid\t//p')" | sed -nE 's/.*url\":"([^"]*)",.*id.*/\1/p') && [ -z "$flix_video" ] && gen_img "theflix" "✗ No" "link returned" "darkred" || gen_img "theflix" "✓ $(printf "%s\n" "$flix_video" | wc -l)" "link returned" "darkgreen" &

wait
sed -i '4,$d' results
