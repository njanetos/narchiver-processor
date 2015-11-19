list.of.packages <- c("sqldf", "data.table", "plm")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

library(sqldf)
library(data.table)
library(plm)

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

prices_ = sqldf("SELECT * FROM prices", dbname = path)
prices_ = prices_[prices_$rating <= 5 & prices_$rating >= 0 & prices_$sales >= 0, ]
prices_ = prices_[order(prices_$vendor, prices_$listing, prices_$dat), ]
prices_$log = log(prices_$price)
prices_ = prices_[c(3, 1, 2, 4, 5, 6, 7)]
prices_$dat = prices_$dat/86400

# Run some tests

prices_temp = prices_[prices_$vendor < 100,]

pool.test = pvcm(log ~ price + rating, data=prices_temp, model="within")
