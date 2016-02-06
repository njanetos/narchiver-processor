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
from lxml.html import fromstring, tostring

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
    con.cursor().execute("CREATE TABLE vendors( dat INT, name TEXT, rating TEXT, ratings TEXT )")
except lite.Error as e:
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

        name = tree.xpath('//div/strong/text()')

        if len(name) != 1:
            continue
        else:
            name = name[0]

        rating = tree.xpath('//span[@class="gen-user-ratings"]/text()')

        rating = [ r for r in rating if r != ' ']

        if len(rating) < 1:
            continue
        else:
            vendor_rating = clean(rating[0].replace('~', '.').replace('/', '.').replace(' deals', '').replace('.5, ', ' '))

        test = tree.xpath('//div[@class="embedded-feedback-list"]/table/tr/td//text()')
        test = [t for t in test if t.replace(' ', '') != '']

        vals_re = re.compile('[0-5]/[0-5]')
        days_ago_re = re.compile('[0-9]+ days ago')

        if len(test) > 0:
            rating_inds = [ind for ind, t in enumerate(test) if vals_re.match(t)]
            days_ago_inds = [ind for ind, t in enumerate(test) if days_ago_re.match(t)]
        else:
            continue

        # The only reviews which are really reviews are those which
        # are followed by a 'left X days ago' thing
        real_reviews_ind = [r for r in rating_inds if r + 3 in days_ago_inds]

        rating_vals    = [clean(test[t]) for t in real_reviews_ind]
        rating_text    = [clean(test[t+1]) for t in real_reviews_ind]
        rating_product = [clean(test[t+2]) for t in real_reviews_ind]
        rating_date    = [clean(test[t+3]) for t in real_reviews_ind]
        rating_rating  = [clean(test[t+5]) for t in real_reviews_ind]

        # interweave arrays
        ratings = [""]*len(rating_vals)*5
        ratings[0::5] = rating_vals
        ratings[1::5] = rating_text
        ratings[2::5] = rating_product
        ratings[3::5] = rating_date
        ratings[4::5] = rating_rating

        ratings = "|".join(ratings)

        # Read the date
        date = f[0:10]

        # Insert into SQL
        con.cursor().execute("INSERT INTO vendors VALUES({0}, '{1}', '{2}', '{3}')".format(date, name, vendor_rating, ratings))

        tot_scraped = tot_scraped + 1

        # Write to database
        buf = buf + 1
        if buf > buffer_limit:
                con.commit()
                buf = 0
except lite.Error as e:
    print_progress("Failed to insert into database, error %s:" % e.args[0])
finally:
    con.commit()
    con.close()

try:
    os.rename(output_path + output_file, output_path + final_output)
except OSError:
    pass

print_progress("Cleaned agora vendors, output in " + output_path + final_output)
print_progress("Scraped " + str(tot_scraped) + " out of " + str(count) + " vendors.")
