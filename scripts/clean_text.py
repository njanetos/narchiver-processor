# Cleans out spaces, special characters, etc. from text

import re

def clean(messy):
    result = re.compile('[^A-Z,a-z,0-9, .,-\,]+')
    return result.sub('', messy).strip()
