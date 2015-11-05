#!/bin/bash

mkdir -p raw_by_site && cd raw_by_site && mkdir -p hydra && cd hydra && mkdir -p listings && mkdir -p vendors

cd ../../raw

# Find all directories with agora in the title and pipe all files it contains to the appropriate directory

find -name *hydra* -type d | while read directory; do
        ../scripts/update_progress.sh "Sorting directory $directory..."
        find "$directory" -type f -name "*%2Fsale%2F*" -exec sh -c '../scripts/clean_css.sh $0 hydra listings' {} \;;
        find "$directory" -type f -name "*%2Fvendor%2F*" -exec sh -c '../scripts/clean_css.sh $0 hydra vendors' {} \;;
done

