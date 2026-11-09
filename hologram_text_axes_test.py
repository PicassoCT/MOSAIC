"""Validate the animation basis against both actual exported letter models."""
import math
import re
import xml.etree.ElementTree as ET

IDENTITY = [[float(i == j) for j in range(4)] for i in range(4)]


def product(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(4)) for j in range(4)] for i in range(4)]


def vertical(matrix, axis):
    vector = [matrix[row][axis] for row in range(3)]
    length = math.sqrt(sum(v*v for v in vector))
    return length > 0 and abs(vector[1]/length-1) < 1e-5


for path in ("objects3d/house_western_hologram.DAE", "objects3d/house_western_brothel_hologram.DAE"):
    root = ET.parse(path).getroot()
    ns = {"c": root.tag.split("}")[0][1:]}
    assert root.findtext("c:asset/c:up_axis", namespaces=ns) == "Y_UP"
    pieces = {}

    def walk(node, parent):
        values = list(map(float, node.findtext("c:matrix", namespaces=ns).split()))
        local = [values[i:i+4] for i in range(0, 16, 4)]
        world = product(parent, local)
        pieces[node.get("name")] = (node, parent, world)
        for child in node.findall("c:node", ns):
            walk(child, world)

    for scene in root.findall(".//c:visual_scene", ns):
        for node in scene.findall("c:node", ns):
            walk(node, IDENTITY)

    _, parent, spinner = pieces["text_spin"]
    # Script Move precedes baked rotation; script Turn follows it.
    assert vertical(parent, 1), path + ": spinner lift must use parent Y"
    assert vertical(spinner, 2), path + ": spinner yaw must use authored Z"
    letters = [v for name, v in pieces.items() if re.fullmatch(r"[A-Z]\d+", name)]
    assert len(letters) >= 26
    for node, parent, world in letters:
        assert vertical(parent, 2), (path, node.get("name"), "drop axis")
        assert vertical(world, 2), (path, node.get("name"), "spin axis")
        geometry = node.find("c:instance_geometry", ns).get("url")[1:]
        mesh = root.find('.//c:geometry[@id="' + geometry + '"]/c:mesh', ns)
        source = mesh.find('c:vertices/c:input[@semantic="POSITION"]', ns).get("source")[1:]
        coords = list(map(float, mesh.findtext('c:source[@id="' + source + '"]/c:float_array', namespaces=ns).split()))
        extents = [max(coords[i::3])-min(coords[i::3]) for i in range(3)]
        assert extents[0] < min(extents[1:]), (path, node.get("name"), "glyph face must lie in Y/Z")
    print(path + ": spinner lift/yaw and " + str(len(letters)) + " letter axes PASS")
