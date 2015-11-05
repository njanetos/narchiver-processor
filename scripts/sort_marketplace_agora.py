# Find all directories with agora in the title and pipe all files it contains to the appropriate directory

market = 'agora'

destinations = zip(['vendors', 'listings'], ['%2Fvendor%2F', '%2Fp%2F'])

execfile('scripts/sort_marketplace_common.py')
