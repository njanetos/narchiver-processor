list.of.packages <- c("sqldf", "data.table", "zoo")
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
cat('[combine_market_agora.R]: Sorted vendors\n')
vendors_ = unique(rbind(vend_vendors, list_vendors))

# Load all categories
# This is the final ordering of categories
cat('[combine_market_agora.R]: Sorted categories\n')
categories_ = as.data.table(sqldf("SELECT * FROM categories", dbname = dblist))

# Load shipping from, to locations
# Final ordering
cat('[combine_market_agora.R]: Sorted shipping locations\n')
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
cat('[combine_market_agora.R]: Sorted listings\n')

# Load all prices
# Cross reference with listing titles
# If everything went right with the listings, this should almost be the final ordering.
prices_ = as.data.table(sqldf("SELECT p.dat, p.listing, l.vendor, p.max_sales, p.min_sales, p.price, p.rating FROM prices AS p
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

# Re-order so it's nice
reviews_vendors = subset(reviews_vendors, select = c(dat, vendor, listing, val, content, user_rating, scraped_at))

# Load reviews from the listings
# If everything went right with the listing, we can use the same rowids
reviews_listings = as.data.table(sqldf("SELECT r.dat, l.vendor, r.listing, r.val, r.review AS content, r.user_rating, r.scraped_at FROM reviews AS r
                                        LEFT JOIN listings_ AS l
                                            WHERE l.rowid == r.listing", dbname = dblist))

# Append them both on top of each other
reviews = rbind(reviews_listings, reviews_vendors)

# Remove duplicates
# Sort by date, date scraped at, content, and value.
# Delete everything which is on the same date, was scraped at different dates, and has the same value and content
reviews_ = sqldf("SELECT dat, vendor, listing, val, content, user_rating, scraped_at, MAX(scraped_at) AS max FROM reviews GROUP BY dat, vendor, listing, val, content")
reviews_ = subset(reviews_, select = -c(max, scraped_at))
old_len = length(reviews$dat)
rm(reviews)
cat(paste('[combine_market_agora.R]: Sorted reviews, ', 100 - 100*round(length(reviews_$dat)/old_len, digits = 2), '% were found to be duplicates.\n', sep = ''))

# Build smoothed estimates of daily sales rate from reviews
prices_temp = as.data.table(sqldf("SELECT p.listing, p.dat, p.rowid AS id FROM prices_ AS p"))
prices_temp$dat = floor(prices_temp$dat / 86400)
reviews_temp = as.data.table(sqldf("SELECT r.dat, r.listing, l.category FROM reviews_ AS r LEFT JOIN listings_ AS l ON l.rowid == r.listing"))
# Build estimate of aggregate reviews up to the time the price was scraped
prices_temp = as.data.table(sqldf("SELECT p.listing, p.dat, p.id, COUNT(r.rowid) AS prev FROM prices_temp AS p LEFT JOIN reviews_temp AS r ON r.dat <= p.dat AND r.listing == p.listing GROUP BY p.id"))

# Order the prices
prices_temp = prices_temp[order(prices_temp$dat),]
prices_temp = prices_temp[order(prices_temp$id),]

# Fit a smooth spline to every listing, compute averages looking ahead
prices_temp$net_reviews_smooth = prices_temp$dat*NA
prices_temp$reviews_per_day = prices_temp$dat*NA
prices_temp$reviews_average_week = prices_temp$dat*NA
prices_temp$reviews_average_month = prices_temp$dat*NA
prices_temp$net_reviews = prices_temp$dat*NA
x = split(prices_temp, f = prices_temp$listing)
tot = length(names(x))
cat('[combine_market_agora.R]: Fitting smooth splines...\n')

for (i in 1:length(prices_temp$listing)) {
    tryCatch({
        # Eliminate duplicate entries
        x[[i]] = x[[i]][!duplicated(subset(x[[i]], select = c(listing, dat)))]
        
        # Fit a smooth spline
        mod = smooth.spline(y = x[[i]]$prev, x = x[[i]]$dat, spar = 0.6)
        
        # Read in the spline values
        x[[i]]$net_reviews_smooth = predict(mod, x[[i]]$dat, deriv = 0)$y
        x[[i]]$reviews_per_day = predict(mod, x[[i]]$dat, deriv = 1)$y
        x[[i]]$net_reviews = x[[i]]$prev
        
        # Do the horrids
        by_listing = zoo(c(NA, diff(x[[i]]$net_reviews, lag = 1)), as.Date(x[[i]]$dat))
        g = zoo(, seq(start(by_listing), end(by_listing), "day"))
        regular_by_listing = merge(by_listing, g)
        # Get week average
        temp = rollapply(regular_by_listing, 7, mean, align = "right", na.rm = TRUE, fill = NA)
        temp = merge(temp, by_listing, all = FALSE)
        x[[i]]$reviews_average_week = as.data.table(temp$temp)
        # Get month average
        temp = rollapply(regular_by_listing, 28, mean, align = "right", na.rm = TRUE, fill = NA)
        temp = merge(temp, by_listing, all = FALSE)
        x[[i]]$reviews_average_month = as.data.table(temp$temp)
    }, error = function(e) {})
    cat('\r')
    cat(paste('Progress: ', 100*round(i / tot, digits = 4), '%'), sep = '')
}
prices_temp = as.data.table(do.call(rbind, x))

# Re-create prices
prices_ = as.data.table(sqldf("SELECT p.dat, p.listing, q.vendor, q.max_sales, q.min_sales, q.price, q.rating, p.reviews_per_day, p.reviews_average_week, p.reviews_average_month, p.net_reviews, p.net_reviews_smooth FROM prices_temp AS p
                                    JOIN prices_ AS q ON q.rowid == p.id"))
cat('[combine_market_agora.R]: Sorted prices\n')

# Write everything to the database

# Create the output path
dir.create("combined_market", showWarnings = FALSE)

dbout = "combined_market/agora.db"
file.remove(dbout)

db <- dbConnect(SQLite(), dbname = dbout)

try({
    sqldf("DROP TABLE IF EXISTS categories")
    sqldf("CREATE TABLE categories(category TEXT)", dbname = dbout)
    sqldf("INSERT INTO categories SELECT * FROM categories_", dbname = dbout)
    
    sqldf("DROP TABLE IF EXISTS listings")
    sqldf("CREATE TABLE listings(title TEXT, category INT, vendor INT, units TEXT, amount REAL, quantity INT, ships_from INT, ships_to INT)", dbname = dbout)
    sqldf("INSERT INTO listings SELECT * FROM listings_", dbname = dbout)
    
    sqldf("DROP TABLE IF EXISTS prices")
    sqldf("CREATE TABLE prices(dat INT, listing INT, vendor INT, max_sales INT, min_sales INT, price REAL, rating REAL, reviews_per_day REAL, reviews_average_week REAL, reviews_average_month REAL, net_reviews INT, net_reviews_smooth REAL)", dbname = dbout)
    sqldf("INSERT INTO prices SELECT * FROM prices_", dbname = dbout)
    
    sqldf("DROP TABLE IF EXISTS reviews")
    sqldf("CREATE TABLE reviews(dat INT, vendor INT, listing INT, val INT, content TEXT, user_rating REAL, user_deals INT)", dbname = dbout)
    sqldf("INSERT INTO reviews SELECT * FROM reviews_", dbname = dbout)
    
    sqldf("DROP TABLE IF EXISTS ships_from")
    sqldf("CREATE TABLE ships_from(location TEXT)", dbname = dbout)
    sqldf("INSERT INTO ships_from SELECT * FROM ships_from_", dbname = dbout)
    
    sqldf("DROP TABLE IF EXISTS ships_to")
    sqldf("CREATE TABLE ships_to(location TEXT)", dbname = dbout)
    sqldf("INSERT INTO ships_to SELECT * FROM ships_to_", dbname = dbout)
    
    sqldf("DROP TABLE IF EXISTS vendors")
    sqldf("CREATE TABLE vendors(name TEXT)", dbname = dbout)
    sqldf("INSERT INTO vendors SELECT * FROM vendors_", dbname = dbout)
})

dbDisconnect(db)
