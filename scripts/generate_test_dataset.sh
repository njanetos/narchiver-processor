#!/bin/bash

# Generates a random dataset with 2000 pages pulled at random, in raw_zipped.zip, zipped for E-Z distribution.

rm -rf raw_zipped_test && mkdir raw_zipped_test && cd raw

randomfiles=`find -type f | shuf -n 2000`

while read -r file; do
	cp --parents "$file" ../raw_zipped_test
done <<< "$randomfiles"

cd ../raw_zipped_test

alldirs=`ls`

while read -r dir; do
	zip -qr "$dir"".zip" "$dir"
	rm -rf "$dir"
done <<< "$alldirs"
