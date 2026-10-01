#!/usr/bin/env python3
"""Render the exported COLLADA files, not the generator's in-memory geometry.

Optional tooling dependencies: numpy pillow pycollada moderngl glcontext.
Uses headless EGL; output is an asset preview, not a Recoil screenshot.
"""
import argparse
import json
from pathlib import Path
import collada
import moderngl
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[2]


def normalize(v): return v/np.linalg.norm(v)


def look_at(eye,target):
    f=normalize(np.array(target,dtype=float)-eye);s=normalize(np.cross(f,[0,1,0]));u=np.cross(s,f)
    v=np.eye(4);v[0,:3]=s;v[1,:3]=u;v[2,:3]=-f
    v[:3,3]=-v[:3,:3]@eye
    return v


def ortho(left,right,bottom,top,near,far):
    p=np.eye(4);p[0,0]=2/(right-left);p[1,1]=2/(top-bottom);p[2,2]=-2/(far-near)
    p[0,3]=-(right+left)/(right-left);p[1,3]=-(top+bottom)/(top-bottom);p[2,3]=-(far+near)/(far-near)
    return p


VERT='''#version 330
in vec3 pos; in vec3 normal; in vec2 uv;
uniform mat4 mvp,light_mvp;
out vec3 n; out vec2 tex; out vec4 shadow; out vec3 world;
void main(){n=normal;tex=uv;world=pos;shadow=light_mvp*vec4(pos,1);gl_Position=mvp*vec4(pos,1);}
'''
FRAG='''#version 330
in vec3 n;in vec2 tex;in vec4 shadow;in vec3 world;
uniform sampler2D atlas;uniform sampler2DShadow depth;
uniform bool ground;out vec4 color;
void main(){
 vec3 N=normalize(n);vec3 L=normalize(vec3(-.55,1.,.7));
 vec3 q=shadow.xyz/shadow.w*.5+.5;float vis=0.;
 float bias=max(.00035,.001*(1.-dot(N,L)));
 for(int x=-1;x<=1;x++)for(int y=-1;y<=1;y++)vis+=texture(depth,vec3(q.xy+vec2(x,y)/2048.,q.z-bias))/9.;
 vec3 base=ground?vec3(.68,.69,.69):pow(texture(atlas,tex).rgb,vec3(2.2));
 float sky=.34+.12*max(0.,N.y);float sun=max(0.,dot(N,L))*.85*vis;
 vec3 lit=base*(sky+sun);
 color=vec4(pow(lit,vec3(1./2.2)),1.);
}
'''


def load_geometry(path):
    doc=collada.Collada(str(path));chunks=[]
    for node in doc.scene.objects('geometry'):
        for primitive in node.primitives():
            if not isinstance(primitive,collada.triangleset.BoundTriangleSet): raise ValueError('not triangles')
            chunks.append(np.column_stack((primitive.vertex[primitive.vertex_index].reshape(-1,3),primitive.normal[primitive.normal_index].reshape(-1,3),primitive.texcoordset[0][primitive.texcoord_indexset[0]].reshape(-1,2))))
    return np.concatenate(chunks).astype('f4')


def render_all(atlas_path,out,size=960,update_repo=False):
    out.mkdir(parents=True,exist_ok=True)
    ctx=moderngl.create_standalone_context(backend='egl')
    prog=ctx.program(vertex_shader=VERT,fragment_shader=FRAG)
    dep=ctx.program(vertex_shader='''#version 330
in vec3 pos;uniform mat4 mvp;void main(){gl_Position=mvp*vec4(pos,1);}''',fragment_shader='''#version 330
void main(){}''')
    tex_im=Image.open(atlas_path).convert('RGB').transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    atlas=ctx.texture(tex_im.size,3,tex_im.tobytes());atlas.build_mipmaps();atlas.use(0)
    prog['atlas']=0;prog['depth']=1
    depth=ctx.depth_texture((2048,2048));depth.compare_func='<=';depth.repeat_x=False;depth.repeat_y=False
    shadow=ctx.framebuffer(depth_attachment=depth)
    frame=ctx.simple_framebuffer((size,size),components=3)
    ground=np.array([[-300,-.15,-300,0,1,0,0,0],[-300,-.15,300,0,1,0,0,0],[300,-.15,300,0,1,0,0,0],[-300,-.15,-300,0,1,0,0,0],[300,-.15,300,0,1,0,0,0],[300,-.15,-300,0,1,0,0,0]],dtype='f4')
    gb=ctx.buffer(ground.tobytes());gv=ctx.vertex_array(prog,[(gb,'3f 3f 2f','pos','normal','uv')])
    light=ortho(-110,110,-110,110,1,700)@look_at(np.array([-180.,320.,230.]),[0,20,0])
    prog['light_mvp'].write(light.T.astype('f4').tobytes())
    manifest=json.loads((ROOT/'tools/civic_objectives/manifest.json').read_text())
    ctx.enable(moderngl.DEPTH_TEST|moderngl.CULL_FACE)
    for record in manifest:
        data=load_geometry(ROOT/'objects3d'/(record['name']+'.dae'))
        buf=ctx.buffer(data.tobytes());vao=ctx.vertex_array(prog,[(buf,'3f 3f 2f','pos','normal','uv')]);dv=ctx.vertex_array(dep,[(buf,'3f 20x','pos')])
        camera=look_at(np.array([180.,165.,220.]),[0,record['height']*.38,0])
        coords=(camera@np.column_stack((data[:,:3],np.ones(len(data)))).T).T
        extent=max(np.ptp(coords[:,0]),np.ptp(coords[:,1]))*.57
        cx=(coords[:,0].min()+coords[:,0].max())/2;cy=(coords[:,1].min()+coords[:,1].max())/2
        mvp=ortho(cx-extent,cx+extent,cy-extent,cy+extent,1,800)@camera
        shadow.use();shadow.clear(depth=1);dep['mvp'].write(light.T.astype('f4').tobytes());dv.render()
        frame.use();frame.clear(.83,.84,.84,1,depth=1);depth.use(1)
        prog['mvp'].write(mvp.T.astype('f4').tobytes());prog['ground']=True;gv.render()
        prog['ground']=False;vao.render()
        im=Image.frombytes('RGB',(size,size),frame.read(alignment=1)).transpose(Image.Transpose.FLIP_TOP_BOTTOM)
        im.save(out/(record['name']+'.png'))
        if update_repo:
            (ROOT/'unitpics').mkdir(exist_ok=True)
            im.resize((256,256),Image.Resampling.LANCZOS).save(ROOT/'unitpics'/(record['name']+'.png'))
        vao.release();dv.release();buf.release()
    # A compact contact sheet and game build pictures from the very same render.
    fontpath='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
    font=ImageFont.truetype(fontpath,23);small=ImageFont.truetype(fontpath,17)
    sheet=Image.new('RGB',(2400,1350),'#e2e5e5');d=ImageDraw.Draw(sheet)
    d.text((28,15),'MOSAIC / CIVIC OBJECTIVES — ACTUAL EXPORTED MESHES + ASIAN ATLAS',font=font,fill='#172328')
    for i,r in enumerate(manifest):
        x=(i%4)*600;y=60+(i//4)*640
        im=Image.open(out/(r['name']+'.png'));im.thumbnail((590,560));sheet.paste(im,(x+(600-im.width)//2,y))
        d.text((x+18,y+565),r['title'],font=font,fill='#172328')
        d.text((x+18,y+598),f"{r['triangles']:,} triangles | {r['height']} units high",font=small,fill='#43535b')
    sheet.save(out/'civic-objectives-preview.jpg',quality=92)
    if update_repo:
        (ROOT/'docs/images').mkdir(parents=True,exist_ok=True)
        sheet.save(ROOT/'docs/images/civic-objectives-preview.jpg',quality=92)
    print(f'Rendered {len(manifest)} exported assets with {ctx.info["GL_RENDERER"]}: {out}')


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--atlas',type=Path,required=True);parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--update-repo-previews',action='store_true',help='also replace the eight build pictures and documentation contact sheet')
    a=parser.parse_args();render_all(a.atlas,a.output,update_repo=a.update_repo_previews)
