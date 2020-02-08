#!/usr/bin/env bash

#########################################################################
# Title:         ComparePlexLibraries                                   #
# Author:        BeansIsFat                                             #
# URL:           https://github.com/BeansIsFat/Compare-Plex-Libraries   #
# Description:   Finds items in one Plex library missing from another   #
#########################################################################
#
# Usage: ComparePlexLibraries.sh library1 library2 librarytype
#
# Will show all the titles in the 2nd library that are missing from the
# 1st e.g. find the movies in 4K that aren't in the regular library
#
# Depends on accurate metadata. If a library item exists but is reported
# as missing that means the metadata is probably slightly different.
# Go to Fix Match > Search Options > Agent for the item in both libraries
# and select the same agent for both to resolve this.
#
# Edit User variables before use
#
# PLEXTOKEN: See https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/
# for information on getting your Plex token
#
# DIR: should be the path to export media in ExportTools
# Be sure to provide the absolute path if you are running Plex in Docker
#
# PLEXURL: should not have a trailing slash but should have the port if
# you are accessing without a domain (e.g. http://localhost:32400)
#
# Requires ExportTools to be installed and configured in Plex
# https://github.com/ukdtom/ExportTools.bundle/wiki

# User variables
PLEXTOKEN=YourPlexToken
DIR=/mnt/local/Media/ExportTools # Default export location for ExportTools
PLEXURL=YourPlexURL # e.g. https://plex.yourdomain.tld

# Internal variables
TMPSUFFIX=.csv.tmp-Wait-Please

if [[ $# -lt 3 ]] ; then
  echo "Not enough arguments"
  echo "Usage: ComparePlexLibraries.sh library1 library2 librarytype"
  echo
  echo "Library names must be properly escaped"
  echo "  e.g TV\\ Shows or \"TV Shows\""
  echo
  echo "librarytype must be tv or movie"
  exit 0
fi

if ! [[ $3 =~ ^(tv|movie)$ ]] ; then
  echo "librarytype must be tv or movie"
  exit 0
fi

LIB1=$1
LIB2=$2
LIBTYPE=$3

case $LIBTYPE in
  movie)
    LEVEL="level 1"
    ;;
  tv)
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
    "$PLEXURL/applications/ExportTools/launch" \
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
