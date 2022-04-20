#!/usr/bin/env zsh

#########################################################################
# Title:         ComparePlexLibraries                                   #
# Author:        BeansIsFat                                             #
# URL:           https://github.com/BeansIsFat/Compare-Plex-Libraries   #
# Description:   Finds items in one Plex library missing from another   #
#########################################################################
#
# Will show all the titles in the 2nd library that are missing from the
# 1st e.g. find the movies in 4K that aren't in the regular library
#
# Usage:
# ComparePlexLibraries.sh --lib1 library_name --lib2 library_name --lib_type library_type
#
# Example:
# ComparePlexLibraries.sh --lib1 Movies --lib2 Movies-4K --lib_type movie
#
# The example represents the default values used if no options are supplied
#
# Library names must be properly escaped
# e.g TV\ Shows or "TV Shows"
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

# command line options (case-sensitive), set to defaults
lib_type=${lib_type:-movie}
lib1=${lib1:-Movies}
lib2=${lib2:-Movies-4K}

# process command line arguments and assign them to named variables
while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="$2"
  fi
  shift
done

if ! [[ $lib_type =~ ^(tv|movie)$ ]] ; then
  echo "lib_type must be tv or movie"
  exit 0
fi

case $lib_type in
  movie)
    LEVEL="Level 1"
    ;;
  tv)
    LEVEL="Show Only 1"
    ;;
  *)
esac

# Display spinner and text passed to function while waiting for the export
# Will continue until temp file is deleted by the export process
# Usage: wait_for_export file_name "text"
function wait_for_export() {
    local _tmpfile="$1"
    local info="$2"
    local delay=0.08
    # local spinstr='-\|/'
    # Alternative spinner using braille characters
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [[ -f $_tmpfile ]]; do
        # Create temp string with all but first spinner character
        local temp=${spinstr: 1}
        # Print first spinner character
        # Using s because c only works for low ascii characters
        printf " [%.1s] $info" "$spinstr"
        # Move first spinner character to end of string
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        local reset="\b\b\b\b\b\b"
        for ((i=1; i<=$(echo $info | wc -c); i++)); do
            reset+="\b"
        done
        printf $reset
    done
    # Clear line
    printf '\33[2K\r'
}

for LIBRARY in "$lib1" "$lib2"
do
  # Construct temp file name based on selected options
  TMPSUFFIX=.csv.tmp-Wait-Please
  tmpfile=$DIR/$LIBRARY-$LEVEL$TMPSUFFIX

  # Create dummy temp file so we don't have to wait to start checking
  touch $tmpfile

  # Launch ExportTools via URL for selected library
  curl -sG -d "title=${LIBRARY// /%20}" \
    -d "skipts=true" \
    -d "level=${LEVEL// /%20}" \
    -d "X-Plex-Token=$PLEXTOKEN" \
    -d "playlist=false" \
    "$PLEXURL/applications/ExportTools/launch" \
    > /dev/null

  wait_for_export "$tmpfile" "Processing $LIBRARY library"
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
  <(getList "$DIR/$lib1-$LEVEL.csv") \
  <(getList "$DIR/$lib2-$LEVEL.csv")
