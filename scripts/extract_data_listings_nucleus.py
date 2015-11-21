import os

market = 'nucleus'

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

		# Find listing id
                listing_id = titles.index(row[1]) + 1

		# Add price in
		write_cur.execute("INSERT INTO prices VALUES({0}, {1}, {2}, '{3}')".format(row[0], listing_id, round(float(row[2]), 2), row))
		count = count + 1
		update_progress(count, tot_count)

		# Get reviews
		reviews = row[4].split('|')

		# Write to database
		for r in range(0, len(reviews)-1):

			rev = reviews[r]

			if (rev == '5' or rev == '4' or rev == '3' or rev == '2' or rev == '1' or rev == '0'):
				rating = int(rev)
				review_text = reviews[r+1]
				review_price = float(reviews[r+2])
				review_user = reviews[r+3]
				review_date = int(reviews[r+4])

				try:
					write_cur.execute("INSERT INTO reviews VALUES({0}, {1}, '{2}', {3}, {4})".format(review_date, listing_id, review_text, rating, review_price))
				except:
					continue

				buf = buf + 1
				if buf > buffer_limit:
					write.commit()
					buf = 0

	# Collapse duplicate rows
	print_progress("Collapsing duplicate reviews...")
	tot_reviews = (write_cur.execute("SELECT Count(*) FROM reviews").fetchall()[0])[0]
	write_cur.execute("DELETE FROM reviews WHERE rowid NOT IN (SELECT MAX(rowid) FROM reviews GROUP BY dat, listing, review, val, price)")
	remaining_reviews = (write_cur.execute("SELECT Count(*) FROM reviews").fetchall()[0])[0]
	print_progress("Kept " + str(remaining_reviews) + " out of " + str(tot_reviews))

	print_progress("Finished aggregating.")

except lite.Error, e:
	print "Error %s:" % e.args[0]
finally:
	if write:
		write.close()
	if read:
		read.close()

try:
    os.rename(os.path.join('extract_data_listings', 'temp.db'), os.path.join('extract_data_listings', market+'.db'))
except OSError:
    pass

print_progress("Finished aggregating, output in " + os.path.join('extract_data_listings', market+'.db'))
