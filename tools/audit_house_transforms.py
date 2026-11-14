#!/usr/bin/env python3
"""Read-only audit of authored COLLADA transforms and visibility-risk geometry."""
from pathlib import Path
from collections import Counter
import argparse,json,hashlib
import numpy as np
import xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
NS={'c':'http://www.collada.org/2005/11/COLLADASchema'}


def classify(m):
    if not np.isfinite(m).all():return ['nonfinite'],None,None
    a=m[:3,:3];scales=np.linalg.norm(a,axis=0);flags=[]
    if scales.min()<1e-9 or abs(np.linalg.det(a))<1e-18:flags.append('singular')
    if scales.min()>0 and scales.max()/scales.min()>1.0001:flags.append('non-uniform')
    if scales.min()>1e-12 and np.max(np.abs((a/scales).T@(a/scales)-np.eye(3)))>1e-4:flags.append('sheared')
    if np.linalg.det(a)<0:flags.append('mirrored')
    if not np.allclose(m[3],[0,0,0,1],atol=1e-6):flags.append('non-affine')
    return flags,scales.tolist(),float(np.linalg.det(a))


def local_matrix(node):
    matrix=np.eye(4)
    for el in node:
        tag=el.tag.rsplit('}',1)[-1]
        if tag not in ('matrix','translate','scale','rotate','skew','lookat'):continue
        vals=np.fromstring(el.text or '',sep=' ');m=np.eye(4)
        if tag=='matrix':m=vals.reshape(4,4)
        elif tag=='translate':m[:3,3]=vals
        elif tag=='scale':m[:3,:3]=np.diag(vals)
        elif tag=='rotate':
            axis=vals[:3]/np.linalg.norm(vals[:3]);x,y,z=axis;t=np.deg2rad(vals[3])
            skew=np.array([[0,-z,y],[z,0,-x],[-y,x,0]])
            m[:3,:3]=np.eye(3)*np.cos(t)+(1-np.cos(t))*np.outer(axis,axis)+np.sin(t)*skew
        else:raise ValueError('Unsupported transform '+tag)
        matrix=matrix@m
    return matrix


def audit(path):
    doc=ET.parse(path).getroot();unit=float(doc.find('c:asset/c:unit',NS).get('meter'))
    up=doc.findtext('c:asset/c:up_axis',namespaces=NS)
    geometry={};geometry_warnings={}
    for g in doc.findall('c:library_geometries/c:geometry',NS):
        mesh=g.find('c:mesh',NS)
        if mesh is None:continue
        src=mesh.find('c:vertices/c:input[@semantic="POSITION"]',NS).get('source')[1:]
        source=mesh.find('c:source[@id="'+src+'"]',NS)
        accessor=source.find('c:technique_common/c:accessor',NS)
        values=np.fromstring(source.findtext('c:float_array',namespaces=NS),sep=' ')
        stride=int(accessor.get('stride','3'));offset=int(accessor.get('offset','0'));n=int(accessor.get('count'))
        pos=values[offset:offset+n*stride].reshape(n,stride)[:,:3]
        geometry[g.get('id')]=pos
        flags=[]
        for primitive in list(mesh):
            normal=primitive.find('c:input[@semantic="NORMAL"]',NS)
            if normal is None:continue
            sid=normal.get('source')[1:]
            src=mesh.find('c:source[@id="'+sid+'"]',NS)
            normals=np.fromstring(src.findtext('c:float_array',namespaces=NS),sep=' ').reshape(-1,3)
            if not np.isfinite(normals).all():flags.append('nonfinite normals')
            elif np.any(np.linalg.norm(normals,axis=1)<1e-9):flags.append('zero-length normals')
        geometry_warnings[g.get('id')]=sorted(set(flags))
    records=[];names=Counter()
    def walk(node,parent,parent_name=None,ancestors=()):
        name=node.get('name') or node.get('id');names[name]+=1
        local=local_matrix(node);world=parent@local
        lf,ls,ld=classify(local);wf,ws,wd=classify(world)
        instances=node.findall('c:instance_geometry',NS)
        positions=[]
        for inst in instances:
            p=geometry.get(inst.get('url')[1:])
            if p is not None:positions.append(p)
        rec={'name':name,'parent':parent_name,'local_flags':lf,'effective_flags':wf,
             'local_scales':ls,'effective_scales':ws,'local_determinant':ld,'geometry_count':len(instances),
             'malformed_ancestors':list(ancestors),'warnings':[]}
        for inst in instances:rec['warnings'].extend(geometry_warnings.get(inst.get('url')[1:],[]))
        if ls and max(ls)<.01:rec['warnings'].append('tiny local scale (<0.01)')
        if ws and max(ws)*unit<1e-5:rec['warnings'].append('tiny inherited unit-adjusted scale (<1e-5)')
        if positions:
            p=np.concatenate(positions);worldpos=(p@world[:3,:3].T+world[:3,3])*unit
            if not np.isfinite(p).all():rec['warnings'].append('nonfinite vertex positions')
            if np.isfinite(worldpos).all():
                lo=worldpos.min(0);hi=worldpos.max(0);dim=hi-lo
                rec['world_bounds']=[lo.tolist(),hi.tolist()];rec['world_dimensions']=dim.tolist()
                rec['raw_dimensions']=np.ptp(p,axis=0).tolist()
                rec['world_max_dimension']=float(max(dim))
                if max(dim)<.1:rec['warnings'].append('tiny geometry (<0.1 world units across)')
                if max(dim)<1e-6:rec['warnings'].append('collapsed geometry')
                rec['distance_from_origin']=float(np.linalg.norm((lo+hi)/2))
        records.append(rec)
        for child in node.findall('c:node',NS):walk(child,world,name,ancestors+((name,) if lf else ()))
    for node in doc.findall('c:library_visual_scenes/c:visual_scene/c:node',NS):walk(node,np.eye(4))
    malformed=[r for r in records if r['local_flags'] or r['effective_flags']]
    warnings=[r for r in records if r['warnings']]
    folded=Counter(n.lower() for n in names)
    return {'file':str(path.relative_to(ROOT)),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
        'unit_meter':unit,'up_axis':up,'nodes':len(records),'geometry_nodes':sum(r['geometry_count']>0 for r in records),
        'local_malformed':sum(bool(r['local_flags']) for r in records),'effective_malformed':sum(bool(r['effective_flags']) for r in records),
        'duplicate_names':[n for n,c in names.items() if c>1],'malformed':malformed,'visibility_warnings':warnings,
        'case_insensitive_name_collisions':[n for n in names if folded[n.lower()]>1],
        'smallest_geometry':sorted((r for r in records if 'world_max_dimension'in r),key=lambda r:r['world_max_dimension'])[:15],
        'largest_geometry':sorted((r for r in records if 'world_max_dimension'in r),key=lambda r:r['world_max_dimension'],reverse=True)[:10],
        'scale_distribution':dict(Counter(tuple(round(s,6) for s in r['local_scales']) for r in records if r['local_scales']))}


def main():
    p=argparse.ArgumentParser();p.add_argument('files',nargs='*')
    p.add_argument('--output',type=Path,default=ROOT/'docs/reports/house-transform-audit.json')
    args=p.parse_args()
    files=[ROOT/x for x in args.files] if args.files else [ROOT/'objects3d/house_asian.dae',ROOT/'objects3d/house_western.dae',ROOT/'objects3d/house_asian_standalone.dae']+sorted((ROOT/'objects3d').glob('house_asian_split_*.dae'))
    results=[]
    for path in files:
        r=audit(path);r['scale_distribution']={str(k):v for k,v in r['scale_distribution'].items()};results.append(r)
        print(path.name,'nodes',r['nodes'],'local malformed',r['local_malformed'],'effective malformed',r['effective_malformed'],'visibility warnings',len(r['visibility_warnings']),flush=True)
        for item in r['malformed'][:8]:print(' ',item['name'],item['local_flags'],item['effective_flags'],flush=True)
    out=args.output
    out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(results,indent=2)+'\n')
    print(out)

if __name__=='__main__':main()
