"""Seeded, monotone split/rejoin graph for the terrain rain shader's baked field.

Coordinates: x across the slope, y downhill. One unit is one square tile.
Boundary ports depend on the shared edge ID, never on the adjacent tile's seed.
"""
from dataclasses import dataclass, field
import hashlib
import json
import numpy as np


def hash01(*parts):
    b = ('|'.join(map(str, parts))).encode('ascii')
    return int.from_bytes(hashlib.blake2s(b, digest_size=8).digest(), 'little') / 2**64


def boundary(seed, row):
    # Same total flux at every boundary for this steady, planar strip.
    count = 2 + int(hash01(seed, row, 'count') > .70)
    weights = np.array([.5 + hash01(seed, row, i, 'flux') for i in range(count)])
    weights /= weights.sum()
    return [(float((i+.27+.46*hash01(seed,row,i,'pos'))/count), float(q))
            for i,q in enumerate(weights)]


@dataclass
class Node:
    xy: np.ndarray
    outgoing: list = field(default_factory=list)
    incoming: list = field(default_factory=list)


@dataclass
class Edge:
    start: int
    end: int
    q: float
    xy: np.ndarray
    tag: str
    width: np.ndarray = None
    velocity: np.ndarray = None
    seconds: np.ndarray = None


class Graph:
    def __init__(self, seed, rows=2, periodic=False):
        self.seed, self.rows = seed, rows
        self.nodes, self.edges, self.ports = [], [], {}
        for row in range(rows+1):
            self.ports[row] = [(self.node(x,row),q) for x,q in boundary(seed,row % rows if periodic else row)]
        for row in range(rows):
            self.tile(row)
        self.finish()

    def node(self,x,y):
        self.nodes.append(Node(np.array([x,y],dtype=float)))
        return len(self.nodes)-1

    def curve(self, a, b, tag, bend=0.):
        p,q=self.nodes[a].xy,self.nodes[b].xy
        u=np.linspace(0,1,65)
        smooth=u*u*(3-2*u)
        # Vertical tangents at graph nodes, including shared tile borders.
        x=p[0]+(q[0]-p[0])*smooth
        x+=bend*np.sin(np.pi*u)**2*(.75+.25*np.sin(2*np.pi*u+hash01(self.seed,tag)*6.28))
        return np.column_stack([x,p[1]+(q[1]-p[1])*u])

    def edge(self,a,b,q,tag,xy=None):
        if xy is None: xy=self.curve(a,b,tag)
        k=len(self.edges)
        self.edges.append(Edge(a,b,q,xy,tag))
        self.nodes[a].outgoing.append(k);self.nodes[b].incoming.append(k)

    def recurse(self,a,b,q,span,depth,tag,centre=None):
        p0,p1=self.nodes[a].xy,self.nodes[b].xy
        if centre is None:
            xy=self.curve(a,b,tag,bend=span*(hash01(self.seed,tag,'bend')-.5)*.15)
            centre=lambda y: np.interp(y,xy[:,1],xy[:,0])
        if depth==0 or p1[1]-p0[1]<.07 or q<.07:
            ys=np.linspace(p0[1],p1[1],65)
            self.edge(a,b,q,tag,np.column_stack([centre(ys),ys]));return
        # The split and reunion are intentionally at unequal distances.
        start=.08+.26*hash01(self.seed,tag,'start')
        stop=.70+.22*hash01(self.seed,tag,'end')
        ya=p0[1]+(p1[1]-p0[1])*start
        yb=p0[1]+(p1[1]-p0[1])*stop
        fork=self.node(float(centre(ya)),ya);join=self.node(float(centre(yb)),yb)
        self.recurse(a,fork,q,span,0,tag+'a',centre)
        self.recurse(join,b,q,span,0,tag+'b',centre)
        fraction=.19+.62*hash01(self.seed,tag,'fraction')
        skew=.78+.5*hash01(self.seed,tag,'skew')
        for side,part in [(-1,fraction),(1,1-fraction)]:
            offset=span*(.38+.75*hash01(self.seed,tag,side,'width'))
            aa=1.35+1.4*hash01(self.seed,tag,side,'front')
            bb=1.35+1.4*hash01(self.seed,tag,side,'back')
            peak=(aa/(aa+bb))**aa*(bb/(aa+bb))**bb
            def arm(y,side=side,offset=offset,aa=aa,bb=bb,peak=peak,centre=centre):
                u=np.clip((np.asarray(y)-ya)/(yb-ya),0,1)
                envelope=u**aa*(1-u)**bb/peak
                shape=1+.16*np.sin(2*np.pi*u+skew)
                return centre(y)+side*offset*envelope*shape
            child_depth=depth-1 if hash01(self.seed,tag,side,'subdivide')<.72 else 0
            self.recurse(fork,join,q*part,span*.27,child_depth,tag+str(side),arm)

    def tile(self,row):
        ins,outs=self.ports[row],self.ports[row+1]
        # Tributaries join at distinct places; no compulsory tile-centre hub.
        # The central port continues as a meandering backbone across the tile.
        primary_in=min(range(len(ins)),key=lambda i:abs(self.nodes[ins[i][0]].xy[0]-.5))
        primary_out=min(range(len(outs)),key=lambda i:abs(self.nodes[outs[i][0]].xy[0]-.5))
        first=ins[primary_in][0];last=outs[primary_out][0]
        base=self.curve(first,last,f'backbone{row}',bend=.10*(hash01(self.seed,row,'bend')-.5))
        centre=lambda y: np.interp(y,base[:,1],base[:,0])
        current=first;flow=ins[primary_in][1]
        tributaries=[i for i in range(len(ins)) if i!=primary_in]
        for order,i in enumerate(tributaries):
            y=row+.12+order*.10+.07*hash01(self.seed,row,i,'join')
            join=self.node(float(centre(y)),y)
            self.recurse(current,join,flow,.065,0,f'{row}spine{order}',centre)
            node,q=ins[i]
            lateral=self.nodes[node].xy[0]-float(centre(row))
            def feeder(ys,lateral=lateral,end=y,centre=centre):
                u=np.clip((np.asarray(ys)-row)/(end-row),0,1)
                return centre(ys)+lateral*(1-u*u*(3-2*u))
            self.recurse(node,join,q,.050,1,f'{row}tributary{i}',feeder)
            current=join;flow+=q
        departure=row+.69+.05*hash01(self.seed,row,'departure')
        fork=self.node(float(centre(departure)),departure)
        self.recurse(current,fork,flow,.175,2,f'tile{row}',centre)
        current=fork
        exits=[i for i in range(len(outs)) if i!=primary_out]
        for order,i in enumerate(exits):
            if order:
                y=departure+.12*order
                fork=self.node(float(centre(y)),y)
                self.recurse(current,fork,flow,.05,0,f'{row}tail{order}',centre)
                current=fork
            node,q=outs[i]
            start=self.nodes[current].xy[1]
            lateral=self.nodes[node].xy[0]-float(centre(row+1))
            def outlet(ys,lateral=lateral,start=start,centre=centre):
                u=np.clip((np.asarray(ys)-start)/(row+1-start),0,1)
                return centre(ys)+lateral*u*u*(3-2*u)
            self.recurse(current,node,q,.055,0,f'{row}out{i}',outlet)
            flow-=q
        self.recurse(current,last,flow,.06,0,f'{row}last',centre)

    def finish(self):
        # Width/depth are stylized, not a shallow-water simulation.
        for edge in self.edges:
            u=np.linspace(0,1,len(edge.xy))
            edge.width=.014*edge.q**.52*(1+.13*np.sin(np.pi*u)**2*np.sin(8*u+hash01(self.seed,edge.tag)*6.28))
            # Stable narrow-section acceleration, zero modulation at borders.
            v=.13+.12*edge.q**.28
            edge.velocity=v*(1+.22*np.sin(np.pi*u)**2*np.sin(5*u+hash01(self.seed,edge.tag,'v')*6.28))
            length=np.linalg.norm(np.diff(edge.xy,axis=0),axis=1)
            edge.seconds=np.r_[0,np.cumsum(length/(.5*(edge.velocity[:-1]+edge.velocity[1:])))]

    def validate(self):
        for e in self.edges:
            assert e.q>0 and np.all(np.diff(e.xy[:,1])>0), 'Non-downhill edge'
            assert np.all((e.xy[:,0]>0)&(e.xy[:,0]<1)), 'Left tile bounds'
            assert np.allclose(e.xy[0],self.nodes[e.start].xy)
            assert np.allclose(e.xy[-1],self.nodes[e.end].xy)
        for n in self.nodes:
            if n.incoming and n.outgoing:
                qi=sum(self.edges[i].q for i in n.incoming)
                qo=sum(self.edges[i].q for i in n.outgoing)
                assert abs(qi-qo)<1e-12, 'Flux discontinuity'
        for row,ports in self.ports.items():
            for node,q in ports:
                n=self.nodes[node]
                for k in n.incoming:
                    for j in n.outgoing:
                        a,b=self.edges[k],self.edges[j]
                        assert abs(a.width[-1]-b.width[0])<1e-12
                        assert abs(a.velocity[-1]-b.velocity[0])<1e-12
        return {'nodes':len(self.nodes),'edges':len(self.edges),'boundary_flux':1.,
                'downhill':True,'conserved_flux':True,'matching_boundary_width_speed':True}

    def fingerprint(self):
        return hashlib.sha256(b''.join(e.xy.tobytes()+np.float64(e.q).tobytes() for e in self.edges)).hexdigest()


if __name__=='__main__':
    for seed in [17,43,91]:
        graph=Graph(seed)
        assert graph.fingerprint()==Graph(seed).fingerprint()
        print(seed,json.dumps(graph.validate()),graph.fingerprint()[:16])
