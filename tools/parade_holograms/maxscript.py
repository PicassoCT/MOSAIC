"""Write the editable 3ds Max 2018 master for parade hologram cages.

The output is self-contained apart from the existing Asian-house texture pair.
It creates genuine SplineShape bases with live modifiers; the runtime voxel DAE
is a separate export.  Native Max execution is not available in the Linux
authoring environment, so the writer also performs conservative lexical checks.
"""
from __future__ import annotations

import json
import math
from pathlib import Path
import re


def _number(value):
    value = float(value)
    if not math.isfinite(value):
        raise ValueError("Nonfinite MAXScript coordinate")
    text = f"{value:.9f}".rstrip("0").rstrip(".")
    if text in ("", "-0"):
        text = "0"
    return text if "." in text else text + ".0"


def _point(value):
    if len(value) != 3:
        raise ValueError("MAXScript point must have three coordinates")
    return "[" + ",".join(_number(x) for x in value) + "]"


def _array(items):
    return "#(" + ",".join(items) + ")"


def _string(value):
    # UTF-8 BOM on output lets Max 2018 read any non-ASCII authoring labels.
    return json.dumps(str(value), ensure_ascii=False)


def _boolean(value):
    return "true" if value else "false"


_RUNTIME = r'''
global MPHC_AtlasDir
global MPHC_SurfaceSteps
global MPHC_TubeSteps
global MPHC_WeldThreshold
global MPHC_ReviewLayout
global MPHC_ReviewColumns
global MPHC_LayoutStep
global MPHC_StrictClosed
global MPHC_Palette
global MPHC_DiffuseFile
global MPHC_PackedFile
global MPHC_DiffuseSHA256
global MPHC_PackedSHA256
global MPHC_AtlasDimensions

if MPHC_AtlasDir == undefined do MPHC_AtlasDir=""
if MPHC_SurfaceSteps == undefined do MPHC_SurfaceSteps=0
if MPHC_TubeSteps == undefined do MPHC_TubeSteps=1
if MPHC_WeldThreshold == undefined do MPHC_WeldThreshold=0.001
if MPHC_ReviewLayout == undefined do MPHC_ReviewLayout=true
if MPHC_ReviewColumns == undefined do MPHC_ReviewColumns=6
if MPHC_StrictClosed == undefined do MPHC_StrictClosed=true

struct MPHC_Builder
(
    rootNode, layerNode, layerName="MOSAIC_PARADE_EDITABLE_CAGES",
    prefix="", created=#(), roots=#(), parts=#(), currentParts=#(),
    roleKeys=#(), roleNodes=#(), materials=#(), ownsLayer=false,
    diffusePath="", packedPath="",

    fn openRaw path =
    (
        local b=openBitmap path gamma:1.0
        if b == undefined do throw ("Could not open texture: "+path)
        b
    ),

    fn sha256File path =
    (
        local stream=undefined
        local algorithm=dotNetObject "System.Security.Cryptography.SHA256Managed"
        local result
        try
        (
            stream=(dotNetClass "System.IO.File").OpenRead path
            local bytes=algorithm.ComputeHash stream
            result=toLower (substituteString ((dotNetClass "System.BitConverter").ToString bytes) "-" "")
            stream.Close()
            algorithm.Dispose()
        )
        catch
        (
            local err=getCurrentException()
            if stream != undefined do try(stream.Close())catch()
            try(algorithm.Dispose())catch()
            throw err
        )
        result
    ),

    fn paletteRow key =
    (
        for row in MPHC_Palette where row[1] == key do return row
        throw ("Unknown Asian-house atlas palette key: "+key)
    ),

    fn validateAtlas =
    (
        local db=undefined, eb=undefined
        try
        (
            db=openRaw diffusePath
            eb=openRaw packedPath
            if db.width != MPHC_AtlasDimensions[1] or db.height != MPHC_AtlasDimensions[2] or eb.width != db.width or eb.height != db.height do
                throw "The palette requires the original matching Asian-house atlas dimensions."
            for row in MPHC_Palette do
            (
                local rect=row[2]
                local gutter=row[5]
                local x0=amax 0 ((floor (rect[1]*db.width))-gutter)
                local x1=amin (db.width-1) ((floor (rect[3]*db.width))+gutter)
                local y0=amax 0 ((floor ((1.0-rect[4])*db.height))-gutter)
                local y1=amin (db.height-1) ((floor ((1.0-rect[2])*db.height))+gutter)
                for yy=y0 to y1 do
                (
                    local erow=getPixels eb [x0,yy] (x1-x0+1) linear:false
                    local drow=getPixels db [x0,yy] (x1-x0+1) linear:false
                    for j=1 to erow.count do
                    (
                        local valid=(erow[j].a >= 250 and drow[j].a <= 12)
                        valid=valid and (if row[4] then erow[j].r >= 245 else erow[j].r <= 12)
                        if not valid do throw ("Asian-house palette validation failed for "+row[1]+". No source geometry has been replaced.")
                    )
                )
            )
            close db
            close eb
        )
        catch
        (
            local err=getCurrentException()
            if db != undefined do try(close db)catch()
            if eb != undefined do try(close eb)catch()
            throw err
        )
        true
    ),

    fn prepare folder =
    (
        if MPHC_SurfaceSteps < 0 or MPHC_SurfaceSteps > 6 do throw "MPHC_SurfaceSteps must be in 0..6."
        if MPHC_TubeSteps < 0 or MPHC_TubeSteps > 6 do throw "MPHC_TubeSteps must be in 0..6."
        if MPHC_WeldThreshold <= 0 do throw "MPHC_WeldThreshold must be positive."
        if MPHC_ReviewColumns < 1 do throw "MPHC_ReviewColumns must be at least one."
        local atlasDir=if MPHC_AtlasDir != "" then MPHC_AtlasDir else (pathConfig.appendPath folder "..\\..\\unittextures")
        diffusePath=pathConfig.appendPath atlasDir MPHC_DiffuseFile
        packedPath=pathConfig.appendPath atlasDir MPHC_PackedFile
        for path in #(diffusePath,packedPath) where not (doesFileExist path) do
            throw ("Missing Asian-house texture: "+path+". Set MPHC_AtlasDir to your MOSAIC unittextures folder and run again.")
        if MPHC_DiffuseSHA256 != "" and (sha256File diffusePath) != MPHC_DiffuseSHA256 do
            throw "Asian-house diffuse checksum mismatch. Regenerate the measured palette for changed textures."
        if MPHC_PackedSHA256 != "" and (sha256File packedPath) != MPHC_PackedSHA256 do
            throw "Asian-house packed-mask checksum mismatch. Regenerate the measured palette for changed textures."
        validateAtlas()
        local diffuseMap=bitmapTexture filename:diffusePath name:"MOSAIC Asian diffuse RGB"
        diffuseMap.rgbOutput=0
        diffuseMap.alphaSource=2
        local packed=bitmapTexture filename:packedPath name:"MOSAIC Asian packed tex2 linear"
        packed.bitmap=openRaw packedPath
        packed.monoOutput=0
        packed.rgbOutput=0
        local redMap=RGB_Tint map1:packed red:(color 255 255 255) green:(color 0 0 0) blue:(color 0 0 0) name:"MOSAIC tex2 RED emission"
        local greenMap=RGB_Tint map1:packed red:(color 0 0 0) green:(color 255 255 255) blue:(color 0 0 0) name:"MOSAIC tex2 GREEN reflection"
        materials=#()
        for row in MPHC_Palette do
        (
            local m=standardMaterial name:("ParadeAsian_"+row[1]) diffuse:(color 255 255 255)
            m.diffuseMap=diffuseMap
            m.diffuseMapEnable=true
            m.diffuseMapAmount=100.0
            m.useSelfIllumColor=false
            m.selfIllumAmount=100.0
            m.selfIllumMap=redMap
            m.selfIllumMapEnable=true
            m.selfIllumMapAmount=100.0
            m.specularLevel=35.0
            m.specularLevelMap=greenMap
            m.specularLevelMapEnable=true
            m.specularLevelMapAmount=100.0
            m.glossiness=24.0
            m.opacity=100.0
            m.twoSided=false
            showTextureMap m diffuseMap true
            append materials #(row[1],m)
        )
        layerNode=LayerManager.getLayerFromName layerName
        if layerNode == undefined do
        (
            layerNode=LayerManager.newLayerFromName layerName
            ownsLayer=true
        )
        true
    ),

    fn materialFor key =
    (
        for row in materials where row[1] == key do return row[2]
        throw ("Missing material: "+key)
    ),

    fn roleNode key pivot parentNode =
    (
        local n=dummy name:(prefix+"__"+key) boxsize:[0.4,0.4,0.4]
        append created n
        n.transform=transMatrix pivot
        n.parent=parentNode
        layerNode.addNode n
        setUserProp n "MOSAIC_role" key
        setUserProp n "MOSAIC_source_pivot" (pivot as string)
        append roleKeys key
        append roleNodes n
        n
    ),

    fn startModel slug title category variant cellSize pivot description isFigure =
    (
        prefix=slug
        currentParts=#(); roleKeys=#(); roleNodes=#()
        rootNode=dummy name:prefix boxsize:[0.8,0.8,0.8]
        rootNode.transform=matrix3 1
        append created rootNode
        append roots rootNode
        layerNode.addNode rootNode
        setUserProp rootNode "MOSAIC_parade_model" title
        setUserProp rootNode "MOSAIC_category" category
        setUserProp rootNode "MOSAIC_variant" variant
        setUserProp rootNode "MOSAIC_description" description
        setUserProp rootNode "MOSAIC_source_coordinates" "X right, Y depth, Z up, front -Y; foot origin [0,0,0]"
        setUserProp rootNode "MOSAIC_game_basis" "[x,y,z] source becomes [x,z,-y] in the voxel DAE"
        setUserProp rootNode "MOSAIC_source_foot_origin" "[0,0,0]"
        setUserProp rootNode "MOSAIC_pixel_cell_size" cellSize
        setUserProp rootNode "MOSAIC_source_head_pivot" (pivot as string)
        setUserProp rootNode "MOSAIC_authoring" "Editable SplineShape cages with live Surface/Shell/Normal/UVW; separate game voxel export"
        setUserProp rootNode "MOSAIC_tex1" MPHC_DiffuseFile
        setUserProp rootNode "MOSAIC_tex2" MPHC_PackedFile
        roleNode "body" [0,0,0] rootNode
        if isFigure do
        (
            local head=roleNode "head" pivot rootNode
            roleNode "mask" pivot head
        )
        rootNode
    ),

    fn addCurve n pts closed smooth inHandles:undefined outHandles:undefined =
    (
        addNewSpline n
        local si=numSplines n
        local count=pts.count
        in coordsys world
        (
            for i=1 to count do
            (
                local p=pts[i]
                if smooth and inHandles != undefined and outHandles != undefined then
                    addKnot n si #bezierCorner #curve p inHandles[i] outHandles[i]
                else if smooth then
                (
                    local tangent
                    if closed then
                    (
                        local before=if i == 1 then pts[count] else pts[i-1]
                        local after=if i == count then pts[1] else pts[i+1]
                        tangent=(after-before)/6.0
                    )
                    else
                    (
                        if i == 1 then tangent=(pts[2]-p)/3.0
                        else if i == count then tangent=(p-pts[count-1])/3.0
                        else tangent=(pts[i+1]-pts[i-1])/6.0
                    )
                    addKnot n si #bezierCorner #curve p (p-tangent) (p+tangent)
                )
                else addKnot n si #corner #line p
            )
        )
        if closed do close n si
        true
    ),

    fn uvBounds n =
    (
        local tmp=undefined, result
        try
        (
            tmp=snapshotAsMesh n
            if (getNumTVerts tmp) == 0 do throw ("No UV coordinates on "+n.name)
            local lo=[1e20,1e20,0], hi=[-1e20,-1e20,0]
            for i=1 to (getNumTVerts tmp) do
            (
                local uv=getTVert tmp i
                lo.x=amin lo.x uv.x; lo.y=amin lo.y uv.y
                hi.x=amax hi.x uv.x; hi.y=amax hi.y uv.y
            )
            result=#(lo,hi)
            delete tmp
        )
        catch
        (
            local err=getCurrentException()
            if tmp != undefined do try(delete tmp)catch()
            throw err
        )
        result
    ),

    fn atlasUV n rect =
    (
        local bb=nodeGetBoundingBox n n.transform
        local ext=bb[2]-bb[1]
        local mapping=UVWMap maptype:4 width:(amax ext.x 0.01) length:(amax ext.y 0.01) height:(amax ext.z 0.01) mapChannel:1
        mapping.name="03 Editable box projection"
        mapping.realWorldMapSize=false
        addModifier n mapping
        mapping.gizmo.position=(bb[1]+bb[2])*0.5
        mapping.gizmo.rotation=quat 0 0 0 1
        mapping.gizmo.scale=[1,1,1]
        local bounds=uvBounds n
        local span=bounds[2]-bounds[1]
        if span.x <= 0 or span.y <= 0 do throw ("Degenerate UV projection: "+n.name)
        local sx=(rect[3]-rect[1])/span.x
        local sy=(rect[4]-rect[2])/span.y
        local xf=UVW_Xform U_Tile:sx V_Tile:sy U_Offset:(rect[1]-bounds[1].x*sx) V_Offset:(rect[2]-bounds[1].y*sy) Map_Channel:1
        xf.name="04 Measured Asian atlas rectangle"
        addModifier n xf
        local actual=uvBounds n
        xf.U_Offset += rect[1]-actual[1].x
        xf.V_Offset += rect[2]-actual[1].y
        actual=uvBounds n
        if abs(actual[1].x-rect[1]) > 0.00001 or abs(actual[1].y-rect[2]) > 0.00001 or abs(actual[2].x-rect[3]) > 0.00001 or abs(actual[2].y-rect[4]) > 0.00001 do
            throw ("Atlas UV bounds check failed: "+n.name)
        setUserProp n "MOSAIC_atlas_rect" (rect as string)
    ),

    fn surfaceStats n =
    (
        local tmp=undefined, result
        try
        (
            tmp=snapshotAsMesh n
            if tmp.numfaces == 0 do throw ("No evaluated faces on "+n.name+". The original cage was not replaced.")
            local center=[0,0,0]
            for i=1 to tmp.numverts do center += getVert tmp i
            center /= tmp.numverts
            local volume=0.0
            for i=1 to tmp.numfaces do
            (
                local face=getFace tmp i
                local a=(getVert tmp (face.x as integer))-center
                local b=(getVert tmp (face.y as integer))-center
                local c=(getVert tmp (face.z as integer))-center
                volume += dot a (cross b c)
            )
            local edges=meshop.getOpenEdges tmp
            result=#(edges.numberSet,tmp.numfaces,volume/6.0)
            delete tmp
        )
        catch
        (
            local err=getCurrentException()
            if tmp != undefined do try(delete tmp)catch()
            throw err
        )
        result
    ),

    fn orientClosed n =
    (
        local evaluatedMesh=Mesh_Select()
        evaluatedMesh.name="01c Mesh evaluation for normals (live)"
        addModifier n evaluatedMesh
        local normal=NormalModifier unify:true flip:false
        normal.name="02 Consistent outward normals (live)"
        addModifier n normal
        local stats=surfaceStats n
        if stats[3] < 0 do
        (
            normal.flip=true
            stats=surfaceStats n
        )
        if MPHC_StrictClosed and (stats[1] != 0 or stats[3] <= 0.000000001) do
            throw ("Closed cage failed native evaluation: "+n.name+"; open edges="+(stats[1] as string))
        setUserProp n "MOSAIC_native_open_edges" stats[1]
        setUserProp n "MOSAIC_native_signed_volume" stats[3]
        true
    ),

    fn finishPart n key role =
    (
        local row=paletteRow key
        n.wirecolor=color row[3].x row[3].y row[3].z
        n.material=materialFor key
        atlasUV n row[2]
        local ri=findItem roleKeys role
        if ri == 0 do throw ("Missing semantic role "+role+" for "+n.name)
        n.parent=roleNodes[ri]
        layerNode.addNode n
        setUserProp n "MOSAIC_source" "editable_spline_cage"
        setUserProp n "MOSAIC_role" role
        setUserProp n "MOSAIC_palette_key" key
        setUserProp n "MOSAIC_glow" row[4]
        setUserProp n "MOSAIC_tex1" MPHC_DiffuseFile
        setUserProp n "MOSAIC_tex2" MPHC_PackedFile
        append parts n
        append currentParts n
        n
    ),

    fn cage name curves key role closed thickness =
    (
        local n=splineShape name:(prefix+"_"+name)
        n.transform=matrix3 1
        append created n
        for c in curves do
        (
            if c.count >= 5 then addCurve n c[3] c[1] c[2] inHandles:c[4] outHandles:c[5]
            else addCurve n c[3] c[1] c[2]
        )
        updateShape n
        n.steps=1; n.optimize=false; n.adaptive=false
        local surf=Surface threshold:MPHC_WeldThreshold steps:MPHC_SurfaceSteps
        surf.name="01 Surface from connected spline cage"
        addModifier n surf
        if thickness > 0 do
        (
            local skin=Shell innerAmount:(thickness/2.0) outerAmount:(thickness/2.0) segments:1
            skin.name="01b Thin panel skin (live Shell)"
            addModifier n skin
        )
        if closed or thickness > 0 do orientClosed n
        setUserProp n "MOSAIC_cage_splines" curves.count
        setUserProp n "MOSAIC_closed_surface" (closed or thickness > 0)
        finishPart n key role
    ),

    fn tube name pts radius sides closed smooth key role =
    (
        local n=splineShape name:(prefix+"_"+name)
        n.transform=matrix3 1
        append created n
        addCurve n pts closed smooth
        updateShape n
        n.steps=MPHC_TubeSteps; n.optimize=false; n.adaptive=false
        local tubeMod=Renderable_Spline renderable:true displayRenderSettings:true useViewportSettings:false mapcoords:true thickness:(radius*2.0) sides:sides
        tubeMod.name="01 Renderable spline contour (live)"
        tubeMod.SymmetricalOrRectangular=0
        tubeMod.realWorldMapSize=false
        addModifier n tubeMod
        setUserProp n "MOSAIC_closed_surface" false
        finishPart n key role
    ),

    fn finishModel =
    (
        if MPHC_ReviewLayout do
        (
            local index=roots.count-1
            local col=mod index MPHC_ReviewColumns
            local row=floor ((index as float)/MPHC_ReviewColumns)
            rootNode.position=[col*MPHC_LayoutStep.x,-row*MPHC_LayoutStep.y,0]
        )
        setUserProp rootNode "MOSAIC_review_translation" (rootNode.position as string)
        setUserProp rootNode "MOSAIC_source_component_count" currentParts.count
        format "Built %: % editable cage and contour components.\n" prefix currentParts.count
        rootNode
    ),

    fn validateAll =
    (
        local totalFaces=0
        for n in parts do
        (
            if classOf n.baseObject != SplineShape do throw ("Editable spline base missing: "+n.name)
            local hasSurface=false
            for m in n.modifiers do
                if classOf m == Surface or classOf m == Renderable_Spline do hasSurface=true
            if not hasSurface do throw ("Live cage generator missing: "+n.name)
            local stats=surfaceStats n
            totalFaces += stats[2]
            if MPHC_StrictClosed and (getUserProp n "MOSAIC_closed_surface") == true and (stats[1] != 0 or stats[3] <= 0.000000001) do
                throw ("Closed evaluated geometry failed: "+n.name)
            local rect=(paletteRow (getUserProp n "MOSAIC_palette_key"))[2]
            local bounds=uvBounds n
            if bounds[1].x < rect[1]-0.00001 or bounds[1].y < rect[2]-0.00001 or bounds[2].x > rect[3]+0.00001 or bounds[2].y > rect[4]+0.00001 do
                throw ("Evaluated UVs escaped their atlas rectangle: "+n.name)
        )
        format "Parade source validation: % roots, % components, % evaluated triangles.\n" roots.count parts.count totalFaces
        format "Save this editable master as .max. Review translations are root-only; source origins remain foot-local.\n"
        true
    ),

    fn cleanup =
    (
        -- These are only nodes created by this invocation, never existing work.
        for n in created where isValidNode n do delete n
        if ownsLayer do try(LayerManager.deleteLayerByName layerName)catch()
        created=#(); roots=#(); parts=#(); currentParts=#()
    )
)
'''


def _emit_part(part, figure):
    role = part.get("group") if figure else "body"
    if role not in ("body", "head", "mask"):
        raise ValueError(f"Unknown figure semantic role: {role!r}")
    if part["kind"] == "cage":
        curves = []
        for curve in part["curves"]:
            items = [_boolean(curve["closed"]), _boolean(curve["smooth"]),
                     _array(_point(p) for p in curve["points"])]
            if "in_handles" in curve or "out_handles" in curve:
                if len(curve.get("in_handles", [])) != len(curve["points"]) or len(curve.get("out_handles", [])) != len(curve["points"]):
                    raise ValueError("Explicit Bezier handles must match every knot")
                items.extend(_array(_point(p) for p in curve[key])
                             for key in ("in_handles", "out_handles"))
            curves.append(_array(items))
        curve_text = "#(\n                    " + ",\n                    ".join(curves) + "\n                )"
        return (f"f.cage {_string(part['name'])} {curve_text} "
                f"{_string(part['material'])} {_string(role)} "
                f"{_boolean(part['closed'])} {_number(part['thickness'])}")
    if part["kind"] != "tube":
        raise ValueError(f"Unsupported source kind: {part['kind']}")
    return (f"f.tube {_string(part['name'])} {_array(_point(p) for p in part['points'])} "
            f"{_number(part['radius'])} {int(part['sides'])} "
            f"{_boolean(part['closed'])} {_boolean(part['smooth'])} "
            f"{_string(part['material'])} {_string(role)}")


def _lexical_check(text):
    """Balanced delimiters and literals, not a claim of native Max execution."""
    code, index = [], 0
    while index < len(text):
        if text.startswith("--", index):
            end = text.find("\n", index+2)
            index = len(text) if end < 0 else end
        elif text.startswith("/*", index):
            depth, index = 1, index+2
            while index < len(text) and depth:
                if text.startswith("/*", index):
                    depth, index = depth+1, index+2
                elif text.startswith("*/", index):
                    depth, index = depth-1, index+2
                else:
                    index += 1
            if depth:
                raise ValueError("Unterminated MAXScript comment")
        elif text[index] == '"' or text.startswith('@"', index):
            verbatim = text.startswith('@"', index)
            index += 2 if verbatim else 1
            closed = False
            while index < len(text):
                if not verbatim and text[index] == "\\":
                    index += 2
                elif text[index] == '"':
                    index += 1
                    closed = True
                    break
                else:
                    index += 1
            if not closed:
                raise ValueError("Unterminated MAXScript string")
            code.append('""')
        else:
            code.append(text[index])
            index += 1
    stripped = "".join(code)
    stack = []
    for char in stripped:
        if char in "([":
            stack.append(char)
        elif char in ")]":
            if not stack or stack.pop() != (")" == char and "(" or "["):
                raise ValueError("Mismatched MAXScript delimiter")
    if stack:
        raise ValueError("Unclosed MAXScript delimiter")
    for command in ("convertToMesh", "convertToPoly", "collapseStack", "resetMaxFile",
                    "resetXForm", "meshop.attach", "polyop.attach"):
        if command.casefold() in stripped.casefold():
            raise ValueError("Destructive scene command: "+command)


def write_maxscript(models, palette, path):
    """Write a self-contained, non-destructive native cage builder and return its path."""
    models = list(models)
    if not models:
        raise ValueError("No parade cage models were supplied")
    figure_categories = {"civilian", "dead", "ai", "helper"}
    used = sorted({part["material"] for model in models for part in model["parts"]})
    palette_rows = []
    for key in used:
        patch = palette["patches"][key]
        rect = patch["uv_rect"]
        if len(rect) != 4 or not (0 <= rect[0] < rect[2] <= 1 and 0 <= rect[1] < rect[3] <= 1):
            raise ValueError(f"Invalid bottom-left atlas rectangle for {key}")
        palette_rows.append(_array([_string(key), _array(_number(x) for x in rect),
                                    _point(patch["preview_rgb"]), _boolean(patch["emissive"]),
                                    str(int(patch.get("verified_gutter_pixels", 0)))]))
    dimensions = palette.get("dimensions", [4096,4096])
    if isinstance(dimensions, dict):
        dimensions = [dimensions["width"], dimensions["height"]]
    if len(dimensions) != 2:
        raise ValueError("Atlas dimensions must specify width and height")
    tex1, tex2 = palette["texture1"], palette["texture2"]
    files = palette.get("files", {})
    texture_hashes = [files.get(name, {}).get("sha256", "") for name in (tex1, tex2)]
    for value in texture_hashes:
        if value and not re.fullmatch(r"[0-9a-f]{64}", value):
            raise ValueError("Invalid expected atlas SHA-256")

    names, max_width, max_depth = [], 8.0, 4.0
    for model in models:
        slug = model["slug"]
        if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*", slug):
            raise ValueError(f"Unsafe source root name: {slug!r}")
        figure = model.get("category") in figure_categories
        names.extend([slug, slug+"__body"])
        if figure:
            names.extend([slug+"__head", slug+"__mask"])
        low, high = [math.inf]*3, [-math.inf]*3
        for part in model["parts"]:
            if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*", part["name"]):
                raise ValueError("Unsafe source component name")
            names.append(slug+"_"+part["name"])
            points = part["vertices"] if part["kind"] == "cage" else part["points"]
            radius = part.get("radius", 0)
            for point in points:
                for axis, value in enumerate(point):
                    low[axis] = min(low[axis], value-radius)
                    high[axis] = max(high[axis], value+radius)
        max_width = max(max_width, high[0]-low[0])
        max_depth = max(max_depth, high[1]-low[1])
    if len({name.casefold() for name in names}) != len(names):
        raise ValueError("Case-insensitive duplicate source node name")

    lines = ['''/* MOSAIC PARADE HOLOGRAMS / EDITABLE SPLINE CAGE MASTER
   Native 3ds Max 2018 authoring source. Run from tools/parade_holograms/.
   The expected existing texture pair is in ../../unittextures/.
   Before running, optionally set MPHC_AtlasDir to a different atlas folder.
   Set MPHC_ReviewLayout=false to build all roots at their foot-local origins.
   Review layout only translates root helpers; it never scales the source.
   Change Surface steps for a smooth editing preview; source knots stay live.
   Save the result as .max to retain its SplineShape bases and modifier stacks.
   The pixelated game DAE is a separate generated asset, not this source scene.
   Existing node names are rejected before creation; no existing work is reset.
   Generator checks are lexical; native Max evaluation occurs when this runs.
*/
''', _RUNTIME,
             "MPHC_Palette=#(\n    " + ",\n    ".join(palette_rows) + "\n)",
             "MPHC_DiffuseFile=" + _string(tex1),
             "MPHC_PackedFile=" + _string(tex2),
             "MPHC_DiffuseSHA256=" + _string(texture_hashes[0]),
             "MPHC_PackedSHA256=" + _string(texture_hashes[1]),
             "MPHC_AtlasDimensions=" + _array(str(int(x)) for x in dimensions),
             "if MPHC_LayoutStep == undefined do MPHC_LayoutStep=" + _point((max_width+4,max_depth+6,0)),
             "(\n    local folder=getFilenamePath (getSourceFileName())\n"
             "    local previousSelection=selection as array\n"
             "    local f=MPHC_Builder()\n"
             "    local wanted=" + _array(_string(name) for name in names) + "\n"
             "    for name in wanted where (getNodeByName name exact:true) != undefined do\n"
             "        throw (\"Source node already exists: \"+name+\". Undo the previous build or use a clean scene; existing work is preserved.\")\n"
             "    undo \"Build MOSAIC parade spline cages\" on\n"
             "    (\n        with redraw off\n        (\n            try\n            (\n"
             "                f.prepare folder"]
    for model in models:
        figure = model.get("category") in figure_categories
        category = model.get("category", "prop")
        lines.append("                f.startModel " + " ".join([
            _string(model["slug"]), _string(model.get("title",model["slug"])),
            _string(category), str(int(model.get("variant",1))),
            _number(model.get("cell_size",.2)), _point(model.get("head_pivot",[0,0,0])),
            _string(model.get("description","")), _boolean(figure)]))
        lines.extend("                " + _emit_part(part, figure) for part in model["parts"])
        lines.append("                f.finishModel()")
    lines.append('''                f.validateAll()
                select f.roots
            )
            catch
            (
                local err=getCurrentException()
                f.cleanup()
                select (for n in previousSelection where isValidNode n collect n)
                throw err
            )
        )
    )
    redrawViews()
    f.roots
)
''')
    text = "\n".join(lines)
    _lexical_check(text)
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8-sig")
    return path
