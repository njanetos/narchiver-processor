list.of.packages <- c("sqldf", "data.table", "plm", "texreg", "dummies", "relaimpo")
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

path = paste(getwd(), "/combined_market/", market, ".db", sep = "")

if (!file.exists(path)) {
    warning("Database missing.")
    quit()
}

# Create the output path
dir.create("regressions", showWarnings = FALSE)

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
                                      l.rowid AS listing
                                FROM prices AS p 
                                    LEFT JOIN listings AS l 
                                        ON p.listing = l.rowid 
                                    LEFT JOIN ships_from AS sf 
                                        ON sf.rowid = l.ships_from 
                                    LEFT JOIN ships_to AS st 
                                        ON st.rowid = l.ships_to", dbname = path))
categories_ = as.data.table(sqldf("SELECT * FROM categories", dbname = path))
vendors_ = as.data.table(sqldf("SELECT * FROM vendors", dbname = path))
reviews_ = as.data.table(sqldf("SELECT * FROM reviews", dbname = path))
listings_ = as.data.table(sqldf("SELECT * FROM listings", dbname = path))

# Construct average sales
prices_$sales = (prices_$max_sales + prices_$min_sales)/2

# Drop impossible values
prices_ = prices_[prices_$amount != 0 | prices_$quantity != 0,]

# Log prices
prices_$log = log(prices_$price)

# Construct growth rates
prices_ = prices_[order(prices_$vendor, prices_$dat),]
reviews_ = reviews_[order(reviews_$vendor, reviews_$dat),]

# Print some pretty pictures
first_vendors = c(1, 2, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68)
m = matrix(c(1:64, 65, 65, 65, 65, 65, 65, 65, 65), nrow = 9, ncol = 8, byrow = TRUE)
pdf(paste("regressions/", "total_sales.pdf"), width = 32, height = 32)
par(oma = c(10, 10, 14, 10))
layout(mat = m)
for (i in first_vendors) {
    plot(prices_$max_sales[prices_$vendor == i], type = 'l', col = '3', lwd = 2, ylab = 'Sales', xlab = paste('Days since start (obs: ', length(prices_$max_sales[prices_$vendor == i]), ")", sep = ""))
    lines(prices_$min_sales[prices_$vendor == i], col = '2', lwd = 2)
    title(main = paste("Vendor", vendors_$name[i]))
}
mtext("Recorded sales of the first recorded 64 vendors", outer = TRUE, cex = 7, padj = -0.5)
plot(1, type = "n", axes=FALSE, xlab="", ylab="")
legend(x = "top",inset = 0,
       legend = c("Lower bound on total sales", "Upper bound on total sales"), 
       col=c(2, 3), lwd=10, cex=4, horiz = TRUE)
dev.off()

pdf(paste("regressions/", "rating.pdf"), width = 32, height = 32)
par(oma = c(10, 10, 14, 10))
m = matrix(c(1:64), nrow = 8, ncol = 8, byrow = TRUE)
layout(mat = m)
for (i in first_vendors) {
    plot(prices_$rating[prices_$vendor == i], type = 'l', col = '4', lwd = 2, ylim = c(4.5, 5), ylab = 'Sales', xlab = paste('Days since start (obs: ', length(prices_$max_sales[prices_$vendor == i]), ")", sep = ""))
    title(main = paste("Vendor", vendors_$name[i]))
}
mtext("Rating history of the first recorded 64 vendors", outer = TRUE, cex = 7, padj = -0.5)
dev.off()

pdf(paste("regressions/", "ind_ratings.pdf"), width = 32, height = 32)
par(oma = c(10, 10, 14, 10))
m = matrix(c(1:64), nrow = 8, ncol = 8, byrow = TRUE)
layout(mat = m)
for (i in first_vendors) {
    plot(reviews_$val[reviews_$vendor == i], col = '4', pch = '+', lwd = 2, ylim = c(0, 5), ylab = 'Sales', xlab = paste('Days since start (obs: ', length(reviews_$val[reviews_$vendor == i]), ")", sep = ""))
    title(main = paste("Vendor", vendors_$name[i]))
}
mtext("Review history for first recorded 64 vendors", outer = TRUE, cex = 7, padj = -0.5)
dev.off()

prices_ = prices_[order(prices_$listing, prices_$dat),]

pdf(paste("regressions/", "listing_prices.pdf"), width = 32, height = 32)
par(oma = c(10, 10, 14, 10))
m = matrix(c(1:64), nrow = 8, ncol = 8, byrow = TRUE)
layout(mat = m)
for (i in first_vendors) {
    try(plot(round(prices_$price[prices_$listing == i], digits = 1), col = '6', type = 'l', lwd = 2, ylab = 'Sales', xlab = paste('Days since start (obs: ', length(prices_$price[prices_$listing == i]), ")", sep = "")))
    title(main = paste("'", listings_$title[i], "'", sep = ""))
}
mtext("Price history for first recorded 64 listing", outer = TRUE, cex = 7, padj = -0.5)
dev.off()


m = matrix(c(1:64), nrow = 8, ncol = 8, byrow = TRUE)
for (c in 1:length(categories_$category)) {
    pdf(paste("regressions/", "listing_prices_", gsub("/", "", categories_$category[c]), ".pdf", sep = ""), width = 32, height = 32)
    par(oma = c(10, 10, 14, 10))
    layout(mat = m)
    prices_t = prices_[prices_$category == c,]
    prices_t = prices_t[order(prices_t$listing, prices_t$dat)]
    prices_t$temp = prices_t$listing
    for (i in 1:64) {
        prices_t$temp = prices_t$temp - min(prices_t$temp) + 1
        try(plot(round(prices_t$price[prices_t$temp == 1], digits = 0), col = '4', type = 'l', lwd = 2, ylab = 'Sales', xlab = paste('Days since start (obs: ', length(prices_t$price[prices_t$temp == 1]), ")", sep = "")))
        title(main = paste("'", listings_$title[prices_t$listing[prices_t$temp == 1][1]], "'", sep = ""))
        prices_t = prices_t[prices_t$temp != 1,]
    }
    mtext(paste("Price history for first recorded 64 listings for", categories_$category[c]), outer = TRUE, cex = 5, padj = -0.5)
    dev.off()
}


# Normalized prices
prices_$normalized = prices_$price / (prices_$amount + prices_$quantity)
prices_$log_normalized = log(prices_$normalized)
prices_$log_rating = log(prices_$rating)

prices_mdma = subset(prices_[prices_$category == 7 & prices_$units == 'mg' & prices_$quantity > 1,])
prices_mdma = prices_mdma[prices_mdma$normalized > 0.01 & prices_mdma$normalized < 0.5,]

prices_xtc = subset(prices_[prices_$category == 23 & prices_$units == 'mg' & prices_$quantity > 1,])
prices_xtc = prices_xtc[prices_xtc$normalized > 0.01 & prices_xtc$normalized < 0.5,]

prices_oxy = subset(prices_[prices_$category == 22 & prices_$units == 'mg' & prices_$quantity > 1,])
prices_oxy = prices_oxy[prices_oxy$normalized < 1,]

prices_her = subset(prices_[prices_$category == 17 & (prices_$units == 'mg' | prices_$units == 'g' | prices_$units == 'kg') & prices_$quantity > 1,])
prices_her[prices_her$units == 'mg']$amount = prices_her[prices_her$units == 'mg']$amount/1000
prices_her[prices_her$units == 'kg']$amount = prices_her[prices_her$units == 'kg']$amount*1000

options(scipen=2)
options(digits=2)
sink(paste(getwd(), "/regressions/", 'agora_output.txt', sep = ''))
print("-----------------------------------------------------------------------------------")
print("----------Regressions--------------------------------------------------------------")
print("-----------------------------------------------------------------------------------")
print("Listings for MDMA")
summary(lm(log_normalized ~ rating, data = prices_mdma))
summary(lm(log_normalized ~ rating + sales, data = prices_mdma))
summary(lm(log_normalized ~ rating + sales + quantity, data = prices_mdma))
summary(lm(log_normalized ~ rating + sales + quantity + amount, data = prices_mdma))
summary(lm(log_normalized ~ rating + sales + quantity + dummy(prices_mdma$ships_from) + dummy(prices_mdma$ships_to), data = prices_mdma))
print("Listings for XTC")
summary(lm(log_normalized ~ rating, data = prices_xtc))
summary(lm(log_normalized ~ rating + sales, data = prices_xtc))
summary(lm(log_normalized ~ rating + sales + quantity, data = prices_xtc))
summary(lm(log_normalized ~ rating + sales + quantity + amount, data = prices_xtc))
summary(lm(log_normalized ~ log_rating + sales, data = prices_xtc))
summary(lm(log_normalized ~ rating + sales + quantity + dummy(prices_xtc$ships_from) + dummy(prices_xtc$ships_to), data = prices_xtc))
print("Listings for Oxycodone")
summary(lm(log_normalized ~ rating, data = prices_oxy))
summary(lm(log_normalized ~ rating + sales, data = prices_oxy))
summary(lm(log_normalized ~ rating + sales + quantity, data = prices_oxy))
summary(lm(log_normalized ~ rating + sales + quantity + amount, data = prices_oxy))
summary(lm(log_normalized ~ rating + sales + quantity + dummy(prices_oxy$ships_from) + dummy(prices_oxy$ships_to), data = prices_oxy))
print("Listings for Heroin")
summary(lm(log_normalized ~ rating, data = prices_her))
summary(lm(log_normalized ~ rating + sales, data = prices_her))
summary(lm(log_normalized ~ rating + sales + quantity, data = prices_her))
summary(lm(log_normalized ~ rating + sales + quantity + amount, data = prices_her))
summary(lm(log_normalized ~ rating + sales + quantity + dummy(prices_her$ships_from) + dummy(prices_her$ships_to), data = prices_her))
print("")
print("-----------------------------------------------------------------------------------")
print("----------Panel regressions--------------------------------------------------------")
print("-----------------------------------------------------------------------------------")
sink()
