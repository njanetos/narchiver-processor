install.packages("sqldf")
install.packages("data.table")

library(sqldf)
library(data.table)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) > 0) {
    market = args[1]
} else {
    market = "agora"
}

path = paste(getwd(), "/aggregate_listings/", market, ".db", sep = "")

if (!file.exists(path)) {
    warning("Database missing.")
    quit()
}

cats = sqldf("SELECT * FROM categories", dbname = path);

N = length(cats$category)

u = c('g', 'mg', 'kg', 'lb', 'oz')
conversion = c(1, 1000, 0.001, 0.00220462, 0.035274)

for (i in 1:N) {
    
    all_prices = subset(sqldf(paste("SELECT * FROM listings AS L JOIN prices AS P on P.listing=L.rowid WHERE category =", i), dbname = path), select = -c(vendor, ships_from, ships_to, category, listing))
    
    all_prices$units[all_prices$units == 'g'] = 1;
    all_prices$units[all_prices$units == 'mg'] = 1000;
    all_prices$units[all_prices$units == 'kg'] = 0.001;
    all_prices$units[all_prices$units == 'lb'] = 0.00220462;
    all_prices$units[all_prices$units == 'oz'] = 0.035274;
    
    all_prices = all_prices[,!is.numeric(all_prices$units)]
    all_prices$units = as.numeric(all_prices$units)
    all_prices = all_prices[!is.na(all_prices$units),]
    
    all_prices$normalized = all_prices$price/(all_prices$amount*all_prices$quantity)*all_prices$units
    
    all_prices$day = as.Date(as.POSIXct(all_prices$dat, origin = "1970-01-01"))
    
    # Throw away prices which are far away
    med.price = median(all_prices$normalized);
    all_prices = all_prices[all_prices$normalized > med.price * 0.2 &
                                all_prices$normalized < med.price * 5,]
    all_prices = all_prices[all_prices$quantity != 1,]
    
    
    # sort by date
    all_prices = all_prices[order(all_prices$dat),]
    
    # group the data with binsize k
    n = length(all_prices$price)
    binsize = round(n/10)
    if (binsize == 0) {
        next
    }
    all_prices$bin = rep(1:ceiling(n / binsize), each = binsize)[1:n]
    
    # create data table
    all_prices.dt = data.table(all_prices)
    
    # create prices by bin
    prices.by.bin = data.frame(c(all_prices.dt[,list(first.quartile = quantile(normalized, 0.25),
                                                     second.quartile = quantile(normalized, 0.5),
                                                     third.quartile = quantile(normalized, 0.75)), by = bin],
                                 all_prices.dt[,list(bin.day = min(day)), by = bin]))
    
    dir.create(file.path(getwd(), "plots"), showWarnings = FALSE)
    dir.create(file.path(getwd(), "plots", market), showWarnings = FALSE)
    png(paste('plots/', market, "/", cats$category[i], '.png', sep=""))
    plot(as.Date(prices.by.bin$bin.day), prices.by.bin$first.quartile, type = 'l', lwd = 4, xlab = "Date", ylab = "$/g")
    title(paste("Price of ", cats$category[i], sep=""))
    dev.off()

}

