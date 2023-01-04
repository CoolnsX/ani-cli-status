#!/bin/sh

gen_img() {
	convert -fill white -background "$4" -pointsize 72 -font "iosevka-regular.ttf" label:"\ $2 $3 " "images/$1.jpg"
	printf "%s : %s %s\n" "$1" "$2" "$3" >> results
	printf "\n\033[1;32m%s image generated!!" "$1"
	#analytics
	if [ -n "$5" ];then
		prev=$(sed -nE "s/$1\t(.*)/\1/p" data)
		prev=$((prev+1))
		sed -i -E "s_${1}(.*)_${1}\t${prev}_g" data
	fi
}

provider_run(){
	provider_id=$(printf "%s" "$data" | sed -n "$2" | head -1 | cut -d':' -f2)
	[ -z "$provider_id" ] && gen_img "$1" "! No" "embed link" "#a26b03" || printf "\n\033[1;34mFetching %s links < %s" "$1" "$provider_id"
	[ -z "$provider_id" ] || (provider_video=$(curl -s "https://blog.allanime.pro/apivtwo/clock.json?id=$provider_id" | sed 's|},{|\n|g' | sed -nE 's|.*link":"([^"]*)".*"resolutionStr":"([^"]*)".*|\2 >\1|p') && [ -z "$provider_video" ] && gen_img "$1" "✗ No" "link returned" "darkred" || gen_img "$1" "✓ $(printf "%s\n" "$provider_video" | wc -l)" "links returned" "darkgreen" "yes")
}
#intializing
printf "" > results
base_url="https://allanime.site"
total=$(cat total)
total=$((total+1))
printf "%s" "$total" > total
agent="uwu"
[ -z "$*" ] && url=$(curl -s "$base_url/allanimeapi?variables=%7B%22search%22%3A%7B%22sortBy%22%3A%22Recent%22%2C%22allowAdult%22%3Afalse%2C%22allowUnknown%22%3Afalse%7D%2C%22limit%22%3A40%2C%22page%22%3A1%2C%22translationType%22%3A%22sub%22%2C%22countryOrigin%22%3A%22JP%22%7D&extensions=%7B%22persistedQuery%22%3A%7B%22version%22%3A1%2C%22sha256Hash%22%3A%229c7a8bc1e095a34f2972699e8105f7aaf9082c6e1ccd56eab99c2f1a971152c6%22%7D%7D" -A "$agent" | sed 's|Show|\n|g' | sed -nE 's|.*_id":"([^"]*)","name":"([^"]*)".*"sub":([1-9][^,]*).*|\1\t\2\tepisode \3 sub|p' | shuf -n1 | tr -d '[:punct:]' | tr ' \t' '-/') || url=$*
[ -z "$url" ] && exit 0 || printf "\033[1;35mSelected %s\n\033[1;36mLoading Episode.." "$url"
sed -i -E "s_Episode Name: (.*)_Episode Name: $(printf "$url" | cut -d"/" -f2- | tr "[:punct:]" " ")_g ; s_${base_url}(.*)_${base_url}/watch/${url}_g" README.md &
data=$(curl -A "$agent" -s "${base_url}/watch/${url}" | tr '{}' '\n' | sed 's|\\u002F|\/|g;s|\\||g' | sed -nE 's|.*sourceUrl":".*?id=([^"]*)".*sourceName":"([^"]*)".*|\2 :\1|p')

#vrv|wixmp links
provider_run "vrv" "/Default :/p" &

#vrv|wixmp links
provider_run "pstatic" "/Default B :/p" &

#vrv|wixmp links
provider_run "sharepoint" "/S-mp4 :/p" &

#vrv|wixmp links
provider_run "usercloud" "/Uv-mp4 :/p" &

#vrv|wixmp links
provider_run "gogoplay" "/Luf-mp4 :/p" &

wait

#scraping gogoanime id for their inbuilt providers for my website
id=$(printf "%s" "$data" | sed -nE 's/Vid-mp4 :([^&]*).*/\1/p')
resp="$(curl -A "$agent" -sL "https://gogohd.net/streaming.php?id=$id" | sed -nE 's/.*data-status="1".*data-video="(.*)">.*/\1/p')"
[ -z "$resp" ] || printf "\33[2K\r\033[1;32m link providers (GOGO)>>\033[0m\n%s\n" "$resp"

#xstreamcdn(fembed) links
fb_id=$(printf "%s" "$resp" | sed -n "s_.*fembed.*/v/__p")
[ -z "$fb_id" ] && gen_img "xstreamcdn" "! No" "embed link" "#a26b03" || printf "\n\033[1;34mFetching xstreamcdn links < %s" "$fb_id"
[ -z "$fb_id" ] || (fb_video=$(curl -s -X POST "https://fembed-hd.com/api/source/$fb_id" -H "x-requested-with:XMLHttpRequest" | sed -e 's/\\//g' -e 's/.*data"://' | tr "}" "\n" | sed -nE 's/.*file":"(.*)","label":"(.*)",.*type.*/\2 > \1/p') && [ -z "$fb_video" ] && gen_img "xstreamcdn" "✗ No" "link returned" "darkred" || gen_img "xstreamcdn" "✓ $(printf "%s\n" "$fb_video" | wc -l)" "links returned" "darkgreen")

#doodstream link
dood_id=$(printf "%s" "$resp" | sed -n "s_.*dood.*/e/__p")
[ -z "$dood_id" ] && gen_img "doodstream" "! No" "embed link" "#a26b03" || printf "\n\033[1;34mFetching doodstream links <  %s" "$dood_id"
[ -z "$dood_id" ] || (dood_link=$(curl --cipher AES256-SHA256 --tls-max 1.2 -A "$agent" -sL "https://dood.wf/d/$dood_id" | sed -nE 's_.*a href="(/download[^"]*)".*_\1_p') && [ -z "$dood_link" ] && gen_img "doodstream" "✗ No" "link returned" "darkred" || gen_img "doodstream" "✓ $(printf "%s\n" "$dood_link" | wc -l)" "link returned" "darkgreen") &

#mp4upload (gogo) link
mp4up_link=$(printf "%s" "$resp" | grep "mp4upload")
[ -z "$mp4up_link" ] && gen_img "mp4upload" "! No" "embed link" "#a26b03" || printf "\n\033[1;34mFetching mp4upload links <  %s" "$mp4up_link"
[ -z "$mp4up_link" ] || (mp4up_video=$(curl -A "$agent" -s "$mp4up_link" -H "DNT: 1" | sed -nE 's_.*embed\|(.*)\|.*blank.*\|(.*)\|(.*)\|(.*)\|(.*)\|src.*_https://\1.mp4upload.com:\5/d/\4/\3.\2_p') && [ -z "$mp4up_video" ] && gen_img "mp4upload" "✗ No" "link returned" "darkred" || gen_img "mp4upload" "✓ $(printf "%s\n" "$mp4up_link" | wc -l)" "link returned" "darkgreen") &

wait

#scraping hentaimama
hent_video=$(curl -s https://hentaimama.io/wp-admin/admin-ajax.php -d "action=get_player_contents&a=$(curl -s "https://hentaimama.io" | sed -nE 's_.*id="post-hot-([^"]*)".*_\1_p' | shuf | head -1)" -H X-Requested-With:XMLHttpRequest | tr -d '\\' | tr ',' '\n' | sed -nE 's/.*src="(.*)" width.*/\1/p') && [ -z "$hent_video" ] && gen_img "hentaimama" "✗ No" "link returned" "darkred" || gen_img "hentaimama" "✓ $(printf "%s\n" "$hent_video" | wc -l)" "links returned" "darkgreen" &

wait

#analytics
LOGFILE=./data
OUTFILE=./analytics.png

gnuplot << EOF
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
