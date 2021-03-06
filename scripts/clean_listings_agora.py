# Reads through all files in ..raw_by_site/agora/listings, and extracts price, name, vendor, title, popularity, etc.

import os

market = 'agora'

exec(open('scripts/clean_listings_common.py').read())

try:
    con = lite.connect(output_path + output_file)
    con.cursor().execute("CREATE TABLE listings(dat INT, title TEXT, price REAL, vendor TEXT, reviews TEXT, category TEXT, ships_from TEXT, ships_to TEXT, rating REAL, min_sales INT, max_sales INT, url TEXT)")
except lite.Error as e:
    print_progress("Failed to clean " + market + " listings, error %s:" % e.args[0])

count = 0
tot_scraped = 0
try:
    con = lite.connect(output_path + output_file)
    buf = 0;
    for f in listdir(path):

        # Update the progress
        update_progress(count, size)
        count = count + 1

        # Load the file into a string
        with open(path + f, "r") as file:
            try:
                file_string = file.read()
            except OSError as e:
                # Some files are corrupted, try to fix this
                continue


        # Check if empty (some are empty for some reason)
        if not file_string:
            continue

        # Parse the HTML
        tree = html.fromstring(file_string)

        # Read title
        title = tree.xpath('//h1/text()')

        if (len(title) != 1):
            # print_progress("Malprocessed title " + f)
            continue

        # Encode file in ASCII
        title = title[0]

        # Clean title
        title = clean(title)

        # Read price
        price = tree.xpath('//div[@style="text-align: left;"]/text()')

        if (len(price) != 1):
            # print_progress("Malprocessed price " + f + str(len(price)))
            continue

        price = price[0]
        raw_price = price
        conversion = -1

        # Convert to USD if necessary
        if "BTC" in price:
            price = price.replace("BTC", "")
            price = float(price)
            try:
                conversion = re.search('(?<=fa-btc"></i> ).*?(?= USD)', file_string).group(0)
            except AttributeError:
                # print_progress("[clean_listings_agora]: Cannot find conversion rate " + f)
                continue
            conversion = float(conversion)
            price = price*conversion
        elif "USD" in price:
            price = price.replace("USD", "")
            price = float(price)
        else:
            # print_progress("Unrecognized currency: " + price)
            continue

        # Read vendor
        try:
            vendor = re.search('(?<=class="gen-user-link").*?(?=</a>)', file_string).group(0)
            vendor = re.search('(?<=>).*', vendor).group(0).replace(' ', '')
        except AttributeError:
            # print_progress("Cannot find vendor: " + f)
            vendor = ""

        # Read category
        category = tree.xpath('//div[@class="topnav-element"]/a/text()')
        category = ".".join(category)
        category = category.replace(' ', '')

        # Read the date
        date = f[0:10]

        # Read reviews
        reviews = tree.find_class('embedded-feedback-list')
        if (len(reviews) != 1):
            # print_progress("Malprocessed reviews: " + f)
            continue

        # Clean up reviews -- remove spaces, remove special characters, remove 'Feedback' from every listings.
        text = reviews[0].text_content().replace('/', 's')
        reviews = clean(re.sub("  +", ", ", text)[11:])

        # Get origin, destination
        ships = tree.xpath('//div[@class="product-page-ships"]/text()')
        ships = "".join(ships).replace(' ', '')

        ships_from = re.search('(?<=From:)(.*)(?=To:)', ships)
        ships_to = re.search('(?<=To:)(.*)', ships)

        # Get vendor rating, sales
        rating = tree.xpath('//span[@class="gen-user-ratings"]/text()')
        if len(rating) < 2:
            continue
        rating = rating[1].split(',')
        if len(rating) < 2:
            continue

        sales = rating[1]
        rating = rating[0]

        rating = float(rating.replace('/5', '').replace('~', ''))

        sales = sales.replace(' deals', '').split('~')
        if len(sales) < 2:
            continue
        min_sales = int(sales[0])
        max_sales = int(sales[1])

        if ships_from is None:
            ships_from = ""
        else:
            ships_from = clean(ships_from.group(0))

        if ships_to is None:
            ships_to = ""
        else:
            ships_to = clean(ships_to.group(0))

        # Insert into SQL
        con.cursor().execute("INSERT INTO listings VALUES({0}, '{1}', {2}, '{3}', '{4}', '{5}', '{6}', '{7}', {8}, {9}, {10}, '{11}')".format(date, title, price, vendor, reviews, category, ships_from, ships_to, rating, min_sales, max_sales, f.split('|')[1]))
        buf = buf + 1
        if buf > buffer_limit:
            con.commit()
            buf = 0
        tot_scraped = tot_scraped + 1

except lite.Error as e:
    print_progress("Failed to insert into database, error %s:" % e.args[0])
except:
    print_progress(f)
    exit()
finally:
    con.commit()
    con.close()

try:
    os.rename(output_path + output_file, output_path + final_output)
except OSError:
    pass

print_progress("Cleaned agora listings, output in " + output_path + final_output)
print_progress("Scraped " + str(tot_scraped) + " out of " + str(count) + " listings.")
