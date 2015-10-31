#!/bin/bash

# Sorts the agora files into listings, vendors, and categories.

cd raw_by_site/agora

rm -rf ../listings
rm -rf ../vendors
rm -rf ../categories

mkdir ../listings
mkdir ../vendors
mkdir ../categories

../../scripts/update_progress.sh "Sorting agora into listings..."
find -type f -name "*%2Fp%2F*" -exec mv '{}' ../listings \;;
../../scripts/update_progress.sh "Sorting agora into vendors..."
find -type f -name "*%2Fvendor%2F*" -exec mv '{}' ../vendors \;;

mv ../listings listings
mv ../vendors vendors
mv ../categories categories
