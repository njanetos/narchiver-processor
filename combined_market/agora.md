# Documentation for dataset `combined_market/agora`

Combined, cross-referenced data for the Agora marketplace. This should be the final stop of Agora data, before it goes on to be combined with other markets.

## Tables

### Table: `ships_from`

Complete list of locations listings ship from, the rowid is the id.

#### First 10 rows of table `ships_from`

| category                 |
|:-------------------------|
| Drugs.Stimulants.Cocaine |
| Drugs.Ecstasy.Pills      |
| Drugs.RCs                |
| Weapons.Fireworks        |
| Data.Software            |
| Drugs.Prescription       |
| Drugs.Other              |
| Drugs.Stimulants.Speed   |
| Drugs.Ecstasy.MDMA       |
| Services.Other           |

#### Column descriptions for table `ships_from`

* `location`: The name of the location.

### Table: `listings`

Each row of this table corresponds to a single listing, by title. For example, a listing might be `100 pills of 200 mg XTC`. It contains data on the amount and quantity of the good on sale, as well as various characteristics of the good, such as its shipping location. Many observations of a single listing were taken over time, but each listing only has one row in this table. See the table `prices` and `reviews` for time dependent data

#### First 10 rows of table `listings`

| title                                                                        |   vendor |   category |   ships_from |   ships_to | units   |   amount |   quantity |
|:-----------------------------------------------------------------------------|---------:|-----------:|-------------:|-----------:|:--------|---------:|-----------:|
| KILLA COKE 1G                                                                |      145 |          1 |            1 |          1 | g       |      1   |          1 |
| One 115mg Capsule of Rolling Buddha MDMA Sassafras Extract Escrow            |      146 |          2 |            2 |          2 | mg      |    115   |          1 |
| 500g APHP                                                                    |       85 |          3 |            1 |          1 | g       |    500   |          1 |
| Potassium chlorate 40g                                                       |      147 |          4 |            1 |          1 | g       |     40   |          1 |
| Tails Preloaded Bootable USB Flash Drive Current 1.0.1 version FREE SHIPPING |      148 |          5 |            1 |          1 |         |      0   |          1 |
| 500 Pills Rivotril 2 MG                                                      |      149 |          6 |            3 |          3 | mg      |      2   |        500 |
| 250g of 99.8 PURE METHYLONE.  250 grams                                      |      150 |          3 |            4 |          4 | g       |    250   |          1 |
| MDMA Pills 200mg 5stk SUPERMANN gelb                                         |      151 |          2 |            5 |          5 | mg      |    200   |        200 |
| USA ONLY  Clonodine .2mg                                                     |      152 |          7 |            1 |          1 | mg      |      0.2 |          1 |
| STHOMPSONSPEED PASTE 1gHIGH QUALITY                                          |      153 |          8 |            5 |          6 | g       |      1   |          1 |

#### Column descriptions for table `listings`

* `category`: The id of the category to which this belongs. See table `categories` for a complete listing of categories by id.
* `vendor`: The id of the vendor who offers this listing. See `vendors` for a complete listing of vendors.
* `ships_from`: The id of the location which this ships from. See column `ships_from` for a complete listing.
* `title`: The name of this listing.
* `ships_to`: The id of the location which this ships to. See column `ships_to` for a complete listing.
* `amount`: The total amount of each unit of this listing. For example, if the listing is `200 g cocaine`, then `amount` is 200. If an amount was not found, this defaults to 0.
* `units`: The units in which this listing is measured, e.g., `g` for grams. Empty (or null) if no units found.
* `quantity`: The total quantity of this listing on sale. For example, if the listing is `100 pills of 200 mg XTC`, then quantity is 100. (Compare to column `amount`, which here would be 200.)

### Table: `reviews`

A complete listing of all reviews for each listing.

#### First 10 rows of table `reviews`

|        dat |   listing |   vendor |     pricel |   rating |   min_sales |   max_sales |
|-----------:|----------:|---------:|-----------:|---------:|------------:|------------:|
| 1437562495 |         1 |     1126 |  244.991   |    5     |          25 |          40 |
| 1426577697 |         2 |     1126 |   14.3     |    4.957 |         500 |        1000 |
| 1441547341 |         3 |     1126 | 2140       |    4.88  |         500 |        1000 |
| 1430619342 |         4 |     1126 |    9.99957 |    4.67  |          55 |          70 |
| 1430858829 |         5 |     1126 |   19.9991  |    5     |          25 |          40 |
| 1416052591 |         6 |     1126 |  460       |    5     |          25 |          40 |
| 1435913399 |         7 |     1126 |  933.963   |    5     |          25 |          40 |
| 1441111488 |         8 |     1126 |   22.849   |    4.96  |         200 |         300 |
| 1417312912 |         9 |     1126 |    5       |    4.95  |         500 |        1000 |
| 1416112378 |        10 |     1126 |   12.6     |    5     |         150 |         200 |

#### Column descriptions for table `reviews`

* `dat`: The date at which this review was LEFT, in DAYS since 1970.
* `user_min_sales`: A lower bound on the number of transactions made by the user who left this review.
* `vendor`: The id of the vendor to whom the listing for which this review was left belongs.
* `val`: The actual review value, from 0 to 5.
* `content`: The text of the rating.
* `user_max_sales`: An upper bound on the number of transactions made by the user who left this review.
* `listing`: The id of the listing to which this review belongs.
* `scraped_at`: The date at which this review was SCRAPED, in DAYS since 1970.
* `user_rating`: The average rating of the user who left this review.

### Table: `vendors`

Complete list of vendors, the rowid is the id.

#### First 10 rows of table `vendors`

|   vendor |   listing |   val |   dat | content                                                                             | user_rating   |   user_min_sales |   user_max_sales |   scraped_at |
|---------:|----------:|------:|------:|:------------------------------------------------------------------------------------|:--------------|-----------------:|-----------------:|-------------:|
|       13 |      1603 |     5 | 16420 | FE for very trusted vendor.                                                         | null          |                  |                  |        16420 |
|       13 |      1603 |     5 | 16418 | FE for best domestic vendor                                                         | 3.0           |                6 |               10 |        16420 |
|       17 |       970 |     5 | 16372 | Good stuff, super fast delivery, quality vendor                                     | 5.0           |               70 |              100 |        16376 |
|       17 |       970 |     5 | 16365 | Decent price, gear and quick shipping. Another successful transaction.              | null          |                  |                  |        16376 |
|       17 |       970 |     5 | 16365 | Average but ok for price                                                            | null          |                  |                  |        16376 |
|       17 |       970 |     5 | 16363 | perfect  5                                                                          | 5.0           |               40 |               55 |        16376 |
|       17 |       970 |     5 | 16360 | Shipped quickly as promised. Stealth good. Product great and price is good also. 55 | null          |                  |                  |        16376 |
|       17 |       970 |     5 | 16359 | Fed                                                                                 | 5.0           |               70 |              100 |        16376 |
|       17 |       970 |     5 | 16357 | A will be back.                                                                     | 5.0           |                6 |               10 |        16376 |
|       19 |       738 |     5 | 16624 | FE trusted vendor                                                                   | null          |                  |                  |        16624 |

#### Column descriptions for table `vendors`

* `name`: The name of the vendor.

### Table: `prices`

A complete listing of all price, sales, and rating observations for each listing. The name `prices` is a misnomer, and should be changed, since this table also contains seller characteristics as well.

#### First 10 rows of table `prices`

| location           |
|:-------------------|
|                    |
| USA                |
| UK,USA,Philippines |
| China              |
| Germany            |
| Canada             |
| EU                 |
| Europe             |
| bluerave           |
| Australia          |

#### Column descriptions for table `prices`

* `rating`: The aggregate rating of the vendor offering the listing to which this price belongs, at the time it was scraped. It ranges from 0 to 5.
* `vendor`: The id of the vendor who offers this listing. See `vendors` for a complete listing of vendors.
* `pricel`: The price (in USD, converted from BTC).
* `dat`: The date at which this price was observed, in seconds since 1970.
* `max_sales`: The upper number of sales the vendor offering the listing to which this price belongs had made, at the time this price was scraped.
* `listing`: The id of the listing to which this price belongs.
* `min_sales`: The lower number of sales the vendor offering the listing to which this price belongs had made, at the time this price was scraped.

### Table: `ships_to`

Complete list of locations listings ship to, the rowid is the id.

#### First 10 rows of table `ships_to`

| location      |
|:--------------|
|               |
| USA           |
| Worldwide     |
| World         |
| Germany       |
| worldwide     |
| you           |
| Australia     |
| Scandinaviaww |
| WORLDWIDE     |

#### Column descriptions for table `ships_to`

* `location`: The name of the location.

### Table: `categories`

Contains a list of the categories to which listings might belong. The `rowid` is the id of the category.

#### First 10 rows of table `categories`

| name            |
|:----------------|
| HumboldtFarms   |
| itewqq          |
| MILF            |
| panacea         |
| RU18YET         |
| Weedy           |
| ferrisbueller   |
| The-Dabbler     |
| REALDEAL        |
| only-dmt-fromtj |

#### Column descriptions for table `categories`

* `category`: Textual description of this category.

