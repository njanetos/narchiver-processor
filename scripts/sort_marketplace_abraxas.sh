#!/bin/bash

# Sorts the agora files into listings, vendors, and categories.

cd raw_by_site/abraxas

rm -rf ../listings
rm -rf ../vendors
rm -rf ../categories
rm -rf ../stats

mkdir ../listings
mkdir ../vendors
mkdir ../categories
mkdir ../stats

../../scripts/update_progress.sh "Sorting abraxas into listings..."
find -type f -name "*%2Flisting%2F*" -exec mv '{}' ../listings \;;
../../scripts/update_progress.sh "Sorting abraxas into vendors..."
find -type f -name "*%2Fvendor%2F*" -exec mv '{}' ../vendors \;;
../../scripts/update_progress.sh "Sorting abraxas into categories..."
find -type f -name "*%2Fc%2F*" -exec mv '{}' ../categories \;;
../../scripts/update_progress.sh "Sorting abraxas into stats..."
find -type f -name "*%2Fstats%2F*" -exec mv '{}' ../stats \;;

mv ../listings listings
mv ../vendors vendors
mv ../categories categories
mv ../stats stats
