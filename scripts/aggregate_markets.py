import os
import sqlite3 as lite
import sys
from update_progress import update_progress
from update_progress import print_progress
from clean_text import clean
import re

if not os.path.exists('aggregate_markets'):
    os.makedirs('aggregate_markets')

try:
	if os.path.exists('aggregate_markets/temp.db'):
		os.remove('aggregate_markets/temp.db')
except OSError:
	sys.exit(1)

buffer_limit = 10000

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
write_cur.execute('CREATE TABLE listings(title TEXT, vendor TEXT, category INT, ships_from INT, ships_to INT, units TEXT, amount REAL, quantity INT)')
write_cur.execute('CREATE TABLE categories(category TEXT)')
write_cur.execute('CREATE TABLE ships_from(location TEXT)')
write_cur.execute('CREATE TABLE ships_to(location TEXT)')
write_cur.execute('CREATE TABLE prices(dat INT, listing INT, price REAl)')
write_cur.execute('CREATE TABLE reviews(dat INT, listing INT, review TEXT, val INT, price REAL)')
write.commit()
