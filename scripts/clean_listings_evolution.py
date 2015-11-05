# Reads through all files in ..raw_by_site/evolution/categories, and extracts price, name, vendor, title, popularity, etc.

import os

market = 'evolution'

execfile('scripts/clean_listings_common.py')

try:
    con = lite.connect(output_path + output_file)
    con.cursor().execute("CREATE TABLE listings(dat INT, title TEXT, price REAL, vendor TEXT, reviews TEXT, category TEXT, vendor_rating TEXT, ships_from TEXT, ships_to TEXT)")
except lite.Error, e:
    print_progress("Failed to clean " + market + " listings, error %s:" % e.args[0])


count = 1
tot_scraped = 0
for f in listdir(path):

    # Update the progress
    update_progress(count, size)
    count = count + 1

    # Load the file into a string
    with open(path + f, "r") as file:
        file_string = file.read()

    # Parse the HTML
    tree = html.fromstring(file_string)

    # Read title
    title = tree.xpath('//h2/text()')

    if (len(title) != 1):
        # print_progress("Malprocessed title " + f)
        continue

    # Clean title
    title = title[0]
    title = clean(title)

	# Read price
    price = tree.xpath('//span[@class="price_row"]/span/text()')
    if (len(price) != 1):
        # print_progress("Malprocessed price " + f + " " + str(len(price)))
        continue

    # Get exchange rate
    exchange = [s for s in tree.xpath('//div[@class="well well-sm"]/ul/li[1]/text()') if "$" in s]
    if (len(exchange) != 1):
        # print_progress("Malprocessed exchange rate " + f + " " + str(len(exchange)))
        continue

    try:
        price = float(price[0][:-3])
        exchange = float(exchange[0][3:])
    except:
        # print_progress("Malprocessed price " + f)
        continue

    price = price*exchange

    # Get category
    category = tree.xpath('//ol[@class="breadcrumb"]/li/a/text()')
    if (len(category) == 0):
        # print_progress("Malprocessed category " + f + " " + str(len(category)))
        continue
    category = ".".join(category)

    # Get vendor
    vendor = tree.xpath('//div/span/a[@class="username"]/text()')
    if (len(vendor) != 1):
        # print_progress("Malprocessed vendor " + f + " " + str(len(vendor)))
        continue
    vendor = clean(vendor[0])

    # Get vendor's rating
    vendor_rating = [s for s in tree.xpath('//div/span/span[@class="rating"]/text()') if ("/" in s or "~" in s)]
    if (len(vendor_rating) != 2):
        # print_progress("Malprocessed vendor rating " + f + " " + str(len(vendor_rating)))
        continue
    vendor_rating = "".join(vendor_rating).replace(' ', '')

    # Get reviews
    review_value = tree.xpath('//table[@class="table table-hower table-static"]/tbody/tr/td/strong/text()')
    reviews_date = tree.xpath('//table[@class="table table-hower table-static"]/tbody/tr/td[@class="nowrap"]/text()')
    if (len(review_value) == 0):
        # print_progress("Malprocessed reviews " + f + " " + str(len(review_value)) + ", " + str(len(reviews_date)))
        continue

    if (review_value[0] == 'No feedbacks yet'):
        reviews = ""
    else:
        reviews = [""] * len(review_value)*2
        reviews[0::2] = review_value
        reviews[1::2] = reviews_date
        reviews = ".".join(reviews).replace(' ', '')

    # Get country of origin
    ships_from = tree.xpath('//div/strong[contains(text(), "Ships from:")]/text()')
    if (len(ships_from) == 0 or len(ships_from) > 2):
        ships_from = ""
    else:
        ships_from = clean("".join(ships_from).replace(' ', '').replace('Shipsfrom:', ''))

    # Get destination
    ships_to = tree.xpath('//div[@class="col-md-10 pull-right product"]/div/div[@class="col-sm-6"]/div[4]/text()')
    if (len(ships_to) != 1):
        ships_to = ""
    else:
        ships_to = clean("".join(ships_to).replace(' ', ''))

    # Read the date
    date = f[0:10]

    # Write to database
    try:
        con = lite.connect(output_path + output_file)
        con.cursor().execute("INSERT INTO listings VALUES({0}, '{1}', {2}, '{3}', '{4}', '{5}', '{6}', '{7}', '{8}')".format(date, title, price, vendor, reviews, category, vendor_rating, ships_from, ships_to))
        con.commit()
        con.close()
    except lite.Error, e:
        # print_progress("Failed to insert into database, error %s:" % e.args[0])
        continue

    tot_scraped = tot_scraped + 1
	
try:
    os.rename(output_path + output_file, output_path + final_output)
except OSError:
    pass

print_progress("Cleaned evolution listings, output in " + output_path + final_output)
print_progress("Scraped " + str(tot_scraped) + " out of " + str(count) + " listings.")
