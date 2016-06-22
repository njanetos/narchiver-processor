#!/bin/bash

# Unzips anything that hasn't been unzipped into the folder raw
# Then goes through and recursively unzips everything

# Unzip the test file, if necessary
if [ ! -d raw_zipped ]; then
	if [ -f raw_zipped_test.zip ]; then
		unzip raw_zipped_test.zip
	else
		echo "Failed to find data. Either raw_zipped_test.zip or raw_zipped/ must be present. Exiting."
		exit 1
	fi
fi

mkdir -p raw && cd raw_zipped

../scripts/update_progress.sh "Looking for new archives..."

find -type f -exec sh -c 'temp=${0#./} && if [ ! -d "../raw/""${temp%.zip}" ]; then ../scripts/update_progress.sh "Found new zip file, ""$temp"", unzipping..." && unzip -q -d -o ../raw/"${temp%.zip}" "$0"; fi' {} \;;

../scripts/update_progress.sh "All archives unzipped. I will now recursively unzip all zip files in the folder raw."

cd ../raw

while [ "`find . -type f -name '*.zip' | wc -l`" -gt 0 ]; do
        ../scripts/update_progress.sh "Found zip files, unzipping..."
	find -type f -name "*.zip" -exec sh -c '../scripts/update_progress.sh "Unzipping ""$1" && unzip -q -d -o "${1%.*}" "$1" && rm "$1"' _ {} \;;
done
