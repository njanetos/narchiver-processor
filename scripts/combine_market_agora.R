list.of.packages <- c("sqldf", "data.table")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, repos='http://cran.us.r-project.org')

for (p in list.of.packages) {
    library(p, character.only = TRUE)
}

dblist = "extract_data_listings/agora.db"
dbvend = "extract_data_vendors/agora.db"

# Load lists of vendors seen in vendor pages, and listing pages, separately
vend_vendors = as.data.table(sqldf("SELECT name FROM vendors", dbname = dbvend))
list_vendors = as.data.table(sqldf("SELECT vendor AS name FROM listings", dbname = dblist))

# Compile them together and remove duplicates
# This is the final ordering of vendors
vendors_ = unique(rbind(vend_vendors, list_vendors))

# Load all categories
# This is the final ordering of categories
categories_ = as.data.table(sqldf("SELECT * FROM categories", dbname = dblist))

# Load shipping from, to locations
# Final ordering
ships_from_ = as.data.table(sqldf("SELECT * FROM ships_from", dbname = dblist))
ships_to_ = as.data.table(sqldf("SELECT * FROM ships_to", dbname = dblist))

# Load all listings
# Cross reference with vendors_ (categories, ships_from, ships_to should already be good)
# This is the final ordering of listings
tmp_size = sqldf("SELECT Count(*) FROM listings", dbname = dblist)
listings_ = as.data.table(sqldf("SELECT l.title, l.category, v.rowid AS vendor, l.units, l.amount, l.quantity, l.ships_from, l.ships_to, l.rowid AS ind 
                                 FROM listings AS l
                                 LEFT JOIN vendors_ AS v
                                    WHERE v.name == l.vendor", dbname = dblist))
if (tmp_size != length(listings_$title)) {
    warning("Shrinkage in listings!")
}

# Check to see if there's any difference between the rowid and the original index
# If so, something's fishy
# Otherwise, this is consistent and that column is removed
tmp = sum(abs(listings_$ind - 1:length(listings_$title)))
if (tmp != 0) {
    warning("Something went wrong in the listings.")
}
listings_ = subset(listings_, select = -c(ind))

# Load all prices
# Cross reference with listing titles
# If everything went right with the listings, this should almost be the final ordering.
prices = as.data.table(sqldf("SELECT p.dat, p.listing, l.vendor, p.max_sales, p.min_sales, p.price, p.rating FROM prices AS p
                               LEFT JOIN listings as l
                                   ON l.rowid == p.listing", dbname = dblist))

# Load reviews from the vendors
reviews_vendors = as.data.table(sqldf("SELECT r.dat, v.rowid AS vendor, r.val, r.content, r.max_user_sales, r.min_user_sales, r.product, r.scraped_at, r.user_rating FROM reviews AS r
                                       JOIN vendors AS db_v
                                           ON db_v.rowid == r.vendor
                                       JOIN vendors_ AS v
                                           ON v.name == db_v.name", dbname = dbvend))
# Test for shrinkage
if (sqldf("SELECT Count(*) FROM reviews", dbname = dbvend) != length(reviews_vendors$dat)) {
    warning("Shrinkage in reviews!")
}

# Cross reference with listings
reviews_vendors = as.data.table(sqldf("SELECT r.dat, r.vendor, l.ind AS listing, r.val, r.content, r.max_user_sales, r.min_user_sales, r.user_rating, r.scraped_at FROM reviews_vendors AS r
                                       LEFT JOIN (SELECT vendor, title, rowid AS ind FROM listings_ GROUP BY vendor, title) AS l
                                           ON (l.title == r.product AND l.vendor == r.vendor)"))

# Test for shrinkage
if (sqldf("SELECT Count(*) FROM reviews", dbname = dbvend) != length(reviews_vendors$dat)) {
    warning("Error with reviews!")
}

# Average the user sales
reviews_vendors$user_deals = (as.numeric(reviews_vendors$min_user_sales) + as.numeric(reviews_vendors$max_user_sales))/2
# Re-order so it's nice
reviews_vendors = subset(reviews_vendors, select = c(dat, vendor, listing, val, content, user_rating, user_deals, scraped_at))

# Load reviews from the listings
# If everything went right with the listing, we can use the same rowids
reviews_listings = as.data.table(sqldf("SELECT r.dat, l.vendor, r.listing, r.val, r.review AS content, r.user_rating, r.user_deals, r.scraped_at FROM reviews AS r
                                        LEFT JOIN listings_ AS l
                                            WHERE l.rowid == r.listing", dbname = dblist))

# Append them both on top of each other
reviews = rbind(reviews_listings, reviews_vendors)

# Remove duplicates
# Sort by date, date scraped at, content, and value.
# Delete everything which is on the same date, was scraped at different dates, and has the same value and content
reviews_ = sqldf("SELECT dat, vendor, listing, val, content, user_rating, user_deals, scraped_at, MAX(scraped_at) AS max FROM reviews GROUP BY dat, vendor, listing, val, content")
reviews_ = subset(reviews_, select = -c(max, scraped_at))
rm(reviews)

# Build smoothed estimates of daily sales rate from reviews
prices_temp = sqldf("SELECT *, p.rowid AS id FROM prices AS p")
prices_temp$dat = floor(prices_temp$dat / 86400)
reviews_temp = sqldf("SELECT r.dat, r.listing, l.category FROM reviews_ AS r LEFT JOIN listings_ AS l ON l.rowid == r.listing")
# Build estimate of aggregate reviews up to the time the price was scraped
prices_temp = as.data.table(sqldf("SELECT *, COUNT(r.rowid) AS prev FROM prices_temp AS p LEFT JOIN reviews_temp AS r ON r.dat <= p.dat AND r.listing == p.listing GROUP BY p.id"))

# Order the prices
prices_temp = prices_temp[order(prices_temp$dat),]

# Fit a smooth spline to every listing
# Fit 4 week ahead / behind averages of the growth rate
prices_temp$smooth_change = prices_temp$dat*NA
prices_temp$smooth_ahead_4 = prices_temp$dat*NA
prices_temp$smooth_behind_4 = prices_temp$dat*NA
x = split(prices_temp, f = as.factor(prices_temp$listing))
tot = length(names(x))
cat('Fitting smooth splines...')
for (i in 1:length(names(x))) {
    tryCatch({
        # Fit a smooth spline to review rate
        mod = smooth.spline(y = x[[i]]$prev, x = x[[i]]$dat, spar = 0.6)
        x[[i]]$smooth_change = predict(mod, deriv = 1)$y
        # Compute averages
        for (j in 1:length(x[[i]]$smooth_change)) {
            d = x[[i]]$dat[j]
            behind = x[[i]]$smooth_change[x[[i]]$dat > d - 28 & x[[i]]$dat <= d]
            ahead = x[[i]]$smooth_change[x[[i]]$dat < d + 28 & x[[i]]$dat >= d]
            x[[i]]$smooth_behind_4[j] = mean(behind)
            x[[i]]$smooth_ahead_4[j] = mean(ahead)
        }
    }, error = function(e) {})
    cat('\r')
    cat(paste('Progress: ', 100*round(i / tot, digits = 1), '%'), sep = '')
}
prices_ = as.data.table(unsplit(x, f = as.factor(prices_temp$listing)))
prices_ = subset(prices_, select = c("dat", "listing", "vendor", "max_sales", "min_sales", "price", "rating", "smooth_change", "smooth_behind_4", "smooth_ahead_4"))
# Write everything to the database

# Create the output path
dir.create("combined_market", showWarnings = FALSE)

dbout = "combined_market/agora.db"
file.remove(dbout)

db <- dbConnect(SQLite(), dbname = dbout)

sqldf("CREATE TABLE categories(category TEXT)", dbname = dbout)
sqldf("INSERT INTO categories SELECT * FROM categories_", dbname = dbout)

sqldf("CREATE TABLE listings(title TEXT, category INT, vendor INT, units TEXT, amount REAL, quantity INT, ships_from INT, ships_to INT)", dbname = dbout)
sqldf("INSERT INTO listings SELECT * FROM listings_", dbname = dbout)

sqldf("CREATE TABLE prices(dat INT, listing INT, vendor INT, max_sales INT, min_sales INT, price REAL, rating REAL, smooth_change REAL, smooth_behind_4 REAL, smooth_ahead_4 REAL)", dbname = dbout)
sqldf("INSERT INTO prices SELECT * FROM prices_", dbname = dbout)

sqldf("CREATE TABLE reviews(dat INT, vendor INT, listing INT, val INT, content TEXT, user_rating REAL, user_deals INT)", dbname = dbout)
sqldf("INSERT INTO reviews SELECT * FROM reviews_", dbname = dbout)

sqldf("CREATE TABLE ships_from(location TEXT)", dbname = dbout)
sqldf("INSERT INTO ships_from SELECT * FROM ships_from_", dbname = dbout)

sqldf("CREATE TABLE ships_to(location TEXT)", dbname = dbout)
sqldf("INSERT INTO ships_to SELECT * FROM ships_to_", dbname = dbout)

sqldf("CREATE TABLE vendors(name TEXT)", dbname = dbout)
sqldf("INSERT INTO vendors SELECT * FROM vendors_", dbname = dbout)

dbDisconnect(db)
