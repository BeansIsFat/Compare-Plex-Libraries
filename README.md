# Compare Plex Libraries
Script to compare Plex Movie or TV libraries. Written for Cloudbox but could be adapted to other Plex configurations.

Will show all the titles in the 2nd library that are missing from the 1st e.g. find the movies in 4K that aren't in the regular library

Usage:
```ComparePlexLibraries.sh --lib1 library_name --lib2 library_name --lib_type library_type```
 
Example:
```ComparePlexLibraries.sh --lib1 Movies --lib2 Movies-4K --lib_type movie```

The example represents the default values used if no options are supplied

Library names must be properly escaped
e.g `TV\ Shows` or ``"TV Shows"``

Useful if you have a 4K library using Trakt to add items via Radarr and want to make sure you have the regular HD version without having to sync Radarr instances

Depends on accurate metadata. If a library item exists but is reported as missing that means the metadata is probably slightly different.

Go to Fix Match > Search Options > Agent for the item in both libraries and select the same agent for both to resolve this

Edit User variables before use

PLEXTOKEN: See https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/ for information on getting your Plex token

DIR: should be the path to export media in ExportTools. Be sure to provide the absolute path if you are running Plex in Docker.

PLEXURL: should not have a trailing slash but should have the port if you are accessing without a domain (e.g. http://localhost:32400)

Requires ExportTools to be installed and configured in Plex
https://github.com/ukdtom/ExportTools.bundle/wiki
