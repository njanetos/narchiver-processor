list.of.packages <- c("sqldf", "data.table", "texreg", "MASS", "RColorBrewer", "dummy", "kfigr", "plm")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, repos='http://cran.us.r-project.org')

for (p in list.of.packages) {
    library(p, character.only = TRUE)
}

args <- commandArgs(trailingOnly = TRUE)

if (length(args) > 0) {
    market = args[1]
} else {
    market = "agora"
}

# Colors

rf <- colorRampPalette(rev(brewer.pal(11,'Spectral')))
r <- rf(32)

path = paste("~/Google Drive/Programming/narchiver-processor/combined_market/", market, ".db", sep = "")

if (!file.exists(path)) {
    warning("Database missing.")
}

# Load data
prices_ = as.data.table(sqldf("SELECT p.dat AS dat, 
                              p.price AS price, 
                              p.rating AS rating, 
                              p.min_sales AS min_sales, 
                              p.max_sales AS max_sales, 
                              sf.location AS ships_from, 
                              st.location AS ships_to, 
                              l.amount AS amount,
                              l.quantity AS quantity,
                              l.units AS units,
                              l.category AS category,
                              l.vendor AS vendor,
                              l.rowid AS listing,
                              p.rowid AS id
                              FROM prices AS p 
                              LEFT JOIN listings AS l 
                              ON p.listing = l.rowid 
                              LEFT JOIN ships_from AS sf 
                              ON sf.rowid = l.ships_from 
                              LEFT JOIN ships_to AS st 
                              ON st.rowid = l.ships_to", dbname = path))
categories_ = as.data.table(sqldf("SELECT * FROM categories", dbname = path))
reviews_ = as.data.table(sqldf("SELECT * FROM reviews", dbname = path))
vendors_ = as.data.table(sqldf("SELECT v.name, COUNT(r.dat) AS size, v.rowid AS id FROM vendors AS v LEFT OUTER JOIN reviews_ AS r ON r.vendor == v.rowid GROUP BY v.rowid", dbname = path))
listings_ = as.data.table(sqldf("SELECT * FROM listings", dbname = path))

# Construct average sales
prices_$sales = (prices_$max_sales + prices_$min_sales)/2

# Drop impossible values
prices_ = prices_[prices_$amount != 0 | prices_$quantity != 0,]

# Log prices
prices_$log = log(prices_$price)

prices_ = prices_[order(prices_$vendor, prices_$dat),]
reviews_ = reviews_[order(reviews_$vendor, reviews_$dat),]


# Normalized prices
prices_$normalized = prices_$price / (prices_$amount + prices_$quantity)
prices_$log_normalized = log(prices_$normalized)
prices_$log_rating = log(prices_$rating)

prices_$days = floor(prices_$dat / 86400)
reviews_$days_ago = reviews_$dat - 10
reviews_ = reviews_[order(reviews_$dat),]

pri = prices_[prices_$category == i,]
pri$dat = pri$dat / 86400

rev = sqldf("SELECT r.dat, r.listing, l.category FROM reviews_ AS r LEFT JOIN listings_ AS l ON l.rowid == r.listing")

fin = as.data.table(sqldf("SELECT *, COUNT(r.rowid) AS prev FROM pri AS p LEFT JOIN rev AS r ON r.dat <= p.dat AND r.listing == p.listing GROUP BY p.id"))

fin = fin[order(fin$dat),]

x = split(fin, f = as.factor(fin$listing))
for (i in 1:length(names(x))) {
    x[[i]]$raw_change = c(NA, diff(x[[i]]$prev))
    x[[i]]$smooth_change = NA
    tryCatch({
        mod = smooth.spline(y = x[[i]]$prev, x = x[[i]]$dat, spar = 0.6)
        x[[i]]$smooth_change = predict(mod, deriv = 1)$y
        x[[i]]$smooth_ahead_1 = x[[i]]$smooth_change
        x[[i]]$smooth_behind_1 = x[[i]]$smooth_change
        x[[i]]$smooth_ahead_3 = x[[i]]$smooth_change
        x[[i]]$smooth_behind_3 = x[[i]]$smooth_change
        x[[i]]$smooth_ahead_5 = x[[i]]$smooth_change
        x[[i]]$smooth_behind_5 = x[[i]]$smooth_change
        x[[i]]$smooth_ahead_7 = x[[i]]$smooth_change
        x[[i]]$smooth_behind_7 = x[[i]]$smooth_change
        for (j in 1:length(x[[i]]$smooth_change)) {
            d = x[[i]]$dat[j]
            behind = x[[i]]$smooth_change[x[[i]]$dat > d - 7 & x[[i]]$dat <= d]
            ahead = x[[i]]$smooth_change[x[[i]]$dat < d + 7 & x[[i]]$dat >= d]
            x[[i]]$smooth_behind_1[j] = mean(behind)
            x[[i]]$smooth_ahead_1[j] = mean(ahead)
            behind = x[[i]]$smooth_change[x[[i]]$dat > d - 21 & x[[i]]$dat <= d]
            ahead = x[[i]]$smooth_change[x[[i]]$dat < d + 21 & x[[i]]$dat >= d]
            x[[i]]$smooth_behind_3[j] = mean(behind)
            x[[i]]$smooth_ahead_3[j] = mean(ahead)
            behind = x[[i]]$smooth_change[x[[i]]$dat > d - 35 & x[[i]]$dat <= d]
            ahead = x[[i]]$smooth_change[x[[i]]$dat < d + 35 & x[[i]]$dat >= d]
            x[[i]]$smooth_behind_5[j] = mean(behind)
            x[[i]]$smooth_ahead_5[j] = mean(ahead)
            behind = x[[i]]$smooth_change[x[[i]]$dat > d - 42 & x[[i]]$dat <= d]
            ahead = x[[i]]$smooth_change[x[[i]]$dat < d + 42 & x[[i]]$dat >= d]
            x[[i]]$smooth_behind_7[j] = mean(behind)
            x[[i]]$smooth_ahead_7[j] = mean(ahead)
        }
        
    }, error = function(e) {})
    cat('\r')
    cat(i)
}
fin = as.data.table(unsplit(x, f = as.factor(fin$listing)))

finpd = pdata.frame(fin, index = c("listing", "dat"))

finpd$smooth_change_lag = lag(finpd$smooth_change, k = )