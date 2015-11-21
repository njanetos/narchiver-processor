import os

market = 'abraxas'

try:

	execfile('scripts/extract_data_listings_common.py')

	# Get total number of listings
	val = (read_cur.execute("SELECT Count(*) FROM listings").fetchall()[0])[0]

	# Get the price history
	print_progress("Aggregating reviews and prices...")
	tot_count, count = val, 0
	buf = 0
	for i in range(1, val):
		read_cur.execute("SELECT * FROM listings WHERE rowid = {0}".format(i))
		row = read_cur.fetchall()[0]

		# Get the listing id
 		listing_id = titles.index(row[1]) + 1

		# Add price in
		write_cur.execute("INSERT INTO prices VALUES({0}, {1}, {2})".format(row[0], listing_id, round(float(row[2]), 2)))
		count = count + 1
		update_progress(count, tot_count)

		# Get reviews
		reviews = row[4].split('.')

		# Find the day, in days since 1970, on which it was scraped
		days_since = int(row[0])//86400

		# Write to database
		for r in range(0, len(reviews)-1, 2):
			if "daysago" in reviews[r+1]:
				days_ago = int(reviews[r+1].replace("daysago", "").replace("(editafter", "  ")[0:2])
				date = days_since - days_ago
				write_cur.execute("INSERT INTO reviews VALUES({0}, {1}, '{2}', {3}, 0)".format(date, listing_id, str(days_ago), int(reviews[r][0])))
				buf = buf + 1
				if buf > buffer_limit:
					write.commit()
					buf = 0

	# Collapse duplicate rows
	print_progress("Not collapsing duplicate reviews...")

except lite.Error, e:
	print "Error %s:" % e.args[0]
finally:
	if write:
		write.commit()
		write.close()
	if read:
		read.close()

try:
    os.rename(os.path.join('aggregate_listings', 'temp.db'), os.path.join('aggregate_listings', market+'.db'))
except OSError:
    pass

print_progress("Finished aggregating, output in " + os.path.join('aggregate_listings', market+'.db'))
