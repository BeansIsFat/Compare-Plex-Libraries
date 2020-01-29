#!/usr/bin/env bash

# Requires ExportTools to be installed in Plex — https://github.com/ukdtom/ExportTools.bundle/wiki
# Will show all the titles in the 2nd library that are missing from the 1st
# e.g. find the movies in 4K that aren't in the regular library

PLEXTOKEN=YourPlexToken
DIR=/mnt/local/Media/ExportTools
LIB1=Movies
LIB2=Movies-4K
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

  sleep 1 # wait a second for the temp file to be created

  while [[ -e $DIR/$LIBRARY$TMPFILE ]]
    do sleep 1
  done
done

getList() {
  awk -F "\",\"" '{print $2}' "$1" | sort
}

comm -13 \
  <(getList $DIR/$LIB1-level\ 1.csv) \
  <(getList $DIR/$LIB2-level\ 1.csv)
