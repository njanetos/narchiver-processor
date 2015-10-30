# Reads through all files in ../categories, and extracts price, name, vendor, title, popularity, etc.

import os
from os import listdir
from os.path import isfile, join
from lxml import html
import requests

# Path to the category files
path = '../raw_categories/'

# Read them all into an array
all_files = [ f for f in listdir(path) if isfile(join(path, f)) ]

# HTML parser which extracts relevant info
for f in all_files:
	
	# Load the file into a string
	with open(path + f, "r") as file:
		file_string = file.read().replace('\n', '')

	# Parse the HTML
	tree = html.fromstring(file_string)

	# Identify which market this is from

	
