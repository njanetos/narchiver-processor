# Find all directories with abraxas in the title and pipe all files it contains to the appropriate directory

market = 'abraxas'

destinations = zip(['vendors', 'categories', 'listings'], ['%2Fvendor%2F', '2Fc%2F', '%2Flisting%2F'])

execfile('scripts/sort_marketplace_common.py')
