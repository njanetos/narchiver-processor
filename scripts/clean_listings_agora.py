# Reads through all files in ..raw_by_site/agora/categories, and extracts price, name, vendor, title, popularity, etc.

import os
from update_progress import update_progress
from update_progress import print_progress
import re
from os import listdir
from os.path import isfile, join
from lxml import html
import requests

# Paths
path 		= 'raw_by_site/agora/listings/'
output_path 	= 'clean/'
output_file 	= 'agora_listings.csv'
if not os.path.exists(output_path):
    os.makedirs(output_path)

# Loop through files and parse info
output = open(output_path + output_file, 'w+')

size = len([name for name in os.listdir(path)])

print_progress("Cleaning html files and putting information in csv format for agora market.")

count = 0;
for f in listdir(path):

        # Update the progress
	update_progress(count, size)
	count = count + 1

	# Load the file into a string
	with open(path + f, "r") as file:
		file_string = file.read()

	# Parse the HTML
	tree = html.fromstring(file_string)

	# Read title
	title = tree.xpath('//h1/text()')

	if (len(title) != 1): 
		print_progress("Malprocessed title " +  f)
		continue

	title = title[0]

	# Read price
	price = tree.xpath('//div[@style="text-align: left;"]/text()')

	if (len(price) != 1):
		print_progress("Malprocessed price " +  f +  len(price))
		continue

	price = price[0]
	raw_price = price
	conversion = -1

	# Convert to USD if necessary
	if "BTC" in price:
		price = price.replace("BTC", "")
		price = float(price)
		try:
			conversion = re.search('(?<=fa-btc"></i> ).*?(?= USD)', file_string).group(0)
		except AttributeError:
			print_progress("[clean_listings_agora]: Cannot find conversion rate " + f)
			continue
		conversion = float(conversion)
		price = price*conversion
	elif "USD" in price:
		price = price.replace("USD", "")
		price = float(price)
	else:
		print_progress("Unrecognized currency: " + price)
		continue
		
	# Read vendor
	try:
		vendor = re.search('(?<=class="gen-user-link").*?(?=</a>)', file_string).group(0)
		vendor = re.search('(?<=>).*', vendor).group(0).replace(' ', '')
	except AttributeError:
		print_progress("Cannot find vendor: " + f)
		continue

	# Read category
	category = tree.xpath('//div[@class="topnav-element"]/a/text()')
	category = ".".join(category)
	category = category.replace(' ', '')

	# Read the date
	date = f[0:10]

	# Write this all to a csv
	out = date + ", " + title + ", " + str(price) + ", " + str(raw_price) + ", " + str(conversion) + ", " + vendor + ", " + category + "\n"
	out = out.encode('ascii', errors='backslashreplace')
	output.write(out)	

output.close()
print_progress("Cleaned agora listings, output in " + output_path + output_file)
