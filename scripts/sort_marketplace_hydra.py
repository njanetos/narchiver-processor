# Find all directories with hydra in the title and pipe all files it contains to the appropriate directory

market = 'hydra'

destinations = zip(['listings', 'vendors'], ['%2Fsale%2F', '%2Fvendor%2F'])

exec(open('scripts/sort_marketplace_common.py').read())
