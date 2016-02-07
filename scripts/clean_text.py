# Cleans out spaces, special characters, etc. from text

import re

def clean(messy):
    # Get rid of fractions if possible
    messy = messy.replace('1/2', '0.5')
    messy = messy.replace('1/4', '0.25')
    messy = messy.replace('1/8', '0.125')
    messy = messy.replace('3/8', '0.375')
    messy = messy.replace('3/4', '0.75')

    result = re.compile('[^A-Z,a-z,0-9, .,-\,]+')
    return result.sub('', messy).strip()
