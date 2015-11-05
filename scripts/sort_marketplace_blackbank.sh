#!/bin/bash

mkdir -p raw_by_site && cd raw_by_site && mkdir -p blackbank && cd blackbank && mkdir -p listings && mkdir -p vendors

cd ../../raw

# Find all directories with blackbank in the title and pipe all files it contains to the appropriate directory

find -name *blackbank* -type d | while read directory; do
        ../scripts/update_progress.sh "Sorting directory $directory..."
        find "$directory" -type f -name "*%2Fitem%2F*" -exec sh -c '../scripts/clean_css.sh $0 blackbank listings' {} \;;
        find "$directory" -type f -name "*%2Fvendor%2F*" -exec sh -c '../scripts/clean_css.sh $0 blackbank vendors' {} \;;
done

