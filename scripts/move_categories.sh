#!/bin/bash

cd ..
find raw/ -type f -name "*category*.html" -exec cp -i {} -t categories \;
