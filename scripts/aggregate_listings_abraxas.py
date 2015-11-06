import os

market = 'abraxas'

try:

	execfile('scripts/aggregate_listings_common.py')

	# Get total number of listings
	val = (read_cur.execute("SELECT Count(*) FROM listings").fetchall()[0])[0]

	# Get the price history
	print_progress("Aggregating reviews and prices...")
	tot_count, count = val, 0
	for i in range(1, val):
		read_cur.execute("SELECT * FROM listings WHERE rowid = {0}".format(i))
		row = read_cur.fetchall()[0]

		# Add price in
		write_cur.execute("INSERT INTO prices VALUES({0}, {1}, {2})".format(row[0], i, round(float(row[2]), 2)))
		write.commit()
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
				date = (days_since-days_ago)*86400
				write_cur.execute("INSERT INTO reviews VALUES({0}, {1}, '{2}', {3}, 0)".format(date*86400, i, "", int(reviews[r][0])))
				write.commit()

	# Collapse duplicate rows
	print_progress("Collapsing duplicate reviews...")
	tot_reviews = (write_cur.execute("SELECT Count(*) FROM reviews").fetchall()[0])[0]
	write_cur.execute("DELETE FROM reviews WHERE rowid NOT IN (SELECT MAX(rowid) FROM reviews GROUP BY dat, review)")
	remaining_reviews = (write_cur.execute("SELECT Count(*) FROM reviews").fetchall()[0])[0]
	print_progress("Kept " + str(remaining_reviews) + " out of " + str(tot_reviews))

except lite.Error, e:
	print "Error %s:" % e.args[0]
finally:
	if write:
		write.close()
	if read:
		read.close()

try:
    os.rename(os.path.join('aggregate_listings', 'temp.db'), os.path.join('aggregate_listings', market+'.db'))
except OSError:
    pass

print_progress("Finished aggregating, output in " + os.path.join('aggregate_listings', market+'.db'))
