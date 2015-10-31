#!/bin/bash

# Sort by marketplace

rm -rf temp && mkdir temp && mkdir -p raw_by_site && cd raw
find -type d -name "*$1*" -exec cp -r '{}' ../temp/ \;;
cd ../raw_by_site && rm -rf "$1" && mkdir "$1" && cd ../temp
find -type f -exec mv '{}' ../raw_by_site/"$1" \;;
cd .. && rm -rf temp
