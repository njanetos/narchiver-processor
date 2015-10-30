#!/bin/bash

# Unzips all files in raw.zip to /raw, then goes through and recursively unzips all of those files into the same folder.
# Then, deletes all zip files in /raw.
# Finally, sorts them by marketplace.

rm -rf raw
mkdir raw

unzip raw.zip -d raw

cd raw

while [ "`find . -type f -name '*.zip' | wc -l`" -gt 0 ]; do
	find -type f -name "*.zip" -exec sh -c 'echo "Unzipping ""$1" && unzip -q -d "${1%.*}" "$1" && rm "$1"' _ {} \;;
done

# Sort by marketplace

cd .. && rm -rf raw_site_temp && mkdir raw_site_temp && cd raw

for marketplace in silkroad evolution agora nucleus blackbank abraxas dream; do
	mkdir ../raw_site_temp/$marketplace
	find -type d -name "*$marketplace*" -exec cp -r '{}' ../raw_site_temp/$marketplace/ \;;
	find -type d -name "*$marketplace*" -exec rm -rf '{}' \;;

	rm -rf $marketplace
	mkdir $marketplace

	find ../raw_site_temp/$marketplace/ -type f -exec cp '{}' $marketplace/ \;;
	rm -rf ../raw_site_temp/$marketplace
done

rm -rf ../raw_site_temp
