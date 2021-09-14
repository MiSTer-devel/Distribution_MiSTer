#!/usr/bin/env python3
# Copyright (c) 2021 José Manuel Barroso Galindo <theypsilon@gmail.com>

import os
from pathlib import Path
import hashlib
import json
import time
import re
import subprocess
import sys
from datetime import datetime
import os
import tempfile

def benchtime(func):
    def benchfn(*args, **kwargs):
        begin_time = time.time()
        result = func(*args, **kwargs)
        end_time = time.time()
        print("%s: %ss" % (func.__name__, end_time - begin_time))
        return result

    return benchfn

@benchtime
def main():
    sha = run_stdout('git rev-parse --verify HEAD').strip()
    print('sha: %s' % sha)

    db_url = envvar('DB_URL')
    db_file_zip = Path(db_url).name
    db_file_json = Path(db_url).stem

    db = create_db('.', {
        'base_files_url': envvar('BASE_FILES_URL') % sha,
        'db_url': db_url,
        'db_files': [db_file_zip],
        'db_id': envvar('DB_ID'),
        'latest_zip_url': envvar('LATEST_ZIP_URL'),
        'linux_github_repository': os.getenv('LINUX_GITHUB_REPOSITORY', '').strip()
    })

    save_data_to_compressed_json(db, db_file_json, db_file_zip)
    force_push_file(db_file_zip, 'main')

def envvar(var):
    result = os.getenv(var)
    print("{} = {}".format(var, result))
    return result

def create_db(folder, options):

    finder = Finder(folder)
    folders = dict()

    db = {
        "db_id": options['db_id'],
        "db_url": options['db_url'],
        "db_files": options['db_files'],
        "latest_zip_url": options['latest_zip_url'],
        "files": dict()
    }

    delete_list_regex = re.compile("^(.*_)[0-9]{8}(\.[a-zA-Z0-9]+)*$", )

    for file in finder.find_all():
        strfile = str(file)
        folders[str(file.parent)] = True

        if file.name in ['.delme'] or strfile in ['README.md', 'LICENSE', 'latest_linux.txt']:
            continue

        db["files"][strfile] = {
            "url": options['base_files_url'] + strfile,
            "delete": delete_list(strfile, delete_list_regex),
            "size": size(file),
            "hash": hash(file)
        }

        if file.name.lower() == "boot.rom":
            db["files"][strfile]['overwrite'] = False

        if strfile in ['MiSTer', 'menu.rbf']:
            db["files"][strfile]['path'] = 'system'
            db["files"][strfile]['reboot'] = True

    folders.pop(folder, None)

    db["folders"] = sorted(list(folders.keys()))
    db["files_count"] = len(db["files"])
    db["folders_count"] = len(db["folders"])

    if options['linux_github_repository'] != '':
        db["linux"] = create_linux_description(options['linux_github_repository'])

    return db

def create_linux_description(repository):
    sd_installer_output = run_stdout('curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/%s/git/trees/HEAD' % repository)
    sd_installer_json = json.loads(sd_installer_output)

    releases = sorted([x['path'] for x in sd_installer_json['tree'] if x['path'][0:8].lower() == 'release_' and x['path'][-3:].lower() == '.7z'])

    latest_release = releases[-1]
    url_linux = 'https://raw.githubusercontent.com/%s/%s/%s' % (repository, sd_installer_json['sha'], latest_release)
    with tempfile.NamedTemporaryFile(delete=False) as tmp_file:
        run_succesfully('curl --show-error --fail --location -o "%s" "%s"' % (tmp_file.name, url_linux))

        return {
            "url": url_linux,
            "delete": [],
            "size": size(tmp_file.name),
            "hash": hash(tmp_file.name),
            "version": Path(latest_release).stem[-6:]
        }

def save_data_to_compressed_json(db, json_name, zip_name):

    with open(json_name, 'w') as f:
        json.dump(db, f, sort_keys=True)

    run_succesfully('touch -a -m -t 202108231405 %s' % json_name)
    run_succesfully('zip -q -D -X -9  %s %s' % (zip_name, json_name))

def force_push_file(file_name, branch):
    run_succesfully('git add %s' % file_name)
    run_succesfully('git commit -m "-"')
    run_succesfully('git push --force origin %s' % branch)
    print()
    print("New %s ready to be used." % file_name)

def run_conditional(command):
    result = subprocess.run(command, shell=True, stderr=subprocess.DEVNULL, stdout=subprocess.PIPE)

    stdout = result.stdout.decode()
    if stdout.strip():
        print(stdout)
        
    return result.returncode == 0

def run_succesfully(command):
    result = subprocess.run(command, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)

    stdout = result.stdout.decode()
    stderr = result.stderr.decode()
    if stdout.strip():
        print(stdout)
    
    if stderr.strip():
        print(stderr)

    if result.returncode != 0:
        raise Exception("subprocess.run Return Code was '%d'" % result.returncode)

def run_stdout(command):
    result = subprocess.run(command, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)

    if result.returncode != 0:
        raise Exception("subprocess.run Return Code was '%d'" % result.returncode)

    return result.stdout.decode()

def delete_list(strfile, regex):
    matches = regex.match(strfile)
    if matches:
        return [matches.group(1) + "*"]

    return []

def hash(file):
    with open(file, "rb") as f:
        file_hash = hashlib.md5()
        chunk = f.read(8192)
        while chunk:
            file_hash.update(chunk)
            chunk = f.read(8192)
        return file_hash.hexdigest()

def size(file):
    return os.path.getsize(file)

class Finder:
    def __init__(self, dir):
        self._dir = dir
        self._not_in_directory = [dir + '/.git', dir + '/.github']

    def find_all(self):
        return sorted(self._scan(self._dir), key=lambda file: file.name.lower())

    def _scan(self, directory):
        for entry in os.scandir(directory):
            if entry.is_dir(follow_symlinks=False):
                if entry.path not in self._not_in_directory:
                    yield from self._scan(entry.path)
            else:
                yield Path(entry.path)

if __name__ == '__main__':
    main()
