# Find all directories with abraxas in the title and pipe all files it contains to the appropriate directory

import os
import re
from update_progress import update_progress
from update_progress import print_progress

# Create the destination folders
for d, m in destinations:
	if not os.path.exists(os.path.join('raw_by_site', market, d)):
	    os.makedirs(os.path.join('raw_by_site', market, d))
if not os.path.exists(os.path.join('raw_by_site', market, 'remaining')):
	os.makedirs(os.path.join('raw_by_site', market, 'remaining'))

# Find the set of existing files and convert to hashed list
existing_files = []
for root, dirnames, filenames in os.walk('raw_by_site/' + market):
	for f in filenames:
		existing_files.append(f)
existing_files = frozenset(existing_files)

# Find all the directories with the marketplace name in the title
dirs = []
for root, dirnames, filenames in os.walk('raw'):
	for dirname in [d for d in dirnames if market in d]:
		dirs.append(os.path.join(root + '/' + dirname))

tot_count = len(dirs)

# Go through and remove the CSS unless they already exist.
count = 0
for d in dirs:
	for root, dirnames, filenames in os.walk(d):
		for f in filenames:
			if not f in existing_files:

				# Identify the Final Destination IV of this file
				dest_dir = 'remaining'
				for d, m in destinations:
					if m in f:
						dest_dir = d

				# Read it, remove CSS, and write it out
				with open (os.path.join(root, f)) as open_file:
					value = open_file.read()
					#value = re.sub('(<style ?type ?= ?"text/css">)(.*?)(<\/style>)', '', value)
					#value = re.sub('(<img)(.*?)(>)', '', value)
					#value = re.sub('(<head)(.*?)(head>)', '', value)
				with open(os.path.join('raw_by_site', market, dest_dir, f), "w") as open_file:
					open_file.write(value)
	count = count + 1
	update_progress(count, tot_count)

print_progress("Finished sorting " + market)
