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
    write_cur.execute('CREATE TABLE prices(dat INT, listing INT, vendor INT, price REAl, rating REAL)')
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
    print_progress("Cross-referencing ratings...")
    read_ven_cur.execute('SELECT * FROM ratings')
    ratings = [ v for v in read_ven_cur.fetchall() ]
    written, tot = 0, len(ratings)
    for v in ratings:
        update_progress(written, tot)
        write_cur.execute("INSERT INTO ratings VALUES({0}, {1}, {2})".format(v[0], v[1], v[2]))
        written = written + 1
    write.commit()
    print_progress("Ratings cross-referenced, leakage " + str(round(100*(1-float(written)/float(tot)), 2)) + '%')

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
    for p in prices:
        update_progress(written, tot)

        # Find the vendor
        try:
            l = listings[p[1]-1]
            vendor_id = vendors.index(l[1]) + 1
        except ValueError, e:
            continue

        # Find all the vendor's ratings
        try:
            vendor_ratings = [r for r in ratings if r[0] == vendor_id ]

            if len(vendor_ratings) == 0:
                # No ratings found
                rating = 0
            else:
                greater = [r[2] for r in vendor_ratings if r[2] < p[0]]
                lesser = [r[2] for r in vendor_ratings if r[2] > p[0]]

                if len(greater) != 0:
                    max_ind, max_val = max(enumerate(greater), key=operator.itemgetter(1))
                else:
                    max_ind, max_val = len(vendor_ratings)-1, vendor_ratings[-1][2]

                if len(lesser) != 0:
                    min_ind, min_val = min(enumerate(lesser), key=operator.itemgetter(1))
                else:
                    min_ind, min_val = 0, vendor_ratings[0][2]

                if max_val == min_val:
                    rating = vendor_ratings[min_ind][1]
                else:
                    mix = (float(p[0]) - float(min_val))/(float(max_val) - float(min_val))
                    rating = (1-mix)*vendor_ratings[max_ind][1] + mix*vendor_ratings[min_ind][1]
        except:
            continue


        write_cur.execute("INSERT INTO prices VALUES({0}, {1}, {2}, {3}, {4})".format(p[0], p[1], vendor_id, p[2], rating))
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

    # Sales
    print_progress("Cross-referencing sales...")
    read_ven_cur.execute('SELECT * FROM sales')
    sales = [ v for v in read_ven_cur.fetchall() ]
    written, tot = 0, len(sales)
    for v in sales:
        update_progress(written, tot)
        write_cur.execute("INSERT INTO sales VALUES({0}, {1}, {2})".format(v[0], v[1], v[2]))
        written = written + 1
    write.commit()
    print_progress("Sales cross-referenced, leakage " + str(round(100*(1-float(written)/float(tot)), 2)) + '%')

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
