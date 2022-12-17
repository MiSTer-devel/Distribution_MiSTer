#!/usr/bin/env python3
# Copyright (c) 2022 José Manuel Barroso Galindo <theypsilon@gmail.com>

import subprocess
import json
import sys

if len(sys.argv) < 2 or len(sys.argv) > 3:
    print(f'Wrong arguments.\n\nUsage:\n{sys.argv[0]} <url> [ref_url]')
    exit(1)

def run(cmd, stdout=None):
    result = subprocess.run(cmd, stderr=subprocess.STDOUT, stdout=stdout)
    if result.returncode != 0:
        raise subprocess.CalledProcessError(result.returncode, cmd)
    return result

def download(url):
    run(['curl', '-L', '-o', '/tmp/existing.json', url])
    return run(['unzip', '-p', '/tmp/existing.json'], stdout=subprocess.PIPE).stdout.decode()

def get_url_db(url):
    print("Downloading db from " + url)
    return json.loads(download(url))

def sub(left, right):
    return [i for i in left if i not in right]

other = get_url_db(sys.argv[1].strip())
dist = get_url_db("https://raw.githubusercontent.com/MiSTer-devel/Distribution_MiSTer/main/db.json.zip" if len(sys.argv) < 3 else sys.argv[2].strip())

def diff(key):
    missing = sub(dist[key], other[key])
    if len(missing):
        print()
        print(f'missing {key}:')
        for miss in missing:
            print(miss)

    extra = sub(other[key], dist[key])
    if len(extra):
        print()
        print(f'extra {key}:')
        for x in extra:
            print(x)

diff('files')
diff('folders')
diff('zips')
diff('tag_dictionary')

tags = lambda collection: {collection['tag_dictionary'][word]: word for word in sorted(collection['tag_dictionary'])}
other_tags = tags(other)
dist_tags = tags(dist)

def intersect(left, right):
    return [i for i in left if i in right]

def tag_missmatches(key):
    common = intersect(dist[key], other[key])
    for e in common:
        entity_tags = lambda col_tags, collection: {col_tags[t] for t in collection[key][e].get('tags', [])}
        left, right = entity_tags(dist_tags, dist), entity_tags(other_tags, other)
        missmatches = [*sub(left, right), *sub(right, left)]
        if len(missmatches) > 0:
            print()
            print(f'tag missmatch at {key}:{e}:')
            for miss in missmatches:
                print(miss)

tag_missmatches('files')
tag_missmatches('folders')
