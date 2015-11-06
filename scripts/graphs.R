library(sqldf)

sqldf("SELECT * FROM listings WHERE category = 1", dbname = "aggregate_listings/agora.db")