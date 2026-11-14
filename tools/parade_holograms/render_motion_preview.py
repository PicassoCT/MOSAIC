#!/usr/bin/env python3
"""Animated proof from runtime meshes, exported hinges and actual Lua poses."""
import json, subprocess
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
from render_preview import ROOT, Piece, load_export, render_piece, combine_pieces, font, BG, INK, MUTED


def rotate(piece, degrees, axis, pivot=(0,0,0)):
    axis=np.asarray(axis,dtype=float);axis/=np.linalg.norm(axis)
    a=np.deg2rad(degrees);x,y,z=axis
    k=np.array([[0,-z,y],[z,0,-x],[-y,x,0]])
    m=np.eye(3)*np.cos(a)+(1-np.cos(a))*np.outer(axis,axis)+np.sin(a)*k
    return Piece(piece.name,(piece.positions-pivot)@m.T+pivot,piece.normals@m.T,piece.uvs,piece.geometry_ids)


def main():
    _,_,pieces=load_export(ROOT/'objects3d/paradeHologramSceneryRuntime.dae')
    catalog=json.loads((ROOT/'tools/parade_holograms/import_manifest.json').read_text())['catalog']
    lua='''local s=dofile('luarules/gadgets/include/parade_hologram_scene.lua')
local c=dofile('luarules/configs/parade_hologram_scene.lua')
local bird,petal
for _,i in ipairs(c.props) do if i.motion=='origami' then bird=i elseif i.motion=='petal' then petal=i end end
local st={born=0,x=0,z=0,dx=0,dz=1}
for i=0,81 do
 local t=i*.2;local b=s.pose(bird,t,0);local p=s.worldPose(st,petal,t,0,0,c)
 print(t,b.wingFlap,b.y-bird.y,b.x-bird.x,b.z-bird.z,p.x-petal.x,p.y,p.z-petal.z,p.tilt,p.roll,p.yaw,p.opacity)
end'''
    rows=np.loadtxt(subprocess.check_output(['lua','-'],input=lua,text=True,cwd=ROOT).splitlines())
    animations=[[],[],[],[]]
    for row in rows:
        _,flap,by,bx,bz,px,py,pz,tilt,roll,yaw,opacity=row
        for i,bird in enumerate(catalog['props']['moth']['variants']):
            members=[pieces[bird['piece']]]
            for wing in bird['wings']:
                members.append(rotate(pieces[wing['piece']],flap*wing['sign'],wing['axis'],np.array(wing['pivot'])))
            combined=Piece('bird',*(np.concatenate([getattr(p,a) for p in members]) for a in ('positions','normals','uvs')),())
            combined.positions+=np.array([bx,by,bz])
            animations[i].append(combined)
        petal=pieces['paradelotus1']
        petal=rotate(petal,roll,[0,0,1]);petal=rotate(petal,tilt,[1,0,0]);petal=rotate(petal,yaw,[0,1,0])
        petal.positions+=np.array([px,py,pz]);animations[3].append(petal)
    cameras=[(.8,.7,1.3)]*3+[(.2,.1,1.5)]
    bounds=[]
    for meshes,cam in zip(animations,cameras):
        camera=np.array(cam);camera/=np.linalg.norm(camera);right=np.cross([0,1,0],camera);right/=np.linalg.norm(right);up=np.cross(camera,right)
        pos=np.concatenate([p.positions for p in meshes]);projection=np.stack((pos@right,pos@up),axis=-1)
        bounds.append((projection.min((0,1)),projection.max((0,1))))
    output=ROOT/'docs/images/parade-holograms';output.mkdir(parents=True,exist_ok=True)
    frames=[]
    for frame,row in enumerate(rows):
        image=Image.new('RGB',(1280,460),BG);draw=ImageDraw.Draw(image)
        draw.text((20,10),'MOSAIC / EXPORTED BIRD AND PETAL MOTION',font=font(24,True),fill=INK)
        for col in range(4):
            preview=render_piece(animations[col][frame],{},(300,340),camera=cameras[col],frame_bounds=bounds[col])
            if col==3:preview.putalpha(preview.getchannel('A').point(lambda a:int(a*row[-1])))
            image.paste(preview,(col*320+10,70),preview)
            draw.text((col*320+16,48),'Origami bird '+str(col+1) if col<3 else 'Cherry blossom petal',font=font(18,True),fill=INK)
        draw.text((20,428),f'{row[0]:.1f}s | Actual Lua poses and DAE geometry; mesh proof, not an in-game capture.',font=font(16),fill=MUTED)
        frames.append(image)
    frames[0].save(output/'motion.webp',save_all=True,append_images=frames[1:],duration=200,loop=0,lossless=True)
    frames[4].save(output/'motion-sample.png')
    print(output/'motion.webp')

if __name__=='__main__':main()
