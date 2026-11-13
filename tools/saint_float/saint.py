"""One-mesh mother-and-child saint, authored as connected spline cages.
Authoring coordinates: X right, Y depth, Z up; front is -Y.
"""
import math
from pathlib import Path
import sys
import numpy as np
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools/truck_parade_payloads/source'))
from authoring import Recipe, curve, rotation_matrix, points_list


def sheet(r, name, grid, material, thickness=.06):
    """Closed thin cage: paired row/rail lattices and connected boundary rails."""
    grid = np.asarray(grid, float)
    h,w,_ = grid.shape
    # Displace depth rather than node scale: all exported transforms stay identity.
    back = grid + [0, thickness, 0]
    vertices = np.concatenate((grid.reshape(-1,3), back.reshape(-1,3)))
    count = h*w
    faces=[]
    for i in range(h-1):
        for j in range(w-1):
            a=i*w+j;b=a+1;c=a+w+1;d=a+w
            faces += [[a,b,c,d],[d+count,c+count,b+count,a+count]]
    boundary=list(range(w))+[i*w+w-1 for i in range(1,h)]+list(range(h*w-2,(h-1)*w-1,-1))+[i*w for i in range(h-2,0,-1)]
    for a,b in zip(boundary,boundary[1:]+boundary[:1]):faces.append([b,a,a+count,b+count])
    curves=[]
    for layer in (grid,back):
        curves.extend(curve(row,False,False) for row in layer)
        curves.extend(curve(layer[:,j],False,False) for j in range(w))
    curves.extend(curve([vertices[a],vertices[a+count]],False,False) for a in boundary)
    # Consistent positive orientation independently of how the panel was drawn.
    vol=sum(np.dot(vertices[f[0]],np.cross(vertices[f[j]],vertices[f[j+1]])) for f in faces for j in range(1,len(f)-1))
    if vol<0:faces=[list(reversed(f)) for f in faces]
    return r._cage(name,material,None,vertices,faces,curves)


def vertical(r,name,sections,material,sides=12,fold=.0):
    rings=[]; centers=[]
    for x,y,z,rx,ry in sections:
        centers.append((x,y,z))
        rings.append([(x+rx*math.cos(t)*(1+fold*math.cos(t*6)),
                       y+ry*math.sin(t)*(1+fold*math.cos(t*6)),z)
                      for t in np.arange(sides)*math.tau/sides])
    return r._section_cage(name,rings,centers,material,smooth=False)


def hood(r):
    # Closed cloth shell around a genuine face opening. The outer silhouette
    # peaks off-centre and widens below the jaw like folded fabric, not a helmet.
    profiles=[(-.51,.73,1.04),(-.35,.94,1.22),(.33,.90,1.18),(.68,.025,.025),
              (.59,.025,.025),(.24,.82,1.08)]
    n=20;rings=[]
    for y,rx,rz in profiles:
        row=[]
        for t in np.arange(n)*math.tau/n:
            x=rx*math.sin(t);z=rz*math.cos(t)+.08
            if rx>.1:
                x-=.12*max(0,math.cos(t))
                if z<-.35:x*=1.18;z-=.13*abs(math.sin(t))
                z+=.10*max(0,-math.sin(t))*max(0,math.cos(t))
            row.append((x,y,z))
        rings.append(row)
    vertices=np.asarray(rings).reshape(-1,3);faces=[]
    for i in range(len(rings)):
        k=(i+1)%len(rings)
        for j in range(n):faces.append([i*n+j,i*n+(j+1)%n,k*n+(j+1)%n,k*n+j])
    vol=sum(np.dot(vertices[f[0]],np.cross(vertices[f[j]],vertices[f[j+1]])) for f in faces for j in range(1,len(f)-1))
    if vol<0:faces=[list(reversed(f)) for f in faces]
    curves=[curve(row,True,False) for row in rings]
    curves += [curve([row[j] for row in rings],True,False) for j in range(n)]
    return r._cage('Hood', 'cloak',None,vertices,faces,curves)


def transform(parts,pivot,angles,offset):
    rot=rotation_matrix(angles);pivot=np.asarray(pivot);offset=np.asarray(offset)
    def apply(points):return points_list((np.asarray(points)-pivot)@rot.T+offset)
    for p in parts:
        p['vertices']=apply(p['vertices'])
        for c in p['curves']:c['points']=apply(c['points'])


def face(r,prefix,scale=1,baby=False):
    start=len(r.parts)
    rows=([(-.86,.12,.14),(-.74,.25,.25),(-.54,.37,.32),(-.34,.43,.37),(-.16,.47,.40),
           (.02,.51,.43),(.20,.51,.43),(.36,.50,.42),(.56,.47,.40),(.76,.36,.32),(.90,.16,.16)]
          if not baby else [(-.58,.13,.13),(-.46,.32,.27),(-.20,.45,.37),(.12,.48,.40),(.40,.39,.33),(.55,.18,.18)])
    rings=[]
    for z,rx,ry in rows:
        ring=[]
        for a in np.arange(20)*math.tau/20:
            x,y=rx*math.cos(a),ry*math.sin(a)
            if y<0 and not baby:
                # Connected cheekbones, eye sockets, nasal bridge and chin.
                front=max(0,-math.sin(a))**4
                y+=front*(.045*math.exp(-((abs(x)-.21)/.13)**2-((z-.22)/.19)**2)
                          -.065*math.exp(-((abs(x)-.32)/.16)**2-((z+.03)/.22)**2)
                          -.10*math.exp(-(x/.11)**2-((z-.20)/.32)**2))
            ring.append((x,y,z))
        rings.append(ring)
    r._section_cage(prefix+'Face',rings,[(0,0,z) for z,_,_ in rows],'skin',smooth=False)
    # Sculptural nose, eyelids and brows are also cages, joined into the one mesh.
    r.sweep(prefix+'Nose',[(0,-.43,.25),(0,-(.64 if not baby else .51),-.04),(0,-.47,-.13)],
            [.058,.081 if not baby else .065,.047],'skin',sides=8)
    for side in (-1,1):
        x=.215*side
        if baby:
            pts=[(x-side*.12,-.365,.015),(x,-.407,-.025),(x+side*.10,-.366,-.015)]
        else:
            pts=[(x-side*.105,-.394,.205),(x,-.428,.21),(x+side*.10,-.37,.17)]
            r.ellipsoid(prefix+('Left' if side<0 else 'Right')+'Eye',
                (x,-.397,.183),(.108,.031,.043),'eye',rings=5,sides=10)
            r.ellipsoid(prefix+('Left' if side<0 else 'Right')+'Iris',
                (x+.021,-.430,.165),(.025,.012,.026),'hair',rings=5,sides=8)
            r.sweep(prefix+('Left' if side<0 else 'Right')+'Brow',
                [(x-side*.12,-.389,.36),(x,-.412,.34),(x+side*.12,-.35,.28)],
                [.013,.022,.011],'hair',sides=6)
        r.sweep(prefix+('Left' if side<0 else 'Right')+'Lid',pts,[.008,.014,.007],'shadow',sides=6)
    r.sweep(prefix+'Mouth',[(-.10,-.358,-.355),(0,-.389,-.33),(.10,-.358,-.355)],
            [.010,.018,.010],'lip',sides=6)
    if not baby:
        r.sweep(prefix+'LowerLip',[(-.07,-.363,-.37),(0,-.398,-.375),(.07,-.363,-.37)],
                [.012,.025,.012],'skin',sides=6)
    if scale!=1:
        for p in r.parts[start:]:
            p['vertices']=points_list(np.asarray(p['vertices'])*scale)
            for c in p['curves']:c['points']=points_list(np.asarray(c['points'])*scale)
    return start


def build():
    r=Recipe(1,'paradesaintmother','Mother and Child — another float saint')
    # Weight-bearing foot and exposed advancing leg establish the human scale.
    r.ellipsoid('BackFoot',(-.85,.20,.19),(.28,.59,.18),'skin',rings=5,sides=10)
    r.sweep('ForwardShin',[(.65,-.68,3.75),(.83,-.87,2.6),(.67,-.84,.35)],[.43,.29,.20],'skin',sides=10)
    r.ellipsoid('ForwardFoot',(.81,-1.14,.23),(.30,.72,.21),'skin',rings=6,sides=10,rotation=(0,0,-12))
    for i in range(4):
        r.sweep('Toe'+str(i),[(.58+i*.135,-1.52,.23),(.60+i*.135,-1.79+i*.025,.18)],[.066,.055],'skin',sides=6)
    vertical(r,'InnerRobe',[(-.4,.25,.50,1.12,.67),(-.45,.18,2.3,1.12,.75),(-.20,.1,4.4,1.04,.72),
                           (-.28,.05,5.8,.92,.61),(-.35,.06,7.0,.85,.58),(-.35,.10,8.45,1.04,.62),
                           (-.25,.11,9.3,.85,.47),(-.05,.05,9.6,.42,.33)],'robe',sides=16,fold=.10)
    # Swept-back mantle: long silhouette, pointed hem and broad planar folds.
    mantle=[]
    specs=[(-1.6,.2,.55,1.2),(-2.4,.5,2.25,1.9),(-2.5,.8,4.4,2.05),(-1.75,.65,6.6,1.75),(-.72,.60,8.65,1.4),(-.03,.51,9.7,.85)]
    for cx,cy,z,width in specs:
        row=[]
        for j,t in enumerate(np.linspace(-1,1,9)):
            x=cx+width*t
            depth=cy+.50*(1-t*t)+(.32 if j%2 else -.29)
            zz=z+(.42*abs(t) if z<5 else -.20*abs(t))
            row.append((x,depth,zz))
        mantle.append(row)
    sheet(r,'WindSweptMantle',mantle,'cloak',.09)
    # Front folds overlap the robe without fragmenting the runtime node.
    sheet(r,'LeftMantleLap',[
        [(-3.8,.0,2.6),(-2.9,-.18,2.5),(-2.1,-.02,2.9)],
        [(-2.7,-.25,4.2),(-1.9,-.60,4.3),(-1.2,-.35,4.7)],
        [(-1.8,-.38,6.1),(-1.1,-.70,6.2),(-.65,-.38,6.4)],
        [(-1.3,-.26,8.6),(-.90,-.58,8.8),(-.4,-.30,9.1)]],'cloak',.09)
    sheet(r,'RightMantleFall',[
        [(1.0,.4,.8),(1.30,.12,1.3),(1.52,.43,1.0)],
        [(.70,.2,3.7),(1.25,-.17,3.9),(1.50,.28,3.6)],
        [(.50,.15,6.1),(1.20,-.18,6.3),(1.57,.31,6.0)],
        [(.68,.13,8.3),(1.45,-.21,8.6),(1.80,.17,8.3)],
        [(.6,.21,9.7),(1.17,-.05,9.8),(1.50,.20,9.3)]],'cloak',.07)
    sheet(r,'RaisedKneeDrape',[
        [(-1.30,-.72,1.3),(-.65,-.86,1.5),(.08,-.73,1.8)],
        [(-.97,-.70,2.8),(-.22,-1.08,3.2),(.82,-.74,3.8)],
        [(-.74,-.58,4.9),(-.05,-.95,5.3),(.90,-.53,4.7)],
        [(-.89,-.55,6.6),(-.25,-.83,6.7),(.50,-.53,6.25)]],'robe',.07)
    # Sleeve bends below the child; the exposed forearm and palm cradle the bundle.
    r.sweep('CradlingSleeve',[(-1.04,-.13,8.95),(-1.40,-.55,7.75),(-.94,-1.08,7.05),(-.16,-1.35,7.30)],
            [.48,.48,.43,.28],'robe',sides=10)
    r.sweep('CradlingForearm',[(-.23,-1.34,7.29),(.56,-1.55,7.31),(1.35,-1.46,7.66)],
            [.23,.21,.18],'skin',sides=8)
    r.sweep('CradlingPalm',[(1.28,-1.45,7.62),(1.53,-1.43,7.95),(1.61,-1.34,8.11)],
            [.18,.19,.11],'skin',sides=8)
    for i in range(4):
        r.sweep('CradlingFinger'+str(i),[(1.51+i*.055,-1.42+i*.06,7.96),
            (1.52+i*.055,-1.37+i*.06,8.20),(1.44+i*.06,-1.30+i*.06,8.33)],
            [.047,.043,.026],'skin',sides=6)
    # Swaddled infant is a diagonal tapered bundle with large readable folds.
    start=len(r.parts)
    vertical(r,'SwaddledChild',[(0,0,-.95,.19,.22),(0,0,-.64,.38,.37),(0,0,-.12,.53,.44),
                              (0,0,.43,.48,.41),(0,0,.62,.34,.29)],'swaddle',sides=12,fold=.045)
    transform(r.parts[start:],(0,0,0),(0,35,-5),(.57,-1.22,8.09))
    for i in range(3):
        z=7.57+i*.26
        sheet(r,'SwaddleFold'+str(i),[
            [(-.08+i*.10,-1.64,z),(.46+i*.10,-1.72,z+.14),(1.04+i*.08,-1.50,z+.36)],
            [(-.11+i*.1,-1.65,z+.12),(.44+i*.1,-1.74,z+.27),(1.02+i*.08,-1.51,z+.48)],
            [(-.10+i*.1,-1.60,z+.19),(.45+i*.1,-1.67,z+.34),(1.01+i*.08,-1.48,z+.55)]],'swaddle',.035)
    child=face(r,'Infant',scale=.85,baby=True)
    transform(r.parts[child:],(0,0,0),(8,-19,-9),(1.0,-1.28,8.89))
    # Far arm rises to the baby's crown, with a flattened protective hand.
    r.sweep('ProtectingSleeve',[(1.02,.02,9.18),(1.65,-.26,8.04),(1.94,-.53,8.18)],
            [.37,.34,.24],'cloak',sides=8)
    r.sweep('ProtectingForearm',[(1.91,-.52,8.15),(1.96,-.88,8.77),(1.72,-1.04,9.12)],
            [.19,.18,.15],'skin',sides=8)
    r.ellipsoid('ProtectingPalm',(1.58,-1.13,9.23),(.30,.15,.21),'skin',rings=5,sides=8,rotation=(0,30,0))
    for i in range(4):
        r.sweep('ProtectingFinger'+str(i),[(1.55,-1.07-i*.08,9.32-i*.045),
            (1.32,-1.12-i*.075,9.40-i*.04),(1.16,-1.19-i*.065,9.32-i*.04)],
            [.055,.049,.035],'skin',sides=6)
    r.sweep('ProtectingThumb',[(1.64,-1.31,9.18),(1.44,-1.46,9.12),(1.32,-1.43,9.03)],
            [.075,.067,.04],'skin',sides=6)
    r.sweep('Neck',[(.08,-.02,9.34),(.34,-.20,10.02)],[.29,.30],'skin',sides=10)
    head=face(r,'Mother')
    # A few broad hair locks, not strands, frame the sombre face.
    for sign in (-1,1):
        r.sweep('Hair'+str(sign).replace('-','M'),[(sign*.20,.0,.87),(sign*.52,-.12,.61),
            (sign*.58,-.17,.04),(sign*.49,-.09,-.65)], [.20,.16,.13,.06],'hair',sides=6)
    # The folded hood has a face aperture and a continuous cloth back.
    angles=np.linspace(-2.48,2.48,13)
    hood(r)
    # Fine light-facing edge follows the opening without adding a separate node.
    r.sweep('HoodRim',[(math.sin(t)*.73-.12*max(0,math.cos(t)),-.525,math.cos(t)*1.04+.08) for t in angles],
            [.024]*len(angles),'rim',sides=6)
    transform(r.parts[head:],(0,0,0),(20,-12,13),(.62,-.39,10.43))
    # A gentle whole-figure contrapposto, evaluated into the cage knots,
    # keeps the head and child forward of the weight-bearing hip.
    def lean(points):
        p=np.asarray(points).copy();p[:,0]+=.45*np.clip((p[:,2]-4)/6,0,1)
        return points_list(p)
    for part in r.parts:
        part['vertices']=lean(part['vertices'])
        for c in part['curves']:c['points']=lean(c['points'])
    result=r.to_dict();result['coordinate_system']='X right, Y depth, Z up; front -Y; feet at Z=0'
    result['reference']='MosaicConcept/another float.png'
    result['description']='Hooded mother carrying a swaddled child, bowed head, protective hand, forward step and wind-swept mantle.'
    return result
