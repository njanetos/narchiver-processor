#!/bin/bash

# Unzips all files in raw.zip to /raw, then goes through and recursively unzips all of those files into the same folder.
# Then, deletes all zip files in /raw.

rm -rf raw && mkdir raw

scripts/update_progress.sh "Unzipping raw.zip."
unzip -q  -d raw raw.zip

cd raw

while [ "`find . -type f -name '*.zip' | wc -l`" -gt 0 ]; do
	find -type f -name "*.zip" -exec sh -c '../scripts/update_progress.sh "Unzipping ""$1" && unzip -q -d "${1%.*}" "$1" && rm "$1"' _ {} \;;
done
