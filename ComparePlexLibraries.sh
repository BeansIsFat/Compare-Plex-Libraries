#!/usr/bin/env bash

#########################################################################
# Title:         ComparePlexLibraries                                   #
# Author:        BeansIsFat                                             #
# URL:           https://github.com/BeansIsFat/Compare-Plex-Libraries   #
# Description:   Finds items in one Plex library missing from another   #
#########################################################################
#
# Will show all the titles in the 2nd library that are missing from the 1st
# e.g. find the movies in 4K that aren't in the regular library
#
# Depends on accurate metadata. If a library item exists but is reported
# as missing that means the metadata is probably slightly different.
# Go to Fix Match > Search Options > Agent for the item in both libraries
# and select the same agent for both to resolve this.
#
# Assumes Plex is running from Docker container with default CloudBox paths
#
# Requires ExportTools to be installed and configured in Plex
# https://github.com/ukdtom/ExportTools.bundle/wiki

# User variables
PLEXTOKEN=YourPlexToken
LIB1="Movies"       # case-sensitive
LIB2="Movies-4K"    # case-sensitive
LIBTYPE="Movies"    # set to TV or Movies to get proper metadata for library type
DIR=/mnt/local/Media/ExportTools # export location

# Internal variables
TMPSUFFIX=.csv.tmp-Wait-Please

printf "Getting Plex IP address"
PLEXIP=$(docker inspect \
  -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' plex)
printf  '\33[2K\r'

case $LIBTYPE in
  Movies)
    LEVEL="level 1"
    ;;
  TV)
    LEVEL="Show Only 1"
    ;;
  *)
esac

for LIBRARY in "$LIB1" "$LIB2"
do
  # Launch ExportTools via URL for selected library
  printf "Processing $LIBRARY library:  "
  curl -sG -d "title=${LIBRARY// /%20}" \
    -d "skipts=true" \
    -d "level=${LEVEL// /%20}" \
    -d "X-Plex-Token=$PLEXTOKEN" \
    -d "playlist=false" \
    "http://$PLEXIP:32400/applications/ExportTools/launch" \
    > /dev/null

  while :
  do
    for c in / - \\ \|
    do
      # Update progress spinner
      printf '%s\b' "$c"
      sleep .2
      # When temp file is gone erase line and break out of both loops
      [[ ! -f $DIR/$LIBRARY-$LEVEL$TMPSUFFIX ]] && { printf '\33[2K\r'; break 2; }
    done
  done
done

getList() {
  # Prints title,year for movies or tv shows
  awk \
    -v COL1="\"Title\"" \
    -v COL2="\"Year\"" \
    'BEGIN {FPAT="[^,]*|\"[^\"]|\"\"*\""} \
    NR==1 { \
      for(i=1;i<=NF;i++) { \
        if($i==COL1)c1=i; \
        if ($i==COL2)c2=i; \
      } \
    } \
    {print $c1 "," $c2}' \
    "$1" | sort
}

# Compares both lists, returning only the unique items in the second list
comm -13 \
  <(getList "$DIR/$LIB1-$LEVEL.csv") \
  <(getList "$DIR/$LIB2-$LEVEL.csv")
