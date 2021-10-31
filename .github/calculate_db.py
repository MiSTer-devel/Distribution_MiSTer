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
import shutil
from typing import Protocol, Any


class Finder:
    def __init__(self, dir):
        self._dir = dir
        self._not_in_directory = []

    @property
    def dir(self):
        return self._dir

    def ignore_folder(self, folder):
        directory = str(Path(folder))
        print('ignore_folder: %s' % directory)
        self._not_in_directory.append(directory)

    def find_all(self):
        return sorted(self._scan(self._dir), key=lambda file: str(file).lower())

    def _scan(self, directory):
        for entry in os.scandir(directory):
            if entry.is_dir(follow_symlinks=False):
                if str(Path(entry.path)) not in self._not_in_directory:
                    yield from self._scan(entry.path)
            else:
                yield Path(entry.path)


class EmptyFinder(Finder):
    def __init__(self):
        Finder.__init__(self, None)

    def find_all(self):
        return []


def benchtime(func):
    def benchfn(*args, **kwargs):
        begin_time = time.time()
        result = func(*args, **kwargs)
        end_time = time.time()
        print("%s: %ss" % (func.__name__, end_time - begin_time))
        return result

    return benchfn


@benchtime
def main(dryrun):
    sha = run_stdout('git rev-parse --verify HEAD').strip()
    print('sha: %s' % sha)

    db_url = envvar('DB_URL')
    db_file_zip = Path(db_url).name
    db_file_json = Path(db_url).stem

    db = create_db('.', {
        'sha': sha,
        'base_files_url': envvar('BASE_FILES_URL'),
        'db_url': db_url,
        'db_files': [db_file_zip],
        'db_id': envvar('DB_ID'),
        'dryrun': dryrun,
        'latest_zip_url': envvar('LATEST_ZIP_URL'),
        'linux_github_repository': os.getenv('LINUX_GITHUB_REPOSITORY', '').strip(),
        'zips_config': os.getenv('ZIPS_CONFIG', '').strip()
    })

    save_data_to_compressed_json(db, db_file_json, db_file_zip)
    if not dryrun:
        force_push_file(db_file_zip, 'main')


def envvar(var):
    result = os.getenv(var)
    print("{} = {}".format(var, result))
    return result


def create_db(folder, options):
    db_finder = Finder(folder)
    db_finder.ignore_folder('./.git')
    db_finder.ignore_folder('./.github')
    db = {
        "db_id": options['db_id'],
        "db_url": options['db_url'],
        "db_files": options['db_files'],
        "latest_zip_url": options['latest_zip_url'],
        "files": dict(),
        "base_files_url": options['base_files_url'] % options['sha']
    }

    zips = dict()

    if options['zips_config'] != '':
        print('reading zips_config: ' + options['zips_config'])
        with open(options['zips_config']) as zips_config_file:
            zips_config = json.load(zips_config_file)
            for zip_id in zips_config:
                zip_description = zips_config[zip_id]
                zip_creator = make_zip_creator(zip_description)
                zip_creator.create_zip(db_finder, zips, zip_id, zip_description, options)

    if len(zips) > 0:

        current_branch = run_stdout('git rev-parse --abbrev-ref HEAD').strip()
        if current_branch == 'zips':
            raise Exception('Should not start on branch "zip"')

        run_succesfully('git branch -D zips || true')
        run_succesfully('git checkout --orphan zips')
        run_succesfully('git reset')

        for zip_id in zips:
            run_succesfully('git add %s.zip' % zip_id)
            run_succesfully('git add %s_summary.json.zip' % zip_id)

        run_succesfully('git commit -m "-"')
        zip_sha = run_stdout('git rev-parse --verify HEAD').strip()

        if not options['dryrun']:
            run_succesfully('git fetch origin main || true')
            if not run_conditional('git diff --quiet main origin/zip'):
                print('zip branch has changes')
                run_succesfully('git push --force origin zips')
            else:
                print('Using old zip branch from origin')
                zip_sha = run_stdout('git rev-parse --verify origin/zip').strip()

        print('zip_sha: ' + zip_sha)

        run_succesfully('git checkout --force ' + current_branch)

        for zip_id in zips:
            zips[zip_id]['contents_file']['url'] = (options['base_files_url'] % zip_sha) + '%s.zip' % zip_id
            zips[zip_id]['summary_file']['url'] = (options['base_files_url'] % zip_sha) + '%s_summary.json.zip' % zip_id

    db_summary = create_summary(db_finder, options)
    db['files'] = db_summary['files']
    db['folders'] = db_summary['folders']
    db['zips'] = zips
    db['files_count'] = db_summary['files_count']
    db['folders_count'] = db_summary['folders_count']

    if options['linux_github_repository'] != '':
        db["linux"] = create_linux_description(options['linux_github_repository'])

    return db


class ZipCreator(Protocol):
    def create_zip(self, db_finder: Finder, zips: [str, Any], zip_id: str, zip_description: [str, Any], options: [str, Any]) -> None:
        pass


def make_zip_creator(zip_description: [str, Any]) -> ZipCreator:
    mode = zip_description['mode'] if 'mode' in zip_description else 'simple'

    if mode == 'simple':
        return SimpleZipCreator()
    elif mode == 'subfolders':
        return SubfoldersZipCreator()
    elif mode == 'multi':
        return MultiSourcesZipCreator()
    else:
        raise NotImplementedError('No ZipCreator for mode: ' + mode)


class SimpleZipCreator:
    def create_zip(self, db_finder: Finder, zips: [str, Any], zip_id: str, zip_description: [str, Any], options: [str, Any]) -> None:
        source_path = Path(zip_description['source'])
        zip_description['sources'] = [source_path.name]
        zip_description['path'] = str(source_path.parent)
        multi = MultiSourcesZipCreator()
        multi.create_zip(db_finder, zips, zip_id, zip_description, options)
        return


class SubfoldersZipCreator:
    def create_zip(self, db_finder: Finder, zips: [str, Any], zip_id: str, zip_description: [str, Any], options: [str, Any]) -> None:
        simple = SimpleZipCreator()
        for folder in [entry.path for entry in os.scandir(zip_description['source']) if entry.is_dir(follow_symlinks=False)]:
            if len(Finder(folder).find_all()) < 60:
                continue
            simple.create_zip(db_finder, zips, zip_id + Path(folder).name.lower(), {"source": folder}, options)


class MultiSourcesZipCreator:
    def create_zip(self, db_finder: Finder, zips: [str, Any], zip_id: str, zip_description: [str, Any], options: [str, Any]) -> None:
        print('Processing zip_id: %s' % zip_id)

        source_parent = zip_description['path']
        summary_name = '%s_summary.json' % zip_id

        multi_summary = create_summary(EmptyFinder(), options)

        source_name_list = []
        for source in zip_description['sources']:
            db_finder.ignore_folder('./' + source_parent + '/' + source)
            zip_finder = Finder(source_parent + '/' + source)
            zip_summary = create_summary(zip_finder, options)
            zip_summary['folders'][str(Path(source_parent + '/' + source))] = {}
            multi_summary['files_count'] += zip_summary['files_count']
            multi_summary['folders_count'] += zip_summary['folders_count']
            multi_summary['files'].update(zip_summary['files'])
            multi_summary['folders'].update(zip_summary['folders'])
            source_name_list.append(Path(source).name)

        multi_summary['folders'] = multi_summary['folders']

        zip_description['raw_files_size'] = 0
        zip_description['path'] = source_parent + '/'
        zip_description['contents'] = zip_description['sources']
        zip_description['files_count'] = multi_summary['files_count']
        zip_description['folders_count'] = multi_summary['folders_count']
        zip_description['base_files_url'] = options['base_files_url'] % options['sha']
        zip_description.pop('sources')

        for folder in multi_summary['folders']:
            multi_summary['folders'][folder]['zip_id'] = zip_id

        for file in multi_summary['files']:
            multi_summary['files'][file]['zip_id'] = zip_id
            zip_description['raw_files_size'] += multi_summary['files'][file]['size']

        summary_zip = summary_name + '.zip'

        save_data_to_compressed_json(multi_summary, summary_name, summary_zip)
        zip_description['summary_file'] = {
            'size': size(summary_zip),
            'hash': hash(summary_zip)
        }
        Path(summary_name).unlink()

        zip_name = zip_id + '.zip'

        run_succesfully('cur=$(pwd) && cd %s && zip -q -D -X -A -r $cur/%s %s' % (source_parent, zip_name, " ".join(source_name_list)))
        zip_description['contents_file'] = {
            'size': size(zip_name),
            'hash': hash(zip_name)
        }

        zips[zip_id] = zip_description
        print('Created zip: ' + zip_name)


def create_summary(finder: Finder, options):
    delete_list_regex = re.compile("^(.*_)[0-9]{8}(\.[a-zA-Z0-9]+)*$", )

    summary = {
        'files': dict(),
        'folders': dict()
    }

    for file in finder.find_all():
        strfile = str(file)
        summary['folders'][str(file.parent)] = {}

        if file.name in ['.delme'] or strfile in ['README.md', 'LICENSE', 'latest_linux.txt']:
            continue

        summary["files"][strfile] = {
            "size": size(file),
            "hash": hash(file)
        }

        delete_list = create_delete_list(strfile, delete_list_regex)
        if len(delete_list) > 0:
            summary["files"][strfile]["delete"] = delete_list

        if file.name.lower() == "boot.rom":
            summary["files"][strfile]['overwrite'] = False

        if strfile in ['MiSTer', 'menu.rbf']:
            summary["files"][strfile]['path'] = 'system'
            summary["files"][strfile]['reboot'] = True

    summary['folders'].pop(finder.dir, None)

    summary['files_count'] = len(summary['files'])
    summary['folders_count'] = len(summary['folders'])
    return summary


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


def create_delete_list(strfile, regex):
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


if __name__ == '__main__':
    dryrun = len(sys.argv) == 2 and sys.argv[1] == '-d'
    main(dryrun)
