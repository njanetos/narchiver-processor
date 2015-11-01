# Reads through all files in ..raw_by_site/agora/categories, and extracts price, name, vendor, title, popularity, etc.

import os
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

# Paths
path 		= 'raw_by_site/agora/listings/'
output_path 	= 'clean_listings/'
output_file 	= 'temp.db'
final_output    = 'agora.db'

try:
    os.remove(output_path + output_file)
except OSError:
    pass

if not os.path.exists(output_path):
    os.makedirs(output_path)

size = len([name for name in os.listdir(path)])

print_progress("Cleaning html files and putting information in sql format for agora market.")
print_progress("Connecting to " + output_file)

try:
    con = lite.connect(output_path + output_file)
    con.cursor().execute("CREATE TABLE listings(dat INT, title TEXT, price REAL, conversion REAL, vendor TEXT, reviews TEXT, category TEXT)")
except lite.Error, e:
    print_progress("Failed to clean agora listings, error %s:" % e.args[0])

count = 0;
for f in listdir(path):

    # Update the progress
    update_progress(count, size)
    count = count + 1

	# Load the file into a string
    with open(path + f, "r") as file:
        file_string = file.read().decode('utf-8').encode('ascii', errors='ignore')

	# Parse the HTML
    tree = html.fromstring(file_string)

	# Read title
    title = tree.xpath('//h1/text()')

    if (len(title) != 1):
        print_progress("Malprocessed title " + f)
        continue

    # Encode file in ASCII
    title = title[0]

    # Clean title
    title = clean(title)

	# Read price
    price = tree.xpath('//div[@style="text-align: left;"]/text()')

    if (len(price) != 1):
        print_progress("Malprocessed price " + f + len(price))
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

    # Read reviews
    reviews = tree.find_class('embedded-feedback-list')
    if (len(reviews) != 1):
        print_progress("Malprocessed reviews: " + f)
        continue

    reviews = clean(reviews[0].text_content()).replace(' ', '')

    try:
        con = lite.connect(output_path + output_file)
        con.cursor().execute("INSERT INTO listings VALUES({0}, '{1}', {2}, {3}, '{4}', '{5}', '{6}')".format(date, title, price, conversion, vendor, reviews, category))
        con.commit()
        con.close()
    except lite.Error, e:
        print_progress("Failed to clean agora listings, error %s:" % e.args[0])

try:
    os.rename(output_path + output_file, output_path + final_output)
except OSError:
    pass

print_progress("Cleaned agora listings, output in " + output_path + final_output)
