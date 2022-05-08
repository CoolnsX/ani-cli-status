#!/bin/sh

gen_img() {
    [ "$2" -eq 0 ] && convert -fill white -background darkred -pointsize 72 -font "$font" label:"\ ✗ No link returned " images/$1.jpg || convert -fill white -background darkgreen -pointsize 72 -font "$font" label:"\ ✓ $2 link(s) returned " images/$1.jpg
    printf "\n\033[1;32m$1 image geneated\n"
}

#intializing
font="font/iosevka-regular.ttf"
agent="Mozilla/5.0 (Linux; Android 11; moto g(9) power) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.41 Mobile Safari/537.36"
refr=$(curl -s "https://goload.pro/videos/boruto-naruto-next-generations-episode-200" | sed -nE 's/.*iframe src="(.*)" al.*/\1/p')
resp="$(curl -s "https:$refr")"
links=$(printf "%s" "$resp" | sed -nE 's/.*data-status="1".*data-video="(.*)">.*/\1/p')
printf "\33[2K\r\033[1;32m link providers>>\033[0m\n$links\n"

#scraping goload direct links
printf "\n\033[1;34mFetching goload links"
id=$(printf "%s" "$refr" | sed -nE 's/.*id=(.*)&title.*/\1/p')
secret_key=$(printf "%s" "$resp" | sed -nE 's/.*class="container-(.*)">/\1/p' | tr -d "\n" | od -A n -t x1 | tr -d " |\n")
iv=$(printf "%s" "$resp" | sed -nE 's/.*class="wrapper container-(.*)">/\1/p' | tr -d "\n" | od -A n -t x1 | tr -d " |\n")
second_key=$(printf "%s" "$resp" | sed -nE 's/.*class=".*videocontent-(.*)">/\1/p' | tr -d "\n" | od -A n -t x1 | tr -d " |\n")
token=$(printf "%s" "$resp" | sed -nE 's/.*data-value="(.*)">.*/\1/p' | base64 -d | openssl enc -d -aes256 -K "$secret_key" -iv "$iv" | sed -nE 's/.*&(token.*)/\1/p')
ajax=$(printf '%s' "$id" |openssl enc -e -aes256 -K "$secret_key" -iv "$iv" -a)
go_video=$(curl -s -H "X-Requested-With:XMLHttpRequest" "https://goload.pro/encrypt-ajax.php?id=${ajax}&alias=${id}&${token}" | sed -e 's/{"data":"//' -e 's/"}/\n/' -e 's/\\//g' | base64 -d | openssl enc -d -aes256 -K "$second_key" -iv "$iv" | sed -e 's/\].*/\]/' -e 's/\\//g' | grep -Eo 'https:\/\/[-a-zA-Z0-9@:%._\+~#=][a-zA-Z0-9][-a-zA-Z0-9@:%_\+.~#?&\/\/=]*') && [ -z "$go_video" ] && gen_img "gogoplay" "0" || gen_img "gogoplay" "$(printf "%s\n" "$go_video" | wc -l)" &

#xstreamcdn(fembed) links
printf "\n\033[1;34mFetching xstreamcdn links"
fb_id=$(printf "$links" | sed -n "s_.*fembed.*/v/__p")
fb_video=$(curl -s -X POST "https://fembed-hd.com/api/source/$fb_id" -H "x-requested-with:XMLHttpRequest" | sed -e 's/\\//g' -e 's/.*data"://' | tr "}" "\n" | sed -nE 's/.*file":"(.*)","label":"(.*)",.*type.*/\2 > \1/p') && [ -z "$fb_video" ] && gen_img "xstreamcdn" "0" || gen_img "xstreamcdn" "$(printf "%s\n" "$fb_video" | wc -l)" &

#doodstream link
printf "\n\033[1;34mFetching doodstream links"
dood_id=$(printf "$links" | sed -n "s_.*dood.*/e/__p")
dood_link=$(curl -A "$agent" -s "https://dood.ws/d/$dood_id" | sed -nE 's/<a href="(.*)" class="btn.*justify.*/\1/p') && sleep .5 && dood_video=$(curl -A "$agent" -s "https://dood.ws${dood_link}" | sed -nE "s/.*window.open.*'(.*)',.*/\1/p") && [ -z "$dood_video" ] && gen_img "doodstream" "0" || gen_img "doodstream" "$(printf "%s\n" "$dood_video" | wc -l)" &

#mp4upload link
printf "\n\033[1;34mFetching mp4upload links"
mp4up_link=$(printf "$links" | grep "mp4upload")
mp4up_video=$(curl -A "$agent" -s "$mp4up_link" -H "DNT: 1" | sed -nE 's_.*embed\|(.*)\|.*blank.*\|(.*)\|(.*)\|(.*)\|(.*)\|src.*_https://\1.mp4upload.com:\5/d/\4/\3.\2_p') && [ -z "$mp4up_video" ] && gen_img "mp4upload" "0" || gen_img "mp4upload" "$(printf "%s\n" "$mp4up_video" | wc -l)" &
wait
