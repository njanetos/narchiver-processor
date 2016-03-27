#!/bin/bash

# Generates a random dataset with pages pulled at random, in raw_zipped.zip, zipped for E-Z distribution.

rm -rf raw_zipped_test && mkdir raw_zipped_test && cd raw

randomfiles=`find -type f | shuf -n 100000`

while read -r file; do
	cp --parents "$file" ../raw_zipped_test
done <<< "$randomfiles"

cd ../raw_zipped_test

alldirs=`ls`

while read -r dir; do
	zip -qr "$dir"".zip" "$dir"
	rm -rf "$dir"
done <<< "$alldirs"

# Zip the file

cd .. && rm -rf temp && mkdir temp
mv raw_zipped_test temp
cd temp
mv raw_zipped_test raw_zipped
zip -rq raw_zipped_test.zip raw_zipped
mv raw_zipped_test.zip ../
cd .. && rm -rf temp
