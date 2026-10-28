#!/usr/bin/env python3
"""Preview the actual exported payload pieces with their existing texture atlas.

Dependencies: numpy pillow assimp_py moderngl glcontext.  Uses headless EGL.
These are imported-mesh previews, not Recoil screenshots or generated artwork.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import assimp_py
import moderngl
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
TITLES = (
    "Air scrubber", "Night kitchen", "Battery exchange", "Salvage press",
    "Cold chain", "Sleeper shuttle", "Mobile crematorium", "Noodle stall",
    "Mobile casino", "Mobile strip club", "Mobile bar", "Mobile band stage",
    "UNATO ration dispenser",
)
# Measured native model-space offsets; the shared script applies these to center.
# Transportees inherit carrier BODY orientation (holdSteady=false), not the
# authored attachment piece's FBX rotation/scale.
MOUNTS = {
    "truck_arab6": (0.0, 0.0, -3.5),
    "truck_arab7": (0.0, 3.5, 1.0),
    "truck_arab8": (0.0, 4.1, 0.0),
}


def load_pieces(path: Path):
    """Read Assimp's imported geometry and every native node transform."""
    scene = assimp_py.import_file(str(path), assimp_py.Process_Triangulate)
    pieces, transforms = {}, {}

    def visit(node, parent):
        matrix = parent @ np.asarray(node.transformation, dtype=float)
        transforms[node.name] = matrix
        normal_matrix = np.linalg.inv(matrix[:3, :3]).T
        chunks = []
        for index in node.mesh_indices:
            mesh = scene.meshes[index]
            points = np.asarray(mesh.vertices).reshape(-1, 3)
            norms = np.asarray(mesh.normals).reshape(-1, 3)
            points = (matrix @ np.column_stack((points, np.ones(len(points)))).T).T[:, :3]
            norms = (normal_matrix @ norms.T).T
            lengths = np.linalg.norm(norms, axis=1)
            norms = norms / np.maximum(lengths[:, None], 1e-12)
            uv = np.asarray(mesh.texcoords[0]).reshape(-1, mesh.num_uv_components[0])[:, :2]
            indices = np.asarray(mesh.indices, dtype=int).reshape(-1)
            chunks.append(np.column_stack((points, norms, uv))[indices])
        if chunks:
            pieces[node.name] = np.concatenate(chunks).astype("f4")
        for child in node.children:
            visit(child, matrix)

    visit(scene.root_node, np.eye(4))
    return pieces, transforms


def normalize(v):
    return v / np.linalg.norm(v)


def look_at(eye, target):
    f = normalize(np.asarray(target, dtype=float) - eye)
    s = normalize(np.cross(f, [0, 1, 0]))
    u = np.cross(s, f)
    result = np.eye(4)
    result[0, :3], result[1, :3], result[2, :3] = s, u, -f
    result[:3, 3] = -result[:3, :3] @ eye
    return result


def ortho(left, right, bottom, top, near, far):
    result = np.eye(4)
    result[0, 0], result[1, 1], result[2, 2] = 2/(right-left), 2/(top-bottom), -2/(far-near)
    result[0, 3] = -(right+left)/(right-left)
    result[1, 3] = -(top+bottom)/(top-bottom)
    result[2, 3] = -(far+near)/(far-near)
    return result


VERT = """#version 330
in vec3 pos; in vec3 normal; in vec2 uv;
uniform mat4 mvp, light_mvp;
out vec3 n; out vec2 tex; out vec4 shadow;
void main(){ n=normal; tex=uv; shadow=light_mvp*vec4(pos,1); gl_Position=mvp*vec4(pos,1); }
"""
FRAG = """#version 330
in vec3 n; in vec2 tex; in vec4 shadow;
uniform sampler2D atlas; uniform sampler2DShadow depth;
uniform bool ground; out vec4 color;
void main(){
 vec3 N=normalize(n), L=normalize(vec3(-.55,1.,-.7));
 vec3 q=shadow.xyz/shadow.w*.5+.5;
 float vis=0., bias=max(.00035,.001*(1.-dot(N,L)));
 for(int x=-1;x<=1;x++) for(int y=-1;y<=1;y++)
   vis+=texture(depth,vec3(q.xy+vec2(x,y)/2048.,q.z-bias))/9.;
 vec3 base=ground?vec3(.68,.70,.70):pow(texture(atlas,tex).rgb,vec3(2.2));
 float sky=.40+.14*max(0.,N.y), sun=max(0.,dot(N,L))*.9*vis;
 color=vec4(pow(base*(sky+sun),vec3(1./2.2)),1.);
}
"""


class Renderer:
    def __init__(self, size=900):
        self.size = size
        self.ctx = moderngl.create_standalone_context(backend="egl")
        self.prog = self.ctx.program(vertex_shader=VERT, fragment_shader=FRAG)
        self.depth_prog = self.ctx.program(
            vertex_shader="#version 330\nin vec3 pos; uniform mat4 mvp; void main(){gl_Position=mvp*vec4(pos,1);}",
            fragment_shader="#version 330\nvoid main(){}",
        )
        self.depth = self.ctx.depth_texture((2048, 2048))
        self.depth.compare_func = "<="
        self.depth.repeat_x = self.depth.repeat_y = False
        self.shadow = self.ctx.framebuffer(depth_attachment=self.depth)
        self.frame = self.ctx.simple_framebuffer((size, size), components=3)
        self.prog["atlas"] = 0
        self.prog["depth"] = 1
        self.textures = {}
        self.ctx.enable(moderngl.DEPTH_TEST | moderngl.CULL_FACE)

    def texture(self, path):
        if path not in self.textures:
            im = Image.open(path).convert("RGB").transpose(Image.Transpose.FLIP_TOP_BOTTOM)
            texture = self.ctx.texture(im.size, 3, im.tobytes())
            texture.build_mipmaps()
            self.textures[path] = texture
        return self.textures[path]

    def render(self, groups, front=False):
        points = np.concatenate([data[:, :3] for data, _ in groups])
        target = (points.min(0) + points.max(0)) * .5
        eye = target + np.asarray([145., 105., 170. if front else -170.])
        view = look_at(eye, target)
        projected = (view @ np.column_stack((points, np.ones(len(points)))).T).T
        extent = max(np.ptp(projected[:, 0]), np.ptp(projected[:, 1])) * .58
        cx, cy = (projected[:, :2].min(0) + projected[:, :2].max(0)) * .5
        camera = ortho(cx-extent, cx+extent, cy-extent, cy+extent, 1, 800) @ view
        light_extent = max(np.ptp(points, axis=0)) * .8
        light = ortho(-light_extent, light_extent, -light_extent, light_extent, 1, 800) @ look_at(
            target + np.asarray([-180., 320., -230.]), target)
        ground_y = points[:, 1].min() - .12
        ground = np.array([
            [-300,ground_y,-300,0,1,0,0,0],[-300,ground_y,300,0,1,0,0,0],[300,ground_y,300,0,1,0,0,0],
            [-300,ground_y,-300,0,1,0,0,0],[300,ground_y,300,0,1,0,0,0],[300,ground_y,-300,0,1,0,0,0]], dtype="f4")
        buffers, vaos, depth_vaos = [], [], []
        for data, path in groups:
            buf = self.ctx.buffer(data.astype("f4").tobytes())
            buffers.append(buf)
            vaos.append(self.ctx.vertex_array(self.prog, [(buf,"3f 3f 2f","pos","normal","uv")]))
            depth_vaos.append(self.ctx.vertex_array(self.depth_prog, [(buf,"3f 20x","pos")]))
        gb = self.ctx.buffer(ground.tobytes())
        gv = self.ctx.vertex_array(self.prog, [(gb,"3f 3f 2f","pos","normal","uv")])
        self.shadow.use()
        self.shadow.clear(depth=1)
        self.depth_prog["mvp"].write(light.T.astype("f4").tobytes())
        for vao in depth_vaos:
            vao.render()
        self.frame.use()
        self.frame.clear(.86, .88, .88, 1, depth=1)
        self.depth.use(1)
        self.prog["mvp"].write(camera.T.astype("f4").tobytes())
        self.prog["light_mvp"].write(light.T.astype("f4").tobytes())
        self.prog["ground"] = True
        gv.render()
        self.prog["ground"] = False
        for vao, (_, path) in zip(vaos, groups):
            self.texture(path).use(0)
            vao.render()
        image = Image.frombytes("RGB", (self.size, self.size), self.frame.read(alignment=1)).transpose(Image.Transpose.FLIP_TOP_BOTTOM)
        for item in [*vaos, *depth_vaos, *buffers, gv, gb]:
            item.release()
        return image


def make_sheet(records, output, title, subtitle):
    columns, cell_w, cell_h = 4, 600, 620
    rows = (len(records) + columns - 1) // columns
    sheet = Image.new("RGB", (columns*cell_w, 110+rows*cell_h), "#e5e9e9")
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 26)
    small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 19)
    draw.text((25,18), title, font=font, fill="#14282d")
    draw.text((25,58), subtitle, font=small, fill="#475b60")
    for i, (path, label, triangles) in enumerate(records):
        x, y = (i%columns)*cell_w, 110+(i//columns)*cell_h
        im = Image.open(path).convert("RGB")
        im.thumbnail((590,550), Image.Resampling.LANCZOS)
        sheet.paste(im, (x+(cell_w-im.width)//2, y))
        number = int(path.name.split("-",1)[0])
        draw.text((x+18,y+552), f"{number:02d}  {label}", font=font, fill="#14282d")
        draw.text((x+18,y+589), f"{triangles:,} visible triangles", font=small, fill="#475b60")
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, quality=93)


def make_ration_sheet(isolated, mounted, stacked, output, triangles, pitch, carrier):
    """Compare one imported module, its carrier fit, and physical stack fit."""
    cell_w, image_h, top = 720, 750, 126
    sheet = Image.new("RGB", (3*cell_w, top+image_h+110), "#e5e9e9")
    draw = ImageDraw.Draw(sheet)
    font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
    title_font = ImageFont.truetype(font_path, 34)
    label_font = ImageFont.truetype(font_path, 25)
    small = ImageFont.truetype(font_path, 21)
    draw.text((28,22), "MOSAIC / 13 — UNATO RATION DISPENSER", font=title_font, fill="#14282d")
    draw.text((28,72), "Actual exported mesh and existing Asian-house texture atlas | offline model preview",
              font=small, fill="#475b60")
    panels = (
        (isolated, "DETACHABLE MODULE", f"{triangles:,} triangles / container13"),
        (mounted, "ON STANDARD CARRIER", carrier),
        (stacked, "TWO-HIGH STACK", f"Four corner contacts / {pitch:g} units between origins"),
    )
    for i, (path, label, detail) in enumerate(panels):
        x = i*cell_w
        im = Image.open(path).convert("RGB")
        im.thumbnail((cell_w-20, image_h), Image.Resampling.LANCZOS)
        sheet.paste(im, (x+(cell_w-im.width)//2, top+(image_h-im.height)//2))
        draw.text((x+24,top+image_h+12), label, font=label_font, fill="#14282d")
        draw.text((x+24,top+image_h+50), detail, font=small, fill="#475b60")
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, quality=93)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", type=Path, default=ROOT/"objects3d/truckPayloadService.dae")
    parser.add_argument("--output", type=Path, default=ROOT.parent/"payload-model-previews")
    parser.add_argument("--carrier", choices=tuple(MOUNTS), default="truck_arab8")
    parser.add_argument("--size", type=int, default=900)
    parser.add_argument("--limit", type=int, default=len(TITLES), help="preview an initial subset while authoring")
    parser.add_argument("--piece", type=int, choices=range(1,len(TITLES)+1),
                        help="render one numbered payload instead of the entire bundle")
    parser.add_argument("--front", action="store_true")
    parser.add_argument("--update-repo-preview", action="store_true")
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    payload_pieces, _ = load_pieces(args.model)
    carrier_pieces, carrier_nodes = load_pieces(ROOT/"objects3d"/(args.carrier+".dae"))
    carrier = np.concatenate([v for k,v in carrier_pieces.items()
                              if k.lower() not in ("center","attachpoint","detectpiece")
                              and not k.lower().startswith("emitlight")])
    origin = carrier_nodes["attachPoint"][:3,3]
    offset = origin + np.asarray(MOUNTS[args.carrier])
    atlas = ROOT/"unittextures/house_asian_diffuse.dds"
    truck_atlas = ROOT/"unittextures"/("truck_"+args.carrier[-1]+"_diffuse.DDS")
    renderer = Renderer(args.size)
    isolated_records, mounted_records, metadata = [], [], []
    selected = [(args.piece,TITLES[args.piece-1])] if args.piece else list(enumerate(TITLES[:args.limit],1))
    for i, title in selected:
        name = "container"+str(i)
        data = payload_pieces[name]
        triangles = len(data)//3
        isolated_path = args.output/(f"{i:02d}-payload.png")
        mounted_path = args.output/(f"{i:02d}-{args.carrier}.png")
        renderer.render([(data,atlas)], args.front).save(isolated_path)
        mounted = data.copy()
        mounted[:,:3] += offset
        renderer.render([(carrier,truck_atlas),(mounted,atlas)], args.front).save(mounted_path)
        isolated_records.append((isolated_path,title,triangles))
        mounted_records.append((mounted_path,title,triangles))
        metadata.append({"piece":name,"title":title,"triangles":triangles,
                         "bounds":[data[:,:3].min(0).tolist(),data[:,:3].max(0).tolist()]})
    isolated_sheet = args.output/"truck-service-payloads-isolated.jpg"
    mounted_sheet = args.output/"truck-service-payloads-preview.jpg"
    make_sheet(isolated_records,isolated_sheet,"MOSAIC / SERVICE PAYLOAD MODELS",
               "Actual exported geometry | existing Asian-house diffuse atlas | individual visible variants")
    make_sheet(mounted_records,mounted_sheet,"MOSAIC / SERVICE PAYLOADS ON ORDINARY TRUCKS",
               f"Actual exported models on {args.carrier} | existing texture atlases | offline mesh preview")
    if args.update_repo_preview and not args.piece and len(selected)==len(TITLES):
        destination = ROOT/"docs/images/truck-service-payloads-preview.jpg"
        destination.parent.mkdir(parents=True,exist_ok=True)
        Image.open(mounted_sheet).save(destination,quality=93)
    if any(i==13 for i,_ in selected):
        manifest = json.loads((ROOT/"tools/truck_service_payloads/manifest.json").read_text())
        record = next(v for v in manifest["variants"] if v["piece"]=="container13")
        pitch = float(record["stack"]["pitch_y"])
        lower = payload_pieces["container13"]
        upper = lower.copy()
        upper[:,1] += pitch
        stacked_path = args.output/"13-stacked.png"
        renderer.render([(lower,atlas),(upper,atlas)],args.front).save(stacked_path)
        ration_sheet = args.output/"unato-ration-payload-preview.jpg"
        make_ration_sheet(args.output/"13-payload.png",args.output/f"13-{args.carrier}.png",
                          stacked_path,ration_sheet,len(lower)//3,pitch,args.carrier)
        if args.update_repo_preview:
            Image.open(ration_sheet).save(ROOT/"docs/images/unato-ration-payload-preview.jpg",quality=93)
    (args.output/"render-manifest.json").write_text(json.dumps({
        "renderer":renderer.ctx.info["GL_RENDERER"],"carrier":args.carrier,
        "attachment_position":origin.tolist(),"model_offset":list(MOUNTS[args.carrier]),
        "pieces":metadata},indent=2)+"\n")
    print(f"Rendered {len(metadata)} imported variants on {args.carrier} with {renderer.ctx.info['GL_RENDERER']}: {args.output}")


if __name__ == "__main__":
    main()
