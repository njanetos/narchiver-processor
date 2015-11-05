# Find all directories with blackbank in the title and pipe all files it contains to the appropriate directory

market = 'blackbank'

destinations = zip(['listings', 'vendors'], ['%2Fitem%2F', '2Fvendor%2F'])

execfile('scripts/sort_marketplace_common.py')
