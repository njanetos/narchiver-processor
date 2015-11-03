#!/bin/bash

mkdir -p raw_by_site && cd raw_by_site

rm -rf abraxas && mkdir abraxas && cd abraxas && mkdir listings && mkdir vendors && mkdir categories

cd ../../raw

# Find all directories with abraxas in the title and pipe all files it contains to the appropriate directory

find -name *abraxas* -type d | while read directory; do
	../scripts/update_progress.sh "Sorting directory $directory..."
	find "$directory" -type f -name "*%2Flisting%2F*" -exec sh -c 'perl -pe "s|(<style ?type ?= ?\"text/css\">)(.*?)(<\/style>)||g" < $0 > ../raw_by_site/abraxas/listings/`echo $0 | sed "s/.*\///"`' {} \;;
        find "$directory" -type f -name "*%2Fvendor%2F*" -exec sh -c 'perl -pe "s|(<style ?type ?= ?\"text/css\">)(.*?)(<\/style>)||g" < $0 > ../raw_by_site/abraxas/vendors/`echo $0 | sed "s/.*\///"`' {} \;;
	find "$directory" -type f -name "*%2Fc%2F*" -exec sh -c 'perl -pe "s|(<style ?type ?= ?\"text/css\">)(.*?)(<\/style>)||g" < $0 > ../raw_by_site/abraxas/categories/`echo $0 | sed "s/.*\///"`' {} \;;
done

