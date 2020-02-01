# Compare Plex Libraries
Script to compare Plex Movie or TV libraries. Written for Cloudbox but could be adapted to other Plex configurations.

Will show all the titles in the 2nd library that are missing from the 1st
e.g. find the movies in 4K that aren't in the regular library

Useful if you have a 4K library using Trakt to add items via Radarr and want to make sure you have the regular HD version without having to sync Radarr instances

Depends on accurate metadata. If a library item exists but is reported as missing that means the metadata is probably slightly different.

Go to Fix Match > Search Options > Agent for the item in both libraries and select the same agent for both to resolve this

Assumes Plex is running from Docker container with default CloudBox paths

Requires ExportTools to be installed and configured in Plex
https://github.com/ukdtom/ExportTools.bundle/wiki
