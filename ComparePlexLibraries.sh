#!/usr/bin/env bash

# Requires ExportTools to be installed in Plex — https://github.com/ukdtom/ExportTools.bundle/wiki
# Will show all the titles in the 2nd library that are missing from the 1st
# e.g. find the movies in 4K that aren't in the regular library

PLEXTOKEN=YourPlexToken
DIR=/mnt/local/Media/ExportTools
LIB1=Movies
LIB2=Movies-4K
TMPFILE=-level\ 1.csv.tmp-Wait-Please

for LIBRARY in $LIB1 $LIB2
do
  docker exec plex bash -c \
    'curl -s "http://localhost:32400/applications/ExportTools/launch?title='"$LIBRARY"'&skipts=true&level=level%201&X-Plex-Token='"$PLEXTOKEN"'&playlist=false"' > /dev/null
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
