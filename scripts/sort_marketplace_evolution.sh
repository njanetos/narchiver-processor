#!/bin/bash

mkdir -p raw_by_site && cd raw_by_site && mkdir -p evolution && cd evolution && mkdir -p listings && mkdir -p categories

cd ../../raw

# Find all directories with evolution in the title and pipe all files it contains to the appropriate directory

find -name *evolution* -type d | while read directory; do
	../scripts/update_progress.sh "Sorting directory $directory..."
	find "$directory" -type f -name "*%2Flisting%2F*" -exec sh -c '../scripts/clean_css.sh $0 evolution listings' {} \;;
	find "$directory" -type f -name "*%2Fcategory%2F*" -exec sh -c '../scripts/clean_css.sh $0 evolution categories' {} \;;
done

