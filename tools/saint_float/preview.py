#!/usr/bin/env python3
"""Read the actual exported saint mesh and atlas to render review images."""
from pathlib import Path
import sys,json,math
from PIL import Image,ImageDraw
import numpy as np
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/parade_holograms'))
from render_preview import load_export,render_piece,font,Piece
OUT=ROOT/'docs/images/saint-float'

def main():
    _,_,pieces=load_export(ROOT/'objects3d/paradeSaintMother.dae')
    piece=pieces['paradesaintmother'];palette=json.loads((ROOT/'tools/saint_float/palette.json').read_text())
    proof=Image.new('RGB',(1660,1080),(15,22,29));d=ImageDraw.Draw(proof)
    d.text((32,20),'MOSAIC / MOTHER AND CHILD',font=font(30,True),fill=(236,231,215))
    d.text((32,66),f'Actual spline-cage mesh  |  One object, one atlas material  |  {len(piece.positions):,} triangles',font=font(19),fill=(152,171,181))
    for label,camera,x,w in [('FRONT',(0,.06,1),18,560),('THREE-QUARTER',(.72,.17,1.3),580,560),('BACK',(-.4,.12,-1),1150,490)]:
        tile=render_piece(piece,palette,(w,870),camera=camera,padding=25)
        proof.paste(tile,(x,125),tile)
        d.text((x+w//2,1010),label,font=font(16,True),fill=(183,199,204),anchor='mt')
    proof.save(OUT/'preview.png')
    # Tight facial detail is rendered from the same vertices and UVs.
    upper=piece.positions[:,:,1].min(1)>7.0
    close=Piece('detail',piece.positions[upper],piece.normals[upper],piece.uvs[upper],())
    face=render_piece(close,palette,(950,950),camera=(.12,.04,1),padding=35)
    bg=Image.new('RGB',face.size,(15,22,29));bg.paste(face,(0,0),face);bg.save(OUT/'detail.png')
    if '--turntable' in sys.argv:
        frames=[]
        # Fixed projection bounds prevent the model growing/shrinking on orbit.
        points=piece.positions.reshape(-1,3)
        radius=np.linalg.norm(points[:,[0,2]],axis=1).max()
        for i in range(40):
            angle=i*math.tau/40
            view=render_piece(piece,palette,(800,960),camera=(math.sin(angle),.08,math.cos(angle)),
                padding=30,frame_bounds=(np.array([-radius,-.3]),np.array([radius,12.1])))
            frame=Image.new('RGB',view.size,(15,22,29));frame.paste(view,(0,0),view)
            ImageDraw.Draw(frame).text((20,20),'MOSAIC / MOTHER AND CHILD',font=font(21,True),fill=(236,231,215))
            frames.append(frame)
        frames[0].save(OUT/'turntable.webp',save_all=True,append_images=frames[1:],duration=180,loop=0,lossless=True)
    print(OUT/'preview.png')

if __name__=='__main__':main()
