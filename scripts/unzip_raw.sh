#!/bin/bash

# Copied everything in raw_zipped/ to raw/, then goes through and recursively unzips all of those files into the same folder.
# Deletes all CSS styling
# Then, deletes all zip files in /raw.

rm -rf raw && cp -r raw_zipped raw && cd raw

while [ "`find . -type f -name '*.zip' | wc -l`" -gt 0 ]; do
	find -type f -name "*.zip" -exec sh -c '../scripts/update_progress.sh "Unzipping ""$1" && unzip -q -d "${1%.*}" "$1" && rm "$1"' _ {} \;;
done
