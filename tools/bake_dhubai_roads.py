"""Recover Dhubai's authored asphalt centrelines from the compiled SMF minimap.
Usage: python tools/bake_dhubai_roads.py path/to/MOSAIC_LastDayOfDubai_V1.smf
Requires Pillow, numpy, lupa (build time only). No client image analysis.
"""
import hashlib
import struct
import sys
from pathlib import Path
import numpy as np
from PIL import Image
from io import BytesIO
from lupa.lua51 import LuaRuntime

root=Path(__file__).resolve().parents[1]
b=Path(sys.argv[1]).read_bytes()
h=struct.unpack_from('<16s7i2f7i',b)
assert h[0]==b'spring map file\0' and h[3:5]==(1024,1024)
o=h[13]
hdr=b'DDS '+struct.pack('<7I',124,0xA1007,1024,1024,524288,0,9)+bytes(44)+struct.pack('<II4s5I',32,4,b'DXT1',0,0,0,0,0)+struct.pack('<5I',0x401008,0,0,0,0)
im=Image.open(BytesIO(hdr+b[o:o+699048])).convert('RGB')
a=np.asarray(im).astype(int)
# Asphalt is dark neutral grey; turquoise water and vegetation are excluded.
mask=(a.max(2)<105)&((a.max(2)-a.min(2))<24)
# Airport apron/runways are not neighbourhood streets. Keep boundary roads.
mask[595:,830:947]=False
# Preserve thin lanes by max pooling 4x4, then remove isolated speckles through
# centreline tracing/minimum chain length. SMF top row is world z=0 (no flip).
mask=mask.reshape(256,4,256,4).mean((1,3))>=0.25
runtime=LuaRuntime(unpack_returned_tuples=True)
roads=runtime.execute((root/'scripts/lib_city_roads.lua').read_text())
table=runtime.table_from({i+1:True for i,v in enumerate(mask.flat) if v})
network=roads.trace(table,256,256,32,'arabic','Dhubai authored asphalt v1')
lines=['-- Authored asphalt centrelines, SMF SHA-256 '+hashlib.sha256(b).hexdigest(),
       '-- Source: PicassoCT/MOSAIC_LastDayOfDubai master f7938d012affd4cd2fc4c50fe3d92dd5c0af894e',
       '-- Built by tools/bake_dhubai_roads.py; map-specific geometry, no RNG.',
       "return {schema=1,generation='game',roads={"]
for _,r in network.roads.items():
    pts=','.join('{%d,%d}'%(p[1],p[2]) for _,p in r.points.items())
    lines.append("{id='%s',name='%s',width=%d,points={%s}},"%(r.id,r.name,r.width,pts))
lines.append('}}\n')
out=root/'scripts/city_roads/dhubai.lua';out.write_text('\n'.join(lines))
print('Baked',len(network.roads),'road pieces to',out)
