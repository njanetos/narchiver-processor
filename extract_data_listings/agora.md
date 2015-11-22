# Documentation for dataset `extract_data_listings/agora`

[MISSING DATABASE DESCRIPTION]

## Tables

### Table: `ships_from`

[MISSING TABLE: ships_from]

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

* `location`: [MISSING COLUMN: ships_from.location]

### Table: `listings`

[MISSING TABLE: listings]

#### First 10 rows of table `listings`

| title                                                                        | vendor          |   category |   ships_from |   ships_to | units   |   amount |   quantity |
|:-----------------------------------------------------------------------------|:----------------|-----------:|-------------:|-----------:|:--------|---------:|-----------:|
| KILLA COKE 1G                                                                | thepillguyAUS   |          1 |            1 |          1 | g       |      1   |          1 |
| One 115mg Capsule of Rolling Buddha MDMA Sassafras Extract Escrow            | TheBestCannabis |          2 |            2 |          2 | mg      |    115   |          1 |
| 500g APHP                                                                    | starlight       |          3 |            1 |          1 | g       |    500   |          1 |
| Potassium chlorate 40g                                                       | TorChem         |          4 |            1 |          1 | g       |     40   |          1 |
| Tails Preloaded Bootable USB Flash Drive Current 1.0.1 version FREE SHIPPING | Peddler         |          5 |            1 |          1 |         |      0   |          1 |
| 500 Pills Rivotril 2 MG                                                      | Meds2Buy        |          6 |            3 |          3 | mg      |      2   |        500 |
| 250g of 99.8 PURE METHYLONE.  250 grams                                      | MrGuapo         |          3 |            4 |          4 | g       |    250   |          1 |
| MDMA Pills 200mg 5stk SUPERMANN gelb                                         | MIcasa-SUcasa   |          2 |            5 |          5 | mg      |    200   |        200 |
| USA ONLY  Clonodine .2mg                                                     | canadasunshine  |          7 |            1 |          1 | mg      |      0.2 |          1 |
| STHOMPSONSPEED PASTE 1gHIGH QUALITY                                          | huntersthompson |          8 |            5 |          6 | g       |      1   |          1 |

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

|        dat |   listing |     pricel |   rating |   min_sales |   max_sales | url               |
|-----------:|----------:|-----------:|---------:|------------:|------------:|:------------------|
| 1437562495 |         1 |  244.991   |    5     |          25 |          40 | %2Fp%2FCPRtFYaJd0 |
| 1426577697 |         2 |   14.3     |    4.957 |         500 |        1000 | %2Fp%2FXUd0DsSVMZ |
| 1441547341 |         3 | 2140       |    4.88  |         500 |        1000 | %2Fp%2FXUqqMG0FGU |
| 1430619342 |         4 |    9.99957 |    4.67  |          55 |          70 | %2Fp%2Fcv6GtuTYWw |
| 1430858829 |         5 |   19.9991  |    5     |          25 |          40 | %2Fp%2FremaSAdDA1 |
| 1416052591 |         6 |  460       |    5     |          25 |          40 | %2Fp%2FVnWuCbTNbJ |
| 1435913399 |         7 |  933.963   |    5     |          25 |          40 | %2Fp%2FpxR41eiJgn |
| 1441111488 |         8 |   22.849   |    4.96  |         200 |         300 | %2Fp%2FTaaCjhyM7f |
| 1417312912 |         9 |    5       |    4.95  |         500 |        1000 | %2Fp%2Fsgh64kWaUh |
| 1416112378 |        10 |   12.6     |    5     |         150 |         200 | %2Fp%2FiSRtBbfSdS |

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

|   dat |   listing | review                                   |   val |   price |   scraped_at |   user_rating |   user_deals |
|------:|----------:|:-----------------------------------------|------:|--------:|-------------:|--------------:|-------------:|
| 16556 |         1 | great stealth                            |     5 |         |        16638 |               |         1525 |
| 16495 |         4 | Thx                                      |     5 |         |        16558 |               |         1525 |
| 16429 |         5 | Great Vendor                             |     5 |         |        16560 |               |         2540 |
| 16662 |         8 | Fast shippingbonus                       |     5 |         |        16679 |               |         1015 |
| 16654 |         8 | Arrived after 2 days domestic            |     5 |         |        16679 |               |          610 |
| 16389 |        10 | Alles Super... Danke                     |     5 |         |        16390 |               |         1015 |
| 16385 |        10 | 5 days ship international                |     5 |         |        16390 |               |           35 |
| 16384 |        10 | 6 days ago                               |     5 |         |        16390 |               |          610 |
| 16382 |        10 | 8 days ago                               |     5 |         |        16390 |               |          610 |
| 16374 |        10 | Unbeatable Shipped in less than 24 hours |     5 |         |        16390 |               |           12 |

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

#### Column descriptions for table `ships_to`

* `location`: [MISSING COLUMN: ships_to.location]

### Table: `categories`

[MISSING TABLE: categories]

#### First 10 rows of table `categories`

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

#### Column descriptions for table `categories`

* `category`: [MISSING COLUMN: categories.category]

