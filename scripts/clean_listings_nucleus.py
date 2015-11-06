# Reads through all files in ..raw_by_site/agora/listings, and extracts price, name, vendor, title, popularity, etc.

import os

market = 'nucleus'

execfile('scripts/clean_listings_common.py')

try:
    con = lite.connect(output_path + output_file)
    con.cursor().execute("CREATE TABLE listings(dat INT, title TEXT, price REAL, vendor TEXT, reviews TEXT, category TEXT, ships_from TEXT, ships_to TEXT)")
except lite.Error, e:
    print_progress("Failed to clean " + market + " listings, error %s:" % e.args[0])

try:
    con = lite.connect(output_path + output_file)

    count = 0
    tot_scraped = 0
    buf = 0
    for f in listdir(path):

        # Update the progress
        update_progress(count, size)
        count = count + 1

        # Load the file into a string
        with open(path + f, "r") as file:
            file_string = file.read().decode('utf-8').encode('ascii', errors='ignore')

        # Parse the HTML
        try:
            tree = html.fromstring(file_string)
        except:
            continue

        # Read title
        title = tree.xpath('//div[@class="content"]/div/h2/text()')

        if (len(title) != 1):
            print_progress("Malprocessed title " + f)
            continue

        title = clean(title[0])

        # Read price
        price = tree.xpath('//form/table/tr/td/text()')
        if len(price) == 0:
            print_progress("Malprocessed price ")
            continue
        price = float(price[0])

        units = tree.xpath('//form/table/tr/td/strong/text()')[2]
        if not "USD" in units:
            print_process("Malprocessed price units " + f)
            continue

        vendor = tree.xpath('//form/table/tr/td/a/text()')
        if len(vendor) != 1:
            print_progress("Malprocessed vendor " + f)
            continue
        vendor = vendor[0]

        reviews = tree.xpath('//div[@class="content"]/div[@class="item"]/table[@class="table"]/tr/td/text()')
        reviews_strong = tree.xpath('//div[@class="content"]/div[@class="item"]/table[@class="table"]/tr/td/strong/text()')

        if len(reviews) > 0:
            try:
                reviews_strong = reviews_strong[4::2]
                review_text = [ clean(r.replace('\t', '')) for r in reviews[0::6] ]
                review_price = reviews[3::6]
                review_name = reviews[4::6]
                review_date = [ str(int(time.mktime(parse(r).timetuple()))) for r in reviews[5::6] ]
                reviews = [0] * 5 * len(review_date)
                reviews[0::5] = reviews_strong
                reviews[1::5] = review_text
                reviews[2::5] = review_price
                reviews[3::5] = review_name
                reviews[4::5] = review_date
                reviews = "|".join(reviews)
            except:
                reviews = ""
        else:
            reviews = ""

        category_top = tree.xpath('//div/ul/li[./ul]/a/text()')
        category_middle = tree.xpath('//div/ul/li/ul/li[./ul]/a/text()')
        category = ".".join(category_top + category_middle)
        category.replace(' ', '')

        # To do: Put this in!

        ships_from = ""
        ships_to = ""

        # Read the date
        date = f[0:10]

        # Insert into SQL

        con.cursor().execute("INSERT INTO listings VALUES({0}, '{1}', {2}, '{3}', '{4}', '{5}', '{6}', '{7}')".format(date, title, price, vendor, reviews, category, ships_from, ships_to))
        buf = buf + 1
        if buf == 500:
            con.commit()
            buf = 0
        tot_scraped = tot_scraped + 1

except lite.Error, e:
    print_progress("Failed to insert into database, error %s:" % e.args[0])
finally:
    con.commit()
    con.close()

try:
    os.rename(output_path + output_file, output_path + final_output)
except OSError:
    pass

print_progress("Cleaned " + market + " listings, output in " + output_path + final_output)
print_progress("Scraped " + str(tot_scraped) + " out of " + str(count) + " listings.")
