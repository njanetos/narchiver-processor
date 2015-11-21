# Documentation for dataset combined_market/agora

Combined, cross-referenced data for the Agora marketplace. This should be the final stop of Agora data, before it goes on to be combined with other markets.

## Tables

### ships_from

Complete list of locations listings ship from, the rowid is the id.

* __location__

  The name of the location.

### listings

Each row of this table corresponds to a single listing, by title. For example, a listing might be `100 pills of 200 mg XTC`. It contains data on the amount and quantity of the good on sale, as well as various characteristics of the good, such as its shipping location. Many observations of a single listing were taken over time, but each listing only has one row in this table. See the table `prices` and `reviews` for time dependent data

* __category__

  The id of the category to which this belongs. See table `categories` for a complete listing of categories by id.

* __vendor__

  The id of the vendor who offers this listing. See `vendors` for a complete listing of vendors.

* __ships_from__

  The id of the location which this ships from. See column `ships_from` for a complete listing.

* __title__

  The name of this listing.

* __ships_to__

  The id of the location which this ships to. See column `ships_to` for a complete listing.

* __amount__

  The total amount of each unit of this listing. For example, if the listing is `200 g cocaine`, then `amount` is 200. If an amount was not found, this defaults to 0.

* __units__

  The units in which this listing is measured, e.g., `g` for grams. Empty (or null) if no units found.

* __quantity__

  The total quantity of this listing on sale. For example, if the listing is `100 pills of 200 mg XTC`, then quantity is 100. (Compare to column `amount`, which here would be 200.)

### reviews

A complete listing of all reviews for each listing.

* __dat__

  The date at which this review was LEFT, in DAYS since 1970.

* __user_min_sales__

  A lower bound on the number of transactions made by the user who left this review.

* __vendor__

  The id of the vendor to whom the listing for which this review was left belongs.

* __val__

  The actual review value, from 0 to 5.

* __content__

  The text of the rating.

* __user_max_sales__

  An upper bound on the number of transactions made by the user who left this review.

* __listing__

  The id of the listing to which this review belongs.

* __scraped_at__

  The date at which this review was SCRAPED, in DAYS since 1970.

* __user_rating__

  The average rating of the user who left this review.

### vendors

Complete list of vendors, the rowid is the id.

* __name__

  The name of the vendor.

### prices

A complete listing of all price, sales, and rating observations for each listing. The name `prices` is a misnomer, and should be changed, since this table also contains seller characteristics as well.

* __rating__

  The aggregate rating of the vendor offering the listing to which this price belongs, at the time it was scraped. It ranges from 0 to 5.

* __vendor__

  The id of the vendor who offers this listing. See `vendors` for a complete listing of vendors.

* __pricel__

  The price (in USD, converted from BTC).

* __dat__

  The date at which this price was observed, in seconds since 1970.

* __max_sales__

  The upper number of sales the vendor offering the listing to which this price belongs had made, at the time this price was scraped.

* __listing__

  The id of the listing to which this price belongs.

* __min_sales__

  The lower number of sales the vendor offering the listing to which this price belongs had made, at the time this price was scraped.

### ships_to

Complete list of locations listings ship to, the rowid is the id.

* __location__

  The name of the location.

### categories

Contains a list of the categories to which listings might belong. The `rowid` is the id of the category.

* __category__

  Textual description of this category.

