#!/bin/bash

mkdir -p raw_by_site && cd raw_by_site && mkdir -p marketplace && cd marketplace && mkdir -p listings && mkdir -p vendors

cd ../../raw

# Find all directories with agora in the title and pipe all files it contains to the appropriate directory

find -name *marketplace* -type d | while read directory; do
        ../scripts/update_progress.sh "Sorting directory $directory..."
        find "$directory" -type f -name "*%2Fproduct%2F*" -exec sh -c '../scripts/clean_css.sh $0 marketplace listings' {} \;;
        find "$directory" -type f -name "*%2Fvendor%2F*" -exec sh -c '../scripts/clean_css.sh $0 marketplace vendors' {} \;;
done

