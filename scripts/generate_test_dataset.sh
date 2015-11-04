#!/bin/bash

# Generates a random dataset with 2000 pages pulled at random, in raw_zipped.zip, zipped for E-Z distribution.

rm -rf raw_zipped_test && mkdir raw_zipped_test && cd raw

test=`find -type f | shuf -n 10`

echo "$test"
