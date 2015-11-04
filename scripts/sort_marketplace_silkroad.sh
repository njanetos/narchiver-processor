#!/bin/bash

mkdir -p raw_by_site && cd raw_by_site && mkdir -p silkroad && cd silkroad && mkdir listings

cd ../../raw

# Find all directories with silkroad in the title and pipe all files it contains to the appropriate directory

find -name *silkroad* -type d | while read directory; do
        ../scripts/update_progress.sh "Sorting directory $directory..."
        find "$directory" -type f -name "*%2Fitems%2F*" -exec sh -c '../scripts/clean_css.sh $0 silkroad listings' {} \;;
done

