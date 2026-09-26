"""Bake once, ship the PNG; no Python or graph traversal runs in the game.

Run python tools/rain/bake_runoff.py (numpy, scipy, Pillow).
RG: sqrt(bank/spill height / 2). BA: unit complex travelling-wave phase.
Two columns and two rows repeat on a torus; border ports and phases agree.
"""
from pathlib import Path
import heapq
import numpy as np
from scipy.ndimage import map_coordinates
from scipy.spatial import cKDTree
from PIL import Image
from runoff_graph import Graph

ROOT = Path(__file__).resolve().parents[2]
SIZE = 1024


def bake(size=SIZE):
    points, widths, phases = [], [], []
    graphs = [Graph(seed, rows=2, periodic=True) for seed in (17, 43)]
    for column, graph in enumerate(graphs):
        graph.validate()
        first = [(graph.nodes[n].xy[0], q) for n, q in graph.ports[0]]
        last = [(graph.nodes[n].xy[0], q) for n, q in graph.ports[2]]
        assert first == last, 'Repeat must preserve boundary ports and flux'
        for edge in graph.edges:
            # Node phases depend on height, so all incoming/outgoing branches
            # meet continuously. Inside each edge, arclength/velocity controls
            # the wave spacing. Longer branches have different crest speeds.
            fraction = edge.seconds / edge.seconds[-1]
            phase = edge.xy[0, 1] + np.ptp(edge.xy[:, 1]) * fraction
            for j, (a, b) in enumerate(zip(edge.xy[:-1], edge.xy[1:])):
                count = max(2, int(np.linalg.norm(b-a)*size*2))
                u = np.arange(count)/count
                points.extend(a+u[:, None]*(b-a)+[column, 0])
                widths.extend(edge.width[j]*(1-u)+edge.width[j+1]*u)
                phases.extend(phase[j]*(1-u)+phase[j+1]*u)
    points = np.asarray(points) % 2
    widths, phases = np.asarray(widths), np.asarray(phases)
    yy, xx = np.mgrid[0:size, 0:size]
    positions = np.stack([(xx+.5)*2/size, (yy+.5)*2/size], axis=-1)
    distance, index = cKDTree(points, boxsize=2).query(positions, workers=2)
    rng = np.random.default_rng(4017)

    def noise(n):
        return map_coordinates(rng.random((n, n)),
            [(yy+.5)*n/size, (xx+.5)*n/size], order=3, mode='grid-wrap')

    low, mid, fine = noise(10), noise(32), noise(128)
    bank = (distance/(widths[index]*5.5+.025))**.82
    bank = np.maximum(0, bank*(.68+.65*low+.32*mid)+.12*(mid-.5)+.07*(fine-.5))
    # A low patch cannot wet until water overtops every intervening bank.
    spill = np.full((size, size), np.inf)
    heap = []
    for y, x in zip(*np.where(distance < widths[index]*.3)):
        spill[y, x] = bank[y, x]
        heap.append((float(bank[y, x]), int(y), int(x)))
    heapq.heapify(heap)
    while heap:
        z, y, x = heapq.heappop(heap)
        if z > spill[y, x]:
            continue
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            ny, nx = (y+dy) % size, (x+dx) % size
            height = max(z, bank[ny, nx])
            if height < spill[ny, nx]:
                spill[ny, nx] = height
                heapq.heappush(heap, (height, ny, nx))
    scale = np.quantile(spill, .76)
    bank, spill = bank/scale, spill/scale
    phase = phases[index]*np.pi*16  # Eight whole crests per tile, seamless wrap.
    data = np.stack([np.sqrt(np.clip(bank/2, 0, 1)),
                     np.sqrt(np.clip(spill/2, 0, 1)),
                     .5+.5*np.cos(phase), .5+.5*np.sin(phase)], axis=-1)
    pixels = np.rint(data*255).astype('uint8')
    decoded = (pixels[:, :, 1]/255.)**2*2
    previous = np.zeros((size, size), bool)
    coverage = []
    for rain in np.arange(1, 11)/10:
        wet = decoded < .010+.990*rain**1.85
        assert np.all(wet[previous]), 'Rising water dried a wet pixel'
        previous = wet
        coverage.append(round(float(wet.mean()*100), 1))
    print('10–100% settled wet coverage:', coverage)
    return pixels


if __name__ == '__main__':
    path = ROOT/'luaui/images/rain/terrain-runoff.png'
    path.parent.mkdir(parents=True, exist_ok=True)
    # Spring's named texture loader uploads PNG rows in file order (upper-left).
    # Keep graph row zero in file row zero, which is sampled at texture v=0.
    Image.fromarray(bake()).save(path, optimize=True)
    print(path)
