#!/bin/bash

# Unzips anything that hasn't been unzipped into the folder raw
# Then goes through and recursively unzips everything

mkdir -p raw && cd raw_zipped

find -type f -exec sh -c 'temp=${0#./} && if [ ! -d "../raw/""${temp%.zip}" ]; then ../scripts/update_progress.sh "Found new zip file, ""$temp"", unzipping..." && unzip -q -d ../raw/"${temp%.zip}" "$0"; fi' {} \;;

cd ../raw

while [ "`find . -type f -name '*.zip' | wc -l`" -gt 0 ]; do
	find -type f -name "*.zip" -exec sh -c '../scripts/update_progress.sh "Unzipping ""$1" && unzip -q -d "${1%.*}" "$1" && rm "$1"' _ {} \;;
done
