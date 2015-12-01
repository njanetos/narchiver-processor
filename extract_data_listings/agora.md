# Documentation for dataset `extract_data_listings/agora`

[MISSING DATABASE DESCRIPTION]

## Tables

### Table: `ships_from`

[MISSING TABLE: ships_from]

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

* `location`: [MISSING COLUMN: ships_from.location]

### Table: `listings`

[MISSING TABLE: listings]

#### First 10 rows of table `listings`

| title                                                                             | vendor           |   category |   ships_from |   ships_to | units   |   amount |   quantity |
|:----------------------------------------------------------------------------------|:-----------------|-----------:|-------------:|-----------:|:--------|---------:|-----------:|
| Dior Logo Necklace Replica                                                        | foxygirl         |          1 |            1 |          1 |         |      0   |          1 |
| Chanel Sunglasses CHL5171 Replica blackblack frame white legs burgundy beige c952 | Bigdeal100       |          1 |            1 |          1 |         |      0   |          1 |
| Ice Crystal Meth 8 OZ 224 Grams  599 OZ .   Escrow  Stealth                       | VerdeLimon       |          2 |            1 |          1 | oz      |      8   |          1 |
| 2.5gr. Ketamine Risomer                                                           | Apotheke         |          3 |            1 |          1 | g       |      2.5 |          1 |
| 1.0 gram Risomer KETAMINE                                                         | Alex-Sosa        |          3 |            2 |          2 | g       |      1   |          1 |
| 12 oz AlienTrain                                                                  | UrLocalBudTender |          4 |            1 |          1 | oz      |     12   |          1 |
| Yohimbine Hydrochloride HCL 10g                                                   | Overdos3d        |          5 |            1 |          1 | g       |     10   |          1 |
| Bayer Dbol Dianabol Methandrostenolone 10mg x 100 tablets From EU                 | ThreeKings       |          6 |            3 |          3 | mg      |     10   |        100 |
| MDMA 5g                                                                           | MarcelKetman     |          7 |            1 |          1 | g       |      5   |          1 |
| FE SPECIAL 20 x 30mg Adderall IR Pills TEVABARRCheapest on Agora                  | FOCUSED          |          8 |            4 |          4 | mg      |     30   |         20 |

#### Column descriptions for table `listings`

* `category`: [MISSING COLUMN: listings.category]
* `vendor`: [MISSING COLUMN: listings.vendor]
* `ships_from`: [MISSING COLUMN: listings.ships_from]
* `title`: [MISSING COLUMN: listings.title]
* `ships_to`: [MISSING COLUMN: listings.ships_to]
* `amount`: [MISSING COLUMN: listings.amount]
* `units`: [MISSING COLUMN: listings.units]
* `quantity`: [MISSING COLUMN: listings.quantity]

### Table: `reviews`

[MISSING TABLE: reviews]

#### First 10 rows of table `reviews`

|        dat |   listing |    pricel |   rating |   min_sales |   max_sales | url               |
|-----------:|----------:|----------:|---------:|------------:|------------:|:------------------|
| 1436372350 |         1 |   50      |    5     |          40 |          55 | %2Fp%2Fn1ocApPnl0 |
| 1416638199 |         2 |   49.9986 |    4.98  |         100 |         150 | %2Fp%2FTc1SKeEUUD |
| 1439522202 |         3 | 4784.82   |    4.67  |         300 |         500 | %2Fp%2FeS1KmiWTLT |
| 1437264919 |         4 |  123.76   |    4.941 |        1000 |        1500 | %2Fp%2FL82Scxmx9N |
| 1412403260 |         5 |   59.9983 |    4.87  |          40 |          55 | %2Fp%2FXd9DLogYLn |
| 1437550313 |         6 |  129.995  |    4.93  |         500 |        1000 | %2Fp%2FoCy539A2EY |
| 1438407888 |         7 |   60      |    5     |         150 |         200 | %2Fp%2Fx4CSu7V2kg |
| 1438864023 |         8 |   27      |    4.949 |        1000 |        1500 | %2Fp%2Fgb1KuDqojl |
| 1426218434 |         9 |  160.995  |    4.952 |        1000 |        2000 | %2Fp%2FRgJFuPWG63 |
| 1430883821 |        10 |  275      |    4.07  |          55 |          70 | %2Fp%2FGgqrv4MtP6 |

#### Column descriptions for table `reviews`

* `user_rating`: [MISSING COLUMN: reviews.user_rating]
* `user_deals`: [MISSING COLUMN: reviews.user_deals]
* `val`: [MISSING COLUMN: reviews.val]
* `price`: [MISSING COLUMN: reviews.price]
* `listing`: [MISSING COLUMN: reviews.listing]
* `dat`: [MISSING COLUMN: reviews.dat]
* `review`: [MISSING COLUMN: reviews.review]
* `scraped_at`: [MISSING COLUMN: reviews.scraped_at]

### Table: `prices`

[MISSING TABLE: prices]

#### First 10 rows of table `prices`

|   dat |   listing | review                                                            |   val |   price |   scraped_at |   user_rating |   user_deals |
|------:|----------:|:------------------------------------------------------------------|------:|--------:|-------------:|--------------:|-------------:|
| 16630 |         4 | Update because of FE.no problems                                  |     5 |         |        16635 |               |          610 |
| 16625 |         4 | FE will update after product has arrived                          |     5 |         |        16635 |               |          610 |
| 16624 |         4 | FE  did arrive                                                    |     5 |         |        16635 |               |           35 |
| 16617 |         4 | FE for apotheke                                                   |     5 |         |        16635 |               |         1015 |
| 16617 |         4 | Excellent service and product  couldnt be any better              |     5 |         |        16635 |               |         1015 |
| 16597 |         4 | Good vendor                                                       |     5 |         |        16635 |               |          610 |
| 16596 |         4 | update product okthank                                            |     5 |         |        16635 |               |         1015 |
| 16595 |         4 | Very safe stealth... the k is very good will order more soon  Thx |     5 |         |        16635 |               |         1015 |
| 16589 |         4 | as always amazing vendor                                          |     5 |         |        16635 |               |         1525 |
| 16589 |         4 | alles super                                                       |     5 |         |        16635 |               |          610 |

#### Column descriptions for table `prices`

* `rating`: [MISSING COLUMN: prices.rating]
* `pricel`: [MISSING COLUMN: prices.pricel]
* `url`: [MISSING COLUMN: prices.url]
* `dat`: [MISSING COLUMN: prices.dat]
* `max_sales`: [MISSING COLUMN: prices.max_sales]
* `listing`: [MISSING COLUMN: prices.listing]
* `min_sales`: [MISSING COLUMN: prices.min_sales]

### Table: `ships_to`

[MISSING TABLE: ships_to]

#### First 10 rows of table `ships_to`

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

#### Column descriptions for table `ships_to`

* `location`: [MISSING COLUMN: ships_to.location]

### Table: `categories`

[MISSING TABLE: categories]

#### First 10 rows of table `categories`

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

#### Column descriptions for table `categories`

* `category`: [MISSING COLUMN: categories.category]

