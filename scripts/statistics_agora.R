list.of.packages <- c("sqldf", "data.table", "plm", "texreg", "dummies", "relaimpo")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

library(sqldf)
library(data.table)
library(plm)
library(texreg)
library(dummies)
library(relaimpo)

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
                                      p.est_rating AS est_rating, 
                                      p.est_sales AS est_sales, 
                                      p.rating AS rating, 
                                      p.min_sales AS min_sales, 
                                      p.max_sales AS max_sales, 
                                      sf.location AS ships_from, 
                                      st.location AS ships_to, 
                                      l.amount AS amount,
                                      l.quantity AS quantity,
                                      l.units AS units,
                                      l.category AS category
                                FROM prices AS p 
                                    LEFT JOIN listings AS l 
                                        ON p.listing = l.rowid 
                                    LEFT JOIN ships_from AS sf 
                                        ON sf.rowid = l.ships_from 
                                    LEFT JOIN ships_to AS st 
                                        ON st.rowid = l.ships_to", dbname = path))
categories_ = as.data.table(sqldf("SELECT * FROM categories", dbname = path))

# Construct average sales
prices_$sales = (prices_$min_sales + prices_$max_sales)/2

# Drop impossible values
prices_ = prices_[prices_$amount != 0 | prices_$quantity != 0,]

# Log prices
prices_$log = log(prices_$price)

# Normalized prices
prices_$normalized = prices_$price / (prices_$amount + prices_$quantity)
prices_$log_normalized = log(prices_$normalized)
prices_$log_rating = log(prices_$rating)

prices_mdma = subset(prices_[prices_$category == 7 & prices_$units == 'mg' & prices_$quantity > 1,], select = c(dat, price, sales, rating, amount, quantity, normalized, log_normalized, log_rating, ships_from, ships_to))
prices_mdma = prices_mdma[prices_mdma$normalized > 0.01 & prices_mdma$normalized < 0.5,]

prices_xtc = subset(prices_[prices_$category == 23 & prices_$units == 'mg' & prices_$quantity > 1,], select = c(dat, price, sales, rating, amount, quantity, normalized, log_normalized, log_rating, ships_from, ships_to))
prices_xtc = prices_xtc[prices_xtc$normalized > 0.01 & prices_xtc$normalized < 0.5,]

prices_oxy = subset(prices_[prices_$category == 22 & prices_$units == 'mg' & prices_$quantity > 1,], select = c(dat, price, sales, rating, amount, quantity, normalized, log_normalized, log_rating, ships_from, ships_to))
prices_oxy = prices_oxy[prices_oxy$normalized < 1,]

prices_her = subset(prices_[prices_$category == 17 & (prices_$units == 'mg' | prices_$units == 'g' | prices_$units == 'kg') & prices_$quantity > 1,], select = c(dat, price, sales, rating, amount, quantity, normalized, log_normalized, log_rating, ships_from, ships_to))
prices_her[prices_her$units == 'mg']$amount = prices_her[prices_her$units == 'mg']$amount/1000
prices_her[prices_her$units == 'kg']$amount = prices_her[prices_her$units == 'kg']$amount*1000

options(scipen=5)
sink(paste(getwd(), "/regressions/", 'agora_output.txt', sep = ''))
print("")
print("-----------------------------------------------------------------------------------")
print("----------Consistency checks-------------------------------------------------------")
print("-----------------------------------------------------------------------------------")
summary(lm(prices_$rating ~ prices_$est_rating))
summary(lm(prices_$sales ~ prices_$est_sales))
print("")
print("-----------------------------------------------------------------------------------")
print("----------Categories---------------------------------------------------------------")
print("-----------------------------------------------------------------------------------")
categories_$category
print("")
print("-----------------------------------------------------------------------------------")
print("----------Regressions--------------------------------------------------------------")
print("-----------------------------------------------------------------------------------")
print("Listings for MDMA")
summary(lm(log_normalized ~ rating + sales, data = prices_mdma))
summary(lm(log_normalized ~ rating + sales + quantity, data = prices_mdma))
summary(lm(log_normalized ~ rating + sales + quantity + amount, data = prices_mdma))
summary(lm(log_normalized ~ log_rating + sales, data = prices_mdma))
summary(lm(log_normalized ~ rating + sales + quantity + dummy(prices_mdma$ships_from) + dummy(prices_mdma$ships_to), data = prices_mdma))
print("Listings for XTC")
summary(lm(log_normalized ~ rating + sales, data = prices_xtc))
summary(lm(log_normalized ~ rating + sales + quantity, data = prices_xtc))
summary(lm(log_normalized ~ rating + sales + quantity + amount, data = prices_xtc))
summary(lm(log_normalized ~ log_rating + sales, data = prices_xtc))
summary(lm(log_normalized ~ rating + sales + quantity + dummy(prices_xtc$ships_from) + dummy(prices_xtc$ships_to), data = prices_xtc))
print("Listings for Oxycodone")
summary(lm(log_normalized ~ rating + sales, data = prices_oxy))
summary(lm(log_normalized ~ rating + sales + quantity, data = prices_oxy))
summary(lm(log_normalized ~ rating + sales + quantity + amount, data = prices_oxy))
summary(lm(log_normalized ~ log_rating + sales, data = prices_oxy))
summary(lm(log_normalized ~ rating + sales + quantity + dummy(prices_oxy$ships_from) + dummy(prices_oxy$ships_to), data = prices_oxy))
print("Listings for Heroin")
summary(lm(log_normalized ~ rating + sales, data = prices_her))
summary(lm(log_normalized ~ rating + sales + quantity, data = prices_her))
summary(lm(log_normalized ~ rating + sales + quantity + amount, data = prices_her))
summary(lm(log_normalized ~ log_rating + sales, data = prices_her))
summary(lm(log_normalized ~ rating + sales + quantity + dummy(prices_her$ships_from) + dummy(prices_her$ships_to), data = prices_her))
print("")
print("-----------------------------------------------------------------------------------")
print("----------Panel regressions--------------------------------------------------------")
print("-----------------------------------------------------------------------------------")
sink()
