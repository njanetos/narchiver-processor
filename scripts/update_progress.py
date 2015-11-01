import time, sys, inspect

root_file = inspect.stack()[-1][1]

def print_progress(progress):
	barLength = 80
	if isinstance(progress, float):
		block = int(round(barLength*progress))
		sys.stdout.write("\r" + " "*(barLength+20))
		sys.stdout.flush()
		sys.stdout.write("\r[" + "="*(block-1) + ">" + " "*(barLength-block) + "] " + str(int(100*progress)) + "%")
		sys.stdout.flush()
	elif isinstance(progress, str):
		sys.stdout.write("\r" + " "*(barLength+20))
		sys.stdout.flush()
		sys.stdout.write('\r' + "[" + root_file + "] " + progress + '\n')
		sys.stdout.flush()

def update_progress(progress, total):
	# Update the progress
    if (progress % (total//100) == 0):
		print_progress(float(progress) / float(total))
