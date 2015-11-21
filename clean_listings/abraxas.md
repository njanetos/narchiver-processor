# Documentation for dataset clean_listings/abraxas

Contains strings from listings files, with the HTML stripped out. Once the HTML has been stripped, the next stop is to extract data from these strings.

## Tables

### listings

Each row corresponds to a single listing page, on the date it was scraped. (That is, each listing should have more than one row, corresponding to different dates.)

####       category

The category to which this listing belongs.

####       reviews

All the reviews which were left.

####       vendor

The name of the vendor offering this listing

####       ships_from

The location this item ships from.

####       title

The name of this listing.

####       url

The stem of the url at which this listing was found.

####       price

The recorded price of this listing.

####       ships_to

The location this item ships to.

####       dat

The date on which this listing was scraped.

