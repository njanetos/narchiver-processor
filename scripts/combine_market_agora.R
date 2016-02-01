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
listings_ = as.data.table(sqldf("SELECT l.title, l.category, v.rowid AS vendor, l.units, l.amount, l.quantity, sf.location AS ships_from, l.ships_to, l.rowid AS ind, l.url
                                 FROM listings AS l
                                 JOIN vendors_ AS v
                                    ON v.name == l.vendor
                                 JOIN ships_from AS sf
                                    ON sf.rowid == l.ships_from
                                 JOIN ships_to AS st
                                    ON st.rowid == l.ships_to", dbname = dblist))
if (tmp_size != length(listings_$title)) {
    warning("Shrinkage in listings!")
}

# Construct ships_from and ships_to by filtering out weird stuff

# First, make it all lowercase
listings_$ships_from = tolower(listings_$ships_from)
listings_$ships_to = tolower(listings_$ships_to)

# Now start to replace as much random crap as possible
listings_$ships_from[listings_$ships_from == "thehomeofthebodybags,shotty,andmag"] = "usa"
listings_$ships_from[listings_$ships_from == "thenetherlands"] = "netherlands"
listings_$ships_from[listings_$ships_from == "thenetherlandsgermany"] = "netherlands"
listings_$ships_from[listings_$ships_from == "uk,usa,philippines"] = "usa,uk"
listings_$ships_from[listings_$ships_from == "uk,philippines"] = "uk"
listings_$ships_from[listings_$ships_from == "theunitedsnakesofcaptivity"] = "usa"
listings_$ships_from[listings_$ships_from == "uk,usaandworldwide"] = "usa,uk"
listings_$ships_from[listings_$ships_from == "uk,usa,eu,aus"] = "usa,uk"
listings_$ships_from[listings_$ships_from == "untiedkingdom"] = "uk"
listings_$ships_from[listings_$ships_from == "usa,ukandphilippines"] = "usa,uk"
listings_$ships_from[listings_$ships_from == "latinamericanocolombia"] = "colombia"
listings_$ships_from[listings_$ships_from == "thehomeofthebodybags,shotty,andmacmakeup"] = "usa"
listings_$ships_from[listings_$ships_from == "uk,usaworldwide"] = "usa,uk"
listings_$ships_from[listings_$ships_from == "ukandireland"] = "uk"
listings_$ships_from[listings_$ships_from == "usa,ukandworldwide"] = "usa,uk"
listings_$ships_from[listings_$ships_from == "unitedkingdom"] = "uk"
listings_$ships_from[listings_$ships_from == "usa,uk"] = "usa"
listings_$ships_from[listings_$ships_from == "worldwide"] = "world"
listings_$ships_from[listings_$ships_from == "chinaoreu"] = "china"
listings_$ships_from[listings_$ships_from == "uk,asia"] = "uk"

listings_$ships_from[!(listings_$ships_from %in% c( "netherlands", "eu", "usa", "canada", "germany", "uk", "china", "sweden", "hongkong",
                                                    "france", "australia", "belgium", "world", "poland", "ukraine", "europe", "india",
                                                    "southafrica", "fiji", "italy", "austria", "philippines", "spain", "switzerland", "pakistan",
                                                    "denmark", "finland", "norway", "mexico", "argentina", "ireland", "russianfederation",
                                                    "czechrepublic", "cambodia", "colombia", "latvia", "scandinavia", "newzealand",
                                                    "swaziland", "singapore", "chinaoreu", "slovakia", "dominicanrepublic", "malaysia",
                                                    "bangkok", "uk,asia", "seychelles", "asia", "brazil", "hungary", "serbia",
                                                    "belarus", "barbados", "peru", "guatemala", "us", "romania",
                                                    "thailand", "japan", "chile", "jamaica", "srilanka"))] = ""

# Build a new ships_from table
ships_from_ = data.frame(location = unique(listings_$ships_from))

# Cross-reference listings on this table
tmp_size = sqldf("SELECT Count(*) FROM listings", dbname = dblist)
listings_ = as.data.table(sqldf("SELECT l.title, l.category, l.vendor, l.units, l.amount, l.quantity, sf.rowid AS ships_from, l.ships_to, l.ind
                                 FROM listings_ AS l
                                 JOIN ships_from_ AS sf
                                    ON sf.location == l.ships_from", dbname = dblist))
if (tmp_size != length(listings_$title)) {
    warning("Shrinkage in listings!")
}

# Write out ships_from table
ships_from_ = sqldf("SELECT * FROM ships_from", dbname = dblist)

# Check to see if there's any difference between the rowid and the original index
# If so, something's fishy
# Otherwise, this is consistent and that column is removed
tmp = sum(abs(listings_$ind - 1:length(listings_$title)))
if (tmp != 0) {
    warning("Something went wrong in the listings.")
}
cat('[combine_market_agora.R]: Sorted listings\n')

# Load all prices
# Cross reference with listing titles
# If everything went right with the listings, this should almost be the final ordering.
prices_ = as.data.table(sqldf("SELECT p.dat, p.listing, l.vendor, p.max_sales, p.min_sales, p.price, p.rating FROM prices AS p
                               LEFT JOIN listings_ as l
                                   ON l.ind == p.listing", dbname = dblist))

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
reviews_vendors = as.data.table(sqldf("SELECT r.dat, r.vendor, l.ind AS listing, r.val, r.content, r.max_user_sales, r.min_user_sales, r.user_rating, r.scraped_at, r.rowid AS id FROM reviews_vendors AS r
                                       LEFT JOIN (SELECT vendor, title, rowid AS ind FROM listings_ GROUP BY vendor, title) AS l
                                           ON (l.title == r.product AND l.vendor == r.vendor)"))

# Test for shrinkage
if (sqldf("SELECT Count(*) FROM reviews", dbname = dbvend) != length(reviews_vendors$dat)) {
    warning("Error with reviews!")
}

# Re-order so it's nice
reviews_vendors = subset(reviews_vendors, select = c(dat, vendor, listing, val, content, user_rating, scraped_at, id))

# Load reviews from the listings
# If everything went right with the listing, we can use the same rowids
reviews_listings = as.data.table(sqldf("SELECT r.dat, l.vendor, r.listing, r.val, r.review AS content, r.user_rating, r.scraped_at, r.rowid AS id FROM reviews AS r
                                        LEFT JOIN listings_ AS l
                                            WHERE l.rowid == r.listing", dbname = dblist))

# Append them both on top of each other
reviews = rbind(reviews_listings, reviews_vendors)

# Remove duplicates
# Sort by date, date scraped at, content, and value.
# Delete everything which is on the same date, was scraped at different dates, and has the same value and content
reviews_ = sqldf("SELECT dat, vendor, listing, val, content, user_rating, rowid AS id, scraped_at FROM reviews GROUP BY dat, vendor, listing, val, content")
old_len = length(reviews$dat)
rm(reviews)
cat(paste('[combine_market_agora.R]: Sorted reviews, ', 100 - 100*round(length(reviews_$dat)/old_len, digits = 2), '% were found to be duplicates.\n', sep = ''))
cat(paste('[combine_market_agora.R]: Cross-referencing reviews with the price 1 week before the review was left.\n'))
# Find an estimate for each review of the price at the time it was left
prices_$days = floor(prices_$dat / 86400)
reviews_$days_ago = reviews_$dat
reviews_ = reviews_[order(reviews_$dat),]
reviews_ = reviews_[!is.na(reviews_$listing),]
old_len = length(reviews_$dat)

tmp = as.data.table(sqldf("SELECT m.dat, m.listing, m.val, m.content, m.user_rating, r.rowid AS matched_price
                           FROM (
                            SELECT MAX(r.dat) AS max, r.id, p.rowid AS rowid
                              FROM reviews_ AS r
                            JOIN prices_ AS p
                              ON p.days < r.days_ago - 4 AND p.listing == r.listing
                            GROUP BY r.id
                          ) AS r
                          INNER JOIN reviews_ AS m ON m.id = r.id"))

reviews_ = tmp
rm(tmp)
cat(paste('[combine_market_agora.R]: Cross-referenced reviews. Discrepancy: ', 100*round(length(reviews_$dat)/old_len, digits = 2), '%. If this number is not very close to 100, then something is wrong.\n', sep = ''))

# Build smoothed estimates of daily sales rate from reviews
prices_temp = as.data.table(sqldf("SELECT p.listing, p.dat, p.vendor, p.rowid AS id FROM prices_ AS p"))
prices_temp$dat = floor(prices_temp$dat / 86400)
reviews_temp = as.data.table(sqldf("SELECT r.dat, r.listing, l.vendor FROM reviews_ AS r LEFT JOIN listings_ AS l ON l.rowid == r.listing"))

# Build estimate of aggregate reviews up to the time the price was scraped
prices_temp = as.data.table(sqldf("SELECT p.listing, p.dat, p.vendor, p.id, COUNT(r.rowid) AS prev FROM prices_temp AS p LEFT JOIN reviews_temp AS r ON r.dat <= p.dat AND r.listing == p.listing GROUP BY p.id"))

# Order the prices
prices_temp = prices_temp[order(prices_temp$dat),]

# Fit a smooth spline to every listing, compute averages looking ahead
prices_temp$reviews_per_day = prices_temp$dat*NA
prices_temp$net_reviews = prices_temp$dat*NA
prices_temp$net_reviews_smooth = prices_temp$dat*NA
x = split(prices_temp, f = prices_temp$listing)
tot = length(names(x))
cat('[combine_market_agora.R]: Fitting smooth splines to listings...\n')

for (i in 1:tot) {
    tryCatch({
        # Eliminate duplicate entries
        x[[i]] = x[[i]][!duplicated(subset(x[[i]], select = c(listing, dat)))]

        # Fit a smooth spline
        mod = smooth.spline(y = x[[i]]$prev, x = x[[i]]$dat, spar = 0.6)

        # Read in the spline values
        x[[i]]$net_reviews_smooth = predict(mod, x[[i]]$dat, deriv = 0)$y
        x[[i]]$reviews_per_day = predict(mod, x[[i]]$dat, deriv = 1)$y
        x[[i]]$net_reviews = x[[i]]$prev
    }, error = function(e) {})
    cat('\r')
    cat(paste('[combine_market_agora.R]: Progress: ', 100*round(i / tot, digits = 4), '%'), sep = '')
}
cat('\n[combine_market_agora.R]: Fitted smooth splines to listings.\n')
prices_temp = as.data.table(do.call(rbind, x))
reviews_temp = reviews_temp[order(reviews_temp$vendor),]

# Build estimate of aggregate reviews, for a vendor, up to the time the price was scraped
prices_temp$vendor_net_reviews_smooth = NA*prices_temp$dat
prices_temp$vendor_reviews_per_day = NA*prices_temp$dat
prices_temp$vendor_net_reviews = NA*prices_temp$dat

x = split(prices_temp, f = prices_temp$vendor)
tot = length(names(x))
cat('[combine_market_agora.R]: Fitting smooth splines to vendors...\n')
vendors_names = names(x)
for (i in 1:length(names(x))) {
    tryCatch({

        # Read into temporary variable
        tmp = x[[i]]
        tmp_reviews = reviews_temp[reviews_temp$vendor == vendors_names[i]]
        tmp = sqldf("SELECT p.listing, p.dat, p.vendor, p.id, COUNT(r.rowid) AS vendor_net_reviews, p.reviews_per_day, p.net_reviews, p.net_reviews_smooth, p.vendor_net_reviews_smooth, p.vendor_reviews_per_day FROM tmp AS p LEFT JOIN tmp_reviews AS r ON r.dat <= p.dat AND r.vendor == p.vendor GROUP BY p.id")
        tmp = tmp[order(tmp$dat),]

        # Read back out
        x[[i]] = tmp

        # Fit a smooth spline
        mod = smooth.spline(y = x[[i]]$vendor_net_reviews, x = x[[i]]$dat, spar = 0.6)

        # Read in the spline values
        x[[i]]$vendor_net_reviews_smooth = predict(mod, x[[i]]$dat, deriv = 0)$y
        x[[i]]$vendor_reviews_per_day = predict(mod, x[[i]]$dat, deriv = 1)$y
    }, error = function(e) {})
    cat('\r')
    cat(paste('[combine_market_agora.R]: Progress: ', 100*round(i / tot, digits = 4), '%'), sep = '')
}
prices_temp = as.data.table(do.call(rbind, x))
cat('\n[combine_market_agora.R]: Fitted smooth splines to vendors.\n')

# Re-create prices
prices_ = as.data.table(sqldf("SELECT p.dat,
                                        p.listing,
                                        q.max_sales,
                                        q.min_sales,
                                        q.price,
                                        q.rating,
                                        p.reviews_per_day,
                                        p.net_reviews,
                                        p.net_reviews_smooth,
                                        p.vendor_reviews_per_day,
                                        p.vendor_net_reviews,
                                        p.vendor_net_reviews_smooth FROM prices_temp AS p
                                    JOIN prices_ AS q ON q.rowid == p.id"))
cat('[combine_market_agora.R]: Sorted prices\n')

# Write everything to the database, clean up stuff
listings_ = subset(listings_, select = -c(ind))

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
    sqldf("CREATE TABLE listings(title TEXT, category INT, vendor INT, units TEXT, amount REAL, quantity INT, ships_from INT, ships_to INT, url TEXT)", dbname = dbout)
    sqldf("INSERT INTO listings SELECT * FROM listings_", dbname = dbout)

    sqldf("DROP TABLE IF EXISTS prices")
    sqldf("CREATE TABLE prices(dat INT,
                              listing INT,
                              max_sales INT,
                              min_sales INT,
                              price REAL,
                              rating REAL,
                              reviews_per_day REAL,
                              net_reviews INT,
                              net_reviews_smooth REAL,
                              vendor_reviews_per_day REAL,
                              vendor_net_reviews INT,
                              vendor_net_reviews_smooth REAL)", dbname = dbout)
    sqldf("INSERT INTO prices SELECT * FROM prices_", dbname = dbout)

    sqldf("DROP TABLE IF EXISTS reviews")
    sqldf("CREATE TABLE reviews(dat INT, listing INT, val INT, content TEXT, user_rating REAL, matched_price INT)", dbname = dbout)
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
