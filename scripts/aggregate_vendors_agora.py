import os
import sqlite3 as lite
import sys
from update_progress import update_progress
from update_progress import print_progress
from clean_text import clean
import re

market = 'agora'

if not os.path.exists('aggregate_vendors'):
    os.makedirs('aggregate_vendors')

try:
	if os.path.exists('aggregate_vendors/temp.db'):
		os.remove('aggregate_vendors/temp.db')
except OSError:
	sys.exit(1)

buffer_limit = 10000

try:
    read = lite.connect(os.path.join('clean_vendors', market+'.db'))
    read_cur = read.cursor()
    read_cur.execute('SELECT DISTINCT name FROM vendors')
    names = read_cur.fetchall()

    write = lite.connect(os.path.join('aggregate_vendors', 'temp.db'))
    write_cur = write.cursor()
    write_cur.execute('CREATE TABLE vendors(name TEXT)')
    write_cur.execute('CREATE TABLE reviews(vendor INT, val INT, content TEXT, product TEXT, dat INT)')
    write_cur.execute('CREATE TABLE ratings(vendor INT, val REAL, dat INT)')
    write_cur.execute('CREATE TABLE sales(vendor INT, val INT, dat INT)')
    write.commit()

    vendors = [c[0] for c in names]

    # Add all the categories
    print_progress("Writing vendors...")
    for c in vendors:
    	write_cur.execute("INSERT INTO vendors VALUES('{0}')".format(c))
    write.commit()

    # Get # of rows to sort
    read_cur.execute("SELECT Count(*) FROM vendors")
    row_count = read_cur.fetchall()[0][0]

    # Sort all the titles
    print_progress("Sorting reviews and ratings by vendor...")
    tot_count, count, tot_aggregated = row_count, 0, 0
    buf = 0

    for i in range(1, row_count):

        count = count + 1
        update_progress(count, tot_count)

        read_cur.execute("SELECT * FROM vendors WHERE rowid == {0}".format(i))

        row = read_cur.fetchall()[0]

        # Get the date
        date = row[0]

        # Get the vendor
        vendor_name = row[1]

        # Find the vendor's id
        # Add 1 b/c that's what SQLite uses
        vendor_id = vendors.index(vendor_name) + 1

        # Extract their rating
        rating = row[2].split(' ')[0]
        # Get rid of the period in front if necessary
        if (rating[0] == '.'):
            rating = rating[1:]
        # If they're zero, throw it out
        if (rating[0] == '0'):
            continue
        # Convert to number
        rating = float(rating)

        # Extract their sales.
        sales = row[2].split(' ')
        if len(sales) < 2:
            continue
        sales = sales[1].split('.')
        # Take the average if there are two
        if len(sales) > 1:
            sales = (int(sales[0]) + int(sales[1]))//2
        elif len(sales) == 1:
            sales = int(sales[0])

        # Write this to the database
        write_cur.execute("INSERT INTO ratings VALUES({0}, {1}, {2})".format(vendor_id, rating, date))
        write_cur.execute("INSERT INTO sales VALUES({0}, {1}, {2})".format(vendor_id, sales, date))
        buf = buf + 1

        # Extract their reviews
        review_raw = row[3].split("|")

        review_rating = review_raw[0::5]
        review_text = review_raw[1::5]
        review_product = review_raw[2::5]

        # Insert reviews
        for i in range(1, len(review_rating)):
            write_cur.execute("INSERT INTO reviews VALUES({0}, {1}, '{2}', '{3}', {4})".format(vendor_id, int(review_rating[i][1:]), review_text[i], review_product[i], date))
            buf = buf + 1

        if (buf > buffer_limit):
            buf = 0
            write.commit()

        tot_aggregated = tot_aggregated + 1

except lite.Error, e:
	print "Error %s:" % e.args[0]
finally:
    if write:
        write.commit()
        write.close()
    if read:
        read.close()

print_progress("Wrote " + str(tot_aggregated) + " out of " + str(row_count) + " to database.")

try:
    os.rename(os.path.join('aggregate_vendors', 'temp.db'), os.path.join('aggregate_vendors', market+'.db'))
except OSError:
    pass

print_progress("Finished aggregating, output in " + os.path.join('aggregate_vendors', market+'.db'))
