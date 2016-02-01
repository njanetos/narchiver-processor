# Find all directories with silkroad in the title and pipe all files it contains to the appropriate directory

market = 'silkroad'

destinations = zip(['listings'], ['%2Fitems%2F'])

exec(open('scripts/sort_marketplace_common.py').read())
