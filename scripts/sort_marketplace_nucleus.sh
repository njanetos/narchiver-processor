#!/bin/bash

mkdir -p raw_by_site && cd raw_by_site && mkdir -p nucleus && cd nucleus && mkdir -p listings && mkdir -p vendors

cd ../../raw

# Find all directories with agora in the title and pipe all files it contains to the appropriate directory

find -name *nucleus* -type d | while read directory; do
        ../scripts/update_progress.sh "Sorting directory $directory..."
        find "$directory" -type f -name "*%2Fuser%2F*" -exec sh -c '../scripts/clean_css.sh $0 nucleus vendors' {} \;;
        find "$directory" -type f -name "*%2Fitem%2F*" -exec sh -c '../scripts/clean_css.sh $0 nucleus listings' {} \;;
done

