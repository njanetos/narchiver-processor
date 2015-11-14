import os
import sqlite3 as lite
import sys
from update_progress import update_progress
from update_progress import print_progress
from clean_text import clean
import re

market = 'agora'

if not os.path.exists('combined_market'):
    os.makedirs('combined_market')

try:
	if os.path.exists('combined_market/temp.db'):
		os.remove('combined_market/temp.db')
except OSError:
	sys.exit(1)

buffer_limit = 10000

try:
    read_ven = lite.connect(os.path.join('aggregate_vendors', market+'.db'))
    read_ven_cur = read_ven.cursor()

    read_list = lite.connect(os.path.join('aggregate_listings', market+'.db'))
    read_list_cur = read_list.cursor()

    write = lite.connect(os.path.join('combined_market', 'temp.db'))
    write_cur = write.cursor()
    write_cur.execute('CREATE TABLE vendors(name TEXT)')
    write_cur.execute('CREATE TABLE listings(title TEXT, vendor INT, category INT, ships_from INT, ships_to INT, units TEXT, amount REAL, quantity INT)')
    write_cur.execute('CREATE TABLE reviews(vendor INT, listing INT, val INT, dat INT)')
    write_cur.execute('CREATE TABLE ratings(vendor INT, val REAL, dat INT)')
    write_cur.execute('CREATE TABLE sales(vendor INT, val INT, dat INT)')
    write_cur.execute('CREATE TABLE categories(category TEXT)')
    write_cur.execute('CREATE TABLE ships_from(location TEXT)')
    write_cur.execute('CREATE TABLE ships_to(location TEXT)')
    write_cur.execute('CREATE TABLE prices(dat INT, listing INT, vendor INT, price REAl)')
    write.commit()

    # Copy in and cross-reference stuff!

    # Vendors
    read_ven_cur.execute('SELECT name FROM vendors')
    vendors = read_ven_cur.fetchall()
    vendors = [ v[0] for v in vendors ]

    for v in vendors:
        write_cur.execute("INSERT INTO vendors VALUES('{0}')".format(v))
    write.commit()

    # Listings
    read_list_cur.execute('SELECT * FROM listings')
    for l in read_list_cur.fetchall():
        # Find the vendor
        print vendors
        vendor_id = vendors.index(l[1])
        print vendor_id
        # write_cur.execute("INSERT INTO listings VALUES('{0}')".format(v))

    quit()

    # Ships_from

    # Ships_to

    # Prices

    # Categories

    # Sales

    # Reviews

    # Ratings
except lite.Error, e:
	print "Error %s:" % e.args[0]
finally:
    if write:
        write.commit()
        write.close()
    if read_ven:
        read_ven.close()
    if read_list:
        read_list.close()
