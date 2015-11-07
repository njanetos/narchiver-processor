from update_progress import update_progress
from update_progress import print_progress
import re
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

# Paths
path            = 'raw_by_site/' + market + '/listings/'
output_path 	= 'clean_listings/'
output_file 	= 'temp.db'
final_output    = market + '.db'

buffer_limit = 10000

try:
    os.remove(output_path + output_file)
except OSError:
    pass

if not os.path.exists(output_path):
    os.makedirs(output_path)

size = len([name for name in os.listdir(path)])

print_progress("Cleaning html files and putting information in sql format for " + market + " market.")
print_progress("Connecting to " + output_file)
