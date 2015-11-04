#!/bin/bash

mkdir -p raw_by_site && cd raw_by_site && mkdir -p abraxas && cd abraxas && mkdir -p listings && mkdir -p vendors && mkdir -p categories

cd ../../raw

# Find all directories with abraxas in the title and pipe all files it contains to the appropriate directory

find -name *abraxas* -type d | while read directory; do
	../scripts/update_progress.sh "Sorting directory $directory..."
	find "$directory" -type f -name "*%2Flisting%2F*" -exec sh -c '../scripts/clean_css.sh $0 abraxas listings' {} \;;
	find "$directory" -type f -name "*%2Fvendor%2F*" -exec sh -c '../scripts/clean_css.sh $0 abraxas vendors' {} \;;
	find "$directory" -type f -name "*%2Fc%2F*" -exec sh -c '../scripts/clean_css.sh $0 abraxas categories' {} \;;

done

