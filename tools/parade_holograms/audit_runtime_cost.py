#!/usr/bin/env python3
"""Count bounded native work; not a frame-time or GPU benchmark."""
import json, subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
new=json.loads((ROOT/'tools/parade_holograms/import_manifest.json').read_text())
old=json.loads((ROOT/'tools/parade_holograms/manifest.json').read_text())
old_counts={k:v['triangles'] for k,v in old['pieces'].items()}
lua='''local cfg=dofile('luarules/configs/parade_hologram_scene.lua')
local models=dofile('luarules/configs/parade_hologram_models.lua')
print('LIMITS',cfg.maxVisiblePayloads,2)
for id=1,30 do
 local before,after={},{};local count=0
 for _,item in ipairs(cfg.figures) do
  for _,role in ipairs({'body','head','mask'}) do
   table.insert(before,item.model..role);table.insert(after,models.figures[item.model].pieces[role])
  end
  count=count+1
 end
 for _,item in ipairs(cfg.props) do
  table.insert(before,'parade'..item.model)
  local choices=models.props[item.model].variants
  local choice=choices[(id+count)%#choices+1]
  table.insert(after,choice.piece)
  for _,w in ipairs(choice.wings or {}) do table.insert(after,w.piece) end
  count=count+1
 end
 print('COST',id,table.concat(before,','),table.concat(after,','))
end'''
lines=subprocess.check_output(['lua','-'],input=lua,text=True,cwd=ROOT).splitlines()
costs=[]
for line in lines:
 fields=line.split('\t')
 if fields[0]=='LIMITS':limits=int(fields[1])*int(fields[2])
 else:
  before,after=fields[2].split(','),fields[3].split(',')
  costs.append(dict(before_draws=len(before),after_draws=len(after),
                    before_triangles=sum(old_counts[n] for n in before),
                    after_triangles=sum(new['pieces'][n] for n in after)))
report={'comparison':'Prior embedded cage scenery with the same merged six-lantern station configuration',
        'scope':'Fully visible native pass only; excludes sprites, buildings, radiance and CPU pose cost. Not an FPS measurement.',
        'max_simultaneous_stations':limits,
        'per_station':{key:{'min':min(c[key] for c in costs),'max':max(c[key] for c in costs)} for key in costs[0]},
        'worst_case_native_draws_before':limits*max(c['before_draws'] for c in costs),
        'worst_case_native_draws_after':limits*max(c['after_draws'] for c in costs),
        'worst_case_native_triangles_before':limits*max(c['before_triangles'] for c in costs),
        'worst_case_native_triangles_after':limits*max(c['after_triangles'] for c in costs)}
assert all(c['after_draws']==c['before_draws']+2 for c in costs)
assert all(c['after_triangles']<c['before_triangles'] for c in costs)
path=ROOT/'tools/parade_holograms/runtime_cost.json';path.write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
