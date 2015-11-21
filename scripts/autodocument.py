import sqlite3 as lite
import sys
import os
import re
import json
import copy
from update_progress import update_progress
from update_progress import print_progress

if len(sys.argv) == 1:
    print("Missing arguments")
    quit(1)

if not os.path.isfile(sys.argv[1]):
    print("Failed to find " + sys.argv[1])
    quit(0)

extension = sys.argv[1].replace('./', '').split('.')
print extension

if len(extension) != 2:
    print("Malformed file name " + sys.argv[1].replace('./', ''))
    quit(1)

clean = '--clean' in sys.argv

name = extension[0].split('/')[-1]
extension = extension[1]
root = sys.argv[1].replace('./', '').split('/')
root = root[:-1]
root = os.path.join(root)

markdown_file = os.path.join("".join(os.path.join(root)), name + '.md')

if extension == 'db':

    # Get the schema
    read = lite.connect(sys.argv[1])
    read_cur = read.cursor()

    read_cur.execute("SELECT name, sql FROM sqlite_master WHERE type='table' ORDER BY name")
    results = read_cur.fetchall()

    doc_file = os.path.join("".join(os.path.join(root)), name + '.json')

    # Check that the schema is up to date
    if not os.path.isfile(doc_file):
        with open(doc_file, "w") as file:
            file.write("{}")

    with open(doc_file, "r") as file:
        doc_json = file.read()
        try:
            doc_json = json.loads(doc_json)
        except ValueError, e:
            doc_json = json.loads("{}")

    # Check that all the tables are there
    names = []
    schemas = []

    for r in results:
        name = r[0]
        names.append(name)
        schema = re.search('(?<=\()(.*)(?=\))', re.sub('[A-Z ]', '', r[1])).group(0).split(',')
        schemas.append(schema)

        if name not in doc_json:
            doc_json[name] = {}
            doc_json[name]['table_doc'] = "[MISSING TABLE: " + name + "]"
            for s in schema:
                doc_json[name][s] = "[MISSING COLUMN: " + name + '.' + s + "]"
        else:
            for s in schema:
                if s not in doc_json[name]:
                    doc_json[name][s] = "[MISSING COLUMN: " + name + '.' + s + "]"

    # Check if database documentation is there
    if 'data_doc' not in doc_json:
        doc_json['data_doc'] = "[MISSING DATABASE DESCRIPTION]"

    # Check for removed categories, if clean is on
    if clean:
        names = [r[0] for r in results]
        temp_doc = copy.deepcopy(doc_json)
        for d in doc_json:
            if d not in names and d != 'data_doc':
                del temp_doc[d]
            elif d != 'data_doc':
                ind = names.index(d)
                for s in doc_json[d]:
                    if s not in schemas[ind] and s != 'table_doc':
                        del temp_doc[d][s]
        doc_json = temp_doc

    with open(doc_file, "w") as file:
        file.write(json.dumps(doc_json, indent = 4, sort_keys=True, separators=(',', ': ')))

    # Complain!
    bad = re.findall('\[MISSING', json.dumps(doc_json, indent = 4, sort_keys=True, separators=(',', ': ')))
    if len(bad) > 0:
        print_progress('Parsed ' + doc_file)
        print_progress('')
        print_progress('')
        print_progress('------------------------- WARNING! -------------------------')
        print_progress(str(len(bad)) + ' instances of undocumented columns detected.')
        print_progress('')
        print_progress('     DOCUMENT THEM IMMEDIATELY OR YOU WILL BE PUNISHED')
        print_progress('')
        print_progress('')
    else:
        print_progress('Parsed ' + doc_file)

else:
    print("Unrecognized file extension: " + extension)
    quit(1)

# Write to Markdown
with open(markdown_file, "w") as file:

    file.write("# Documentation for dataset " + markdown_file.split('.')[0])
    file.write("\n\n")

    file.write(doc_json['data_doc'])
    file.write("\n\n")

    file.write("## Tables")
    file.write("\n\n")

    for d in [d for d in doc_json if d != 'data_doc']:
        file.write("### " + d)
        file.write("\n\n")
        file.write(doc_json[d]['table_doc'])
        file.write("\n\n")
        for s in [s for s in doc_json[d] if s != 'table_doc']:
            file.write("* " + "__" + s + "__: " + doc_json[d][s] + '\n')
        file.write('\n')
