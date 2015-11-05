#!/bin/bash

mkdir -p raw_by_site && cd raw_by_site && mkdir -p dream && cd dream && mkdir -p listings

cd ../../raw

# Find all directories with dream in the title and pipe all files it contains to the appropriate directory

find -name *dream* -type d | while read directory; do
        ../scripts/update_progress.sh "Sorting directory $directory..."
        find "$directory" -type f -name "*%2FviewProduct%3F*" -exec sh -c '../scripts/clean_css.sh $0 dream listings' {} \;;
done

