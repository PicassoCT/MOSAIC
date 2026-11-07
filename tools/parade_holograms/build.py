#!/usr/bin/env python3
"""Build editable cages and native cage scenery, preserving authored floats.

The payload updater is deliberately an append/replace of our own namespace.
It never invokes the historical six-float generator: the current payload is a
user-expanded FBX export whose unrelated libraries and scene nodes must survive.
"""
from __future__ import annotations

import argparse
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import sys
from lxml import etree as ET
import numpy as np

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
sys.path.insert(0,str(ROOT/'tools/truck_parade_payloads/source'))
from figures import build as build_figures
from props import build as build_props

NS='http://www.collada.org/2005/11/COLLADASchema'
PREFIX='paradehologram_'
SCENE_ROOT='paradeholograms'
PAYLOAD=ROOT/'objects3d/truckPayloadParade.dae'
STANDALONE=ROOT/'objects3d/paradeHologramScenery.dae'


def tag(s):
    return '{'+NS+'}'+s


def child(parent,name,attrs=None,text=None):
    n=ET.SubElement(parent,tag(name),attrs or {})
    if text is not None:n.text=str(text)
    return n


def format_float(x):
    return format(float(x),'.8g')


def add_material(doc):
    image=child(child(doc,'library_images'),'image',{'id':PREFIX+'atlas_image'})
    child(image,'init_from',text='../unittextures/house_asian_diffuse.dds')
    effect=child(child(doc,'library_effects'),'effect',{'id':PREFIX+'atlas_effect'})
    profile=child(effect,'profile_COMMON')
    surface=child(child(profile,'newparam',{'sid':PREFIX+'surface'}),'surface',{'type':'2D'})
    child(surface,'init_from',text=PREFIX+'atlas_image')
    sampler=child(child(profile,'newparam',{'sid':PREFIX+'sampler'}),'sampler2D')
    child(sampler,'source',text=PREFIX+'surface')
    shader=child(child(profile,'technique',{'sid':'common'}),'lambert')
    child(child(shader,'diffuse'),'texture',{'texture':PREFIX+'sampler','texcoord':'UVMap'})
    material=child(child(doc,'library_materials'),'material',
                   {'id':PREFIX+'atlas_material','name':'ParadeAsianAtlas'})
    child(material,'instance_effect',{'url':'#'+PREFIX+'atlas_effect'})


def geometry(library,name,data):
    records=data['records'];indices=data['indices'];gid=PREFIX+name+'_mesh'
    m=child(child(library,'geometry',{'id':gid,'name':name}),'mesh')
    for label,start,size,components in (('pos',0,3,'XYZ'),('norm',3,3,'XYZ'),('uv',6,2,'ST')):
        sid=PREFIX+name+'_'+label
        s=child(m,'source',{'id':sid})
        a=child(s,'float_array',{'id':sid+'_array','count':str(len(records)*size)},
                ' '.join(format_float(r[k]) for r in records for k in range(start,start+size)))
        accessor=child(child(s,'technique_common'),'accessor',
                       {'source':'#'+a.get('id'),'count':str(len(records)),'stride':str(size)})
        for c in components:child(accessor,'param',{'name':c,'type':'float'})
    v=child(m,'vertices',{'id':PREFIX+name+'_vertices'})
    child(v,'input',{'semantic':'POSITION','source':'#'+PREFIX+name+'_pos'})
    t=child(m,'triangles',{'count':str(len(indices)//3),'material':PREFIX+'atlas'})
    for sem,suffix,offset in (('VERTEX','vertices',0),('NORMAL','norm',1),('TEXCOORD','uv',2)):
        attrs={'semantic':sem,'source':'#'+PREFIX+name+'_'+suffix,'offset':str(offset)}
        if sem=='TEXCOORD':attrs['set']='0'
        child(t,'input',attrs)
    child(t,'p',text=' '.join(f'{i} {i} {i}' for i in indices))
    return gid


def node(parent,name,gid=None):
    n=child(parent,'node',{'id':name,'name':name,'type':'NODE'})
    # Identity nodes are intentional. Recoil gl.UnitPiece draws the raw mesh
    # buffer with no model/piece transform, independently of FBX scene units.
    child(n,'matrix',text='1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1')
    if gid:
        inst=child(n,'instance_geometry',{'url':'#'+gid})
        bind=child(child(child(inst,'bind_material'),'technique_common'),'instance_material',
                   {'symbol':PREFIX+'atlas','target':'#'+PREFIX+'atlas_material'})
        child(bind,'bind_vertex_input',{'semantic':'UVMap','input_semantic':'TEXCOORD','input_set':'0'})
    return n


def make_document(models,pieces):
    doc=ET.Element(tag('COLLADA'),{'version':'1.4.1'},nsmap={None:NS})
    asset=child(doc,'asset')
    child(child(asset,'contributor'),'authoring_tool',text='MOSAIC editable spline cages and pixel surface exporter')
    child(asset,'created',text='2026-11-05T00:00:00Z')
    child(asset,'modified',text='2026-11-05T00:00:00Z')
    child(asset,'unit',{'name':'meter','meter':'1'})
    child(asset,'up_axis',text='Y_UP')
    add_material(doc)
    library=child(doc,'library_geometries')
    geometries={name:geometry(library,name,data) for name,data in pieces.items()}
    scene=child(child(doc,'library_visual_scenes'),'visual_scene',
                {'id':'ParadeHologramScenery','name':'ParadeHologramScenery'})
    root=node(scene,SCENE_ROOT)
    for model in models:
        if model['category']=='prop':node(root,model['slug'],geometries[model['slug']])
        else:
            group=node(root,model['slug'])
            for role in ('body','head','mask'):
                name=model['slug']+role
                node(group,name,geometries[name])
    child(child(doc,'scene'),'instance_visual_scene',{'url':'#ParadeHologramScenery'})
    ET.indent(doc,space='  ')
    return doc


def canonical_definition(element):
    e=deepcopy(element)
    for item in e.iter():
        if item.text is not None and not item.text.strip():item.text=None
        if item.tail is not None and not item.tail.strip():item.tail=None
    return ET.tostring(e,method='c14n')


def original_fingerprints(doc):
    records={}
    for library in doc:
        kind=ET.QName(library).localname
        if kind.startswith('library_'):
            for e in library:
                if (e.get('id') or '').startswith(PREFIX):continue
                if kind=='library_visual_scenes':
                    for n in e:
                        if n.get('id')==SCENE_ROOT:continue
                        key=f'{kind}/{e.get("id")}/{n.get("id") or ET.QName(n).localname}'
                        records[key]=hashlib.sha256(canonical_definition(n)).hexdigest()
                else:
                    key=kind+'/'+str(e.get('id') or e.get('name'))
                    records[key]=hashlib.sha256(canonical_definition(e)).hexdigest()
        elif kind in ('asset','scene'):
            records[kind]=hashlib.sha256(canonical_definition(library)).hexdigest()
    return records


def patch_payload(path,scenery):
    parser=ET.XMLParser(remove_blank_text=False,resolve_entities=False,no_network=True)
    doc=ET.parse(str(path),parser)
    root=doc.getroot()
    before=original_fingerprints(root)
    for kind in ('library_images','library_effects','library_materials','library_geometries'):
        target=root.find(tag(kind))
        if target is None:
            # COLLADA libraries must precede <scene>.
            target=ET.Element(tag(kind));root.insert(list(root).index(root.find(tag('scene'))),target)
        for e in list(target):
            if (e.get('id') or '').startswith(PREFIX):target.remove(e)
        for e in scenery.find(tag(kind)):target.append(deepcopy(e))
    instance=root.find(tag('scene')+'/'+tag('instance_visual_scene'))
    if instance is None:raise ValueError('Payload has no active visual scene')
    active=instance.get('url','').removeprefix('#')
    scene=root.find(tag('library_visual_scenes')+'/'+tag('visual_scene')+f'[@id="{active}"]')
    if scene is None:raise ValueError('Payload active scene is unresolved')
    for e in list(scene):
        if e.get('id')==SCENE_ROOT:scene.remove(e)
    added=scenery.find(tag('library_visual_scenes')+'/'+tag('visual_scene')+'/'+tag('node'))
    scene.append(deepcopy(added))
    after=original_fingerprints(root)
    if before!=after:raise ValueError('Refusing to modify existing authored payload content')
    payload=ET.tostring(doc,encoding='utf-8',xml_declaration=True)
    temp=path.with_name(path.name+'.parade-new')
    temp.write_bytes(payload)
    temp.chmod(path.stat().st_mode & 0o777)
    # Verify the serialization as well as the in-memory preservation check.
    if original_fingerprints(ET.fromstring(payload,parser))!=before:
        temp.unlink();raise ValueError('Serialized payload content preservation failed')
    temp.replace(path)
    return before


def lua(value,indent=0):
    if isinstance(value,bool):return 'true' if value else 'false'
    if value is None:return 'nil'
    if isinstance(value,str):return json.dumps(value,ensure_ascii=True)
    if isinstance(value,(int,float)):return format_float(value)
    if isinstance(value,list):return '{'+', '.join(lua(v,indent) for v in value)+'}'
    if isinstance(value,dict):
        pad='    '*(indent+1)
        return '{\n'+''.join(pad+'['+lua(str(k))+'] = '+lua(v,indent+1)+',\n' for k,v in value.items())+'    '*indent+'}'
    raise TypeError(type(value))


def generate(skip_payload=False):
    if STANDALONE.exists() and b'FBX COLLADA exporter' in STANDALONE.read_bytes()[:4000]:
        raise ValueError('Artist export detected. Use import_export.py; refusing to overwrite edited source with legacy recipes.')
    from cage_surface import ROTATION, model_cells, mesh
    palette=json.loads((HERE/'palette.json').read_text())
    models=build_figures()+build_props()
    if len([m for m in models if m['category']!='prop'])!=16:
        raise ValueError('Expected four figures in each of the four requested categories')
    pieces={};catalog={'root':SCENE_ROOT,'figures':{},'props':{}}
    summary=[]
    for model in models:
        groups=model_cells(model)
        if model['category']!='prop' and set(groups)!={'body','head','mask'}:
            raise ValueError('Body, head and mask groups required: '+model['slug'])
        names={}
        for role,cells in groups.items():
            name=model['slug'] if model['category']=='prop' else model['slug']+role
            pieces[name]=mesh(cells,model['cell_size'],palette)
            names[role]=name
        vertices=np.concatenate([np.array(pieces[n]['records'])[:,:3] for n in names.values()])
        lo,hi=vertices.min(0),vertices.max(0)
        count=sum(len(pieces[n]['indices'])//3 for n in names.values())
        entry={'label':model['title'],'category':model['category'],'height':round(float(hi[1]),6),
               'bounds':[[round(float(x),6) for x in p] for p in (lo,hi)],
               'cellSize':model['cell_size']}
        if model['category']=='prop':
            entry['piece']=model['slug'];catalog['props'][model['prop_key']]=entry
        else:
            entry['headPivot']=(np.array(model['head_pivot'])@ROTATION.T).round(6).tolist()
            entry['pieces']=names;catalog['figures'][model['slug']]=entry
        summary.append({'name':model['slug'],**entry,'triangles':count,
                        'cage_parts':len(model['parts']),'description':model.get('description','')})
        print(f'{model["slug"]}: {count} triangles; height {hi[1]:.3f}; {len(model["parts"])} editable cage parts',flush=True)
    doc=make_document(models,pieces)
    STANDALONE.write_bytes(ET.tostring(doc,encoding='utf-8',xml_declaration=True))
    preserved=patch_payload(PAYLOAD,doc) if not skip_payload else {}
    cfg=ROOT/'luarules/configs/parade_hologram_models.lua'
    cfg.write_text('-- Generated by tools/parade_holograms/build.py; mesh dimensions are raw game units.\nreturn '+lua(catalog)+'\n')
    source=HERE/'source';source.mkdir(exist_ok=True)
    (source/'cages.json').write_text(json.dumps({'schema':1,'models':models},indent=2)+'\n')
    from maxscript import write_maxscript
    write_maxscript(models,palette,HERE/'Build_Parade_Hologram_Cages.ms')
    all_vertices=np.concatenate([np.asarray(d['records'])[:,:3] for d in pieces.values()])
    radius=int(np.ceil(np.linalg.norm(all_vertices,axis=1).max()))+1
    STANDALONE.with_suffix('.dae.lua').write_text(
        '-- Standalone authoring/inspection model; runtime uses pieces embedded in truckPayloadParade.dae.\n'
        f'return {{radius = {radius}, height = {int(np.ceil(all_vertices[:,1].max()))+1}, midpos = {{0, 0, 0}},\n'
        '    tex1 = "house_asian_diffuse.dds", tex2 = "house_asian_selfilu_reflection.png",\n}\n')
    manifest={'schema':1,'generator':'tools/parade_holograms/build.py',
              'coordinate_system':'Raw game units, Y up, +Z front; feet Y=0; identity piece transforms',
              'runtime_draw':'gl.UnitPiece draws raw buffers; do not apply the imported FBX unit or piece matrix',
              'figure_count':16,'prop_count':len(catalog['props']),'models':summary,
              'total_triangles':sum(len(d['indices'])//3 for d in pieces.values()),
              'pieces':{n:{'triangles':len(d['indices'])//3,'vertices':len(d['records']),
                           'cage_surface':True,'materials':d['materials']} for n,d in pieces.items()},
              'preserved_payload_definitions':preserved,
              'standalone_sha256':hashlib.sha256(STANDALONE.read_bytes()).hexdigest(),
              'payload_sha256':hashlib.sha256(PAYLOAD.read_bytes()).hexdigest(),
              'atlas_source':'tools/parade_holograms/palette.json',
              'authoring':'Editable connected spline cages; native Max Surface/Shell/UVW modifiers are retained'}
    (HERE/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(f'Total: {manifest["total_triangles"]} triangles, {len(pieces)} geometry pieces; '+
          f'{len(preserved)} original payload definitions preserved.',flush=True)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--skip-payload',action='store_true',help='Build authoring outputs without patching the game payload')
    generate(parser.parse_args().skip_payload)
