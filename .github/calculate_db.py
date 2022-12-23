#!/usr/bin/env python3
# Copyright (c) 2021-2022 José Manuel Barroso Galindo <theypsilon@gmail.com>

import os
from pathlib import Path
import hashlib
import json
import time
import re
import subprocess
import sys
import io
import tempfile
import xml.etree.ElementTree as ET
import xml.etree.ElementTree
import traceback
from zipfile import ZipFile
from inspect import currentframe, getframeinfo
from typing import Dict, List, Any

_print = print
def print(text=""):
    _print(text, flush=True)
    sys.stdout.flush()

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
    db_file_zip = os.getenv('DB_ZIP_NAME', Path(db_url).name)
    db_file_json = os.getenv('DB_JSON_NAME', Path(db_url).stem)
    db_id = envvar('DB_ID')
    check_changed = os.getenv('CHECK_CHANGED', 'true') != 'false' 
    check_test = os.getenv('CHECK_TEST', 'true') != 'false' 
    download_metadata_json = os.getenv('DOWNLOAD_METADATA_JSON', '/tmp/download_metadata.json')

    tags = Tags(try_read_json(download_metadata_json, None))

    db = create_db('.', {
        'sha': sha,
        'base_files_url': envvar('BASE_FILES_URL'),
        'db_url': db_url,
        'db_files': [db_file_zip],
        'db_id': db_id,
        'dryrun': dryrun,
        'latest_zip_url': envvar('LATEST_ZIP_URL'),
        'linux_github_repository': os.getenv('LINUX_GITHUB_REPOSITORY', '').strip(),
        'zips_config': os.getenv('ZIPS_CONFIG', '').strip()
    }, tags)
    
    db['files'] = to_external_paths(db['files'])
    db['folders'] = to_external_paths(db['folders'])

    for zip_description in db['zips'].values():
        zip_description['path'] = external_path(zip_description['path'])
        if 'target_folder_path' not in zip_description:
            continue
        
        zip_description['target_folder_path'] = external_path(zip_description['target_folder_path'])

    save_data_to_compressed_json(db, db_file_json, db_file_zip)
    
    print('check_changed: ' + str(check_changed))
    if check_changed and db_has_no_changes(db, db_url):
        print('No changes deteted.')
        return

    try:
        tag_list = '`' + '`, `'.join(tags.get_report_terms()) + '`'
        print('TAG_LIST: ' + tag_list)

        with open("README.md", "rt") as fin:
            readme_content = fin.read()

        with open("README.md", "wt") as fout:
            fout.write(readme_content.replace('ALL_TAGS_GO_HERE', tag_list))
    except FileNotFoundError:
        pass

    print('check_test: ' + str(check_test))
    if check_test:
        try:
            test_db_file_zip(db_id, db_file_zip)
        except RunException as e:
            print()
            print('############')
            print('TEST FAILED!')
            print('############')
            print()
            print('Exception:')
            print(str(e))
            exit(1)

    if not dryrun:
        force_push_file(db_file_zip, 'main')

def to_external_paths(input):
    output = {}
    for path, description in input.items():
        output[external_path(path)] = description

    return output        

def external_path(path):
    if path.startswith('games') or path.startswith('docs'):
        path = '|' + path
    return path   

distribution_mister_aliases = [
    # Consoles
    ['nes', 'famicom', 'nintendo'],
    ['snes', 'sufami', 'supernes', 'supernintendo', 'superfamicom'],
    ['pcengine', 'tgfx16', 'turbografx16', 'turbografx'],
    ['pcenginecd', 'tgfx16cd', 'turbografx16cd', 'turbografxcd'],
    ['megadrive', 'genesis'],
    ['megacd', 'segacd'],
    ['sms', 'mastersystem', 'segamark3'],
    ['gb', 'gameboy'],
    ['gbc', 'gameboycolor'],
    ['sgb', 'supergameboy'],
    ['gba', 'gameboyadvance'],

    # General
    ['console-cores', 'console'],
    ['arcade-cores', 'arcade'],
    ['computer-cores', 'computer'],
    ['other-cores', 'other'],
    ['service-cores', 'utility'],
]

filter_part_regex = re.compile("[-_a-z0-9.]$", )

main_binaries = ['MiSTer', 'menu.rbf']

class Metadata:
    @staticmethod
    def new_props():
        return {'home': {}, 'aliases': []}

    def __init__(self, props):
        self._props = props

    def is_mgl_home(self, home):
        return home in self._props['home'] and self._props['home'][home]['mgl_dependency'] != ''

    def mgl_dependency(self, home):
        mgl_dependency = self._props['home'][home]['mgl_dependency']
        if len(mgl_dependency) == 0:
            return Exception('This method should be used after is_mgl_home is true')
        return mgl_dependency

    def category_by_home(self, home):
        return None if home not in self._props['home'] else self._props['home'][home]['category']

    def aliases(self):
        return self._props['aliases']

class Tags:
    def __init__(self, metadata_props) -> None:
        self._metadata = Metadata(metadata_props if metadata_props is not None else Metadata.new_props())
        self._dict = {}
        self._alternatives = {}
        self._index = 0
        self._report_set = set()
        self._used = set()
        self._init = False

    def init_aliases(self, aliases):
        if self._init:
            raise Exception("Can only be initialised once.")
        self._init = True

        for alias_list in [*self._metadata.aliases(), *aliases]:
            clean_terms = [self._clean_term(alias) for alias in alias_list]
            index = self._matching_dict_index(clean_terms)
            for term in clean_terms:
                self._dict[term] = index

    def _matching_dict_index(self, clean_terms):
        result = None
        for term in clean_terms:
            if term not in self._dict:
                continue

            if result is None:
                result = self._dict[term]
            elif result != self._dict[term]:
                raise Exception(f'Aliases with different indexes should not happen. {str(result)} != {str(self._dict[term])}')

        if result is not None:
            return result

        result = self._index
        self._index += 1
        return result
    
    def get_tags_for_file(self, path: Path):
        return sorted(self._get_tags_for_file(path))

    def _get_tags_for_file(self, path: Path):
        parent = path.parts[0].lower()
        if parent[0] == '|':
            parent = parent[1:]
        if parent[0] == '_':
            parent = parent[1:]

        result = []
        if len(path.parts) > 1:
            self._append(result, self._use_term(parent))

        self._add_cores_terms(parent, result)

        suffix = path.suffix.lower()
        stem = path.stem.lower()

        if suffix == '.mra':
            self._append(result, self._use_term('mra'))
            rbf, zips = read_mra_fields(path)

            if rbf is not None:
                self._append(result, self._use_arcade_term(rbf))
            
            if self._contains_hbmame_rom(zips):
                self._append(result, self._use_term('hbmame'))

            if len(path.parts) > 1 and path.parts[1].lower() == '_alternatives':
                self._append(result, self._use_term('alternatives'))

                if rbf is not None and len(path.parts) > 2:
                    alternative_subfolder = path.parts[2].lower()[1:]
                    if alternative_subfolder not in self._alternatives:
                        self._alternatives[alternative_subfolder] = set()
                    self._alternatives[alternative_subfolder].add(rbf)

        elif suffix == '.rbf':
            nodates = stem[0:-9]
            if not nodates:
                nodates = stem

            self._append(result, self._use_term('cores'))
            if parent == 'arcade' or nodates.startswith('arcade-'):
                self._append(result, self._use_arcade_term(nodates))
            else:
                self._append(result, self._use_term(nodates))

            if nodates in ['gba2p', 'gameboy2p']:
                self._append(result, self._use_term('handheld2p'))

        elif suffix == '.mgl':
            self._append(result, self._use_term('mgl'))
            self._append(result, self._use_term('cores'))
            self._append(result, self._use_term(stem))
            rbf, setname = read_mgl_fields(path)
            if rbf is not None:
                self._append(result, self._use_term(Path(rbf).name.lower()))

        if stem in ['menu', 'mister']:
            self._append(result, self._use_term('essential'))

        if parent in ['games', 'docs']:
            first_level = path.parts[1].lower()
            self._append(result, self._use_term(first_level))
            if self._metadata.is_mgl_home(first_level):
                self._append(result, self._use_term('mgl'))
                self._append(result, self._use_term(self._metadata.mgl_dependency(first_level)))

            category = self._metadata.category_by_home(first_level)
            if category is not None:
                self._append(result, self._use_term(category))
    
            if first_level in ['gba2p', 'gameboy2p']:
                self._append(result, self._use_term('handheld2p'))

            second_level = path.parts[2].lower()
            if len(path.parts) > 3:
                self._append(result, self._use_term(second_level))
            
            if parent == 'games':
                if second_level.endswith('.rom'):
                    self._append(result, self._use_term('bios'))
                elif second_level not in ['palettes'] and suffix != '.rbf' and suffix != '.mra':
                    self._append(result, self._use_term('extra-utilities'))
            elif parent == 'docs' and 'readme' in stem:
                self._append(result, self._use_term('readme'))

        elif parent == 'cheats':
            first_level = path.parts[1].lower()
            self._append(result, self._use_term(first_level))
            self._append(result, self._use_term('console'))

        elif parent in ['gamma', 'filters', 'filters_audio', 'shadow_masks']:
            self._append(result, self._use_term('all_filters'))
        
            if parent in ['gamma', 'filters', 'shadow_masks']:
                self._append(result, self._use_term('filters_video'))

        return result

    def _contains_hbmame_rom(self, zips):
        for z in zips:
            if 'hbmame' in z.lower():
                return True

        return False

    def get_tags_for_folder(self, path: Path):
        return sorted(self._get_tags_for_folder(path))

    def _get_tags_for_folder(self, path: Path):
        if len(path.parts) == 0:
            return []

        parent = path.parts[0].lower()
        if parent[0] == '|':
            parent = parent[1:]
        if parent[0] == '_':
            parent = parent[1:]
        result = [self._use_term(parent)]

        if parent in ['console', 'computer', 'other', 'utility']:
            self._append(result, self._use_term('cores'))
        elif parent == 'cheats':
            self._append(result, self._use_term('console'))

        self._add_cores_terms(parent, result)

        if len(path.parts) == 1:
            return result

        first_level = path.parts[1].lower()
        if first_level[0] == '_':
            first_level = first_level[1:]

        if parent in ['games', 'docs']:
            if first_level in ['gba2p', 'gameboy2p']:
                self._append(result, self._use_term('handheld2p'))
            if self._metadata.is_mgl_home(first_level):
                self._append(result, self._use_term('mgl'))
                self._append(result, self._use_term(self._metadata.mgl_dependency(first_level)))
            category = self._metadata.category_by_home(first_level)
            if category is not None:
                self._append(result, self._use_term(category))

        self._append(result, self._use_term(first_level))
            
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
                    self._append(result, self._use_arcade_term(rbf))

        if parent == 'games':
            if second_level in ['palettes']:
                self._append(result, self._use_term(second_level))
            else:
                self._append(result, self._use_term('extra-utilities'))

        return result

    def _use_term(self, term: str):
        return self._use_from_dict(self._clean_term(term))

    def _use_arcade_term(self, term: str):
        return self._use_from_dict(self._clean_term('arcade-' + term))

    def _use_cores_term(self, term: str):
        return self._use_from_dict(self._clean_term(term + '-cores'))

    def _clean_term(self, term: str):
        if not term:
            raise Exception('Term is empty')
        result = ''.join(filter(lambda chr: filter_part_regex.match(chr), term.replace(' ', '')))
        if result not in self._report_set:
            self._report_set.add(result)
        return result.replace('-', '').replace('_', '')

    def _use_from_dict(self, term: str):
        if term == 'menu.rbf':
            raise Exception('should not happen')
        if not term:
            raise Exception('Term is empty')
        if term not in self._dict:
            self._dict[term] = self._index
            self._index += 1

        self._used.add(self._dict[term])

        return self._dict[term]

    def _add_cores_terms(self, parent, result):
        if parent in ['console', 'computer', 'other', 'arcade']:
            self._append(result, self._use_cores_term(parent))
        elif parent == 'utility':
            self._append(result, self._use_cores_term('service'))

    def _append(self, result, term):
        if term in result:
            return
        result.append(term)

    def get_dictionary(self):
        result = {}
        for k, v in self._dict.items():
            if v in self._used:
                result[k] = v
        return result

    def get_report_terms(self):
        result = []
        for entry in self._report_set:
            if self._dict[self._clean_term(entry)] in self._used:
                result.append(entry)
        return sorted(result)

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

    db_summary = create_summary(db_finder, tags, None)
    db['files'] = db_summary['files']
    db['folders'] = db_summary['folders']

    print("Fixing folders...")

    for folders in stored_folders:
        give_folders_tags(folders, tags)

    give_folders_tags(db['folders'], tags)

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

            run_succesfully('git checkout --orphan new_zips')
            run_succesfully('git reset')

            for zip_id in zips:
                run_succesfully('git add %s.zip' % zip_id)
                run_succesfully('git add %s_summary.json.zip' % zip_id)

            run_succesfully('git commit -m "-"')
            zip_sha = run_stdout('git rev-parse --verify HEAD').strip()

            run_succesfully('git fetch origin main || true')
            if not run_conditional('git diff --quiet main origin/zips'):
                print('zip branch has changes')
                run_succesfully('git checkout origin/zips -b zips_backup || true')
                run_succesfully('git push origin zips_backup || true')
                run_succesfully('git push origin --delete zips || true')
                run_succesfully('git push origin new_zips:zips')
                run_succesfully('git push origin --delete zips_backup || true')
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

def give_folders_tags(folders, tags):
    for folder in list(sorted(folders, key=len, reverse=True)):
        folder_description = folders[folder]
        if 'path' not in folder_description:
            continue
        path = folder_description['path']
        folder_tags = tags.get_tags_for_folder(path)
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

        multi_summary = create_summary(EmptyFinder(), tags, source_parent)

        source_name_list = []
        for source in zip_description['sources']:
            db_finder.ignore_folder('./' + source_parent + '/' + source)
            zip_finder = Finder(source_parent + '/' + source)
            zip_summary = create_summary(zip_finder, tags, source)
            file_parent = Path(source_parent + '/' + source)
            zip_summary['folders'][str(file_parent)] = {"path": file_parent}
            add_missing_folders(zip_summary['folders'], source)
            multi_summary['files'].update(zip_summary['files'])
            multi_summary['folders'].update(zip_summary['folders'])
            source_name_list.append(Path(source).name)

        multi_summary['folders'] = multi_summary['folders']

        zip_description['raw_files_size'] = 0
        zip_description['kind'] = 'extract_all_contents'
        zip_description['path'] = source_parent + '/'
        zip_description['target_folder_path'] = source_parent + '/'
        zip_description['contents'] = zip_description['sources']
        zip_description['description'] = self._zip_description_message(zip_description['sources'], zip_description['target_folder_path'])
        zip_description['base_files_url'] = options['base_files_url'] % options['sha']
        zip_description.pop('sources')

        for folder in multi_summary['folders']:
            multi_summary['folders'][folder]['zip_id'] = zip_id

        for file in multi_summary['files']:
            multi_summary['files'][file]['zip_id'] = zip_id
            zip_description['raw_files_size'] += multi_summary['files'][file]['size']

        multi_summary['files'] = to_external_paths(multi_summary['files'])
        multi_summary['folders'] = to_external_paths(multi_summary['folders'])
        
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

    def _zip_description_message(self, contents, zip_path):
        if zip_path == './':
            path_message = 'the root'
        else:
            path_message = zip_path

        return 'Unpacking %s at %s' % (', '.join(contents), path_message)
   
    def save_zip(self):
        save_data_to_compressed_json(self._multi_summary, self._summary_name, self._summary_zip)
        self._zip_description['summary_file'] = {
            'size': size(self._summary_zip),
            'hash': hash(self._summary_zip)
        }
        Path(self._summary_name).unlink()

        run_succesfully('cur=$(pwd) && cd %s && 7z a -r $cur/%s %s' % (self._source_parent, self._zip_name, " ".join(self._source_name_list)))
        self._zip_description['contents_file'] = {
            'size': size(self._zip_name),
            'hash': hash(self._zip_name)
        }

        print('Created zip: ' + self._zip_name)
            
def create_summary(finder: Finder, tags: Tags, source):
    summary = {
        'files': dict(),
        'folders': dict()
    }

    for file in finder.find_all():
        strfile = str(file)
        summary['folders'][str(file.parent)] = {"path": file.parent}

        if file.name in ['.delme'] or strfile in ['README.md', 'LICENSE', 'latest_linux.txt', '.gitattributes']:
            continue

        summary["files"][strfile] = {
            "size": size(file),
            "hash": hash(file),
            "tags": tags.get_tags_for_file(file)
        }
            
        file_name = file.name.lower()

        if (file_name == 'boot.rom' or file_name == 'boot1.rom' or file_name == 'boot0.rom') and not strfile.startswith('games/AO486/'):
            summary["files"][strfile]['overwrite'] = False
            
        if strfile in main_binaries or strfile.startswith('linux/'):
            summary["files"][strfile]['path'] = 'system'
            
        if strfile in main_binaries:
            summary["files"][strfile]['reboot'] = True

    summary['folders'].pop(finder.dir, None)
    add_missing_folders(summary['folders'], source)
    return summary

def add_missing_folders(folders, source):
    source = None if source is None else str(source)

    for folder in list(folders):
        path = Path(folder)

        for parent in path.parents:
            strparent = str(parent)
            if strparent in folders or strparent == '.':
                break
            if source is not None and strparent == source:
                break

            folders[strparent] = {"path": parent}

def create_linux_description(repository):
    token = os.environ.get("GITHUB_TOKEN", None)
    auth = '' if token is None else f'-H "Authorization: Bearer {token}"'
    sd_installer_output = run_stdout(f'curl -H "Accept: application/vnd.github.v3+json" {auth} https://api.github.com/repos/{repository}/git/trees/HEAD')
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

def db_has_no_changes(new_db, db_url):
    old_db = load_db_from_url(db_url)

    new_json = json.dumps(clean_db(new_db), sort_keys=True)
    old_json = json.dumps(clean_db(old_db), sort_keys=True)

    print()
    print('new_json:')
    print(new_json)
    print()
    print('old_json:')
    print(old_json)
    print()

    return new_json == old_json

def load_db_from_url(url_db):
    with tempfile.NamedTemporaryFile() as tmp_file:
        run_succesfully('curl --show-error --fail --location -o "%s" "%s"' % (tmp_file.name, url_db))
        path = Path(url_db)
        json_name = path.stem
        with ZipFile(tmp_file.name, 'r') as zipf:
            with zipf.open(json_name, 'r') as jsonf:
                return json.load(jsonf)

def clean_db(db):
    db['timestamp'] = 0
    db['base_files_url'] = ''
    if 'zips' not in db:
        return db

    for zip in db['zips'].values():
        zip['base_files_url'] = ''
        if 'summary_file' in zip:
            zip['summary_file']['url'] = ''
        if 'contents_file' in zip:
            zip.pop('contents_file')

    return db

def test_db_file_zip(db_id, db_file_zip):
    run_succesfully('mkdir delme_test')
    run_succesfully('echo "[mister]" > delme_test/downloader.ini')
    run_succesfully('echo "base_path = delme_test" >> delme_test/downloader.ini')
    run_succesfully('echo "base_system_path = delme_test" >> delme_test/downloader.ini')
    run_succesfully('echo "update_linux = false" >> delme_test/downloader.ini')
    run_succesfully('echo "allow_reboot  = 0" >> delme_test/downloader.ini')
    run_succesfully('echo "verbose = true" >> delme_test/downloader.ini')
    run_succesfully('echo "downloader_retries = 0" >> delme_test/downloader.ini')
    run_succesfully('echo "[%s]" >> delme_test/downloader.ini' % db_id)
    run_succesfully('echo "db_url = %s" >> delme_test/downloader.ini' % db_file_zip)
    run_succesfully('curl --show-error --fail --location -o "delme_test/downloader.sh" "https://raw.githubusercontent.com/MiSTer-devel/Downloader_MiSTer/main/downloader.sh"')
    run_succesfully('chmod +x delme_test/downloader.sh')
    
    test_env = os.environ.copy()
    test_env['CURL_SSL'] = ''
    test_env['DEBUG'] = 'true'
    run_succesfully('./delme_test/downloader.sh', env=test_env)

def force_push_file(file_name, branch):
    run_succesfully('git add %s' % file_name)
    run_succesfully('git add README.md || true')
    run_succesfully('git commit -m "-"')
    run_succesfully('git push --force origin %s' % branch)
    run_unattended("""
        gh release download all_releases --pattern releases.txt
        DATE=$(date +"%Y-%m-%d %T")
        echo "$DATE: $(git rev-parse --verify HEAD)" >> releases.txt
        gh release create all_releases
        gh release upload all_releases releases.txt --clobber
                   """)
    print()
    print("New %s ready to be used." % file_name)

class RunException(Exception):
    pass


def run_conditional(command):
    print('run_conditional: ' + command)
    result = subprocess.run(command, shell=True, stderr=subprocess.STDOUT)
    return result.returncode == 0

def run_succesfully(command, env=None):
    print('run_succesfully: ' + command)
    result = subprocess.run(command, shell=True, stderr=subprocess.STDOUT, env=env)
    if result.returncode != 0:
        raise RunException("subprocess.run Return Code was '%d'" % result.returncode)


def run_stdout(command):
    print('run_stdout: ' + command)
    result = subprocess.run(command, shell=True, stderr=subprocess.DEVNULL, stdout=subprocess.PIPE)
    if result.returncode != 0:
        raise RunException("subprocess.run Return Code was '%d'" % result.returncode)

    return result.stdout.decode()


def run_unattended(command, env=None):
    print('run_unattended: ' + command)
    return subprocess.run(command, shell=True, stderr=subprocess.STDOUT, env=env)


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

def et_iterparse(mra_file, events):
    try:
        with open(mra_file, 'r') as ftemp:
            f = io.StringIO()
            f.write(ftemp.read().lower())
            f.seek(0)
            return ET.iterparse(f, events=events)
    except Exception as e:
        print('Exception during %s !' % mra_file)
        raise e

def read_mra_fields(mra_path):
    rbf = None
    zips = set()

    try:
        context = et_iterparse(str(mra_path), events=("start",))
        for _, elem in context:
            elem_tag = elem.tag.lower()
            if elem_tag == 'rbf':
                if rbf is not None:
                    print('WARNING! Duplicated rbf tag on file %s, first value %s, later value %s' % (str(mra_path),rbf,elem.text))
                    continue
                if elem.text is None:
                    continue
                rbf = elem.text.strip().lower()
            elif elem_tag == 'rom':
                attributes = {k.strip().lower(): v for k, v in elem.attrib.items()}
                if 'zip' in attributes and attributes['zip'] is not None:
                    zips |= {z.strip().lower() for z in attributes['zip'].strip().lower().split('|')}
    except xml.etree.ElementTree.ParseError as e:
        print('ERROR: Defect XML for mra file: ' + str(mra_path))
        raise e
   
    return rbf, list(zips)

def try_read_json(filename, default):
    try:
        with open(filename) as f:
            return json.load(f)
    except:
        print('WARNING! No JSON! Using default instead.')
        return default

def read_mgl_fields(mgl_path):
    rbf = None
    setname = None

    try:
        context = et_iterparse(str(mgl_path), events=("start",))
        for _, elem in context:
            elem_tag = elem.tag.lower()
            if elem_tag == 'rbf':
                if rbf is not None:
                    print('WARNING! Duplicated rbf tag on file %s, first value %s, later value %s' % (str(mgl_path),rbf,elem.text))
                    continue
                if elem.text is None:
                    continue
                rbf = elem.text.strip().lower()
            elif setname == 'rom':
                if setname is not None:
                    print('WARNING! Duplicated setname tag on file %s, first value %s, later value %s' % (str(mgl_path),setname,elem.text))
                    continue
                if elem.text is None:
                    continue
                setname = elem.text.strip().lower()
    except xml.etree.ElementTree.ParseError as e:
        print('ERROR: Defect XML for mgl file: ' + str(mgl_path))
        raise e

    return rbf, setname

if __name__ == '__main__':
    dryrun = len(sys.argv) == 2 and sys.argv[1] == '-d'
    try:
        main(dryrun)
    except Exception as e:
        print(str(e))
        print(traceback.format_exc())
        exit(1)
