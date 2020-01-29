#!/usr/bin/env bash

# Will show all the titles in the 2nd library that are missing from the 1st
# e.g. find the movies in 4K that aren't in the regular library
# Requires ExportTools to be installed in Plex — https://github.com/ukdtom/ExportTools.bundle/wiki

PLEXTOKEN=YourPlexToken
LIB1=Movies
LIB2=Movies-4K
DIR=/mnt/local/Media/ExportTools
TMPFILE=-level\ 1.csv.tmp-Wait-Please
PLEXIP=$(docker inspect \
  -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' plex)

for LIBRARY in $LIB1 $LIB2
do
  curl -sG -d "title=$LIBRARY" \
    -d "skipts=true" \
    -d "level=level%201" \
    -d "X-Plex-Token=$PLEXTOKEN" \
    -d "playlist=false" \
    "http://$PLEXIP:32400/applications/ExportTools/launch" \
    > /dev/null

  printf "Processing $LIBRARY library:  "
  while :
  do
    for c in / - \\ \|
    do
      # Update progress spinner
      printf '%s\b' "$c"
      sleep .2
      # When temp file is gone erase line and break out of both loops
      [[ ! -f $DIR/$LIBRARY$TMPFILE ]] && { printf '\33[2K\r'; break 2; }
    done
  done
done

getList() {
  # Prints title,year for movies
  awk '{print $2 "," $6}' FPAT="([^,]+)|(\"[^\"]+\")" "$1" | sort
}

comm -13 \
  <(getList $DIR/$LIB1-level\ 1.csv) \
  <(getList $DIR/$LIB2-level\ 1.csv)
