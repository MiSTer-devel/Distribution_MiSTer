#!/usr/bin/env python3
# Copyright (c) 2022 José Manuel Barroso Galindo <theypsilon@gmail.com>

from multiprocessing.pool import ThreadPool
import os
import time
import subprocess
from pathlib import Path
from urllib.parse import urlparse
import requests
import re
import shutil
import shlex
import json
import zipfile
import xml.etree.ElementTree as ET
import sys

amount_of_cores_validation_limit = 200
amount_of_extra_content_urls_validation_limit = 25

def main():

    start = time.time()

    cores = fetch_cores()
    extra_content_urls = fetch_extra_content_urls()
    extra_content_categories = classify_extra_content(extra_content_urls)

    print(f'Cores {len(cores)}:')
    print(json.dumps(cores))
    print()

    validate_cores(cores)

    print(f'Extra Content URLs {len(extra_content_urls)}:')
    print(json.dumps(extra_content_urls))
    print()

    validate_extra_content_urls(extra_content_urls)

    print('Extra Content Categories:')
    print(json.dumps(extra_content_categories))
    print()

    target = 'delme'
    if len(sys.argv) > 1:
        target = sys.argv[1].strip()

    if 'delme' in target.lower():
        shutil.rmtree(target, ignore_errors=True)
        Path(target).mkdir(parents=True, exist_ok=True)

    process_all(extra_content_categories, cores, target)

    print()
    print("Time:")
    end = time.time()
    print(end - start)
    print()


# content validation

def validate_cores(cores):
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
        if not is_valid_uri(url):
            print(c)
            raise ValueError(f'Not valid uri "{url}" for core with name "{c.get("name", None)}".')

    for c in [*console_cores, *computer_cores]:
        home = c.get('home', None)
        if home is None or len(home) == 0:
            print(c)
            raise ValueError(f'Not valid "home" field for core with url "{c.get("url", None)}" and name "{c.get("name", None)}".')

def validate_extra_content_urls(urls):
    if len(urls) < amount_of_extra_content_urls_validation_limit:
        raise ValueError(f'Too few urls! {len(urls)} < {amount_of_extra_content_urls_validation_limit}. Change the value of "amount_of_extra_content_urls_validation_limit" when necessary.')

# content description

def fetch_cores():
    text = fetch_text('https://raw.githubusercontent.com/wiki/MiSTer-devel/Wiki_MiSTer/Cores.md')
    link_regex = re.compile(r'\[(.*)\]\((.*)\)')

    reading_cores_list = False
    reading_arcade_list = False
    result = []

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

def fetch_extra_content_urls():
    result = []
    result.extend(['https://github.com/MiSTer-devel/Main_MiSTer', 'https://github.com/MiSTer-devel/Menu_MiSTer'])
    result.extend(['user-content-mra-alternatives', 'https://github.com/MiSTer-devel/MRA-Alternatives_MiSTer'])
    result.extend(["user-cheats"])  # @TODO Modify this mapping whenever there is a new system with cheats
    result.extend(["fds|NES"])
    result.extend(["gb|GameBoy"])
    result.extend(["gba|GBA"])
    result.extend(["gbc|GameBoy"])
    result.extend(["gen|Genesis"])
    result.extend(["gg|SMS"])
    result.extend(["lnx|AtariLynx"])
    result.extend(["nes|NES"])
    result.extend(["pce|TGFX16"])
    result.extend(["pcd|TGFX16-CD"])
    result.extend(["psx|PSX"])
    result.extend(["scd|MegaCD"])
    result.extend(["sms|SMS"])
    result.extend(["snes|SNES"])
    #result.extend(["user-backup-cheats", "https://github.com/MiSTer-devel/Distribution_MiSTer/archive/refs/heads/main.zip"])  # Uncomment if user-cheats breaks (and comment user-cheats instead)
    result.extend(["user-content-fonts", "https://github.com/MiSTer-devel/Fonts_MiSTer"])
    result.extend(["user-content-folders"])
    result.extend(["https://github.com/MiSTer-devel/Filters_MiSTer"])
    result.extend(["https://github.com/MiSTer-devel/ShadowMasks_MiSTer"])
    result.extend(["https://github.com/MiSTer-devel/Presets_MiSTer"])
    result.extend(["user-content-scripts"])
    result.extend(["https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/ini_settings.sh"])
    result.extend(["https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/samba_on.sh"])
    result.extend(["https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/other_authors/fast_USB_polling_on.sh"])
    result.extend(["https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/other_authors/fast_USB_polling_off.sh"])
    result.extend(["https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/other_authors/wifi.sh"])
    result.extend(["https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/rtc.sh"])
    result.extend(["https://raw.githubusercontent.com/MiSTer-devel/Scripts_MiSTer/master/timezone.sh"])
    result.extend(["user-content-linux-binary", "https://github.com/MiSTer-devel/PDFViewer_MiSTer"])
    result.extend(["user-content-empty-folder", "games/TGFX16-CD"])
    result.extend(["user-content-gamecontrollerdb", "https://raw.githubusercontent.com/MiSTer-devel/Gamecontrollerdb_MiSTer/main/gamecontrollerdb.txt"])
    return result

def classify_extra_content(extra_content_urls):
    current_category = 'main'
    extra_content_categories = {}
    for url in extra_content_urls:
        if url == "user-content-linux-binary": current_category = url
        elif url == "user-content-zip-release": current_category = url
        elif url == "user-content-scripts": current_category = url
        elif url == "user-cheats": current_category = url
        elif url == "user-backup-cheats": current_category = url
        elif url == "user-content-empty-folder": current_category = url
        elif url == "user-content-gamecontrollerdb": current_category = url
        elif url == "user-content-folders": current_category = url
        elif url == "user-content-mra-alternatives": current_category = url
        elif url == "user-content-fonts": current_category = url
        elif url in ["user-content-fpga-cores", "user-content-development", ""]: print('WARNING! Ignored url: ' + url)
        else:
            if url not in extra_content_categories:
                extra_content_categories[url] = current_category
            elif current_category != extra_content_categories[url]:
                print(f'Already processed {url} as {extra_content_categories[url]}. Tried to be processed again as {current_category}.')

    return extra_content_categories

# processors

def process_all(extra_content_categories, core_descriptions, target):
    delme = subprocess.run(['mktemp', '-d'], shell=False, stderr=subprocess.STDOUT, stdout=subprocess.PIPE).stdout.decode().strip()
    metadata_props = Metadata.new_props()

    core_jobs = [(core, delme, target, metadata_props) for core in core_descriptions if 'MiSTer-devel/Menu_MiSTer' not in core['url']]
    extra_content_jobs = [(url, category, delme, target) for url, category in extra_content_categories.items()]

    with ThreadPool(processes=30) as pool:
        core_results = pool.starmap_async(process_core, core_jobs)
        extra_content_results = pool.starmap_async(process_extra_content, extra_content_jobs)

        core_results.get()
        extra_content_results.get()

    print()
    print('METADATA:')
    print(json.dumps(metadata_props))
    with open(os.environ.get('DOWNLOAD_METADATA_JSON', '/tmp/download_metadata.json'), 'w', encoding='utf-8') as f:
        json.dump(metadata_props, f, sort_keys=True, indent=4)

def process_core(core, delme, target, metadata_props):
    category = core['category']
    url = core['url']

    path = download_mister_devel_repository(url, delme, category)

    if not Path(f'{path}/releases').exists():
        print(f'Warning! Ignored {category}: {url}')
        return

    if category in core_installers:
        return core_installers[category](path, target, core, Metadata(metadata_props))

    raise SystemError(f'Ignored core: {url} {category}')

def process_extra_content(url, category, delme, target):
    if category in extra_content_early_installers:
        return extra_content_early_installers[category](url, target)

    path = download_mister_devel_repository(url, delme, category)

    if category in extra_content_late_installers:
        return extra_content_late_installers[category](path, target, category, url)

    if category in core_installers:
        print(f'WARNING! Ignored core: {url} {category}')
        return

    raise SystemError(f'Ignored extra content: {url} {category}')

# core installers

def install_arcade_core(path, target_dir, core, metadata):
    touch_folder(f'{target_dir}/games/hbmame')
    touch_folder(f'{target_dir}/games/mame')

    releases_dir = f'{path}/releases'
    arcade_installed = False

    for bin in uniq_files_with_stripped_date(releases_dir, 'Arcade-'):
        latest_release = get_latest_release(releases_dir, bin)
        if not is_rbf(latest_release):
            print(f'{core["url"]}: {latest_release} is NOT a RBF file')
            continue

        if is_arcade_core(bin):
            arcade_installed = True
        elif arcade_installed:
            continue

        print('BINARY: ' + bin)
        copy_file(f'{releases_dir}/{latest_release}', f'{target_dir}/_Arcade/cores/{latest_release.replace("Arcade-", "")}')

    for mra in mra_files(releases_dir):
        copy_file(f'{releases_dir}/{mra}', f'{target_dir}/_Arcade/{mra}')

def install_console_core(path, target_dir, core, metadata): impl_install_generic_core(path, target_dir, core, metadata, touch_games_folder=True)
def install_computer_core(path, target_dir, core, metadata): impl_install_generic_core(path, target_dir, core, metadata, touch_games_folder=True)
def install_other_core(path, target_dir, core, metadata): impl_install_generic_core(path, target_dir, core, metadata, touch_games_folder=False)
def install_utility_core(path, target_dir, core, metadata): impl_install_generic_core(path, target_dir, core, metadata, touch_games_folder=False)

def impl_install_generic_core(path, target_dir, core, metadata, touch_games_folder):
    releases_dir = f'{path}/releases'

    binaries = []
    for bin in uniq_files_with_stripped_date(releases_dir, core["home"]):
        if is_arcade_core(bin):
            continue

        latest_release = get_latest_release(releases_dir, bin)
        if not is_rbf(latest_release):
            print(f'{core["url"]}: {latest_release} is NOT a RBF file')
            continue

        print('BINARY: ' + bin)
        copy_file(f'{releases_dir}/{latest_release}', f'{target_dir}/{core["category"]}/{latest_release}')
        binaries.append(bin)

    home_folders = [core['home']]

    for mgl in mgl_files(releases_dir):
        setname, rbf = extract_mgl(f'{releases_dir}/{mgl}')
        if rbf is None or len(rbf) == 0:
            continue

        copy_file(f"{releases_dir}/{mgl}", f'{target_dir}/{core["category"]}/{mgl}')
        if setname is None or len(setname) == 0:
            continue

        home_folders.append(setname)

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

def install_main_binary(path, target_dir, category, url):
    releases_dir = f'{path}/releases'

    if not Path(releases_dir).exists():
        print(f'Warning! Ignored {category}: {url}')
        return

    for bin in uniq_files_with_stripped_date(releases_dir, None):
        latest_release = get_latest_release(releases_dir, bin)
        if is_empty_release(latest_release):
            continue

        print('BINARY: ' + bin)
        copy_file(f'{releases_dir}/{latest_release}', f'{target_dir}/{remove_date(latest_release)}')

def install_linux_binary(path, target_dir, category, url):
    releases_dir = f'{path}/releases'

    if not Path(releases_dir).exists():
        print(f'Warning! Ignored {category}: {url}')
        return

    for bin in uniq_files_with_stripped_date(releases_dir, None):
        latest_release = get_latest_release(releases_dir, bin)
        if is_empty_release(latest_release):
            continue

        print('BINARY: ' + bin)
        copy_file(f'{releases_dir}/{latest_release}', f'{target_dir}/linux/{remove_date(latest_release)}')

def install_zip_release(path, target_dir, category, url):
    releases_dir = f'{path}/releases'

    if not Path(releases_dir).exists():
        print(f'Warning! Ignored {category}: {url}')
        return
    
    for zip in uniq_files_with_stripped_date(releases_dir, None):
        latest_release = get_latest_release(releases_dir, zip)
        if is_empty_release(latest_release):
            continue

        unzip(f'{releases_dir}/{latest_release}', target_dir)

def install_mra_alternatives(path, target_dir, category, url):
    print(f'Installing MRA Alternatives {url}')
    copy_folder(f'{path}/_alternatives', f'{target_dir}/_Arcade/_alternatives')

def install_fonts(path, target_dir, category, url):
    print(f'Installing Fonts {url}')
    for font in list_fonts(path):
        copy_file(f'{path}/{font}', f'{target_dir}/font/{font}')

def install_folders(path, target_dir, category, url):
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
}

def install_script(url, target_dir):
    print('Script: ' + url)
    download_file(url, f'{target_dir}/Scripts/{Path(url).name}')

def install_empty_folder(url, target_dir):
    touch_folder(f'{target_dir}/{url}')

def install_gamecontrollerdb(url, target_dir):
    print(f"SDL Game Controller DB: {url}")
    download_file(url, f'{target_dir}/linux/gamecontrollerdb/{Path(url).name}')

def install_cheats(mapping, target_dir):
    page_url = "https://gamehacking.org/mister"

    parts = mapping.split('|')
    cheat_key = parts[0].strip()
    cheat_platform = parts[1].strip()

    cheat_zips = collect_cheat_zips(page_url)

    cheat_zip = next(cheat_zip for cheat_zip in cheat_zips if cheat_key in cheat_zip)
    cheat_url = f'{page_url}/{cheat_zip}'
    tmp_zip = f'/tmp/{cheat_key}{cheat_platform}.zip'
    cheat_folder = f'{target_dir}/Cheats/{cheat_platform}'

    print(f'cheat_keys: {cheat_key}, cheat_platform: {cheat_platform}, cheat_zip: {cheat_zip}, cheat_url: {cheat_url}')

    download_file(cheat_url, tmp_zip)
    unzip(tmp_zip, cheat_folder)

def install_cheats_backup(url, target_dir):
    tmp_zip = '/tmp/old_main.zip'
    download_file(url, tmp_zip)
    unzip(tmp_zip, f'{target_dir}/Cheats/')

extra_content_early_installers = {
    'user-content-scripts': install_script,
    'user-content-empty-folder': install_empty_folder,
    'user-cheats': install_cheats,
    'user-backup-cheats': install_cheats_backup,
    'user-content-gamecontrollerdb': install_gamecontrollerdb,
}

# mister domain helpers

class Metadata:
    @staticmethod
    def new_props():
        return {}

    def __init__(self, props):
        self._props = props

def mra_files(folder):
    return [without_folder(folder, f) for f in list_files(folder, recursive=False) if Path(f).suffix.lower() == '.mra']

def is_arcade_core(path):
    return Path(path).name.lower().startswith('arcade-')

def is_rbf(path):
    return Path(path).suffix.lower() == '.rbf'

def get_latest_release(folder, bin):
    files = [without_folder(folder, f) for f in list_files(folder, recursive=False)]
    releases = sorted([f for f in files if bin in f and remove_date(f) != f])
    return releases[-1]

def uniq_files_with_stripped_date(folder, home):
    result = []
    for f in list_files(folder, recursive=False):
        f = without_folder(folder, str(Path(f).with_suffix('')))

        no_date = remove_date(f)
        if no_date == f or no_date in result:
            continue

        result.append(no_date)

    if home is not None:
        only_home = [f for f in result if home.lower() in f.lower()]
        if len(only_home) > 0:
            return only_home

    return result

def clean_palettes(palette_folder):
    for file in list_files(palette_folder, recursive=True):
        path = Path(file)
        if path.suffix.lower() in ['.pal', '.gbp']:
            continue

        path.unlink()

def find_palette_folder(path):
    for folder in list_folders(path):
        if folder.lower() in ['palette', 'palettes']:
            return folder
        
    return None

def is_standard_core_category(category):
    return category.strip() in ["_Computer", "_Arcade", "_Console", "_Other", "_Utility"]

def is_mgl(file):
    return Path(file).suffix.lower() == '.mgl'

def is_doc(file):
    return Path(file).suffix.lower() in ['.md', '.pdf', '.txt', '.rtf']

def is_mra(file):
    return Path(file).suffix.lower() == '.mra'

def files_with_no_date(folder):
    return [without_folder(folder, f) for f in list_files(folder, recursive=True) if f == remove_date(f)]

def list_readmes(folder):
    files = [without_folder(folder, f) for f in list_files(folder, recursive=False)]
    return [f for f in files if 'readme.' in f.lower()]

def mgl_files(folder):
    return [without_folder(folder, f) for f in list_files(folder, recursive=False) if Path(f).suffix.lower() == '.mgl']

def extract_mgl(mgl):
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

def remove_date(path):
    if len(path) < 10:
        return path

    last_part = Path(path).stem[-9:]
    if last_part[0] == '_' and last_part[1:].isnumeric():
        return path.replace(last_part, '')

    return path

def without_folder(folder, f):
    return f.replace(f'{folder}/', '').replace(folder, '').strip()

def is_empty_release(bin):
    return bin == '' or bin is None or len(bin) == 0

def list_fonts(path):
    return [Path(f).name for f in list_files(path, recursive=True) if Path(f).suffix.lower() == '.pf']

def collect_cheat_zips(url):
    text = fetch_text(url, cookies={'challenge': 'BitMitigate.com'})
    return [f[f.find('mister_'):f.find('.zip') + 4] for f in text.splitlines() if 'mister_' in f and '.zip' in f]

def download_mister_devel_repository(input_url, delme, category):
    name = get_repository_name(input_url)
    name, branch = get_branch(name)

    path = f'{delme}/{name}'

    if category[0] == '_':
        path = path + category
    
    if len(branch) > 0:
        path = path + branch

    git_url = f'{input_url.replace("/tree/" + branch, "")}.git'
    download_repository(path, git_url, branch)
    return path

def get_repository_name(input_url):
    return str(Path(urlparse(input_url).path.split('/')[2]).with_suffix(''))

# file system utilities

def get_branch(name):
    pos = name.find('/tree/')
    if pos == -1:
        return name, ""
    return name[0:pos], name[pos + len('/tree/'):]

def list_files(directory, recursive):
    for f in os.scandir(directory):
        if f.is_dir() and recursive:
            yield from list_files(f.path, recursive)
        elif f.is_file():
            yield f.path

def list_folders(directory):
    for f in os.scandir(directory):
        if f.is_dir():
            yield (f.path.replace(directory + '/', '').replace(directory, ''))

def copy_file(source, target):
    Path(target).parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)

def copy_folder(source, target):
    shutil.copytree(source, target)

def touch_folder(folder):
    folder = Path(folder)
    if folder.exists():
        return

    folder.mkdir(parents=True, exist_ok=True)
    Path(f'{folder}/.delme').touch()

def unzip(zip_file, target_dir):
    Path(target_dir).mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(zip_file, 'r') as zip_ref:
        zip_ref.extractall(target_dir)

def is_valid_uri(x):
    try:
        result = urlparse(x)
        return all([result.scheme, result.netloc])
    except:
        return False

# network utilities

def fetch_text(url, cookies=None):
    r = requests.get(url, allow_redirects=True, cookies=cookies)
    if r.status_code != 200:
        raise Exception(f'Request to {url} failed')
    
    return r.text

def download_repository(path, url, branch):
    if Path(path).exists():
        shutil.rmtree(path, ignore_errors=True)
    os.makedirs(path)

    minus_b = '' if len(branch) == 0 else f'-b {branch}'
    run(f'git -c protocol.version=2 clone -q --no-tags --no-recurse-submodules --depth=1 {minus_b} {url} {path}')

def download_file(url, target):
    Path(target).parent.mkdir(parents=True, exist_ok=True)
    
    r = requests.get(url, allow_redirects=True)
    if r.status_code != 200:
        raise Exception(f'Request to {url} failed')
    
    with open(target, 'wb') as f:
        f.write(r.content)

# execution utilities

def run(command, cwd=None):
    result = subprocess.run(shlex.split(command), cwd=cwd, shell=False, stderr=subprocess.STDOUT)
    if result.returncode == -2:
        raise KeyboardInterrupt()
    elif result.returncode != 0:
        print(f'returncode {result.returncode} from: {command}')
        raise Exception(f'returncode {result.returncode} from: {command}')

if __name__ == '__main__':
    main()
