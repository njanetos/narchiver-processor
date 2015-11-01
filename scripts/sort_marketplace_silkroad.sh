#!/bin/bash

# Sorts the silkroad files into listings.

cd raw_by_site/evolution

rm -rf ../listings

mkdir ../listings

../../scripts/update_progress.sh "Sorting silkroad into listings..."
find -type f -name "*%2Fitems%2F*" -exec mv '{}' ../listings \;;

mv ../listings listings
