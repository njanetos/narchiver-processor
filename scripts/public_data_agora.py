# Imports
import copy
import csv
import datetime
import math
import numpy
import os
import pandas
from scipy.stats import norm
from scipy.optimize import minimize
from scipy.interpolate import interp2d
import statsmodels.api as stats
import statsmodels.formula.api as smf
import sqlite3
import warnings
from scripts.update_progress import update_progress
from scripts.update_progress import print_progress
from scripts.update_progress import ProgressBar

# Load the database
read = sqlite3.connect(os.path.join(os.getcwd(), 'combined_market/agora.db'))
read_cur = read.cursor()

print_progress("Fetching prices...")

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
                            p.rowid AS id,
                            p.min_sales AS min_sales,
                            p.max_sales AS max_sales
                        FROM prices AS p
                            LEFT JOIN listings AS l
                                ON p.listing == l.rowid""")
prices = read_cur.fetchall()

# Fetch categories
read_cur.execute("""SELECT *
                    FROM categories""")
categories = read_cur.fetchall()

print_progress("Fetching reviews...")

# Fetch reviews
read_cur.execute("""SELECT r.dat,
                           r.listing,
                           l.vendor,
                           l.category,
                           l.amount,
                           l.quantity,
                           r.matched_price,
                           r.rowid AS id
                        FROM reviews AS r
                            JOIN listings AS l
                                ON l.rowid == r.listing""")
reviews = read_cur.fetchall()

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

print_progress("Fetching listings...")

read_cur.execute("""SELECT l.rowid AS id,
                           l.category,
                           l.vendor,
                           l.units,
                           l.amount,
                           l.quantity,
                           l.ships_from,
                           l.ships_to,
                           COUNT(r.listing) AS num_reviews,
                           l.url
                    FROM listings AS l
                        JOIN reviews AS r
                            ON r.listing == l.rowid
                    GROUP BY r.listing""")
listings = read_cur.fetchall()

read_cur.execute("""SELECT l.rowid AS id,
                           l.category,
                           l.vendor,
                           l.units,
                           l.amount,
                           l.quantity,
                           l.ships_from,
                           l.ships_to,
                           0 AS num_reviews,
                           l.url
                    FROM listings AS l""")
all_listings = read_cur.fetchall()

read_cur.execute("SELECT * FROM ships_from")
ships_from = read_cur.fetchall()

read_cur.execute("SELECT * FROM ships_to")
ships_to = read_cur.fetchall()

# Close the connection
if read:
    read.close()

# Convert tuples to lists
prices =  [ list(p) for p in prices ]
reviews = [ list(r) for r in reviews ]

# Normalize prices and try to put things in the same units
for p in prices:
    p[9] = numpy.float64(p[4]) / (p[7]*p[6])
    if "g" in p[8]:
        p[9] = p[9]/1000
        p[8] = "mg"
        p[6] = p[6]*1000
    elif "kg" in p[8]:
        p[9] = p[9]/1000000
        p[8] = "mg"
        p[6] = p[6]*1000000
    elif "ug" in p[8]:
        p[9] = p[9]*1000
        p[8] = "mg"
        p[6] = p[6]/1000
    elif "oz" in p[8]:
        p[9] = p[9]/28349.5
        p[8] = "mg"
        p[6] = p[6]*28349.5
    elif "lb" in p[8]:
        p[9] = p[9]/453592
        p[8] = "mg"
        p[6] = p[6]*453592

# Read into panda data frame
names = ['DATE', 'CATEGORY', 'VENDOR', 'LISTING', 'PRICE',
         'RATING', 'AMOUNT', 'QUANTITY', 'UNITS', 'NORMALIZED',
         'ID', 'MIN_SALES', 'MAX_SALES']
prices = pandas.DataFrame(prices, columns = names)

names = ['DATE', 'LISTING', 'VENDOR', 'CATEGORY', 'AMOUNT', 'QUANTITY', 'MATCHED_PRICE', 'ID']
reviews = pandas.DataFrame(reviews, columns = names)

# Read listings into panda data frame
names = ['ID', 'CATEGORY', 'VENDOR', 'UNITS', 'AMOUNT',
         'QUANTITY', 'SHIPS_FROM', 'SHIPS_TO', 'NUM_REVIEWS', 'URL']
listings = pandas.DataFrame(listings, columns = names)
all_listings = pandas.DataFrame(all_listings, columns = names)
for i in listings['ID'].values:
    num_rev = listings[listings['ID'] == i]['NUM_REVIEWS'].values[0]
    all_listings.loc[all_listings['ID'] == i, 'NUM_REVIEWS'] = num_rev
listings = all_listings

# Read categories into panda data frame
names = ['NAME']
categories_ = pandas.DataFrame([c[0] for c in categories], columns = names)

# Join to matched price
reviews.drop('AMOUNT', axis=1, inplace=True)
reviews = pandas.merge(reviews, prices, left_on='MATCHED_PRICE', right_on='ID', suffixes=('', '_y'))
reviews.drop('DATE_y', axis=1, inplace=True)
reviews.drop('CATEGORY_y', axis=1, inplace=True)
reviews.drop('VENDOR_y', axis=1, inplace=True)
reviews.drop('LISTING_y', axis=1, inplace=True)
reviews.drop('ID', axis=1, inplace=True)
reviews.drop('MATCHED_PRICE', axis=1, inplace=True)
reviews.drop('QUANTITY', axis=1, inplace=True)
reviews.drop('ID_y', axis=1, inplace=True)

# Change from units to 'trusted price' dummy
reviews['FOUND_PRICE'] = reviews['UNITS'] == 'mg'
reviews.drop('UNITS', axis=1, inplace=True)

# Merge with listings
reviews = pandas.merge(reviews, listings, left_on='LISTING', right_on='ID', suffixes=('', '_y'))
reviews.drop('ID', axis=1, inplace=True)
reviews.drop('QUANTITY_y', axis=1, inplace=True)
reviews.drop('CATEGORY_y', axis=1, inplace=True)
reviews.drop('AMOUNT_y', axis=1, inplace=True)
reviews.drop('NUM_REVIEWS', axis=1, inplace=True)
reviews.drop('URL', axis=1, inplace=True)
reviews.drop('UNITS', axis=1, inplace=True)

# Read vendors in panda data frame
names = ['ID', 'NAME', 'NUM_REVIEWS']
vendors = pandas.DataFrame(vendors, columns = names)
vendors.drop('NAME', axis=1, inplace=True)

# Find min and max dates
min_date_days = min(reviews['DATE'])
max_date_days = max(reviews['DATE'])

# Put prices in terms of day observed at
prices['DATE'] = prices['DATE']/86400

# Throw away vendors who don't sell anything
vendors = vendors[vendors['NUM_REVIEWS'] > 0]

# Find dates entered, exited
# Find first review left for all vendors
vendors['ENTERED'] = 0
vendors['EXITED'] = 0
print_progress("Finding entry and exit dates for vendors...")
for v in set(reviews['VENDOR'].values):
    vendors.set_value(vendors['ID'] == v,
                      'ENTERED',
                      min(reviews[reviews['VENDOR'] == v]['DATE']))
    vendors.set_value(vendors['ID'] == v,
              'EXITED',
              max(reviews[reviews['VENDOR'] == v]['DATE']))

# Find the total number of things in each category
total_num = []
for c in range(1, len(categories)+1):
    total_num.append(len(reviews[reviews['CATEGORY'] == c]['CATEGORY'].values))

names = ['NAME', 'NUM_REVIEWS']
categories_ = pandas.DataFrame(list(map(list, zip(*[[c[0] for c in categories], total_num]))), columns = names)

# construct estimates of age, cumulative reviews, and sales rate, by vendor
reviews = reviews.sort_values('DATE')
reviews['WEEKLY_SALES'] = 0
reviews['WEEKLY_REVENUE'] = 0
reviews['REVIEWS'] = 1
r_vendor = reviews.groupby('VENDOR')

reviews['AGE'] = r_vendor['DATE'].transform(lambda x: x - min(x))
reviews['REVIEWS'] = r_vendor['REVIEWS'].transform(lambda x: x.cumsum())

# estimate of weekly sales rate
print_progress("Constructing weekly revenue and sales estimates...")

count = 0
tot_count = len(set(reviews['VENDOR'].values))
def roll(x):
    global count
    update_progress(count, tot_count)
    count = count + 1
    for i, row in x.iterrows():
        x_date = x[   (x['DATE'] >= x['DATE'][i]-4)
                    & (x['DATE'] <= x['DATE'][i]+4)].replace([numpy.inf, -numpy.inf], numpy.nan).dropna()
        x.set_value(i, 'WEEKLY_SALES', len(x_date['DATE'].values))
        x.set_value(i, 'WEEKLY_REVENUE', sum(x_date['PRICE'].values))
    return(x)

reviews[['WEEKLY_SALES', 'WEEKLY_REVENUE', 'DATE', 'PRICE']] = r_vendor[['WEEKLY_SALES', 'WEEKLY_REVENUE', 'DATE', 'PRICE']].transform(lambda x: roll(x))
reviews['VENDOR'] = reviews['VENDOR_y']
reviews.drop('VENDOR_y', axis=1, inplace=True)

print_progress("Save to csv...")
# Save these to csvs
reviews.to_csv('public_data/agora-reviews.csv')
# prices.to_csv('public_data/agora-prices.csv')
vendors.to_csv('public_data/agora-vendors.csv')
# rename categories to be more professional
categories_.to_csv('public_data/agora-categories.csv')

# construct balanced dataset
# Date bins
bins_date = [numpy.round(d) for d in numpy.linspace(min_date_days, max_date_days, num = 51)]
with open('public_data/agora-dates.csv', 'w') as f:
    writer = csv.writer(f)
    writer.writerows([[b] for b in bins_date])

bins_date = [b for b in zip(bins_date[0:-1], bins_date[1:])]


balanced_categories = {}

# Categories to focus on
#interesting_categories = [4, 35, 7, 17, 43, 38]
interesting_categories = [4, 50, 7, 26]

print_progress("Constructing balanced dataset...")

for category in interesting_categories:

    category_name = categories[category-1][0].split('.')[-1]

    # Extract data only selling in category_id
    prices_cat   = prices  [(prices['CATEGORY'] == category)]
    reviews_cat  = reviews [(reviews['CATEGORY'] == category)]
    listings_cat = listings[(listings['CATEGORY'] == category)]

    # Find extreme values
    upper = numpy.nanpercentile(prices_cat['NORMALIZED'], 90)
    lower = numpy.nanpercentile(prices_cat['NORMALIZED'], 10)

    prices_cat = prices_cat[prices_cat['NORMALIZED'] < upper]
    prices_cat = prices_cat[prices_cat['NORMALIZED'] > lower]

    vendors_cat = set(prices_cat['VENDOR'])

    balanced = pandas.DataFrame(columns = ['VENDOR', 'DATE', 'NORMALIZED', 'RATING', 'REVIEWS', 'SALES', 'QUANTITY', 'AMOUNT', 'REVIEWS'])

    print_progress("Category: " + category_name)

    for v in vendors_cat:
        prices_mask = prices_cat[prices_cat['VENDOR'] == v]
        reviews_mask = reviews_cat[reviews_cat['VENDOR'] == v]
        for date in bins_date:
            prices_date = prices_mask[   (prices_mask['DATE'] >= date[0])
                                       & (prices_mask['DATE'] <  date[1])]
            reviews_date = reviews_mask[ (reviews_mask['DATE'] >= date[0])
                                       & (reviews_mask['DATE'] <  date[1])]
            # Find the average of each value over this particular bin
            if (len(prices_date['NORMALIZED'].values) > 0):
                price             = numpy.mean(prices_date['NORMALIZED'].values)
                rating            = numpy.mean(prices_date['RATING'].values)
                sales             = numpy.mean(prices_date['MIN_SALES'].values)
                review            = len(reviews_date['DATE'].values)
                quantity          = numpy.nanmean(prices_date['QUANTITY'].values)
                amount            = numpy.nanmean(prices_date['AMOUNT'].values)
                reviews           = len(reviews_date['AMOUNT'].values)
            else:
                review     = 0
                price      = float('nan')
                rating     = float('nan')
                sales      = float('nan')
                quantity   = float('nan')
                amount     = float('nan')
                reviews    = 0

            rating_diff = 0

            balanced.loc[len(balanced)] = [v, date[0], price, rating, review, sales, quantity, amount, reviews]

    balanced = balanced.sort_values(by = ['VENDOR', 'DATE'])
    balanced['CATEGORY'] = category
    balanced_categories[category] = copy.deepcopy(balanced)

final_balanced = pandas.DataFrame(columns = ['VENDOR', 'DATE', 'NORMALIZED', 'RATING', 'REVIEWS', 'SALES', 'QUANTITY', 'AMOUNT', 'CATEGORY', 'REVIEWS'])
for cat in interesting_categories:
    final_balanced = final_balanced.append(balanced_categories[cat])

final_balanced.to_csv('public_data/agora-balanced.csv')
