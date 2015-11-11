import os
import sqlite3 as lite
import sys
from update_progress import update_progress
from update_progress import print_progress
from clean_text import clean
import re

if not os.path.exists('aggregate_vendors'):
    os.makedirs('aggregate_vendors')

try:
	if os.path.exists('aggregate_vendors/temp.db'):
		os.remove('aggregate_vendors/temp.db')
except OSError:
	sys.exit(1)

buffer_limit = 10000

# dat INT, name TEXT, rating TEXT, ratings TEXT
read = lite.connect(os.path.join('clean_vendors', market+'.db'))
read_cur.execute('SELECT DISTINCT name FROM vendors')
names = read_cur.fetchall()

write = lite.connect(os.path.join('aggregate_vendors', 'temp.db'))
write_cur = write.cursor()
write_cur.execute('CREATE TABLE vendors(name TEXT)')
write_cur.execute('CREATE TABLE reviews(vendor INT, val INT, content TEXT, product TEXT)')
write_cur.execute('CREATE TABLE ratings(vendor INT, val REAL, dat INT)')
write.commit()

vendors = [c[0] for c in names]

# Add all the categories
print_progress("Writing vendors...")
for c in vendors:
	write_cur.execute("INSERT INTO vendors VALUES('{0}')".format(c))
write.commit()

# Sort all the titles
print_progress("Sorting titles by category...")
tot_count, count = len(titles), 0
buf = 0
for t in titles:

    # Extract unit, amount, quantity info from the title
    try:
        temp = re.findall("([\.0-9]*[0-9]+ ?(?:g|mg|ug|kg|gr|lb|oz|ml))", t[0].lower())
        if (len(temp) != 0):
            units = re.sub('[0-9\. ]', '', temp[0])
            amount = float(re.sub('[a-z ]', '', temp[0]))
        else:
            units = ""
            amount = 0.0

        temp = re.findall("((x|pills) ?[,0-9]+|[,0-9]+ ?(x|pills))", t[0].lower())
        if (len(temp) != 0):
            quantity = int(re.sub('[a-z,]+', '', temp[0][0]))
        else:
            quantity = 1
    except:
        units = ""
        amount = 0.0
        quantity = 1


    write_cur.execute("INSERT INTO listings VALUES('{0}', '{1}', {2}, {3}, {4}, '{5}', {6}, {7})".format(t[0], t[1], 1+categories.index(t[2]), 1+ships_from.index(t[3]), 1+ships_to.index(t[4]), units, amount, quantity))

    buf = buf + 1
    if (buf > buffer_limit):
        buf = 0
        write.commit()
    count = count + 1
    update_progress(count, tot_count)

# Clean out to just get titles
titles = [t[0] for t in titles]
