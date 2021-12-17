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
import os
import tempfile
import xml.etree.cElementTree as ET
from inspect import currentframe, getframeinfo
from typing import Dict, List, Any


distribution_mister_aliases = [
    # Consoles
    ['nes', 'famicom', 'nintendo'],
    ['snes', 'sufami', 'supernes', 'supernintendo', 'superfamicom'],
    ['pcengine', 'tgfx16', 'turbografx16', 'turbografx'],
    ['pcenginecd', 'tgfx16cd', 'turbografx16cd', 'turbografxcd'],
    ['megadrive', 'genesis'],
    ['megacd', 'segacd'],
    ['sms', 'mastersystem'],
    ['coleco', 'colecovision'],

    # Computers
    ['vector06c', 'vector06'],
    ['amiga', 'minimig'],
    
    # General
    ['console-cores', 'console'],
    ['arcade-cores', 'arcade'],
    ['computer-cores', 'computer'],
    ['other-cores', 'other'],
    ['service-cores', 'utility'],
]


filter_part_regex = re.compile("[-_a-z0-9.]$", )


class Tags:
    def __init__(self) -> None:
        self._dict = {}
        self._alternatives = {}
        self._index = 0
        self._report_set = set()

    def init_aliases(self, aliases):
        for alias_list in aliases:
            for alias in alias_list:
                self._dict[self._clean_term(alias)] = self._index
            self._index += 1

    def get_tags_for_file(self, path: Path):
        parent = path.parts[0].lower()
        if parent[0] == '_':
            parent = parent[1:]

        result = []
        if len(path.parts) > 1:
            self._append(result, self._get_term(parent))

        self._add_cores_terms(parent, result)

        suffix = path.suffix.lower()
        stem = path.stem.lower()

        if (stem == 'readme' or (parent == 'games' and 'readme' in stem)) and (suffix == '.txt' or suffix == '.md'):
            self._append(result, self._get_term('docs'))
            self._append(result, self._get_term('readme'))
            
        elif suffix == '.mra':
            self._append(result, self._get_term('mra'))
            mra_fields = read_mra_fields(path, ['rbf'])
            if 'rbf' in mra_fields and not mra_fields['rbf']:
                mra_fields.pop('rbf')
            else:
                mra_fields['rbf'] = mra_fields['rbf'].lower()

            if 'rbf' in mra_fields:
                self._append(result, self._get_arcade_term(mra_fields['rbf']))

            if len(path.parts) > 1 and path.parts[1].lower() == '_alternatives':
                self._append(result, self._get_term('alternatives'))

                if 'rbf' in mra_fields and len(path.parts) > 2:
                    alternative_subfolder = path.parts[2].lower()[1:]
                    if alternative_subfolder not in self._alternatives:
                        self._alternatives[alternative_subfolder] = set()
                    self._alternatives[alternative_subfolder].add(mra_fields['rbf'])

        elif suffix == '.rbf':
            nodates = stem[0:-9]
            if not nodates:
                nodates = stem

            self._append(result, self._get_term('cores'))
            if parent == 'arcade':
                self._append(result, self._get_arcade_term(nodates))
            else:
                self._append(result, self._get_term(nodates))

            if nodates in ['gba2p', 'gameboy2p']:
                self._append(result, self._get_term('handheld2p'))

        if parent == 'games':
            first_level = path.parts[1].lower()
            self._append(result, self._get_term(first_level))
            if path.parts[2].lower() == 'palettes':
                self._append(result, self._get_term('palettes'))
            if first_level in ['gba2p', 'gameboy2p']:
                self._append(result, self._get_term('handheld2p'))
        elif parent == 'cheats':
            self._append(result, self._get_term(path.parts[1].lower()))

        if parent in ['gamma', 'filters', 'filters_audio', 'shadow_masks']:
            self._append(result, self._get_term('all_filters'))
        
        if parent in ['gamma', 'filters', 'shadow_masks']:
            self._append(result, self._get_term('filters_video'))

        if stem in ['menu', 'mister']:
            self._append(result, self._get_term('essential'))

        return result

    def get_tags_for_folder(self, path: Path):
        if len(path.parts) == 0:
            return []

        parent = path.parts[0].lower()
        if parent[0] == '_':
            parent = parent[1:]

        result = [self._get_term(parent)]

        if parent in ['console', 'computer', 'other', 'utility']:
            self._append(result, self._get_term('cores'))
        
        self._add_cores_terms(parent, result)

        if len(path.parts) == 1:
            return result

        first_level = path.parts[1].lower()
        if first_level[0] == '_':
            first_level = first_level[1:]

        if parent == 'games' and first_level in ['gba2p', 'gameboy2p']:
            self._append(result, self._get_term('handheld2p'))

        self._append(result, self._get_term(first_level))
            
        if len(path.parts) == 2:
            return result
                
        second_level = path.parts[2].lower()
        if second_level[0] == '_':
            second_level = second_level[1:]

        if parent == 'arcade' and first_level == 'alternatives':
            if second_level in self._alternatives:
                for rbf in self._alternatives[second_level]:
                    if not rbf:
                        continue
                    self._append(result, self._get_arcade_term(rbf))

        if second_level in ['palettes']:
            self._append(result, self._get_term(second_level))

        return result

    def _get_term(self, term: str):
        return self._from_dict(self._clean_term(term))

    def _get_arcade_term(self, term: str):
        return self._from_dict(self._clean_term('arcade-' + term))

    def _get_cores_term(self, term: str):
        return self._from_dict(self._clean_term(term + '-cores'))

    def _clean_term(self, term: str):
        if not term:
            raise Exception('Term is empty')
        result = ''.join(filter(lambda chr: filter_part_regex.match(chr), term.replace(' ', '')))
        self._report_set.add(result)
        return result.replace('-', '').replace('_', '')

    def _from_dict(self, term: str):
        if term == 'menu.rbf':
            raise Exception('should not happen')
        if not term:
            raise Exception('Term is empty')
        if term not in self._dict:
            self._dict[term] = self._index
            self._index += 1

        return self._dict[term]

    def _add_cores_terms(self, parent, result):
        if parent in ['console', 'computer', 'other', 'arcade']:
            self._append(result, self._get_cores_term(parent))
        elif parent == 'utility':
            self._append(result, self._get_cores_term('service'))

    def _append(self, result, term):
        if term in result:
            return
        result.append(term)

    def get_dictionary(self):
        return self._dict

    def get_report_terms(self):
        return sorted(list(self._report_set))


class Finder:
    def __init__(self, dir: str):
        self._dir = dir
        self._not_in_directory = []

    @property
    def dir(self):
        return self._dir

    def ignore_folder(self, folder: str):
        directory = str(Path(folder))
        print('ignore_folder: %s' % directory)
        self._not_in_directory.append(directory)

    def find_all(self) -> List[Path]:
        return sorted(self._scan(self._dir), key=lambda file: str(file).lower())

    def _scan(self, directory: str) -> List[Path]:
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

    tags = Tags()

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
    }, tags)

    save_data_to_compressed_json(db, db_file_json, db_file_zip)

    tag_list = '`' + '`, `'.join(tags.get_report_terms()) + '`'
    print('TAG_LIST: ' + tag_list)

    with open("README.md", "rt") as fin:
        readme_content = fin.read()

    with open("README.md", "wt") as fout:
        fout.write(readme_content.replace('ALL_TAGS_GO_HERE', tag_list))

    if not dryrun:
        force_push_file(db_file_zip, 'main')


def envvar(var):
    result = os.getenv(var)
    print("{} = {}".format(var, result))
    return result


def create_db(folder, options, tags):
    tags.init_aliases(distribution_mister_aliases)

    db_finder = Finder(folder)
    db_finder.ignore_folder('./.git')
    db_finder.ignore_folder('./.github')
    db = {
        "db_id": options['db_id'],
        "db_url": options['db_url'],
        "db_files": options['db_files'],
        "latest_zip_url": options['latest_zip_url'],
        "files": dict(),
        "base_files_url": options['base_files_url'] % options['sha'],
        "default_options": dict(),
        "timestamp": int(time.time())
    }

    zips = dict()
    zip_creators = []
    stored_folders = []

    if options['zips_config'] != '':
        print('reading zips_config: ' + options['zips_config'])
        with open(options['zips_config']) as zips_config_file:
            zips_config = json.load(zips_config_file)
            for zip_id in zips_config:
                zip_description = zips_config[zip_id]
                make_zip_creator(zip_description)\
                    .create_zip(db_finder, zips, zip_id, zip_description, options, tags, stored_folders, zip_creators)

    db_summary = create_summary(db_finder, tags)
    db['files'] = db_summary['files']
    db['folders'] = db_summary['folders']

    print("Fixing folders...")

    for folders in stored_folders:
        fix_folders(folders, tags)

    fix_folders(db['folders'], tags)

    print('Saving zips...')

    for zip_creator in zip_creators:
        zip_creator.save_zip()

    if len(zips) > 0:

        if options['dryrun']:
            zip_sha = 'dry-run'
        else:
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

            run_succesfully('git fetch origin main || true')
            if not run_conditional('git diff --quiet main origin/zip'):
                print('zip branch has changes')
                run_succesfully('git push --force origin zips')
            else:
                print('Using old zip branch from origin')
                zip_sha = run_stdout('git rev-parse --verify origin/zip').strip()


            run_succesfully('git checkout --force ' + current_branch)

        print('zip_sha: ' + zip_sha)

        for zip_id in zips:
            zips[zip_id]['contents_file']['url'] = (options['base_files_url'] % zip_sha) + '%s.zip' % zip_id
            zips[zip_id]['summary_file']['url'] = (options['base_files_url'] % zip_sha) + '%s_summary.json.zip' % zip_id

    db['zips'] = zips
    db['tag_dictionary'] = tags.get_dictionary()

    if options['linux_github_repository'] != '':
        db["linux"] = create_linux_description(options['linux_github_repository'])

    return db

def fix_folders(folders, tags):
    for folder in folders:
        folder_description = folders[folder]
        if 'path' not in folder_description:
            continue
        folder_tags = tags.get_tags_for_folder(folder_description['path'])
        if len(folder_tags) > 0:
            folder_description["tags"] = folder_tags
        folder_description.pop('path')

class ZipCreator:
    def create_zip(self, db_finder: Finder, zips: Dict[str, Any], zip_id: str, zip_description: Dict[str, Any], options: Dict[str, Any], tags: Tags, stored_folders, zip_creators) -> None:
        pass

    def folders(self):
        pass


def make_zip_creator(zip_description: Dict[str, Any]) -> ZipCreator:
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
    def create_zip(self, db_finder: Finder, zips: Dict[str, Any], zip_id: str, zip_description: Dict[str, Any], options: Dict[str, Any], tags: Tags, stored_folders, zip_creators) -> None:
        source_path = Path(zip_description['source'])
        zip_description['sources'] = [source_path.name]
        zip_description['path'] = str(source_path.parent)
        self._multi = MultiSourcesZipCreator()
        self._multi.create_zip(db_finder, zips, zip_id, zip_description, options, tags, stored_folders, zip_creators)
        return

class SubfoldersZipCreator:
    def create_zip(self, db_finder: Finder, zips: Dict[str, Any], zip_id: str, zip_description: Dict[str, Any], options: Dict[str, Any], tags: Tags, stored_folders, zip_creators) -> None:
        simple = SimpleZipCreator()
        self._simples = []
        for folder in [entry.path for entry in os.scandir(zip_description['source']) if entry.is_dir(follow_symlinks=False)]:
            if len(Finder(folder).find_all()) < 60:
                continue
            simple.create_zip(db_finder, zips, zip_id + Path(folder).name.lower(), {"source": folder}, options, tags, stored_folders, zip_creators)
            self._simples.append(simple)

class MultiSourcesZipCreator:
    def create_zip(self, db_finder: Finder, zips: Dict[str, Any], zip_id: str, zip_description: Dict[str, Any], options: Dict[str, Any], tags: Tags, stored_folders, zip_creators) -> None:
        print('Processing zip_id: %s' % zip_id)

        source_parent = zip_description['path']
        summary_name = '%s_summary.json' % zip_id

        multi_summary = create_summary(EmptyFinder(), tags)

        source_name_list = []
        for source in zip_description['sources']:
            db_finder.ignore_folder('./' + source_parent + '/' + source)
            zip_finder = Finder(source_parent + '/' + source)
            zip_summary = create_summary(zip_finder, tags)
            file_parent = Path(source_parent + '/' + source)
            zip_summary['folders'][str(file_parent)] = {"path": file_parent}
            multi_summary['files'].update(zip_summary['files'])
            multi_summary['folders'].update(zip_summary['folders'])
            source_name_list.append(Path(source).name)

        multi_summary['folders'] = multi_summary['folders']

        zip_description['raw_files_size'] = 0
        zip_description['path'] = source_parent + '/'
        zip_description['contents'] = zip_description['sources']
        zip_description['base_files_url'] = options['base_files_url'] % options['sha']
        zip_description.pop('sources')

        for folder in multi_summary['folders']:
            multi_summary['folders'][folder]['zip_id'] = zip_id

        for file in multi_summary['files']:
            multi_summary['files'][file]['zip_id'] = zip_id
            zip_description['raw_files_size'] += multi_summary['files'][file]['size']

        summary_zip = summary_name + '.zip'
        zip_name = zip_id + '.zip'
        zips[zip_id] = zip_description

        self._zip_name = zip_name
        self._zip_description = zip_description

        self._multi_summary = multi_summary
        self._summary_name = summary_name
        self._summary_zip = summary_zip
        self._source_parent = source_parent
        self._source_name_list = source_name_list

        stored_folders.append(multi_summary['folders'])
        zip_creators.append(self)

    def save_zip(self):
        save_data_to_compressed_json(self._multi_summary, self._summary_name, self._summary_zip)
        self._zip_description['summary_file'] = {
            'size': size(self._summary_zip),
            'hash': hash(self._summary_zip)
        }
        Path(self._summary_name).unlink()

        run_succesfully('cur=$(pwd) && cd %s && zip -q -D -X -A -r $cur/%s %s' % (self._source_parent, self._zip_name, " ".join(self._source_name_list)))
        self._zip_description['contents_file'] = {
            'size': size(self._zip_name),
            'hash': hash(self._zip_name)
        }

        print('Created zip: ' + self._zip_name)

def create_summary(finder: Finder, tags: Tags):
    delete_list_regex = re.compile("^(.*_)[0-9]{8}(\.[a-zA-Z0-9]+)*$", )

    summary = {
        'files': dict(),
        'folders': dict()
    }

    for file in finder.find_all():
        strfile = str(file)
        summary['folders'][str(file.parent)] = {"path": file.parent} 

        if file.name in ['.delme'] or strfile in ['README.md', 'LICENSE', 'latest_linux.txt']:
            continue

        summary["files"][strfile] = {
            "size": size(file),
            "hash": hash(file),
            "tags": tags.get_tags_for_file(file)
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
    run_succesfully('git add README.md || true')
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

def lineno():
    return getframeinfo(currentframe().f_back).lineno

def read_mra_fields(mra_path, tags):
    fields = { i : '' for i in tags }

    try:
        context = ET.iterparse(str(mra_path), events=("start",))
        for _, elem in context:
            elem_tag = elem.tag.lower()
            if elem_tag in tags:
                tags.remove(elem_tag)
                elem_value = elem.text
                if isinstance(elem_value, str):
                    fields[elem_tag] = elem_value
                if len(tags) == 0:
                    break
    except Exception as e:
        print("Line %s || %s (%s)" % (lineno(), e, mra_path))

    return fields

if __name__ == '__main__':
    dryrun = len(sys.argv) == 2 and sys.argv[1] == '-d'
    main(dryrun)
