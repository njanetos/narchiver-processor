from update_progress import update_progress
from update_progress import print_progress
import sqlite3 as lite

# Paths
path            = 'clean_listings/' + market + '.db'
output_path 	= 'compiled_listings/'
output_file 	= 'temp.db'
final_output    = market + '.db'

try:
    os.remove(output_path + output_file)
except OSError:
    pass

if not os.path.exists(output_path):
    os.makedirs(output_path)

print_progress("Compiling the listings for the " + market + " market.")
print_progress("Connecting to " + output_file)
