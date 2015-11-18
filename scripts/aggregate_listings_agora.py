import os

market = 'agora'

try:

	execfile('scripts/aggregate_listings_common.py')

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
		write_cur.execute("INSERT INTO prices VALUES({0}, {1}, {2}, {3}, {4}, {5})".format(row[0], listing_id, float(row[2]), row[8], row[9], row[10]))
		count = count + 1
		update_progress(count, tot_count)

		# Separate reviews and add them all in
		toke = [x.strip() for x in row[4].split(',')][1:]

		reviews = []
		for t in toke:
			# Check if there are no feedbacks
			if t == 'No feedbacks found.':
				continue
			# If it's a review, add on a new review row
			elif '55' == t or '45' == t or '35' == t or '25' == t or '15' == t or '05' == t:
				reviews.append([])
				reviews[-1].append(t[0])
				continue

			# Otherwise, append the info onto the end
			if len(reviews) > 0:
				reviews[-1].append(t)
			else:
				continue

		# Go through the reviews and find the day, in days since 1970, on which it was scraped
		days_since = int(row[0])//86400

		# Write to database
		for r in reviews:
			dates = [s for s in r if "days ago" in s]
			if len(dates) != 1:
				# print_progress("Malformed review date")
				continue
			dates = int(re.sub('[a-zA-Z ]', '', dates[0]))
			# Subtract to estimate days since
			date = days_since - dates

			if len(r) > 1:
				review_text = clean(r[1]);
			else:
				review_text = "N/A"

			write_cur.execute("INSERT INTO reviews VALUES({0}, {1}, '{2}', {3}, 0)".format(date, listing_id, review_text, int(r[0])))
			buf = buf + 1
			if buf > buffer_limit:
				write.commit()
				buf = 0

	# Collapse duplicate rows
	print_progress("Collapsing duplicate reviews...")
	tot_reviews = (write_cur.execute("SELECT Count(*) FROM reviews").fetchall()[0])[0]
	write_cur.execute("DELETE FROM reviews WHERE rowid NOT IN (SELECT MAX(rowid) FROM reviews GROUP BY dat, listing, review, val)")
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
    os.rename(os.path.join('aggregate_listings', 'temp.db'), os.path.join('aggregate_listings', market+'.db'))
except OSError:
    pass

print_progress("Finished aggregating, output in " + os.path.join('aggregate_listings', market+'.db'))
