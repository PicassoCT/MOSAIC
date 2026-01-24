import bpy
from pathlib import Path

# ---------------- CONFIG ----------------
dae_path = "../objects3d/objective_PrinterDock.dae"
output_path = "../tools/hierarchy.txt"
# --------------------------------------

# Optional: start clean
bpy.ops.wm.read_factory_settings(use_empty=True)

# Import DAE
bpy.ops.wm.collada_import(filepath=dae_path)

def write_hierarchy(obj, file, depth=0):
    indent = "  " * depth
    file.write(f"{indent}{obj.name}\n")
    for child in sorted(obj.children, key=lambda o: o.name):
        write_hierarchy(child, file, depth + 1)

# Find root objects (no parent)
roots = [o for o in bpy.context.scene.objects if o.parent is None]

with open(output_path, "w", encoding="utf-8") as f:
    for root in sorted(roots, key=lambda o: o.name):
        write_hierarchy(root, f)

print(f"Hierarchy written to: {output_path}")
