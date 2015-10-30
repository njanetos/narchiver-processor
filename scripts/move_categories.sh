#!/bin/bash

mkdir raw_categories
find raw/ -type f -name '*category*' -exec cp -i {} -t raw_categories \;
