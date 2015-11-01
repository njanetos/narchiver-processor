#!/bin/bash

# Sorts files by the marketplace they belong to into /raw_by_site

rm -rf temp && mkdir temp && mkdir -p raw_by_site && cd raw
../scripts/update_progress.sh "Copying all from $1 into temporary folder..."
find -type d -name "*$1*" -exec cp -r '{}' ../temp/ \;;
cd ../raw_by_site && rm -rf "$1" && mkdir "$1" && cd ../temp

../scripts/update_progress.sh "Collapsing directory structure for $1 and removing CSS..."

find -type f -exec sh -c 'perl -pe "s|(<style type=\"text/css\">)(.*?)(<\/style>)||g" < $0 > ../raw_by_site/$1/`echo $0 | sed "s/.*\///"`' {} "$1" \;;
cd .. && rm -rf temp
