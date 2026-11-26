"""Audit Watch and iPhone language coverage without compiling asset catalogs."""
from pathlib import Path
import json
import re
import subprocess

root = Path(__file__).resolve().parents[1]
module = root / 'terrariumidle_ios/Apps/Modules/AppleWatch'
shared = json.loads((module / 'Shared/WatchLocalizable.xcstrings').read_text())['strings']
main = json.loads((root / 'terrariumidle_ios/Localizable.xcstrings').read_text())['strings']
languages = {'vi', 'en', 'ja', 'zh-Hans', 'ko'}
paths = list(module.rglob('*.swift')) + list((root / 'TerrariumWatch').glob('*.swift')) + list((root / 'TerrariumWatchWidgets').glob('*.swift'))
keys = set()
for path in paths:
    for key in re.findall(r'"([^"\n]+)"', path.read_text()):
        if re.search('[À-ỹ]', key) and '\\(' not in key:
            keys.add(key)
# These shared UI elements are also shown inside the Watch setup screen.
sleep_source = (root / 'terrariumidle_ios/Apps/Modules/Sleep/SleepJournalViews.swift').read_text().split('struct ManualSleepSheet')[0]
schedule_keys = set(re.findall(r'"([^"\n]+)"\.tr', sleep_source))
for catalog, required in [(shared, keys), (main, keys | schedule_keys)]:
    for key in sorted(required):
        assert key in catalog, f'Missing key: {key}'
        entry = catalog[key].get('localizations', {})
        assert languages <= entry.keys(), f'Missing language: {key}'
        source_args = sorted(re.findall(r'%(?:\d+\$)?[@dif]', key))
        for language in languages:
            unit = entry[language].get('stringUnit', {})
            value = unit.get('value', '')
            assert value and unit.get('state') == 'translated', (key, language)
            assert sorted(re.findall(r'%(?:\d+\$)?[@dif]', value)) == source_args, (key, language, 'format arguments')
consent = json.loads((root / 'terrariumidle_ios/InfoPlist.xcstrings').read_text())['strings']
for key in ['NSHealthShareUsageDescription', 'NSHealthUpdateUsageDescription', 'NSLocationWhenInUseUsageDescription']:
    assert languages <= consent[key]['localizations'].keys()
# Shared catalogs and language lookup must be in each Watch target, not just in iOS.
project = json.loads(subprocess.check_output(['plutil', '-convert', 'json', '-o', '-', str(root / 'terrariumidle_ios.xcodeproj/project.pbxproj')]))['objects']
for target_name in ['TerrariumWatch', 'TerrariumWatchWidgets']:
    target = next(v for v in project.values() if v.get('isa') == 'PBXNativeTarget' and v.get('name') == target_name)
    refs = [project[project[file]['fileRef']]['path']
            for phase in target['buildPhases']
            for file in project[phase].get('files', [])]
    assert any(p.endswith('/WatchLocalizable.xcstrings') for p in refs), target_name
    assert any(p.endswith('/WatchText.swift') for p in refs), target_name
print(f'PASS: {len(keys)} Watch strings + {len(schedule_keys)} schedule strings, 5 languages, format arguments, Health/location consent and both target resources')
