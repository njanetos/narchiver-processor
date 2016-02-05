# Imports
import numpy
from scipy.stats import norm
from scipy.optimize import minimize
from scipy.interpolate import interp2d
import scipy.stats
import time
from numpy import around
import pandas
import statsmodels.api as stats
import statsmodels.formula.api as smf
import sqlite3
import os
from math import log
from collections import Counter
import datetime
import copy
from update_progress import update_progress
from update_progress import print_progress

pandas.options.mode.chained_assignment = None

print_progress('Loading combined_market database...')

# Load the database
read = sqlite3.connect(os.path.join(os.getcwd(), 'combined_market/agora.db'))
read_cur = read.cursor()

# Fetch all price information
read_cur.execute(""" SELECT p.dat AS dat,
                            l.category AS category,
                            l.vendor AS vendor,
                            p.listing AS listing,
                            p.price AS price,
                            p.rating AS rating,
                            l.amount AS amount,
                            l.quantity AS quantity,
                            l.units AS units,
                            p.dat AS normalized,
                            p.dat AS log_normalized,
                            p.rowid AS id,
                            p.min_sales AS min_sales,
                            p.max_sales AS max_sales
                        FROM prices AS p
                            LEFT JOIN listings AS l
                                ON p.listing == l.rowid""")
prices = read_cur.fetchall()

print_progress('Loaded prices...')

# Fetch categories
read_cur.execute("""SELECT *
                    FROM categories""")
categories = read_cur.fetchall()

print_progress('Loaded categories...')

# Fetch reviews
read_cur.execute("""SELECT r.dat,
                           r.listing,
                           l.vendor,
                           l.category,
                           r.rowid AS id
                        FROM reviews AS r
                            JOIN listings AS l
                                ON l.rowid == r.listing""")
reviews = read_cur.fetchall()

print_progress('Loaded reviews...')

read_cur.execute("""SELECT v.rowid AS id,
                           v.*,
                           COUNT(v.rowid) AS num_reviews
                    FROM vendors AS v
                        JOIN listings AS l
                            ON l.vendor == v.rowid
                        JOIN reviews AS r
                            ON r.listing == l.rowid
                    GROUP BY v.rowid""")
vendors = read_cur.fetchall()

print_progress('Loaded vendors')

read_cur.execute("""SELECT l.rowid AS id,
                           l.*,
                           COUNT(r.listing) AS num_reviews
                    FROM listings AS l
                        JOIN reviews AS r
                            ON r.listing = l.rowid
                    GROUP BY r.listing""")
listings = read_cur.fetchall()

print_progress('Loaded listings...')

read_cur.execute("SELECT * FROM ships_from")
ships_from = read_cur.fetchall()

read_cur.execute("SELECT * FROM ships_to")
ships_to = read_cur.fetchall()

print_progress('Loaded shipping information...')

# Close the connection
if read:
    read.close()

# Convert tuples to lists
prices =  [ list(p) for p in prices ]
reviews = [ list(r) for r in reviews ]

# Drop impossible values
prices =  [ p for p in prices if p[6] != 0 and p[7] != 0 ]

print_progress('Loaded from combined_market')

# Normalize prices and try to put things in the same units
for p in prices:
    p[11] = p[4] / (p[7]*p[6])

    if "g" in p[8]:
        p[11] = p[11]/1000
        p[8] = "mg"
        p[6] = p[6]*1000
    elif "kg" in p[8]:
        p[11] = p[11]/1000000
        p[8] = "mg"
        p[6] = p[6]*1000000
    elif "ug" in p[8]:
        p[11] = p[11]*1000
        p[8] = "mg"
        p[6] = p[6]/1000
    elif "oz" in p[8]:
        p[11] = p[11]/28349.5
        p[8] = "mg"
        p[6] = p[6]*28349.5
    elif "lb" in p[8]:
        p[11] = p[11]/453592
        p[8] = "mg"
        p[6] = p[6]*453592

    # Compute logs
    p[12] = log(p[11])

# Select the stuff we normalized
prices = [ p for p in prices if 'mg' in p[8]]

# Read into panda data frame
names = ['DATE', 'CATEGORY', 'VENDOR', 'LISTING', 'PRICE',
         'RATING', 'AMOUNT', 'QUANTITY', 'UNITS', 'NORMALIZED',
         'LOG_NORMALIZED', 'ID', 'MIN_SALES', 'MAX_SALES']
_prices = pandas.DataFrame(prices, columns = names)

names = ['DATE', 'LISTING', 'CATEGORY', 'VENDOR', 'ID']
_reviews = pandas.DataFrame(reviews, columns = names)

# Read listings into panda data frame
names = ['ID', 'TITLE', 'CATEGORY', 'VENDOR', 'UNITS', 'AMOUNT',
         'QUANTITY', 'SHIPS_FROM', 'SHIPS_TO', 'NUM_REVIEWS', 'URL']
_listings = pandas.DataFrame(listings, columns = names)

# Read vendors in panda data frame
names = ['ID', 'NAME', 'NUM_REVIEWS']
_vendors = pandas.DataFrame(vendors, columns = names)

print_progress('Constructed normalized prices')

# Find min and max dates
min_date_days = min(_reviews['DATE'])
max_date_days = max(_reviews['DATE'])

# Construct a balanced dataset

interesting_categories = [2, 3, 4, 6, 7, 9, 17, 22, 23, 35, 43]

print_progress('Constructing balanced panel dataset...')

balanced_categories = pandas.DataFrame(columns = ['VENDOR', 'DATE', 'NORMALIZED', 'RATING', 'REVIEWS', 'SALES', 'CATEGORY'])

tot = len(interesting_categories)
prog = 0

for category_id in interesting_categories:

    vendors = copy.deepcopy(_vendors)

    prices_cat   = _prices  [_prices  ['CATEGORY'] == category_id]
    reviews_cat  = _reviews [_reviews ['CATEGORY'] == category_id]
    listings_cat = _listings[_listings['CATEGORY'] == category_id]

    # Throw out extreme prices (higher than $1000 / gram)
    prices_cat = prices_cat[prices_cat['NORMALIZED'] < 0.2]

    # Count the number of reviews for each vendor
    for v in vendors['ID']:
        vendors.set_value(_vendors['ID'] == v, 'NUM_REVIEWS', len(reviews_cat[reviews_cat['VENDOR'] == v]))

    # Count the number of reviews for each listing
    for l in listings_cat['ID']:
        listings_cat.set_value(listings_cat['ID'] == l, 'NUM_REVIEWS', len(reviews_cat[reviews_cat['LISTING'] == l]))

    # Throw out vendors who don't sell stuff
    vendors = vendors[vendors['NUM_REVIEWS'] > 0]

    # Construct a balanced panel data set for each vendor
    bins_date = [numpy.round(d) for d in numpy.linspace(min_date_days, max_date_days, num = 35)]
    bins_date = [b for b in zip(bins_date[0:-1], bins_date[1:])]

    balanced = pandas.DataFrame(columns = ['VENDOR', 'DATE', 'NORMALIZED', 'RATING', 'REVIEWS', 'SALES', 'CATEGORY'])

    for v in set(vendors['ID']):
        prices_mask = prices_cat[prices_cat['VENDOR'] == v]
        reviews_mask = reviews_cat[reviews_cat['VENDOR'] == v]
        for date in bins_date:
            prices_date = prices_mask[   (prices_mask['DATE'] >= date[0])
                                       & (prices_mask['DATE'] <  date[1])]
            reviews_date = reviews_mask[ (reviews_mask['DATE'] >= date[0])
                                       & (reviews_mask['DATE'] <  date[1])]
            # Find the average of each value over this particular bin
            if (len(prices_date['DATE'].values) > 0):
                price             = numpy.mean(prices_date['NORMALIZED'].values)
                rating            = numpy.mean(prices_date['RATING'].values)
                sales             = numpy.mean(prices_date['MIN_SALES'].values)
                reviews           = len(reviews_date['RATING'].values)
            else:
                # reviews = float('nan')
                reviews = 0
                price = float('nan')
                rating = float('nan')
                sales = float('nan')

            rating_diff = 0

            balanced.loc[len(balanced)] = [int(v), int(date[0]), price, rating, int(reviews), sales, int(category_id)]

    balanced = balanced.sort_values(by = ['VENDOR', 'DATE'])

    prog = prog + 1
    update_progress(prog, tot)

    # Add to the full mix
    balanced_categories = balanced_categories.append(balanced)

# Write to csv
if not os.path.exists('balanced_panel'):
    os.makedirs('balanced_panel')

balanced_categories.to_csv('balanced_panel/agora.csv')

print_progress('Balanced panel data constructed')
