#!/usr/bin/env python3

import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("calculate_db", "../calculate_db.py")
calculate_db = importlib.util.module_from_spec(spec)
spec.loader.exec_module(calculate_db)

tags = calculate_db.Tags(None)
db = calculate_db.create_db('../..', {
    'sha': 3,
    'latest_zip_url': 'w/',
    'base_files_url': 'x/%s/a',
    'db_url': 'y/lala.json.zip',
    'db_files': 'lala.json.zip',
    'db_id': 'z/',
    'linux_github_repository': '',
    'zips_config': ''
}, tags)

calculate_db.save_data_to_compressed_json(db, 'db.json', 'db1.json.zip')

hash1 = calculate_db.hash('db1.json.zip')

calculate_db.save_data_to_compressed_json(db, 'db.json', 'db2.json.zip')

hash2 = calculate_db.hash('db2.json.zip')

print("hash1 %s" % hash1)
print("hash2 %s" % hash2)

Path('db.json').unlink(missing_ok=True)
Path('db1.json.zip').unlink(missing_ok=True)
Path('db2.json.zip').unlink(missing_ok=True)

if hash1 != hash2:
    print("hash1 is not same as hash2")
    exit(1)
