#!/bin/bash

# Cleans the CSS from an HTML file and sends it to /raw_by_site/$1/$2/filename, unless it exists

if [ ! -e "../raw_by_site/""$2""/""$3""/"`echo $1 | sed "s/.*\///"` ]; then
	perl -pe "s|(<style ?type ?= ?\"text/css\">)(.*?)(<\/style>)||g" < $1 > "../raw_by_site/""$2""/""$3""/"`echo $1 | sed "s/.*\///"`
fi
