#!/usr/bin/env python3
"""Resolve only the reviewed c0982bac/cf2e2f04 reverse-patch overlaps.
This temporary maintenance script is not included in the resulting commit.
"""
from pathlib import Path
import re
import subprocess

TARGET = 'cf2e2f04bdc4d9369b0eb0adda63b2030d9ad5fd'
BASE = 'c0982bac374dd211761eac305d393c193c1763a8'

def read_version(path, version='current'):
    ref = BASE if version == 'current' else TARGET + '^'
    return subprocess.check_output(['git', 'show', f'{ref}:{path}'], text=True)

def write(path, source):
    assert not re.search(r'(?m)^(<<<<<<< |=======\s*$|>>>>>>> )', source), path
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text(source)

def replace(source, old, new, count=1):
    actual = source.count(old)
    assert actual == count, (old[:100], actual, count)
    return source.replace(old, new)

def remove_log_calls(source):
    """Remove diagnostic log calls while respecting quoted Lua strings."""
    while True:
        match = re.search(r'(?<![\w.])log\(', source)
        if not match:
            return source
        begin = match.start()
        i = match.end()
        depth = 1
        quote = None
        while depth:
            assert i < len(source), 'unterminated log call'
            char = source[i]
            if quote:
                if char == '\\':
                    i += 2
                    continue
                if char == quote:
                    quote = None
            elif char in "'\"":
                quote = char
            elif char == '(':
                depth += 1
            elif char == ')':
                depth -= 1
            i += 1
        line_start = source.rfind('\n', 0, begin) + 1
        if not source[line_start:begin].strip() and source[i:i+1] == '\n':
            begin, i = line_start, i+1
        source = source[:begin] + source[i:]

# Preserve independent regression coverage and later workflow triggers.
for path in ['.github/workflows/building-block-damage.yml', '.github/workflows/effects-validation.yml']:
    source = read_version(path)
    source = ''.join(line for line in source.splitlines(keepends=True) if 'execution_trace' not in line)
    write(path, source)

# Parent dispatcher with every later non-diagnostic delta retained.
path = 'luarules/gadgets/game_building_block_damage.lua'
source = read_version(path, 'parent')
source = replace(source,
    'local blockDamageableHouseTypeTable = getStructuralBuildingTypeTable(UnitDefs)\n',
    'local blockDamageableHouseTypeTable = getStructuralBuildingTypeTable(UnitDefs)\n'
    'local damageHealthFraction = getBuildingDamageConfig().healthThreshold\n')
source = replace(source, 'maxHP * 0.5', 'maxHP * damageHealthFraction', count=2)
source = replace(source,
    '    if GG.BuildingDamageAnchor then GG.BuildingDamageAnchor[id] = nil end\n',
    '    if GG.BuildingDamageAnchor then GG.BuildingDamageAnchor[id] = nil end\n'
    '    if GG.BuildingDamageEffects then GG.BuildingDamageEffects[id] = nil end\n')
write(path, source)

# Preserve finite expiry and multiplicative distance/lifetime fading.
path = 'luarules/gadgets/include/smoke_ribbon_renderer.lua'
source = read_version(path, 'parent')
source = replace(source,
    '        local now = (Spring.GetGameFrame()+(Spring.GetFrameTimeOffset() or 0))/(Game.gameSpeed or 30)\n',
    '        local sampleFrame = Spring.GetGameFrame()+(Spring.GetFrameTimeOffset() or 0)\n'
    '        local now = sampleFrame/(Game.gameSpeed or 30)\n')
source = replace(source,
    '            if r.enabled and (fullView or (los and los.los)) and not Spring.GetUnitIsDead(id)\n',
    '            if r.enabled and (not r.endFrame or sampleFrame < r.endFrame)\n'
    '                and (fullView or (los and los.los)) and not Spring.GetUnitIsDead(id)\n')
source = replace(source,
    '                        local fade = 1\n',
    '                        local fade = 1\n'
    '                        if r.endFrame and (r.fadeFrames or 0) > 0 then\n'
    '                            fade = math.min(1, (r.endFrame-sampleFrame)/r.fadeFrames)\n'
    '                        end\n')
source = replace(source, '                            fade = 1-t*t*(3-2*t)\n',
    '                            fade = fade*(1-t*t*(3-2*t))\n')
write(path, source)

# Preserve the current controller, especially lightBlockFire's functional clock.
path = 'scripts/lib_building_damage.lua'
source = read_version(path)
source = replace(source,
    "local trace = VFS.Include('luarules/gadgets/include/execution_trace.lua').New('BuildingDestruction', {maxEvents=256})\n"
    'local function log(stage, fields, cycle)\n'
    '    trace.Log(unitID, cycle or (Spring.GetGameFrame and Spring.GetGameFrame() or 0), stage, fields)\n'
    'end\n', '')
source = remove_log_calls(source)
source = replace(source,
    "    options.executionTrace = {prefix='BuildingDestruction',stagePrefix='building_fire',cycle=cycle}\n", '')
source = replace(source, 'local ok, reason=GG.SmokeRibbon.Set(unitID,slot,p,options)',
    'local ok=GG.SmokeRibbon.Set(unitID,slot,p,options)')
source = replace(source,
    '    local columnCount, visibleCount = 0, 0\n'
    '    for _ in pairs(columns) do columnCount=columnCount+1 end\n'
    '    for _, block in ipairs(blocks) do if visible[block.piece] then visibleCount=visibleCount+1 end end\n', '')
source = replace(source, 'local function nearestBlock(hitPiece, x, y, z, cycle)',
    'local function nearestBlock(hitPiece, x, y, z)')
source = replace(source, 'nearestBlock(hit.piece, hit.x, hit.y, hit.z, frame)',
    'nearestBlock(hit.piece, hit.x, hit.y, hit.z)')
source = replace(source, '    local candidates, hidden, gone, pending = 0, 0, 0, 0\n', '')
source = replace(source,
    '        if block.gone then gone=gone+1\n'
    '        elseif block.pending then pending=pending+1\n'
    '        elseif not visible[block.piece] then hidden=hidden+1 end\n', '')
source = replace(source, '            candidates=candidates+1\n', '')
source = re.sub(r'(?m)^    if not collapsing then\s*end\n', '', source)
source = replace(source, '        else\n        end\n', '        end\n')
source = replace(source,
    '    -- ticking. Avoid a health query, support scan and trace on every fire tick.\n',
    '    -- ticking. Avoid a health query and support scan on every fire tick.\n')
assert 'executionTrace' not in source and 'trace.' not in source and not re.search(r'\blog\(', source)
write(path, source)

# Current fixture loaders are required by the newer shared functional config.
path = 'tests/building_block_damage_test.lua'
source = read_version(path)
source = replace(source, '        Echo=noop,\n', '')
source = replace(source, 'Spring={Echo=noop,UnitScript={', 'Spring={UnitScript={')
write(path, source)

# Keep all later lifetime, remnant, visibility and cheap-tick assertions.
path = 'tests/building_damage_header_test.lua'
source = read_version(path)
source = replace(source, '        traces={},frame=0,healthReads=0}', '        frame=0,healthReads=0}')
source = replace(source, 'Echo=function(line)state.traces[#state.traces+1]=line end', 'Echo=noop')
source = replace(source, 'local healthReads,traceCount=a.healthReads,#a.traces', 'local healthReads=a.healthReads')
source = replace(source,
    "assert(a.healthReads==healthReads and #a.traces==traceCount, 'effects-only tick rescanned or retraced the structure')",
    "assert(a.healthReads==healthReads, 'effects-only tick rescanned the structure')")
begin = source.index("local sequence={'block_lookup_skipped'")
end = source.index('-- Reused include source', begin)
source = source[:begin] + source[end:]
write(path, source)

write('DEBUG-INSTRUMENTATION.md', '''# Optional building fire and tank muzzle diagnostics

Production tracing from `cf2e2f04bdc4d9369b0eb0adda63b2030d9ad5fd`
(`debug: trace building fire and tank muzzle delivery`) is removed from master.
The instrumented snapshot and its reuse instructions are retained on:

- Branch: `debug/building-fire-tank-muzzle-tracing`
- Archive head: `8004b41973bde9abf63a4b6e985619088ec54ccd`
- Guide on that branch: `DEBUG-INSTRUMENTATION.md`
- Detailed stage guide on that branch: `docs/building-effects-tracing.md`

```sh
git fetch origin
git show origin/debug/building-fire-tank-muzzle-tracing:DEBUG-INSTRUMENTATION.md
```

This is a historical diagnostic archive, not a feature branch to merge wholesale.
Do not delete it as an already-merged branch. Future coding assistants should
read the archive guide and inspect the current runtime before reapplying traces.
Use a fresh debugging branch from current master and explicitly reapply the
instrumentation or revert its removal. Preserve subsequent gameplay and effects
changes when resolving conflicts; do not restore entire old runtime files.

In particular, keep the configured damage threshold, retained block geometry,
facade flame placement, finite effect lifetimes, and client-side expiry/fading.
The frame argument passed to `lightBlockFire` now controls actual lifetimes and
must remain even with tracing removed. Ordinary error reporting and the manual
validation commands are unaffected. Traces have allocation and bookkeeping costs
in addition to log output, so keep diagnostic commits separate from fixes.

The archive's original stage guide contains historical numerical examples; it
is not an instruction to reset current dimensions, thresholds, or timings.
''')

for root in ['scripts', 'luarules', 'luaui/widgets_mosaic', 'tests']:
    for path in Path(root).rglob('*.lua'):
        source = path.read_text(errors='replace')
        assert 'execution_trace.lua' not in source, f'leftover trace import: {path}'
        assert 'executionTrace' not in source, f'leftover trace metadata: {path}'

# Exact blobs already reviewed and exercised by fifteen local regressions.
expected = {
 '.github/workflows/building-block-damage.yml': '5d7b99398e0ceb2c4d844decc9863df6d0d75ea4',
 '.github/workflows/effects-validation.yml': 'f034cd3076ca154a72c23eb783cffc1b6fbf3d23',
 'DEBUG-INSTRUMENTATION.md': '6e90765447907f9f84e01ad9970cfc47685d1162',
 'docs/building-effects-tracing.md': None,
 'luarules/gadgets/game_building_block_damage.lua': 'ecb2f7952991090ada72edb351b78a79ef182e4d',
 'luarules/gadgets/gfx_smoke_ribbons.lua': '0d3ca55aed475cc26b73300ec90bc805f54452ad',
 'luarules/gadgets/include/execution_trace.lua': None,
 'luarules/gadgets/include/smoke_ribbon_renderer.lua': '802ade66ba99e9b6f47b28f04114e1d766a48cc4',
 'luaui/widgets_mosaic/gfx_light_effects.lua': '6a42fb420f0c00ae72d16843fcb76c263c0dbbcc',
 'luaui/widgets_mosaic/include/combat_light_sources.lua': '4a478b81d5b848b52f0f43a156f4a2ae30a8a073',
 'luaui/widgets_mosaic/include/tank_muzzle_flash.lua': '020b7026a9404d36011076ef410f08f3e94860f3',
 'scripts/lib_building_damage.lua': '8ffa0f046633ca0450a64a265cce49562e84f446',
 'scripts/lib_graphene_arc.lua': 'bf69ff78e61484d85300351aa3279f5bb1d09e13',
 'scripts/tankscript.lua': '31866d10feaaaec3c9a11cf162ef35368dc34847',
 'tests/building_block_damage_test.lua': 'da4c9998f43cda09419c40e3a88135cad473d5b7',
 'tests/building_damage_header_test.lua': '2bb55d5092fa6f02aa6d863e3b50be225e5ed1a4',
 'tests/building_rubble_lifecycle_test.lua': 'a0011047417a1d05de4d768282908610d1851e3a',
 'tests/execution_trace_test.lua': None,
 'tests/smoke_ribbons_lifecycle.lua': 'ad0a7e9181aded33af5570334b681e079da1fa70',
 'tests/tank_muzzle_effects.lua': '949c41710d5639c5a5f956e76f7d6a7e60b9b042',
}
for path, sha in expected.items():
    actual = subprocess.check_output(['git', 'hash-object', path], text=True).strip() if Path(path).exists() else None
    assert actual == sha, (path, actual, sha)
subprocess.run(['git', 'add', '-A'], check=True)
changed = subprocess.check_output(['git', 'diff', '--cached', '--name-only'], text=True).splitlines()
assert set(changed) == set(expected), changed
subprocess.run(['git', 'diff', '--cached', '--check'], check=True)
print('Verified exactly 20 reviewed paths; no runtime trace imports or metadata remain.')
