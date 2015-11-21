# Documentation for dataset clean_listings/nucleus

Contains strings from listings files, with the HTML stripped out. Once the HTML has been stripped, the next stop is to extract data from these strings.

## Tables

### listings

Each row corresponds to a single listing page, on the date it was scraped. (That is, each listing should have more than one row, corresponding to different dates.)

* __category__: The category to which this listing belongs.
* __reviews__: All the reviews which were left.
* __vendor__: The name of the vendor offering this listing
* __ships_from__: The location this item ships from.
* __title__: The name of this listing.
* __url__: The stem of the url at which this listing was found.
* __price__: The recorded price of this listing.
* __ships_to__: The location this item ships to.
* __dat__: The date on which this listing was scraped.

