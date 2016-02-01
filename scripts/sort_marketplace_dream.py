# Find all directories with dream in the title and pipe all files it contains to the appropriate directory

market = 'dream'

destinations = zip(['listings'], ['%2FviewProduct%3F'])

exec(open('scripts/sort_marketplace_common.py').read())
