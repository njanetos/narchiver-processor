#!/bin/bash

# Sorts the evolution files into listings, categories.

cd raw_by_site/evolution

rm -rf ../listings
rm -rf ../categories

mkdir ../listings
mkdir ../categories

../../scripts/update_progress.sh "Sorting evolution into listings..."
find -type f -name "*%2Flisting%2F*" -exec mv '{}' ../listings \;;
../../scripts/update_progress.sh "Sorting evolution into categories..."
find -type f -name "*%2Fcategory%2F*" -exec mv '{}' ../categories \;;

mv ../listings listings
mv ../categories categories
