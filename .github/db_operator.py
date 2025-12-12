#!/usr/bin/env python3
# Copyright (c) 2022-2025 José Manuel Barroso Galindo <theypsilon@gmail.com>

from itertools import chain
import subprocess
import sys
import time
from typing import Any, Dict, Generator, Iterator, List, Optional, Set, Tuple, TypedDict
from pathlib import Path
import xml.etree.ElementTree as ET
import io
import re
import os
import json
import hashlib
import shlex
import tempfile
import csv
from urllib.parse import urlparse
from argparse import ArgumentParser
from zipfile import ZipFile, ZIP_DEFLATED
from dataclasses import dataclass


def main() -> None:
    start = time.time()

    parser = ArgumentParser()
    subparsers = parser.add_subparsers(dest='command', required=True)
    subparsers.add_parser('build').add_argument('source_dir', default='delme', help="Folder with the content that will be in the Database")
    compare_parser = subparsers.add_parser('compare')
    compare_parser.add_argument('left_db', help="Address pointing to Database")
    compare_parser.add_argument('right_db', help="Address pointing to another Database")
    args = parser.parse_args()

    if args.command == 'build':
        build_database(args.source_dir)
    elif args.command == 'compare':
        compare_databases(args.left_db, args.right_db)
    else:
        raise ValueError(args.command)

    print()
    print("Time:")
    end = time.time()
    print(end - start)
    print()

# Entrypoints for the different Use Cases:

def build_database(source_dir: str):
    print('Building database...')
    print()
    vars = BuildVars()
    print('BuildVars:', json.dumps(vars.__dict__, indent=True))
    if vars.db_id == '':
        raise ValueError(f'Variable "DB_ID" is missing!')

    set_source_dir(source_dir)

    finder = Finder('.')
    finder.ignore('./.git')
    finder.ignore('./.github')
    for ignore_entry in vars.finder_ignore.split():
        finder.ignore(ignore_entry)
    internal_files = finder.find_all()
    external_files = ExternalFilesReader(vars.external_files).read_external_files()

    if os.environ.get('OMIT_DUAL_SDRAM_CORES', 'true') == 'true' or os.environ.get('GITHUB_REPOSITORY', '').lower() == 'mister-devel/distribution_mister':
        print('Checking on Dual SDRAM cores...')
        dualsdram_cores = {f.name for f in internal_files if f.name.lower().endswith('.rbf') and ('_dualsdram_' in f.name.lower() or '_ds_' in f.name.lower())}
        if len(dualsdram_cores) > 0:
            print(f'Omitting {len(dualsdram_cores)} Dual SDRAM cores:', dualsdram_cores)
            internal_files = [f for f in internal_files if f.name not in dualsdram_cores]

    tags = Tags(try_read_json(vars.download_metadata_json), vars.broken_mras_ignore)
    tags.init_aliases(initial_filter_aliases)

    all_files = [
        (f, new_file_description(str(f)), []) for f in internal_files
    ] + external_files
    # We want to place the .rbf files at the end, so that they can receive
    # the mad terms from the related .mra's
    all_files.sort(key=lambda t: t[0].suffix.lower() == '.rbf')

    builder = DatabaseBuilder(tags)
    for file, description, filter_terms in all_files:
        builder.add_file(file, description, filter_terms)
    for file, _d, _f in all_files:
        builder.add_parent_folders(file)

    db = builder.build(db_id=vars.db_id)

    transformer = DatabaseTransformer(db, vars)
    transformer.apply_urls()
    transformer.apply_linux_update()
    transformer.apply_zips()

    persistence = DatabasePersistence(db, vars)
    if persistence.needs_save():
        print()
        print('Changes detected. Proceeding to save new db...')
        persistence.save()
        save_report_terms_in_readme(tags.get_report_terms())
        print()
        print('Saving complete.')
    else:
        print()
        print('No changes detected.')

def compare_databases(left_path: str, right_path: str) -> None:
    are_same = mut_diff_db(get_url_db(left_path), get_url_db(right_path))
    print()
    if are_same:
        print('No changes.')
    else:
        print('Databases are different.')

# build_database domain:

@dataclass
class BuildVars:
    github_token: str = os.getenv("GITHUB_TOKEN", '').strip()
    db_id: str = os.getenv("DB_ID", '').strip()
    db_url: str = os.getenv('DB_URL', '').strip()
    test_db_url: str = os.getenv('TEST_DB_URL', '').strip()
    db_json_name: str = os.getenv('DB_JSON_NAME', 'dbresult.json').strip()
    base_files_url: str = os.getenv('BASE_FILES_URL', '').strip()
    linux_github_repository: str = os.getenv('LINUX_GITHUB_REPOSITORY', '').strip()
    zips_config: str = os.getenv('ZIPS_CONFIG', '').strip()
    download_metadata_json: str = os.getenv('DOWNLOAD_METADATA_JSON', '/tmp/download_metadata.json').strip()
    finder_ignore: str = os.getenv('FINDER_IGNORE', '').strip()
    broken_mras_ignore: bool = os.getenv('BROKEN_MRAS_IGNORE', 'false').strip().lower() == 'true'
    external_files: str = os.getenv("EXTERNAL_FILES", '').strip()

class Finder:
    def __init__(self, dir: str):
        self._dir = dir
        self._not_in_ignore: List[str] = []

    @property
    def dir(self) -> str:
        return self._dir

    def ignore(self, entry_path: str) -> None:
        ignored_entry = str(Path(entry_path))
        print('Ignored: %s' % ignored_entry)
        self._not_in_ignore.append(ignored_entry)

    def find_all(self) -> List[Path]:
        return sorted(list_files(self._dir, True, self._not_in_ignore), key=lambda file: str(file).lower())

def list_files(directory: str, recursive: bool, not_in_ignore: list[str]) -> Generator[Path, None, None]:
    try:
        for entry in os.scandir(directory):
            if str(Path(entry.path)) in not_in_ignore:
                continue
            if entry.is_dir(follow_symlinks=False) and recursive:
                yield from list_files(entry.path, recursive, not_in_ignore)
            elif entry.is_file():
                yield Path(entry.path)
    except FileNotFoundError: pass

class ExternalFilesReader:
    def __init__(self, strpath: str):
        self._strpath = strpath
        
    def read_external_files(self) -> List[Tuple[Path, Dict[str, Any], List[str]]]:
        if self._strpath == '':
            return []
        
        result = []
        for strpath in self._strpath.split():
            data = self._read_csv_data(strpath)
            if data is None or len(data) == 0:
                continue

            print(f"Parsing CSV '{strpath}' to extract external files.")
            for row in data:
                self._parse_data_row(row, result)

        return result
        
    def _parse_data_row(self, row, result: List[Tuple[Path, Dict[str, Any], List[str]]]) -> None:
        if len(row) < 2:
            print('Not enough columns in this row, skipping it.', row)
            return
        if len(row) == 2:
            print('Hash and size columns are missing.', row)
            path, url, size, md5hash  = row[0].strip(), row[1].strip(), '', ''
        elif len(row) == 3:
            print('Hash column is missing.', row)
            path, url, size, md5hash  = row[0].strip(), row[1].strip(), row[2].strip(), ''
        else:
            path, url, size, md5hash  = row[0].strip(), row[1].strip(), row[2].strip(), row[3].strip().lower()

        if size == '' or md5hash == '':
            size, md5hash = self._read_size_and_md5hash_from_real_file(url, size, md5hash)

        if not is_valid_path(path):
            print(f"Invalid path in this row: {path}, skipping it.", row)
            return
        if not is_valid_url(url):
            print(f"Invalid URL in this row: {url}, skipping it.", row)
            return
        if not is_valid_size(size):
            print(f"Invalid size in this row: {size}, skipping it.", row)
            return
        if not is_valid_md5hash(md5hash):
            print(f"Invalid MD5 hash in this row: {md5hash}, skipping it.", row)
            return

        description = {"url": url, "size": int(size), "hash": md5hash}

        filter_terms = self._extract_filter_terms(row)

        for field_name, field_value in self._extract_extra_fields(row):
            description[field_name] = field_value

        result.append((Path(path), description, filter_terms))

    def _read_size_and_md5hash_from_real_file(self, url: str, size: str, md5hash: str) -> Tuple[str, str]:
        with tempfile.NamedTemporaryFile() as tmp_file:
            download_file(url, tmp_file.name)
            new_size, new_md5hash = str(file_size(tmp_file.name)), file_hash(tmp_file.name)
            if size != '' and size != new_size:
                print(f'Real size {new_size} is different than anotated size {size}')
            if md5hash != '' and md5hash != new_md5hash:
                print(f'Real MD5 Hash {new_md5hash} is different than anotated MD5 Hash {md5hash}')
            return new_size, new_md5hash

    @staticmethod
    def _extract_filter_terms(row: List[str]) -> List[str]:
        filter_terms = []
        if len(row) >= 5:
            filter_terms = row[4].strip().lower().split()

        return filter_terms

    @staticmethod
    def _extract_extra_fields(row: List[str]) -> List[Tuple[str, Any]]:
        if len(row) < 6:
            return []

        result = []
        for extra_field in row[5].strip().split():
            if not is_valid_field_tuple(extra_field):
                print(f"Invalid field tuple: {extra_field}. in row:", row)
                continue
            
            field_parts = extra_field.split(':')
            field_name = field_parts[0].lower()
            field_value = field_parts[1]

            actual_value = None

            if field_name in ['overwrite', 'reboot']:
                actual_value = parse_boolean(field_value)
            else:
                print(f"Invalid field name: {field_name}. in row:", row)
                continue

            if actual_value is None:
                print(f"Invalid field value: {field_value}, for field name: {field_name}, in row:", row)
                continue

            result.append((field_name, actual_value))

        return result

    @staticmethod
    def _read_csv_data(strpath) -> Optional[List[List[str]]]:
        try:
            with open(strpath, newline='') as csvfile:
                csv_reader = csv.reader(csvfile, delimiter=',', quotechar='"')
                return [row for row in csv_reader][1:]
        except Exception as e:
            print('csv file not opened: ' + strpath)
            print(e)
            return None

def is_valid_url(url: str) -> bool:
    try:
        result = urlparse(url)
        return all([result.scheme, result.netloc])
    except ValueError:
        return False

def is_valid_path(path: str) -> bool:
    try:
        p = Path(path)
        if p.is_absolute() or len(path) < 3:
            return False

        for part in p.parts:
            if part in ['..', '.']:
                return False

        return True
    except Exception as e:
        print(e)
        return False

def is_valid_size(size: str) -> bool:
    return size.isdigit() and int(size) > 0

def is_valid_md5hash(md5hash: str) -> bool:
    return bool(re.match(r'^[a-fA-F0-9]{32}$', md5hash))

def is_valid_field_tuple(s):
    pattern = r'^\w+:\w+$'
    return bool(re.match(pattern, s))

def parse_boolean(s):
    s_lower = s.lower()
    if s_lower in ('true', 'yes', 'y', '1'):
        return True
    elif s_lower in ('false', 'no', 'n', '0'):
        return False
    else:
        return None

class MadGameFields(TypedDict):
    alternative: bool
    bootleg: bool
    category: List[str]
    file: str
    flip: bool
    homebrew: bool
    manufacturer: List[str]
    move_inputs: List[str]
    name: str
    num_buttons: int
    platform: List[str]
    players: str
    region: str
    resolution: str
    rotation: int
    series: List[str]
    year: int

def load_mad_db() -> dict[str, MadGameFields]:
    return download_db('https://raw.githubusercontent.com/MiSTer-devel/ArcadeDatabase_MiSTer/refs/heads/db/mad_db.json.zip')

initial_filter_aliases = [
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

    # Arcade Database
    ['screen_rotation_horizontal', 'screen_no_tate'],
    ['screen_rotation_vertical_cw', 'screen_tate_cw'],
    ['screen_rotation_vertical_ccw', 'screen_tate_ccw'],
    ['screen_rotation_vertical_cw_no_flip', 'screen_tate_cw_no_flip'],
    ['screen_rotation_vertical_ccw_no_flip', 'screen_tate_ccw_no_flip'],
    ['screen_rotation_flip', 'screen_tate_flip'],

    # General
    ['console-cores', 'console'],
    ['arcade-cores', 'arcade'],
    ['computer-cores', 'computer'],
    ['other-cores', 'other'],
    ['service-cores', 'utility'],
]

class Tags:
    filter_part_regex = re.compile("[-_a-z0-9.]$", )

    def __init__(self, metadata_props: Optional[Dict[str, Any]], broken_mras_ignore: bool) -> None:
        self._metadata = Metadata(metadata_props if metadata_props is not None else Metadata.new_props())
        self._broken_mras_ignore = broken_mras_ignore
        self._dict: Dict[str, int] = {}
        self._alternatives: Dict[str, Set[str]] = {}
        self._index: int = 0
        self._report_set: Set[str] = set()
        self._used: Set[int] = set()
        self._init: bool = False
        self._mad_db: Optional[dict[str, MadGameFields]] = None

    def init_aliases(self, aliases: List[List[str]]) -> None:
        if self._init:
            raise Exception("Can only be initialised once.")
        self._init = True

        for alias_list in [*self._metadata.aliases(), *aliases]:
            clean_terms = [self._clean_term(alias) for alias in alias_list]
            index = self._matching_dict_index(clean_terms)
            for term in clean_terms:
                self._dict[term] = index

    def _matching_dict_index(self, clean_terms: List[str]) -> int:
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
    
    def get_tags_for_file(self, path: Path) -> List[int]:
        return sorted(self._impl_tags_for_file(path))

    def _impl_tags_for_file(self, path: Path) -> List[int]:
        parent = path.parts[0].lower()
        if parent[0] == '|':
            parent = parent[1:]
        if parent[0] == '_':
            parent = parent[1:]

        result: List[int] = []
        if len(path.parts) > 1:
            self._append(result, self._use_term(parent))

        self._add_cores_terms(parent, result)

        suffix = path.suffix.lower()
        stem = path.stem.lower()

        if suffix == '.mra':
            self._append(result, self._use_term('mra'))
            rbf, setname, zips, broken_error = read_mra_fields(path)

            if broken_error is None:
                if rbf is not None:
                    self._append(result, self._use_arcade_term(rbf))

                if setname is not None:
                    mad_terms = [self._use_term(term) for term in self._mad_terms(setname)]
                    for term in mad_terms:
                        self._append(result, term)
                else:
                    self._append(result, self._use_term('no-setname-mra'))

                if contains_hbmame_rom(zips):
                    self._append(result, self._use_term('alternatives'))

                if len(path.parts) > 1 and path.parts[1].lower() == '_alternatives':
                    self._append(result, self._use_term('alternatives'))

                    if rbf is not None and len(path.parts) > 2:
                        alternative_subfolder = path.parts[2].lower()[1:]
                        if alternative_subfolder not in self._alternatives:
                            self._alternatives[alternative_subfolder] = set()
                        self._alternatives[alternative_subfolder].add(rbf)
            else:
                if not self._broken_mras_ignore:
                    raise broken_error

        elif suffix == '.rbf':
            nodates, datepart = split_on_date(stem)

            if has_dualsdram_variant(path, nodates, datepart):
                self._append(result, self._use_term('single-sdram-variant'))

            self._append(result, self._use_term('cores'))
            if parent == 'arcade' or nodates.startswith('arcade-'):
                self._append(result, self._use_arcade_term(nodates))
            else:
                self._append(result, self._use_term(nodates))

            if nodates in ['gba2p', 'gameboy2p']:
                self._append(result, self._use_term('handheld2p'))

            if nodates == 'genesis':
                self._append(result, self._use_term('genesis-core'))
    
            if nodates == 'megadrive':
                self._append(result, self._use_term('megadrive-core'))
    
            if parent == 'arcade':
                self._append(result, self._use_term('arcade-rbfs-only'))

        elif suffix == '.mgl':
            self._append(result, self._use_term('mgl'))
            self._append(result, self._use_term('cores'))
            self._append(result, self._use_term(stem))
            rbf, _, broken_error = read_mgl_fields(path)
            if broken_error is None and rbf is not None:
                self._append(result, self._use_term(Path(rbf).name.lower()))
            elif broken_error is not None and not self._broken_mras_ignore:
                raise broken_error

        if stem in ['menu', 'mister']:
            self._append(result, self._use_term('essential'))

        if stem == 'mister':
            self._append(result, self._use_term('misterfirmware'))
        
        if stem == 'yc' and suffix == '.txt':
            self._append(result, self._use_term('yctxt'))

        if stem == 'mister_example' and suffix == '.ini':
            self._append(result, self._use_term('mister_example-ini'))

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
                
        elif parent in ['wallpapers']:
            ar = read_image_aspect_ratio(path)
            if ar is None:
                pass
            elif abs(ar - 1.77) < 0.1:
                self._append(result, self._use_term('ar16:9'))
            elif abs(ar - 1.33) < 0.1:
                self._append(result, self._use_term('ar4:3'))

            self._append(result, self._use_term(stem))

        elif parent == 'scripts':
            first_level = Path(path.parts[1]).stem.lower()
            if first_level == 'update':
                self._append(result, self._use_term('downloader'))
            elif 'fast_usb_polling' in first_level:
                self._append(result, self._use_term('fast_usb_polling'))
            elif first_level != '.config':
                self._append(result, self._use_term(first_level))
            if len(path.parts) > 2:
                second_level = path.parts[2].lower()
                self._append(result, self._use_term(second_level))
                self._append(result, self._use_term(stem))

        return result

    def get_tags_for_folder(self, path: Path) -> List[int]:
        return sorted(self._impl_tags_for_folder(path))

    def _impl_tags_for_folder(self, path: Path) -> List[int]:
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

        if first_level != '.config':
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

    def _use_term(self, term: str) -> int:
        return self._use_from_dict(self._clean_term(term))

    def _use_arcade_term(self, term: str) -> int:
        return self._use_from_dict(self._clean_term('arcade-' + term))

    def _use_cores_term(self, term: str) -> int:
        return self._use_from_dict(self._clean_term(term + '-cores'))

    def _clean_term(self, term: str) -> str:
        if not term:
            raise Exception('Term is empty')
        result = ''.join(filter(lambda chr: self.filter_part_regex.match(chr), term.replace(' ', '')))
        if result not in self._report_set:
            self._report_set.add(result)
        result = result.replace('-', '').replace('_', '')
        if not result:
            print('WARNING! Cleaned term is empty.', term, result)
        return result

    def _use_from_dict(self, term: str) -> int:
        if term == 'menu.rbf':
            raise Exception('should not happen')
        if not term:
            raise Exception('Term is empty')
        if term not in self._dict:
            self._dict[term] = self._index
            self._index += 1

        self._used.add(self._dict[term])

        return self._dict[term]

    def _add_cores_terms(self, parent: str, result: List[int]) -> None:
        if parent in ['console', 'computer', 'other', 'arcade']:
            self._append(result, self._use_cores_term(parent))
        elif parent == 'utility':
            self._append(result, self._use_cores_term('service'))

    def _append(self, result: List[int], term: int) -> None:
        if term in result:
            return
        result.append(term)

    def get_dictionary(self) -> Dict[str, int]:
        result: Dict[str, int] = {}
        for k, v in self._dict.items():
            if v in self._used:
                result[k] = v
        return result

    def get_report_terms(self) -> List[str]:
        result: List[str] = []
        for entry in self._report_set:
            if self._dict[self._clean_term(entry)] in self._used:
                result.append(entry)
        return sorted(result)

    def _mad_terms(self, setname: str) -> List[str]:
        if self._mad_db is None:
            self._mad_db = load_mad_db()
        game = self._mad_db.get(setname, None)
        if game is None:
            return ['no-mad-entry-mra']

        terms = []

        if game.get('bootleg', False) or game.get('homebrew', False): terms.append('unlicensed_games')

        rotation = game.get('rotation', 0)
        flip = game.get('flip', False)
        if flip:
            terms.append('screen_rotation_flip')
        if rotation == 90 or rotation == 270:
            if flip:
                terms.append('screen_rotation_vertical_ccw')
                terms.append('screen_rotation_vertical_cw')
            elif rotation == 90:
                terms.append('screen_rotation_vertical_cw')
                terms.append('screen_rotation_vertical_cw_no_flip')
            elif rotation == 270:
                terms.append('screen_rotation_vertical_ccw')
                terms.append('screen_rotation_vertical_ccw_no_flip')
        else:
            terms.append('screen_rotation_horizontal')

        num_buttons = game.get('num_buttons', 0)
        if num_buttons == 1:
            terms.append('controls_1_button')
        elif num_buttons == 2:
            terms.append('controls_2_buttons')
        elif num_buttons == 3:
            terms.append('controls_3_buttons')
        elif num_buttons == 4:
            terms.append('controls_4_buttons')
        elif num_buttons == 5:
            terms.append('controls_5_buttons')
        elif num_buttons == 6:
            terms.append('controls_6_buttons')

        if 'simultaneous' in game.get('players', '').lower():
            if '2' in game['players']:
                terms.append('controls_2_players')
            elif '3' in game['players']:
                terms.append('controls_3_players')
                terms.append('controls_2_players')
            elif '4' in game['players']:
                terms.append('controls_4_players')
                terms.append('controls_3_players')
                terms.append('controls_2_players')

        move_inputs = game.get('move_inputs', [])
        for control in chain(game.get('special_controls', []), move_inputs):
            control = control.lower()
            if 'paddle' in control:
                terms.append('controls_paddle')
            if 'dial' in control:
                terms.append('controls_dial')
            if 'spinner' in control:
                terms.append('controls_spinner')
            if 'trackball' in control:
                terms.append('controls_trackball')

        for mv_input in move_inputs:
            mv_input = mv_input.lower()
            if '2-way' in mv_input:
                terms.append('controls_move_2-way')
            elif '4-way' in mv_input:
                terms.append('controls_move_4-way')
            elif '8-way' in mv_input:
                terms.append('controls_move_8-way')

        resolution = game.get('resolution', '').lower()
        if '15khz' in resolution:
            terms.append('screen_horizontal_scan_rate_15khz')
        elif '31khz' in resolution:
            terms.append('screen_horizontal_scan_rate_31khz')

        return terms


class DatabaseBuilder:
    firmware = 'MiSTer'
    main_binaries = ['MiSTer', 'menu.rbf']

    def __init__(self, tags: Tags):
        self._files: Dict[str, Any] = {}
        self._lowerfiles: Set[str] = set()
        self._folders: Dict[str, Any] = {}
        self._tags = tags

    def add_file(self, file: Path, description: Dict[str, Any], filter_terms: List[str]) -> None:
        strfile = str(file)
        lowerstrfile = strfile.lower()
        
        if file.name in ['.delme', '.DS_Store'] or strfile in ['README.md', 'LICENSE', 'latest_linux.txt', '.gitattributes']:
            return

        if lowerstrfile in self._lowerfiles:
            print(f"ERROR! File {strfile} would clase in a case insensitive system, so it's ignored!")
            return

        self._lowerfiles.add(lowerstrfile)

        if strfile.startswith('games') or strfile.startswith('docs'):
            strfile = f'|{strfile}'

        tags = self._tags.get_tags_for_file(file)
        for term in filter_terms:
            if not term:
                print('WARNING! Empty term found in filter_terms', file, filter_terms)
                continue
            tags.append(self._tags._use_term(term))

        self._files[strfile] = {**description, "tags": tags}

        if file.suffix.lower() == '.rbf':
            core_name, datepart = split_on_date(file.stem.lower())
            if datepart != '':
                self._files[strfile]['tangle'] = [f'{core_name}_core']

        if file.name.lower() in ['boot.rom', 'boot1.rom', 'boot0.rom'] and not strfile.startswith('|games/AO486/'):
            self._files[strfile]['overwrite'] = False

        if strfile in self.main_binaries or strfile.startswith('linux/'):
            self._files[strfile]['path'] = 'system'

        if strfile in self.main_binaries:
            self._files[strfile]['reboot'] = True
        
        if strfile == self.firmware:
            self._files[strfile]['backup'] = '.MiSTer.old'
            self._files[strfile]['tmp'] = 'MiSTer.new'

    def add_parent_folders(self, file: Path) -> None:
        for folder in file.parents:
            strfolder = str(folder)

            if strfolder.startswith('games') or strfolder.startswith('docs'):
                strfolder = f'|{strfolder}'
            if strfolder in self._folders or strfolder in ['.', '']:
                continue
            self._folders[strfolder] = {"tags": self._tags.get_tags_for_folder(folder)}

    def build(self, db_id: str) -> Dict[str, Any]:
        return {
            "db_id": db_id,
            "files": self._files,
            "folders": self._folders,
            "tag_dictionary": self._tags.get_dictionary(),
            "timestamp": int(time.time()),
        }

class DatabaseTransformer:
    def __init__(self, db: Dict[str, Any], vars: BuildVars):
        self._db = db
        self._vars = vars
    
    def apply_urls(self) -> None:
        if self._vars.base_files_url == '':
            raise ValueError('Variable "BASE_FILES_URL" missing!')

        print('BASE_FILES_URL:', self._vars.base_files_url)
        sha = run_stdout('git rev-parse --verify HEAD')
        print('SHA:', sha)
        base_files_url = self._vars.base_files_url % sha
        print('Combined BASE_FILES_URL % SHA:', base_files_url)
        self._db['base_files_url'] = base_files_url

        if self._vars.db_url != '':
            self._db['db_url'] = self._vars.db_url

    def apply_linux_update(self) -> None:
        if self._vars.linux_github_repository == '':
            return
        
        print('LINUX_GITHUB_REPOSITORY:', self._vars.linux_github_repository)
        url_linux = get_linux_latest_release_url(self._vars.linux_github_repository, self._vars.github_token)
        with tempfile.NamedTemporaryFile() as tmp_file:
            download_file(url_linux, tmp_file.name)
            version = Path(url_linux).stem[-6:]
            self._db['linux'] = {**new_file_description(tmp_file.name), "url": url_linux, "version": version}

    def apply_zips(self) -> None:
        if self._vars.zips_config == '':
            return

        config = try_read_json(self._vars.zips_config)
        if config is None:
            raise ValueError(f'Need "{self._vars.zips_config}" to be a valid JSON!')

        builder = ZipsBuilder(self._db)
        for zip_id, zip_description in config.items():
            builder.add_zip(zip_id, zip_description)

        self._db['zips'] = builder.build()

class DatabasePersistence:
    def __init__(self, db: Dict[str, Any], vars: BuildVars):
        self._db = db
        self._vars = vars

    def needs_save(self) -> bool:
        test_db_url = self._vars.test_db_url
        if test_db_url == '':
            test_db_url = self._vars.db_url
        if test_db_url == '':
            print('Missing "DB_URL" and "TEST_DB_URL", can not check previous db!')
            return True

        try:
            previous_db = get_url_db(test_db_url)
        except ReturnCodeException as e:
            print('ReturnCodeException at get_url_db ' + test_db_url)
            print(e)
            return True

        are_same = mut_diff_db(previous_db, json.loads(json.dumps(self._db)))
        return not are_same

    def save(self):
        easy_debug = self._vars.db_json_name == 'dbresult.json'
        if 'zips' in self._db:
            if self._vars.base_files_url == '':
                raise ValueError('Variable "BASE_FILES_URL" missing!')

            save_zips(self._db['zips'], self._vars.base_files_url)

        with open(self._vars.db_json_name, 'w') as f:
            json.dump(self._db, f, indent=4 if easy_debug else None, sort_keys=True)

class ZipsBuilder:
    def __init__(self, db: Dict[str, Any]):
        self._db = db
        self._zips: Dict[str, Any] = {}
        self._intermediate: Dict[str, Any] = {}

    def add_zip(self, zip_id: str, zip_description: Dict[str, Any]) -> None:
        mode = zip_description.get('mode', 'simple')
        if mode == 'simple':
            self._simple_process(zip_id, zip_description['source'], zip_description)
        elif mode == 'multi':
            self._multi_process(zip_id, zip_description)
        elif mode == 'subfolders':
            self._subfolders_process(zip_id, zip_description['source'], zip_description)
        else:
            raise ValueError(f'Unknown mode: {mode}')

    def build(self) -> Dict[str, Any]:
        return self._zips

    def _multi_process(self, zip_id: str, zip_description: Dict[str, Any]) -> None:
        self._intermediate[zip_id] = {'files': {}, 'folders': {}}
        for source in zip_description['sources']:
            if source.startswith('games/') or source.startswith('docs/'):
                source = f'|{source}'

            self._move_elements(zip_id, source, 'files')
            self._move_elements(zip_id, source, 'folders')

        path = zip_description['path']
        if path[0] == '|':
            path = path[1:]

        self._add_zip(zip_id,
            contents=zip_description['sources'],
            description=self._description(", ".join(zip_description["sources"]), path),
            parent=zip_description['path'] + '/',
            mode='multi'
        )
    
    def _simple_process(self, zip_id: str, source: str, zip_description: Dict[str, Any]) -> None:
        self._intermediate[zip_id] = {'files': {}, 'folders': {}}
        if source.startswith('games/') or source.startswith('docs/'):
            source = f'|{source}'
        
        self._move_elements(zip_id, source, 'files')
        self._move_elements(zip_id, source, 'folders')

        source2 = Path(source)
        for outer in source2.parents:
            outer = str(outer)
            if outer == '.' or outer == '':
                continue
            self._intermediate[zip_id]['folders'][outer] = {**self._db['folders'][outer], 'zip_id': zip_id}

        parent = str(source2.parent) + '/'

        path = parent
        if path[0] == '|':
            path = path[1:]

        self._add_zip(zip_id,
            contents=[source2.name],
            description=self._description(source2.name, path),
            parent=parent,
            source=zip_description['source']
        )

    @staticmethod
    def _description(unpacking_str: str, parent: str) -> str:
        return f'Unpacking {unpacking_str} at {parent}' if parent not in ['./', '.'] else f'Unpacking {unpacking_str} at the root'

    def _subfolders_process(self, zip_id: str, source: str, zip_description: Dict[str, Any]) -> None:
        if source.startswith('games/') or source.startswith('docs/'):
            source = f'|{source}'

        subfolder_len = len(Path(source).parts)
        subfolders: Set[str] = set()
        
        self._fill_subfolders(subfolders, subfolder_len, source, 'files')
        self._fill_subfolders(subfolders, subfolder_len, source, 'folders')

        for folder in sorted(subfolders, key=lambda k: len(k), reverse=True):
            composed_source = f'{source}/{folder}'

            if not self._enough_files_for_subfolder(composed_source):
                continue

            composed_zip_id = f'{zip_id}{folder.lower()}'
            self._simple_process(composed_zip_id, composed_source, {**zip_description, 'source': composed_source})

    def _move_elements(self, zip_id: str, source: str, key: str) -> None:
        for element in list(self._db[key]):
            if element.startswith(source):
                self._intermediate[zip_id][key][element] = self._db[key][element]
                self._intermediate[zip_id][key][element]['zip_id'] = zip_id
                del self._db[key][element]

    def _fill_subfolders(self, subfolders: Set[str], subfolder_len: int, source: str, key: str) -> None:
        for element in list(self._db[key]):
            if element.startswith(source):
                parts = Path(element).parts
                if len(parts) == subfolder_len:
                    continue

                subfolder = Path(element).parts[subfolder_len]
                subfolders.add(subfolder)

    def _add_zip(self, zip_id: str, contents: List[str], description: str, parent: str, mode: Optional[str] = None, source: Optional[str] = None) -> None:
        path = parent
        if path.startswith('games') or path.startswith('docs'):
            path = f'|{path}'

        raw_files_size = 0
        for file_desc in self._intermediate[zip_id]['files'].values():
            raw_files_size += file_desc['size']

        result = {
            'base_files_url': self._db['base_files_url'],
            'contents': contents,
            'description': description,
            'kind': 'extract_all_contents',
            'path': path,
            'raw_files_size': raw_files_size,
            'summary_file_content': {
                'folders': self._intermediate[zip_id]['folders'],
                'files': self._intermediate[zip_id]['files'],
            },
            'target_folder_path': path,
        }

        if mode is not None:
            result['mode'] = mode

        if source is not None:
            result['source'] = source

        self._zips[zip_id] = result

    def _enough_files_for_subfolder(self, composed_source: str) -> bool:
        qty = 0
        for f in self._db['files']:
            if not f.startswith(composed_source):
                continue
            qty += 1
            if qty >= 60:
                return True

        return False

class Metadata:
    @staticmethod
    def new_props() -> Dict[str, Any]:
        return {'home': {}, 'aliases': []}

    def __init__(self, props: Dict[str, Any]):
        self._props = props

    def is_mgl_home(self, home: str) -> bool:
        return home in self._props['home'] and self._props['home'][home]['mgl_dependency'] != ''

    def mgl_dependency(self, home: str) -> str:
        mgl_dependency = self._props['home'][home]['mgl_dependency']
        if len(mgl_dependency) == 0:
            raise Exception('This method should be used after is_mgl_home is true')
        return mgl_dependency

    def category_by_home(self, home: str) -> Optional[str]:
        return None if home not in self._props['home'] else self._props['home'][home]['category']

    def aliases(self) -> List[List[str]]:
        return self._props['aliases']

# MiSTer save functions

def save_zips(zips: Dict[str, Any], base_files_url: str) -> None:
    base_zips_url = base_files_url % '<ZIPS_BRANCH_BASE_URL>'
    for zip_id, zip_description in zips.items():
        summary_file_content = zip_description['summary_file_content']
        del zip_description['summary_file_content']

        summary_file_zip = save_summary_file_zip(zip_id, summary_file_content)
        zip_description['summary_file'] = {**new_file_description(summary_file_zip), 'url': f'{base_zips_url}{summary_file_zip}'}
        contents_file_zip = save_contents_file_zip(zip_id, summary_file_content, zip_description['path'])
        zip_description['contents_file'] = {**new_file_description(contents_file_zip), 'url': f'{base_zips_url}{contents_file_zip}'}

def save_summary_file_zip(zip_id: str, summary_file_content: Dict[str, Any]) -> str:
    summary_file_zip = f'{zip_id}_summary.json.zip'
    with ZipFile(summary_file_zip, 'w', compression=ZIP_DEFLATED, compresslevel=1) as zipf:
        zipf.writestr(f'{zip_id}_summary.json', json.dumps(summary_file_content, sort_keys=True))
    return summary_file_zip

def save_contents_file_zip(zip_id: str, summary_file_content: Dict[str, Any], zip_path: str) -> str:
    contents_file_zip = f'{zip_id}.zip'
    with ZipFile(contents_file_zip, 'w', compression=ZIP_DEFLATED, compresslevel=1) as zipf:
        for file in summary_file_content['files']:
            source = file
            if source[0] == '|':
                source = source[1:]
            target = file
            if target.find(zip_path) == 0:
                target = target[len(zip_path):]
            zipf.write(source, target)
    return contents_file_zip

def save_report_terms_in_readme(terms: List[str]) -> None:
    try:
        tag_list = '`' + '`, `'.join(terms) + '`'
        print('TAG_LIST: ' + tag_list)

        with open("README.md", "rt") as fin:
            readme_content = fin.read()

        with open("README.md", "wt") as fout:
            fout.write(readme_content.replace('ALL_TAGS_GO_HERE', tag_list))

        print('README.md updated!')
    except FileNotFoundError as e:
        print('FileNotFoundError: README.md', flush=True)
        print(e, flush=True)

# MiSTer entity descriptions

def new_file_description(name: str) -> Dict[str, Any]:
    return {"size": file_size(name), "hash": file_hash(name)}

# MiSTer XMLs

def read_mra_fields(mra_path: Path) -> Tuple[Optional[str], Optional[str], List[str], Optional[ET.ParseError]]:
    try:
        rbf, setname, zips = _read_mra_fields_impl(mra_path)
        return rbf, setname, zips, None
    except ET.ParseError as e:
        print('ERROR: Defect XML for mra file: ' + str(mra_path))
        return None, None, [], e

def _read_mra_fields_impl(mra_path: Path) -> Tuple[Optional[str], List[str]]:
    rbf = None
    setname = None
    zips: Set[str] = set()

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
        elif elem_tag == 'setname':
            if setname is not None:
                print('WARNING! Duplicated setname tag on file %s, first value %s, later value %s' % (str(mra_path),setname,elem.text))
                continue
            if elem.text is None:
                continue
            setname = elem.text.strip().lower()
        elif elem_tag == 'rom':
            attributes = {k.strip().lower(): v for k, v in elem.attrib.items()}
            if 'zip' in attributes and attributes['zip'] is not None:
                zips |= {z.strip().lower() for z in attributes['zip'].strip().lower().split('|')}

    return rbf, setname,list(zips)

def read_mgl_fields(mgl_path: Path) -> Tuple[Optional[str], Optional[str], Optional[ET.ParseError]]:
    try:
        rbf, setname = _read_mgl_fields_impl(mgl_path)
        return rbf, setname, None
    except ET.ParseError as e:
        print('ERROR: Defect XML for mgl file: ' + str(mgl_path))
        return None, None, e

def _read_mgl_fields_impl(mgl_path: Path) -> Tuple[Optional[str], Optional[str]]:
    rbf = None
    setname = None

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

    return rbf, setname

# Other checks

def split_on_date(stem: str) -> tuple[str, str]:
    datepart = stem[-9:]
    if len(datepart) == 9 and datepart[0] == '_' and datepart[1:].isdigit():
        return stem[0:-9], datepart
    else:
        return stem, ''

def contains_hbmame_rom(zips: List[str]) -> bool:
    for z in zips:
        if 'hbmame' in z.lower():
            return True
    return False

def has_dualsdram_variant(path: Path, nodates: str, datepart: str) -> bool:
    pos = str(path).lower().find(nodates)
    if pos == -1:
        print(f'WARNING! Could not find "{nodates}" in path: ', str(path))
        return False

    fq_folder = str(path)[:pos]
    fq_nodates = str(path)[pos:pos+len(nodates)]

    for same_folder_file in list_files(fq_folder, False, []):
        if same_folder_file == path or not same_folder_file.name.startswith(fq_nodates):
            continue

        sff_nodates, _ = split_on_date(same_folder_file.stem)
        for ds_part in ('_DS', '_DualSDRAM'):
            if sff_nodates == (fq_nodates + ds_part):
                print('Found Dual SDRAM variant: ', same_folder_file)
                return True

    return False

# Read other files

def read_image_aspect_ratio(path: Path) -> Optional[float]:
    try:
        _ensure_image_library()
        from PIL import Image
        img = Image.open(str(path))
        return float(img.width) / float(img.height)
    except Exception as e:
        print('wallpaper image not opened: ' + str(path))
        print(e)
        return None

def _ensure_image_library() -> None:
    try:
        from PIL import Image
    except ImportError as _e:
        subprocess.run([sys.executable, '-m', 'pip', 'install', 'Pillow'], stderr=subprocess.STDOUT, check=True)

# MiSTer network utilities

def download_db(url: str) -> Dict[str, Any]:
    with tempfile.NamedTemporaryFile() as tf:
        download_file(url, tf.name)
        return load_json(tf.name) if is_json(url) else unzip_json(tf.name)

def get_url_db(url: str) -> Dict[str, Any]:
    print("Downloading db from " + url)
    try:
        db = load_json(url) if is_json(url) else unzip_json(url)
    except Exception as _:
        db = download_db(url)

    if 'zips' not in db:
        return db
    
    for zip in db['zips'].values():
        summary_url = zip['summary_file']['url']
        try:
            zip['summary_file_content'] = get_summary_file_content(summary_url)
        except ReturnCodeException as e:
            print('ReturnCodeException at get_summary_file_content ' + summary_url)
            print(e)

    return db

def get_summary_file_content(url: str) -> Dict[str, Any]:
    summary = download_db(url)
    content: Dict[str, Any] = {'files': {}, 'folders': {}}
    for file_name, file_description in summary['files'].items():
        content['files'][file_name] = file_description

    for folder_name, folder_description in summary['folders'].items():
        content['folders'][folder_name] = folder_description
    
    return content

def get_linux_latest_release_url(linux_github_repository: str, github_token: str) -> str:
    auth = '' if github_token == '' else f'-H "Authorization: Bearer {github_token}"'
    sd_installer_output = run_stdout(f'curl --fail --location --silent -H "Accept: application/vnd.github.v3+json" {auth} https://api.github.com/repos/{linux_github_repository}/git/trees/HEAD')
    try:
        sd_installer_json = json.loads(sd_installer_output)
    except Exception as e:
        print('Could not parse output: ' + sd_installer_output)
        raise e

    releases = sorted([x['path'] for x in sd_installer_json['tree'] if x['path'][0:8].lower() == 'release_' and x['path'][-3:].lower() == '.7z'])

    latest_release = releases[-1]
    return 'https://raw.githubusercontent.com/%s/%s/%s' % (linux_github_repository, sd_installer_json['sha'], latest_release)

# db diff tooling

def mut_diff_db(left_db: Dict[str, Any], right_db: Dict[str, Any]) -> bool:
    reformat_db_for_comparison(left_db)
    reformat_db_for_comparison(right_db)

    left_str = json.dumps(left_db, sort_keys=True)
    right_str = json.dumps(right_db, sort_keys=True)

    with tempfile.NamedTemporaryFile() as temp_left, tempfile.NamedTemporaryFile() as temp_right:
        with open(temp_left.name, 'w') as ndf, open(temp_right.name, 'w') as odf:
            print(json.dumps(left_db, sort_keys=True, indent=True), file=ndf)
            print(json.dumps(right_db, sort_keys=True, indent=True), file=odf)
        try:
            run(f'git diff --no-index --exit-code {temp_left.name} {temp_right.name}')
        except ReturnCodeException as _:
            print('RED[-] is left, GREEN[+] is right')
            pass

    return left_str == right_str

def reformat_db_for_comparison(db: Dict[str, Any]) -> None:
    db['base_files_url'] = ''
    db['latest_zip_url'] = ''
    db['timestamp'] = 0
    db['db_files'] = []
    db['db_url'] = db.get('db_url', '')
    db['default_options'] = db.get('default_options', {})

    indexes: Dict[int, str] = {db['tag_dictionary'][word]: word for word in sorted(db.get('tag_dictionary', {}))}

    reformat_elements(indexes, db['files'].values())
    reformat_elements(indexes, db['folders'].values())

    for zip_description in db.get('zips', {}).values():
        zip_description['base_files_url'] = ''
        zip_description['contents_file'] = {}
        zip_description['summary_file'] = {}

        if 'summary_file_content' in zip_description:
            reformat_elements(indexes, zip_description['summary_file_content']['files'].values())
            reformat_elements(indexes, zip_description['summary_file_content']['folders'].values())

    db['tag_dictionary'] = sorted(db.get('tag_dictionary', {}).keys())

def reformat_elements(indexes: Dict[int, str], collection: List[Dict[str, Any]]) -> None:
    for dict in collection:
        if 'tags' in dict:
            dict['tags'] = sorted([indexes[t] for t in dict.get('tags', [])])

# filesystem utilities

def et_iterparse(xml: str, events: Tuple[str]) -> Iterator[Tuple[str, Any]]:
    try:
        with open(xml, 'r') as ftemp:
            f = io.StringIO()
            f.write(ftemp.read().lower())
            f.seek(0)
            return ET.iterparse(f, events=events)
    except Exception as e:
        print('Exception during %s !' % xml)
        raise e

def file_size(file: str) -> int:
    return os.path.getsize(file)

def file_hash(file: str) -> str:
    with open(file, "rb") as f:
        file_hash = hashlib.md5()
        chunk = f.read(8192)
        while chunk:
            file_hash.update(chunk)
            chunk = f.read(8192)
        return file_hash.hexdigest()

def try_read_json(filename: str) -> Optional[Dict[str, Any]]:
    try:
        return load_json(filename)
    except:
        print(f'WARNING! File "{filename}" is not valid JSON.')
        return None

def load_json(filename: str) -> Dict[str, Any]:
    with open(filename) as f:
        return json.load(f)

def unzip_json(path: str) -> Dict[str, Any]:
    return json.loads(run_stdout('unzip -p ' + path))

def set_source_dir(source_dir: str):
    print('Source directory: ' + source_dir)
    os.chdir(source_dir)

def is_json(file: str):
    return Path(file).suffix.lower() == '.json'

# network utilities

def download_file(url: str, target: str) -> None:
    Path(target).parent.mkdir(parents=True, exist_ok=True)
    run(f'curl --show-error --fail --location -o "{target}" "{url}"')

# execution utilities

def run(command: str, cwd: Optional[str] = None) -> None:
    _run(command, cwd, stderr=subprocess.STDOUT, stdout=None)

def run_stdout(command: str, cwd: Optional[str] = None) -> str:
    return _run(command, cwd, stderr=subprocess.DEVNULL, stdout=subprocess.PIPE).stdout.decode().strip()

def _run(command: str, cwd: Optional[str], stderr: Optional[int], stdout: Optional[int]) -> Any:
    result = subprocess.run(shlex.split(command), cwd=cwd, shell=False, stderr=subprocess.STDOUT, stdout=stdout)
    if result.returncode == -2:
        raise KeyboardInterrupt()
    elif result.returncode != 0:
        print(f'returncode {result.returncode} from: {command}')
        raise ReturnCodeException(f'returncode {result.returncode} from: {command}')
    return result

class ReturnCodeException(Exception):
    pass

if __name__ == '__main__':
    main()
