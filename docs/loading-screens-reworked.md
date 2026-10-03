# Reworked loading screens

65 PNG images in `luaui/images/loadpictures_reworked/`: a matching rework for each of the 45 original loading-screen files, plus 20 additional incident, warning, and factory scenes.

The original assets and current loading-screen selection remain unchanged. The new folder is a separate review collection; it is not automatically included in the current rotation. The selector is in `luaintro/Addons/bg_texture.lua`. If activated later, use a PNG-only file glob.

## Art direction

MOSAIC world-archive collages combine news, CCTV, satellite, and equipment photographs with navy margins, white headings, cyan rules, and restrained amber warnings. Factory imagery depicts poor, grimy, repurposed facilities with patched machinery. Modular assemblies use standardized capsules, vitamin components, and tightly fitted packaging foil. Legacy armored vehicles remain conventional vehicles with camouflage upgrades.

These are visual and editorial reworks, not verbatim transcriptions. Dense copy is condensed into readable fictional dossiers. Threat overviews present selected cases. Operational weapon details become exterior equipment or aftermath imagery; coercion and propaganda are framed as in-world archive material. The aerosol screen uses protective messaging. Images are generated artwork and their incidental labels are not technical specifications.

## Inventory

Original numbering is preserved: 1–47, excluding 5 and 20, which were absent from the source. Original files 22 and 23 were identical; their reworked counterparts intentionally share the same assembly artwork. Additional scenes have descriptive filenames.

`loading-screens-reworked.json` records every image, its source, native dimensions, byte count, SHA-256, and Git blob SHA. Native generated resolution is preserved without upscaling.

Validation checks PNG decoding, dimensions, complete filename coverage, and differences from every original. This is an asset-only change; no gameplay code or active loader behavior is modified. No engine runtime test was performed.
