# Find all directories with nucleus in the title and pipe all files it contains to the appropriate directory

market = 'nucleus'

destinations = zip(['vendors', 'listings'], ['%2Fuser%2F', '%2Fitem%2F'])

exec(open('scripts/sort_marketplace_common.py').read())
