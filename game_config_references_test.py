"""Validate production references against the config contract, without an engine.

Run from the repository root. Covers full config handles, explicit subsection
handles, getGameConfig() access and constant string subscripts. Dynamic aerosol
selection is checked at its section and at the settings handle.
"""
from pathlib import Path
import re
import subprocess

TOKEN = re.compile(
    r'--\[(=*)\[.*?\]\1\]|--[^\r\n]*|\[(=*)\[.*?\]\2\]|'
    r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|[A-Za-z_]\w*|\s+|.', re.S)


def tokens(text):
    return [m for m in TOKEN.finditer(text)
            if not m[0].isspace() and not m[0].startswith('--')]


def suffix(ts, start):
    parts = []
    while start + 1 < len(ts):
        if ts[start][0] == '.' and re.fullmatch(r'[A-Za-z_]\w*', ts[start+1][0]):
            parts.append(ts[start+1][0]); start += 2
        elif (start + 2 < len(ts) and ts[start][0] == '['
              and ts[start+2][0] == ']' and ts[start+1][0][0] in '\"\''):
            parts.append(ts[start+1][0][1:-1]); start += 3
        else:
            break
    return '.'.join(parts)


expected = Path('tests/fixtures/game_config_expected.lua').read_text()
leaves = set(re.findall(r'\["([\w.]+)"\]', expected))
paths = {''}
for leaf in leaves:
    parts = leaf.split('.')
    paths.update('.'.join(parts[:n]) for n in range(1, len(parts)+1))

# These modules accept config/subsection arguments rather than creating them.
parameters = {
    'luarules/gadgets/include/police_bribery.lua': {'config': ''},
    'luarules/gadgets/include/objective_income.lua': {'config': 'objectives.income'},
    'scripts/lib_aerosol_behaviour.lua': {'config': '', 'settings': 'military.aerosols'},
}
files = subprocess.check_output(['git', 'ls-files', '*.lua'], text=True).splitlines()
errors, checked = [], 0
for name in files:
    if name.startswith('tests/'):
        continue
    text = Path(name).read_bytes().decode('latin1')
    ts = tokens(text)
    handles = {'GameConfig': '', 'gameConfig': '', **parameters.get(name, {})}
    # Follow named local aliases such as cfg = getGameConfig().police, and
    # cfg = config.espionage.bribe. Runtime data tables are not config handles.
    for _ in range(4):
        for i in range(2, len(ts)-1):
            if ts[i-1][0] != '=' or not re.fullmatch(r'[A-Za-z_]\w*', ts[i-2][0]):
                continue
            base, pos = ts[i][0], i+1
            prefix = None
            if base == 'getGameConfig' and [t[0] for t in ts[pos:pos+2]] == ['(', ')']:
                prefix, pos = '', pos+2
            elif base == 'GG' and [t[0] for t in ts[pos:pos+2]] == ['.', 'GameConfig']:
                prefix, pos = '', pos+2
            elif base in handles:
                prefix = handles[base]
            if prefix is not None:
                path = '.'.join(filter(None, (prefix, suffix(ts, pos))))
                # Scalars aren't config handles. Dynamic subscripts are
                # deliberately checked separately below.
                if path in paths and path not in leaves:
                    handles[ts[i-2][0]] = path
    for i, token in enumerate(ts):
        base, pos = token[0], i+1
        if base == 'getGameConfig' and [t[0] for t in ts[pos:pos+2]] == ['(', ')']:
            prefix, pos = '', pos+2
        elif base in handles:
            prefix = handles[base]
        else:
            continue
        tail = suffix(ts, pos)
        if not tail:
            continue
        path = '.'.join(filter(None, (prefix, tail)))
        if base == 'settings' and name == 'scripts/lib_aerosol_behaviour.lua':
            valid = any('military.aerosols.'+kind+'.'+tail in paths
                        for kind in ('orgyanyl', 'wanderlost', 'tollwutox', 'depressol'))
        else:
            valid = path in paths
        checked += 1
        if not valid:
            errors.append(f'{name}:{text[:token.start()].count(chr(10))+1}: {base}.{tail}')
assert not errors, '\n'.join(errors)
print(f'Game config references: {checked} accesses checked across {len(files)} tracked Lua files PASS')
