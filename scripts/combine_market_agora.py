import os
import sqlite3 as lite
import sys
from update_progress import update_progress
from update_progress import print_progress
from clean_text import clean
import re
import operator

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
    read_ven = lite.connect(os.path.join('extract_data_vendors', market+'.db'))
    read_ven_cur = read_ven.cursor()

    read_list = lite.connect(os.path.join('extract_data_listings', market+'.db'))
    read_list_cur = read_list.cursor()

    write = lite.connect(os.path.join('combined_market', 'temp.db'))
    write_cur = write.cursor()
    write_cur.execute('CREATE TABLE vendors(name TEXT)')
    write_cur.execute('CREATE TABLE listings(title TEXT, vendor INT, category INT, ships_from INT, ships_to INT, units TEXT, amount REAL, quantity INT)')
    write_cur.execute('CREATE TABLE reviews(vendor INT, listing INT, val INT, dat INT)')
    write_cur.execute('CREATE TABLE categories(category TEXT)')
    write_cur.execute('CREATE TABLE ships_from(location TEXT)')
    write_cur.execute('CREATE TABLE ships_to(location TEXT)')
    write_cur.execute('CREATE TABLE prices(dat INT, listing INT, vendor INT, price REAl, rating REAL, min_sales INT, max_sales INT)')
    write.commit()

    # Copy in and cross-reference stuff!

    # Vendors
    print_progress("Cross-referencing vendors...")
    read_ven_cur.execute('SELECT name FROM vendors')
    vendors = [ v[0] for v in read_ven_cur.fetchall() ]
    written, tot = 0, len(vendors)
    for v in vendors:
        update_progress(written, tot)
        write_cur.execute("INSERT INTO vendors VALUES('{0}')".format(v))
        written = written + 1
    write.commit()
    print_progress("Vendors cross-referenced, leakage " + str(round(100*(1-float(written)/float(tot)), 2)) + '%')

    # Ships_from
    print_progress("Cross-referencing ships_from...")
    read_list_cur.execute('SELECT location FROM ships_from')
    ships_from = [ v[0] for v in read_list_cur.fetchall() ]
    written, tot = 0, len(ships_from)
    for v in ships_from:
        update_progress(written, tot)
        write_cur.execute("INSERT INTO ships_from VALUES('{0}')".format(v))
        written = written + 1
    write.commit()
    print_progress("ships_from cross-referenced, leakage " + str(round(100*(1-float(written)/float(tot)), 2)) + '%')

    # Ships_to
    print_progress("Cross-referencing ships_to...")
    read_list_cur.execute('SELECT location FROM ships_to')
    ships_to = [ v[0] for v in read_list_cur.fetchall() ]
    written, tot = 0, len(ships_to)
    for v in ships_to:
        update_progress(written, tot)
        write_cur.execute("INSERT INTO ships_to VALUES('{0}')".format(v))
        written = written + 1
    write.commit()
    print_progress("ships_to cross-referenced, leakage " + str(round(100*(1-float(written)/float(tot)), 2)) + '%')

    # Ratings
    read_ven_cur.execute('SELECT * FROM ratings')
    ratings = [ v for v in read_ven_cur.fetchall() ]

    # Sales
    read_ven_cur.execute('SELECT * FROM sales')
    sales = [ v for v in read_ven_cur.fetchall() ]

    # Listings
    print_progress("Cross-referencing listings...")
    read_list_cur.execute('SELECT * FROM listings')
    listings = read_list_cur.fetchall()
    written, tot = 0, len(listings)
    for l in listings:
        update_progress(written, tot)
        # Find the vendor
        try:
            vendor_id = vendors.index(l[1])
        except ValueError, e:
            continue
        # Insert the new listings object with vendor name replaced by id
        write_cur.execute("INSERT INTO listings VALUES('{0}', {1}, {2}, {3}, {4}, '{5}', {6}, {7})".format(l[0], vendor_id, l[2], l[3], l[4], l[5], l[6], l[7]))
        written = written + 1
    write.commit()
    print_progress("Listings cross-referenced, leakage " + str(round(100*(1-float(written)/float(tot)), 2)) + '%')

    # Prices
    print_progress("Cross-referencing prices...")
    read_list_cur.execute('SELECT * FROM prices')
    prices = read_list_cur.fetchall()
    written, tot = 0, len(prices)
    buf = 0
    for p in prices:
        update_progress(written, tot)

        write_cur.execute("INSERT INTO prices VALUES({0}, {1}, {2}, {3}, {4}, {5}, {6})".format(p[0], p[1], vendor_id, p[2], p[3], p[4], p[5]))
        buf = buf + 1
        if buf > buffer_limit:
            write.commit()
            buf = 0
        written = written + 1
    write.commit()
    print_progress("Prices cross-referenced, leakage " + str(round(100*(1-float(written)/float(tot)), 2)) + '%')

    # Categories
    print_progress("Cross-referencing categories...")
    read_list_cur.execute('SELECT * FROM categories')
    categories = [ v[0] for v in read_list_cur.fetchall() ]
    written, tot = 0, len(categories)
    for v in categories:
        update_progress(written, tot)
        write_cur.execute("INSERT INTO categories VALUES('{0}')".format(v))
        written = written + 1
    write.commit()
    print_progress("Categories cross-referenced, leakage " + str(round(100*(1-float(written)/float(tot)), 2)) + '%')


    # Reviews
    # TODO Fill this in

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

try:
    os.rename(os.path.join('combined_market', 'temp.db'), os.path.join('combined_market', market+'.db'))
except OSError:
    pass

print_progress("Finished combining databases for the " + market + " market.")
