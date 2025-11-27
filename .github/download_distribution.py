#!/usr/bin/env python3
# Copyright (c) 2022-2025 José Manuel Barroso Galindo <theypsilon@gmail.com>

from multiprocessing.pool import ThreadPool
import os
import time
import subprocess
from pathlib import Path
from typing import Any, Dict, Generator, List, Optional, Set, Tuple
from urllib.parse import urlparse, urlsplit
import re
import shutil
import shlex
import json
import zipfile
import xml.etree.ElementTree as ET
import sys
import tempfile
import base64
from datetime import datetime

amount_of_cores_validation_limit = 200
amount_of_extra_content_urls_validation_limit = 20

def main() -> None:

    start = time.time()

    cores = fetch_cores()
    extra_content_urls = fetch_extra_content_urls()
    extra_content_categories = classify_extra_content(extra_content_urls)

    print(f'Cores {len(cores)}:')
    print(cores)
    print()

    validate_cores(cores)

    print(f'Extra Content URLs {len(extra_content_urls)}:')
    print(extra_content_urls)
    print()

    validate_extra_content_urls(extra_content_urls)

    print('Extra Content Categories:')
    print(extra_content_categories)
    print()

    process_all(extra_content_categories, cores, read_target_dir())

    print()
    print("Time:")
    end = time.time()
    print(end - start)
    print()

def read_target_dir():
    target = 'delme'
    if len(sys.argv) > 1:
        target = sys.argv[1].strip()

    if 'delme' in target.lower():
        shutil.rmtree(target, ignore_errors=True)
        Path(target).mkdir(parents=True, exist_ok=True)

    return target

# content validation

CoreProps = Dict[str, str]

def validate_cores(cores: List[CoreProps]) -> None:
    if len(cores) < amount_of_cores_validation_limit:
        raise ValueError(f'Too few cores! {len(cores)} < {amount_of_cores_validation_limit}. Change the value of "amount_of_cores_validation_limit" when necessary.')

    arcade_cores = [c for c in cores if c['category'] == '_Arcade']
    console_cores = [c for c in cores if c['category'] == '_Console']
    computer_cores = [c for c in cores if c['category'] == '_Computer']
    other_cores = [c for c in cores if c['category'] == '_Other']
    service_cores = [c for c in cores if c['category'] == '_Utility']

    sum_len = len(arcade_cores) + len(console_cores) + len(computer_cores) + len(other_cores) + len(service_cores)
    if sum_len != len(cores):
        print(len(arcade_cores), len(console_cores), len(computer_cores), len(other_cores), len(service_cores))
        raise ValueError('sum_len does not match len(coers)!')

    if len(arcade_cores) == 0: raise ValueError('0 Arcade Cores!')
    if len(console_cores) == 0: raise ValueError('0 Console Cores!')
    if len(computer_cores) == 0: raise ValueError('0 Computer Cores!')

    for c in cores:
        url = c.get('url', None)
        if url is None or not is_valid_uri(url):
            print(c)
            raise ValueError(f'Not valid uri "{url}" for core with name "{c.get("name", "")}".')

    for c in [*console_cores, *computer_cores, *other_cores, *service_cores]:
        home = c.get('home', None)
        if home is None or len(home) == 0:
            print(c)
            raise ValueError(f'Not valid "home" field for core with url "{c.get("url", None)}" and name "{c.get("name", None)}".')

def validate_extra_content_urls(urls: List[str]) -> None:
    if len(urls) < amount_of_extra_content_urls_validation_limit:
        raise ValueError(f'Too few urls! {len(urls)} < {amount_of_extra_content_urls_validation_limit}. Change the value of "amount_of_extra_content_urls_validation_limit" when necessary.')

# content description

def fetch_cores() -> List[CoreProps]:
    text = fetch_text('https://raw.githubusercontent.com/wiki/MiSTer-devel/Wiki_MiSTer/Cores.md')
    link_regex = re.compile(r'\[(.*)\]\((.*)\)')

    reading_cores_list = False
    reading_arcade_list = False
    result: List[CoreProps] = []

    category = None

    for line in text.splitlines():
        line = line.strip()
        lower = line.lower()

        if not reading_cores_list and not reading_arcade_list:
            if 'cores_list_start' in lower:
                reading_cores_list = True
            elif 'arcade_list_start' in lower:
                reading_arcade_list = True
        elif reading_cores_list:
            if 'cores_list_end' in lower:
                reading_cores_list = False
                continue

            if lower.startswith('##'):
                header = lower.replace('#', '').strip()

                if 'computer' in header:
                    category = '_Computer'
                elif 'console' in header:
                    category = '_Console'
                elif 'service' in header or 'utility' in header:
                    category = '_Utility'
                elif 'other' in header:
                    category = '_Other'

                continue

            if 'https://github.com/mister-devel/' not in lower:
                continue

            columns = line.split('|')
            matches = link_regex.search(columns[1])
            if not matches:
                continue

            name = matches.group(1).strip()
            url = matches.group(2).strip()
            home = columns[2].strip()
            if 'MiSTer-devel/Menu_MiSTer' in url:
                print('Ignoring menu core on cores list parsing.')
            elif category is None:
                raise ValueError('ERROR! Missing category!')
            else:
                result.append({'name': name, 'url': url, 'home': home, 'category': category})

        elif reading_arcade_list:
            if 'arcade_list_end' in line:
                reading_arcade_list = False
                continue

            if 'https://github.com/mister-devel/' not in lower:
                continue

            columns = line.split('|')
            matches = link_regex.search(columns[1])
            if not matches:
                continue

            name = matches.group(1).strip()
            url = matches.group(2).strip()
            result.append({'name': name, 'url': url, 'category': '_Arcade'})

    return sorted(result, key=lambda element: element['category'].lower() + element['url'].lower())

def fetch_extra_content_urls() -> List[str]:
    result: List[str] = []
    result.extend(['https://github.com/MiSTer-devel/Main_MiSTer', 'https://github.com/MiSTer-devel/Menu_MiSTer'])
    result.extend(['user-content-mra-alternatives', 'https://github.com/MiSTer-devel/MRA-Alternatives_MiSTer'])
    result.extend(["user-content-fonts", "https://github.com/MiSTer-devel/Fonts_MiSTer"])
    result.extend(["user-content-folders"])
    result.extend(["https://github.com/MiSTer-devel/Cheats_MiSTer"])
    result.extend(["https://github.com/MiSTer-devel/Filters_MiSTer"])
    result.extend(["https://github.com/MiSTer-devel/ShadowMasks_MiSTer"])
    result.extend(["https://github.com/MiSTer-devel/Presets_MiSTer"])
    result.extend(["user-content-linux-binary", "https://github.com/MiSTer-devel/PDFViewer_MiSTer"])
    result.extend(["user-content-empty-folder", "games/TGFX16-CD"])
    result.extend(["user-content-empty-folder", "games/NeoGeo-CD"])
    result.extend(["user-content-mister-ini-example", ("MiSTer_example.ini", "https://raw.githubusercontent.com/MiSTer-devel/Distribution_MiSTer/refs/heads/main/MiSTer_example.ini")])
    result.extend(["user-content-file"])
    result.extend([("/", "https://raw.githubusercontent.com/MiSTer-devel/Main_MiSTer/master/yc.txt")])
    result.extend([("/linux/gamecontrollerdb/", "https://raw.githubusercontent.com/MiSTer-devel/Gamecontrollerdb_MiSTer/main/gamecontrollerdb.txt")])
    result.extend([("/games/N64/", "https://raw.githubusercontent.com/MiSTer-devel/N64_ROM_Database/main/N64-database.txt")])
    result.extend([("/Scripts/", "https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/ini_settings.sh")])
    result.extend([("/Scripts/", "https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/samba_on.sh")])
    result.extend([("/Scripts/", "https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/other_authors/fast_USB_polling_on.sh")])
    result.extend([("/Scripts/", "https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/other_authors/fast_USB_polling_off.sh")])
    result.extend([("/Scripts/", "https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/other_authors/wifi.sh")])
    result.extend([("/Scripts/", "https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/rtc.sh")])
    result.extend([("/Scripts/", "https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/timezone.sh")])
    result.extend([("/Scripts/update.sh", "https://raw.githubusercontent.com/MiSTer-devel/Downloader_MiSTer/main/downloader.sh")])
    result.extend([("/Scripts/.config/downloader/downloader_latest.zip", "https://github.com/MiSTer-devel/Downloader_MiSTer/releases/download/latest/dont_download.zip")])
    result.extend([("/Scripts/.config/downloader/downloader_bin", "https://github.com/MiSTer-devel/Downloader_MiSTer/releases/download/latest/downloader_bin")])
    result.extend(['user-content-file-valid-hash'])
    result.extend([("/Scripts/.config/downloader/cacert.pem", "https://curl.se/ca/cacert.pem", "sha256sum", "https://curl.se/ca/cacert.pem.sha256")])
    result.extend(["user-content-unzip"])
    result.extend([("/games/VECTREX/Overlays/", "https://raw.githubusercontent.com/MiSTer-devel/Vectrex_MiSTer/master/overlays/overlays.zip")])

    return result

ContentClassification = Dict[str, str]

def classify_extra_content(extra_content_urls: List[str]) -> ContentClassification:
    current_category = 'main'
    extra_content_categories: ContentClassification = {}
    for url in extra_content_urls:
        if url == "user-content-linux-binary": current_category = url
        elif url == "user-content-zip-release": current_category = url
        elif url == "user-content-empty-folder": current_category = url
        elif url == "user-content-mister-ini-example": current_category = url
        elif url == "user-content-file": current_category = url
        elif url == "user-content-file-valid-hash": current_category = url
        elif url == "user-content-unzip": current_category = url
        elif url == "user-content-folders": current_category = url
        elif url == "user-content-mra-alternatives": current_category = url
        elif url == "user-content-mra-alternatives-under-releases": current_category = url
        elif url == "user-content-fonts": current_category = url
        elif url in ["user-content-fpga-cores", "user-content-development", ""]: print('WARNING! Ignored url: ' + url)
        else:
            if url not in extra_content_categories:
                extra_content_categories[url] = current_category
            elif current_category != extra_content_categories[url]:
                print(f'Already processed {url} as {extra_content_categories[url]}. Tried to be processed again as {current_category}.')

    return extra_content_categories

# metadata class (up here because of function arg types)

MetadataProps = Dict[str, Any]

class Metadata:
    @staticmethod
    def new_props() -> MetadataProps:
        return {'home': {}, 'aliases': []}

    def __init__(self, props: MetadataProps):
        self._props = props
        self._terms: Set[str] = set()
        self._ctx: Any = None
    
    def set_ctx(self, ctx: Any) -> None:
        self._ctx = ctx
    
    def add_mgl_home(self, folder: str, category: str, rbf: str) -> None:
        lower = folder.lower()
        self._props['home'][lower] = self._props['home'].get(lower, {'mgl_dependency': Path(rbf).stem.lower(), 'category': category.lower()[1:]})

    def add_home(self, folder: str, category: str) -> None:
        lower = folder.lower()
        self._props['home'][lower] = self._props['home'].get(lower, {'mgl_dependency': '', 'category': category.lower()[1:]})
        self._props['home'][lower]['mgl_dependency'] = ''

    def add_core_aliases(self, core_aliases: List[str]) -> None:
        terms = {to_filter_term(c) for c in core_aliases}
        for t in terms:
            if t in self._terms:
                raise ValueError(f'{t} from {str(core_aliases)} was already present!', self._ctx)
            self._terms.add(t)
        if len(terms) > 1:
            self._props['aliases'].append(list(terms))

# processors

def process_all(extra_content_categories: ContentClassification, core_descriptions: List[CoreProps], target: str) -> None:
    delme = subprocess.run(['mktemp', '-d'], shell=False, stderr=subprocess.STDOUT, stdout=subprocess.PIPE).stdout.decode().strip()
    metadata_props = Metadata.new_props()

    core_jobs = [(core, delme, target, metadata_props) for core in core_descriptions]
    extra_content_jobs = [(url, category, delme, target) for url, category in extra_content_categories.items()]

    with ThreadPool(processes=30) as pool:
        core_results = pool.starmap_async(process_core, core_jobs)
        extra_content_results = pool.starmap_async(process_extra_content, extra_content_jobs)

        core_results.get()
        extra_content_results.get()

    save_metadata(metadata_props)

def retry(fn: Any) -> Any:
    def callback(*args: List[Any]):
        for i in range(5):
            try:        
                return fn(*args)
            except Exception as e:
                if i == 4:
                    raise e
                print(e, flush=True)
                print('Trying again... ', i, args[0], flush=True)

    return callback

@retry
def process_core(core: CoreProps, delme: str, target: str, metadata_props: MetadataProps):
    category = core['category']
    url = core['url']

    path = download_mister_devel_repository(url, delme, category)

    if not Path(get_releases_dir(path, url)).exists():
        print(f'Warning! Ignored {category}: {url}')
        return

    metadata = Metadata(metadata_props)
    metadata.set_ctx(core)

    if category in core_installers:
        return core_installers[category](path, target, core, metadata)

    raise SystemError(f'Ignored core: {url} {category}')

@retry
def process_extra_content(url: str, category: str, delme: str, target: str):
    if category in extra_content_early_installers:
        return extra_content_early_installers[category](url, target)

    path = download_mister_devel_repository(url, delme, category)

    if category in extra_content_late_installers:
        return extra_content_late_installers[category](path, target, category, url)

    if category in core_installers:
        print(f'WARNING! Ignored core: {url} {category}')
        return

    raise SystemError(f'Ignored extra content: {url} {category}')

def save_metadata(metadata_props: MetadataProps):
    metadata_props['aliases'] = sorted(metadata_props['aliases'], key=lambda arr: sorted(arr)[0])  # This allow us to have a deterministic build, otherwise this array would introduce RNG in the tag indexes calculation

    print()
    print('METADATA:')
    print(json.dumps(metadata_props))
    with open(os.environ.get('DOWNLOAD_METADATA_JSON', '/tmp/download_metadata.json'), 'w', encoding='utf-8') as f:
        json.dump(metadata_props, f, sort_keys=True, indent=4)

# core installers

def install_arcade_core(path: str, target_dir: str, core: CoreProps, metadata: Metadata):
    touch_folder(f'{target_dir}/games/hbmame')
    touch_folder(f'{target_dir}/games/mame')

    url = core["url"]
    releases_dir = get_releases_dir(path, url)
    arcade_installed = False

    for bin in try_filter_list(uniq_files_with_stripped_date(releases_dir), 'Arcade-'):
        latest_release = get_latest_release(releases_dir, bin)
        if not is_rbf(latest_release):
            print(f'{url}: {latest_release} is NOT a RBF file')
            continue

        if is_arcade_core(bin):
            arcade_installed = True
        elif arcade_installed:
            continue

        print('BINARY: ' + bin)
        copy_file(f'{releases_dir}/{latest_release}', f'{target_dir}/_Arcade/cores/{latest_release.replace("Arcade-", "")}')

    for mra_dir in (releases_dir, os.path.join(releases_dir, 'mra')):
        for mra in mra_files(mra_dir):
            copy_file(f'{mra_dir}/{mra}', f'{target_dir}/_Arcade/{mra}')

def install_console_core(path: str, target_dir: str, core: CoreProps, metadata: Metadata): impl_install_generic_core(path, target_dir, core, metadata, touch_games_folder=True)
def install_computer_core(path: str, target_dir: str, core: CoreProps, metadata: Metadata): impl_install_generic_core(path, target_dir, core, metadata, touch_games_folder=True)
def install_other_core(path: str, target_dir: str, core: CoreProps, metadata: Metadata): impl_install_generic_core(path, target_dir, core, metadata, touch_games_folder=False)
def install_utility_core(path: str, target_dir: str, core: CoreProps, metadata: Metadata): impl_install_generic_core(path, target_dir, core, metadata, touch_games_folder=False)

def impl_install_generic_core(path: str, target_dir: str, core: CoreProps, metadata: Metadata, touch_games_folder: bool):
    releases_dir = get_releases_dir(path, core['url'])

    binaries: List[str] = []
    for bin in try_filter_list(uniq_files_with_stripped_date(releases_dir), core["home"]):
        if is_arcade_core(bin):
            continue

        latest_release = get_latest_release(releases_dir, bin)
        if not is_rbf(latest_release):
            print(f'{core["url"]}: {latest_release} is NOT a RBF file')
            continue

        print('BINARY: ' + bin)
        copy_file(f'{releases_dir}/{latest_release}', f'{target_dir}/{core["category"]}/{latest_release}')
        binaries.append(bin)

    metadata.add_home(core['home'], core['category'])
    metadata.add_core_aliases([core['home'], *binaries])
    home_folders = [core['home']]

    for mgl in mgl_files(releases_dir):
        setname, rbf = extract_mgl(f'{releases_dir}/{mgl}')
        if rbf is None or len(rbf) == 0:
            continue

        copy_file(f"{releases_dir}/{mgl}", f'{target_dir}/{core["category"]}/{mgl}')
        if setname is None or len(setname) == 0:
            continue

        home_folders.append(setname)
        metadata.add_mgl_home(setname, core['category'], rbf)
        metadata.add_core_aliases([setname, Path(mgl).stem])

    for folder in home_folders:
        for readme in list_readmes(path):
            copy_file(f"{path}/{readme}", f"{target_dir}/docs/{folder}/{readme}")

        for file in files_with_no_date(releases_dir):
            if is_mra(file) or is_mgl(file):
                continue

            if is_doc(file):
                copy_file(f"{releases_dir}/{file}", f'{target_dir}/docs/{folder}/{file}')
            else:
                copy_file(f"{releases_dir}/{file}", f'{target_dir}/games/{folder}/{file}')

        if touch_games_folder:
            touch_folder(f'{target_dir}/games/{folder}')

        source_palette_folder = find_palette_folder(path)
        if source_palette_folder is None:
            continue

        target_palette_folder = f'{target_dir}/games/{folder}/Palettes/'
        copy_folder(f'{path}/{source_palette_folder}', target_palette_folder)
        clean_palettes(target_palette_folder)

core_installers = {
    "_Arcade": install_arcade_core,
    "_Computer": install_computer_core,
    "_Console": install_console_core,
    "_Utility": install_utility_core,
    "_Other": install_other_core,
}

# extra content installers

def install_main_binary(path: str, target_dir: str, category: str, url: str):
    releases_dir = get_releases_dir(path, url)

    if not Path(releases_dir).exists():
        print(f'Warning! Ignored {category}: {url}')
        return

    for bin in uniq_files_with_stripped_date(releases_dir):
        latest_release = get_latest_release(releases_dir, bin)
        if is_empty_release(latest_release):
            continue

        print('BINARY: ' + bin)
        copy_file(f'{releases_dir}/{latest_release}', f'{target_dir}/{remove_date(latest_release)}')

def install_linux_binary(path: str, target_dir: str, category: str, url: str):
    releases_dir = get_releases_dir(path, url)

    if not Path(releases_dir).exists():
        print(f'Warning! Ignored {category}: {url}')
        return

    for bin in uniq_files_with_stripped_date(releases_dir):
        latest_release = get_latest_release(releases_dir, bin)
        if is_empty_release(latest_release):
            continue

        print('BINARY: ' + bin)
        copy_file(f'{releases_dir}/{latest_release}', f'{target_dir}/linux/{remove_date(latest_release)}')

def install_zip_release(path: str, target_dir: str, category: str, url: str):
    releases_dir = get_releases_dir(path, url)

    if not Path(releases_dir).exists():
        print(f'Warning! Ignored {category}: {url}')
        return
    
    for zip in uniq_files_with_stripped_date(releases_dir):
        latest_release = get_latest_release(releases_dir, zip)
        if is_empty_release(latest_release):
            continue

        unzip(f'{releases_dir}/{latest_release}', target_dir)

def install_mra_alternatives(path: str, target_dir: str, category: str, url: str):
    print(f'Installing MRA Alternatives {url}')
    copy_folder(f'{path}/_alternatives', f'{target_dir}/_Arcade/_alternatives')

def install_mra_alternatives_under_releases(path: str, target_dir: str, category: str, url: str):
    print(f'Installing MRA Alternatives under /releases {url}')
    alternative_folders = [*list_folders(f'{get_releases_dir(path, url)}/_alternatives')]
    if len(alternative_folders) == 0:
        print('WARNING! _alternatives folder is empty.')
        return

    for folder in alternative_folders:
        copy_folder(f'{get_releases_dir(path, url)}/_alternatives/{folder}', f'{target_dir}/_Arcade/_alternatives/{folder}')

def install_fonts(path: str, target_dir: str, category: str, url: str):
    print(f'Installing Fonts {url}')
    for font in list_fonts(path):
        copy_file(f'{path}/{font}', f'{target_dir}/font/{font}')

def install_folders(path: str, target_dir: str, category: str, url: str):
    ignore_folders = ['releases', 'matlab', 'samples']
    for folder in list_folders(path):
        if folder.lower() in ignore_folders or folder[0] == '.':
            continue
        
        print(f"Installing Folder '{folder}' from {url}")
        copy_folder(f'{path}/{folder}', f'{target_dir}/{folder}')

extra_content_late_installers = {
    "main": install_main_binary,
    "user-content-zip-release": install_zip_release,
    "user-content-linux-binary": install_linux_binary,
    "user-content-folders": install_folders,
    "user-content-fonts": install_fonts,
    "user-content-mra-alternatives": install_mra_alternatives,
    "user-content-mra-alternatives-under-releases": install_mra_alternatives_under_releases,
}

def install_empty_folder(folder_path: str, target_dir: str):
    touch_folder(f'{target_dir}/{folder_path}')

def install_mister_ini_example(path_and_url: tuple[str, str], target_dir: str):
    file_path, backup_url = path_and_url
    target_file = f'{target_dir}/{file_path}'
    try:
        fetch_mister_ini_from_main_mister(target_file)
    except Exception as e:
        print(f'ERROR: Could not install {file_path} from Main_MiSTer: {e}. Falling back to {backup_url}.', flush=True)
        try:
            download_file(backup_url, target_file)
        except Exception as e:
            print(f'ERROR: Could not install {file_path} from backup url {backup_url}: {e}.')

def install_file(path_and_url: Tuple[str, str], target_dir: str):
    if len(path_and_url) != 2:
        raise ValueError("Wrong path_and_url value: " + str(path_and_url))
    path, url = path_and_url
    if path[-1] == '/':
        path += Path(url).name
    print(f"File {path}: {url}")
    Path(f'{target_dir}/{path}').parent.mkdir(parents=True, exist_ok=True)
    download_file(url, f'{target_dir}/{path}')

def install_file_valid_hash(path_url_alg_hashurl: Tuple[str, str, str, str], target_dir: str):
    if len(path_url_alg_hashurl) != 4:
        raise ValueError("Wrong path_url_alg_hashurl value: " + str(path_url_alg_hashurl))
    path, url, alg, hashurl = path_url_alg_hashurl
    if path[-1] == '/':
        path += Path(url).name
    print(f"File {path}: {url} | {alg}: {hashurl}")
    Path(f'{target_dir}/{path}').parent.mkdir(parents=True, exist_ok=True)
    download_file(url, f'{target_dir}/{path}')
    download_file(hashurl, '/tmp/temp_hash_file')
    hashsum = subprocess.run([alg, f'{target_dir}/{path}'], check=True, capture_output=True, text=True).stdout.strip().split()[0]
    with open('/tmp/temp_hash_file', 'r') as f:
        expected_hashsum = f.read().strip().split()[0]

    if hashsum != expected_hashsum:
        print(f'hash missmatch: {hashsum} != {expected_hashsum}')
        exit(1)

def install_unzip(path_and_url: Tuple[str, str], target_dir: str):
    if len(path_and_url) != 2:
        raise ValueError("Wrong path_and_url value: " + str(path_and_url))
    path, url = path_and_url
    print(f"Unzip {path}: {url}")
    Path(f'{target_dir}/{path}').parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(delete=True) as temp_file:
        download_file(url, temp_file.name)
        unzip(temp_file.name, f'{target_dir}/{path}')

extra_content_early_installers = {
    'user-content-empty-folder': install_empty_folder,
    'user-content-mister-ini-example': install_mister_ini_example,
    'user-content-file': install_file,
    'user-content-file-valid-hash': install_file_valid_hash,
    'user-content-unzip': install_unzip 
}

# mister domain helpers

def get_releases_dir(path: str, url: str) -> str:
    relative_path = get_repository_relative_path(url)
    if relative_path == '':
        return f'{path}/releases'
    else:
        return f'{path}/{relative_path}/releases'

def mra_files(folder: str) -> List[str]:
    return [without_folder(folder, f) for f in list_files(folder, recursive=False) if Path(f).suffix.lower() == '.mra']

def is_arcade_core(path: str) -> bool:
    return Path(path).name.lower().startswith('arcade-')

def is_rbf(path: str) -> bool:
    return Path(path).suffix.lower() == '.rbf'

def get_latest_release(folder: str, bin: str) -> str:
    files = [without_folder(folder, f) for f in list_files(folder, recursive=False)]
    releases = sorted([f for f in files if bin.lower() in f.lower() and remove_date(f).lower() != f.lower()])
    return releases[-1]

def uniq_files_with_stripped_date(folder: str) -> List[str]:
    result: List[str] = []
    seen: Set[str] = set()
    for f in list_files(folder, recursive=False):
        f = without_folder(folder, str(Path(f).with_suffix('')))

        no_date = remove_date(f)
        lower_no_date = no_date.lower()
        if lower_no_date == f.lower() or lower_no_date in seen:
            continue

        seen.add(lower_no_date)
        result.append(no_date)
    return result

def try_filter_list(col: List[str], filter: str) -> List[str]:
    filtered = [el for el in col if filter.lower() in el.lower()]
    if len(filtered) > 0:
        return filtered
    
    return col

def clean_palettes(palette_folder: str) -> None:
    for file in list_files(palette_folder, recursive=True):
        path = Path(file)
        if path.suffix.lower() in ['.pal', '.gbp']:
            continue

        path.unlink()

def find_palette_folder(path: str) -> Optional[str]:
    for folder in list_folders(path):
        if folder.lower() in ['palette', 'palettes']:
            return folder
        
    return None

def is_standard_core_category(category: str) -> bool:
    return category.strip() in ["_Computer", "_Arcade", "_Console", "_Other", "_Utility"]

def is_mgl(file: str) -> bool:
    return Path(file).suffix.lower() == '.mgl'

def is_doc(file: str) -> bool:
    return Path(file).suffix.lower() in ['.md', '.pdf', '.txt', '.rtf']

def is_mra(file: str) -> bool:
    return Path(file).suffix.lower() == '.mra'

def files_with_no_date(folder: str) -> List[str]:
    return [without_folder(folder, f) for f in list_files(folder, recursive=True) if f == remove_date(f)]

def list_readmes(folder: str) -> List[str]:
    files = [without_folder(folder, f) for f in list_files(folder, recursive=False)]
    return [f for f in files if 'readme.' in f.lower()]

def mgl_files(folder: str) -> List[str]:
    return [without_folder(folder, f) for f in list_files(folder, recursive=False) if Path(f).suffix.lower() == '.mgl']

def extract_mgl(mgl: str) -> Tuple[Optional[str], Optional[str]]:
    setname = None
    rbf = None
    try:
        for _, elem in ET.iterparse(mgl, events=('start',)):
            if elem.tag.lower() == 'setname' and elem.text is not None:
                setname = elem.text.strip()
            elif elem.tag.lower() == 'rbf' and elem.text is not None:
                rbf = elem.text.strip()
    except ET.ParseError as e:
        print('Warning! extract_mgl error: ' + str(e), flush=True)
    return setname, rbf

def remove_date(path: str) -> str:
    if len(path) < 10:
        return path

    last_part = Path(path).stem[-9:]
    if last_part[0] == '_' and last_part[1:].isnumeric():
        return path.replace(last_part, '')

    return path

def without_folder(folder: str, f: str) -> str:
    return f.replace(f'{folder}/', '').replace(folder, '').strip()

def is_empty_release(bin: str) -> bool:
    return bin == '' or bin is None or len(bin) == 0

def list_fonts(path: str) -> List[str]:
    return [Path(f).name for f in list_files(path, recursive=True) if Path(f).suffix.lower() == '.pf']

def download_mister_devel_repository(input_url: str, delme: str, category: str) -> str:
    name = get_repository_name(input_url)
    branch = get_branch(input_url)
    relative_path = get_repository_relative_path(input_url)

    path = f'{delme}/{name}'

    if category[0] == '_':
        path = path + category

    if len(branch) > 0:
        path = path + branch

    cleanup = "/tree/" + branch
    if len(relative_path) > 0:
        path = path + repository_relative_path_to_fs_path(relative_path)
        cleanup = cleanup + '/' + relative_path

    git_url = f'{input_url.replace(cleanup, "")}.git'
    download_repository(path, git_url, branch)
    return path

def get_repository_name(url: str) -> str:
    return str(Path(urlparse(url).path.split('/')[2]).with_suffix(''))

def get_branch(url: str) -> str:
    pos = url.find('/tree/')
    if pos == -1:
        return ""
    later_part = url[pos + len('/tree/'):]
    pos = later_part.find('/')
    if pos == -1:
        return later_part
    return later_part[:pos]

def get_repository_relative_path(url: str) -> str:
    parts = urlsplit(url)
    segments = parts.path.strip('/').split('/')
    if len(segments) > 4 and segments[2] == "tree":
        return '/'.join(segments[4:])
    return ""

def repository_relative_path_to_fs_path(path: str) -> str:
    return '_' + path.replace('/', '_')

filter_term_char_regex = re.compile("[-_a-z0-9.]$", )
def to_filter_term(name: str):
    result = ''.join(filter(lambda chr: filter_term_char_regex.match(chr), name.lower().replace(' ', '')))
    return result.replace('-', '').replace('_', '')

def parse_release_date(binary_name, name_root) -> Optional[datetime]:
    try:
        date_str = binary_name.replace(name_root, '')
        if len(date_str) == 8 and date_str.isdigit():
            return datetime(int(date_str[0:4]), int(date_str[4:6]), int(date_str[6:8]))
    except (ValueError, IndexError):
        pass
    return None

# file system utilities

def list_files(directory: str, recursive: bool) -> Generator[str, None, None]:
    try:
        for f in os.scandir(directory):
            if f.is_dir() and recursive:
                yield from list_files(f.path, recursive)
            elif f.is_file():
                yield f.path
    except FileNotFoundError: pass

def list_folders(directory: str) -> Generator[str, None, None]:
    try:
        for f in os.scandir(directory):
            if f.is_dir():
                yield (f.path.replace(directory + '/', '').replace(directory, ''))
    except FileNotFoundError: pass

def copy_file(source: str, target: str) -> None:
    Path(target).parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)

def copy_folder(source: str, target: str) -> None:
    shutil.copytree(source, target)

def touch_folder(folder: str) -> None:
    path = Path(folder)
    if path.exists():
        return

    path.mkdir(parents=True, exist_ok=True)
    Path(f'{folder}/.delme').touch()

def unzip(zip_file: str, target_dir: str) -> None:
    Path(target_dir).mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(zip_file, 'r') as zip_ref:
        zip_ref.extractall(target_dir)

def is_valid_uri(x: str) -> bool:
    try:
        result = urlparse(x)
        return all([result.scheme, result.netloc])
    except:
        return False

# network utilities

def fetch_text(url: str) -> str:
    cache_bust = int(time.time_ns() / 1000)
    return run_stdout(f'curl -H "Cache-Control: no-cache, no-store" -H "Pragma: no-cache" --fail --location --silent {url}?_={cache_bust}')

def download_repository(path: str, url: str, branch: str) -> None:
    if Path(path).exists():
        shutil.rmtree(path, ignore_errors=True)
    os.makedirs(path)

    minus_b = '' if len(branch) == 0 else f'-b {branch}'
    run(f'git -c protocol.version=2 clone -q --no-tags --no-recurse-submodules --depth=1 {minus_b} {url} {path}')

def download_file(url: str, target: str) -> None:
    cache_bust = int(time.time_ns() / 1000)
    Path(target).parent.mkdir(parents=True, exist_ok=True)
    run(f'curl -H "Cache-Control: no-cache, no-store" -H "Pragma: no-cache" --show-error --fail --location -o "{target}" "{url}?_={cache_bust}"')

# fetch mister ini from main mister

def main_mister_releases() -> list[str]: return json.loads(gh('api repos/MiSTer-devel/Main_MiSTer/contents/releases --jq .'))
def main_mister_latest_commit(file_path) -> dict[str, str]: return json.loads(gh(f'api repos/MiSTer-devel/Main_MiSTer/commits?path={file_path}&per_page=1'
                                                   f' --jq ".[0] | {{sha: .sha, date: .commit.committer.date}}"'))

def fetch_main_mister_file_from_commit(commit_sha, file_path) -> str:
    output = gh(f'api repos/MiSTer-devel/Main_MiSTer/contents/{file_path}?ref={commit_sha} --jq .content')

    try:
        clean_b64 = output.replace('\n', '').replace('\r', '').replace(' ', '').strip()
        return base64.b64decode(clean_b64).decode('utf-8')
    except Exception as e:
        raise Exception(f"Error decoding {file_path}: {e}")

def validate_mister_ini(content):
    if '[mister]' not in content.lower():
        raise Exception("Fetched file does not contain [MiSTer] section")
    if len(content) < 100:
        raise Exception(f"File too small ({len(content)} bytes) - likely corrupted")

def fetch_mister_ini_from_main_mister(file_path: str):
    print("Fetching files from Main_MiSTer/releases/")
    files = main_mister_releases()

    mister_binaries = [f for f in files if f['name'].startswith('MiSTer_') and f['type'] == 'file']
    if not mister_binaries:
        raise Exception("No MiSTer_* binaries found")

    print(f"Found {len(mister_binaries)} MiSTer_* binaries")

    binaries_with_dates = [(b, d) for b in mister_binaries if (d := parse_release_date(b['name'], 'MiSTer_'))]
    if not binaries_with_dates:
        raise Exception("Could not parse dates from any binaries")

    binaries_with_dates.sort(key=lambda x: x[1], reverse=True)
    latest_binary_info, latest_date = binaries_with_dates[0]
    latest_binary = latest_binary_info['name']

    print(f"Latest binary by filename date: {latest_binary} ({latest_date.strftime('%Y-%m-%d')})")
    print(f"\nFetching commit info for {latest_binary}...")

    commit_info = main_mister_latest_commit(latest_binary_info['path'])
    commit_sha = commit_info['sha']
    commit_date = datetime.fromisoformat(commit_info['date'].replace('Z', '+00:00'))

    print(f"\n{'='*60}")
    print(f"Latest Binary: {latest_binary}")
    print(f"Commit Hash:   {commit_sha}")
    print(f"Commit Date:   {commit_date.strftime('%Y-%m-%d %H:%M:%S UTC')}")
    print(f"{'='*60}\n")

    print(f"Fetching MiSTer.ini from commit {commit_sha[:7]}...")
    ini_content = fetch_main_mister_file_from_commit(commit_sha, 'MiSTer.ini')
    validate_mister_ini(ini_content)

    output_path = Path(file_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(ini_content)

    print(f"✓ MiSTer.ini saved to {output_path}")
    print(f"  File size: {len(ini_content)} bytes")
    print(f"  Lines: {len(ini_content.splitlines())}")

# execution utilities

def gh(args: str) -> str:
    try:
        output = subprocess.run(['gh'] + shlex.split(args), capture_output=True, text=True, check=True).stdout.strip()
        if not output: raise Exception(f"Empty output from gh {args}")
        return output
    except subprocess.CalledProcessError as e:
        raise Exception(f"GitHub CLI command failed: {e.stderr if e.stderr else str(e)}")

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
