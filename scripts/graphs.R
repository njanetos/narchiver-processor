list.of.packages <- c("sqldf", "data.table")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

library(sqldf)
library(data.table)

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

categories_ = sqldf("SELECT * FROM categories", dbname = path);

ratings_ = sqldf("SELECT * FROM ratings", dbname = path)
prices_ = sqldf("SELECT * FROM prices", dbname = path)

ratings_ = ratings_[order(ratings_$dat),]

prices_$rating = prices_$vendor

len = length(prices_$dat)

for (i in 1:length(prices_$dat)) {
    # Find the two closest rating dates for the same vendor
    lower_ind = which.max(ratings_$dat[ratings_$dat < prices_$dat[i] & ratings_$vendor == prices_$vendor[i]])
    upper_ind = min(lower_ind + 1, length(ratings_$dat[ratings_$vendor == prices_$vendor[i]]))
    
    lower_date = ratings_$dat[ratings_$vendor == prices_$vendor[i]][lower_ind]
    upper_date = ratings_$dat[ratings_$vendor == prices_$vendor[i]][upper_ind]
    
    lower_rating = ratings_$val[ratings_$vendor == prices_$vendor[i]][lower_ind]
    upper_rating = ratings_$val[ratings_$vendor == prices_$vendor[i]][upper_ind]
    
    date = prices_$dat[i]
    
    mixture = (date - lower_date)/(upper_date - lower_date)
    
    if (length(lower_rating) != 1 | length(upper_rating) != 1) {
        prices_$rating[i] = NA
    } else {
        prices_$rating[i] = lower_rating*(1-mixture) + upper_rating*mixture
    }
    
    cat(i / len, " \r")
    flush.console()
}
