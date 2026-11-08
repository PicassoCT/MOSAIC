#!/usr/bin/env python3
"""Generate the single-piece saint, its UVs and editable spline source."""
from pathlib import Path
import sys,json,hashlib
import numpy as np
from PIL import Image
from lxml import etree as ET
import saint
ROOT=saint.ROOT
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'tools/parade_holograms'))
# Load the existing COLLADA writer under an unambiguous name.
import importlib.util
spec=importlib.util.spec_from_file_location('parade_writer',ROOT/'tools/parade_holograms/build.py')
writer=importlib.util.module_from_spec(spec);spec.loader.exec_module(writer)
from geometry import evaluate,triangulate
from cage_surface import ROTATION

# Pixel rectangles refer to the unmodified 4096-square Asian-house atlas.
RECTS={
 'cloak':(1129,417,1160,466),
 'rim':(1075,417,1105,459),
 'robe':(976,105,999,139),
 'skin':(1008,80,1011,130),
 'swaddle':(970,91,997,134),
 'eye':(1134,182,1164,249),
 'hair':(1188,344,1212,447),
 'shadow':(1190,398,1212,452),
 'lip':(1189,225,1215,293),
}

def palette():
    return {k:{'uv_rect':[a/4096,1-d/4096,c/4096,1-b/4096]} for k,(a,b,c,d) in RECTS.items()}


def generate():
    model=saint.build(); pal=palette(); records=[];ranges=[]
    light=np.array([-.55,.55,1.0]);light/=np.linalg.norm(light)
    for part in model['parts']:
        vertices,faces=evaluate(part)
        vertices=np.asarray(vertices)@ROTATION.T
        triangles=triangulate(faces)
        lower=vertices.min(0);span=np.maximum(np.ptp(vertices,axis=0),1e-6)
        start=len(records)//3
        u0,v0,u1,v1=pal[part['material']]['uv_rect']
        for triangle in triangles:
            xyz=vertices[triangle]
            normal=np.cross(xyz[1]-xyz[0],xyz[2]-xyz[0]);length=np.linalg.norm(normal)
            if length<1e-10:raise ValueError('Degenerate cage triangle: '+part['name'])
            normal/=length
            # Grey-blue and ivory gradients run vertically in this atlas.
            # Face orientation supplies sculptural shade even under self-illumination.
            vertical=(xyz[:,1]-lower[1])/span[1]
            brightness=(np.dot(normal,light)+1)/2
            t=np.clip(.02+.80*brightness+.12*vertical,.04,.94)
            u=u0+(u1-u0)*(.15+.70*(xyz[:,0]-lower[0])/span[0])
            v=v0+(v1-v0)*t
            for p,uv in zip(xyz,np.stack((u,v),axis=1)):
                records.append(tuple(p)+tuple(normal)+tuple(uv))
        ranges.append({'name':part['name'],'material':part['material'],'first_triangle':start,'triangles':len(records)//3-start})
    data={'records':records,'indices':list(range(len(records)))}
    doc=writer.make_document([],{'paradesaintmother':data})
    scene=doc.find('c:library_visual_scenes/c:visual_scene',{'c':writer.NS})
    scene.remove(scene[0]);writer.node(scene,'paradesaintmother',writer.PREFIX+'paradesaintmother_mesh')
    doc.find('c:asset/c:contributor/c:authoring_tool',{'c':writer.NS}).text='MOSAIC single-piece saint from connected spline cages'
    ET.indent(doc,space='  ')
    target=ROOT/'objects3d/paradeSaintMother.dae'
    target.write_bytes(ET.tostring(doc,encoding='utf-8',xml_declaration=True))
    (HERE/'source.json').write_text(json.dumps(model,indent=2)+'\n')
    (HERE/'palette.json').write_text(json.dumps(pal,indent=2)+'\n')
    xyz=np.asarray(records)[:,:3]
    manifest={'name':model['title'],'source':model['reference'],'mesh_objects':1,'materials':1,
       'triangles':len(records)//3,'bounds':[xyz.min(0).tolist(),xyz.max(0).tolist()],
       'cages':len(model['parts']),'parts':ranges,'atlas_rectangles_pixels':RECTS,
       'source_sha256':hashlib.sha256((HERE/'source.json').read_bytes()).hexdigest()}
    ms_spec=importlib.util.spec_from_file_location('saint_maxscript',HERE/'maxscript.py')
    ms=importlib.util.module_from_spec(ms_spec);ms_spec.loader.exec_module(ms)
    manifest['maxscript']=ms.write(model,data,HERE/'Build_Saint.ms')
    (HERE/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    height=float(xyz[:,1].max());mid=(xyz.min(0)+xyz.max(0))/2
    radius=float(np.linalg.norm(xyz-mid,axis=1).max())+.5
    target.with_suffix('.dae.lua').write_text('return {\n  radius = %.6f,\n  height = %.6f,\n  midpos = {%.6f, %.6f, %.6f},\n  tex1 = "house_asian_diffuse.dds",\n  tex2 = "house_asian_selfilu_reflection.png",\n}\n'%(radius,height+.5,*mid))
    print(json.dumps({k:manifest[k] for k in ['mesh_objects','materials','triangles','cages','bounds']}))
    return model,data,manifest

if __name__=='__main__':generate()
