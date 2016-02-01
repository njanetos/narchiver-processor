# Find all directories with marketplace in the title and pipe all files it contains to the appropriate directory

market = 'marketplace'

destinations = zip(['listings', 'vendors'], ['%2Fproduct%2F', '%2Fvendor%2F'])

exec(open('scripts/sort_marketplace_common.py').read())
