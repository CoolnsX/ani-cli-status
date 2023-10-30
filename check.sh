#!/bin/sh

set -x

gen_img() {
        convert -fill white -background "$4" -pointsize 72 -font "iosevka-regular.ttf" label:"\ $2 $3 " "images/$1.jpg"
        printf "%s : %s %s\n" "$1" "$2" "$3" >>results
        printf "\n\033[1;32m%s image generated!!" "$1"
        #analytics
        if [ -n "$5" ]; then
                prev=$(sed -nE "s/$1\t(.*)/\1/p" data)
                prev=$((prev + 1))
                sed -i -E "s_${1}(.*)_${1}\t${prev}_g" data
        fi
}

gen_analytics() {
LOGFILE=./data
OUTFILE=./analytics.png
gnuplot <<EOF
set lmargin at screen 0.20
set rmargin at screen 0.85
set bmargin at screen 0.30
set tmargin at screen 0.85
set datafile separator "\t"
set title "Provider Analytics" textcolor rgb"white"
set ylabel "Probability" textcolor rgb"white"
set yrange [0:$total]
set xlabel "Providers" textcolor rgb"white"
set key textcolor rgb "white"
set xtics rotate by 45 right
set xtics textcolor rgb "white"
set ytics textcolor rgb "white"
set style fill solid 1.00 noborder
set boxwidth 2 relative
set border lw 2 lc rgb "white"
set terminal png
set object 1 rectangle from screen 0,0 to screen 1,1 fillcolor rgb"#272822" behind
set output "$OUTFILE"
plot "$LOGFILE" using 2:xticlabels(stringcolumn(1)) with histogram notitle linecolor rgb 'blue'
EOF
}

decrypt_allanime() {
        printf "%s" "$-" | grep -q 'x' && set +x
        for hex in $(printf '%s' "$1" | sed 's/../&\n/g'); do
                dec=$(printf "%d" "0x$hex")
                xor=$((dec ^ 56))
                #shellcheck disable=SC2059
                printf "\\$(printf "%o" "$xor")"
        done
        printf "%s" "$-" | grep -q 'x' || set -x
}

provider_run() {
        provider_id="$(decrypt_allanime "$(printf "%s" "$data" | sed -n "$2" | head -1 | cut -d':' -f2)" | sed "s/\/clock/\/clock\.json/")"
        [ -z "$provider_id" ] && gen_img "$1" "! No" "embed" "#a26b03" || printf "\n\033[1;34mFetching %s links < %s" "$1" "$provider_id"
        [ -z "$provider_id" ] || (provider_video=$(curl -s "https://${domain}$provider_id" | sed 's|},{|\n|g' | sed -nE 's|.*link":"([^"]*)".*"resolutionStr":"([^"]*)".*|\2 >\1|p') && [ -z "$provider_video" ] && gen_img "$1" "✗ No" "url" "darkred" || gen_img "$1" "✓ $(printf "%s\n" "$provider_video" | wc -l)" "url(s)" "darkgreen" "yes")
}

#intializing
printf "" >results
domain="allanime.day"
base_url="https://api.$domain"
lol="https://allanime.to"
total=$(cat total)
total=$((total + 1))
printf "%s" "$total" >total
agent="Mozilla/5.0"
query="query(        \$search: SearchInput        \$limit: Int        \$page: Int        \$translationType: VaildTranslationTypeEnumType        \$countryOrigin: VaildCountryOriginEnumType    ) {    shows(        search: \$search        limit: \$limit        page: \$page        translationType: \$translationType        countryOrigin: \$countryOrigin    ) {        edges {            _id name lastEpisodeInfo __typename       }    }}"
[ -z "$*" ] && url=$(curl -s -e "$lol" -G "$base_url/api" -d "variables=%7B%22search%22%3A%7B%22sortBy%22%3A%22Recent%22%2C%22allowAdult%22%3Afalse%2C%22allowUnknown%22%3Afalse%7D%2C%22limit%22%3A40%2C%22page%22%3A1%2C%22translationType%22%3A%22sub%22%2C%22countryOrigin%22%3A%22JP%22%7D" --data-urlencode "query=$query" -A "$agent" | sed 's|Show|\n|g' | sed -nE 's|.*_id":"([^"]*)","name":"([^"]*)".*sub":\{"episodeString":"([^"]*)".*|\1\t\2 Episode \3|p' | shuf -n1 | tr '[:punct:]' ' ' | tr -s ' ') || url=$*
title=$(printf "%s" "$url" | cut -f2-)
id=$(printf "%s" "$url" | cut -f1)
ep_no=$(printf "%s" "$url" | sed 's/.*Episode //g')
[ -z "$url" ] && exit 0 || printf "\033[1;35mSelected %s\n\033[1;36mLoading Episode.." "$title"
sed -i -E "s_Episode Name: (.*)_Episode Name: $(printf "$title" | cut -d"/" -f2- | tr "[:punct:]" " ")_g ; s_${lol}(.*)_${lol}/watch/${id}/episode-${ep_no}-sub_g" README.md &
episode_embed_gql="query (\$showId: String!, \$translationType: VaildTranslationTypeEnumType!, \$episodeString: String!) {    episode(        showId: \$showId        translationType: \$translationType        episodeString: \$episodeString    ) {        episodeString sourceUrls    }}"
data=$(curl -e "$lol" -A "$agent" -s -G "$base_url/api" -d "variables=%7B%22showId%22%3A%22$id%22%2C%22translationType%22%3A%22sub%22%2C%22countryOrigin%22%3A%22ALL%22%2C%22episodeString%22%3A%22$ep_no%22%7D" --data-urlencode "query=$episode_embed_gql" | tr '{}' '\n' | sed 's|\\u002F|\/|g;s|\\||g' | sed -nE 's|.*sourceUrl":"--([^"]*)".*sourceName":"([^"]*)".*|\2 :\1|p')

#vrv links
provider_run "wixmp" "/Default :/p" &

#dropbox
provider_run "dropbox" "/Sak :/p" &

#wetransfer
provider_run "wetransfer" "/Kir :/p" &

#sharepoint
provider_run "sharepoint" "/S-mp4 :/p" &

#gogoplay
provider_run "gogoplay" "/Luf-mp4 :/p" &

wait

#analytics using gnuplot
gen_analytics && echo "Analytics graph generated"
