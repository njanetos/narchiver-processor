import numpy
from numpy import around
import pandas
import statsmodels.api as stats
import statsmodels.formula.api as smf
import sqlite3
import os
from math import log
import matplotlib.pyplot as plt
from collections import Counter
import datetime
import matplotlib.dates as mdates

pandas.options.mode.chained_assignment = None 

# Load the database
read = sqlite3.connect(os.path.join(os.getcwd(), '../combined_market/agora.db'))
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
                            p.reviews_per_day AS reviews_per_day,
                            p.vendor_reviews_per_day AS vendor_reviews_per_day,
                            p.dat AS normalized,
                            p.dat AS log_normalized,
                            p.rowid AS id
                        FROM prices AS p
                            LEFT JOIN listings AS l
                                ON p.listing == l.rowid""")
prices = read_cur.fetchall()

# Fetch categories
read_cur.execute("""SELECT * 
                    FROM categories""")
categories = read_cur.fetchall()

# Fetch reviews
read_cur.execute("""SELECT r.dat, 
                           l.category,
                           l.vendor, 
                           r.listing, 
                           p.price,
                           p.rating,
                           l.amount,
                           l.quantity,
                           l.units,
                           p.reviews_per_day,
                           p.vendor_reviews_per_day,
                           p.dat AS normalized,
                           p.dat AS log_normalized,
                           r.rowid AS id
                        FROM reviews AS r
                            JOIN listings AS l
                                ON l.rowid == r.listing
                            JOIN prices AS p
                                ON p.rowid == r.matched_price""")
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

read_cur.execute("""SELECT l.rowid AS id, 
                           l.*,
                           COUNT(r.listing) AS num_reviews
                    FROM listings AS l
                        JOIN reviews AS r
                            ON r.listing = l.rowid
                    GROUP BY r.listing""")
listings = read_cur.fetchall()

# Close the connection
if read:
    read.close()
    
# Convert tuples to lists
prices =  [ list(p) for p in prices ]
reviews = [ list(r) for r in reviews ]

# Drop impossible values
prices =  [ p for p in prices if p[6] != 0 and p[7] != 0 ]
reviews = [ r for r in reviews if r[6] != 0 and r[7] != 0 ]

# Normalize prices and try to put things in the same units
for p in prices:
    p[11] = p[4] / (p[7]*p[6])
    
    if "g" in p[8]:
        p[11] = p[11]/1000
        p[8] = "mg"
    elif "kg" in p[8]:
        p[11] = p[11]/1000000
        p[8] = "mg"
    elif "ug" in p[8]:
        p[11] = p[11]*1000
        p[8] = "mg"
    elif "oz" in p[8]:
        p[11] = p[11]/28349.5
        p[8] = "mg"
    elif "lb" in p[8]:
        p[11] = p[11]/453592
        p[8] = "mg"
        
    # Compute logs
    p[12] = log(p[11])
    
# Normalize reviews and try to put things in the same units
for r in reviews:
    r[11] = r[4] / (r[7]*r[6])
    
    if "g" in r[8]:
        r[11] = r[11]/1000
        r[8] = "mg"
    elif "kg" in r[8]:
        r[11] = r[11]/1000000
        r[8] = "mg"
    elif "ug" in r[8]:
        r[11] = r[11]*1000
        r[8] = "mg"
    elif "oz" in r[8]:
        r[11] = r[11]/28349.5
        r[8] = "mg"
    elif "lb" in r[8]:
        r[11] = r[11]/453592
        r[8] = "mg"
        
    # Compute logs
    r[12] = log(r[11])
    
# Select the stuff we normalized
prices = [ p for p in prices if 'mg' in p[8] ]
reviews = [ r for r in reviews if 'mg' in r[8] ]

# Read into panda data frame
names = ['DATE', 'CATEGORY', 'VENDOR', 'LISTING', 'PRICE', 
         'RATING', 'AMOUNT', 'QUANTITY', 'UNITS', 'REVIEWS_PER_DAY', 
         'V_REVIEWS_PER_DAY', 'NORMALIZED', 'LOG_NORMALIZED', 'ID']
prices = pandas.DataFrame(prices, columns = names)
reviews = pandas.DataFrame(reviews, columns = names)

# Read listings into panda data frame
names = ['ID', 'TITLE', 'CATEGORY', 'VENDOR', 'UNITS', 'AMOUNT', 
         'QUANTITY', 'SHIPS_FROM', 'SHIPS_TO', 'NUM_REVIEWS']
listings = pandas.DataFrame(listings, columns = names)

# Read vendors in panda data frame
names = ['ID', 'NAME', 'NUM_REVIEWS']
vendors = pandas.DataFrame(vendors, columns = names)

# Get min, max dates
min_date = datetime.datetime.fromtimestamp(min(prices['DATE'])*86400)
max_date = datetime.datetime.fromtimestamp(max(prices['DATE'])*86400)

