# Documentation for dataset `combined_market/agora`

Combined, cross-referenced data for the Agora marketplace. This should be the final stop of Agora data, before it goes on to be combined with other markets.

## Tables

### Table: `ships_from`

Complete list of locations listings ship from, the rowid is the id.

#### First 10 rows of table `ships_from`

| category                      |
|:------------------------------|
| Jewelry                       |
| Drugs.Stimulants.Meth         |
| Drugs.Dissociatives.Ketamine  |
| Drugs.Cannabis.Weed           |
| Drugs.Weightloss              |
| Drugs.Steroids                |
| Drugs.Ecstasy.MDMA            |
| Drugs.Stimulants.Prescription |
| Drugs.Benzos                  |
| Information.eBooks            |

#### Column descriptions for table `ships_from`

* `location`: The name of the location.

### Table: `listings`

Each row of this table corresponds to a single listing, by title. For example, a listing might be `100 pills of 200 mg XTC`. It contains data on the amount and quantity of the good on sale, as well as various characteristics of the good, such as its shipping location. Many observations of a single listing were taken over time, but each listing only has one row in this table. See the table `prices` and `reviews` for time dependent data

#### First 10 rows of table `listings`

| title                                                                             |   category |   vendor | units   |   amount |   quantity |   ships_from |   ships_to |
|:----------------------------------------------------------------------------------|-----------:|---------:|:--------|---------:|-----------:|-------------:|-----------:|
| Dior Logo Necklace Replica                                                        |          1 |     1277 |         |      0   |          1 |            1 |          1 |
| Chanel Sunglasses CHL5171 Replica blackblack frame white legs burgundy beige c952 |          1 |      808 |         |      0   |          1 |            1 |          1 |
| Ice Crystal Meth 8 OZ 224 Grams  599 OZ .   Escrow  Stealth                       |          2 |      860 | oz      |      8   |          1 |            1 |          1 |
| 2.5gr. Ketamine Risomer                                                           |          3 |      977 | g       |      2.5 |          1 |            1 |          1 |
| 1.0 gram Risomer KETAMINE                                                         |          3 |      748 | g       |      1   |          1 |            2 |          2 |
| 12 oz AlienTrain                                                                  |          4 |      129 | oz      |     12   |          1 |            1 |          1 |
| Yohimbine Hydrochloride HCL 10g                                                   |          5 |      612 | g       |     10   |          1 |            1 |          1 |
| Bayer Dbol Dianabol Methandrostenolone 10mg x 100 tablets From EU                 |          6 |       74 | mg      |     10   |        100 |            3 |          3 |
| MDMA 5g                                                                           |          7 |     1499 | g       |      5   |          1 |            1 |          1 |
| FE SPECIAL 20 x 30mg Adderall IR Pills TEVABARRCheapest on Agora                  |          8 |     2266 | mg      |     30   |         20 |            4 |          4 |

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

|   dat |   listing | vendor   |   max_sales |   min_sales |   price |   rating |   reviews_per_day |   reviews_average_week |   reviews_average_month |   net_reviews |   net_reviews_smooth |
|------:|----------:|:---------|------------:|------------:|--------:|---------:|------------------:|-----------------------:|------------------------:|--------------:|---------------------:|
| 16624 |         1 | foxygirl |          55 |          40 | 50      |     5    |                 0 |                        |                         |             0 |                    0 |
| 16576 |         1 | foxygirl |          10 |           6 | 50      |     5    |                 0 |                      0 |                         |             0 |                    0 |
| 16616 |         1 | foxygirl |          40 |          25 | 49.998  |     5    |                 0 |                      0 |                         |             0 |                    0 |
| 16596 |         1 | foxygirl |          25 |          15 | 50      |     4.58 |                 0 |                      0 |                         |             0 |                    0 |
| 16684 |         1 | foxygirl |         150 |         100 | 50      |     4.9  |                 0 |                      0 |                         |             0 |                    0 |
| 16593 |         1 | foxygirl |          10 |           6 | 50      |     5    |                 0 |                      0 |                         |             0 |                    0 |
| 16591 |         1 | foxygirl |          10 |           6 | 49.9978 |     5    |                 0 |                      0 |                         |             0 |                    0 |
| 16649 |         1 | foxygirl |         100 |          70 | 49.9982 |     4.98 |                 0 |                      0 |                         |             0 |                    0 |
| 16651 |         1 | foxygirl |         100 |          70 | 49.9982 |     4.98 |                 0 |                      0 |                         |             0 |                    0 |
| 16589 |         1 | foxygirl |          10 |           6 | 50      |     5    |                 0 |                      0 |                       0 |             0 |                    0 |

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

|   dat |   vendor |   listing |   val | content                                                                                                                         |   user_rating |
|------:|---------:|----------:|------:|:--------------------------------------------------------------------------------------------------------------------------------|--------------:|
|     0 |      320 |     15507 |     5 | Quick delivery thanks                                                                                                           |             5 |
|     0 |      320 |     15507 |     5 | fast shipping, ideal                                                                                                            |             5 |
|     0 |      320 |     17065 |     5 | 100 Delicious chocolates with a euphoric high Also received a yummy brownie, thanks again.                                      |             5 |
|     0 |      320 |     17065 |     5 | Excellent. Superb chocs, good packaging and speedy delivery. Great vendor.                                                      |             5 |
|     0 |      320 |     17065 |     5 | Professional and prompt seller, highly recommended. Good packaging. 1 choc gives nice mellow high.                              |             5 |
|     0 |      320 |     17065 |     5 | Sorry for delay, had family issues. Really tasty, incredible buzz and stone, matching if not better quality to edibles I have e |             5 |
|     0 |      320 |     31614 |     5 | Arrived next day after shipping Thanks once again A                                                                             |             5 |
|     0 |      320 |     31614 |     5 | Excellent vendor. Cookies were perfect and the communication was amazing. Thanks                                                |             5 |
|     0 |      320 |     31614 |     5 | Good packaging, decent stealth and NDD. Cookies look good  will update once Ive tried them.                                     |             5 |
|     0 |      320 |     31614 |     5 | Great vendor Friendly comms and great products.                                                                                 |             5 |

#### Column descriptions for table `vendors`

* `name`: The name of the vendor.

### Table: `prices`

A complete listing of all price, sales, and rating observations for each listing. The name `prices` is a misnomer, and should be changed, since this table also contains seller characteristics as well.

#### First 10 rows of table `prices`

| location    |
|:------------|
|             |
| Netherlands |
| EU          |
| USA         |
| Canada      |
| Germany     |
| UK          |
| Internet    |
| China       |
| Sweden      |

#### Column descriptions for table `prices`

* `rating`: The aggregate rating of the vendor offering the listing to which this price belongs, at the time it was scraped. It ranges from 0 to 5.
* `vendor`: The id of the vendor who offers this listing. See `vendors` for a complete listing of vendors.
* `net_reviews`: The total number of reviews observed up to and including the date at which this listing was scraped.
* `price`: The price of the listing, in USD.
* `reviews_average_week`: Average number of new reviews received, per day, over the next week, for this listing.
* `dat`: The date at which this price was observed, in days since 1970.
* `max_sales`: The upper number of sales the vendor offering the listing to which this price belongs had made, at the time this price was scraped.
* `reviews_per_day`: Estimate of the number of reviews this listing was receiving per day at the time this listing was scraped.
* `net_reviews_smooth`: A smooth spline fitted to the reviews.
* `listing`: The id of the listing to which this price belongs.
* `min_sales`: The lower number of sales the vendor offering the listing to which this price belongs had made, at the time this price was scraped.
* `reviews_average_month`: Average number of new reviews received, per day, over the next month, for this listing.

### Table: `ships_to`

Complete list of locations listings ship to, the rowid is the id.

#### First 10 rows of table `ships_to`

| location                |
|:------------------------|
|                         |
| WorldWideexceptUSA      |
| Worldwide               |
| USA                     |
| EU                      |
| WorldWide               |
| EU,UK,CH,SWE,DK         |
| WorldwideExeptAUSTRALIA |
| UK,Euro,Worldwide       |
| WORLDWIDE               |

#### Column descriptions for table `ships_to`

* `location`: The name of the location.

### Table: `categories`

Contains a list of the categories to which listings might belong. The `rowid` is the id of the category.

#### First 10 rows of table `categories`

| name                  |
|:----------------------|
| Dr.Prof.Med.Apotheker |
| Big_Boy               |
| NAPP                  |
| DrawkwarD             |
| TheRoyalOil           |
| juliabela_original    |
| laWnmoWermAn          |
| kriminale2            |
| cashflow              |
| PureHeaven-Agora      |

#### Column descriptions for table `categories`

* `category`: Textual description of this category.

