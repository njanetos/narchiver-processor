import os
import sqlite3 as lite
import sys
from update_progress import update_progress
from update_progress import print_progress
from clean_text import clean

if not os.path.exists('aggregate_listings'):
    os.makedirs('aggregate_listings')

try:
	if os.path.exists('aggregate_listings/temp.db'):
		os.remove('aggregate_listings/temp.db')
except OSError:
	sys.exit(1)

read = lite.connect(os.path.join('clean_listings', market+'.db'))
read_cur = read.cursor()
read_cur.execute('SELECT DISTINCT title, vendor, category, ships_from, ships_to FROM listings')
titles = read_cur.fetchall()
read_cur.execute('SELECT DISTINCT category FROM listings')
categories = read_cur.fetchall()
read_cur.execute('SELECT DISTINCT ships_from FROM listings')
ships_from = read_cur.fetchall()
read_cur.execute('SELECT DISTINCT ships_to FROM listings')
ships_to = read_cur.fetchall()

write = lite.connect(os.path.join('aggregate_listings', 'temp.db'))
write_cur = write.cursor()
write_cur.execute('CREATE TABLE listings(title TEXT, vendor TEXT, category INT, ships_from INT, ships_to INT)')
write_cur.execute('CREATE TABLE categories(category TEXT)')
write_cur.execute('CREATE TABLE ships_from(location TEXT)')
write_cur.execute('CREATE TABLE ships_to(location TEXT)')
write_cur.execute('CREATE TABLE prices(dat INT, listing INT, price REAl)')
write_cur.execute('CREATE TABLE reviews(dat INT, listing INT, review TEXT, val INT, price REAL)')
write.commit()

categories = [c[0] for c in categories]
ships_from = [c[0] for c in ships_from]
ships_to = [c[0] for c in ships_to]

# Add all the categories
print_progress("Extracting categories...")
for c in categories:
	write_cur.execute("INSERT INTO categories VALUES('{0}')".format(c))
write.commit()

print_progress("Extracting shipping locations...")
for c in ships_from:
	write_cur.execute("INSERT INTO ships_from VALUES('{0}')".format(c))
write.commit()

print_progress("Extracting ship to locations...")
for c in ships_to:
	write_cur.execute("INSERT INTO ships_to VALUES('{0}')".format(c))
write.commit()

# Sort all the titles
print_progress("Sorting titles by category...")
tot_count, count = len(titles), 0
for t in titles:
	write_cur.execute("INSERT INTO listings VALUES('{0}', '{1}', {2}, {3}, {4})".format(t[0], t[1], 1+categories.index(t[2]), 1+ships_from.index(t[3]), 1+ships_to.index(t[4])))
	write.commit()
	count = count + 1
	update_progress(count, tot_count)

# Clean out to just get titles
titles = [t[0] for t in titles]
