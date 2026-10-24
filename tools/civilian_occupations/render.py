#!/usr/bin/env python3
"""Render the shipped civilian DAE assets through Assimp and headless OpenGL.

This is a model inspection render, not a Recoil screenshot or generated concept
art. Only the ordinary body pieces shown by civilianscript.bodyBuild are drawn.
Optional tools: assimp-py, numpy, pillow, moderngl, glcontext.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

os.environ.setdefault("MESA_SHADER_CACHE_DIR", "/tmp/mosaic-civilian-shader-cache")

import assimp_py
import moderngl
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
MODELS = (
    ("civilian_worker_western", "MUNICIPAL WORKER"),
    ("civilian_courier_asian", "FOOT COURIER"),
)
VISIBLE = {
    "center", "UpBody", "Head1", "UpArm1", "UpArm2", "LowArm1", "LowArm2",
    "Hand1", "Hand2", "UpLeg1", "UpLeg2", "LowLeg1", "LowLeg2", "Feet1", "Feet2",
    "Eye1", "Eye2",
}


def normalize(vector):
    vector = np.asarray(vector, dtype=float)
    return vector / np.linalg.norm(vector)


def look_at(eye, target):
    eye = np.asarray(eye, dtype=float)
    forward = normalize(np.asarray(target) - eye)
    right = normalize(np.cross(forward, [0, 1, 0]))
    up = np.cross(right, forward)
    result = np.eye(4)
    result[0, :3], result[1, :3], result[2, :3] = right, up, -forward
    result[:3, 3] = -result[:3, :3] @ eye
    return result


def ortho(left, right, bottom, top, near, far):
    result = np.eye(4)
    result[0, 0], result[1, 1], result[2, 2] = (
        2 / (right - left), 2 / (top - bottom), -2 / (far - near)
    )
    result[0, 3] = -(right + left) / (right - left)
    result[1, 3] = -(top + bottom) / (top - bottom)
    result[2, 3] = -(far + near) / (far - near)
    return result


def load_model(path, visible=None):
    """Use the actual imported hierarchy, including COLLADA unit/root scaling."""
    flags = (assimp_py.Process_Triangulate | assimp_py.Process_ValidateDataStructure
             | assimp_py.Process_CalcTangentSpace)
    scene = assimp_py.import_file(str(path), flags)
    chunks, counts = [], {}
    visible = VISIBLE if visible is None else set(visible)

    def walk(node, parent):
        world = parent @ np.asarray(node.transformation, dtype=float)
        if node.name in visible or node.name.startswith("RoleGear"):
            for index in node.mesh_indices:
                mesh = scene.meshes[index]
                vertices = np.asarray(mesh.vertices).reshape(-1, 3)
                normals = np.asarray(mesh.normals).reshape(-1, 3)
                indices = np.asarray(mesh.indices).reshape(-1)
                uv_components = mesh.num_uv_components[0]
                uvs = np.asarray(mesh.texcoords[0]).reshape(-1, uv_components)[:, :2]
                vertices = (world @ np.column_stack((vertices, np.ones(len(vertices)))).T).T[:, :3]
                normals = (np.linalg.inv(world[:3, :3]).T @ normals.T).T
                normals /= np.linalg.norm(normals, axis=1)[:, None]
                chunks.append(np.column_stack((vertices, normals, uvs))[indices])
                counts[node.name] = counts.get(node.name, 0) + len(indices) // 3
        for child in node.children:
            walk(child, world)

    walk(scene.root_node, np.eye(4))
    if not chunks:
        raise ValueError(f"No visible body geometry in {path}")
    return np.concatenate(chunks).astype("f4"), counts


VERTEX = """#version 330
in vec3 position; in vec3 normal; in vec2 uv;
uniform mat4 mvp; uniform mat4 light_mvp;
out vec3 N; out vec2 UV; out vec4 shadow_coord;
void main() {
    N = normal; UV = uv;
    shadow_coord = light_mvp * vec4(position, 1.0);
    gl_Position = mvp * vec4(position, 1.0);
}
"""
FRAGMENT = """#version 330
in vec3 N; in vec2 UV; in vec4 shadow_coord;
uniform sampler2D atlas; uniform sampler2DShadow shadow_map;
uniform bool ground; out vec4 color;
void main() {
    vec3 n = normalize(N);
    vec3 light = normalize(vec3(-0.6, 1.0, 0.8));
    vec3 q = shadow_coord.xyz / shadow_coord.w * 0.5 + 0.5;
    float visibility = 0.0;
    float bias = max(0.0005, 0.002 * (1.0-dot(n, light)));
    for (int x=-1; x<=1; ++x) for (int y=-1; y<=1; ++y)
        visibility += texture(shadow_map, vec3(q.xy+vec2(x,y)/1536.0,q.z-bias))/9.0;
    vec3 base = ground ? vec3(0.62,0.63,0.61) : pow(texture(atlas,UV).rgb,vec3(2.2));
    float ambient = 0.48 + 0.10*max(n.y,0.0);
    float sunlight = max(dot(n,light),0.0)*0.75*visibility;
    color = vec4(pow(base*(ambient+sunlight),vec3(1.0/2.2)),1.0);
}
"""


class Renderer:
    def __init__(self, atlas):
        self.ctx = moderngl.create_standalone_context(backend="egl")
        self.program = self.ctx.program(vertex_shader=VERTEX, fragment_shader=FRAGMENT)
        self.depth_program = self.ctx.program(
            vertex_shader="""#version 330
in vec3 position; uniform mat4 mvp;
void main(){gl_Position=mvp*vec4(position,1.0);}""",
            fragment_shader="#version 330\nvoid main(){}",
        )
        image = Image.open(atlas).convert("RGB").transpose(Image.Transpose.FLIP_TOP_BOTTOM)
        self.atlas = self.ctx.texture(image.size, 3, image.tobytes())
        self.atlas.build_mipmaps()
        self.atlas.use(0)
        self.program["atlas"], self.program["shadow_map"] = 0, 1
        self.depth = self.ctx.depth_texture((1536, 1536))
        self.depth.compare_func = "<="
        self.depth.repeat_x = self.depth.repeat_y = False
        self.shadow_frame = self.ctx.framebuffer(depth_attachment=self.depth)
        self.ctx.enable(moderngl.DEPTH_TEST | moderngl.CULL_FACE)

    def draw(self, data, eye, size=(512, 640), border=1.08):
        bounds = (data[:, :3].min(0), data[:, :3].max(0))
        center = (bounds[0] + bounds[1]) / 2
        height = bounds[1][1] - bounds[0][1]
        eye = normalize(eye) * height * 4 + center
        camera = look_at(eye, center)
        points = (camera @ np.column_stack((data[:, :3], np.ones(len(data)))).T).T
        aspect = size[0] / size[1]
        half_y = max(np.ptp(points[:, 1]), np.ptp(points[:, 0]) / aspect) * 0.5 * border
        half_x = half_y * aspect
        cx, cy = (points[:, 0].min()+points[:, 0].max())/2, (points[:, 1].min()+points[:, 1].max())/2
        mvp = ortho(cx-half_x, cx+half_x, cy-half_y, cy+half_y, .01, height*12) @ camera
        light_camera = look_at(center + np.array([-1.6, 3, 2]) * height, center)
        light_mvp = ortho(-height, height, -height, height, .01, height*12) @ light_camera
        self.program["light_mvp"].write(light_mvp.T.astype("f4").tobytes())
        buffer = self.ctx.buffer(data.tobytes())
        model = self.ctx.vertex_array(self.program, [(buffer, "3f 3f 2f", "position", "normal", "uv")])
        depth_model = self.ctx.vertex_array(self.depth_program, [(buffer, "3f 20x", "position")])
        self.shadow_frame.use()
        self.shadow_frame.clear(depth=1)
        self.depth_program["mvp"].write(light_mvp.T.astype("f4").tobytes())
        depth_model.render()
        floor_y = bounds[0][1]-.04
        x, z, extent = center[0], center[2], height*2
        ground = np.array([
            [x-extent,floor_y,z-extent,0,1,0,0,0], [x-extent,floor_y,z+extent,0,1,0,0,0], [x+extent,floor_y,z+extent,0,1,0,0,0],
            [x-extent,floor_y,z-extent,0,1,0,0,0], [x+extent,floor_y,z+extent,0,1,0,0,0], [x+extent,floor_y,z-extent,0,1,0,0,0],
        ], dtype="f4")
        ground_buffer = self.ctx.buffer(ground.tobytes())
        ground_model = self.ctx.vertex_array(self.program, [(ground_buffer,"3f 3f 2f","position","normal","uv")])
        frame = self.ctx.simple_framebuffer(size, components=3)
        frame.use()
        frame.clear(.83, .84, .82, 1, depth=1)
        self.depth.use(1)
        self.atlas.use(0)
        self.program["mvp"].write(mvp.T.astype("f4").tobytes())
        self.program["ground"] = True
        ground_model.render()
        self.program["ground"] = False
        model.render()
        result = Image.frombytes("RGB", size, frame.read(alignment=1)).transpose(Image.Transpose.FLIP_TOP_BOTTOM)
        for resource in (frame, ground_model, ground_buffer, depth_model, model, buffer):
            resource.release()
        return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--update-repo-previews", action="store_true")
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    renderer = Renderer(ROOT / "unittextures/civ_occupations_diffuse.png")
    font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
    heading = ImageFont.truetype(font_path, 34)
    label = ImageFont.truetype(font_path, 24)
    small = ImageFont.truetype(font_path, 18)
    sheet = Image.new("RGB", (1536, 1536), "#e1e4e0")
    draw = ImageDraw.Draw(sheet)
    draw.text((32, 20), "MOSAIC / CIVILIAN PLACEHOLDER MESHES", font=heading, fill="#162a30")
    draw.text((32, 65), "Actual exported DAE assets / bind pose / Assimp + headless OpenGL", font=small, fill="#46575b")
    records = []
    for row, (name, title) in enumerate(MODELS):
        data, counts = load_model(ROOT / "objects3d" / f"{name}.dae")
        y = 112 + row * 710
        draw.text((32, y), title, font=label, fill="#162a30")
        # Existing civilian authoring convention faces +Z after COLLADA import.
        views = (("FRONT", (0,0,1)), ("SIDE", (1,0,0)), ("BACK", (0,0,-1)))
        for column, (view, eye) in enumerate(views):
            preview = renderer.draw(data, eye, (496, 610))
            sheet.paste(preview, (8+column*512, y+37))
            draw.text((32+column*512,y+657),view,font=small,fill="#46575b")
        hero = renderer.draw(data, (-.65,.24,1), (768,768), border=1.10)
        hero.save(args.output / f"{name}.png")
        if args.update_repo_previews:
            (ROOT / "unitpics").mkdir(exist_ok=True)
            hero.resize((256,256),Image.Resampling.LANCZOS).save(ROOT / "unitpics" / f"{name}.png")
        records.append({"name":name,"visible_triangles":len(data)//3,"piece_triangles":counts,
                        "bounds":[data[:,:3].min(0).tolist(),data[:,:3].max(0).tolist()]})
    sheet.save(args.output / "civilian-placeholder-preview.png")
    if args.update_repo_previews:
        (ROOT / "docs/images").mkdir(parents=True, exist_ok=True)
        sheet.save(ROOT / "docs/images/civilian-placeholder-preview.png")
    (args.output / "render-report.json").write_text(json.dumps(records,indent=2)+"\n")
    print(json.dumps({"renderer":renderer.ctx.info["GL_RENDERER"],"models":records},indent=2))


if __name__ == "__main__":
    main()
