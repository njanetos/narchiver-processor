from update_progress import update_progress
from update_progress import print_progress
import re
import os
from os import listdir
from os.path import isfile, join
from lxml import html
import requests
import sqlite3 as lite
import sys
from clean_text import clean
from dateutil.parser import parse
import calendar
import time
import datetime

market = 'agora'

# Paths
path            = 'raw_by_site/' + market + '/vendors/'
output_path 	= 'clean_vendors/'
output_file 	= 'temp.db'
final_output    = market + '.db'

buffer_limit = 10000

try:
    os.remove(output_path + output_file)
except OSError:
    pass

if not os.path.exists(output_path):
    os.makedirs(output_path)

try:
    con = lite.connect(output_path + output_file)
    con.cursor().execute("CREATE TABLE vendors( stuff here )")
except lite.Error, e:
    print_progress("Failed to clean " + market + " listings, error %s:" % e.args[0])

size = len([name for name in os.listdir(path)])

count = 1
tot_scraped = 0
try:
    con = lite.connect(output_path + output_file)

    buf = 0;
    for f in listdir(path):

        # Update the progress
        update_progress(count, size)
        count = count + 1

    	# Load the file into a string
        with open(path + f, "r") as file:
            file_string = file.read()

    	# Parse the HTML
        tree = html.fromstring(file_string)

        tot_scraped = tot_scraped + 1

        # Write to database
        buf = buf + 1
    	if buf > buffer_limit:
                con.commit()
                buf = 0
except lite.Error, e:
    print_progress("Failed to insert into database, error %s:" % e.args[0])
finally:
    con.commit()
    con.close()

try:
    os.rename(output_path + output_file, output_path + final_output)
except OSError:
    pass

print_progress("Cleaned abraxas vendors, output in " + output_path + final_output)
print_progress("Scraped " + str(tot_scraped) + " out of " + str(count) + " vendors.")
