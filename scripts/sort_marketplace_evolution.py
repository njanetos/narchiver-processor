# Find all directories with evolution in the title and pipe all files it contains to the appropriate directory

market = 'evolution'

destinations = zip(['listings', 'categories'], ['%2Flisting%2F', '%2Fcategory%2F'])

execfile('scripts/sort_marketplace_common.py')
