list.of.packages <- c("sqldf", "data.table", "plm", "texreg", "dummies", "relaimpo", "MASS", "RColorBrewer", "plotrix")
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

# Print some pretty pictures
prices_ = prices_[order(prices_$vendor, prices_$dat),]
reviews_ = reviews_[order(reviews_$vendor, reviews_$dat),]

# Vendor size
size = vendors_$size
hist(log10(size[size >= 10]), breaks = 20, main = "Distribution of sellers by number of reviews", xlab = "log base 10 of total reviews")

# Count max sales
vendors_$max = vendors_$size
for (i in 1:length(vendors_$name)) {
    vendors_$max[i] = max(prices_$max_sales[prices_$vendor == i])
}

size = vendors_$max[vendors_$max != -Inf]
hist(log10(size), breaks = 20, main = "Distribution of sellers by number of sales", xlab = "log base 10 of total sales")

# Top 2.5% of vendors
top_vendors = vendors_[vendors_$size > quantile(vendors_$size, 0.95),]
top_vendors = top_vendors[order(-top_vendors$size),]

pdf(paste("regressions/", "top_vendors.pdf"), width = 256, height = 16)
par(oma = c(10, 10, 14, 10))
layout(mat = matrix(c(1:(64*3)), nrow = 3, ncol = 64, byrow = FALSE))
int = c(1, 3, 4, 5, 7, 8, 9, 10, 
        11, 13, 15, 80, 17, 18, 19, 20, 
        22, 24, 25, 27, 29, 31, 33, 78,
        36, 37, 38, 39, 40, 41, 42, 43,
        44, 45, 46, 47, 48, 49, 50, 51,
        52, 53, 54, 55, 56, 57, 58, 59,
        60, 61, 62, 63, 64, 65, 66, 67,
        68, 69, 76, 71, 77, 73, 74, 79)
for (j in int) {
    try({
    i = top_vendors$id[j]
    
    max_s = prices_$max_sales[prices_$vendor == i & prices_$amount != 0]
    min_s = prices_$min_sales[prices_$vendor == i & prices_$amount != 0]
    
    set.seed(0)
    max_s = max_s[sample(length(max_s), min(100, length(max_s)))]
    set.seed(0)
    min_s = min_s[sample(length(min_s), min(100, length(min_s)))]
    
    max_range = max(max_s)
    min_range = min(min_s)
    
    time = prices_$dat[prices_$vendor == i & prices_$amount != 0]
    set.seed(0)
    time = time[sample(length(time), min(100, length(time)))]
    
    temp = data.frame(max_s, min_s, time)
    temp = temp[order(time),]
    max_s = temp$max_s
    min_s = temp$min_s
    time = (temp$time - min(temp$time))/86400

    xlabel = paste('Days since start (obs: ', length(prices_$max_sales[prices_$vendor == i]), ")", sep = "")
    plot(y = max_s, x = time, type = 'l', ylim = c(min_range, max_range), col = '3', lwd = 2, ylab = 'Sales', xlab = xlabel)
    lines(y = min_s, x = time, col = '2', lwd = 2)
    temp1 = c(max_s, min_s)
    temp2 = c(time, time)
    temp = data.frame(temp1, temp2)
    temp = temp[order(temp2),]
    reg = smooth.spline(temp1 ~ temp2, spar = 1.1)
    lines(predict(reg), col = '4', lwd = 2)
    title("Total sales")
    
    plot(predict(reg, deriv = 1), col = '6', lwd = 2, type = 'l', xlab = xlabel, main = "Estimated sales rate", ylim = c(0, 50))
    
    time = prices_$dat[prices_$vendor == i & prices_$amount != 0]
    plot(prices_$rating[prices_$vendor == i & prices_$amount != 0], x = (time - min(time))/86400, type = 'l', col = '4', lwd = 2, ylim = c(4.0, 5.0), ylab = 'Sales', xlab = paste('Days since start (obs: ', length(prices_$max_sales[prices_$vendor == i]), ")", sep = ""))
    title(main = paste("Rating"))
    
    
    cat('\r')
    cat(j/64)
    })
    
}
mtext("Histories of top 0.2% (by reviews) of vendors", outer = TRUE, cex = 6, padj = -0.5)
plot(1, type = "n", axes=FALSE, xlab="", ylab="")
dev.off()

first_vendors = c(1, 2, 5, 6, 7, 8, 9, 10, 
                  11, 12, 13, 14, 15, 16, 17, 18, 
                  19, 21, 22, 23, 24, 25, 69, 70, 
                  28, 29, 30, 31, 32, 33, 34, 35, 
                  36, 71, 38, 39, 40, 42, 43, 44, 
                  45, 46, 47, 48, 49, 50, 51, 52, 
                  53, 54, 55, 56, 57, 58, 59, 60, 
                  61, 62, 63, 64, 72, 73, 67, 68)
m = matrix(c(1:64, 65, 65, 65, 65, 65, 65, 65, 65), nrow = 9, ncol = 8, byrow = TRUE)
pdf(paste("regressions/", "total_sales.pdf"), width = 32, height = 32)
par(oma = c(10, 10, 14, 10))
layout(mat = m)
for (i in first_vendors) {
    time = prices_$dat[prices_$vendor == i]
    max_range = max(prices_$max_sales[prices_$vendor == i])
    min_range = min(prices_$min_sales[prices_$vendor == i])
    plot(y = prices_$max_sales[prices_$vendor == i], x = (time - min(time))/86400, type = 'l', ylim = c(min_range, max_range), col = '3', lwd = 2, ylab = 'Sales', xlab = paste('Days since start (obs: ', length(prices_$max_sales[prices_$vendor == i]), ")", sep = ""))
    lines(y = prices_$min_sales[prices_$vendor == i], x = (time - min(time))/86400, col = '2', lwd = 2)

    title(main = paste("Vendor", vendors_$name[i]))
}
mtext("Total sales of the first recorded 64 vendors", outer = TRUE, cex = 7, padj = -0.5)
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
    time = prices_$dat[prices_$vendor == i]
    plot(prices_$rating[prices_$vendor == i], x = (time - min(time))/86400, type = 'l', col = '4', lwd = 2, ylim = c(4.0, 5.0), ylab = 'Sales', xlab = paste('Days since start (obs: ', length(prices_$max_sales[prices_$vendor == i]), ")", sep = ""))
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

prices_$days = floor(prices_$dat / 86400)
reviews_$days_ago = reviews_$dat - 10
reviews_ = reviews_[order(reviews_$dat),]

tmp = sqldf("SELECT r.vendor, r.listing, r.val, p.days AS dat FROM reviews_ AS r LEFT JOIN prices_ AS p ON p.days < r.days_ago AND p.listing == r.listing AND p.vendor == r.vendor GROUP BY r.dat, r.listing, r.vendor, r.val, r.content")

dr = sqldf("SELECT r.dat, r.vendor, r.listing, r.val, p.price, p.sales, p.ships_from, p.ships_to, p.amount, p.quantity, p.units, p.category, p.sales, p.log_normalized, p.normalized, p.rating FROM tmp AS r
            JOIN prices_ AS p
                ON p.days == r.dat AND p.listing == r.listing AND p.vendor == r.vendor")

# Try to put as many things in the same units as possible
dr$normalized[dr$units == 'g'] = dr$normalized[dr$units == 'g']/1000
dr$normalized[dr$units == 'kg'] = dr$normalized[dr$units == 'kg']/1000000
dr$normalized[dr$units == 'ug'] = dr$normalized[dr$units == 'ug']*1000
dr$normalized[dr$units == 'oz'] = dr$normalized[dr$units == 'oz']/28349.5
dr$normalized[dr$units == 'lb'] = dr$normalized[dr$units == 'lb']/453592
dr$log_normalized = log(dr$normalized)
dr = dr[dr$units == 'mg' | dr$units == 'g' | dr$units == 'kg' | dr$units == 'ug' | dr$units == 'oz' | dr$units == 'lb',]

options(scipen=10)
options(digits=2)
sink(paste(getwd(), "/regressions/", 'agora_output.txt', sep = ''))
categories_$fear = as.numeric(categories_$category)
categories_$p = categories_$fear
categories_$average = categories_$fear
categories_$index = 1:length(categories_$fear)

int = c(2, 3, 4, 7, 9, 17, 19, 20, 22, 23, 26, 33, 35, 38, 43, 46, 47, 48, 51, 54, 59, 60, 65, 68, 88, 89, 90, 91, 92, 94, 96, 97, 99)
int = int[c(1, 2, 3, 4, 5, 6, 7, 9, 13, 14, 15, 17, 19, 20)]


print("-----------------------------------------------------------------------------------")
print("----------Regressions--------------------------------------------------------------")
print("-----------------------------------------------------------------------------------")
pdf(paste("regressions/", "histograms.pdf"), width = 20, height = 96)
par(oma = c(10, 10, 14, 10))
m = matrix(c(1:(33*4)), nrow = 33, ncol = 4, byrow = TRUE)
layout(mat = m)
for (i in int) {
    print(paste("-------------- Listings for", categories_$category[i]))
    tryCatch({
    sub = dr[dr$category == i,]
    med = median(sub$normalized)
    v = sqrt(var(sub$normalized))
    #sub = sub[abs(sub$normalized - med) < v,]
    q = quantile(sub$normalized, 0.9)
    sub = sub[sub$normalized < q,]

    plot(1, type="n", axes=F, xlab="", ylab="")
    text(1, 1, tail(strsplit(categories_$category[i], "\\.")[[1]], n = 1), cex = 4)
    
    k = kde2d(sub$dat, sub$normalized, lims = c(min(sub$dat), max(sub$dat), 0, 2*max(sub$normalized)))
    image(k, col = r, ylab = "$/mg", xlab = "Days since 1970")
    if (i == int[1]) {
        title("Density of prices over time")
    }
    
    hist(sub$normalized, breaks = 50, xlab = "$ / mg", main = "")
    if (i == int[1]) {
        title("Density of prices")
    }
    
    ran = runif(1, 0.7, 0.9)[1]
    r = runif(1, 0.05,  0.1)[1]
    pie(c(1 - ran - r, ran, r), c("Not illegal at all!", "Extremely illegal", "Pretty illegal"))
    if (i == int[1]) {
        title("How illegal am I?")
    }
    
    print(summary(subset(sub, select = c(normalized))))
    categories_$average[i] = mean(sub$normalized)
    
    mod = lm(log_normalized ~ rating + sales, data = sub)
    print(summary(mod))
    categories_$fear[i] = mod$coefficients['rating']
    categories_$p[i] = summary(mod)$coefficients[2, 4]}, error = function(e){})
}
mtext("Price distributions for all categories", outer = TRUE, cex = 5, padj = -0.5)
dev.off()
print("")
print("-----------------------------------------------------------------------------------")
print("----------Most to least ordered----------------------------------------------------")
print("-----------------------------------------------------------------------------------")
categories_$fear = as.numeric(categories_$fear)
categories_$p = as.numeric(categories_$p)
final_cats = categories_[order(categories_$fear),]
final_cats = final_cats[!is.na(final_cats$fear),]
final_cats$g = final_cats$average*1000
print(final_cats)
sink()


