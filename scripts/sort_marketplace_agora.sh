#!/bin/bash

mkdir -p raw_by_site && cd raw_by_site

rm -rf agora && mkdir agora && cd agora && mkdir listings && mkdir vendors

cd ../../raw

# Find all directories with agora in the title and pipe all files it contains to the appropriate directory

find -name *agora* -type d | while read directory; do
	../scripts/update_progress.sh "Sorting directory $directory..."
	find "$directory" -type f -name "*%2Fp%2F*" -exec sh -c 'perl -pe "s|(<style ?type ?= ?\"text/css\">)(.*?)(<\/style>)||g" < $0 > ../raw_by_site/agora/listings/`echo $0 | sed "s/.*\///"`' {} \;;
        find "$directory" -type f -name "*%2Fvendor%2F*" -exec sh -c 'perl -pe "s|(<style ?type ?= ?\"text/css\">)(.*?)(<\/style>)||g" < $0 > ../raw_by_site/agora/vendors/`echo $0 | sed "s/.*\///"`' {} \;;
done
