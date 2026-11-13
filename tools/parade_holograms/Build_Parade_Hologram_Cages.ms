/* MOSAIC PARADE HOLOGRAMS / EDITABLE SPLINE CAGE MASTER
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

MPHC_Palette=#(
    #("cream",#(0.222290039,0.483032227,0.231811523,0.492553711),[177.133,176.541,163.826],false,12),
    #("cyan_glow",#(0.31262207,0.814575195,0.363647461,0.836303711),[53.825608466,211.353227513,251.68010582],true,12),
    #("dark",#(0.225219727,0.110961914,0.234741211,0.120483398),[32.248,28.982,33.107],false,12),
    #("gold_glow",#(0.328491211,0.932983398,0.341674805,0.955932617),[239.050334928,161.391004785,28.642870813],true,12),
    #("green_glow",#(0.630493164,0.837524414,0.640014648,0.847045898),[110.32,141.964,50.121],true,12),
    #("ivory_glow",#(0.23449707,0.97277832,0.245239258,0.997924805),[250.608119658,238.373717949,193.500641026],true,12),
    #("orange_glow",#(0.342407227,0.932983398,0.361206055,0.955932617),[245.092037787,108.443184885,65.815249663],true,12),
    #("pink_glow",#(0.247680664,0.820922852,0.257202148,0.830444336),[254.919,131.348,173.038],true,12),
    #("red_glow",#(0.164672852,0.839477539,0.174194336,0.848999023),[225.0,63.0,44.0],true,12),
    #("teal",#(0.489379883,0.258911133,0.493041992,0.262573242),[18.676,99.828,71.523],false,8),
    #("violet_glow",#(0.300415039,0.895141602,0.363647461,0.915649414),[116.96561086,15.791809955,231.438190045],true,12)
)
MPHC_DiffuseFile="house_asian_diffuse.dds"
MPHC_PackedFile="house_asian_selfilu_reflection.png"
MPHC_DiffuseSHA256="818da3a29085fdbd61eb90d23aad57fb722868d8d0421df958b7f941c90ddff9"
MPHC_PackedSHA256="d9be7dad2062f36e69bbe7adf8cb2679bb3dbe22262f46cac333051c4ae3e406"
MPHC_AtlasDimensions=#(4096,4096)
if MPHC_LayoutStep == undefined do MPHC_LayoutStep=[12.2,10.0,0.0]
(
    local folder=getFilenamePath (getSourceFileName())
    local previousSelection=selection as array
    local f=MPHC_Builder()
    local wanted=#("paradecivilian1","paradecivilian1__body","paradecivilian1__head","paradecivilian1__mask","paradecivilian1_LeftShoe","paradecivilian1_RightShoe","paradecivilian1_LeftTrouser","paradecivilian1_RightTrouser","paradecivilian1_LongRaincoat","paradecivilian1_LeftSleeve","paradecivilian1_LeftHand","paradecivilian1_RightSleeve","paradecivilian1_RightHand","paradecivilian1_HighCollar","paradecivilian1_Neck","paradecivilian1_Head","paradecivilian1_FacePlate","paradecivilian1_EyeLeft","paradecivilian1_EyeRight","paradecivilian1_SingleLapel","paradecivilian1_RaincoatHem","paradecivilian2","paradecivilian2__body","paradecivilian2__head","paradecivilian2__mask","paradecivilian2_LeftBoot","paradecivilian2_RightBoot","paradecivilian2_LeftTrouser","paradecivilian2_RightTrouser","paradecivilian2_ShortJacket","paradecivilian2_PocketArm","paradecivilian2_WavingSleeve","paradecivilian2_WavingHand","paradecivilian2_RolledCollar","paradecivilian2_Head","paradecivilian2_FacePlate","paradecivilian2_EyeLeft","paradecivilian2_EyeRight","paradecivilian2_JacketSeam","paradecivilian2_RaisedCuff","paradecivilian3","paradecivilian3__body","paradecivilian3__head","paradecivilian3__mask","paradecivilian3_ForwardShoe","paradecivilian3_BackShoe","paradecivilian3_LeftLeg","paradecivilian3_RightLeg","paradecivilian3_AsymmetricPoncho","paradecivilian3_LeftArm","paradecivilian3_LeftHand","paradecivilian3_RightArm","paradecivilian3_StrapHand","paradecivilian3_MessengerBag","paradecivilian3_DiagonalStrap","paradecivilian3_Head","paradecivilian3_FacePlate","paradecivilian3_EyeLeft","paradecivilian3_EyeRight","paradecivilian3_QuietMouth","paradecivilian3_ModernCap","paradecivilian3_CapPeak","paradecivilian3_PonchoCorner","paradecivilian4","paradecivilian4__body","paradecivilian4__head","paradecivilian4__mask","paradecivilian4_LeftShoe","paradecivilian4_RightShoe","paradecivilian4_LeftLeg","paradecivilian4_RightLeg","paradecivilian4_FittedCoat","paradecivilian4_PoleArm","paradecivilian4_PoleHand","paradecivilian4_RelaxedArm","paradecivilian4_RelaxedHand","paradecivilian4_Head","paradecivilian4_FacePlate","paradecivilian4_EyeLeft","paradecivilian4_EyeRight","paradecivilian4_UmbrellaHandle","paradecivilian4_UmbrellaCanopy","paradecivilian4_UmbrellaFrontRib","paradecivilian4_CoatOpening","paradedead1","paradedead1__body","paradedead1__head","paradedead1__mask","paradedead1_LeftOldShoe","paradedead1_RightOldShoe","paradedead1_LeftTrouser","paradedead1_RightTrouser","paradedead1_FrockCoat","paradedead1_CaneSleeve","paradedead1_CaneHand","paradedead1_Cane","paradedead1_RestingSleeve","paradedead1_RestingHand","paradedead1_Head","paradedead1_FacePlate","paradedead1_EyeLeft","paradedead1_EyeRight","paradedead1_QuietMouth","paradedead1_BowlerBrim","paradedead1_BowlerCrown","paradedead1_OldLapel","paradedead2","paradedead2__body","paradedead2__head","paradedead2__mask","paradedead2_HiddenLeftShoe","paradedead2_HiddenRightShoe","paradedead2_BellDress","paradedead2_Shawl","paradedead2_LeftFoldedArm","paradedead2_LeftHand","paradedead2_RightFoldedArm","paradedead2_RightHand","paradedead2_Head","paradedead2_FacePlate","paradedead2_EyeLeft","paradedead2_EyeRight","paradedead2_WideHatBrim","paradedead2_HatCrown","paradedead2_HatFlower","paradedead2_ShawlEdge","paradedead3","paradedead3__body","paradedead3__head","paradedead3__mask","paradedead3_LeftSlipper","paradedead3_RightSlipper","paradedead3_LongWrappedRobe","paradedead3_RobeSash","paradedead3_LeftWideSleeve","paradedead3_RightWideSleeve","paradedead3_JoinedHands","paradedead3_BentNeck","paradedead3_Head","paradedead3_FacePlate","paradedead3_EyeLeft","paradedead3_EyeRight","paradedead3_RearHairKnot","paradedead3_OldSkullCap","paradedead3_RobeCrossing","paradedead4","paradedead4__body","paradedead4__head","paradedead4__mask","paradedead4_LeftBoot","paradedead4_RightBoot","paradedead4_LeftLeg","paradedead4_RightLeg","paradedead4_TravellingGreatcoat","paradedead4_ShoulderCape","paradedead4_LeftCrossedSleeve","paradedead4_RightCrossedSleeve","paradedead4_Head","paradedead4_FacePlate","paradedead4_EyeLeft","paradedead4_EyeRight","paradedead4_QuietMouth","paradedead4_TallHatBrim","paradedead4_TallHatCrown","paradedead4_TrailingScarf","paradedead4_CapeEdge","paradeai1","paradeai1__body","paradeai1__head","paradeai1__mask","paradeai1_LeftMantle","paradeai1_RightMantle","paradeai1_MantleBack","paradeai1_QuietShoulders","paradeai1_ThinNeck","paradeai1_Head","paradeai1_MaskLeft","paradeai1_MaskRight","paradeai1_EyeLeft","paradeai1_EyeRight","paradeai1_ChestLantern","paradeai1_LanternCap","paradeai1_LanternBase","paradeai1_LanternSuspension","paradeai1_LeftInnerEdge","paradeai1_RightInnerEdge","paradeai2","paradeai2__body","paradeai2__head","paradeai2__mask","paradeai2_BellMantle","paradeai2_CeremonialCollar","paradeai2_SlenderNeck","paradeai2_Head","paradeai2_FacePlate","paradeai2_EyeLeft","paradeai2_EyeRight","paradeai2_QuietMouth","paradeai2_WideCollarEdge","paradeai2_BellFrontHem","paradeai3","paradeai3__body","paradeai3__head","paradeai3__mask","paradeai3_PilgrimStem","paradeai3_LeftHangingSleeve","paradeai3_RightOfferingSleeve","paradeai3_OfferingPalm","paradeai3_PilgrimNeck","paradeai3_Head","paradeai3_FacePlate","paradeai3_EyeLeft","paradeai3_EyeRight","paradeai3_ThirdEye","paradeai3_CrownArc","paradeai3_SleeveEdge","paradeai3_HeldLight","paradeai4","paradeai4__body","paradeai4__head","paradeai4__mask","paradeai4_FoldedSail","paradeai4_LeftTrailingFold","paradeai4_RightLiftedFold","paradeai4_CurvedNeck","paradeai4_Head","paradeai4_FacePlate","paradeai4_EyeLeft","paradeai4_EyeRight","paradeai4_SailFold","paradeai4_SleeveTip","paradehelper1","paradehelper1__body","paradehelper1__head","paradehelper1__mask","paradehelper1_LeftFoot","paradehelper1_RightFoot","paradehelper1_LeftLeg","paradehelper1_RightLeg","paradehelper1_PearBody","paradehelper1_NearArm","paradehelper1_FarArm","paradehelper1_NearHand","paradehelper1_FarHand","paradehelper1_Head","paradehelper1_FacePlate","paradehelper1_EyeLeft","paradehelper1_EyeRight","paradehelper1_SmallMouth","paradehelper1_LanternTassel","paradehelper1_SmallLantern","paradehelper1_LanternTop","paradehelper1_LanternBottom","paradehelper2","paradehelper2__body","paradehelper2__head","paradehelper2__mask","paradehelper2_TuckedFoot","paradehelper2_KneelingFoot","paradehelper2_LeftKnee","paradehelper2_BentShin","paradehelper2_CrouchedBody","paradehelper2_WorkingArm","paradehelper2_HoldingArm","paradehelper2_WorkingHand","paradehelper2_HoldingHand","paradehelper2_Head","paradehelper2_FacePlate","paradehelper2_EyeLeft","paradehelper2_EyeRight","paradehelper2_SmallMouth","paradehelper2_RepairThread","paradehelper2_FirstStitch","paradehelper2_SecondStitch","paradehelper3","paradehelper3__body","paradehelper3__head","paradehelper3__mask","paradehelper3_PlantedFoot","paradehelper3_LiftedFoot","paradehelper3_PlantedLeg","paradehelper3_LiftedLeg","paradehelper3_RoundBody","paradehelper3_LeftRaisedArm","paradehelper3_RightRaisedArm","paradehelper3_LeftHand","paradehelper3_RightHand","paradehelper3_Head","paradehelper3_FacePlate","paradehelper3_EyeLeft","paradehelper3_EyeRight","paradehelper3_SmallMouth","paradehelper3_CraneBody","paradehelper3_CraneLeftWing","paradehelper3_CraneRightWing","paradehelper3_CraneNeck","paradehelper4","paradehelper4__body","paradehelper4__head","paradehelper4__mask","paradehelper4_LeftFoot","paradehelper4_RightFoot","paradehelper4_LeftLeg","paradehelper4_RightLeg","paradehelper4_SmallBody","paradehelper4_LongNeck","paradehelper4_LeftBehindArm","paradehelper4_RightBehindArm","paradehelper4_JoinedHands","paradehelper4_Head","paradehelper4_FacePlate","paradehelper4_EyeLeft","paradehelper4_EyeRight","paradehelper4_SmallMouth","paradecandle","paradecandle__body","paradecandle_Holder","paradecandle_Wax","paradecandle_Wick","paradecandle_Flame","paradecandle_FlameHeart","paradelantern","paradelantern__body","paradelantern_PaperShell","paradelantern_BottomRim","paradelantern_TopRim","paradelantern_PaperRib0","paradelantern_PaperRib1","paradelantern_PaperRib2","paradelantern_PaperRib3","paradelantern_PaperRib4","paradelantern_PaperRib5","paradelantern_Tassel","parademoon","parademoon__body","parademoon_Crescent","paradeenvelope","paradeenvelope__body","paradeenvelope_Paper","paradeenvelope_Fold","paradeenvelope_LowerFold","paradeenvelope_Seal","parademoney","parademoney__body","parademoney_Banknote","parademoney_Border","parademoney_LeadingOne","parademoney_Zero0","parademoney_Zero1","parademoney_Zero2","parademoney_Zero3","parademoney_Zero4","parademoney_Zero5","paradekoi","paradekoi__body","paradekoi_Body","paradekoi_HeadPatch","paradekoi_BackPatch","paradekoi_Tail0","paradekoi_Tail1","paradekoi_Fin0","paradekoi_Eye0","paradekoi_Fin1","paradekoi_Eye1","paradelotus","paradelotus__body","paradelotus_Petal0_0","paradelotus_Petal0_1","paradelotus_Petal0_2","paradelotus_Petal0_3","paradelotus_Petal0_4","paradelotus_Petal0_5","paradelotus_Petal1_0","paradelotus_Petal1_1","paradelotus_Petal1_2","paradelotus_Petal1_3","paradelotus_Petal1_4","paradelotus_Petal1_5","paradelotus_Heart","paradeleaf","paradeleaf__body","paradeleaf_Blade","paradeleaf_Vein","paradeleaf_Branch0_L","paradeleaf_Branch0_R","paradeleaf_Branch1_L","paradeleaf_Branch1_R","paradeleaf_Branch2_L","paradeleaf_Branch2_R","paradestar","paradestar__body","paradestar_Star","paradecloud","paradecloud__body","paradecloud_Lobe0","paradecloud_Lobe1","paradecloud_Lobe2","paradepinwheel","paradepinwheel__body","paradepinwheel_Stem","paradepinwheel_Blade0","paradepinwheel_Blade1","paradepinwheel_Blade2","paradepinwheel_Blade3","paradepinwheel_Hub","parademoth","parademoth__body","parademoth_Body","parademoth_ForewingL","parademoth_HindwingL","parademoth_AntennaL","parademoth_ForewingR","parademoth_HindwingR","parademoth_AntennaR")
    for name in wanted where (getNodeByName name exact:true) != undefined do
        throw ("Source node already exists: "+name+". Undo the previous build or use a clean scene; existing work is preserved.")
    undo "Build MOSAIC parade spline cages" on
    (
        with redraw off
        (
            try
            (
                f.prepare folder
                f.startModel "paradecivilian1" "The coat commuter" "civilian" 1 0.23 [0.0,0.0,6.18] "Narrow modern raincoat, visible shoes and quietly clasped hands." true
                f.cage "LeftShoe" #(
                    #(true,true,#([-0.676274,0.207696,0.21],[-0.676274,0.1,0.315],[-0.676274,-0.16,0.358492],[-0.676274,-0.42,0.315],[-0.676274,-0.527696,0.21],[-0.676274,-0.42,0.105],[-0.676274,-0.16,0.061508],[-0.676274,0.1,0.105])),
                    #(true,true,#([-0.45,0.36,0.21],[-0.45,0.207696,0.358492],[-0.45,-0.16,0.42],[-0.45,-0.527696,0.358492],[-0.45,-0.68,0.21],[-0.45,-0.527696,0.061508],[-0.45,-0.16,0.0],[-0.45,0.207696,0.061508])),
                    #(true,true,#([-0.223726,0.207696,0.21],[-0.223726,0.1,0.315],[-0.223726,-0.16,0.358492],[-0.223726,-0.42,0.315],[-0.223726,-0.527696,0.21],[-0.223726,-0.42,0.105],[-0.223726,-0.16,0.061508],[-0.223726,0.1,0.105])),
                    #(false,true,#([-0.77,-0.16,0.21],[-0.676274,0.207696,0.21],[-0.45,0.36,0.21],[-0.223726,0.207696,0.21],[-0.13,-0.16,0.21])),
                    #(false,true,#([-0.77,-0.16,0.21],[-0.676274,0.1,0.315],[-0.45,0.207696,0.358492],[-0.223726,0.1,0.315],[-0.13,-0.16,0.21])),
                    #(false,true,#([-0.77,-0.16,0.21],[-0.676274,-0.16,0.358492],[-0.45,-0.16,0.42],[-0.223726,-0.16,0.358492],[-0.13,-0.16,0.21])),
                    #(false,true,#([-0.77,-0.16,0.21],[-0.676274,-0.42,0.315],[-0.45,-0.527696,0.358492],[-0.223726,-0.42,0.315],[-0.13,-0.16,0.21])),
                    #(false,true,#([-0.77,-0.16,0.21],[-0.676274,-0.527696,0.21],[-0.45,-0.68,0.21],[-0.223726,-0.527696,0.21],[-0.13,-0.16,0.21])),
                    #(false,true,#([-0.77,-0.16,0.21],[-0.676274,-0.42,0.105],[-0.45,-0.527696,0.061508],[-0.223726,-0.42,0.105],[-0.13,-0.16,0.21])),
                    #(false,true,#([-0.77,-0.16,0.21],[-0.676274,-0.16,0.061508],[-0.45,-0.16,0.0],[-0.223726,-0.16,0.061508],[-0.13,-0.16,0.21])),
                    #(false,true,#([-0.77,-0.16,0.21],[-0.676274,0.1,0.105],[-0.45,0.207696,0.061508],[-0.223726,0.1,0.105],[-0.13,-0.16,0.21]))
                ) "dark" "body" true 0.0
                f.cage "RightShoe" #(
                    #(true,true,#([0.223726,0.347696,0.21],[0.223726,0.24,0.315],[0.223726,-0.02,0.358492],[0.223726,-0.28,0.315],[0.223726,-0.387696,0.21],[0.223726,-0.28,0.105],[0.223726,-0.02,0.061508],[0.223726,0.24,0.105])),
                    #(true,true,#([0.45,0.5,0.21],[0.45,0.347696,0.358492],[0.45,-0.02,0.42],[0.45,-0.387696,0.358492],[0.45,-0.54,0.21],[0.45,-0.387696,0.061508],[0.45,-0.02,0.0],[0.45,0.347696,0.061508])),
                    #(true,true,#([0.676274,0.347696,0.21],[0.676274,0.24,0.315],[0.676274,-0.02,0.358492],[0.676274,-0.28,0.315],[0.676274,-0.387696,0.21],[0.676274,-0.28,0.105],[0.676274,-0.02,0.061508],[0.676274,0.24,0.105])),
                    #(false,true,#([0.13,-0.02,0.21],[0.223726,0.347696,0.21],[0.45,0.5,0.21],[0.676274,0.347696,0.21],[0.77,-0.02,0.21])),
                    #(false,true,#([0.13,-0.02,0.21],[0.223726,0.24,0.315],[0.45,0.347696,0.358492],[0.676274,0.24,0.315],[0.77,-0.02,0.21])),
                    #(false,true,#([0.13,-0.02,0.21],[0.223726,-0.02,0.358492],[0.45,-0.02,0.42],[0.676274,-0.02,0.358492],[0.77,-0.02,0.21])),
                    #(false,true,#([0.13,-0.02,0.21],[0.223726,-0.28,0.315],[0.45,-0.387696,0.358492],[0.676274,-0.28,0.315],[0.77,-0.02,0.21])),
                    #(false,true,#([0.13,-0.02,0.21],[0.223726,-0.387696,0.21],[0.45,-0.54,0.21],[0.676274,-0.387696,0.21],[0.77,-0.02,0.21])),
                    #(false,true,#([0.13,-0.02,0.21],[0.223726,-0.28,0.105],[0.45,-0.387696,0.061508],[0.676274,-0.28,0.105],[0.77,-0.02,0.21])),
                    #(false,true,#([0.13,-0.02,0.21],[0.223726,-0.02,0.061508],[0.45,-0.02,0.0],[0.676274,-0.02,0.061508],[0.77,-0.02,0.21])),
                    #(false,true,#([0.13,-0.02,0.21],[0.223726,0.24,0.105],[0.45,0.347696,0.061508],[0.676274,0.24,0.105],[0.77,-0.02,0.21]))
                ) "dark" "body" true 0.0
                f.cage "LeftTrouser" #(
                    #(true,true,#([-0.72,0.0,0.28],[-0.640919,-0.190893,0.283129],[-0.45,-0.269964,0.284426],[-0.259081,-0.190893,0.283129],[-0.18,0.0,0.28],[-0.259081,0.190893,0.276871],[-0.45,0.269964,0.275574],[-0.640919,0.190893,0.276871])),
                    #(true,true,#([-0.749717,0.020118,1.513028],[-0.661999,-0.192048,1.509591],[-0.450095,-0.28,1.500536],[-0.238135,-0.192215,1.491167],[-0.150283,0.019882,1.486972],[-0.238001,0.232048,1.490409],[-0.449905,0.32,1.499464],[-0.661865,0.232215,1.508833])),
                    #(true,true,#([-0.653718,0.000052,3.079502],[-0.554815,-0.240359,3.067786],[-0.315431,-0.339972,3.045651],[-0.075795,-0.240433,3.026064],[0.023718,-0.000052,3.020498],[-0.075185,0.240359,3.032214],[-0.314569,0.339972,3.054349],[-0.554205,0.240433,3.073936])),
                    #(false,true,#([-0.45,0.0,0.28],[-0.72,0.0,0.28],[-0.749717,0.020118,1.513028],[-0.653718,0.000052,3.079502],[-0.315,0.0,3.05])),
                    #(false,true,#([-0.45,0.0,0.28],[-0.640919,-0.190893,0.283129],[-0.661999,-0.192048,1.509591],[-0.554815,-0.240359,3.067786],[-0.315,0.0,3.05])),
                    #(false,true,#([-0.45,0.0,0.28],[-0.45,-0.269964,0.284426],[-0.450095,-0.28,1.500536],[-0.315431,-0.339972,3.045651],[-0.315,0.0,3.05])),
                    #(false,true,#([-0.45,0.0,0.28],[-0.259081,-0.190893,0.283129],[-0.238135,-0.192215,1.491167],[-0.075795,-0.240433,3.026064],[-0.315,0.0,3.05])),
                    #(false,true,#([-0.45,0.0,0.28],[-0.18,0.0,0.28],[-0.150283,0.019882,1.486972],[0.023718,-0.000052,3.020498],[-0.315,0.0,3.05])),
                    #(false,true,#([-0.45,0.0,0.28],[-0.259081,0.190893,0.276871],[-0.238001,0.232048,1.490409],[-0.075185,0.240359,3.032214],[-0.315,0.0,3.05])),
                    #(false,true,#([-0.45,0.0,0.28],[-0.45,0.269964,0.275574],[-0.449905,0.32,1.499464],[-0.314569,0.339972,3.054349],[-0.315,0.0,3.05])),
                    #(false,true,#([-0.45,0.0,0.28],[-0.640919,0.190893,0.276871],[-0.661865,0.232215,1.508833],[-0.554205,0.240433,3.073936],[-0.315,0.0,3.05]))
                ) "dark" "body" true 0.0
                f.cage "RightTrouser" #(
                    #(true,true,#([0.18,0.0,0.28],[0.259081,-0.190893,0.283129],[0.45,-0.269964,0.284426],[0.640919,-0.190893,0.283129],[0.72,0.0,0.28],[0.640919,0.190893,0.276871],[0.45,0.269964,0.275574],[0.259081,0.190893,0.276871])),
                    #(true,true,#([0.150283,0.019882,1.486972],[0.238135,-0.192215,1.491167],[0.450095,-0.28,1.500536],[0.661999,-0.192048,1.509591],[0.749717,0.020118,1.513028],[0.661865,0.232215,1.508833],[0.449905,0.32,1.499464],[0.238001,0.232048,1.490409])),
                    #(true,true,#([-0.023718,-0.000052,3.020498],[0.075795,-0.240433,3.026064],[0.315431,-0.339972,3.045651],[0.554815,-0.240359,3.067786],[0.653718,0.000052,3.079502],[0.554205,0.240433,3.073936],[0.314569,0.339972,3.054349],[0.075185,0.240359,3.032214])),
                    #(false,true,#([0.45,0.0,0.28],[0.18,0.0,0.28],[0.150283,0.019882,1.486972],[-0.023718,-0.000052,3.020498],[0.315,0.0,3.05])),
                    #(false,true,#([0.45,0.0,0.28],[0.259081,-0.190893,0.283129],[0.238135,-0.192215,1.491167],[0.075795,-0.240433,3.026064],[0.315,0.0,3.05])),
                    #(false,true,#([0.45,0.0,0.28],[0.45,-0.269964,0.284426],[0.450095,-0.28,1.500536],[0.315431,-0.339972,3.045651],[0.315,0.0,3.05])),
                    #(false,true,#([0.45,0.0,0.28],[0.640919,-0.190893,0.283129],[0.661999,-0.192048,1.509591],[0.554815,-0.240359,3.067786],[0.315,0.0,3.05])),
                    #(false,true,#([0.45,0.0,0.28],[0.72,0.0,0.28],[0.749717,0.020118,1.513028],[0.653718,0.000052,3.079502],[0.315,0.0,3.05])),
                    #(false,true,#([0.45,0.0,0.28],[0.640919,0.190893,0.276871],[0.661865,0.232215,1.508833],[0.554205,0.240433,3.073936],[0.315,0.0,3.05])),
                    #(false,true,#([0.45,0.0,0.28],[0.45,0.269964,0.275574],[0.449905,0.32,1.499464],[0.314569,0.339972,3.054349],[0.315,0.0,3.05])),
                    #(false,true,#([0.45,0.0,0.28],[0.259081,0.190893,0.276871],[0.238001,0.232048,1.490409],[0.075185,0.240359,3.032214],[0.315,0.0,3.05]))
                ) "dark" "body" true 0.0
                f.cage "LongRaincoat" #(
                    #(true,true,#([1.05,0.0,0.9],[0.742462,0.410122,0.9],[0.0,0.58,0.9],[-0.742462,0.410122,0.9],[-1.05,0.0,0.9],[-0.742462,-0.410122,0.9],[0.0,-0.58,0.9],[0.742462,-0.410122,0.9])),
                    #(true,true,#([1.03,0.0,2.5],[0.72832,0.424264,2.5],[0.0,0.6,2.5],[-0.72832,0.424264,2.5],[-1.03,0.0,2.5],[-0.72832,-0.424264,2.5],[0.0,-0.6,2.5],[0.72832,-0.424264,2.5])),
                    #(true,true,#([0.82,0.0,4.4],[0.579828,0.388909,4.4],[0.0,0.55,4.4],[-0.579828,0.388909,4.4],[-0.82,0.0,4.4],[-0.579828,-0.388909,4.4],[0.0,-0.55,4.4],[0.579828,-0.388909,4.4])),
                    #(true,true,#([0.97,0.0,5.7],[0.685894,0.374767,5.7],[0.0,0.53,5.7],[-0.685894,0.374767,5.7],[-0.97,0.0,5.7],[-0.685894,-0.374767,5.7],[0.0,-0.53,5.7],[0.685894,-0.374767,5.7])),
                    #(true,true,#([0.52,0.0,6.0],[0.367696,0.282843,6.0],[0.0,0.4,6.0],[-0.367696,0.282843,6.0],[-0.52,0.0,6.0],[-0.367696,-0.282843,6.0],[0.0,-0.4,6.0],[0.367696,-0.282843,6.0])),
                    #(false,true,#([0.0,0.0,0.9],[1.05,0.0,0.9],[1.03,0.0,2.5],[0.82,0.0,4.4],[0.97,0.0,5.7],[0.52,0.0,6.0],[0.0,0.0,6.0])),
                    #(false,true,#([0.0,0.0,0.9],[0.742462,0.410122,0.9],[0.72832,0.424264,2.5],[0.579828,0.388909,4.4],[0.685894,0.374767,5.7],[0.367696,0.282843,6.0],[0.0,0.0,6.0])),
                    #(false,true,#([0.0,0.0,0.9],[0.0,0.58,0.9],[0.0,0.6,2.5],[0.0,0.55,4.4],[0.0,0.53,5.7],[0.0,0.4,6.0],[0.0,0.0,6.0])),
                    #(false,true,#([0.0,0.0,0.9],[-0.742462,0.410122,0.9],[-0.72832,0.424264,2.5],[-0.579828,0.388909,4.4],[-0.685894,0.374767,5.7],[-0.367696,0.282843,6.0],[0.0,0.0,6.0])),
                    #(false,true,#([0.0,0.0,0.9],[-1.05,0.0,0.9],[-1.03,0.0,2.5],[-0.82,0.0,4.4],[-0.97,0.0,5.7],[-0.52,0.0,6.0],[0.0,0.0,6.0])),
                    #(false,true,#([0.0,0.0,0.9],[-0.742462,-0.410122,0.9],[-0.72832,-0.424264,2.5],[-0.579828,-0.388909,4.4],[-0.685894,-0.374767,5.7],[-0.367696,-0.282843,6.0],[0.0,0.0,6.0])),
                    #(false,true,#([0.0,0.0,0.9],[0.0,-0.58,0.9],[0.0,-0.6,2.5],[0.0,-0.55,4.4],[0.0,-0.53,5.7],[0.0,-0.4,6.0],[0.0,0.0,6.0])),
                    #(false,true,#([0.0,0.0,0.9],[0.742462,-0.410122,0.9],[0.72832,-0.424264,2.5],[0.579828,-0.388909,4.4],[0.685894,-0.374767,5.7],[0.367696,-0.282843,6.0],[0.0,0.0,6.0]))
                ) "dark" "body" true 0.0
                f.cage "LeftSleeve" #(
                    #(true,true,#([-0.466991,0.0,5.579398],[-0.559977,-0.248965,5.652118],[-0.805281,-0.352089,5.723597],[-1.059207,-0.248965,5.751964],[-1.173009,0.0,5.720602],[-1.080023,0.248965,5.647882],[-0.834719,0.352089,5.576403],[-0.580793,0.248965,5.548036])),
                    #(true,true,#([-0.763948,-0.207902,4.580014],[-0.841198,-0.416606,4.636544],[-1.040762,-0.527715,4.613089],[-1.245736,-0.476142,4.523387],[-1.336052,-0.292098,4.419986],[-1.258802,-0.083394,4.363456],[-1.059238,0.027715,4.386911],[-0.854264,-0.023858,4.476613])),
                    #(true,true,#([-0.088998,-0.6244,3.995818],[-0.146514,-0.785676,4.036682],[-0.264651,-0.896765,3.96819],[-0.374205,-0.892591,3.830464],[-0.411002,-0.7756,3.704182],[-0.353486,-0.614324,3.663318],[-0.235349,-0.503235,3.73181],[-0.125795,-0.507409,3.869536])),
                    #(false,true,#([-0.82,0.0,5.65],[-0.466991,0.0,5.579398],[-0.763948,-0.207902,4.580014],[-0.088998,-0.6244,3.995818],[-0.25,-0.7,3.85])),
                    #(false,true,#([-0.82,0.0,5.65],[-0.559977,-0.248965,5.652118],[-0.841198,-0.416606,4.636544],[-0.146514,-0.785676,4.036682],[-0.25,-0.7,3.85])),
                    #(false,true,#([-0.82,0.0,5.65],[-0.805281,-0.352089,5.723597],[-1.040762,-0.527715,4.613089],[-0.264651,-0.896765,3.96819],[-0.25,-0.7,3.85])),
                    #(false,true,#([-0.82,0.0,5.65],[-1.059207,-0.248965,5.751964],[-1.245736,-0.476142,4.523387],[-0.374205,-0.892591,3.830464],[-0.25,-0.7,3.85])),
                    #(false,true,#([-0.82,0.0,5.65],[-1.173009,0.0,5.720602],[-1.336052,-0.292098,4.419986],[-0.411002,-0.7756,3.704182],[-0.25,-0.7,3.85])),
                    #(false,true,#([-0.82,0.0,5.65],[-1.080023,0.248965,5.647882],[-1.258802,-0.083394,4.363456],[-0.353486,-0.614324,3.663318],[-0.25,-0.7,3.85])),
                    #(false,true,#([-0.82,0.0,5.65],[-0.834719,0.352089,5.576403],[-1.059238,0.027715,4.386911],[-0.235349,-0.503235,3.73181],[-0.25,-0.7,3.85])),
                    #(false,true,#([-0.82,0.0,5.65],[-0.580793,0.248965,5.548036],[-0.854264,-0.023858,4.476613],[-0.125795,-0.507409,3.869536],[-0.25,-0.7,3.85]))
                ) "dark" "body" true 0.0
                f.cage "LeftHand" #(
                    #(true,true,#([-0.382635,-0.58565,3.83],[-0.382635,-0.625,3.975],[-0.382635,-0.72,4.035061],[-0.382635,-0.815,3.975],[-0.382635,-0.85435,3.83],[-0.382635,-0.815,3.685],[-0.382635,-0.72,3.624939],[-0.382635,-0.625,3.685])),
                    #(true,true,#([-0.22,-0.53,3.83],[-0.22,-0.58565,4.035061],[-0.22,-0.72,4.12],[-0.22,-0.85435,4.035061],[-0.22,-0.91,3.83],[-0.22,-0.85435,3.624939],[-0.22,-0.72,3.54],[-0.22,-0.58565,3.624939])),
                    #(true,true,#([-0.057365,-0.58565,3.83],[-0.057365,-0.625,3.975],[-0.057365,-0.72,4.035061],[-0.057365,-0.815,3.975],[-0.057365,-0.85435,3.83],[-0.057365,-0.815,3.685],[-0.057365,-0.72,3.624939],[-0.057365,-0.625,3.685])),
                    #(false,true,#([-0.45,-0.72,3.83],[-0.382635,-0.58565,3.83],[-0.22,-0.53,3.83],[-0.057365,-0.58565,3.83],[0.01,-0.72,3.83])),
                    #(false,true,#([-0.45,-0.72,3.83],[-0.382635,-0.625,3.975],[-0.22,-0.58565,4.035061],[-0.057365,-0.625,3.975],[0.01,-0.72,3.83])),
                    #(false,true,#([-0.45,-0.72,3.83],[-0.382635,-0.72,4.035061],[-0.22,-0.72,4.12],[-0.057365,-0.72,4.035061],[0.01,-0.72,3.83])),
                    #(false,true,#([-0.45,-0.72,3.83],[-0.382635,-0.815,3.975],[-0.22,-0.85435,4.035061],[-0.057365,-0.815,3.975],[0.01,-0.72,3.83])),
                    #(false,true,#([-0.45,-0.72,3.83],[-0.382635,-0.85435,3.83],[-0.22,-0.91,3.83],[-0.057365,-0.85435,3.83],[0.01,-0.72,3.83])),
                    #(false,true,#([-0.45,-0.72,3.83],[-0.382635,-0.815,3.685],[-0.22,-0.85435,3.624939],[-0.057365,-0.815,3.685],[0.01,-0.72,3.83])),
                    #(false,true,#([-0.45,-0.72,3.83],[-0.382635,-0.72,3.624939],[-0.22,-0.72,3.54],[-0.057365,-0.72,3.624939],[0.01,-0.72,3.83])),
                    #(false,true,#([-0.45,-0.72,3.83],[-0.382635,-0.625,3.685],[-0.22,-0.58565,3.624939],[-0.057365,-0.625,3.685],[0.01,-0.72,3.83]))
                ) "teal" "body" true 0.0
                f.cage "RightSleeve" #(
                    #(true,true,#([1.173009,0.0,5.720602],[1.059207,-0.248965,5.751964],[0.805281,-0.352089,5.723597],[0.559977,-0.248965,5.652118],[0.466991,0.0,5.579398],[0.580793,0.248965,5.548036],[0.834719,0.352089,5.576403],[1.080023,0.248965,5.647882])),
                    #(true,true,#([1.336052,-0.292098,4.419986],[1.245736,-0.476142,4.523387],[1.040762,-0.527715,4.613089],[0.841198,-0.416606,4.636544],[0.763948,-0.207902,4.580014],[0.854264,-0.023858,4.476613],[1.059238,0.027715,4.386911],[1.258802,-0.083394,4.363456])),
                    #(true,true,#([0.411002,-0.7756,3.704182],[0.374205,-0.892591,3.830464],[0.264651,-0.896765,3.96819],[0.146514,-0.785676,4.036682],[0.088998,-0.6244,3.995818],[0.125795,-0.507409,3.869536],[0.235349,-0.503235,3.73181],[0.353486,-0.614324,3.663318])),
                    #(false,true,#([0.82,0.0,5.65],[1.173009,0.0,5.720602],[1.336052,-0.292098,4.419986],[0.411002,-0.7756,3.704182],[0.25,-0.7,3.85])),
                    #(false,true,#([0.82,0.0,5.65],[1.059207,-0.248965,5.751964],[1.245736,-0.476142,4.523387],[0.374205,-0.892591,3.830464],[0.25,-0.7,3.85])),
                    #(false,true,#([0.82,0.0,5.65],[0.805281,-0.352089,5.723597],[1.040762,-0.527715,4.613089],[0.264651,-0.896765,3.96819],[0.25,-0.7,3.85])),
                    #(false,true,#([0.82,0.0,5.65],[0.559977,-0.248965,5.652118],[0.841198,-0.416606,4.636544],[0.146514,-0.785676,4.036682],[0.25,-0.7,3.85])),
                    #(false,true,#([0.82,0.0,5.65],[0.466991,0.0,5.579398],[0.763948,-0.207902,4.580014],[0.088998,-0.6244,3.995818],[0.25,-0.7,3.85])),
                    #(false,true,#([0.82,0.0,5.65],[0.580793,0.248965,5.548036],[0.854264,-0.023858,4.476613],[0.125795,-0.507409,3.869536],[0.25,-0.7,3.85])),
                    #(false,true,#([0.82,0.0,5.65],[0.834719,0.352089,5.576403],[1.059238,0.027715,4.386911],[0.235349,-0.503235,3.73181],[0.25,-0.7,3.85])),
                    #(false,true,#([0.82,0.0,5.65],[1.080023,0.248965,5.647882],[1.258802,-0.083394,4.363456],[0.353486,-0.614324,3.663318],[0.25,-0.7,3.85]))
                ) "dark" "body" true 0.0
                f.cage "RightHand" #(
                    #(true,true,#([0.057365,-0.58565,3.83],[0.057365,-0.625,3.975],[0.057365,-0.72,4.035061],[0.057365,-0.815,3.975],[0.057365,-0.85435,3.83],[0.057365,-0.815,3.685],[0.057365,-0.72,3.624939],[0.057365,-0.625,3.685])),
                    #(true,true,#([0.22,-0.53,3.83],[0.22,-0.58565,4.035061],[0.22,-0.72,4.12],[0.22,-0.85435,4.035061],[0.22,-0.91,3.83],[0.22,-0.85435,3.624939],[0.22,-0.72,3.54],[0.22,-0.58565,3.624939])),
                    #(true,true,#([0.382635,-0.58565,3.83],[0.382635,-0.625,3.975],[0.382635,-0.72,4.035061],[0.382635,-0.815,3.975],[0.382635,-0.85435,3.83],[0.382635,-0.815,3.685],[0.382635,-0.72,3.624939],[0.382635,-0.625,3.685])),
                    #(false,true,#([-0.01,-0.72,3.83],[0.057365,-0.58565,3.83],[0.22,-0.53,3.83],[0.382635,-0.58565,3.83],[0.45,-0.72,3.83])),
                    #(false,true,#([-0.01,-0.72,3.83],[0.057365,-0.625,3.975],[0.22,-0.58565,4.035061],[0.382635,-0.625,3.975],[0.45,-0.72,3.83])),
                    #(false,true,#([-0.01,-0.72,3.83],[0.057365,-0.72,4.035061],[0.22,-0.72,4.12],[0.382635,-0.72,4.035061],[0.45,-0.72,3.83])),
                    #(false,true,#([-0.01,-0.72,3.83],[0.057365,-0.815,3.975],[0.22,-0.85435,4.035061],[0.382635,-0.815,3.975],[0.45,-0.72,3.83])),
                    #(false,true,#([-0.01,-0.72,3.83],[0.057365,-0.85435,3.83],[0.22,-0.91,3.83],[0.382635,-0.85435,3.83],[0.45,-0.72,3.83])),
                    #(false,true,#([-0.01,-0.72,3.83],[0.057365,-0.815,3.685],[0.22,-0.85435,3.624939],[0.382635,-0.815,3.685],[0.45,-0.72,3.83])),
                    #(false,true,#([-0.01,-0.72,3.83],[0.057365,-0.72,3.624939],[0.22,-0.72,3.54],[0.382635,-0.72,3.624939],[0.45,-0.72,3.83])),
                    #(false,true,#([-0.01,-0.72,3.83],[0.057365,-0.625,3.685],[0.22,-0.58565,3.624939],[0.382635,-0.625,3.685],[0.45,-0.72,3.83]))
                ) "teal" "body" true 0.0
                f.cage "HighCollar" #(
                    #(true,true,#([0.48,0.0,5.65],[0.339411,0.33234,5.65],[0.0,0.47,5.65],[-0.339411,0.33234,5.65],[-0.48,0.0,5.65],[-0.339411,-0.33234,5.65],[0.0,-0.47,5.65],[0.339411,-0.33234,5.65])),
                    #(true,true,#([0.56,0.0,6.15],[0.39598,0.346482,6.15],[0.0,0.49,6.15],[-0.39598,0.346482,6.15],[-0.56,0.0,6.15],[-0.39598,-0.346482,6.15],[0.0,-0.49,6.15],[0.39598,-0.346482,6.15])),
                    #(false,true,#([0.0,0.0,5.65],[0.48,0.0,5.65],[0.56,0.0,6.15],[0.0,0.0,6.15])),
                    #(false,true,#([0.0,0.0,5.65],[0.339411,0.33234,5.65],[0.39598,0.346482,6.15],[0.0,0.0,6.15])),
                    #(false,true,#([0.0,0.0,5.65],[0.0,0.47,5.65],[0.0,0.49,6.15],[0.0,0.0,6.15])),
                    #(false,true,#([0.0,0.0,5.65],[-0.339411,0.33234,5.65],[-0.39598,0.346482,6.15],[0.0,0.0,6.15])),
                    #(false,true,#([0.0,0.0,5.65],[-0.48,0.0,5.65],[-0.56,0.0,6.15],[0.0,0.0,6.15])),
                    #(false,true,#([0.0,0.0,5.65],[-0.339411,-0.33234,5.65],[-0.39598,-0.346482,6.15],[0.0,0.0,6.15])),
                    #(false,true,#([0.0,0.0,5.65],[0.0,-0.47,5.65],[0.0,-0.49,6.15],[0.0,0.0,6.15])),
                    #(false,true,#([0.0,0.0,5.65],[0.339411,-0.33234,5.65],[0.39598,-0.346482,6.15],[0.0,0.0,6.15]))
                ) "teal" "body" true 0.0
                f.cage "Neck" #(
                    #(true,true,#([-0.25,0.0,5.95],[-0.176777,-0.176777,5.95],[0.0,-0.25,5.95],[0.176777,-0.176777,5.95],[0.25,0.0,5.95],[0.176777,0.176777,5.95],[0.0,0.25,5.95],[-0.176777,0.176777,5.95])),
                    #(true,true,#([-0.25,0.0,6.5],[-0.176777,-0.176777,6.5],[0.0,-0.25,6.5],[0.176777,-0.176777,6.5],[0.25,0.0,6.5],[0.176777,0.176777,6.5],[0.0,0.25,6.5],[-0.176777,0.176777,6.5])),
                    #(false,true,#([0.0,0.0,5.95],[-0.25,0.0,5.95],[-0.25,0.0,6.5],[0.0,0.0,6.5])),
                    #(false,true,#([0.0,0.0,5.95],[-0.176777,-0.176777,5.95],[-0.176777,-0.176777,6.5],[0.0,0.0,6.5])),
                    #(false,true,#([0.0,0.0,5.95],[0.0,-0.25,5.95],[0.0,-0.25,6.5],[0.0,0.0,6.5])),
                    #(false,true,#([0.0,0.0,5.95],[0.176777,-0.176777,5.95],[0.176777,-0.176777,6.5],[0.0,0.0,6.5])),
                    #(false,true,#([0.0,0.0,5.95],[0.25,0.0,5.95],[0.25,0.0,6.5],[0.0,0.0,6.5])),
                    #(false,true,#([0.0,0.0,5.95],[0.176777,0.176777,5.95],[0.176777,0.176777,6.5],[0.0,0.0,6.5])),
                    #(false,true,#([0.0,0.0,5.95],[0.0,0.25,5.95],[0.0,0.25,6.5],[0.0,0.0,6.5])),
                    #(false,true,#([0.0,0.0,5.95],[-0.176777,0.176777,5.95],[-0.176777,0.176777,6.5],[0.0,0.0,6.5]))
                ) "dark" "body" true 0.0
                f.cage "Head" #(
                    #(true,true,#([-0.445477,0.339411,7.05],[-0.445477,0.24,7.45],[-0.445477,0.0,7.615685],[-0.445477,-0.24,7.45],[-0.445477,-0.339411,7.05],[-0.445477,-0.24,6.65],[-0.445477,0.0,6.484315],[-0.445477,0.24,6.65])),
                    #(true,true,#([0.0,0.48,7.05],[0.0,0.339411,7.615685],[0.0,0.0,7.85],[0.0,-0.339411,7.615685],[0.0,-0.48,7.05],[0.0,-0.339411,6.484315],[0.0,0.0,6.25],[0.0,0.339411,6.484315])),
                    #(true,true,#([0.445477,0.339411,7.05],[0.445477,0.24,7.45],[0.445477,0.0,7.615685],[0.445477,-0.24,7.45],[0.445477,-0.339411,7.05],[0.445477,-0.24,6.65],[0.445477,0.0,6.484315],[0.445477,0.24,6.65])),
                    #(false,true,#([-0.63,0.0,7.05],[-0.445477,0.339411,7.05],[0.0,0.48,7.05],[0.445477,0.339411,7.05],[0.63,0.0,7.05])),
                    #(false,true,#([-0.63,0.0,7.05],[-0.445477,0.24,7.45],[0.0,0.339411,7.615685],[0.445477,0.24,7.45],[0.63,0.0,7.05])),
                    #(false,true,#([-0.63,0.0,7.05],[-0.445477,0.0,7.615685],[0.0,0.0,7.85],[0.445477,0.0,7.615685],[0.63,0.0,7.05])),
                    #(false,true,#([-0.63,0.0,7.05],[-0.445477,-0.24,7.45],[0.0,-0.339411,7.615685],[0.445477,-0.24,7.45],[0.63,0.0,7.05])),
                    #(false,true,#([-0.63,0.0,7.05],[-0.445477,-0.339411,7.05],[0.0,-0.48,7.05],[0.445477,-0.339411,7.05],[0.63,0.0,7.05])),
                    #(false,true,#([-0.63,0.0,7.05],[-0.445477,-0.24,6.65],[0.0,-0.339411,6.484315],[0.445477,-0.24,6.65],[0.63,0.0,7.05])),
                    #(false,true,#([-0.63,0.0,7.05],[-0.445477,0.0,6.484315],[0.0,0.0,6.25],[0.445477,0.0,6.484315],[0.63,0.0,7.05])),
                    #(false,true,#([-0.63,0.0,7.05],[-0.445477,0.24,6.65],[0.0,0.339411,6.484315],[0.445477,0.24,6.65],[0.63,0.0,7.05]))
                ) "dark" "head" true 0.0
                f.cage "FacePlate" #(
                    #(true,true,#([-0.360624,-0.302721,7.02],[-0.360624,-0.34,7.345],[-0.360624,-0.43,7.479619],[-0.360624,-0.52,7.345],[-0.360624,-0.557279,7.02],[-0.360624,-0.52,6.695],[-0.360624,-0.43,6.560381],[-0.360624,-0.34,6.695])),
                    #(true,true,#([0.0,-0.25,7.02],[0.0,-0.302721,7.479619],[0.0,-0.43,7.67],[0.0,-0.557279,7.479619],[0.0,-0.61,7.02],[0.0,-0.557279,6.560381],[0.0,-0.43,6.37],[0.0,-0.302721,6.560381])),
                    #(true,true,#([0.360624,-0.302721,7.02],[0.360624,-0.34,7.345],[0.360624,-0.43,7.479619],[0.360624,-0.52,7.345],[0.360624,-0.557279,7.02],[0.360624,-0.52,6.695],[0.360624,-0.43,6.560381],[0.360624,-0.34,6.695])),
                    #(false,true,#([-0.51,-0.43,7.02],[-0.360624,-0.302721,7.02],[0.0,-0.25,7.02],[0.360624,-0.302721,7.02],[0.51,-0.43,7.02])),
                    #(false,true,#([-0.51,-0.43,7.02],[-0.360624,-0.34,7.345],[0.0,-0.302721,7.479619],[0.360624,-0.34,7.345],[0.51,-0.43,7.02])),
                    #(false,true,#([-0.51,-0.43,7.02],[-0.360624,-0.43,7.479619],[0.0,-0.43,7.67],[0.360624,-0.43,7.479619],[0.51,-0.43,7.02])),
                    #(false,true,#([-0.51,-0.43,7.02],[-0.360624,-0.52,7.345],[0.0,-0.557279,7.479619],[0.360624,-0.52,7.345],[0.51,-0.43,7.02])),
                    #(false,true,#([-0.51,-0.43,7.02],[-0.360624,-0.557279,7.02],[0.0,-0.61,7.02],[0.360624,-0.557279,7.02],[0.51,-0.43,7.02])),
                    #(false,true,#([-0.51,-0.43,7.02],[-0.360624,-0.52,6.695],[0.0,-0.557279,6.560381],[0.360624,-0.52,6.695],[0.51,-0.43,7.02])),
                    #(false,true,#([-0.51,-0.43,7.02],[-0.360624,-0.43,6.560381],[0.0,-0.43,6.37],[0.360624,-0.43,6.560381],[0.51,-0.43,7.02])),
                    #(false,true,#([-0.51,-0.43,7.02],[-0.360624,-0.34,6.695],[0.0,-0.302721,6.560381],[0.360624,-0.34,6.695],[0.51,-0.43,7.02]))
                ) "ivory_glow" "mask" true 0.0
                f.cage "EyeLeft" #(
                    #(true,true,#([-0.31095,-0.483594,7.137],[-0.31095,-0.5164,7.20525],[-0.31095,-0.5956,7.23352],[-0.31095,-0.6748,7.20525],[-0.31095,-0.707606,7.137],[-0.31095,-0.6748,7.06875],[-0.31095,-0.5956,7.04048],[-0.31095,-0.5164,7.06875])),
                    #(true,true,#([-0.2244,-0.4372,7.137],[-0.2244,-0.483594,7.23352],[-0.2244,-0.5956,7.2735],[-0.2244,-0.707606,7.23352],[-0.2244,-0.754,7.137],[-0.2244,-0.707606,7.04048],[-0.2244,-0.5956,7.0005],[-0.2244,-0.483594,7.04048])),
                    #(true,true,#([-0.13785,-0.483594,7.137],[-0.13785,-0.5164,7.20525],[-0.13785,-0.5956,7.23352],[-0.13785,-0.6748,7.20525],[-0.13785,-0.707606,7.137],[-0.13785,-0.6748,7.06875],[-0.13785,-0.5956,7.04048],[-0.13785,-0.5164,7.06875])),
                    #(false,true,#([-0.3468,-0.5956,7.137],[-0.31095,-0.483594,7.137],[-0.2244,-0.4372,7.137],[-0.13785,-0.483594,7.137],[-0.102,-0.5956,7.137])),
                    #(false,true,#([-0.3468,-0.5956,7.137],[-0.31095,-0.5164,7.20525],[-0.2244,-0.483594,7.23352],[-0.13785,-0.5164,7.20525],[-0.102,-0.5956,7.137])),
                    #(false,true,#([-0.3468,-0.5956,7.137],[-0.31095,-0.5956,7.23352],[-0.2244,-0.5956,7.2735],[-0.13785,-0.5956,7.23352],[-0.102,-0.5956,7.137])),
                    #(false,true,#([-0.3468,-0.5956,7.137],[-0.31095,-0.6748,7.20525],[-0.2244,-0.707606,7.23352],[-0.13785,-0.6748,7.20525],[-0.102,-0.5956,7.137])),
                    #(false,true,#([-0.3468,-0.5956,7.137],[-0.31095,-0.707606,7.137],[-0.2244,-0.754,7.137],[-0.13785,-0.707606,7.137],[-0.102,-0.5956,7.137])),
                    #(false,true,#([-0.3468,-0.5956,7.137],[-0.31095,-0.6748,7.06875],[-0.2244,-0.707606,7.04048],[-0.13785,-0.6748,7.06875],[-0.102,-0.5956,7.137])),
                    #(false,true,#([-0.3468,-0.5956,7.137],[-0.31095,-0.5956,7.04048],[-0.2244,-0.5956,7.0005],[-0.13785,-0.5956,7.04048],[-0.102,-0.5956,7.137])),
                    #(false,true,#([-0.3468,-0.5956,7.137],[-0.31095,-0.5164,7.06875],[-0.2244,-0.483594,7.04048],[-0.13785,-0.5164,7.06875],[-0.102,-0.5956,7.137]))
                ) "dark" "mask" true 0.0
                f.cage "EyeRight" #(
                    #(true,true,#([0.13785,-0.483594,7.137],[0.13785,-0.5164,7.20525],[0.13785,-0.5956,7.23352],[0.13785,-0.6748,7.20525],[0.13785,-0.707606,7.137],[0.13785,-0.6748,7.06875],[0.13785,-0.5956,7.04048],[0.13785,-0.5164,7.06875])),
                    #(true,true,#([0.2244,-0.4372,7.137],[0.2244,-0.483594,7.23352],[0.2244,-0.5956,7.2735],[0.2244,-0.707606,7.23352],[0.2244,-0.754,7.137],[0.2244,-0.707606,7.04048],[0.2244,-0.5956,7.0005],[0.2244,-0.483594,7.04048])),
                    #(true,true,#([0.31095,-0.483594,7.137],[0.31095,-0.5164,7.20525],[0.31095,-0.5956,7.23352],[0.31095,-0.6748,7.20525],[0.31095,-0.707606,7.137],[0.31095,-0.6748,7.06875],[0.31095,-0.5956,7.04048],[0.31095,-0.5164,7.06875])),
                    #(false,true,#([0.102,-0.5956,7.137],[0.13785,-0.483594,7.137],[0.2244,-0.4372,7.137],[0.31095,-0.483594,7.137],[0.3468,-0.5956,7.137])),
                    #(false,true,#([0.102,-0.5956,7.137],[0.13785,-0.5164,7.20525],[0.2244,-0.483594,7.23352],[0.31095,-0.5164,7.20525],[0.3468,-0.5956,7.137])),
                    #(false,true,#([0.102,-0.5956,7.137],[0.13785,-0.5956,7.23352],[0.2244,-0.5956,7.2735],[0.31095,-0.5956,7.23352],[0.3468,-0.5956,7.137])),
                    #(false,true,#([0.102,-0.5956,7.137],[0.13785,-0.6748,7.20525],[0.2244,-0.707606,7.23352],[0.31095,-0.6748,7.20525],[0.3468,-0.5956,7.137])),
                    #(false,true,#([0.102,-0.5956,7.137],[0.13785,-0.707606,7.137],[0.2244,-0.754,7.137],[0.31095,-0.707606,7.137],[0.3468,-0.5956,7.137])),
                    #(false,true,#([0.102,-0.5956,7.137],[0.13785,-0.6748,7.06875],[0.2244,-0.707606,7.04048],[0.31095,-0.6748,7.06875],[0.3468,-0.5956,7.137])),
                    #(false,true,#([0.102,-0.5956,7.137],[0.13785,-0.5956,7.04048],[0.2244,-0.5956,7.0005],[0.31095,-0.5956,7.04048],[0.3468,-0.5956,7.137])),
                    #(false,true,#([0.102,-0.5956,7.137],[0.13785,-0.5164,7.06875],[0.2244,-0.483594,7.04048],[0.31095,-0.5164,7.06875],[0.3468,-0.5956,7.137]))
                ) "dark" "mask" true 0.0
                f.tube "SingleLapel" #([-0.38,-0.53,5.88],[-0.54,-0.6,5.25],[-0.18,-0.63,4.25]) 0.105 5 false true "cyan_glow" "body"
                f.tube "RaincoatHem" #([-0.85,-0.3,1.02],[0.0,-0.59,1.0],[0.85,-0.3,1.02]) 0.095 5 false true "cyan_glow" "body"
                f.finishModel()
                f.startModel "paradecivilian2" "The jacket watcher" "civilian" 2 0.23 [0.0,0.0,5.83] "Broad short jacket, loose trousers and one restrained greeting hand." true
                f.cage "LeftBoot" #(
                    #(true,true,#([-0.965772,0.270122,0.21],[-0.965772,0.15,0.315],[-0.965772,-0.14,0.358492],[-0.965772,-0.43,0.315],[-0.965772,-0.550122,0.21],[-0.965772,-0.43,0.105],[-0.965772,-0.14,0.061508],[-0.965772,0.15,0.105])),
                    #(true,true,#([-0.69,0.44,0.21],[-0.69,0.270122,0.358492],[-0.69,-0.14,0.42],[-0.69,-0.550122,0.358492],[-0.69,-0.72,0.21],[-0.69,-0.550122,0.061508],[-0.69,-0.14,0.0],[-0.69,0.270122,0.061508])),
                    #(true,true,#([-0.414228,0.270122,0.21],[-0.414228,0.15,0.315],[-0.414228,-0.14,0.358492],[-0.414228,-0.43,0.315],[-0.414228,-0.550122,0.21],[-0.414228,-0.43,0.105],[-0.414228,-0.14,0.061508],[-0.414228,0.15,0.105])),
                    #(false,true,#([-1.08,-0.14,0.21],[-0.965772,0.270122,0.21],[-0.69,0.44,0.21],[-0.414228,0.270122,0.21],[-0.3,-0.14,0.21])),
                    #(false,true,#([-1.08,-0.14,0.21],[-0.965772,0.15,0.315],[-0.69,0.270122,0.358492],[-0.414228,0.15,0.315],[-0.3,-0.14,0.21])),
                    #(false,true,#([-1.08,-0.14,0.21],[-0.965772,-0.14,0.358492],[-0.69,-0.14,0.42],[-0.414228,-0.14,0.358492],[-0.3,-0.14,0.21])),
                    #(false,true,#([-1.08,-0.14,0.21],[-0.965772,-0.43,0.315],[-0.69,-0.550122,0.358492],[-0.414228,-0.43,0.315],[-0.3,-0.14,0.21])),
                    #(false,true,#([-1.08,-0.14,0.21],[-0.965772,-0.550122,0.21],[-0.69,-0.72,0.21],[-0.414228,-0.550122,0.21],[-0.3,-0.14,0.21])),
                    #(false,true,#([-1.08,-0.14,0.21],[-0.965772,-0.43,0.105],[-0.69,-0.550122,0.061508],[-0.414228,-0.43,0.105],[-0.3,-0.14,0.21])),
                    #(false,true,#([-1.08,-0.14,0.21],[-0.965772,-0.14,0.061508],[-0.69,-0.14,0.0],[-0.414228,-0.14,0.061508],[-0.3,-0.14,0.21])),
                    #(false,true,#([-1.08,-0.14,0.21],[-0.965772,0.15,0.105],[-0.69,0.270122,0.061508],[-0.414228,0.15,0.105],[-0.3,-0.14,0.21]))
                ) "dark" "body" true 0.0
                f.cage "RightBoot" #(
                    #(true,true,#([0.384228,0.510122,0.21],[0.384228,0.39,0.315],[0.384228,0.1,0.358492],[0.384228,-0.19,0.315],[0.384228,-0.310122,0.21],[0.384228,-0.19,0.105],[0.384228,0.1,0.061508],[0.384228,0.39,0.105])),
                    #(true,true,#([0.66,0.68,0.21],[0.66,0.510122,0.358492],[0.66,0.1,0.42],[0.66,-0.310122,0.358492],[0.66,-0.48,0.21],[0.66,-0.310122,0.061508],[0.66,0.1,0.0],[0.66,0.510122,0.061508])),
                    #(true,true,#([0.935772,0.510122,0.21],[0.935772,0.39,0.315],[0.935772,0.1,0.358492],[0.935772,-0.19,0.315],[0.935772,-0.310122,0.21],[0.935772,-0.19,0.105],[0.935772,0.1,0.061508],[0.935772,0.39,0.105])),
                    #(false,true,#([0.27,0.1,0.21],[0.384228,0.510122,0.21],[0.66,0.68,0.21],[0.935772,0.510122,0.21],[1.05,0.1,0.21])),
                    #(false,true,#([0.27,0.1,0.21],[0.384228,0.39,0.315],[0.66,0.510122,0.358492],[0.935772,0.39,0.315],[1.05,0.1,0.21])),
                    #(false,true,#([0.27,0.1,0.21],[0.384228,0.1,0.358492],[0.66,0.1,0.42],[0.935772,0.1,0.358492],[1.05,0.1,0.21])),
                    #(false,true,#([0.27,0.1,0.21],[0.384228,-0.19,0.315],[0.66,-0.310122,0.358492],[0.935772,-0.19,0.315],[1.05,0.1,0.21])),
                    #(false,true,#([0.27,0.1,0.21],[0.384228,-0.310122,0.21],[0.66,-0.48,0.21],[0.935772,-0.310122,0.21],[1.05,0.1,0.21])),
                    #(false,true,#([0.27,0.1,0.21],[0.384228,-0.19,0.105],[0.66,-0.310122,0.061508],[0.935772,-0.19,0.105],[1.05,0.1,0.21])),
                    #(false,true,#([0.27,0.1,0.21],[0.384228,0.1,0.061508],[0.66,0.1,0.0],[0.935772,0.1,0.061508],[1.05,0.1,0.21])),
                    #(false,true,#([0.27,0.1,0.21],[0.384228,0.39,0.105],[0.66,0.510122,0.061508],[0.935772,0.39,0.105],[1.05,0.1,0.21]))
                ) "dark" "body" true 0.0
                f.cage "LeftTrouser" #(
                    #(true,true,#([-1.039754,0.0,0.286884],[-0.937314,-0.247487,0.290726],[-0.69,-0.35,0.3],[-0.442686,-0.247487,0.309274],[-0.340246,0.0,0.313116],[-0.442686,0.247487,0.309274],[-0.69,0.35,0.3],[-0.937314,0.247487,0.290726])),
                    #(true,true,#([-1.169639,0.000599,1.91739],[-1.046709,-0.296367,1.923038],[-0.74997,-0.419725,1.915191],[-0.453249,-0.297214,1.898446],[-0.330361,-0.000599,1.88261],[-0.453291,0.296367,1.876962],[-0.75003,0.419725,1.884809],[-1.046751,0.297214,1.901554])),
                    #(true,true,#([-1.016601,0.122678,3.606363],[-0.878941,-0.209579,3.613841],[-0.548593,-0.348772,3.583922],[-0.219068,-0.213365,3.534132],[-0.083399,0.117322,3.493637],[-0.221059,0.449579,3.486159],[-0.551407,0.588772,3.516078],[-0.880932,0.453365,3.565868])),
                    #(false,true,#([-0.69,0.0,0.3],[-1.039754,0.0,0.286884],[-1.169639,0.000599,1.91739],[-1.016601,0.122678,3.606363],[-0.55,0.12,3.55])),
                    #(false,true,#([-0.69,0.0,0.3],[-0.937314,-0.247487,0.290726],[-1.046709,-0.296367,1.923038],[-0.878941,-0.209579,3.613841],[-0.55,0.12,3.55])),
                    #(false,true,#([-0.69,0.0,0.3],[-0.69,-0.35,0.3],[-0.74997,-0.419725,1.915191],[-0.548593,-0.348772,3.583922],[-0.55,0.12,3.55])),
                    #(false,true,#([-0.69,0.0,0.3],[-0.442686,-0.247487,0.309274],[-0.453249,-0.297214,1.898446],[-0.219068,-0.213365,3.534132],[-0.55,0.12,3.55])),
                    #(false,true,#([-0.69,0.0,0.3],[-0.340246,0.0,0.313116],[-0.330361,-0.000599,1.88261],[-0.083399,0.117322,3.493637],[-0.55,0.12,3.55])),
                    #(false,true,#([-0.69,0.0,0.3],[-0.442686,0.247487,0.309274],[-0.453291,0.296367,1.876962],[-0.221059,0.449579,3.486159],[-0.55,0.12,3.55])),
                    #(false,true,#([-0.69,0.0,0.3],[-0.69,0.35,0.3],[-0.75003,0.419725,1.884809],[-0.551407,0.588772,3.516078],[-0.55,0.12,3.55])),
                    #(false,true,#([-0.69,0.0,0.3],[-0.937314,0.247487,0.290726],[-1.046751,0.297214,1.901554],[-0.880932,0.453365,3.565868],[-0.55,0.12,3.55]))
                ) "dark" "body" true 0.0
                f.cage "RightTrouser" #(
                    #(true,true,#([0.310437,0.15,0.317478],[0.413164,-0.097392,0.319214],[0.660485,-0.199865,0.309694],[0.907521,-0.097392,0.294496],[1.009563,0.15,0.282522],[0.906836,0.397392,0.280786],[0.659515,0.499865,0.290306],[0.412479,0.397392,0.305504])),
                    #(true,true,#([0.340745,0.199829,2.075296],[0.461086,-0.089976,2.076698],[0.750669,-0.209916,2.09175],[1.03986,-0.089734,2.111635],[1.159255,0.200171,2.124704],[1.038914,0.489976,2.123302],[0.749331,0.609916,2.10825],[0.46014,0.489734,2.088365])),
                    #(true,true,#([0.036814,0.102087,3.470284],[0.17485,-0.230096,3.471174],[0.503354,-0.368914,3.518239],[0.829893,-0.233048,3.583909],[0.963186,0.097913,3.629716],[0.82515,0.430096,3.628826],[0.496646,0.568914,3.581761],[0.170107,0.433048,3.516091])),
                    #(false,true,#([0.66,0.15,0.3],[0.310437,0.15,0.317478],[0.340745,0.199829,2.075296],[0.036814,0.102087,3.470284],[0.5,0.1,3.55])),
                    #(false,true,#([0.66,0.15,0.3],[0.413164,-0.097392,0.319214],[0.461086,-0.089976,2.076698],[0.17485,-0.230096,3.471174],[0.5,0.1,3.55])),
                    #(false,true,#([0.66,0.15,0.3],[0.660485,-0.199865,0.309694],[0.750669,-0.209916,2.09175],[0.503354,-0.368914,3.518239],[0.5,0.1,3.55])),
                    #(false,true,#([0.66,0.15,0.3],[0.907521,-0.097392,0.294496],[1.03986,-0.089734,2.111635],[0.829893,-0.233048,3.583909],[0.5,0.1,3.55])),
                    #(false,true,#([0.66,0.15,0.3],[1.009563,0.15,0.282522],[1.159255,0.200171,2.124704],[0.963186,0.097913,3.629716],[0.5,0.1,3.55])),
                    #(false,true,#([0.66,0.15,0.3],[0.906836,0.397392,0.280786],[1.038914,0.489976,2.123302],[0.82515,0.430096,3.628826],[0.5,0.1,3.55])),
                    #(false,true,#([0.66,0.15,0.3],[0.659515,0.499865,0.290306],[0.749331,0.609916,2.10825],[0.496646,0.568914,3.581761],[0.5,0.1,3.55])),
                    #(false,true,#([0.66,0.15,0.3],[0.412479,0.397392,0.305504],[0.46014,0.489734,2.088365],[0.170107,0.433048,3.516091],[0.5,0.1,3.55]))
                ) "dark" "body" true 0.0
                f.cage "ShortJacket" #(
                    #(true,true,#([1.05,0.0,3.0],[0.742462,0.459619,3.0],[0.0,0.65,3.0],[-0.742462,0.459619,3.0],[-1.05,0.0,3.0],[-0.742462,-0.459619,3.0],[0.0,-0.65,3.0],[0.742462,-0.459619,3.0])),
                    #(true,true,#([1.34,0.0,3.6],[0.947523,0.53033,3.6],[0.0,0.75,3.6],[-0.947523,0.53033,3.6],[-1.34,0.0,3.6],[-0.947523,-0.53033,3.6],[0.0,-0.75,3.6],[0.947523,-0.53033,3.6])),
                    #(true,true,#([1.3,0.0,5.2],[0.919239,0.509117,5.2],[0.0,0.72,5.2],[-0.919239,0.509117,5.2],[-1.3,0.0,5.2],[-0.919239,-0.509117,5.2],[0.0,-0.72,5.2],[0.919239,-0.509117,5.2])),
                    #(true,true,#([1.05,0.0,5.65],[0.742462,0.417193,5.65],[0.0,0.59,5.65],[-0.742462,0.417193,5.65],[-1.05,0.0,5.65],[-0.742462,-0.417193,5.65],[0.0,-0.59,5.65],[0.742462,-0.417193,5.65])),
                    #(false,true,#([0.0,0.0,3.0],[1.05,0.0,3.0],[1.34,0.0,3.6],[1.3,0.0,5.2],[1.05,0.0,5.65],[0.0,0.0,5.65])),
                    #(false,true,#([0.0,0.0,3.0],[0.742462,0.459619,3.0],[0.947523,0.53033,3.6],[0.919239,0.509117,5.2],[0.742462,0.417193,5.65],[0.0,0.0,5.65])),
                    #(false,true,#([0.0,0.0,3.0],[0.0,0.65,3.0],[0.0,0.75,3.6],[0.0,0.72,5.2],[0.0,0.59,5.65],[0.0,0.0,5.65])),
                    #(false,true,#([0.0,0.0,3.0],[-0.742462,0.459619,3.0],[-0.947523,0.53033,3.6],[-0.919239,0.509117,5.2],[-0.742462,0.417193,5.65],[0.0,0.0,5.65])),
                    #(false,true,#([0.0,0.0,3.0],[-1.05,0.0,3.0],[-1.34,0.0,3.6],[-1.3,0.0,5.2],[-1.05,0.0,5.65],[0.0,0.0,5.65])),
                    #(false,true,#([0.0,0.0,3.0],[-0.742462,-0.459619,3.0],[-0.947523,-0.53033,3.6],[-0.919239,-0.509117,5.2],[-0.742462,-0.417193,5.65],[0.0,0.0,5.65])),
                    #(false,true,#([0.0,0.0,3.0],[0.0,-0.65,3.0],[0.0,-0.75,3.6],[0.0,-0.72,5.2],[0.0,-0.59,5.65],[0.0,0.0,5.65])),
                    #(false,true,#([0.0,0.0,3.0],[0.742462,-0.459619,3.0],[0.947523,-0.53033,3.6],[0.919239,-0.509117,5.2],[0.742462,-0.417193,5.65],[0.0,0.0,5.65]))
                ) "teal" "body" true 0.0
                f.cage "PocketArm" #(
                    #(true,true,#([-0.728609,0.0,5.101444],[-0.831302,-0.282368,5.160169],[-1.091394,-0.399328,5.271516],[-1.356527,-0.282368,5.370259],[-1.471391,0.0,5.398556],[-1.368698,0.282368,5.339831],[-1.108606,0.399328,5.228484],[-0.843473,0.282368,5.129741])),
                    #(true,true,#([-1.060983,-0.023581,4.453014],[-1.149006,-0.273018,4.530158],[-1.395773,-0.391814,4.560347],[-1.656732,-0.31038,4.525896],[-1.779017,-0.076419,4.446986],[-1.690994,0.173018,4.369842],[-1.444227,0.291814,4.339653],[-1.183268,0.21038,4.374104])),
                    #(true,true,#([-0.693692,-0.561758,3.63884],[-0.758907,-0.727889,3.707826],[-0.918488,-0.83082,3.684359],[-1.078955,-0.810256,3.582187],[-1.146308,-0.678242,3.46116],[-1.081093,-0.512111,3.392174],[-0.921512,-0.40918,3.415641],[-0.761045,-0.429744,3.517813])),
                    #(false,true,#([-1.1,0.0,5.25],[-0.728609,0.0,5.101444],[-1.060983,-0.023581,4.453014],[-0.693692,-0.561758,3.63884],[-0.92,-0.62,3.55])),
                    #(false,true,#([-1.1,0.0,5.25],[-0.831302,-0.282368,5.160169],[-1.149006,-0.273018,4.530158],[-0.758907,-0.727889,3.707826],[-0.92,-0.62,3.55])),
                    #(false,true,#([-1.1,0.0,5.25],[-1.091394,-0.399328,5.271516],[-1.395773,-0.391814,4.560347],[-0.918488,-0.83082,3.684359],[-0.92,-0.62,3.55])),
                    #(false,true,#([-1.1,0.0,5.25],[-1.356527,-0.282368,5.370259],[-1.656732,-0.31038,4.525896],[-1.078955,-0.810256,3.582187],[-0.92,-0.62,3.55])),
                    #(false,true,#([-1.1,0.0,5.25],[-1.471391,0.0,5.398556],[-1.779017,-0.076419,4.446986],[-1.146308,-0.678242,3.46116],[-0.92,-0.62,3.55])),
                    #(false,true,#([-1.1,0.0,5.25],[-1.368698,0.282368,5.339831],[-1.690994,0.173018,4.369842],[-1.081093,-0.512111,3.392174],[-0.92,-0.62,3.55])),
                    #(false,true,#([-1.1,0.0,5.25],[-1.108606,0.399328,5.228484],[-1.444227,0.291814,4.339653],[-0.921512,-0.40918,3.415641],[-0.92,-0.62,3.55])),
                    #(false,true,#([-1.1,0.0,5.25],[-0.843473,0.282368,5.129741],[-1.183268,0.21038,4.374104],[-0.761045,-0.429744,3.517813],[-0.92,-0.62,3.55]))
                ) "dark" "body" true 0.0
                f.cage "WavingSleeve" #(
                    #(true,true,#([1.075645,-0.398522,5.25],[1.038,-0.277685,4.97124],[1.042531,0.005816,4.855774],[1.086585,0.28591,4.97124],[1.144355,0.398522,5.25],[1.182,0.277685,5.52876],[1.177469,-0.005816,5.644226],[1.133415,-0.28591,5.52876])),
                    #(true,true,#([1.647987,-0.367217,5.147094],[1.780156,-0.288428,4.956547],[1.859514,-0.069971,4.879323],[1.839572,0.160184,4.960657],[1.732013,0.267217,5.152906],[1.599844,0.188428,5.343453],[1.520486,-0.030029,5.420677],[1.540428,-0.260184,5.339343])),
                    #(true,true,#([1.890316,-0.376558,6.018409],[2.070211,-0.329163,5.973655],[2.167973,-0.165101,5.961907],[2.126334,0.019522,5.990047],[1.969684,0.116558,6.041591],[1.789789,0.069163,6.086345],[1.692027,-0.094899,6.098093],[1.733666,-0.279522,6.069953])),
                    #(false,true,#([1.11,0.0,5.25],[1.075645,-0.398522,5.25],[1.647987,-0.367217,5.147094],[1.890316,-0.376558,6.018409],[1.93,-0.13,6.03])),
                    #(false,true,#([1.11,0.0,5.25],[1.038,-0.277685,4.97124],[1.780156,-0.288428,4.956547],[2.070211,-0.329163,5.973655],[1.93,-0.13,6.03])),
                    #(false,true,#([1.11,0.0,5.25],[1.042531,0.005816,4.855774],[1.859514,-0.069971,4.879323],[2.167973,-0.165101,5.961907],[1.93,-0.13,6.03])),
                    #(false,true,#([1.11,0.0,5.25],[1.086585,0.28591,4.97124],[1.839572,0.160184,4.960657],[2.126334,0.019522,5.990047],[1.93,-0.13,6.03])),
                    #(false,true,#([1.11,0.0,5.25],[1.144355,0.398522,5.25],[1.732013,0.267217,5.152906],[1.969684,0.116558,6.041591],[1.93,-0.13,6.03])),
                    #(false,true,#([1.11,0.0,5.25],[1.182,0.277685,5.52876],[1.599844,0.188428,5.343453],[1.789789,0.069163,6.086345],[1.93,-0.13,6.03])),
                    #(false,true,#([1.11,0.0,5.25],[1.177469,-0.005816,5.644226],[1.520486,-0.030029,5.420677],[1.692027,-0.094899,6.098093],[1.93,-0.13,6.03])),
                    #(false,true,#([1.11,0.0,5.25],[1.133415,-0.28591,5.52876],[1.540428,-0.260184,5.339343],[1.733666,-0.279522,6.069953],[1.93,-0.13,6.03]))
                ) "dark" "body" true 0.0
                f.cage "WavingHand" #(
                    #(true,true,#([1.770294,0.015563,6.33],[1.770294,-0.03,6.54],[1.770294,-0.14,6.626985],[1.770294,-0.25,6.54],[1.770294,-0.295563,6.33],[1.770294,-0.25,6.12],[1.770294,-0.14,6.033015],[1.770294,-0.03,6.12])),
                    #(true,true,#([1.94,0.08,6.33],[1.94,0.015563,6.626985],[1.94,-0.14,6.75],[1.94,-0.295563,6.626985],[1.94,-0.36,6.33],[1.94,-0.295563,6.033015],[1.94,-0.14,5.91],[1.94,0.015563,6.033015])),
                    #(true,true,#([2.109706,0.015563,6.33],[2.109706,-0.03,6.54],[2.109706,-0.14,6.626985],[2.109706,-0.25,6.54],[2.109706,-0.295563,6.33],[2.109706,-0.25,6.12],[2.109706,-0.14,6.033015],[2.109706,-0.03,6.12])),
                    #(false,true,#([1.7,-0.14,6.33],[1.770294,0.015563,6.33],[1.94,0.08,6.33],[2.109706,0.015563,6.33],[2.18,-0.14,6.33])),
                    #(false,true,#([1.7,-0.14,6.33],[1.770294,-0.03,6.54],[1.94,0.015563,6.626985],[2.109706,-0.03,6.54],[2.18,-0.14,6.33])),
                    #(false,true,#([1.7,-0.14,6.33],[1.770294,-0.14,6.626985],[1.94,-0.14,6.75],[2.109706,-0.14,6.626985],[2.18,-0.14,6.33])),
                    #(false,true,#([1.7,-0.14,6.33],[1.770294,-0.25,6.54],[1.94,-0.295563,6.626985],[2.109706,-0.25,6.54],[2.18,-0.14,6.33])),
                    #(false,true,#([1.7,-0.14,6.33],[1.770294,-0.295563,6.33],[1.94,-0.36,6.33],[2.109706,-0.295563,6.33],[2.18,-0.14,6.33])),
                    #(false,true,#([1.7,-0.14,6.33],[1.770294,-0.25,6.12],[1.94,-0.295563,6.033015],[2.109706,-0.25,6.12],[2.18,-0.14,6.33])),
                    #(false,true,#([1.7,-0.14,6.33],[1.770294,-0.14,6.033015],[1.94,-0.14,5.91],[2.109706,-0.14,6.033015],[2.18,-0.14,6.33])),
                    #(false,true,#([1.7,-0.14,6.33],[1.770294,-0.03,6.12],[1.94,0.015563,6.033015],[2.109706,-0.03,6.12],[2.18,-0.14,6.33]))
                ) "teal" "body" true 0.0
                f.cage "RolledCollar" #(
                    #(true,true,#([0.6,0.0,5.4],[0.424264,0.403051,5.4],[0.0,0.57,5.4],[-0.424264,0.403051,5.4],[-0.6,0.0,5.4],[-0.424264,-0.403051,5.4],[0.0,-0.57,5.4],[0.424264,-0.403051,5.4])),
                    #(true,true,#([0.64,0.0,5.87],[0.452548,0.39598,5.87],[0.0,0.56,5.87],[-0.452548,0.39598,5.87],[-0.64,0.0,5.87],[-0.452548,-0.39598,5.87],[0.0,-0.56,5.87],[0.452548,-0.39598,5.87])),
                    #(false,true,#([0.0,0.0,5.4],[0.6,0.0,5.4],[0.64,0.0,5.87],[0.0,0.0,5.87])),
                    #(false,true,#([0.0,0.0,5.4],[0.424264,0.403051,5.4],[0.452548,0.39598,5.87],[0.0,0.0,5.87])),
                    #(false,true,#([0.0,0.0,5.4],[0.0,0.57,5.4],[0.0,0.56,5.87],[0.0,0.0,5.87])),
                    #(false,true,#([0.0,0.0,5.4],[-0.424264,0.403051,5.4],[-0.452548,0.39598,5.87],[0.0,0.0,5.87])),
                    #(false,true,#([0.0,0.0,5.4],[-0.6,0.0,5.4],[-0.64,0.0,5.87],[0.0,0.0,5.87])),
                    #(false,true,#([0.0,0.0,5.4],[-0.424264,-0.403051,5.4],[-0.452548,-0.39598,5.87],[0.0,0.0,5.87])),
                    #(false,true,#([0.0,0.0,5.4],[0.0,-0.57,5.4],[0.0,-0.56,5.87],[0.0,0.0,5.87])),
                    #(false,true,#([0.0,0.0,5.4],[0.424264,-0.403051,5.4],[0.452548,-0.39598,5.87],[0.0,0.0,5.87]))
                ) "dark" "body" true 0.0
                f.cage "Head" #(
                    #(true,true,#([-0.480833,0.367696,6.65],[-0.480833,0.26,7.025],[-0.480833,0.0,7.18033],[-0.480833,-0.26,7.025],[-0.480833,-0.367696,6.65],[-0.480833,-0.26,6.275],[-0.480833,0.0,6.11967],[-0.480833,0.26,6.275])),
                    #(true,true,#([0.0,0.52,6.65],[0.0,0.367696,7.18033],[0.0,0.0,7.4],[0.0,-0.367696,7.18033],[0.0,-0.52,6.65],[0.0,-0.367696,6.11967],[0.0,0.0,5.9],[0.0,0.367696,6.11967])),
                    #(true,true,#([0.480833,0.367696,6.65],[0.480833,0.26,7.025],[0.480833,0.0,7.18033],[0.480833,-0.26,7.025],[0.480833,-0.367696,6.65],[0.480833,-0.26,6.275],[0.480833,0.0,6.11967],[0.480833,0.26,6.275])),
                    #(false,true,#([-0.68,0.0,6.65],[-0.480833,0.367696,6.65],[0.0,0.52,6.65],[0.480833,0.367696,6.65],[0.68,0.0,6.65])),
                    #(false,true,#([-0.68,0.0,6.65],[-0.480833,0.26,7.025],[0.0,0.367696,7.18033],[0.480833,0.26,7.025],[0.68,0.0,6.65])),
                    #(false,true,#([-0.68,0.0,6.65],[-0.480833,0.0,7.18033],[0.0,0.0,7.4],[0.480833,0.0,7.18033],[0.68,0.0,6.65])),
                    #(false,true,#([-0.68,0.0,6.65],[-0.480833,-0.26,7.025],[0.0,-0.367696,7.18033],[0.480833,-0.26,7.025],[0.68,0.0,6.65])),
                    #(false,true,#([-0.68,0.0,6.65],[-0.480833,-0.367696,6.65],[0.0,-0.52,6.65],[0.480833,-0.367696,6.65],[0.68,0.0,6.65])),
                    #(false,true,#([-0.68,0.0,6.65],[-0.480833,-0.26,6.275],[0.0,-0.367696,6.11967],[0.480833,-0.26,6.275],[0.68,0.0,6.65])),
                    #(false,true,#([-0.68,0.0,6.65],[-0.480833,0.0,6.11967],[0.0,0.0,5.9],[0.480833,0.0,6.11967],[0.68,0.0,6.65])),
                    #(false,true,#([-0.68,0.0,6.65],[-0.480833,0.26,6.275],[0.0,0.367696,6.11967],[0.480833,0.26,6.275],[0.68,0.0,6.65]))
                ) "dark" "head" true 0.0
                f.cage "FacePlate" #(
                    #(true,true,#([-0.367696,-0.342721,6.62],[-0.367696,-0.38,6.9025],[-0.367696,-0.47,7.019515],[-0.367696,-0.56,6.9025],[-0.367696,-0.597279,6.62],[-0.367696,-0.56,6.3375],[-0.367696,-0.47,6.220485],[-0.367696,-0.38,6.3375])),
                    #(true,true,#([0.0,-0.29,6.62],[0.0,-0.342721,7.019515],[0.0,-0.47,7.185],[0.0,-0.597279,7.019515],[0.0,-0.65,6.62],[0.0,-0.597279,6.220485],[0.0,-0.47,6.055],[0.0,-0.342721,6.220485])),
                    #(true,true,#([0.367696,-0.342721,6.62],[0.367696,-0.38,6.9025],[0.367696,-0.47,7.019515],[0.367696,-0.56,6.9025],[0.367696,-0.597279,6.62],[0.367696,-0.56,6.3375],[0.367696,-0.47,6.220485],[0.367696,-0.38,6.3375])),
                    #(false,true,#([-0.52,-0.47,6.62],[-0.367696,-0.342721,6.62],[0.0,-0.29,6.62],[0.367696,-0.342721,6.62],[0.52,-0.47,6.62])),
                    #(false,true,#([-0.52,-0.47,6.62],[-0.367696,-0.38,6.9025],[0.0,-0.342721,7.019515],[0.367696,-0.38,6.9025],[0.52,-0.47,6.62])),
                    #(false,true,#([-0.52,-0.47,6.62],[-0.367696,-0.47,7.019515],[0.0,-0.47,7.185],[0.367696,-0.47,7.019515],[0.52,-0.47,6.62])),
                    #(false,true,#([-0.52,-0.47,6.62],[-0.367696,-0.56,6.9025],[0.0,-0.597279,7.019515],[0.367696,-0.56,6.9025],[0.52,-0.47,6.62])),
                    #(false,true,#([-0.52,-0.47,6.62],[-0.367696,-0.597279,6.62],[0.0,-0.65,6.62],[0.367696,-0.597279,6.62],[0.52,-0.47,6.62])),
                    #(false,true,#([-0.52,-0.47,6.62],[-0.367696,-0.56,6.3375],[0.0,-0.597279,6.220485],[0.367696,-0.56,6.3375],[0.52,-0.47,6.62])),
                    #(false,true,#([-0.52,-0.47,6.62],[-0.367696,-0.47,6.220485],[0.0,-0.47,6.055],[0.367696,-0.47,6.220485],[0.52,-0.47,6.62])),
                    #(false,true,#([-0.52,-0.47,6.62],[-0.367696,-0.38,6.3375],[0.0,-0.342721,6.220485],[0.367696,-0.38,6.3375],[0.52,-0.47,6.62]))
                ) "ivory_glow" "mask" true 0.0
                f.cage "EyeLeft" #(
                    #(true,true,#([-0.317047,-0.523594,6.7217],[-0.317047,-0.5564,6.7817],[-0.317047,-0.6356,6.806553],[-0.317047,-0.7148,6.7817],[-0.317047,-0.747606,6.7217],[-0.317047,-0.7148,6.6617],[-0.317047,-0.6356,6.636847],[-0.317047,-0.5564,6.6617])),
                    #(true,true,#([-0.2288,-0.4772,6.7217],[-0.2288,-0.523594,6.806553],[-0.2288,-0.6356,6.8417],[-0.2288,-0.747606,6.806553],[-0.2288,-0.794,6.7217],[-0.2288,-0.747606,6.636847],[-0.2288,-0.6356,6.6017],[-0.2288,-0.523594,6.636847])),
                    #(true,true,#([-0.140553,-0.523594,6.7217],[-0.140553,-0.5564,6.7817],[-0.140553,-0.6356,6.806553],[-0.140553,-0.7148,6.7817],[-0.140553,-0.747606,6.7217],[-0.140553,-0.7148,6.6617],[-0.140553,-0.6356,6.636847],[-0.140553,-0.5564,6.6617])),
                    #(false,true,#([-0.3536,-0.6356,6.7217],[-0.317047,-0.523594,6.7217],[-0.2288,-0.4772,6.7217],[-0.140553,-0.523594,6.7217],[-0.104,-0.6356,6.7217])),
                    #(false,true,#([-0.3536,-0.6356,6.7217],[-0.317047,-0.5564,6.7817],[-0.2288,-0.523594,6.806553],[-0.140553,-0.5564,6.7817],[-0.104,-0.6356,6.7217])),
                    #(false,true,#([-0.3536,-0.6356,6.7217],[-0.317047,-0.6356,6.806553],[-0.2288,-0.6356,6.8417],[-0.140553,-0.6356,6.806553],[-0.104,-0.6356,6.7217])),
                    #(false,true,#([-0.3536,-0.6356,6.7217],[-0.317047,-0.7148,6.7817],[-0.2288,-0.747606,6.806553],[-0.140553,-0.7148,6.7817],[-0.104,-0.6356,6.7217])),
                    #(false,true,#([-0.3536,-0.6356,6.7217],[-0.317047,-0.747606,6.7217],[-0.2288,-0.794,6.7217],[-0.140553,-0.747606,6.7217],[-0.104,-0.6356,6.7217])),
                    #(false,true,#([-0.3536,-0.6356,6.7217],[-0.317047,-0.7148,6.6617],[-0.2288,-0.747606,6.636847],[-0.140553,-0.7148,6.6617],[-0.104,-0.6356,6.7217])),
                    #(false,true,#([-0.3536,-0.6356,6.7217],[-0.317047,-0.6356,6.636847],[-0.2288,-0.6356,6.6017],[-0.140553,-0.6356,6.636847],[-0.104,-0.6356,6.7217])),
                    #(false,true,#([-0.3536,-0.6356,6.7217],[-0.317047,-0.5564,6.6617],[-0.2288,-0.523594,6.636847],[-0.140553,-0.5564,6.6617],[-0.104,-0.6356,6.7217]))
                ) "dark" "mask" true 0.0
                f.cage "EyeRight" #(
                    #(true,true,#([0.140553,-0.523594,6.7217],[0.140553,-0.5564,6.7817],[0.140553,-0.6356,6.806553],[0.140553,-0.7148,6.7817],[0.140553,-0.747606,6.7217],[0.140553,-0.7148,6.6617],[0.140553,-0.6356,6.636847],[0.140553,-0.5564,6.6617])),
                    #(true,true,#([0.2288,-0.4772,6.7217],[0.2288,-0.523594,6.806553],[0.2288,-0.6356,6.8417],[0.2288,-0.747606,6.806553],[0.2288,-0.794,6.7217],[0.2288,-0.747606,6.636847],[0.2288,-0.6356,6.6017],[0.2288,-0.523594,6.636847])),
                    #(true,true,#([0.317047,-0.523594,6.7217],[0.317047,-0.5564,6.7817],[0.317047,-0.6356,6.806553],[0.317047,-0.7148,6.7817],[0.317047,-0.747606,6.7217],[0.317047,-0.7148,6.6617],[0.317047,-0.6356,6.636847],[0.317047,-0.5564,6.6617])),
                    #(false,true,#([0.104,-0.6356,6.7217],[0.140553,-0.523594,6.7217],[0.2288,-0.4772,6.7217],[0.317047,-0.523594,6.7217],[0.3536,-0.6356,6.7217])),
                    #(false,true,#([0.104,-0.6356,6.7217],[0.140553,-0.5564,6.7817],[0.2288,-0.523594,6.806553],[0.317047,-0.5564,6.7817],[0.3536,-0.6356,6.7217])),
                    #(false,true,#([0.104,-0.6356,6.7217],[0.140553,-0.6356,6.806553],[0.2288,-0.6356,6.8417],[0.317047,-0.6356,6.806553],[0.3536,-0.6356,6.7217])),
                    #(false,true,#([0.104,-0.6356,6.7217],[0.140553,-0.7148,6.7817],[0.2288,-0.747606,6.806553],[0.317047,-0.7148,6.7817],[0.3536,-0.6356,6.7217])),
                    #(false,true,#([0.104,-0.6356,6.7217],[0.140553,-0.747606,6.7217],[0.2288,-0.794,6.7217],[0.317047,-0.747606,6.7217],[0.3536,-0.6356,6.7217])),
                    #(false,true,#([0.104,-0.6356,6.7217],[0.140553,-0.7148,6.6617],[0.2288,-0.747606,6.636847],[0.317047,-0.7148,6.6617],[0.3536,-0.6356,6.7217])),
                    #(false,true,#([0.104,-0.6356,6.7217],[0.140553,-0.6356,6.636847],[0.2288,-0.6356,6.6017],[0.317047,-0.6356,6.636847],[0.3536,-0.6356,6.7217])),
                    #(false,true,#([0.104,-0.6356,6.7217],[0.140553,-0.5564,6.6617],[0.2288,-0.523594,6.636847],[0.317047,-0.5564,6.6617],[0.3536,-0.6356,6.7217]))
                ) "dark" "mask" true 0.0
                f.tube "JacketSeam" #([0.28,-0.7,3.35],[0.27,-0.74,4.45],[0.17,-0.59,5.38]) 0.105 5 false true "cyan_glow" "body"
                f.tube "RaisedCuff" #([1.68,-0.32,5.94],[1.98,-0.34,6.02],[2.16,-0.1,6.0]) 0.09 5 false true "cyan_glow" "body"
                f.finishModel()
                f.startModel "paradecivilian3" "The poncho courier" "civilian" 3 0.23 [0.0,-0.04,5.93] "Offset poncho, messenger bag, peaked rain cap and staggered feet." true
                f.cage "ForwardShoe" #(
                    #(true,true,#([-0.732132,-0.055736,0.21],[-0.732132,-0.18,0.315],[-0.732132,-0.48,0.358492],[-0.732132,-0.78,0.315],[-0.732132,-0.904264,0.21],[-0.732132,-0.78,0.105],[-0.732132,-0.48,0.061508],[-0.732132,-0.18,0.105])),
                    #(true,true,#([-0.52,0.12,0.21],[-0.52,-0.055736,0.358492],[-0.52,-0.48,0.42],[-0.52,-0.904264,0.358492],[-0.52,-1.08,0.21],[-0.52,-0.904264,0.061508],[-0.52,-0.48,0.0],[-0.52,-0.055736,0.061508])),
                    #(true,true,#([-0.307868,-0.055736,0.21],[-0.307868,-0.18,0.315],[-0.307868,-0.48,0.358492],[-0.307868,-0.78,0.315],[-0.307868,-0.904264,0.21],[-0.307868,-0.78,0.105],[-0.307868,-0.48,0.061508],[-0.307868,-0.18,0.105])),
                    #(false,true,#([-0.82,-0.48,0.21],[-0.732132,-0.055736,0.21],[-0.52,0.12,0.21],[-0.307868,-0.055736,0.21],[-0.22,-0.48,0.21])),
                    #(false,true,#([-0.82,-0.48,0.21],[-0.732132,-0.18,0.315],[-0.52,-0.055736,0.358492],[-0.307868,-0.18,0.315],[-0.22,-0.48,0.21])),
                    #(false,true,#([-0.82,-0.48,0.21],[-0.732132,-0.48,0.358492],[-0.52,-0.48,0.42],[-0.307868,-0.48,0.358492],[-0.22,-0.48,0.21])),
                    #(false,true,#([-0.82,-0.48,0.21],[-0.732132,-0.78,0.315],[-0.52,-0.904264,0.358492],[-0.307868,-0.78,0.315],[-0.22,-0.48,0.21])),
                    #(false,true,#([-0.82,-0.48,0.21],[-0.732132,-0.904264,0.21],[-0.52,-1.08,0.21],[-0.307868,-0.904264,0.21],[-0.22,-0.48,0.21])),
                    #(false,true,#([-0.82,-0.48,0.21],[-0.732132,-0.78,0.105],[-0.52,-0.904264,0.061508],[-0.307868,-0.78,0.105],[-0.22,-0.48,0.21])),
                    #(false,true,#([-0.82,-0.48,0.21],[-0.732132,-0.48,0.061508],[-0.52,-0.48,0.0],[-0.307868,-0.48,0.061508],[-0.22,-0.48,0.21])),
                    #(false,true,#([-0.82,-0.48,0.21],[-0.732132,-0.18,0.105],[-0.52,-0.055736,0.061508],[-0.307868,-0.18,0.105],[-0.22,-0.48,0.21]))
                ) "dark" "body" true 0.0
                f.cage "BackShoe" #(
                    #(true,true,#([0.267868,0.703051,0.21],[0.267868,0.585,0.315],[0.267868,0.3,0.358492],[0.267868,0.015,0.315],[0.267868,-0.103051,0.21],[0.267868,0.015,0.105],[0.267868,0.3,0.061508],[0.267868,0.585,0.105])),
                    #(true,true,#([0.48,0.87,0.21],[0.48,0.703051,0.358492],[0.48,0.3,0.42],[0.48,-0.103051,0.358492],[0.48,-0.27,0.21],[0.48,-0.103051,0.061508],[0.48,0.3,0.0],[0.48,0.703051,0.061508])),
                    #(true,true,#([0.692132,0.703051,0.21],[0.692132,0.585,0.315],[0.692132,0.3,0.358492],[0.692132,0.015,0.315],[0.692132,-0.103051,0.21],[0.692132,0.015,0.105],[0.692132,0.3,0.061508],[0.692132,0.585,0.105])),
                    #(false,true,#([0.18,0.3,0.21],[0.267868,0.703051,0.21],[0.48,0.87,0.21],[0.692132,0.703051,0.21],[0.78,0.3,0.21])),
                    #(false,true,#([0.18,0.3,0.21],[0.267868,0.585,0.315],[0.48,0.703051,0.358492],[0.692132,0.585,0.315],[0.78,0.3,0.21])),
                    #(false,true,#([0.18,0.3,0.21],[0.267868,0.3,0.358492],[0.48,0.3,0.42],[0.692132,0.3,0.358492],[0.78,0.3,0.21])),
                    #(false,true,#([0.18,0.3,0.21],[0.267868,0.015,0.315],[0.48,-0.103051,0.358492],[0.692132,0.015,0.315],[0.78,0.3,0.21])),
                    #(false,true,#([0.18,0.3,0.21],[0.267868,-0.103051,0.21],[0.48,-0.27,0.21],[0.692132,-0.103051,0.21],[0.78,0.3,0.21])),
                    #(false,true,#([0.18,0.3,0.21],[0.267868,0.015,0.105],[0.48,-0.103051,0.061508],[0.692132,0.015,0.105],[0.78,0.3,0.21])),
                    #(false,true,#([0.18,0.3,0.21],[0.267868,0.3,0.061508],[0.48,0.3,0.0],[0.692132,0.3,0.061508],[0.78,0.3,0.21])),
                    #(false,true,#([0.18,0.3,0.21],[0.267868,0.585,0.105],[0.48,0.703051,0.061508],[0.692132,0.585,0.105],[0.78,0.3,0.21]))
                ) "dark" "body" true 0.0
                f.cage "LeftLeg" #(
                    #(true,true,#([-0.779424,-0.24,0.332705],[-0.705053,-0.422242,0.361962],[-0.522281,-0.497729,0.384212],[-0.338172,-0.422242,0.386421],[-0.260576,-0.24,0.367295],[-0.334947,-0.057758,0.338038],[-0.517719,0.017729,0.315788],[-0.701828,-0.057758,0.313579])),
                    #(true,true,#([-0.92992,-0.036669,1.856197],[-0.840985,-0.255397,1.879494],[-0.6226,-0.347948,1.885515],[-0.402692,-0.260108,1.870731],[-0.31008,-0.043331,1.843803],[-0.399015,0.175397,1.820506],[-0.6174,0.267948,1.814485],[-0.837308,0.180108,1.829269])),
                    #(true,true,#([-0.79788,0.127173,3.538346],[-0.695476,-0.128261,3.551944],[-0.443418,-0.238267,3.535114],[-0.189358,-0.138405,3.497715],[-0.08212,0.112827,3.461654],[-0.184524,0.368261,3.448056],[-0.436582,0.478267,3.464886],[-0.690642,0.378405,3.502285])),
                    #(false,true,#([-0.52,-0.24,0.35],[-0.779424,-0.24,0.332705],[-0.92992,-0.036669,1.856197],[-0.79788,0.127173,3.538346],[-0.44,0.12,3.5])),
                    #(false,true,#([-0.52,-0.24,0.35],[-0.705053,-0.422242,0.361962],[-0.840985,-0.255397,1.879494],[-0.695476,-0.128261,3.551944],[-0.44,0.12,3.5])),
                    #(false,true,#([-0.52,-0.24,0.35],[-0.522281,-0.497729,0.384212],[-0.6226,-0.347948,1.885515],[-0.443418,-0.238267,3.535114],[-0.44,0.12,3.5])),
                    #(false,true,#([-0.52,-0.24,0.35],[-0.338172,-0.422242,0.386421],[-0.402692,-0.260108,1.870731],[-0.189358,-0.138405,3.497715],[-0.44,0.12,3.5])),
                    #(false,true,#([-0.52,-0.24,0.35],[-0.260576,-0.24,0.367295],[-0.31008,-0.043331,1.843803],[-0.08212,0.112827,3.461654],[-0.44,0.12,3.5])),
                    #(false,true,#([-0.52,-0.24,0.35],[-0.334947,-0.057758,0.338038],[-0.399015,0.175397,1.820506],[-0.184524,0.368261,3.448056],[-0.44,0.12,3.5])),
                    #(false,true,#([-0.52,-0.24,0.35],[-0.517719,0.017729,0.315788],[-0.6174,0.267948,1.814485],[-0.436582,0.478267,3.464886],[-0.44,0.12,3.5])),
                    #(false,true,#([-0.52,-0.24,0.35],[-0.701828,-0.057758,0.313579],[-0.837308,0.180108,1.829269],[-0.690642,0.378405,3.502285],[-0.44,0.12,3.5]))
                ) "dark" "body" true 0.0
                f.cage "RightLeg" #(
                    #(true,true,#([0.221932,0.42,0.381634],[0.296802,0.236246,0.366529],[0.478988,0.160133,0.341741],[0.661766,0.236246,0.321791],[0.738068,0.42,0.318366],[0.663198,0.603754,0.333471],[0.481012,0.679867,0.358259],[0.298234,0.603754,0.378209])),
                    #(true,true,#([0.360009,0.372204,1.899012],[0.449307,0.153086,1.881483],[0.667883,0.061033,1.874801],[0.8877,0.149969,1.88288],[0.979991,0.367796,1.900988],[0.890693,0.586914,1.918517],[0.672117,0.678967,1.925199],[0.4523,0.590031,1.91712])),
                    #(true,true,#([0.103012,0.167313,3.454105],[0.206675,-0.087206,3.434305],[0.458732,-0.196915,3.452989],[0.711532,-0.097548,3.49921],[0.816988,0.152687,3.545895],[0.713325,0.407206,3.565695],[0.461268,0.516915,3.547011],[0.208468,0.417548,3.50079])),
                    #(false,true,#([0.48,0.42,0.35],[0.221932,0.42,0.381634],[0.360009,0.372204,1.899012],[0.103012,0.167313,3.454105],[0.46,0.16,3.5])),
                    #(false,true,#([0.48,0.42,0.35],[0.296802,0.236246,0.366529],[0.449307,0.153086,1.881483],[0.206675,-0.087206,3.434305],[0.46,0.16,3.5])),
                    #(false,true,#([0.48,0.42,0.35],[0.478988,0.160133,0.341741],[0.667883,0.061033,1.874801],[0.458732,-0.196915,3.452989],[0.46,0.16,3.5])),
                    #(false,true,#([0.48,0.42,0.35],[0.661766,0.236246,0.321791],[0.8877,0.149969,1.88288],[0.711532,-0.097548,3.49921],[0.46,0.16,3.5])),
                    #(false,true,#([0.48,0.42,0.35],[0.738068,0.42,0.318366],[0.979991,0.367796,1.900988],[0.816988,0.152687,3.545895],[0.46,0.16,3.5])),
                    #(false,true,#([0.48,0.42,0.35],[0.663198,0.603754,0.333471],[0.890693,0.586914,1.918517],[0.713325,0.407206,3.565695],[0.46,0.16,3.5])),
                    #(false,true,#([0.48,0.42,0.35],[0.481012,0.679867,0.358259],[0.672117,0.678967,1.925199],[0.461268,0.516915,3.547011],[0.46,0.16,3.5])),
                    #(false,true,#([0.48,0.42,0.35],[0.298234,0.603754,0.378209],[0.4523,0.590031,1.91712],[0.208468,0.417548,3.50079],[0.46,0.16,3.5]))
                ) "dark" "body" true 0.0
                f.cage "AsymmetricPoncho" #(
                    #(true,true,#([1.65,0.16,2.85],[1.21066,0.697401,2.85],[0.15,0.92,2.85],[-0.91066,0.697401,2.85],[-1.35,0.16,2.85],[-0.91066,-0.377401,2.85],[0.15,-0.6,2.85],[1.21066,-0.377401,2.85])),
                    #(true,true,#([1.45,0.1,3.7],[1.039949,0.665685,3.7],[0.05,0.9,3.7],[-0.939949,0.665685,3.7],[-1.35,0.1,3.7],[-0.939949,-0.465685,3.7],[0.05,-0.7,3.7],[1.039949,-0.465685,3.7])),
                    #(true,true,#([1.17,0.0,5.45],[0.827315,0.46669,5.45],[0.0,0.66,5.45],[-0.827315,0.46669,5.45],[-1.17,0.0,5.45],[-0.827315,-0.46669,5.45],[0.0,-0.66,5.45],[0.827315,-0.46669,5.45])),
                    #(true,true,#([0.54,-0.04,5.86],[0.381838,0.271127,5.86],[0.0,0.4,5.86],[-0.381838,0.271127,5.86],[-0.54,-0.04,5.86],[-0.381838,-0.351127,5.86],[0.0,-0.48,5.86],[0.381838,-0.351127,5.86])),
                    #(false,true,#([0.15,0.16,2.85],[1.65,0.16,2.85],[1.45,0.1,3.7],[1.17,0.0,5.45],[0.54,-0.04,5.86],[0.0,-0.04,5.86])),
                    #(false,true,#([0.15,0.16,2.85],[1.21066,0.697401,2.85],[1.039949,0.665685,3.7],[0.827315,0.46669,5.45],[0.381838,0.271127,5.86],[0.0,-0.04,5.86])),
                    #(false,true,#([0.15,0.16,2.85],[0.15,0.92,2.85],[0.05,0.9,3.7],[0.0,0.66,5.45],[0.0,0.4,5.86],[0.0,-0.04,5.86])),
                    #(false,true,#([0.15,0.16,2.85],[-0.91066,0.697401,2.85],[-0.939949,0.665685,3.7],[-0.827315,0.46669,5.45],[-0.381838,0.271127,5.86],[0.0,-0.04,5.86])),
                    #(false,true,#([0.15,0.16,2.85],[-1.35,0.16,2.85],[-1.35,0.1,3.7],[-1.17,0.0,5.45],[-0.54,-0.04,5.86],[0.0,-0.04,5.86])),
                    #(false,true,#([0.15,0.16,2.85],[-0.91066,-0.377401,2.85],[-0.939949,-0.465685,3.7],[-0.827315,-0.46669,5.45],[-0.381838,-0.351127,5.86],[0.0,-0.04,5.86])),
                    #(false,true,#([0.15,0.16,2.85],[0.15,-0.6,2.85],[0.05,-0.7,3.7],[0.0,-0.66,5.45],[0.0,-0.48,5.86],[0.0,-0.04,5.86])),
                    #(false,true,#([0.15,0.16,2.85],[1.21066,-0.377401,2.85],[1.039949,-0.465685,3.7],[0.827315,-0.46669,5.45],[0.381838,-0.351127,5.86],[0.0,-0.04,5.86]))
                ) "dark" "body" true 0.0
                f.cage "LeftArm" #(
                    #(true,true,#([-0.764307,-0.04,5.010037],[-0.8302,-0.239391,5.081911],[-1.018991,-0.321982,5.164382],[-1.220089,-0.239391,5.209138],[-1.315693,-0.04,5.189963],[-1.2498,0.159391,5.118089],[-1.061009,0.241982,5.035618],[-0.859911,0.159391,4.990862])),
                    #(true,true,#([-1.10104,-0.264667,4.133159],[-1.160548,-0.440226,4.180585],[-1.331035,-0.521928,4.210094],[-1.512631,-0.461911,4.204401],[-1.59896,-0.295333,4.166841],[-1.539452,-0.119774,4.119415],[-1.368965,-0.038072,4.089906],[-1.187369,-0.098089,4.095599])),
                    #(true,true,#([-0.924773,-0.525313,3.115735],[-0.971436,-0.668734,3.141895],[-1.105126,-0.742603,3.131798],[-1.247529,-0.703647,3.091358],[-1.315227,-0.574687,3.044265],[-1.268564,-0.431266,3.018105],[-1.134874,-0.357397,3.028202],[-0.992471,-0.396353,3.068642])),
                    #(false,true,#([-1.04,-0.04,5.1],[-0.764307,-0.04,5.010037],[-1.10104,-0.264667,4.133159],[-0.924773,-0.525313,3.115735],[-1.12,-0.55,3.08])),
                    #(false,true,#([-1.04,-0.04,5.1],[-0.8302,-0.239391,5.081911],[-1.160548,-0.440226,4.180585],[-0.971436,-0.668734,3.141895],[-1.12,-0.55,3.08])),
                    #(false,true,#([-1.04,-0.04,5.1],[-1.018991,-0.321982,5.164382],[-1.331035,-0.521928,4.210094],[-1.105126,-0.742603,3.131798],[-1.12,-0.55,3.08])),
                    #(false,true,#([-1.04,-0.04,5.1],[-1.220089,-0.239391,5.209138],[-1.512631,-0.461911,4.204401],[-1.247529,-0.703647,3.091358],[-1.12,-0.55,3.08])),
                    #(false,true,#([-1.04,-0.04,5.1],[-1.315693,-0.04,5.189963],[-1.59896,-0.295333,4.166841],[-1.315227,-0.574687,3.044265],[-1.12,-0.55,3.08])),
                    #(false,true,#([-1.04,-0.04,5.1],[-1.2498,0.159391,5.118089],[-1.539452,-0.119774,4.119415],[-1.268564,-0.431266,3.018105],[-1.12,-0.55,3.08])),
                    #(false,true,#([-1.04,-0.04,5.1],[-1.061009,0.241982,5.035618],[-1.368965,-0.038072,4.089906],[-1.134874,-0.357397,3.028202],[-1.12,-0.55,3.08])),
                    #(false,true,#([-1.04,-0.04,5.1],[-0.859911,0.159391,4.990862],[-1.187369,-0.098089,4.095599],[-0.992471,-0.396353,3.068642],[-1.12,-0.55,3.08]))
                ) "dark" "body" true 0.0
                f.cage "LeftHand" #(
                    #(true,true,#([-1.248492,-0.42565,2.92],[-1.248492,-0.465,3.065],[-1.248492,-0.56,3.125061],[-1.248492,-0.655,3.065],[-1.248492,-0.69435,2.92],[-1.248492,-0.655,2.775],[-1.248492,-0.56,2.714939],[-1.248492,-0.465,2.775])),
                    #(true,true,#([-1.1,-0.37,2.92],[-1.1,-0.42565,3.125061],[-1.1,-0.56,3.21],[-1.1,-0.69435,3.125061],[-1.1,-0.75,2.92],[-1.1,-0.69435,2.714939],[-1.1,-0.56,2.63],[-1.1,-0.42565,2.714939])),
                    #(true,true,#([-0.951508,-0.42565,2.92],[-0.951508,-0.465,3.065],[-0.951508,-0.56,3.125061],[-0.951508,-0.655,3.065],[-0.951508,-0.69435,2.92],[-0.951508,-0.655,2.775],[-0.951508,-0.56,2.714939],[-0.951508,-0.465,2.775])),
                    #(false,true,#([-1.31,-0.56,2.92],[-1.248492,-0.42565,2.92],[-1.1,-0.37,2.92],[-0.951508,-0.42565,2.92],[-0.89,-0.56,2.92])),
                    #(false,true,#([-1.31,-0.56,2.92],[-1.248492,-0.465,3.065],[-1.1,-0.42565,3.125061],[-0.951508,-0.465,3.065],[-0.89,-0.56,2.92])),
                    #(false,true,#([-1.31,-0.56,2.92],[-1.248492,-0.56,3.125061],[-1.1,-0.56,3.21],[-0.951508,-0.56,3.125061],[-0.89,-0.56,2.92])),
                    #(false,true,#([-1.31,-0.56,2.92],[-1.248492,-0.655,3.065],[-1.1,-0.69435,3.125061],[-0.951508,-0.655,3.065],[-0.89,-0.56,2.92])),
                    #(false,true,#([-1.31,-0.56,2.92],[-1.248492,-0.69435,2.92],[-1.1,-0.75,2.92],[-0.951508,-0.69435,2.92],[-0.89,-0.56,2.92])),
                    #(false,true,#([-1.31,-0.56,2.92],[-1.248492,-0.655,2.775],[-1.1,-0.69435,2.714939],[-0.951508,-0.655,2.775],[-0.89,-0.56,2.92])),
                    #(false,true,#([-1.31,-0.56,2.92],[-1.248492,-0.56,2.714939],[-1.1,-0.56,2.63],[-0.951508,-0.56,2.714939],[-0.89,-0.56,2.92])),
                    #(false,true,#([-1.31,-0.56,2.92],[-1.248492,-0.465,2.775],[-1.1,-0.42565,2.714939],[-0.951508,-0.465,2.775],[-0.89,-0.56,2.92]))
                ) "teal" "body" true 0.0
                f.cage "RightArm" #(
                    #(true,true,#([0.802898,-0.180346,5.1],[0.761043,0.008944,4.991915],[0.87674,0.192994,4.947145],[1.082214,0.263991,4.991915],[1.257102,0.180346,5.1],[1.298957,-0.008944,5.208085],[1.18326,-0.192994,5.252855],[0.977786,-0.263991,5.208085])),
                    #(true,true,#([1.107278,-0.392049,4.550496],[1.070693,-0.245882,4.432562],[1.168434,-0.154848,4.295554],[1.343244,-0.172273,4.219729],[1.492722,-0.287951,4.249504],[1.529307,-0.434118,4.367438],[1.431566,-0.525152,4.504446],[1.256756,-0.507727,4.580271])),
                    #(true,true,#([0.430745,-0.781033,4.454638],[0.385862,-0.679005,4.349723],[0.401982,-0.665427,4.198107],[0.469662,-0.748254,4.088605],[0.549255,-0.878967,4.085362],[0.594138,-0.980995,4.190277],[0.578018,-0.994573,4.341893],[0.510338,-0.911746,4.451395])),
                    #(false,true,#([1.03,0.0,5.1],[0.802898,-0.180346,5.1],[1.107278,-0.392049,4.550496],[0.430745,-0.781033,4.454638],[0.49,-0.83,4.27])),
                    #(false,true,#([1.03,0.0,5.1],[0.761043,0.008944,4.991915],[1.070693,-0.245882,4.432562],[0.385862,-0.679005,4.349723],[0.49,-0.83,4.27])),
                    #(false,true,#([1.03,0.0,5.1],[0.87674,0.192994,4.947145],[1.168434,-0.154848,4.295554],[0.401982,-0.665427,4.198107],[0.49,-0.83,4.27])),
                    #(false,true,#([1.03,0.0,5.1],[1.082214,0.263991,4.991915],[1.343244,-0.172273,4.219729],[0.469662,-0.748254,4.088605],[0.49,-0.83,4.27])),
                    #(false,true,#([1.03,0.0,5.1],[1.257102,0.180346,5.1],[1.492722,-0.287951,4.249504],[0.549255,-0.878967,4.085362],[0.49,-0.83,4.27])),
                    #(false,true,#([1.03,0.0,5.1],[1.298957,-0.008944,5.208085],[1.529307,-0.434118,4.367438],[0.594138,-0.980995,4.190277],[0.49,-0.83,4.27])),
                    #(false,true,#([1.03,0.0,5.1],[1.18326,-0.192994,5.252855],[1.431566,-0.525152,4.504446],[0.578018,-0.994573,4.341893],[0.49,-0.83,4.27])),
                    #(false,true,#([1.03,0.0,5.1],[0.977786,-0.263991,5.208085],[1.256756,-0.507727,4.580271],[0.510338,-0.911746,4.451395],[0.49,-0.83,4.27]))
                ) "dark" "body" true 0.0
                f.cage "StrapHand" #(
                    #(true,true,#([0.303223,-0.712721,4.27],[0.303223,-0.75,4.385],[0.303223,-0.84,4.432635],[0.303223,-0.93,4.385],[0.303223,-0.967279,4.27],[0.303223,-0.93,4.155],[0.303223,-0.84,4.107365],[0.303223,-0.75,4.155])),
                    #(true,true,#([0.48,-0.66,4.27],[0.48,-0.712721,4.432635],[0.48,-0.84,4.5],[0.48,-0.967279,4.432635],[0.48,-1.02,4.27],[0.48,-0.967279,4.107365],[0.48,-0.84,4.04],[0.48,-0.712721,4.107365])),
                    #(true,true,#([0.656777,-0.712721,4.27],[0.656777,-0.75,4.385],[0.656777,-0.84,4.432635],[0.656777,-0.93,4.385],[0.656777,-0.967279,4.27],[0.656777,-0.93,4.155],[0.656777,-0.84,4.107365],[0.656777,-0.75,4.155])),
                    #(false,true,#([0.23,-0.84,4.27],[0.303223,-0.712721,4.27],[0.48,-0.66,4.27],[0.656777,-0.712721,4.27],[0.73,-0.84,4.27])),
                    #(false,true,#([0.23,-0.84,4.27],[0.303223,-0.75,4.385],[0.48,-0.712721,4.432635],[0.656777,-0.75,4.385],[0.73,-0.84,4.27])),
                    #(false,true,#([0.23,-0.84,4.27],[0.303223,-0.84,4.432635],[0.48,-0.84,4.5],[0.656777,-0.84,4.432635],[0.73,-0.84,4.27])),
                    #(false,true,#([0.23,-0.84,4.27],[0.303223,-0.93,4.385],[0.48,-0.967279,4.432635],[0.656777,-0.93,4.385],[0.73,-0.84,4.27])),
                    #(false,true,#([0.23,-0.84,4.27],[0.303223,-0.967279,4.27],[0.48,-1.02,4.27],[0.656777,-0.967279,4.27],[0.73,-0.84,4.27])),
                    #(false,true,#([0.23,-0.84,4.27],[0.303223,-0.93,4.155],[0.48,-0.967279,4.107365],[0.656777,-0.93,4.155],[0.73,-0.84,4.27])),
                    #(false,true,#([0.23,-0.84,4.27],[0.303223,-0.84,4.107365],[0.48,-0.84,4.04],[0.656777,-0.84,4.107365],[0.73,-0.84,4.27])),
                    #(false,true,#([0.23,-0.84,4.27],[0.303223,-0.75,4.155],[0.48,-0.712721,4.107365],[0.656777,-0.75,4.155],[0.73,-0.84,4.27]))
                ) "teal" "body" true 0.0
                f.cage "MessengerBag" #(
                    #(true,false,#([0.51682,-0.027626,2.493061],[1.183649,-0.121343,2.398423],[1.300554,0.710482,2.398423],[0.633725,0.804199,2.493061])),
                    #(true,false,#([0.679446,-0.050482,3.661577],[1.346275,-0.144199,3.566939],[1.46318,0.687626,3.566939],[0.796351,0.781343,3.661577])),
                    #(false,false,#([0.51682,-0.027626,2.493061],[0.679446,-0.050482,3.661577])),
                    #(false,false,#([1.183649,-0.121343,2.398423],[1.346275,-0.144199,3.566939])),
                    #(false,false,#([1.300554,0.710482,2.398423],[1.46318,0.687626,3.566939])),
                    #(false,false,#([0.633725,0.804199,2.493061],[0.796351,0.781343,3.661577]))
                ) "teal" "body" true 0.0
                f.tube "DiagonalStrap" #([-0.66,-0.5,5.55],[0.02,-0.79,4.5],[0.85,-0.73,3.32]) 0.16 5 false true "teal" "body"
                f.cage "Head" #(
                    #(true,true,#([-0.431335,0.276482,6.74],[-0.431335,0.175,7.13],[-0.431335,-0.07,7.291543],[-0.431335,-0.315,7.13],[-0.431335,-0.416482,6.74],[-0.431335,-0.315,6.35],[-0.431335,-0.07,6.188457],[-0.431335,0.175,6.35])),
                    #(true,true,#([0.0,0.42,6.74],[0.0,0.276482,7.291543],[0.0,-0.07,7.52],[0.0,-0.416482,7.291543],[0.0,-0.56,6.74],[0.0,-0.416482,6.188457],[0.0,-0.07,5.96],[0.0,0.276482,6.188457])),
                    #(true,true,#([0.431335,0.276482,6.74],[0.431335,0.175,7.13],[0.431335,-0.07,7.291543],[0.431335,-0.315,7.13],[0.431335,-0.416482,6.74],[0.431335,-0.315,6.35],[0.431335,-0.07,6.188457],[0.431335,0.175,6.35])),
                    #(false,true,#([-0.61,-0.07,6.74],[-0.431335,0.276482,6.74],[0.0,0.42,6.74],[0.431335,0.276482,6.74],[0.61,-0.07,6.74])),
                    #(false,true,#([-0.61,-0.07,6.74],[-0.431335,0.175,7.13],[0.0,0.276482,7.291543],[0.431335,0.175,7.13],[0.61,-0.07,6.74])),
                    #(false,true,#([-0.61,-0.07,6.74],[-0.431335,-0.07,7.291543],[0.0,-0.07,7.52],[0.431335,-0.07,7.291543],[0.61,-0.07,6.74])),
                    #(false,true,#([-0.61,-0.07,6.74],[-0.431335,-0.315,7.13],[0.0,-0.416482,7.291543],[0.431335,-0.315,7.13],[0.61,-0.07,6.74])),
                    #(false,true,#([-0.61,-0.07,6.74],[-0.431335,-0.416482,6.74],[0.0,-0.56,6.74],[0.431335,-0.416482,6.74],[0.61,-0.07,6.74])),
                    #(false,true,#([-0.61,-0.07,6.74],[-0.431335,-0.315,6.35],[0.0,-0.416482,6.188457],[0.431335,-0.315,6.35],[0.61,-0.07,6.74])),
                    #(false,true,#([-0.61,-0.07,6.74],[-0.431335,-0.07,6.188457],[0.0,-0.07,5.96],[0.431335,-0.07,6.188457],[0.61,-0.07,6.74])),
                    #(false,true,#([-0.61,-0.07,6.74],[-0.431335,0.175,6.35],[0.0,0.276482,6.188457],[0.431335,0.175,6.35],[0.61,-0.07,6.74]))
                ) "dark" "head" true 0.0
                f.cage "FacePlate" #(
                    #(true,true,#([-0.346482,-0.418076,6.68],[-0.346482,-0.445,7.005],[-0.346482,-0.51,7.139619],[-0.346482,-0.575,7.005],[-0.346482,-0.601924,6.68],[-0.346482,-0.575,6.355],[-0.346482,-0.51,6.220381],[-0.346482,-0.445,6.355])),
                    #(true,true,#([0.0,-0.38,6.68],[0.0,-0.418076,7.139619],[0.0,-0.51,7.33],[0.0,-0.601924,7.139619],[0.0,-0.64,6.68],[0.0,-0.601924,6.220381],[0.0,-0.51,6.03],[0.0,-0.418076,6.220381])),
                    #(true,true,#([0.346482,-0.418076,6.68],[0.346482,-0.445,7.005],[0.346482,-0.51,7.139619],[0.346482,-0.575,7.005],[0.346482,-0.601924,6.68],[0.346482,-0.575,6.355],[0.346482,-0.51,6.220381],[0.346482,-0.445,6.355])),
                    #(false,true,#([-0.49,-0.51,6.68],[-0.346482,-0.418076,6.68],[0.0,-0.38,6.68],[0.346482,-0.418076,6.68],[0.49,-0.51,6.68])),
                    #(false,true,#([-0.49,-0.51,6.68],[-0.346482,-0.445,7.005],[0.0,-0.418076,7.139619],[0.346482,-0.445,7.005],[0.49,-0.51,6.68])),
                    #(false,true,#([-0.49,-0.51,6.68],[-0.346482,-0.51,7.139619],[0.0,-0.51,7.33],[0.346482,-0.51,7.139619],[0.49,-0.51,6.68])),
                    #(false,true,#([-0.49,-0.51,6.68],[-0.346482,-0.575,7.005],[0.0,-0.601924,7.139619],[0.346482,-0.575,7.005],[0.49,-0.51,6.68])),
                    #(false,true,#([-0.49,-0.51,6.68],[-0.346482,-0.601924,6.68],[0.0,-0.64,6.68],[0.346482,-0.601924,6.68],[0.49,-0.51,6.68])),
                    #(false,true,#([-0.49,-0.51,6.68],[-0.346482,-0.575,6.355],[0.0,-0.601924,6.220381],[0.346482,-0.575,6.355],[0.49,-0.51,6.68])),
                    #(false,true,#([-0.49,-0.51,6.68],[-0.346482,-0.51,6.220381],[0.0,-0.51,6.03],[0.346482,-0.51,6.220381],[0.49,-0.51,6.68])),
                    #(false,true,#([-0.49,-0.51,6.68],[-0.346482,-0.445,6.355],[0.0,-0.418076,6.220381],[0.346482,-0.445,6.355],[0.49,-0.51,6.68]))
                ) "ivory_glow" "mask" true 0.0
                f.cage "EyeLeft" #(
                    #(true,true,#([-0.298756,-0.548707,6.797],[-0.298756,-0.5724,6.86525],[-0.298756,-0.6296,6.89352],[-0.298756,-0.6868,6.86525],[-0.298756,-0.710493,6.797],[-0.298756,-0.6868,6.72875],[-0.298756,-0.6296,6.70048],[-0.298756,-0.5724,6.72875])),
                    #(true,true,#([-0.2156,-0.5152,6.797],[-0.2156,-0.548707,6.89352],[-0.2156,-0.6296,6.9335],[-0.2156,-0.710493,6.89352],[-0.2156,-0.744,6.797],[-0.2156,-0.710493,6.70048],[-0.2156,-0.6296,6.6605],[-0.2156,-0.548707,6.70048])),
                    #(true,true,#([-0.132444,-0.548707,6.797],[-0.132444,-0.5724,6.86525],[-0.132444,-0.6296,6.89352],[-0.132444,-0.6868,6.86525],[-0.132444,-0.710493,6.797],[-0.132444,-0.6868,6.72875],[-0.132444,-0.6296,6.70048],[-0.132444,-0.5724,6.72875])),
                    #(false,true,#([-0.3332,-0.6296,6.797],[-0.298756,-0.548707,6.797],[-0.2156,-0.5152,6.797],[-0.132444,-0.548707,6.797],[-0.098,-0.6296,6.797])),
                    #(false,true,#([-0.3332,-0.6296,6.797],[-0.298756,-0.5724,6.86525],[-0.2156,-0.548707,6.89352],[-0.132444,-0.5724,6.86525],[-0.098,-0.6296,6.797])),
                    #(false,true,#([-0.3332,-0.6296,6.797],[-0.298756,-0.6296,6.89352],[-0.2156,-0.6296,6.9335],[-0.132444,-0.6296,6.89352],[-0.098,-0.6296,6.797])),
                    #(false,true,#([-0.3332,-0.6296,6.797],[-0.298756,-0.6868,6.86525],[-0.2156,-0.710493,6.89352],[-0.132444,-0.6868,6.86525],[-0.098,-0.6296,6.797])),
                    #(false,true,#([-0.3332,-0.6296,6.797],[-0.298756,-0.710493,6.797],[-0.2156,-0.744,6.797],[-0.132444,-0.710493,6.797],[-0.098,-0.6296,6.797])),
                    #(false,true,#([-0.3332,-0.6296,6.797],[-0.298756,-0.6868,6.72875],[-0.2156,-0.710493,6.70048],[-0.132444,-0.6868,6.72875],[-0.098,-0.6296,6.797])),
                    #(false,true,#([-0.3332,-0.6296,6.797],[-0.298756,-0.6296,6.70048],[-0.2156,-0.6296,6.6605],[-0.132444,-0.6296,6.70048],[-0.098,-0.6296,6.797])),
                    #(false,true,#([-0.3332,-0.6296,6.797],[-0.298756,-0.5724,6.72875],[-0.2156,-0.548707,6.70048],[-0.132444,-0.5724,6.72875],[-0.098,-0.6296,6.797]))
                ) "dark" "mask" true 0.0
                f.cage "EyeRight" #(
                    #(true,true,#([0.132444,-0.548707,6.797],[0.132444,-0.5724,6.86525],[0.132444,-0.6296,6.89352],[0.132444,-0.6868,6.86525],[0.132444,-0.710493,6.797],[0.132444,-0.6868,6.72875],[0.132444,-0.6296,6.70048],[0.132444,-0.5724,6.72875])),
                    #(true,true,#([0.2156,-0.5152,6.797],[0.2156,-0.548707,6.89352],[0.2156,-0.6296,6.9335],[0.2156,-0.710493,6.89352],[0.2156,-0.744,6.797],[0.2156,-0.710493,6.70048],[0.2156,-0.6296,6.6605],[0.2156,-0.548707,6.70048])),
                    #(true,true,#([0.298756,-0.548707,6.797],[0.298756,-0.5724,6.86525],[0.298756,-0.6296,6.89352],[0.298756,-0.6868,6.86525],[0.298756,-0.710493,6.797],[0.298756,-0.6868,6.72875],[0.298756,-0.6296,6.70048],[0.298756,-0.5724,6.72875])),
                    #(false,true,#([0.098,-0.6296,6.797],[0.132444,-0.548707,6.797],[0.2156,-0.5152,6.797],[0.298756,-0.548707,6.797],[0.3332,-0.6296,6.797])),
                    #(false,true,#([0.098,-0.6296,6.797],[0.132444,-0.5724,6.86525],[0.2156,-0.548707,6.89352],[0.298756,-0.5724,6.86525],[0.3332,-0.6296,6.797])),
                    #(false,true,#([0.098,-0.6296,6.797],[0.132444,-0.6296,6.89352],[0.2156,-0.6296,6.9335],[0.298756,-0.6296,6.89352],[0.3332,-0.6296,6.797])),
                    #(false,true,#([0.098,-0.6296,6.797],[0.132444,-0.6868,6.86525],[0.2156,-0.710493,6.89352],[0.298756,-0.6868,6.86525],[0.3332,-0.6296,6.797])),
                    #(false,true,#([0.098,-0.6296,6.797],[0.132444,-0.710493,6.797],[0.2156,-0.744,6.797],[0.298756,-0.710493,6.797],[0.3332,-0.6296,6.797])),
                    #(false,true,#([0.098,-0.6296,6.797],[0.132444,-0.6868,6.72875],[0.2156,-0.710493,6.70048],[0.298756,-0.6868,6.72875],[0.3332,-0.6296,6.797])),
                    #(false,true,#([0.098,-0.6296,6.797],[0.132444,-0.6296,6.70048],[0.2156,-0.6296,6.6605],[0.298756,-0.6296,6.70048],[0.3332,-0.6296,6.797])),
                    #(false,true,#([0.098,-0.6296,6.797],[0.132444,-0.5724,6.72875],[0.2156,-0.548707,6.70048],[0.298756,-0.5724,6.72875],[0.3332,-0.6296,6.797]))
                ) "dark" "mask" true 0.0
                f.cage "QuietMouth" #(
                    #(true,false,#([-0.1323,-0.731,6.321],[0.1323,-0.731,6.321],[0.1323,-0.549,6.321],[-0.1323,-0.549,6.321])),
                    #(true,false,#([-0.1323,-0.731,6.441],[0.1323,-0.731,6.441],[0.1323,-0.549,6.441],[-0.1323,-0.549,6.441])),
                    #(false,false,#([-0.1323,-0.731,6.321],[-0.1323,-0.731,6.441])),
                    #(false,false,#([0.1323,-0.731,6.321],[0.1323,-0.731,6.441])),
                    #(false,false,#([0.1323,-0.549,6.321],[0.1323,-0.549,6.441])),
                    #(false,false,#([-0.1323,-0.549,6.321],[-0.1323,-0.549,6.441]))
                ) "dark" "mask" true 0.0
                f.cage "ModernCap" #(
                    #(true,true,#([-0.509117,0.37598,7.35],[-0.509117,0.26,7.47],[-0.509117,-0.02,7.519706],[-0.509117,-0.3,7.47],[-0.509117,-0.41598,7.35],[-0.509117,-0.3,7.23],[-0.509117,-0.02,7.180294],[-0.509117,0.26,7.23])),
                    #(true,true,#([0.0,0.54,7.35],[0.0,0.37598,7.519706],[0.0,-0.02,7.59],[0.0,-0.41598,7.519706],[0.0,-0.58,7.35],[0.0,-0.41598,7.180294],[0.0,-0.02,7.11],[0.0,0.37598,7.180294])),
                    #(true,true,#([0.509117,0.37598,7.35],[0.509117,0.26,7.47],[0.509117,-0.02,7.519706],[0.509117,-0.3,7.47],[0.509117,-0.41598,7.35],[0.509117,-0.3,7.23],[0.509117,-0.02,7.180294],[0.509117,0.26,7.23])),
                    #(false,true,#([-0.72,-0.02,7.35],[-0.509117,0.37598,7.35],[0.0,0.54,7.35],[0.509117,0.37598,7.35],[0.72,-0.02,7.35])),
                    #(false,true,#([-0.72,-0.02,7.35],[-0.509117,0.26,7.47],[0.0,0.37598,7.519706],[0.509117,0.26,7.47],[0.72,-0.02,7.35])),
                    #(false,true,#([-0.72,-0.02,7.35],[-0.509117,-0.02,7.519706],[0.0,-0.02,7.59],[0.509117,-0.02,7.519706],[0.72,-0.02,7.35])),
                    #(false,true,#([-0.72,-0.02,7.35],[-0.509117,-0.3,7.47],[0.0,-0.41598,7.519706],[0.509117,-0.3,7.47],[0.72,-0.02,7.35])),
                    #(false,true,#([-0.72,-0.02,7.35],[-0.509117,-0.41598,7.35],[0.0,-0.58,7.35],[0.509117,-0.41598,7.35],[0.72,-0.02,7.35])),
                    #(false,true,#([-0.72,-0.02,7.35],[-0.509117,-0.3,7.23],[0.0,-0.41598,7.180294],[0.509117,-0.3,7.23],[0.72,-0.02,7.35])),
                    #(false,true,#([-0.72,-0.02,7.35],[-0.509117,-0.02,7.180294],[0.0,-0.02,7.11],[0.509117,-0.02,7.180294],[0.72,-0.02,7.35])),
                    #(false,true,#([-0.72,-0.02,7.35],[-0.509117,0.26,7.23],[0.0,0.37598,7.180294],[0.509117,0.26,7.23],[0.72,-0.02,7.35]))
                ) "teal" "head" true 0.0
                f.cage "CapPeak" #(
                    #(true,true,#([-0.537401,-0.333015,7.25],[-0.537401,-0.42,7.31],[-0.537401,-0.63,7.334853],[-0.537401,-0.84,7.31],[-0.537401,-0.926985,7.25],[-0.537401,-0.84,7.19],[-0.537401,-0.63,7.165147],[-0.537401,-0.42,7.19])),
                    #(true,true,#([0.0,-0.21,7.25],[0.0,-0.333015,7.334853],[0.0,-0.63,7.37],[0.0,-0.926985,7.334853],[0.0,-1.05,7.25],[0.0,-0.926985,7.165147],[0.0,-0.63,7.13],[0.0,-0.333015,7.165147])),
                    #(true,true,#([0.537401,-0.333015,7.25],[0.537401,-0.42,7.31],[0.537401,-0.63,7.334853],[0.537401,-0.84,7.31],[0.537401,-0.926985,7.25],[0.537401,-0.84,7.19],[0.537401,-0.63,7.165147],[0.537401,-0.42,7.19])),
                    #(false,true,#([-0.76,-0.63,7.25],[-0.537401,-0.333015,7.25],[0.0,-0.21,7.25],[0.537401,-0.333015,7.25],[0.76,-0.63,7.25])),
                    #(false,true,#([-0.76,-0.63,7.25],[-0.537401,-0.42,7.31],[0.0,-0.333015,7.334853],[0.537401,-0.42,7.31],[0.76,-0.63,7.25])),
                    #(false,true,#([-0.76,-0.63,7.25],[-0.537401,-0.63,7.334853],[0.0,-0.63,7.37],[0.537401,-0.63,7.334853],[0.76,-0.63,7.25])),
                    #(false,true,#([-0.76,-0.63,7.25],[-0.537401,-0.84,7.31],[0.0,-0.926985,7.334853],[0.537401,-0.84,7.31],[0.76,-0.63,7.25])),
                    #(false,true,#([-0.76,-0.63,7.25],[-0.537401,-0.926985,7.25],[0.0,-1.05,7.25],[0.537401,-0.926985,7.25],[0.76,-0.63,7.25])),
                    #(false,true,#([-0.76,-0.63,7.25],[-0.537401,-0.84,7.19],[0.0,-0.926985,7.165147],[0.537401,-0.84,7.19],[0.76,-0.63,7.25])),
                    #(false,true,#([-0.76,-0.63,7.25],[-0.537401,-0.63,7.165147],[0.0,-0.63,7.13],[0.537401,-0.63,7.165147],[0.76,-0.63,7.25])),
                    #(false,true,#([-0.76,-0.63,7.25],[-0.537401,-0.42,7.19],[0.0,-0.333015,7.165147],[0.537401,-0.42,7.19],[0.76,-0.63,7.25]))
                ) "dark" "head" true 0.0
                f.tube "PonchoCorner" #([-1.1,-0.39,3.12],[0.03,-0.66,2.92],[1.41,-0.35,2.88]) 0.105 5 false true "cyan_glow" "body"
                f.finishModel()
                f.startModel "paradecivilian4" "The umbrella observer" "civilian" 4 0.23 [0.16,0.02,5.78] "Slim fitted raincoat beneath an offset low polygon umbrella." true
                f.cage "LeftShoe" #(
                    #(true,true,#([-0.646274,0.147696,0.21],[-0.646274,0.04,0.315],[-0.646274,-0.22,0.358492],[-0.646274,-0.48,0.315],[-0.646274,-0.587696,0.21],[-0.646274,-0.48,0.105],[-0.646274,-0.22,0.061508],[-0.646274,0.04,0.105])),
                    #(true,true,#([-0.42,0.3,0.21],[-0.42,0.147696,0.358492],[-0.42,-0.22,0.42],[-0.42,-0.587696,0.358492],[-0.42,-0.74,0.21],[-0.42,-0.587696,0.061508],[-0.42,-0.22,0.0],[-0.42,0.147696,0.061508])),
                    #(true,true,#([-0.193726,0.147696,0.21],[-0.193726,0.04,0.315],[-0.193726,-0.22,0.358492],[-0.193726,-0.48,0.315],[-0.193726,-0.587696,0.21],[-0.193726,-0.48,0.105],[-0.193726,-0.22,0.061508],[-0.193726,0.04,0.105])),
                    #(false,true,#([-0.74,-0.22,0.21],[-0.646274,0.147696,0.21],[-0.42,0.3,0.21],[-0.193726,0.147696,0.21],[-0.1,-0.22,0.21])),
                    #(false,true,#([-0.74,-0.22,0.21],[-0.646274,0.04,0.315],[-0.42,0.147696,0.358492],[-0.193726,0.04,0.315],[-0.1,-0.22,0.21])),
                    #(false,true,#([-0.74,-0.22,0.21],[-0.646274,-0.22,0.358492],[-0.42,-0.22,0.42],[-0.193726,-0.22,0.358492],[-0.1,-0.22,0.21])),
                    #(false,true,#([-0.74,-0.22,0.21],[-0.646274,-0.48,0.315],[-0.42,-0.587696,0.358492],[-0.193726,-0.48,0.315],[-0.1,-0.22,0.21])),
                    #(false,true,#([-0.74,-0.22,0.21],[-0.646274,-0.587696,0.21],[-0.42,-0.74,0.21],[-0.193726,-0.587696,0.21],[-0.1,-0.22,0.21])),
                    #(false,true,#([-0.74,-0.22,0.21],[-0.646274,-0.48,0.105],[-0.42,-0.587696,0.061508],[-0.193726,-0.48,0.105],[-0.1,-0.22,0.21])),
                    #(false,true,#([-0.74,-0.22,0.21],[-0.646274,-0.22,0.061508],[-0.42,-0.22,0.0],[-0.193726,-0.22,0.061508],[-0.1,-0.22,0.21])),
                    #(false,true,#([-0.74,-0.22,0.21],[-0.646274,0.04,0.105],[-0.42,0.147696,0.061508],[-0.193726,0.04,0.105],[-0.1,-0.22,0.21]))
                ) "dark" "body" true 0.0
                f.cage "RightShoe" #(
                    #(true,true,#([0.233726,0.247696,0.21],[0.233726,0.14,0.315],[0.233726,-0.12,0.358492],[0.233726,-0.38,0.315],[0.233726,-0.487696,0.21],[0.233726,-0.38,0.105],[0.233726,-0.12,0.061508],[0.233726,0.14,0.105])),
                    #(true,true,#([0.46,0.4,0.21],[0.46,0.247696,0.358492],[0.46,-0.12,0.42],[0.46,-0.487696,0.358492],[0.46,-0.64,0.21],[0.46,-0.487696,0.061508],[0.46,-0.12,0.0],[0.46,0.247696,0.061508])),
                    #(true,true,#([0.686274,0.247696,0.21],[0.686274,0.14,0.315],[0.686274,-0.12,0.358492],[0.686274,-0.38,0.315],[0.686274,-0.487696,0.21],[0.686274,-0.38,0.105],[0.686274,-0.12,0.061508],[0.686274,0.14,0.105])),
                    #(false,true,#([0.14,-0.12,0.21],[0.233726,0.247696,0.21],[0.46,0.4,0.21],[0.686274,0.247696,0.21],[0.78,-0.12,0.21])),
                    #(false,true,#([0.14,-0.12,0.21],[0.233726,0.14,0.315],[0.46,0.247696,0.358492],[0.686274,0.14,0.315],[0.78,-0.12,0.21])),
                    #(false,true,#([0.14,-0.12,0.21],[0.233726,-0.12,0.358492],[0.46,-0.12,0.42],[0.686274,-0.12,0.358492],[0.78,-0.12,0.21])),
                    #(false,true,#([0.14,-0.12,0.21],[0.233726,-0.38,0.315],[0.46,-0.487696,0.358492],[0.686274,-0.38,0.315],[0.78,-0.12,0.21])),
                    #(false,true,#([0.14,-0.12,0.21],[0.233726,-0.487696,0.21],[0.46,-0.64,0.21],[0.686274,-0.487696,0.21],[0.78,-0.12,0.21])),
                    #(false,true,#([0.14,-0.12,0.21],[0.233726,-0.38,0.105],[0.46,-0.487696,0.061508],[0.686274,-0.38,0.105],[0.78,-0.12,0.21])),
                    #(false,true,#([0.14,-0.12,0.21],[0.233726,-0.12,0.061508],[0.46,-0.12,0.0],[0.686274,-0.12,0.061508],[0.78,-0.12,0.21])),
                    #(false,true,#([0.14,-0.12,0.21],[0.233726,0.14,0.105],[0.46,0.247696,0.061508],[0.686274,0.14,0.105],[0.78,-0.12,0.21]))
                ) "dark" "body" true 0.0
                f.cage "LeftLeg" #(
                    #(true,true,#([-0.68,0.0,0.3],[-0.603848,-0.183782,0.304901],[-0.42,-0.259908,0.306931],[-0.236152,-0.183782,0.304901],[-0.16,0.0,0.3],[-0.236152,0.183782,0.295099],[-0.42,0.259908,0.293069],[-0.603848,0.183782,0.295099])),
                    #(true,true,#([-0.709802,0.040309,1.810714],[-0.624905,-0.164744,1.813924],[-0.419977,-0.249861,1.808977],[-0.215063,-0.165181,1.798772],[-0.130198,0.039691,1.789286],[-0.215095,0.244744,1.786076],[-0.420023,0.329861,1.791023],[-0.624937,0.245181,1.801228])),
                    #(true,true,#([-0.633071,0.100778,3.525104],[-0.533683,-0.139717,3.526225],[-0.293892,-0.239789,3.511985],[-0.054164,-0.140817,3.490723],[0.045071,0.099222,3.474896],[-0.054317,0.339717,3.473775],[-0.294108,0.439789,3.488015],[-0.533836,0.340817,3.509277])),
                    #(false,true,#([-0.42,0.0,0.3],[-0.68,0.0,0.3],[-0.709802,0.040309,1.810714],[-0.633071,0.100778,3.525104],[-0.294,0.1,3.5])),
                    #(false,true,#([-0.42,0.0,0.3],[-0.603848,-0.183782,0.304901],[-0.624905,-0.164744,1.813924],[-0.533683,-0.139717,3.526225],[-0.294,0.1,3.5])),
                    #(false,true,#([-0.42,0.0,0.3],[-0.42,-0.259908,0.306931],[-0.419977,-0.249861,1.808977],[-0.293892,-0.239789,3.511985],[-0.294,0.1,3.5])),
                    #(false,true,#([-0.42,0.0,0.3],[-0.236152,-0.183782,0.304901],[-0.215063,-0.165181,1.798772],[-0.054164,-0.140817,3.490723],[-0.294,0.1,3.5])),
                    #(false,true,#([-0.42,0.0,0.3],[-0.16,0.0,0.3],[-0.130198,0.039691,1.789286],[0.045071,0.099222,3.474896],[-0.294,0.1,3.5])),
                    #(false,true,#([-0.42,0.0,0.3],[-0.236152,0.183782,0.295099],[-0.215095,0.244744,1.786076],[-0.054317,0.339717,3.473775],[-0.294,0.1,3.5])),
                    #(false,true,#([-0.42,0.0,0.3],[-0.42,0.259908,0.293069],[-0.420023,0.329861,1.791023],[-0.294108,0.439789,3.488015],[-0.294,0.1,3.5])),
                    #(false,true,#([-0.42,0.0,0.3],[-0.603848,0.183782,0.295099],[-0.624937,0.245181,1.801228],[-0.533836,0.340817,3.509277],[-0.294,0.1,3.5]))
                ) "dark" "body" true 0.0
                f.cage "RightLeg" #(
                    #(true,true,#([0.2,0.0,0.3],[0.276152,-0.183782,0.304901],[0.46,-0.259908,0.306931],[0.643848,-0.183782,0.304901],[0.72,0.0,0.3],[0.643848,0.183782,0.295099],[0.46,0.259908,0.293069],[0.276152,0.183782,0.295099])),
                    #(true,true,#([0.170238,0.039662,1.78827],[0.255089,-0.165202,1.798053],[0.459975,-0.249861,1.808977],[0.664875,-0.164724,1.814642],[0.749762,0.040338,1.81173],[0.664911,0.245202,1.801947],[0.460025,0.329861,1.791023],[0.255125,0.244724,1.785358])),
                    #(true,true,#([-0.016887,0.099149,3.47252],[0.082287,-0.140869,3.489042],[0.321882,-0.239789,3.511983],[0.561545,-0.139665,3.527904],[0.660887,0.100851,3.52748],[0.561713,0.340869,3.510958],[0.322118,0.439789,3.488017],[0.082455,0.339665,3.472096])),
                    #(false,true,#([0.46,0.0,0.3],[0.2,0.0,0.3],[0.170238,0.039662,1.78827],[-0.016887,0.099149,3.47252],[0.322,0.1,3.5])),
                    #(false,true,#([0.46,0.0,0.3],[0.276152,-0.183782,0.304901],[0.255089,-0.165202,1.798053],[0.082287,-0.140869,3.489042],[0.322,0.1,3.5])),
                    #(false,true,#([0.46,0.0,0.3],[0.46,-0.259908,0.306931],[0.459975,-0.249861,1.808977],[0.321882,-0.239789,3.511983],[0.322,0.1,3.5])),
                    #(false,true,#([0.46,0.0,0.3],[0.643848,-0.183782,0.304901],[0.664875,-0.164724,1.814642],[0.561545,-0.139665,3.527904],[0.322,0.1,3.5])),
                    #(false,true,#([0.46,0.0,0.3],[0.72,0.0,0.3],[0.749762,0.040338,1.81173],[0.660887,0.100851,3.52748],[0.322,0.1,3.5])),
                    #(false,true,#([0.46,0.0,0.3],[0.643848,0.183782,0.295099],[0.664911,0.245202,1.801947],[0.561713,0.340869,3.510958],[0.322,0.1,3.5])),
                    #(false,true,#([0.46,0.0,0.3],[0.46,0.259908,0.293069],[0.460025,0.329861,1.791023],[0.322118,0.439789,3.488017],[0.322,0.1,3.5])),
                    #(false,true,#([0.46,0.0,0.3],[0.276152,0.183782,0.295099],[0.255125,0.244724,1.785358],[0.082455,0.339665,3.472096],[0.322,0.1,3.5]))
                ) "dark" "body" true 0.0
                f.cage "FittedCoat" #(
                    #(true,true,#([0.87,0.0,1.45],[0.615183,0.381838,1.45],[0.0,0.54,1.45],[-0.615183,0.381838,1.45],[-0.87,0.0,1.45],[-0.615183,-0.381838,1.45],[0.0,-0.54,1.45],[0.615183,-0.381838,1.45])),
                    #(true,true,#([0.8,0.0,3.1],[0.565685,0.367696,3.1],[0.0,0.52,3.1],[-0.565685,0.367696,3.1],[-0.8,0.0,3.1],[-0.565685,-0.367696,3.1],[0.0,-0.52,3.1],[0.565685,-0.367696,3.1])),
                    #(true,true,#([0.73,0.0,4.8],[0.516188,0.367696,4.8],[0.0,0.52,4.8],[-0.516188,0.367696,4.8],[-0.73,0.0,4.8],[-0.516188,-0.367696,4.8],[0.0,-0.52,4.8],[0.516188,-0.367696,4.8])),
                    #(true,true,#([0.94,0.0,5.55],[0.66468,0.346482,5.55],[0.0,0.49,5.55],[-0.66468,0.346482,5.55],[-0.94,0.0,5.55],[-0.66468,-0.346482,5.55],[0.0,-0.49,5.55],[0.66468,-0.346482,5.55])),
                    #(true,true,#([0.45,0.0,5.8],[0.318198,0.26163,5.8],[0.0,0.37,5.8],[-0.318198,0.26163,5.8],[-0.45,0.0,5.8],[-0.318198,-0.26163,5.8],[0.0,-0.37,5.8],[0.318198,-0.26163,5.8])),
                    #(false,true,#([0.0,0.0,1.45],[0.87,0.0,1.45],[0.8,0.0,3.1],[0.73,0.0,4.8],[0.94,0.0,5.55],[0.45,0.0,5.8],[0.0,0.0,5.8])),
                    #(false,true,#([0.0,0.0,1.45],[0.615183,0.381838,1.45],[0.565685,0.367696,3.1],[0.516188,0.367696,4.8],[0.66468,0.346482,5.55],[0.318198,0.26163,5.8],[0.0,0.0,5.8])),
                    #(false,true,#([0.0,0.0,1.45],[0.0,0.54,1.45],[0.0,0.52,3.1],[0.0,0.52,4.8],[0.0,0.49,5.55],[0.0,0.37,5.8],[0.0,0.0,5.8])),
                    #(false,true,#([0.0,0.0,1.45],[-0.615183,0.381838,1.45],[-0.565685,0.367696,3.1],[-0.516188,0.367696,4.8],[-0.66468,0.346482,5.55],[-0.318198,0.26163,5.8],[0.0,0.0,5.8])),
                    #(false,true,#([0.0,0.0,1.45],[-0.87,0.0,1.45],[-0.8,0.0,3.1],[-0.73,0.0,4.8],[-0.94,0.0,5.55],[-0.45,0.0,5.8],[0.0,0.0,5.8])),
                    #(false,true,#([0.0,0.0,1.45],[-0.615183,-0.381838,1.45],[-0.565685,-0.367696,3.1],[-0.516188,-0.367696,4.8],[-0.66468,-0.346482,5.55],[-0.318198,-0.26163,5.8],[0.0,0.0,5.8])),
                    #(false,true,#([0.0,0.0,1.45],[0.0,-0.54,1.45],[0.0,-0.52,3.1],[0.0,-0.52,4.8],[0.0,-0.49,5.55],[0.0,-0.37,5.8],[0.0,0.0,5.8])),
                    #(false,true,#([0.0,0.0,1.45],[0.615183,-0.381838,1.45],[0.565685,-0.367696,3.1],[0.516188,-0.367696,4.8],[0.66468,-0.346482,5.55],[0.318198,-0.26163,5.8],[0.0,0.0,5.8]))
                ) "teal" "body" true 0.0
                f.cage "PoleArm" #(
                    #(true,true,#([-1.048328,0.114164,5.4],[-0.890953,0.232436,5.281824],[-0.668583,0.202834,5.232874],[-0.511479,0.042699,5.281824],[-0.511672,-0.154164,5.4],[-0.669047,-0.272436,5.518176],[-0.891417,-0.242834,5.567126],[-1.048521,-0.082699,5.518176])),
                    #(true,true,#([-1.230392,-0.348469,4.619323],[-1.191937,-0.401788,4.4315],[-1.052763,-0.512638,4.342382],[-0.894397,-0.616085,4.404173],[-0.809608,-0.651531,4.580677],[-0.848063,-0.598212,4.7685],[-0.987237,-0.487362,4.857618],[-1.145603,-0.383915,4.795827])),
                    #(true,true,#([-1.324335,-0.50172,5.14321],[-1.372122,-0.63872,5.094436],[-1.307367,-0.776469,5.07821],[-1.168002,-0.834277,5.104038],[-1.035665,-0.77828,5.15679],[-0.987878,-0.64128,5.205564],[-1.052633,-0.503531,5.22179],[-1.191998,-0.445723,5.195962])),
                    #(false,true,#([-0.78,-0.02,5.4],[-1.048328,0.114164,5.4],[-1.230392,-0.348469,4.619323],[-1.324335,-0.50172,5.14321],[-1.18,-0.64,5.15])),
                    #(false,true,#([-0.78,-0.02,5.4],[-0.890953,0.232436,5.281824],[-1.191937,-0.401788,4.4315],[-1.372122,-0.63872,5.094436],[-1.18,-0.64,5.15])),
                    #(false,true,#([-0.78,-0.02,5.4],[-0.668583,0.202834,5.232874],[-1.052763,-0.512638,4.342382],[-1.307367,-0.776469,5.07821],[-1.18,-0.64,5.15])),
                    #(false,true,#([-0.78,-0.02,5.4],[-0.511479,0.042699,5.281824],[-0.894397,-0.616085,4.404173],[-1.168002,-0.834277,5.104038],[-1.18,-0.64,5.15])),
                    #(false,true,#([-0.78,-0.02,5.4],[-0.511672,-0.154164,5.4],[-0.809608,-0.651531,4.580677],[-1.035665,-0.77828,5.15679],[-1.18,-0.64,5.15])),
                    #(false,true,#([-0.78,-0.02,5.4],[-0.669047,-0.272436,5.518176],[-0.848063,-0.598212,4.7685],[-0.987878,-0.64128,5.205564],[-1.18,-0.64,5.15])),
                    #(false,true,#([-0.78,-0.02,5.4],[-0.891417,-0.242834,5.567126],[-0.987237,-0.487362,4.857618],[-1.052633,-0.503531,5.22179],[-1.18,-0.64,5.15])),
                    #(false,true,#([-0.78,-0.02,5.4],[-1.048521,-0.082699,5.518176],[-1.145603,-0.383915,4.795827],[-1.191998,-0.445723,5.195962],[-1.18,-0.64,5.15]))
                ) "dark" "body" true 0.0
                f.cage "PoleHand" #(
                    #(true,true,#([-1.342635,-0.52565,5.17],[-1.342635,-0.565,5.295],[-1.342635,-0.66,5.346777],[-1.342635,-0.755,5.295],[-1.342635,-0.79435,5.17],[-1.342635,-0.755,5.045],[-1.342635,-0.66,4.993223],[-1.342635,-0.565,5.045])),
                    #(true,true,#([-1.18,-0.47,5.17],[-1.18,-0.52565,5.346777],[-1.18,-0.66,5.42],[-1.18,-0.79435,5.346777],[-1.18,-0.85,5.17],[-1.18,-0.79435,4.993223],[-1.18,-0.66,4.92],[-1.18,-0.52565,4.993223])),
                    #(true,true,#([-1.017365,-0.52565,5.17],[-1.017365,-0.565,5.295],[-1.017365,-0.66,5.346777],[-1.017365,-0.755,5.295],[-1.017365,-0.79435,5.17],[-1.017365,-0.755,5.045],[-1.017365,-0.66,4.993223],[-1.017365,-0.565,5.045])),
                    #(false,true,#([-1.41,-0.66,5.17],[-1.342635,-0.52565,5.17],[-1.18,-0.47,5.17],[-1.017365,-0.52565,5.17],[-0.95,-0.66,5.17])),
                    #(false,true,#([-1.41,-0.66,5.17],[-1.342635,-0.565,5.295],[-1.18,-0.52565,5.346777],[-1.017365,-0.565,5.295],[-0.95,-0.66,5.17])),
                    #(false,true,#([-1.41,-0.66,5.17],[-1.342635,-0.66,5.346777],[-1.18,-0.66,5.42],[-1.017365,-0.66,5.346777],[-0.95,-0.66,5.17])),
                    #(false,true,#([-1.41,-0.66,5.17],[-1.342635,-0.755,5.295],[-1.18,-0.79435,5.346777],[-1.017365,-0.755,5.295],[-0.95,-0.66,5.17])),
                    #(false,true,#([-1.41,-0.66,5.17],[-1.342635,-0.79435,5.17],[-1.18,-0.85,5.17],[-1.017365,-0.79435,5.17],[-0.95,-0.66,5.17])),
                    #(false,true,#([-1.41,-0.66,5.17],[-1.342635,-0.755,5.045],[-1.18,-0.79435,4.993223],[-1.017365,-0.755,5.045],[-0.95,-0.66,5.17])),
                    #(false,true,#([-1.41,-0.66,5.17],[-1.342635,-0.66,4.993223],[-1.18,-0.66,4.92],[-1.017365,-0.66,4.993223],[-0.95,-0.66,5.17])),
                    #(false,true,#([-1.41,-0.66,5.17],[-1.342635,-0.565,5.045],[-1.18,-0.52565,4.993223],[-1.017365,-0.565,5.045],[-0.95,-0.66,5.17]))
                ) "dark" "body" true 0.0
                f.cage "RelaxedArm" #(
                    #(true,true,#([1.084072,0.0,5.460332],[0.998323,-0.218542,5.425973],[0.784683,-0.309065,5.3764],[0.568299,-0.218542,5.340651],[0.475928,0.0,5.339668],[0.561677,0.218542,5.374027],[0.775317,0.309065,5.4236],[0.991701,0.218542,5.459349])),
                    #(true,true,#([1.279988,0.099429,4.14242],[1.206192,-0.076258,4.159735],[1.029185,-0.148696,4.16549],[0.852656,-0.075451,4.156313],[0.780012,0.100571,4.13758],[0.853808,0.276258,4.120265],[1.030815,0.348696,4.11451],[1.207344,0.275451,4.123687])),
                    #(true,true,#([1.057025,-0.157146,3.247282],[1.003828,-0.284132,3.294094],[0.872236,-0.332546,3.33265],[0.739334,-0.274027,3.340364],[0.682975,-0.142854,3.312718],[0.736172,-0.015868,3.265906],[0.867764,0.032546,3.22735],[1.000666,-0.025973,3.219636])),
                    #(false,true,#([0.78,0.0,5.4],[1.084072,0.0,5.460332],[1.279988,0.099429,4.14242],[1.057025,-0.157146,3.247282],[0.87,-0.15,3.28])),
                    #(false,true,#([0.78,0.0,5.4],[0.998323,-0.218542,5.425973],[1.206192,-0.076258,4.159735],[1.003828,-0.284132,3.294094],[0.87,-0.15,3.28])),
                    #(false,true,#([0.78,0.0,5.4],[0.784683,-0.309065,5.3764],[1.029185,-0.148696,4.16549],[0.872236,-0.332546,3.33265],[0.87,-0.15,3.28])),
                    #(false,true,#([0.78,0.0,5.4],[0.568299,-0.218542,5.340651],[0.852656,-0.075451,4.156313],[0.739334,-0.274027,3.340364],[0.87,-0.15,3.28])),
                    #(false,true,#([0.78,0.0,5.4],[0.475928,0.0,5.339668],[0.780012,0.100571,4.13758],[0.682975,-0.142854,3.312718],[0.87,-0.15,3.28])),
                    #(false,true,#([0.78,0.0,5.4],[0.561677,0.218542,5.374027],[0.853808,0.276258,4.120265],[0.736172,-0.015868,3.265906],[0.87,-0.15,3.28])),
                    #(false,true,#([0.78,0.0,5.4],[0.775317,0.309065,5.4236],[1.030815,0.348696,4.11451],[0.867764,0.032546,3.22735],[0.87,-0.15,3.28])),
                    #(false,true,#([0.78,0.0,5.4],[0.991701,0.218542,5.459349],[1.207344,0.275451,4.123687],[1.000666,-0.025973,3.219636],[0.87,-0.15,3.28]))
                ) "dark" "body" true 0.0
                f.cage "RelaxedHand" #(
                    #(true,true,#([0.718579,-0.022721,3.08],[0.718579,-0.06,3.23],[0.718579,-0.15,3.292132],[0.718579,-0.24,3.23],[0.718579,-0.277279,3.08],[0.718579,-0.24,2.93],[0.718579,-0.15,2.867868],[0.718579,-0.06,2.93])),
                    #(true,true,#([0.86,0.03,3.08],[0.86,-0.022721,3.292132],[0.86,-0.15,3.38],[0.86,-0.277279,3.292132],[0.86,-0.33,3.08],[0.86,-0.277279,2.867868],[0.86,-0.15,2.78],[0.86,-0.022721,2.867868])),
                    #(true,true,#([1.001421,-0.022721,3.08],[1.001421,-0.06,3.23],[1.001421,-0.15,3.292132],[1.001421,-0.24,3.23],[1.001421,-0.277279,3.08],[1.001421,-0.24,2.93],[1.001421,-0.15,2.867868],[1.001421,-0.06,2.93])),
                    #(false,true,#([0.66,-0.15,3.08],[0.718579,-0.022721,3.08],[0.86,0.03,3.08],[1.001421,-0.022721,3.08],[1.06,-0.15,3.08])),
                    #(false,true,#([0.66,-0.15,3.08],[0.718579,-0.06,3.23],[0.86,-0.022721,3.292132],[1.001421,-0.06,3.23],[1.06,-0.15,3.08])),
                    #(false,true,#([0.66,-0.15,3.08],[0.718579,-0.15,3.292132],[0.86,-0.15,3.38],[1.001421,-0.15,3.292132],[1.06,-0.15,3.08])),
                    #(false,true,#([0.66,-0.15,3.08],[0.718579,-0.24,3.23],[0.86,-0.277279,3.292132],[1.001421,-0.24,3.23],[1.06,-0.15,3.08])),
                    #(false,true,#([0.66,-0.15,3.08],[0.718579,-0.277279,3.08],[0.86,-0.33,3.08],[1.001421,-0.277279,3.08],[1.06,-0.15,3.08])),
                    #(false,true,#([0.66,-0.15,3.08],[0.718579,-0.24,2.93],[0.86,-0.277279,2.867868],[1.001421,-0.24,2.93],[1.06,-0.15,3.08])),
                    #(false,true,#([0.66,-0.15,3.08],[0.718579,-0.15,2.867868],[0.86,-0.15,2.78],[1.001421,-0.15,2.867868],[1.06,-0.15,3.08])),
                    #(false,true,#([0.66,-0.15,3.08],[0.718579,-0.06,2.93],[0.86,-0.022721,2.867868],[1.001421,-0.06,2.93],[1.06,-0.15,3.08]))
                ) "dark" "body" true 0.0
                f.cage "Head" #(
                    #(true,true,#([-0.257193,0.345269,6.55],[-0.257193,0.25,6.925],[-0.257193,0.02,7.08033],[-0.257193,-0.21,6.925],[-0.257193,-0.305269,6.55],[-0.257193,-0.21,6.175],[-0.257193,0.02,6.01967],[-0.257193,0.25,6.175])),
                    #(true,true,#([0.16,0.48,6.55],[0.16,0.345269,7.08033],[0.16,0.02,7.3],[0.16,-0.305269,7.08033],[0.16,-0.44,6.55],[0.16,-0.305269,6.01967],[0.16,0.02,5.8],[0.16,0.345269,6.01967])),
                    #(true,true,#([0.577193,0.345269,6.55],[0.577193,0.25,6.925],[0.577193,0.02,7.08033],[0.577193,-0.21,6.925],[0.577193,-0.305269,6.55],[0.577193,-0.21,6.175],[0.577193,0.02,6.01967],[0.577193,0.25,6.175])),
                    #(false,true,#([-0.43,0.02,6.55],[-0.257193,0.345269,6.55],[0.16,0.48,6.55],[0.577193,0.345269,6.55],[0.75,0.02,6.55])),
                    #(false,true,#([-0.43,0.02,6.55],[-0.257193,0.25,6.925],[0.16,0.345269,7.08033],[0.577193,0.25,6.925],[0.75,0.02,6.55])),
                    #(false,true,#([-0.43,0.02,6.55],[-0.257193,0.02,7.08033],[0.16,0.02,7.3],[0.577193,0.02,7.08033],[0.75,0.02,6.55])),
                    #(false,true,#([-0.43,0.02,6.55],[-0.257193,-0.21,6.925],[0.16,-0.305269,7.08033],[0.577193,-0.21,6.925],[0.75,0.02,6.55])),
                    #(false,true,#([-0.43,0.02,6.55],[-0.257193,-0.305269,6.55],[0.16,-0.44,6.55],[0.577193,-0.305269,6.55],[0.75,0.02,6.55])),
                    #(false,true,#([-0.43,0.02,6.55],[-0.257193,-0.21,6.175],[0.16,-0.305269,6.01967],[0.577193,-0.21,6.175],[0.75,0.02,6.55])),
                    #(false,true,#([-0.43,0.02,6.55],[-0.257193,0.02,6.01967],[0.16,0.02,5.8],[0.577193,0.02,6.01967],[0.75,0.02,6.55])),
                    #(false,true,#([-0.43,0.02,6.55],[-0.257193,0.25,6.175],[0.16,0.345269,6.01967],[0.577193,0.25,6.175],[0.75,0.02,6.55]))
                ) "dark" "head" true 0.0
                f.cage "FacePlate" #(
                    #(true,true,#([-0.179411,-0.308076,6.52],[-0.179411,-0.335,6.8275],[-0.179411,-0.4,6.954871],[-0.179411,-0.465,6.8275],[-0.179411,-0.491924,6.52],[-0.179411,-0.465,6.2125],[-0.179411,-0.4,6.085129],[-0.179411,-0.335,6.2125])),
                    #(true,true,#([0.16,-0.27,6.52],[0.16,-0.308076,6.954871],[0.16,-0.4,7.135],[0.16,-0.491924,6.954871],[0.16,-0.53,6.52],[0.16,-0.491924,6.085129],[0.16,-0.4,5.905],[0.16,-0.308076,6.085129])),
                    #(true,true,#([0.499411,-0.308076,6.52],[0.499411,-0.335,6.8275],[0.499411,-0.4,6.954871],[0.499411,-0.465,6.8275],[0.499411,-0.491924,6.52],[0.499411,-0.465,6.2125],[0.499411,-0.4,6.085129],[0.499411,-0.335,6.2125])),
                    #(false,true,#([-0.32,-0.4,6.52],[-0.179411,-0.308076,6.52],[0.16,-0.27,6.52],[0.499411,-0.308076,6.52],[0.64,-0.4,6.52])),
                    #(false,true,#([-0.32,-0.4,6.52],[-0.179411,-0.335,6.8275],[0.16,-0.308076,6.954871],[0.499411,-0.335,6.8275],[0.64,-0.4,6.52])),
                    #(false,true,#([-0.32,-0.4,6.52],[-0.179411,-0.4,6.954871],[0.16,-0.4,7.135],[0.499411,-0.4,6.954871],[0.64,-0.4,6.52])),
                    #(false,true,#([-0.32,-0.4,6.52],[-0.179411,-0.465,6.8275],[0.16,-0.491924,6.954871],[0.499411,-0.465,6.8275],[0.64,-0.4,6.52])),
                    #(false,true,#([-0.32,-0.4,6.52],[-0.179411,-0.491924,6.52],[0.16,-0.53,6.52],[0.499411,-0.491924,6.52],[0.64,-0.4,6.52])),
                    #(false,true,#([-0.32,-0.4,6.52],[-0.179411,-0.465,6.2125],[0.16,-0.491924,6.085129],[0.499411,-0.465,6.2125],[0.64,-0.4,6.52])),
                    #(false,true,#([-0.32,-0.4,6.52],[-0.179411,-0.4,6.085129],[0.16,-0.4,5.905],[0.499411,-0.4,6.085129],[0.64,-0.4,6.52])),
                    #(false,true,#([-0.32,-0.4,6.52],[-0.179411,-0.335,6.2125],[0.16,-0.308076,6.085129],[0.499411,-0.335,6.2125],[0.64,-0.4,6.52]))
                ) "ivory_glow" "mask" true 0.0
                f.cage "EyeLeft" #(
                    #(true,true,#([-0.132659,-0.438707,6.6307],[-0.132659,-0.4624,6.695275],[-0.132659,-0.5196,6.722023],[-0.132659,-0.5768,6.695275],[-0.132659,-0.600493,6.6307],[-0.132659,-0.5768,6.566125],[-0.132659,-0.5196,6.539377],[-0.132659,-0.4624,6.566125])),
                    #(true,true,#([-0.0512,-0.4052,6.6307],[-0.0512,-0.438707,6.722023],[-0.0512,-0.5196,6.75985],[-0.0512,-0.600493,6.722023],[-0.0512,-0.634,6.6307],[-0.0512,-0.600493,6.539377],[-0.0512,-0.5196,6.50155],[-0.0512,-0.438707,6.539377])),
                    #(true,true,#([0.030259,-0.438707,6.6307],[0.030259,-0.4624,6.695275],[0.030259,-0.5196,6.722023],[0.030259,-0.5768,6.695275],[0.030259,-0.600493,6.6307],[0.030259,-0.5768,6.566125],[0.030259,-0.5196,6.539377],[0.030259,-0.4624,6.566125])),
                    #(false,true,#([-0.1664,-0.5196,6.6307],[-0.132659,-0.438707,6.6307],[-0.0512,-0.4052,6.6307],[0.030259,-0.438707,6.6307],[0.064,-0.5196,6.6307])),
                    #(false,true,#([-0.1664,-0.5196,6.6307],[-0.132659,-0.4624,6.695275],[-0.0512,-0.438707,6.722023],[0.030259,-0.4624,6.695275],[0.064,-0.5196,6.6307])),
                    #(false,true,#([-0.1664,-0.5196,6.6307],[-0.132659,-0.5196,6.722023],[-0.0512,-0.5196,6.75985],[0.030259,-0.5196,6.722023],[0.064,-0.5196,6.6307])),
                    #(false,true,#([-0.1664,-0.5196,6.6307],[-0.132659,-0.5768,6.695275],[-0.0512,-0.600493,6.722023],[0.030259,-0.5768,6.695275],[0.064,-0.5196,6.6307])),
                    #(false,true,#([-0.1664,-0.5196,6.6307],[-0.132659,-0.600493,6.6307],[-0.0512,-0.634,6.6307],[0.030259,-0.600493,6.6307],[0.064,-0.5196,6.6307])),
                    #(false,true,#([-0.1664,-0.5196,6.6307],[-0.132659,-0.5768,6.566125],[-0.0512,-0.600493,6.539377],[0.030259,-0.5768,6.566125],[0.064,-0.5196,6.6307])),
                    #(false,true,#([-0.1664,-0.5196,6.6307],[-0.132659,-0.5196,6.539377],[-0.0512,-0.5196,6.50155],[0.030259,-0.5196,6.539377],[0.064,-0.5196,6.6307])),
                    #(false,true,#([-0.1664,-0.5196,6.6307],[-0.132659,-0.4624,6.566125],[-0.0512,-0.438707,6.539377],[0.030259,-0.4624,6.566125],[0.064,-0.5196,6.6307]))
                ) "dark" "mask" true 0.0
                f.cage "EyeRight" #(
                    #(true,true,#([0.289741,-0.438707,6.6307],[0.289741,-0.4624,6.695275],[0.289741,-0.5196,6.722023],[0.289741,-0.5768,6.695275],[0.289741,-0.600493,6.6307],[0.289741,-0.5768,6.566125],[0.289741,-0.5196,6.539377],[0.289741,-0.4624,6.566125])),
                    #(true,true,#([0.3712,-0.4052,6.6307],[0.3712,-0.438707,6.722023],[0.3712,-0.5196,6.75985],[0.3712,-0.600493,6.722023],[0.3712,-0.634,6.6307],[0.3712,-0.600493,6.539377],[0.3712,-0.5196,6.50155],[0.3712,-0.438707,6.539377])),
                    #(true,true,#([0.452659,-0.438707,6.6307],[0.452659,-0.4624,6.695275],[0.452659,-0.5196,6.722023],[0.452659,-0.5768,6.695275],[0.452659,-0.600493,6.6307],[0.452659,-0.5768,6.566125],[0.452659,-0.5196,6.539377],[0.452659,-0.4624,6.566125])),
                    #(false,true,#([0.256,-0.5196,6.6307],[0.289741,-0.438707,6.6307],[0.3712,-0.4052,6.6307],[0.452659,-0.438707,6.6307],[0.4864,-0.5196,6.6307])),
                    #(false,true,#([0.256,-0.5196,6.6307],[0.289741,-0.4624,6.695275],[0.3712,-0.438707,6.722023],[0.452659,-0.4624,6.695275],[0.4864,-0.5196,6.6307])),
                    #(false,true,#([0.256,-0.5196,6.6307],[0.289741,-0.5196,6.722023],[0.3712,-0.5196,6.75985],[0.452659,-0.5196,6.722023],[0.4864,-0.5196,6.6307])),
                    #(false,true,#([0.256,-0.5196,6.6307],[0.289741,-0.5768,6.695275],[0.3712,-0.600493,6.722023],[0.452659,-0.5768,6.695275],[0.4864,-0.5196,6.6307])),
                    #(false,true,#([0.256,-0.5196,6.6307],[0.289741,-0.600493,6.6307],[0.3712,-0.634,6.6307],[0.452659,-0.600493,6.6307],[0.4864,-0.5196,6.6307])),
                    #(false,true,#([0.256,-0.5196,6.6307],[0.289741,-0.5768,6.566125],[0.3712,-0.600493,6.539377],[0.452659,-0.5768,6.566125],[0.4864,-0.5196,6.6307])),
                    #(false,true,#([0.256,-0.5196,6.6307],[0.289741,-0.5196,6.539377],[0.3712,-0.5196,6.50155],[0.452659,-0.5196,6.539377],[0.4864,-0.5196,6.6307])),
                    #(false,true,#([0.256,-0.5196,6.6307],[0.289741,-0.4624,6.566125],[0.3712,-0.438707,6.539377],[0.452659,-0.4624,6.566125],[0.4864,-0.5196,6.6307]))
                ) "dark" "mask" true 0.0
                f.cage "UmbrellaHandle" #(
                    #(true,true,#([-1.285,-0.64,4.75],[-1.254246,-0.714246,4.75],[-1.18,-0.745,4.75],[-1.105754,-0.714246,4.75],[-1.075,-0.64,4.75],[-1.105754,-0.565754,4.75],[-1.18,-0.535,4.75],[-1.254246,-0.565754,4.75])),
                    #(true,true,#([-1.285,-0.64,6.1],[-1.254246,-0.714246,6.1],[-1.18,-0.745,6.1],[-1.105754,-0.714246,6.1],[-1.075,-0.64,6.1],[-1.105754,-0.565754,6.1],[-1.18,-0.535,6.1],[-1.254246,-0.565754,6.1])),
                    #(true,true,#([-1.285,-0.64,7.75],[-1.254246,-0.714246,7.75],[-1.18,-0.745,7.75],[-1.105754,-0.714246,7.75],[-1.075,-0.64,7.75],[-1.105754,-0.565754,7.75],[-1.18,-0.535,7.75],[-1.254246,-0.565754,7.75])),
                    #(false,true,#([-1.18,-0.64,4.75],[-1.285,-0.64,4.75],[-1.285,-0.64,6.1],[-1.285,-0.64,7.75],[-1.18,-0.64,7.75])),
                    #(false,true,#([-1.18,-0.64,4.75],[-1.254246,-0.714246,4.75],[-1.254246,-0.714246,6.1],[-1.254246,-0.714246,7.75],[-1.18,-0.64,7.75])),
                    #(false,true,#([-1.18,-0.64,4.75],[-1.18,-0.745,4.75],[-1.18,-0.745,6.1],[-1.18,-0.745,7.75],[-1.18,-0.64,7.75])),
                    #(false,true,#([-1.18,-0.64,4.75],[-1.105754,-0.714246,4.75],[-1.105754,-0.714246,6.1],[-1.105754,-0.714246,7.75],[-1.18,-0.64,7.75])),
                    #(false,true,#([-1.18,-0.64,4.75],[-1.075,-0.64,4.75],[-1.075,-0.64,6.1],[-1.075,-0.64,7.75],[-1.18,-0.64,7.75])),
                    #(false,true,#([-1.18,-0.64,4.75],[-1.105754,-0.565754,4.75],[-1.105754,-0.565754,6.1],[-1.105754,-0.565754,7.75],[-1.18,-0.64,7.75])),
                    #(false,true,#([-1.18,-0.64,4.75],[-1.18,-0.535,4.75],[-1.18,-0.535,6.1],[-1.18,-0.535,7.75],[-1.18,-0.64,7.75])),
                    #(false,true,#([-1.18,-0.64,4.75],[-1.254246,-0.565754,4.75],[-1.254246,-0.565754,6.1],[-1.254246,-0.565754,7.75],[-1.18,-0.64,7.75]))
                ) "dark" "body" true 0.0
                f.cage "UmbrellaCanopy" #(
                    #(true,false,#([1.34,0.05,7.49],[0.695635,1.096518,7.49],[-0.86,1.53,7.49],[-2.415635,1.096518,7.49],[-3.06,0.05,7.49],[-2.415635,-0.996518,7.49],[-0.86,-1.43,7.49],[0.695635,-0.996518,7.49])),
                    #(true,false,#([1.06,0.05,7.7],[0.497645,0.969239,7.7],[-0.86,1.35,7.7],[-2.217645,0.969239,7.7],[-2.78,0.05,7.7],[-2.217645,-0.869239,7.7],[-0.86,-1.25,7.7],[0.497645,-0.869239,7.7])),
                    #(true,false,#([0.29,0.05,8.03],[-0.046827,0.615685,8.03],[-0.86,0.85,8.03],[-1.673173,0.615685,8.03],[-2.01,0.05,8.03],[-1.673173,-0.515685,8.03],[-0.86,-0.75,8.03],[-0.046827,-0.515685,8.03])),
                    #(true,false,#([-0.64,0.05,8.24],[-0.704437,0.170208,8.24],[-0.86,0.22,8.24],[-1.015563,0.170208,8.24],[-1.08,0.05,8.24],[-1.015563,-0.070208,8.24],[-0.86,-0.12,8.24],[-0.704437,-0.070208,8.24])),
                    #(false,false,#([-0.86,0.05,7.49],[1.34,0.05,7.49],[1.06,0.05,7.7],[0.29,0.05,8.03],[-0.64,0.05,8.24],[-0.86,0.05,8.24])),
                    #(false,false,#([-0.86,0.05,7.49],[0.695635,1.096518,7.49],[0.497645,0.969239,7.7],[-0.046827,0.615685,8.03],[-0.704437,0.170208,8.24],[-0.86,0.05,8.24])),
                    #(false,false,#([-0.86,0.05,7.49],[-0.86,1.53,7.49],[-0.86,1.35,7.7],[-0.86,0.85,8.03],[-0.86,0.22,8.24],[-0.86,0.05,8.24])),
                    #(false,false,#([-0.86,0.05,7.49],[-2.415635,1.096518,7.49],[-2.217645,0.969239,7.7],[-1.673173,0.615685,8.03],[-1.015563,0.170208,8.24],[-0.86,0.05,8.24])),
                    #(false,false,#([-0.86,0.05,7.49],[-3.06,0.05,7.49],[-2.78,0.05,7.7],[-2.01,0.05,8.03],[-1.08,0.05,8.24],[-0.86,0.05,8.24])),
                    #(false,false,#([-0.86,0.05,7.49],[-2.415635,-0.996518,7.49],[-2.217645,-0.869239,7.7],[-1.673173,-0.515685,8.03],[-1.015563,-0.070208,8.24],[-0.86,0.05,8.24])),
                    #(false,false,#([-0.86,0.05,7.49],[-0.86,-1.43,7.49],[-0.86,-1.25,7.7],[-0.86,-0.75,8.03],[-0.86,-0.12,8.24],[-0.86,0.05,8.24])),
                    #(false,false,#([-0.86,0.05,7.49],[0.695635,-0.996518,7.49],[0.497645,-0.869239,7.7],[-0.046827,-0.515685,8.03],[-0.704437,-0.070208,8.24],[-0.86,0.05,8.24]))
                ) "dark" "body" true 0.0
                f.tube "UmbrellaFrontRib" #([-0.86,-1.4,7.5],[-0.86,-1.17,7.72],[-0.86,-0.62,8.06],[-0.86,0.05,8.25]) 0.1 5 false true "cyan_glow" "body"
                f.tube "CoatOpening" #([0.11,-0.52,2.0],[0.13,-0.55,3.8],[0.13,-0.48,5.47]) 0.09 5 false true "cyan_glow" "body"
                f.finishModel()
                f.startModel "paradedead1" "The bowler gentleman" "dead" 1 0.23 [0.0,0.0,6.07] "A bowler, long frock coat, worn shoes and an old walking cane." true
                f.cage "LeftOldShoe" #(
                    #(true,true,#([-0.639203,0.27669,0.21],[-0.639203,0.14,0.315],[-0.639203,-0.19,0.358492],[-0.639203,-0.52,0.315],[-0.639203,-0.65669,0.21],[-0.639203,-0.52,0.105],[-0.639203,-0.19,0.061508],[-0.639203,0.14,0.105])),
                    #(true,true,#([-0.42,0.47,0.21],[-0.42,0.27669,0.358492],[-0.42,-0.19,0.42],[-0.42,-0.65669,0.358492],[-0.42,-0.85,0.21],[-0.42,-0.65669,0.061508],[-0.42,-0.19,0.0],[-0.42,0.27669,0.061508])),
                    #(true,true,#([-0.200797,0.27669,0.21],[-0.200797,0.14,0.315],[-0.200797,-0.19,0.358492],[-0.200797,-0.52,0.315],[-0.200797,-0.65669,0.21],[-0.200797,-0.52,0.105],[-0.200797,-0.19,0.061508],[-0.200797,0.14,0.105])),
                    #(false,true,#([-0.73,-0.19,0.21],[-0.639203,0.27669,0.21],[-0.42,0.47,0.21],[-0.200797,0.27669,0.21],[-0.11,-0.19,0.21])),
                    #(false,true,#([-0.73,-0.19,0.21],[-0.639203,0.14,0.315],[-0.42,0.27669,0.358492],[-0.200797,0.14,0.315],[-0.11,-0.19,0.21])),
                    #(false,true,#([-0.73,-0.19,0.21],[-0.639203,-0.19,0.358492],[-0.42,-0.19,0.42],[-0.200797,-0.19,0.358492],[-0.11,-0.19,0.21])),
                    #(false,true,#([-0.73,-0.19,0.21],[-0.639203,-0.52,0.315],[-0.42,-0.65669,0.358492],[-0.200797,-0.52,0.315],[-0.11,-0.19,0.21])),
                    #(false,true,#([-0.73,-0.19,0.21],[-0.639203,-0.65669,0.21],[-0.42,-0.85,0.21],[-0.200797,-0.65669,0.21],[-0.11,-0.19,0.21])),
                    #(false,true,#([-0.73,-0.19,0.21],[-0.639203,-0.52,0.105],[-0.42,-0.65669,0.061508],[-0.200797,-0.52,0.105],[-0.11,-0.19,0.21])),
                    #(false,true,#([-0.73,-0.19,0.21],[-0.639203,-0.19,0.061508],[-0.42,-0.19,0.0],[-0.200797,-0.19,0.061508],[-0.11,-0.19,0.21])),
                    #(false,true,#([-0.73,-0.19,0.21],[-0.639203,0.14,0.105],[-0.42,0.27669,0.061508],[-0.200797,0.14,0.105],[-0.11,-0.19,0.21]))
                ) "dark" "body" true 0.0
                f.cage "RightOldShoe" #(
                    #(true,true,#([0.210797,0.45669,0.21],[0.210797,0.32,0.315],[0.210797,-0.01,0.358492],[0.210797,-0.34,0.315],[0.210797,-0.47669,0.21],[0.210797,-0.34,0.105],[0.210797,-0.01,0.061508],[0.210797,0.32,0.105])),
                    #(true,true,#([0.43,0.65,0.21],[0.43,0.45669,0.358492],[0.43,-0.01,0.42],[0.43,-0.47669,0.358492],[0.43,-0.67,0.21],[0.43,-0.47669,0.061508],[0.43,-0.01,0.0],[0.43,0.45669,0.061508])),
                    #(true,true,#([0.649203,0.45669,0.21],[0.649203,0.32,0.315],[0.649203,-0.01,0.358492],[0.649203,-0.34,0.315],[0.649203,-0.47669,0.21],[0.649203,-0.34,0.105],[0.649203,-0.01,0.061508],[0.649203,0.32,0.105])),
                    #(false,true,#([0.12,-0.01,0.21],[0.210797,0.45669,0.21],[0.43,0.65,0.21],[0.649203,0.45669,0.21],[0.74,-0.01,0.21])),
                    #(false,true,#([0.12,-0.01,0.21],[0.210797,0.32,0.315],[0.43,0.45669,0.358492],[0.649203,0.32,0.315],[0.74,-0.01,0.21])),
                    #(false,true,#([0.12,-0.01,0.21],[0.210797,-0.01,0.358492],[0.43,-0.01,0.42],[0.649203,-0.01,0.358492],[0.74,-0.01,0.21])),
                    #(false,true,#([0.12,-0.01,0.21],[0.210797,-0.34,0.315],[0.43,-0.47669,0.358492],[0.649203,-0.34,0.315],[0.74,-0.01,0.21])),
                    #(false,true,#([0.12,-0.01,0.21],[0.210797,-0.47669,0.21],[0.43,-0.67,0.21],[0.649203,-0.47669,0.21],[0.74,-0.01,0.21])),
                    #(false,true,#([0.12,-0.01,0.21],[0.210797,-0.34,0.105],[0.43,-0.47669,0.061508],[0.649203,-0.34,0.105],[0.74,-0.01,0.21])),
                    #(false,true,#([0.12,-0.01,0.21],[0.210797,-0.01,0.061508],[0.43,-0.01,0.0],[0.649203,-0.01,0.061508],[0.74,-0.01,0.21])),
                    #(false,true,#([0.12,-0.01,0.21],[0.210797,0.32,0.105],[0.43,0.45669,0.061508],[0.649203,0.32,0.105],[0.74,-0.01,0.21]))
                ) "dark" "body" true 0.0
                f.cage "LeftTrouser" #(
                    #(true,true,#([-0.7,0.0,0.3],[-0.620919,-0.190919,0.3],[-0.43,-0.27,0.3],[-0.239081,-0.190919,0.3],[-0.16,0.0,0.3],[-0.239081,0.190919,0.3],[-0.43,0.27,0.3],[-0.620919,0.190919,0.3])),
                    #(true,true,#([-0.709936,0.00009,1.606008],[-0.627881,-0.197838,1.610176],[-0.42991,-0.279874,1.608383],[-0.231992,-0.197965,1.601679],[-0.150064,-0.00009,1.593992],[-0.232119,0.197838,1.589824],[-0.43009,0.279874,1.591617],[-0.628008,0.197965,1.598321])),
                    #(true,true,#([-0.683687,0.120437,3.61458],[-0.583886,-0.119676,3.624696],[-0.343563,-0.21939,3.620345],[-0.103496,-0.120294,3.604076],[-0.004313,0.119563,3.58542],[-0.104114,0.359676,3.575304],[-0.344437,0.45939,3.579655],[-0.584504,0.360294,3.595924])),
                    #(false,true,#([-0.43,0.0,0.3],[-0.7,0.0,0.3],[-0.709936,0.00009,1.606008],[-0.683687,0.120437,3.61458],[-0.344,0.12,3.6])),
                    #(false,true,#([-0.43,0.0,0.3],[-0.620919,-0.190919,0.3],[-0.627881,-0.197838,1.610176],[-0.583886,-0.119676,3.624696],[-0.344,0.12,3.6])),
                    #(false,true,#([-0.43,0.0,0.3],[-0.43,-0.27,0.3],[-0.42991,-0.279874,1.608383],[-0.343563,-0.21939,3.620345],[-0.344,0.12,3.6])),
                    #(false,true,#([-0.43,0.0,0.3],[-0.239081,-0.190919,0.3],[-0.231992,-0.197965,1.601679],[-0.103496,-0.120294,3.604076],[-0.344,0.12,3.6])),
                    #(false,true,#([-0.43,0.0,0.3],[-0.16,0.0,0.3],[-0.150064,-0.00009,1.593992],[-0.004313,0.119563,3.58542],[-0.344,0.12,3.6])),
                    #(false,true,#([-0.43,0.0,0.3],[-0.239081,0.190919,0.3],[-0.232119,0.197838,1.589824],[-0.104114,0.359676,3.575304],[-0.344,0.12,3.6])),
                    #(false,true,#([-0.43,0.0,0.3],[-0.43,0.27,0.3],[-0.43009,0.279874,1.591617],[-0.344437,0.45939,3.579655],[-0.344,0.12,3.6])),
                    #(false,true,#([-0.43,0.0,0.3],[-0.620919,0.190919,0.3],[-0.628008,0.197965,1.598321],[-0.584504,0.360294,3.595924],[-0.344,0.12,3.6]))
                ) "dark" "body" true 0.0
                f.cage "RightTrouser" #(
                    #(true,true,#([0.16,0.0,0.3],[0.239081,-0.190919,0.3],[0.43,-0.27,0.3],[0.620919,-0.190919,0.3],[0.7,0.0,0.3],[0.620919,0.190919,0.3],[0.43,0.27,0.3],[0.239081,0.190919,0.3])),
                    #(true,true,#([0.150064,-0.00009,1.593992],[0.231992,-0.197965,1.601679],[0.42991,-0.279874,1.608383],[0.627881,-0.197838,1.610176],[0.709936,0.00009,1.606008],[0.628008,0.197965,1.598321],[0.43009,0.279874,1.591617],[0.232119,0.197838,1.589824])),
                    #(true,true,#([0.004313,0.119563,3.58542],[0.103496,-0.120294,3.604076],[0.343563,-0.21939,3.620345],[0.583886,-0.119676,3.624696],[0.683687,0.120437,3.61458],[0.584504,0.360294,3.595924],[0.344437,0.45939,3.579655],[0.104114,0.359676,3.575304])),
                    #(false,true,#([0.43,0.0,0.3],[0.16,0.0,0.3],[0.150064,-0.00009,1.593992],[0.004313,0.119563,3.58542],[0.344,0.12,3.6])),
                    #(false,true,#([0.43,0.0,0.3],[0.239081,-0.190919,0.3],[0.231992,-0.197965,1.601679],[0.103496,-0.120294,3.604076],[0.344,0.12,3.6])),
                    #(false,true,#([0.43,0.0,0.3],[0.43,-0.27,0.3],[0.42991,-0.279874,1.608383],[0.343563,-0.21939,3.620345],[0.344,0.12,3.6])),
                    #(false,true,#([0.43,0.0,0.3],[0.620919,-0.190919,0.3],[0.627881,-0.197838,1.610176],[0.583886,-0.119676,3.624696],[0.344,0.12,3.6])),
                    #(false,true,#([0.43,0.0,0.3],[0.7,0.0,0.3],[0.709936,0.00009,1.606008],[0.683687,0.120437,3.61458],[0.344,0.12,3.6])),
                    #(false,true,#([0.43,0.0,0.3],[0.620919,0.190919,0.3],[0.628008,0.197965,1.598321],[0.584504,0.360294,3.595924],[0.344,0.12,3.6])),
                    #(false,true,#([0.43,0.0,0.3],[0.43,0.27,0.3],[0.43009,0.279874,1.591617],[0.344437,0.45939,3.579655],[0.344,0.12,3.6])),
                    #(false,true,#([0.43,0.0,0.3],[0.239081,0.190919,0.3],[0.232119,0.197838,1.589824],[0.104114,0.359676,3.575304],[0.344,0.12,3.6]))
                ) "dark" "body" true 0.0
                f.cage "FrockCoat" #(
                    #(true,true,#([0.94,0.0,1.15],[0.66468,0.388909,1.15],[0.0,0.55,1.15],[-0.66468,0.388909,1.15],[-0.94,0.0,1.15],[-0.66468,-0.388909,1.15],[0.0,-0.55,1.15],[0.66468,-0.388909,1.15])),
                    #(true,true,#([0.87,0.0,3.4],[0.615183,0.403051,3.4],[0.0,0.57,3.4],[-0.615183,0.403051,3.4],[-0.87,0.0,3.4],[-0.615183,-0.403051,3.4],[0.0,-0.57,3.4],[0.615183,-0.403051,3.4])),
                    #(true,true,#([1.0,0.0,5.6],[0.707107,0.417193,5.6],[0.0,0.59,5.6],[-0.707107,0.417193,5.6],[-1.0,0.0,5.6],[-0.707107,-0.417193,5.6],[0.0,-0.59,5.6],[0.707107,-0.417193,5.6])),
                    #(true,true,#([0.5,0.0,6.0],[0.353553,0.282843,6.0],[0.0,0.4,6.0],[-0.353553,0.282843,6.0],[-0.5,0.0,6.0],[-0.353553,-0.282843,6.0],[0.0,-0.4,6.0],[0.353553,-0.282843,6.0])),
                    #(false,true,#([0.0,0.0,1.15],[0.94,0.0,1.15],[0.87,0.0,3.4],[1.0,0.0,5.6],[0.5,0.0,6.0],[0.0,0.0,6.0])),
                    #(false,true,#([0.0,0.0,1.15],[0.66468,0.388909,1.15],[0.615183,0.403051,3.4],[0.707107,0.417193,5.6],[0.353553,0.282843,6.0],[0.0,0.0,6.0])),
                    #(false,true,#([0.0,0.0,1.15],[0.0,0.55,1.15],[0.0,0.57,3.4],[0.0,0.59,5.6],[0.0,0.4,6.0],[0.0,0.0,6.0])),
                    #(false,true,#([0.0,0.0,1.15],[-0.66468,0.388909,1.15],[-0.615183,0.403051,3.4],[-0.707107,0.417193,5.6],[-0.353553,0.282843,6.0],[0.0,0.0,6.0])),
                    #(false,true,#([0.0,0.0,1.15],[-0.94,0.0,1.15],[-0.87,0.0,3.4],[-1.0,0.0,5.6],[-0.5,0.0,6.0],[0.0,0.0,6.0])),
                    #(false,true,#([0.0,0.0,1.15],[-0.66468,-0.388909,1.15],[-0.615183,-0.403051,3.4],[-0.707107,-0.417193,5.6],[-0.353553,-0.282843,6.0],[0.0,0.0,6.0])),
                    #(false,true,#([0.0,0.0,1.15],[0.0,-0.55,1.15],[0.0,-0.57,3.4],[0.0,-0.59,5.6],[0.0,-0.4,6.0],[0.0,0.0,6.0])),
                    #(false,true,#([0.0,0.0,1.15],[0.66468,-0.388909,1.15],[0.615183,-0.403051,3.4],[0.707107,-0.417193,5.6],[0.353553,-0.282843,6.0],[0.0,0.0,6.0]))
                ) "dark" "body" true 0.0
                f.cage "CaneSleeve" #(
                    #(true,true,#([-1.104908,0.202282,5.62],[-0.90765,0.292209,5.523583],[-0.688336,0.210964,5.483646],[-0.575439,0.006139,5.523583],[-0.635092,-0.202282,5.62],[-0.83235,-0.292209,5.716417],[-1.051664,-0.210964,5.756354],[-1.164561,-0.006139,5.716417])),
                    #(true,true,#([-1.400774,-0.193924,4.604416],[-1.214907,-0.097812,4.558137],[-1.008593,-0.155286,4.565669],[-0.902686,-0.332679,4.622602],[-0.959226,-0.526076,4.695584],[-1.145093,-0.622188,4.741863],[-1.351407,-0.564714,4.734331],[-1.457314,-0.387321,4.677398])),
                    #(true,true,#([-1.163508,-0.587723,3.601015],[-1.025963,-0.504646,3.597455],[-0.873209,-0.536004,3.636392],[-0.794727,-0.663429,3.695015],[-0.836492,-0.812277,3.738985],[-0.974037,-0.895354,3.742545],[-1.126791,-0.863996,3.703608],[-1.205273,-0.736571,3.644985])),
                    #(false,true,#([-0.87,0.0,5.62],[-1.104908,0.202282,5.62],[-1.400774,-0.193924,4.604416],[-1.163508,-0.587723,3.601015],[-1.0,-0.7,3.67])),
                    #(false,true,#([-0.87,0.0,5.62],[-0.90765,0.292209,5.523583],[-1.214907,-0.097812,4.558137],[-1.025963,-0.504646,3.597455],[-1.0,-0.7,3.67])),
                    #(false,true,#([-0.87,0.0,5.62],[-0.688336,0.210964,5.483646],[-1.008593,-0.155286,4.565669],[-0.873209,-0.536004,3.636392],[-1.0,-0.7,3.67])),
                    #(false,true,#([-0.87,0.0,5.62],[-0.575439,0.006139,5.523583],[-0.902686,-0.332679,4.622602],[-0.794727,-0.663429,3.695015],[-1.0,-0.7,3.67])),
                    #(false,true,#([-0.87,0.0,5.62],[-0.635092,-0.202282,5.62],[-0.959226,-0.526076,4.695584],[-0.836492,-0.812277,3.738985],[-1.0,-0.7,3.67])),
                    #(false,true,#([-0.87,0.0,5.62],[-0.83235,-0.292209,5.716417],[-1.145093,-0.622188,4.741863],[-0.974037,-0.895354,3.742545],[-1.0,-0.7,3.67])),
                    #(false,true,#([-0.87,0.0,5.62],[-1.051664,-0.210964,5.756354],[-1.351407,-0.564714,4.734331],[-1.126791,-0.863996,3.703608],[-1.0,-0.7,3.67])),
                    #(false,true,#([-0.87,0.0,5.62],[-1.164561,-0.006139,5.716417],[-1.457314,-0.387321,4.677398],[-1.205273,-0.736571,3.644985],[-1.0,-0.7,3.67]))
                ) "dark" "body" true 0.0
                f.cage "CaneHand" #(
                    #(true,true,#([-1.155563,-0.58565,3.58],[-1.155563,-0.625,3.7],[-1.155563,-0.72,3.749706],[-1.155563,-0.815,3.7],[-1.155563,-0.85435,3.58],[-1.155563,-0.815,3.46],[-1.155563,-0.72,3.410294],[-1.155563,-0.625,3.46])),
                    #(true,true,#([-1.0,-0.53,3.58],[-1.0,-0.58565,3.749706],[-1.0,-0.72,3.82],[-1.0,-0.85435,3.749706],[-1.0,-0.91,3.58],[-1.0,-0.85435,3.410294],[-1.0,-0.72,3.34],[-1.0,-0.58565,3.410294])),
                    #(true,true,#([-0.844437,-0.58565,3.58],[-0.844437,-0.625,3.7],[-0.844437,-0.72,3.749706],[-0.844437,-0.815,3.7],[-0.844437,-0.85435,3.58],[-0.844437,-0.815,3.46],[-0.844437,-0.72,3.410294],[-0.844437,-0.625,3.46])),
                    #(false,true,#([-1.22,-0.72,3.58],[-1.155563,-0.58565,3.58],[-1.0,-0.53,3.58],[-0.844437,-0.58565,3.58],[-0.78,-0.72,3.58])),
                    #(false,true,#([-1.22,-0.72,3.58],[-1.155563,-0.625,3.7],[-1.0,-0.58565,3.749706],[-0.844437,-0.625,3.7],[-0.78,-0.72,3.58])),
                    #(false,true,#([-1.22,-0.72,3.58],[-1.155563,-0.72,3.749706],[-1.0,-0.72,3.82],[-0.844437,-0.72,3.749706],[-0.78,-0.72,3.58])),
                    #(false,true,#([-1.22,-0.72,3.58],[-1.155563,-0.815,3.7],[-1.0,-0.85435,3.749706],[-0.844437,-0.815,3.7],[-0.78,-0.72,3.58])),
                    #(false,true,#([-1.22,-0.72,3.58],[-1.155563,-0.85435,3.58],[-1.0,-0.91,3.58],[-0.844437,-0.85435,3.58],[-0.78,-0.72,3.58])),
                    #(false,true,#([-1.22,-0.72,3.58],[-1.155563,-0.815,3.46],[-1.0,-0.85435,3.410294],[-0.844437,-0.815,3.46],[-0.78,-0.72,3.58])),
                    #(false,true,#([-1.22,-0.72,3.58],[-1.155563,-0.72,3.410294],[-1.0,-0.72,3.34],[-0.844437,-0.72,3.410294],[-0.78,-0.72,3.58])),
                    #(false,true,#([-1.22,-0.72,3.58],[-1.155563,-0.625,3.46],[-1.0,-0.58565,3.410294],[-0.844437,-0.625,3.46],[-0.78,-0.72,3.58]))
                ) "dark" "body" true 0.0
                f.cage "Cane" #(
                    #(true,true,#([-1.135,-0.75,0.03],[-1.104246,-0.824246,0.03],[-1.03,-0.855,0.03],[-0.955754,-0.824246,0.03],[-0.925,-0.75,0.03],[-0.955754,-0.675754,0.03],[-1.03,-0.645,0.03],[-1.104246,-0.675754,0.03])),
                    #(true,true,#([-1.135,-0.75,2.0],[-1.104246,-0.824246,2.0],[-1.03,-0.855,2.0],[-0.955754,-0.824246,2.0],[-0.925,-0.75,2.0],[-0.955754,-0.675754,2.0],[-1.03,-0.645,2.0],[-1.104246,-0.675754,2.0])),
                    #(true,true,#([-1.122833,-0.75,3.649062],[-1.095643,-0.824246,3.634692],[-1.03,-0.855,3.6],[-0.964357,-0.824246,3.565308],[-0.937167,-0.75,3.550938],[-0.964357,-0.675754,3.565308],[-1.03,-0.645,3.6],[-1.095643,-0.675754,3.634692])),
                    #(true,true,#([-0.866334,-0.75,3.832623],[-0.849834,-0.820711,3.808423],[-0.81,-0.85,3.75],[-0.770166,-0.820711,3.691577],[-0.753666,-0.75,3.667377],[-0.770166,-0.679289,3.691577],[-0.81,-0.65,3.75],[-0.849834,-0.679289,3.808423])),
                    #(false,true,#([-1.03,-0.75,0.03],[-1.135,-0.75,0.03],[-1.135,-0.75,2.0],[-1.122833,-0.75,3.649062],[-0.866334,-0.75,3.832623],[-0.81,-0.75,3.75])),
                    #(false,true,#([-1.03,-0.75,0.03],[-1.104246,-0.824246,0.03],[-1.104246,-0.824246,2.0],[-1.095643,-0.824246,3.634692],[-0.849834,-0.820711,3.808423],[-0.81,-0.75,3.75])),
                    #(false,true,#([-1.03,-0.75,0.03],[-1.03,-0.855,0.03],[-1.03,-0.855,2.0],[-1.03,-0.855,3.6],[-0.81,-0.85,3.75],[-0.81,-0.75,3.75])),
                    #(false,true,#([-1.03,-0.75,0.03],[-0.955754,-0.824246,0.03],[-0.955754,-0.824246,2.0],[-0.964357,-0.824246,3.565308],[-0.770166,-0.820711,3.691577],[-0.81,-0.75,3.75])),
                    #(false,true,#([-1.03,-0.75,0.03],[-0.925,-0.75,0.03],[-0.925,-0.75,2.0],[-0.937167,-0.75,3.550938],[-0.753666,-0.75,3.667377],[-0.81,-0.75,3.75])),
                    #(false,true,#([-1.03,-0.75,0.03],[-0.955754,-0.675754,0.03],[-0.955754,-0.675754,2.0],[-0.964357,-0.675754,3.565308],[-0.770166,-0.679289,3.691577],[-0.81,-0.75,3.75])),
                    #(false,true,#([-1.03,-0.75,0.03],[-1.03,-0.645,0.03],[-1.03,-0.645,2.0],[-1.03,-0.645,3.6],[-0.81,-0.65,3.75],[-0.81,-0.75,3.75])),
                    #(false,true,#([-1.03,-0.75,0.03],[-1.104246,-0.675754,0.03],[-1.104246,-0.675754,2.0],[-1.095643,-0.675754,3.634692],[-0.849834,-0.679289,3.808423],[-0.81,-0.75,3.75]))
                ) "dark" "body" true 0.0
                f.cage "RestingSleeve" #(
                    #(true,true,#([1.157343,0.0,5.660503],[1.068424,-0.219041,5.640295],[0.851555,-0.309771,5.608198],[0.633776,-0.219041,5.583015],[0.542657,0.0,5.579497],[0.631576,0.219041,5.599705],[0.848445,0.309771,5.631802],[1.066224,0.219041,5.656985])),
                    #(true,true,#([1.279881,0.048957,4.322211],[1.203514,-0.13387,4.34069],[1.019647,-0.208989,4.352907],[0.835987,-0.132395,4.351705],[0.760119,0.051043,4.337789],[0.836486,0.23387,4.31931],[1.020353,0.308989,4.307093],[1.204013,0.232395,4.308295])),
                    #(true,true,#([1.04617,-0.155916,3.380519],[0.987657,-0.29928,3.423602],[0.842648,-0.355198,3.464575],[0.696088,-0.290913,3.479436],[0.63383,-0.144084,3.459481],[0.692343,-0.00072,3.416398],[0.837352,0.055198,3.375425],[0.983912,-0.009087,3.360564])),
                    #(false,true,#([0.85,0.0,5.62],[1.157343,0.0,5.660503],[1.279881,0.048957,4.322211],[1.04617,-0.155916,3.380519],[0.84,-0.15,3.42])),
                    #(false,true,#([0.85,0.0,5.62],[1.068424,-0.219041,5.640295],[1.203514,-0.13387,4.34069],[0.987657,-0.29928,3.423602],[0.84,-0.15,3.42])),
                    #(false,true,#([0.85,0.0,5.62],[0.851555,-0.309771,5.608198],[1.019647,-0.208989,4.352907],[0.842648,-0.355198,3.464575],[0.84,-0.15,3.42])),
                    #(false,true,#([0.85,0.0,5.62],[0.633776,-0.219041,5.583015],[0.835987,-0.132395,4.351705],[0.696088,-0.290913,3.479436],[0.84,-0.15,3.42])),
                    #(false,true,#([0.85,0.0,5.62],[0.542657,0.0,5.579497],[0.760119,0.051043,4.337789],[0.63383,-0.144084,3.459481],[0.84,-0.15,3.42])),
                    #(false,true,#([0.85,0.0,5.62],[0.631576,0.219041,5.599705],[0.836486,0.23387,4.31931],[0.692343,-0.00072,3.416398],[0.84,-0.15,3.42])),
                    #(false,true,#([0.85,0.0,5.62],[0.848445,0.309771,5.631802],[1.020353,0.308989,4.307093],[0.837352,0.055198,3.375425],[0.84,-0.15,3.42])),
                    #(false,true,#([0.85,0.0,5.62],[1.066224,0.219041,5.656985],[1.204013,0.232395,4.308295],[0.983912,-0.009087,3.360564],[0.84,-0.15,3.42]))
                ) "dark" "body" true 0.0
                f.cage "RestingHand" #(
                    #(true,true,#([0.691508,-0.01565,3.24],[0.691508,-0.055,3.39],[0.691508,-0.15,3.452132],[0.691508,-0.245,3.39],[0.691508,-0.28435,3.24],[0.691508,-0.245,3.09],[0.691508,-0.15,3.027868],[0.691508,-0.055,3.09])),
                    #(true,true,#([0.84,0.04,3.24],[0.84,-0.01565,3.452132],[0.84,-0.15,3.54],[0.84,-0.28435,3.452132],[0.84,-0.34,3.24],[0.84,-0.28435,3.027868],[0.84,-0.15,2.94],[0.84,-0.01565,3.027868])),
                    #(true,true,#([0.988492,-0.01565,3.24],[0.988492,-0.055,3.39],[0.988492,-0.15,3.452132],[0.988492,-0.245,3.39],[0.988492,-0.28435,3.24],[0.988492,-0.245,3.09],[0.988492,-0.15,3.027868],[0.988492,-0.055,3.09])),
                    #(false,true,#([0.63,-0.15,3.24],[0.691508,-0.01565,3.24],[0.84,0.04,3.24],[0.988492,-0.01565,3.24],[1.05,-0.15,3.24])),
                    #(false,true,#([0.63,-0.15,3.24],[0.691508,-0.055,3.39],[0.84,-0.01565,3.452132],[0.988492,-0.055,3.39],[1.05,-0.15,3.24])),
                    #(false,true,#([0.63,-0.15,3.24],[0.691508,-0.15,3.452132],[0.84,-0.15,3.54],[0.988492,-0.15,3.452132],[1.05,-0.15,3.24])),
                    #(false,true,#([0.63,-0.15,3.24],[0.691508,-0.245,3.39],[0.84,-0.28435,3.452132],[0.988492,-0.245,3.39],[1.05,-0.15,3.24])),
                    #(false,true,#([0.63,-0.15,3.24],[0.691508,-0.28435,3.24],[0.84,-0.34,3.24],[0.988492,-0.28435,3.24],[1.05,-0.15,3.24])),
                    #(false,true,#([0.63,-0.15,3.24],[0.691508,-0.245,3.09],[0.84,-0.28435,3.027868],[0.988492,-0.245,3.09],[1.05,-0.15,3.24])),
                    #(false,true,#([0.63,-0.15,3.24],[0.691508,-0.15,3.027868],[0.84,-0.15,2.94],[0.988492,-0.15,3.027868],[1.05,-0.15,3.24])),
                    #(false,true,#([0.63,-0.15,3.24],[0.691508,-0.055,3.09],[0.84,-0.01565,3.027868],[0.988492,-0.055,3.09],[1.05,-0.15,3.24]))
                ) "dark" "body" true 0.0
                f.cage "Head" #(
                    #(true,true,#([-0.431335,0.33234,6.9],[-0.431335,0.235,7.295],[-0.431335,0.0,7.458614],[-0.431335,-0.235,7.295],[-0.431335,-0.33234,6.9],[-0.431335,-0.235,6.505],[-0.431335,0.0,6.341386],[-0.431335,0.235,6.505])),
                    #(true,true,#([0.0,0.47,6.9],[0.0,0.33234,7.458614],[0.0,0.0,7.69],[0.0,-0.33234,7.458614],[0.0,-0.47,6.9],[0.0,-0.33234,6.341386],[0.0,0.0,6.11],[0.0,0.33234,6.341386])),
                    #(true,true,#([0.431335,0.33234,6.9],[0.431335,0.235,7.295],[0.431335,0.0,7.458614],[0.431335,-0.235,7.295],[0.431335,-0.33234,6.9],[0.431335,-0.235,6.505],[0.431335,0.0,6.341386],[0.431335,0.235,6.505])),
                    #(false,true,#([-0.61,0.0,6.9],[-0.431335,0.33234,6.9],[0.0,0.47,6.9],[0.431335,0.33234,6.9],[0.61,0.0,6.9])),
                    #(false,true,#([-0.61,0.0,6.9],[-0.431335,0.235,7.295],[0.0,0.33234,7.458614],[0.431335,0.235,7.295],[0.61,0.0,6.9])),
                    #(false,true,#([-0.61,0.0,6.9],[-0.431335,0.0,7.458614],[0.0,0.0,7.69],[0.431335,0.0,7.458614],[0.61,0.0,6.9])),
                    #(false,true,#([-0.61,0.0,6.9],[-0.431335,-0.235,7.295],[0.0,-0.33234,7.458614],[0.431335,-0.235,7.295],[0.61,0.0,6.9])),
                    #(false,true,#([-0.61,0.0,6.9],[-0.431335,-0.33234,6.9],[0.0,-0.47,6.9],[0.431335,-0.33234,6.9],[0.61,0.0,6.9])),
                    #(false,true,#([-0.61,0.0,6.9],[-0.431335,-0.235,6.505],[0.0,-0.33234,6.341386],[0.431335,-0.235,6.505],[0.61,0.0,6.9])),
                    #(false,true,#([-0.61,0.0,6.9],[-0.431335,0.0,6.341386],[0.0,0.0,6.11],[0.431335,0.0,6.341386],[0.61,0.0,6.9])),
                    #(false,true,#([-0.61,0.0,6.9],[-0.431335,0.235,6.505],[0.0,0.33234,6.341386],[0.431335,0.235,6.505],[0.61,0.0,6.9]))
                ) "dark" "head" true 0.0
                f.cage "FacePlate" #(
                    #(true,true,#([-0.339411,-0.328076,6.87],[-0.339411,-0.355,7.185],[-0.339411,-0.42,7.315477],[-0.339411,-0.485,7.185],[-0.339411,-0.511924,6.87],[-0.339411,-0.485,6.555],[-0.339411,-0.42,6.424523],[-0.339411,-0.355,6.555])),
                    #(true,true,#([0.0,-0.29,6.87],[0.0,-0.328076,7.315477],[0.0,-0.42,7.5],[0.0,-0.511924,7.315477],[0.0,-0.55,6.87],[0.0,-0.511924,6.424523],[0.0,-0.42,6.24],[0.0,-0.328076,6.424523])),
                    #(true,true,#([0.339411,-0.328076,6.87],[0.339411,-0.355,7.185],[0.339411,-0.42,7.315477],[0.339411,-0.485,7.185],[0.339411,-0.511924,6.87],[0.339411,-0.485,6.555],[0.339411,-0.42,6.424523],[0.339411,-0.355,6.555])),
                    #(false,true,#([-0.48,-0.42,6.87],[-0.339411,-0.328076,6.87],[0.0,-0.29,6.87],[0.339411,-0.328076,6.87],[0.48,-0.42,6.87])),
                    #(false,true,#([-0.48,-0.42,6.87],[-0.339411,-0.355,7.185],[0.0,-0.328076,7.315477],[0.339411,-0.355,7.185],[0.48,-0.42,6.87])),
                    #(false,true,#([-0.48,-0.42,6.87],[-0.339411,-0.42,7.315477],[0.0,-0.42,7.5],[0.339411,-0.42,7.315477],[0.48,-0.42,6.87])),
                    #(false,true,#([-0.48,-0.42,6.87],[-0.339411,-0.485,7.185],[0.0,-0.511924,7.315477],[0.339411,-0.485,7.185],[0.48,-0.42,6.87])),
                    #(false,true,#([-0.48,-0.42,6.87],[-0.339411,-0.511924,6.87],[0.0,-0.55,6.87],[0.339411,-0.511924,6.87],[0.48,-0.42,6.87])),
                    #(false,true,#([-0.48,-0.42,6.87],[-0.339411,-0.485,6.555],[0.0,-0.511924,6.424523],[0.339411,-0.485,6.555],[0.48,-0.42,6.87])),
                    #(false,true,#([-0.48,-0.42,6.87],[-0.339411,-0.42,6.424523],[0.0,-0.42,6.24],[0.339411,-0.42,6.424523],[0.48,-0.42,6.87])),
                    #(false,true,#([-0.48,-0.42,6.87],[-0.339411,-0.355,6.555],[0.0,-0.328076,6.424523],[0.339411,-0.355,6.555],[0.48,-0.42,6.87]))
                ) "ivory_glow" "mask" true 0.0
                f.cage "EyeLeft" #(
                    #(true,true,#([-0.292659,-0.458707,6.9834],[-0.292659,-0.4824,7.04955],[-0.292659,-0.5396,7.07695],[-0.292659,-0.5968,7.04955],[-0.292659,-0.620493,6.9834],[-0.292659,-0.5968,6.91725],[-0.292659,-0.5396,6.88985],[-0.292659,-0.4824,6.91725])),
                    #(true,true,#([-0.2112,-0.4252,6.9834],[-0.2112,-0.458707,7.07695],[-0.2112,-0.5396,7.1157],[-0.2112,-0.620493,7.07695],[-0.2112,-0.654,6.9834],[-0.2112,-0.620493,6.88985],[-0.2112,-0.5396,6.8511],[-0.2112,-0.458707,6.88985])),
                    #(true,true,#([-0.129741,-0.458707,6.9834],[-0.129741,-0.4824,7.04955],[-0.129741,-0.5396,7.07695],[-0.129741,-0.5968,7.04955],[-0.129741,-0.620493,6.9834],[-0.129741,-0.5968,6.91725],[-0.129741,-0.5396,6.88985],[-0.129741,-0.4824,6.91725])),
                    #(false,true,#([-0.3264,-0.5396,6.9834],[-0.292659,-0.458707,6.9834],[-0.2112,-0.4252,6.9834],[-0.129741,-0.458707,6.9834],[-0.096,-0.5396,6.9834])),
                    #(false,true,#([-0.3264,-0.5396,6.9834],[-0.292659,-0.4824,7.04955],[-0.2112,-0.458707,7.07695],[-0.129741,-0.4824,7.04955],[-0.096,-0.5396,6.9834])),
                    #(false,true,#([-0.3264,-0.5396,6.9834],[-0.292659,-0.5396,7.07695],[-0.2112,-0.5396,7.1157],[-0.129741,-0.5396,7.07695],[-0.096,-0.5396,6.9834])),
                    #(false,true,#([-0.3264,-0.5396,6.9834],[-0.292659,-0.5968,7.04955],[-0.2112,-0.620493,7.07695],[-0.129741,-0.5968,7.04955],[-0.096,-0.5396,6.9834])),
                    #(false,true,#([-0.3264,-0.5396,6.9834],[-0.292659,-0.620493,6.9834],[-0.2112,-0.654,6.9834],[-0.129741,-0.620493,6.9834],[-0.096,-0.5396,6.9834])),
                    #(false,true,#([-0.3264,-0.5396,6.9834],[-0.292659,-0.5968,6.91725],[-0.2112,-0.620493,6.88985],[-0.129741,-0.5968,6.91725],[-0.096,-0.5396,6.9834])),
                    #(false,true,#([-0.3264,-0.5396,6.9834],[-0.292659,-0.5396,6.88985],[-0.2112,-0.5396,6.8511],[-0.129741,-0.5396,6.88985],[-0.096,-0.5396,6.9834])),
                    #(false,true,#([-0.3264,-0.5396,6.9834],[-0.292659,-0.4824,6.91725],[-0.2112,-0.458707,6.88985],[-0.129741,-0.4824,6.91725],[-0.096,-0.5396,6.9834]))
                ) "dark" "mask" true 0.0
                f.cage "EyeRight" #(
                    #(true,true,#([0.129741,-0.458707,6.9834],[0.129741,-0.4824,7.04955],[0.129741,-0.5396,7.07695],[0.129741,-0.5968,7.04955],[0.129741,-0.620493,6.9834],[0.129741,-0.5968,6.91725],[0.129741,-0.5396,6.88985],[0.129741,-0.4824,6.91725])),
                    #(true,true,#([0.2112,-0.4252,6.9834],[0.2112,-0.458707,7.07695],[0.2112,-0.5396,7.1157],[0.2112,-0.620493,7.07695],[0.2112,-0.654,6.9834],[0.2112,-0.620493,6.88985],[0.2112,-0.5396,6.8511],[0.2112,-0.458707,6.88985])),
                    #(true,true,#([0.292659,-0.458707,6.9834],[0.292659,-0.4824,7.04955],[0.292659,-0.5396,7.07695],[0.292659,-0.5968,7.04955],[0.292659,-0.620493,6.9834],[0.292659,-0.5968,6.91725],[0.292659,-0.5396,6.88985],[0.292659,-0.4824,6.91725])),
                    #(false,true,#([0.096,-0.5396,6.9834],[0.129741,-0.458707,6.9834],[0.2112,-0.4252,6.9834],[0.292659,-0.458707,6.9834],[0.3264,-0.5396,6.9834])),
                    #(false,true,#([0.096,-0.5396,6.9834],[0.129741,-0.4824,7.04955],[0.2112,-0.458707,7.07695],[0.292659,-0.4824,7.04955],[0.3264,-0.5396,6.9834])),
                    #(false,true,#([0.096,-0.5396,6.9834],[0.129741,-0.5396,7.07695],[0.2112,-0.5396,7.1157],[0.292659,-0.5396,7.07695],[0.3264,-0.5396,6.9834])),
                    #(false,true,#([0.096,-0.5396,6.9834],[0.129741,-0.5968,7.04955],[0.2112,-0.620493,7.07695],[0.292659,-0.5968,7.04955],[0.3264,-0.5396,6.9834])),
                    #(false,true,#([0.096,-0.5396,6.9834],[0.129741,-0.620493,6.9834],[0.2112,-0.654,6.9834],[0.292659,-0.620493,6.9834],[0.3264,-0.5396,6.9834])),
                    #(false,true,#([0.096,-0.5396,6.9834],[0.129741,-0.5968,6.91725],[0.2112,-0.620493,6.88985],[0.292659,-0.5968,6.91725],[0.3264,-0.5396,6.9834])),
                    #(false,true,#([0.096,-0.5396,6.9834],[0.129741,-0.5396,6.88985],[0.2112,-0.5396,6.8511],[0.292659,-0.5396,6.88985],[0.3264,-0.5396,6.9834])),
                    #(false,true,#([0.096,-0.5396,6.9834],[0.129741,-0.4824,6.91725],[0.2112,-0.458707,6.88985],[0.292659,-0.4824,6.91725],[0.3264,-0.5396,6.9834]))
                ) "dark" "mask" true 0.0
                f.cage "QuietMouth" #(
                    #(true,false,#([-0.1296,-0.641,6.5202],[0.1296,-0.641,6.5202],[0.1296,-0.459,6.5202],[-0.1296,-0.459,6.5202])),
                    #(true,false,#([-0.1296,-0.641,6.6402],[0.1296,-0.641,6.6402],[0.1296,-0.459,6.6402],[-0.1296,-0.459,6.6402])),
                    #(false,false,#([-0.1296,-0.641,6.5202],[-0.1296,-0.641,6.6402])),
                    #(false,false,#([0.1296,-0.641,6.5202],[0.1296,-0.641,6.6402])),
                    #(false,false,#([0.1296,-0.459,6.5202],[0.1296,-0.459,6.6402])),
                    #(false,false,#([-0.1296,-0.459,6.5202],[-0.1296,-0.459,6.6402]))
                ) "dark" "mask" true 0.0
                f.cage "BowlerBrim" #(
                    #(true,true,#([-0.692965,0.509117,7.53],[-0.692965,0.36,7.605],[-0.692965,0.0,7.636066],[-0.692965,-0.36,7.605],[-0.692965,-0.509117,7.53],[-0.692965,-0.36,7.455],[-0.692965,0.0,7.423934],[-0.692965,0.36,7.455])),
                    #(true,true,#([0.0,0.72,7.53],[0.0,0.509117,7.636066],[0.0,0.0,7.68],[0.0,-0.509117,7.636066],[0.0,-0.72,7.53],[0.0,-0.509117,7.423934],[0.0,0.0,7.38],[0.0,0.509117,7.423934])),
                    #(true,true,#([0.692965,0.509117,7.53],[0.692965,0.36,7.605],[0.692965,0.0,7.636066],[0.692965,-0.36,7.605],[0.692965,-0.509117,7.53],[0.692965,-0.36,7.455],[0.692965,0.0,7.423934],[0.692965,0.36,7.455])),
                    #(false,true,#([-0.98,0.0,7.53],[-0.692965,0.509117,7.53],[0.0,0.72,7.53],[0.692965,0.509117,7.53],[0.98,0.0,7.53])),
                    #(false,true,#([-0.98,0.0,7.53],[-0.692965,0.36,7.605],[0.0,0.509117,7.636066],[0.692965,0.36,7.605],[0.98,0.0,7.53])),
                    #(false,true,#([-0.98,0.0,7.53],[-0.692965,0.0,7.636066],[0.0,0.0,7.68],[0.692965,0.0,7.636066],[0.98,0.0,7.53])),
                    #(false,true,#([-0.98,0.0,7.53],[-0.692965,-0.36,7.605],[0.0,-0.509117,7.636066],[0.692965,-0.36,7.605],[0.98,0.0,7.53])),
                    #(false,true,#([-0.98,0.0,7.53],[-0.692965,-0.509117,7.53],[0.0,-0.72,7.53],[0.692965,-0.509117,7.53],[0.98,0.0,7.53])),
                    #(false,true,#([-0.98,0.0,7.53],[-0.692965,-0.36,7.455],[0.0,-0.509117,7.423934],[0.692965,-0.36,7.455],[0.98,0.0,7.53])),
                    #(false,true,#([-0.98,0.0,7.53],[-0.692965,0.0,7.423934],[0.0,0.0,7.38],[0.692965,0.0,7.423934],[0.98,0.0,7.53])),
                    #(false,true,#([-0.98,0.0,7.53],[-0.692965,0.36,7.455],[0.0,0.509117,7.423934],[0.692965,0.36,7.455],[0.98,0.0,7.53]))
                ) "dark" "head" true 0.0
                f.cage "BowlerCrown" #(
                    #(true,true,#([0.64,0.0,7.5],[0.452548,0.346482,7.5],[0.0,0.49,7.5],[-0.452548,0.346482,7.5],[-0.64,0.0,7.5],[-0.452548,-0.346482,7.5],[0.0,-0.49,7.5],[0.452548,-0.346482,7.5])),
                    #(true,true,#([0.63,0.0,7.95],[0.445477,0.339411,7.95],[0.0,0.48,7.95],[-0.445477,0.339411,7.95],[-0.63,0.0,7.95],[-0.445477,-0.339411,7.95],[0.0,-0.48,7.95],[0.445477,-0.339411,7.95])),
                    #(true,true,#([0.4,0.0,8.17],[0.282843,0.233345,8.17],[0.0,0.33,8.17],[-0.282843,0.233345,8.17],[-0.4,0.0,8.17],[-0.282843,-0.233345,8.17],[0.0,-0.33,8.17],[0.282843,-0.233345,8.17])),
                    #(false,true,#([0.0,0.0,7.5],[0.64,0.0,7.5],[0.63,0.0,7.95],[0.4,0.0,8.17],[0.0,0.0,8.17])),
                    #(false,true,#([0.0,0.0,7.5],[0.452548,0.346482,7.5],[0.445477,0.339411,7.95],[0.282843,0.233345,8.17],[0.0,0.0,8.17])),
                    #(false,true,#([0.0,0.0,7.5],[0.0,0.49,7.5],[0.0,0.48,7.95],[0.0,0.33,8.17],[0.0,0.0,8.17])),
                    #(false,true,#([0.0,0.0,7.5],[-0.452548,0.346482,7.5],[-0.445477,0.339411,7.95],[-0.282843,0.233345,8.17],[0.0,0.0,8.17])),
                    #(false,true,#([0.0,0.0,7.5],[-0.64,0.0,7.5],[-0.63,0.0,7.95],[-0.4,0.0,8.17],[0.0,0.0,8.17])),
                    #(false,true,#([0.0,0.0,7.5],[-0.452548,-0.346482,7.5],[-0.445477,-0.339411,7.95],[-0.282843,-0.233345,8.17],[0.0,0.0,8.17])),
                    #(false,true,#([0.0,0.0,7.5],[0.0,-0.49,7.5],[0.0,-0.48,7.95],[0.0,-0.33,8.17],[0.0,0.0,8.17])),
                    #(false,true,#([0.0,0.0,7.5],[0.452548,-0.346482,7.5],[0.445477,-0.339411,7.95],[0.282843,-0.233345,8.17],[0.0,0.0,8.17]))
                ) "dark" "head" true 0.0
                f.tube "OldLapel" #([-0.23,-0.53,5.88],[-0.47,-0.61,5.28],[-0.13,-0.61,4.52]) 0.085 5 false true "violet_glow" "body"
                f.finishModel()
                f.startModel "paradedead2" "The shawled widow" "dead" 2 0.23 [0.0,-0.02,6.15] "A long bell dress, folded shawl, broad period hat and clasped hands." true
                f.cage "HiddenLeftShoe" #(
                    #(true,true,#([-0.563848,0.003553,0.21],[-0.563848,-0.1,0.315],[-0.563848,-0.35,0.358492],[-0.563848,-0.6,0.315],[-0.563848,-0.703553,0.21],[-0.563848,-0.6,0.105],[-0.563848,-0.35,0.061508],[-0.563848,-0.1,0.105])),
                    #(true,true,#([-0.38,0.15,0.21],[-0.38,0.003553,0.358492],[-0.38,-0.35,0.42],[-0.38,-0.703553,0.358492],[-0.38,-0.85,0.21],[-0.38,-0.703553,0.061508],[-0.38,-0.35,0.0],[-0.38,0.003553,0.061508])),
                    #(true,true,#([-0.196152,0.003553,0.21],[-0.196152,-0.1,0.315],[-0.196152,-0.35,0.358492],[-0.196152,-0.6,0.315],[-0.196152,-0.703553,0.21],[-0.196152,-0.6,0.105],[-0.196152,-0.35,0.061508],[-0.196152,-0.1,0.105])),
                    #(false,true,#([-0.64,-0.35,0.21],[-0.563848,0.003553,0.21],[-0.38,0.15,0.21],[-0.196152,0.003553,0.21],[-0.12,-0.35,0.21])),
                    #(false,true,#([-0.64,-0.35,0.21],[-0.563848,-0.1,0.315],[-0.38,0.003553,0.358492],[-0.196152,-0.1,0.315],[-0.12,-0.35,0.21])),
                    #(false,true,#([-0.64,-0.35,0.21],[-0.563848,-0.35,0.358492],[-0.38,-0.35,0.42],[-0.196152,-0.35,0.358492],[-0.12,-0.35,0.21])),
                    #(false,true,#([-0.64,-0.35,0.21],[-0.563848,-0.6,0.315],[-0.38,-0.703553,0.358492],[-0.196152,-0.6,0.315],[-0.12,-0.35,0.21])),
                    #(false,true,#([-0.64,-0.35,0.21],[-0.563848,-0.703553,0.21],[-0.38,-0.85,0.21],[-0.196152,-0.703553,0.21],[-0.12,-0.35,0.21])),
                    #(false,true,#([-0.64,-0.35,0.21],[-0.563848,-0.6,0.105],[-0.38,-0.703553,0.061508],[-0.196152,-0.6,0.105],[-0.12,-0.35,0.21])),
                    #(false,true,#([-0.64,-0.35,0.21],[-0.563848,-0.35,0.061508],[-0.38,-0.35,0.0],[-0.196152,-0.35,0.061508],[-0.12,-0.35,0.21])),
                    #(false,true,#([-0.64,-0.35,0.21],[-0.563848,-0.1,0.105],[-0.38,0.003553,0.061508],[-0.196152,-0.1,0.105],[-0.12,-0.35,0.21]))
                ) "dark" "body" true 0.0
                f.cage "HiddenRightShoe" #(
                    #(true,true,#([0.196152,0.073553,0.21],[0.196152,-0.03,0.315],[0.196152,-0.28,0.358492],[0.196152,-0.53,0.315],[0.196152,-0.633553,0.21],[0.196152,-0.53,0.105],[0.196152,-0.28,0.061508],[0.196152,-0.03,0.105])),
                    #(true,true,#([0.38,0.22,0.21],[0.38,0.073553,0.358492],[0.38,-0.28,0.42],[0.38,-0.633553,0.358492],[0.38,-0.78,0.21],[0.38,-0.633553,0.061508],[0.38,-0.28,0.0],[0.38,0.073553,0.061508])),
                    #(true,true,#([0.563848,0.073553,0.21],[0.563848,-0.03,0.315],[0.563848,-0.28,0.358492],[0.563848,-0.53,0.315],[0.563848,-0.633553,0.21],[0.563848,-0.53,0.105],[0.563848,-0.28,0.061508],[0.563848,-0.03,0.105])),
                    #(false,true,#([0.12,-0.28,0.21],[0.196152,0.073553,0.21],[0.38,0.22,0.21],[0.563848,0.073553,0.21],[0.64,-0.28,0.21])),
                    #(false,true,#([0.12,-0.28,0.21],[0.196152,-0.03,0.315],[0.38,0.073553,0.358492],[0.563848,-0.03,0.315],[0.64,-0.28,0.21])),
                    #(false,true,#([0.12,-0.28,0.21],[0.196152,-0.28,0.358492],[0.38,-0.28,0.42],[0.563848,-0.28,0.358492],[0.64,-0.28,0.21])),
                    #(false,true,#([0.12,-0.28,0.21],[0.196152,-0.53,0.315],[0.38,-0.633553,0.358492],[0.563848,-0.53,0.315],[0.64,-0.28,0.21])),
                    #(false,true,#([0.12,-0.28,0.21],[0.196152,-0.633553,0.21],[0.38,-0.78,0.21],[0.563848,-0.633553,0.21],[0.64,-0.28,0.21])),
                    #(false,true,#([0.12,-0.28,0.21],[0.196152,-0.53,0.105],[0.38,-0.633553,0.061508],[0.563848,-0.53,0.105],[0.64,-0.28,0.21])),
                    #(false,true,#([0.12,-0.28,0.21],[0.196152,-0.28,0.061508],[0.38,-0.28,0.0],[0.563848,-0.28,0.061508],[0.64,-0.28,0.21])),
                    #(false,true,#([0.12,-0.28,0.21],[0.196152,-0.03,0.105],[0.38,0.073553,0.061508],[0.563848,-0.03,0.105],[0.64,-0.28,0.21]))
                ) "dark" "body" true 0.0
                f.cage "BellDress" #(
                    #(true,true,#([1.52,0.0,0.34],[1.074802,0.66468,0.34],[0.0,0.94,0.34],[-1.074802,0.66468,0.34],[-1.52,0.0,0.34],[-1.074802,-0.66468,0.34],[0.0,-0.94,0.34],[1.074802,-0.66468,0.34])),
                    #(true,true,#([1.47,0.0,1.0],[1.039447,0.650538,1.0],[0.0,0.92,1.0],[-1.039447,0.650538,1.0],[-1.47,0.0,1.0],[-1.039447,-0.650538,1.0],[0.0,-0.92,1.0],[1.039447,-0.650538,1.0])),
                    #(true,true,#([1.17,0.0,2.5],[0.827315,0.551543,2.5],[0.0,0.78,2.5],[-0.827315,0.551543,2.5],[-1.17,0.0,2.5],[-0.827315,-0.551543,2.5],[0.0,-0.78,2.5],[0.827315,-0.551543,2.5])),
                    #(true,true,#([0.71,0.0,3.9],[0.502046,0.353553,3.9],[0.0,0.5,3.9],[-0.502046,0.353553,3.9],[-0.71,0.0,3.9],[-0.502046,-0.353553,3.9],[0.0,-0.5,3.9],[0.502046,-0.353553,3.9])),
                    #(true,true,#([0.76,0.0,4.8],[0.537401,0.346482,4.8],[0.0,0.49,4.8],[-0.537401,0.346482,4.8],[-0.76,0.0,4.8],[-0.537401,-0.346482,4.8],[0.0,-0.49,4.8],[0.537401,-0.346482,4.8])),
                    #(true,true,#([0.88,0.0,5.7],[0.622254,0.346482,5.7],[0.0,0.49,5.7],[-0.622254,0.346482,5.7],[-0.88,0.0,5.7],[-0.622254,-0.346482,5.7],[0.0,-0.49,5.7],[0.622254,-0.346482,5.7])),
                    #(false,true,#([0.0,0.0,0.34],[1.52,0.0,0.34],[1.47,0.0,1.0],[1.17,0.0,2.5],[0.71,0.0,3.9],[0.76,0.0,4.8],[0.88,0.0,5.7],[0.0,0.0,5.7])),
                    #(false,true,#([0.0,0.0,0.34],[1.074802,0.66468,0.34],[1.039447,0.650538,1.0],[0.827315,0.551543,2.5],[0.502046,0.353553,3.9],[0.537401,0.346482,4.8],[0.622254,0.346482,5.7],[0.0,0.0,5.7])),
                    #(false,true,#([0.0,0.0,0.34],[0.0,0.94,0.34],[0.0,0.92,1.0],[0.0,0.78,2.5],[0.0,0.5,3.9],[0.0,0.49,4.8],[0.0,0.49,5.7],[0.0,0.0,5.7])),
                    #(false,true,#([0.0,0.0,0.34],[-1.074802,0.66468,0.34],[-1.039447,0.650538,1.0],[-0.827315,0.551543,2.5],[-0.502046,0.353553,3.9],[-0.537401,0.346482,4.8],[-0.622254,0.346482,5.7],[0.0,0.0,5.7])),
                    #(false,true,#([0.0,0.0,0.34],[-1.52,0.0,0.34],[-1.47,0.0,1.0],[-1.17,0.0,2.5],[-0.71,0.0,3.9],[-0.76,0.0,4.8],[-0.88,0.0,5.7],[0.0,0.0,5.7])),
                    #(false,true,#([0.0,0.0,0.34],[-1.074802,-0.66468,0.34],[-1.039447,-0.650538,1.0],[-0.827315,-0.551543,2.5],[-0.502046,-0.353553,3.9],[-0.537401,-0.346482,4.8],[-0.622254,-0.346482,5.7],[0.0,0.0,5.7])),
                    #(false,true,#([0.0,0.0,0.34],[0.0,-0.94,0.34],[0.0,-0.92,1.0],[0.0,-0.78,2.5],[0.0,-0.5,3.9],[0.0,-0.49,4.8],[0.0,-0.49,5.7],[0.0,0.0,5.7])),
                    #(false,true,#([0.0,0.0,0.34],[1.074802,-0.66468,0.34],[1.039447,-0.650538,1.0],[0.827315,-0.551543,2.5],[0.502046,-0.353553,3.9],[0.537401,-0.346482,4.8],[0.622254,-0.346482,5.7],[0.0,0.0,5.7]))
                ) "dark" "body" true 0.0
                f.cage "Shawl" #(
                    #(true,true,#([1.22,0.0,4.15],[0.86267,0.494975,4.15],[0.0,0.7,4.15],[-0.86267,0.494975,4.15],[-1.22,0.0,4.15],[-0.86267,-0.494975,4.15],[0.0,-0.7,4.15],[0.86267,-0.494975,4.15])),
                    #(true,true,#([1.19,0.0,5.2],[0.841457,0.46669,5.2],[0.0,0.66,5.2],[-0.841457,0.46669,5.2],[-1.19,0.0,5.2],[-0.841457,-0.46669,5.2],[0.0,-0.66,5.2],[0.841457,-0.46669,5.2])),
                    #(true,true,#([0.78,0.0,5.85],[0.551543,0.353553,5.85],[0.0,0.5,5.85],[-0.551543,0.353553,5.85],[-0.78,0.0,5.85],[-0.551543,-0.353553,5.85],[0.0,-0.5,5.85],[0.551543,-0.353553,5.85])),
                    #(true,true,#([0.39,0.0,6.15],[0.275772,0.219203,6.15],[0.0,0.31,6.15],[-0.275772,0.219203,6.15],[-0.39,0.0,6.15],[-0.275772,-0.219203,6.15],[0.0,-0.31,6.15],[0.275772,-0.219203,6.15])),
                    #(false,true,#([0.0,0.0,4.15],[1.22,0.0,4.15],[1.19,0.0,5.2],[0.78,0.0,5.85],[0.39,0.0,6.15],[0.0,0.0,6.15])),
                    #(false,true,#([0.0,0.0,4.15],[0.86267,0.494975,4.15],[0.841457,0.46669,5.2],[0.551543,0.353553,5.85],[0.275772,0.219203,6.15],[0.0,0.0,6.15])),
                    #(false,true,#([0.0,0.0,4.15],[0.0,0.7,4.15],[0.0,0.66,5.2],[0.0,0.5,5.85],[0.0,0.31,6.15],[0.0,0.0,6.15])),
                    #(false,true,#([0.0,0.0,4.15],[-0.86267,0.494975,4.15],[-0.841457,0.46669,5.2],[-0.551543,0.353553,5.85],[-0.275772,0.219203,6.15],[0.0,0.0,6.15])),
                    #(false,true,#([0.0,0.0,4.15],[-1.22,0.0,4.15],[-1.19,0.0,5.2],[-0.78,0.0,5.85],[-0.39,0.0,6.15],[0.0,0.0,6.15])),
                    #(false,true,#([0.0,0.0,4.15],[-0.86267,-0.494975,4.15],[-0.841457,-0.46669,5.2],[-0.551543,-0.353553,5.85],[-0.275772,-0.219203,6.15],[0.0,0.0,6.15])),
                    #(false,true,#([0.0,0.0,4.15],[0.0,-0.7,4.15],[0.0,-0.66,5.2],[0.0,-0.5,5.85],[0.0,-0.31,6.15],[0.0,0.0,6.15])),
                    #(false,true,#([0.0,0.0,4.15],[0.86267,-0.494975,4.15],[0.841457,-0.46669,5.2],[0.551543,-0.353553,5.85],[0.275772,-0.219203,6.15],[0.0,0.0,6.15]))
                ) "dark" "body" true 0.0
                f.cage "LeftFoldedArm" #(
                    #(true,true,#([-1.089959,-0.075455,5.45],[-1.014156,0.065735,5.345449],[-0.836335,0.121556,5.302143],[-0.660661,0.059308,5.345449],[-0.590041,-0.084545,5.45],[-0.665844,-0.225735,5.554551],[-0.843665,-0.281556,5.597857],[-1.019339,-0.219308,5.554551])),
                    #(true,true,#([-1.05706,-0.697755,4.599325],[-0.995205,-0.538286,4.532357],[-0.848291,-0.432541,4.563592],[-0.702378,-0.442465,4.674733],[-0.64294,-0.562245,4.800675],[-0.704795,-0.721714,4.867643],[-0.851709,-0.827459,4.836408],[-0.997622,-0.817535,4.725267])),
                    #(true,true,#([-0.241536,-0.913205,4.256191],[-0.219331,-0.788565,4.226172],[-0.16237,-0.688198,4.286264],[-0.104021,-0.670896,4.401265],[-0.078464,-0.746795,4.503809],[-0.100669,-0.871435,4.533828],[-0.15763,-0.971802,4.473736],[-0.215979,-0.989104,4.358735])),
                    #(false,true,#([-0.84,-0.08,5.45],[-1.089959,-0.075455,5.45],[-1.05706,-0.697755,4.599325],[-0.241536,-0.913205,4.256191],[-0.16,-0.83,4.38])),
                    #(false,true,#([-0.84,-0.08,5.45],[-1.014156,0.065735,5.345449],[-0.995205,-0.538286,4.532357],[-0.219331,-0.788565,4.226172],[-0.16,-0.83,4.38])),
                    #(false,true,#([-0.84,-0.08,5.45],[-0.836335,0.121556,5.302143],[-0.848291,-0.432541,4.563592],[-0.16237,-0.688198,4.286264],[-0.16,-0.83,4.38])),
                    #(false,true,#([-0.84,-0.08,5.45],[-0.660661,0.059308,5.345449],[-0.702378,-0.442465,4.674733],[-0.104021,-0.670896,4.401265],[-0.16,-0.83,4.38])),
                    #(false,true,#([-0.84,-0.08,5.45],[-0.590041,-0.084545,5.45],[-0.64294,-0.562245,4.800675],[-0.078464,-0.746795,4.503809],[-0.16,-0.83,4.38])),
                    #(false,true,#([-0.84,-0.08,5.45],[-0.665844,-0.225735,5.554551],[-0.704795,-0.721714,4.867643],[-0.100669,-0.871435,4.533828],[-0.16,-0.83,4.38])),
                    #(false,true,#([-0.84,-0.08,5.45],[-0.843665,-0.281556,5.597857],[-0.851709,-0.827459,4.836408],[-0.15763,-0.971802,4.473736],[-0.16,-0.83,4.38])),
                    #(false,true,#([-0.84,-0.08,5.45],[-1.019339,-0.219308,5.554551],[-0.997622,-0.817535,4.725267],[-0.215979,-0.989104,4.358735],[-0.16,-0.83,4.38]))
                ) "dark" "body" true 0.0
                f.cage "LeftHand" #(
                    #(true,true,#([-0.281421,-0.736863,4.36],[-0.281421,-0.77,4.47],[-0.281421,-0.85,4.515563],[-0.281421,-0.93,4.47],[-0.281421,-0.963137,4.36],[-0.281421,-0.93,4.25],[-0.281421,-0.85,4.204437],[-0.281421,-0.77,4.25])),
                    #(true,true,#([-0.14,-0.69,4.36],[-0.14,-0.736863,4.515563],[-0.14,-0.85,4.58],[-0.14,-0.963137,4.515563],[-0.14,-1.01,4.36],[-0.14,-0.963137,4.204437],[-0.14,-0.85,4.14],[-0.14,-0.736863,4.204437])),
                    #(true,true,#([0.001421,-0.736863,4.36],[0.001421,-0.77,4.47],[0.001421,-0.85,4.515563],[0.001421,-0.93,4.47],[0.001421,-0.963137,4.36],[0.001421,-0.93,4.25],[0.001421,-0.85,4.204437],[0.001421,-0.77,4.25])),
                    #(false,true,#([-0.34,-0.85,4.36],[-0.281421,-0.736863,4.36],[-0.14,-0.69,4.36],[0.001421,-0.736863,4.36],[0.06,-0.85,4.36])),
                    #(false,true,#([-0.34,-0.85,4.36],[-0.281421,-0.77,4.47],[-0.14,-0.736863,4.515563],[0.001421,-0.77,4.47],[0.06,-0.85,4.36])),
                    #(false,true,#([-0.34,-0.85,4.36],[-0.281421,-0.85,4.515563],[-0.14,-0.85,4.58],[0.001421,-0.85,4.515563],[0.06,-0.85,4.36])),
                    #(false,true,#([-0.34,-0.85,4.36],[-0.281421,-0.93,4.47],[-0.14,-0.963137,4.515563],[0.001421,-0.93,4.47],[0.06,-0.85,4.36])),
                    #(false,true,#([-0.34,-0.85,4.36],[-0.281421,-0.963137,4.36],[-0.14,-1.01,4.36],[0.001421,-0.963137,4.36],[0.06,-0.85,4.36])),
                    #(false,true,#([-0.34,-0.85,4.36],[-0.281421,-0.93,4.25],[-0.14,-0.963137,4.204437],[0.001421,-0.93,4.25],[0.06,-0.85,4.36])),
                    #(false,true,#([-0.34,-0.85,4.36],[-0.281421,-0.85,4.204437],[-0.14,-0.85,4.14],[0.001421,-0.85,4.204437],[0.06,-0.85,4.36])),
                    #(false,true,#([-0.34,-0.85,4.36],[-0.281421,-0.77,4.25],[-0.14,-0.736863,4.204437],[0.001421,-0.77,4.25],[0.06,-0.85,4.36]))
                ) "dark" "body" true 0.0
                f.cage "RightFoldedArm" #(
                    #(true,true,#([0.590041,-0.084545,5.45],[0.660661,0.059308,5.345449],[0.836335,0.121556,5.302143],[1.014156,0.065735,5.345449],[1.089959,-0.075455,5.45],[1.019339,-0.219308,5.554551],[0.843665,-0.281556,5.597857],[0.665844,-0.225735,5.554551])),
                    #(true,true,#([0.64294,-0.562245,4.800675],[0.702378,-0.442465,4.674733],[0.848291,-0.432541,4.563592],[0.995205,-0.538286,4.532357],[1.05706,-0.697755,4.599325],[0.997622,-0.817535,4.725267],[0.851709,-0.827459,4.836408],[0.704795,-0.721714,4.867643])),
                    #(true,true,#([0.078464,-0.746795,4.503809],[0.104021,-0.670896,4.401265],[0.16237,-0.688198,4.286264],[0.219331,-0.788565,4.226172],[0.241536,-0.913205,4.256191],[0.215979,-0.989104,4.358735],[0.15763,-0.971802,4.473736],[0.100669,-0.871435,4.533828])),
                    #(false,true,#([0.84,-0.08,5.45],[0.590041,-0.084545,5.45],[0.64294,-0.562245,4.800675],[0.078464,-0.746795,4.503809],[0.16,-0.83,4.38])),
                    #(false,true,#([0.84,-0.08,5.45],[0.660661,0.059308,5.345449],[0.702378,-0.442465,4.674733],[0.104021,-0.670896,4.401265],[0.16,-0.83,4.38])),
                    #(false,true,#([0.84,-0.08,5.45],[0.836335,0.121556,5.302143],[0.848291,-0.432541,4.563592],[0.16237,-0.688198,4.286264],[0.16,-0.83,4.38])),
                    #(false,true,#([0.84,-0.08,5.45],[1.014156,0.065735,5.345449],[0.995205,-0.538286,4.532357],[0.219331,-0.788565,4.226172],[0.16,-0.83,4.38])),
                    #(false,true,#([0.84,-0.08,5.45],[1.089959,-0.075455,5.45],[1.05706,-0.697755,4.599325],[0.241536,-0.913205,4.256191],[0.16,-0.83,4.38])),
                    #(false,true,#([0.84,-0.08,5.45],[1.019339,-0.219308,5.554551],[0.997622,-0.817535,4.725267],[0.215979,-0.989104,4.358735],[0.16,-0.83,4.38])),
                    #(false,true,#([0.84,-0.08,5.45],[0.843665,-0.281556,5.597857],[0.851709,-0.827459,4.836408],[0.15763,-0.971802,4.473736],[0.16,-0.83,4.38])),
                    #(false,true,#([0.84,-0.08,5.45],[0.665844,-0.225735,5.554551],[0.704795,-0.721714,4.867643],[0.100669,-0.871435,4.533828],[0.16,-0.83,4.38]))
                ) "dark" "body" true 0.0
                f.cage "RightHand" #(
                    #(true,true,#([-0.001421,-0.736863,4.36],[-0.001421,-0.77,4.47],[-0.001421,-0.85,4.515563],[-0.001421,-0.93,4.47],[-0.001421,-0.963137,4.36],[-0.001421,-0.93,4.25],[-0.001421,-0.85,4.204437],[-0.001421,-0.77,4.25])),
                    #(true,true,#([0.14,-0.69,4.36],[0.14,-0.736863,4.515563],[0.14,-0.85,4.58],[0.14,-0.963137,4.515563],[0.14,-1.01,4.36],[0.14,-0.963137,4.204437],[0.14,-0.85,4.14],[0.14,-0.736863,4.204437])),
                    #(true,true,#([0.281421,-0.736863,4.36],[0.281421,-0.77,4.47],[0.281421,-0.85,4.515563],[0.281421,-0.93,4.47],[0.281421,-0.963137,4.36],[0.281421,-0.93,4.25],[0.281421,-0.85,4.204437],[0.281421,-0.77,4.25])),
                    #(false,true,#([-0.06,-0.85,4.36],[-0.001421,-0.736863,4.36],[0.14,-0.69,4.36],[0.281421,-0.736863,4.36],[0.34,-0.85,4.36])),
                    #(false,true,#([-0.06,-0.85,4.36],[-0.001421,-0.77,4.47],[0.14,-0.736863,4.515563],[0.281421,-0.77,4.47],[0.34,-0.85,4.36])),
                    #(false,true,#([-0.06,-0.85,4.36],[-0.001421,-0.85,4.515563],[0.14,-0.85,4.58],[0.281421,-0.85,4.515563],[0.34,-0.85,4.36])),
                    #(false,true,#([-0.06,-0.85,4.36],[-0.001421,-0.93,4.47],[0.14,-0.963137,4.515563],[0.281421,-0.93,4.47],[0.34,-0.85,4.36])),
                    #(false,true,#([-0.06,-0.85,4.36],[-0.001421,-0.963137,4.36],[0.14,-1.01,4.36],[0.281421,-0.963137,4.36],[0.34,-0.85,4.36])),
                    #(false,true,#([-0.06,-0.85,4.36],[-0.001421,-0.93,4.25],[0.14,-0.963137,4.204437],[0.281421,-0.93,4.25],[0.34,-0.85,4.36])),
                    #(false,true,#([-0.06,-0.85,4.36],[-0.001421,-0.85,4.204437],[0.14,-0.85,4.14],[0.281421,-0.85,4.204437],[0.34,-0.85,4.36])),
                    #(false,true,#([-0.06,-0.85,4.36],[-0.001421,-0.77,4.25],[0.14,-0.736863,4.204437],[0.281421,-0.77,4.25],[0.34,-0.85,4.36]))
                ) "dark" "body" true 0.0
                f.cage "Head" #(
                    #(true,true,#([-0.481844,0.305269,6.870747],[-0.514527,0.21,7.24432],[-0.528065,-0.02,7.399059],[-0.514527,-0.25,7.24432],[-0.481844,-0.345269,6.870747],[-0.44916,-0.25,6.497174],[-0.435623,-0.02,6.342435],[-0.44916,0.21,6.497174])),
                    #(true,true,#([-0.066238,0.44,6.907108],[-0.11246,0.305269,7.43542],[-0.131605,-0.02,7.654254],[-0.11246,-0.345269,7.43542],[-0.066238,-0.48,6.907108],[-0.020017,-0.345269,6.378796],[-0.000872,-0.02,6.159962],[-0.020017,0.305269,6.378796])),
                    #(true,true,#([0.349367,0.305269,6.943469],[0.316684,0.21,7.317042],[0.303146,-0.02,7.471781],[0.316684,-0.25,7.317042],[0.349367,-0.345269,6.943469],[0.38205,-0.25,6.569896],[0.395588,-0.02,6.415157],[0.38205,0.21,6.569896])),
                    #(false,true,#([-0.653993,-0.02,6.855686],[-0.481844,0.305269,6.870747],[-0.066238,0.44,6.907108],[0.349367,0.305269,6.943469],[0.521517,-0.02,6.95853])),
                    #(false,true,#([-0.653993,-0.02,6.855686],[-0.514527,0.21,7.24432],[-0.11246,0.305269,7.43542],[0.316684,0.21,7.317042],[0.521517,-0.02,6.95853])),
                    #(false,true,#([-0.653993,-0.02,6.855686],[-0.528065,-0.02,7.399059],[-0.131605,-0.02,7.654254],[0.303146,-0.02,7.471781],[0.521517,-0.02,6.95853])),
                    #(false,true,#([-0.653993,-0.02,6.855686],[-0.514527,-0.25,7.24432],[-0.11246,-0.345269,7.43542],[0.316684,-0.25,7.317042],[0.521517,-0.02,6.95853])),
                    #(false,true,#([-0.653993,-0.02,6.855686],[-0.481844,-0.345269,6.870747],[-0.066238,-0.48,6.907108],[0.349367,-0.345269,6.943469],[0.521517,-0.02,6.95853])),
                    #(false,true,#([-0.653993,-0.02,6.855686],[-0.44916,-0.25,6.497174],[-0.020017,-0.345269,6.378796],[0.38205,-0.25,6.569896],[0.521517,-0.02,6.95853])),
                    #(false,true,#([-0.653993,-0.02,6.855686],[-0.435623,-0.02,6.342435],[-0.000872,-0.02,6.159962],[0.395588,-0.02,6.415157],[0.521517,-0.02,6.95853])),
                    #(false,true,#([-0.653993,-0.02,6.855686],[-0.44916,0.21,6.497174],[-0.020017,0.305269,6.378796],[0.38205,0.21,6.569896],[0.521517,-0.02,6.95853]))
                ) "dark" "head" true 0.0
                f.cage "FacePlate" #(
                    #(true,true,#([-0.389434,-0.338076,6.828641],[-0.415145,-0.365,7.122518],[-0.425795,-0.43,7.244246],[-0.415145,-0.495,7.122518],[-0.389434,-0.521924,6.828641],[-0.363723,-0.495,6.534764],[-0.353074,-0.43,6.413036],[-0.363723,-0.365,6.534764])),
                    #(true,true,#([-0.061881,-0.3,6.857298],[-0.098241,-0.338076,7.272904],[-0.113302,-0.43,7.445053],[-0.098241,-0.521924,7.272904],[-0.061881,-0.56,6.857298],[-0.02552,-0.521924,6.441693],[-0.010459,-0.43,6.269543],[-0.02552,-0.338076,6.441693])),
                    #(true,true,#([0.265673,-0.338076,6.885955],[0.239962,-0.365,7.179833],[0.229312,-0.43,7.301561],[0.239962,-0.495,7.179833],[0.265673,-0.521924,6.885955],[0.291384,-0.495,6.592078],[0.302034,-0.43,6.47035],[0.291384,-0.365,6.592078])),
                    #(false,true,#([-0.525111,-0.43,6.816771],[-0.389434,-0.338076,6.828641],[-0.061881,-0.3,6.857298],[0.265673,-0.338076,6.885955],[0.40135,-0.43,6.897826])),
                    #(false,true,#([-0.525111,-0.43,6.816771],[-0.415145,-0.365,7.122518],[-0.098241,-0.338076,7.272904],[0.239962,-0.365,7.179833],[0.40135,-0.43,6.897826])),
                    #(false,true,#([-0.525111,-0.43,6.816771],[-0.425795,-0.43,7.244246],[-0.113302,-0.43,7.445053],[0.229312,-0.43,7.301561],[0.40135,-0.43,6.897826])),
                    #(false,true,#([-0.525111,-0.43,6.816771],[-0.415145,-0.495,7.122518],[-0.098241,-0.521924,7.272904],[0.239962,-0.495,7.179833],[0.40135,-0.43,6.897826])),
                    #(false,true,#([-0.525111,-0.43,6.816771],[-0.389434,-0.521924,6.828641],[-0.061881,-0.56,6.857298],[0.265673,-0.521924,6.885955],[0.40135,-0.43,6.897826])),
                    #(false,true,#([-0.525111,-0.43,6.816771],[-0.363723,-0.495,6.534764],[-0.02552,-0.521924,6.441693],[0.291384,-0.495,6.592078],[0.40135,-0.43,6.897826])),
                    #(false,true,#([-0.525111,-0.43,6.816771],[-0.353074,-0.43,6.413036],[-0.010459,-0.43,6.269543],[0.302034,-0.43,6.47035],[0.40135,-0.43,6.897826])),
                    #(false,true,#([-0.525111,-0.43,6.816771],[-0.363723,-0.365,6.534764],[-0.02552,-0.338076,6.441693],[0.291384,-0.365,6.592078],[0.40135,-0.43,6.897826]))
                ) "ivory_glow" "mask" true 0.0
                f.cage "EyeLeft" #(
                    #(true,true,#([-0.353571,-0.468707,6.938384],[-0.35897,-0.4924,7.000099],[-0.361206,-0.5496,7.025662],[-0.35897,-0.6068,7.000099],[-0.353571,-0.630493,6.938384],[-0.348171,-0.6068,6.87667],[-0.345935,-0.5496,6.851107],[-0.348171,-0.4924,6.87667])),
                    #(true,true,#([-0.274958,-0.4352,6.945262],[-0.282594,-0.468707,7.03254],[-0.285757,-0.5496,7.068691],[-0.282594,-0.630493,7.03254],[-0.274958,-0.664,6.945262],[-0.267322,-0.630493,6.857984],[-0.264159,-0.5496,6.821834],[-0.267322,-0.468707,6.857984])),
                    #(true,true,#([-0.196345,-0.468707,6.95214],[-0.201745,-0.4924,7.013854],[-0.203981,-0.5496,7.039417],[-0.201745,-0.6068,7.013854],[-0.196345,-0.630493,6.95214],[-0.190946,-0.6068,6.890426],[-0.188709,-0.5496,6.864862],[-0.190946,-0.4924,6.890426])),
                    #(false,true,#([-0.386133,-0.5496,6.935535],[-0.353571,-0.468707,6.938384],[-0.274958,-0.4352,6.945262],[-0.196345,-0.468707,6.95214],[-0.163783,-0.5496,6.954989])),
                    #(false,true,#([-0.386133,-0.5496,6.935535],[-0.35897,-0.4924,7.000099],[-0.282594,-0.468707,7.03254],[-0.201745,-0.4924,7.013854],[-0.163783,-0.5496,6.954989])),
                    #(false,true,#([-0.386133,-0.5496,6.935535],[-0.361206,-0.5496,7.025662],[-0.285757,-0.5496,7.068691],[-0.203981,-0.5496,7.039417],[-0.163783,-0.5496,6.954989])),
                    #(false,true,#([-0.386133,-0.5496,6.935535],[-0.35897,-0.6068,7.000099],[-0.282594,-0.630493,7.03254],[-0.201745,-0.6068,7.013854],[-0.163783,-0.5496,6.954989])),
                    #(false,true,#([-0.386133,-0.5496,6.935535],[-0.353571,-0.630493,6.938384],[-0.274958,-0.664,6.945262],[-0.196345,-0.630493,6.95214],[-0.163783,-0.5496,6.954989])),
                    #(false,true,#([-0.386133,-0.5496,6.935535],[-0.348171,-0.6068,6.87667],[-0.267322,-0.630493,6.857984],[-0.190946,-0.6068,6.890426],[-0.163783,-0.5496,6.954989])),
                    #(false,true,#([-0.386133,-0.5496,6.935535],[-0.345935,-0.5496,6.851107],[-0.264159,-0.5496,6.821834],[-0.188709,-0.5496,6.864862],[-0.163783,-0.5496,6.954989])),
                    #(false,true,#([-0.386133,-0.5496,6.935535],[-0.348171,-0.4924,6.87667],[-0.267322,-0.468707,6.857984],[-0.190946,-0.4924,6.890426],[-0.163783,-0.5496,6.954989]))
                ) "dark" "mask" true 0.0
                f.cage "EyeRight" #(
                    #(true,true,#([0.054072,-0.468707,6.974048],[0.048673,-0.4924,7.035763],[0.046436,-0.5496,7.061326],[0.048673,-0.6068,7.035763],[0.054072,-0.630493,6.974048],[0.059472,-0.6068,6.912334],[0.061708,-0.5496,6.886771],[0.059472,-0.4924,6.912334])),
                    #(true,true,#([0.132685,-0.4352,6.980926],[0.125049,-0.468707,7.068204],[0.121886,-0.5496,7.104355],[0.125049,-0.630493,7.068204],[0.132685,-0.664,6.980926],[0.140321,-0.630493,6.893649],[0.143484,-0.5496,6.857498],[0.140321,-0.468707,6.893649])),
                    #(true,true,#([0.211298,-0.468707,6.987804],[0.205898,-0.4924,7.049518],[0.203662,-0.5496,7.075082],[0.205898,-0.6068,7.049518],[0.211298,-0.630493,6.987804],[0.216697,-0.6068,6.92609],[0.218933,-0.5496,6.900526],[0.216697,-0.4924,6.92609])),
                    #(false,true,#([0.02151,-0.5496,6.9712],[0.054072,-0.468707,6.974048],[0.132685,-0.4352,6.980926],[0.211298,-0.468707,6.987804],[0.24386,-0.5496,6.990653])),
                    #(false,true,#([0.02151,-0.5496,6.9712],[0.048673,-0.4924,7.035763],[0.125049,-0.468707,7.068204],[0.205898,-0.4924,7.049518],[0.24386,-0.5496,6.990653])),
                    #(false,true,#([0.02151,-0.5496,6.9712],[0.046436,-0.5496,7.061326],[0.121886,-0.5496,7.104355],[0.203662,-0.5496,7.075082],[0.24386,-0.5496,6.990653])),
                    #(false,true,#([0.02151,-0.5496,6.9712],[0.048673,-0.6068,7.035763],[0.125049,-0.630493,7.068204],[0.205898,-0.6068,7.049518],[0.24386,-0.5496,6.990653])),
                    #(false,true,#([0.02151,-0.5496,6.9712],[0.054072,-0.630493,6.974048],[0.132685,-0.664,6.980926],[0.211298,-0.630493,6.987804],[0.24386,-0.5496,6.990653])),
                    #(false,true,#([0.02151,-0.5496,6.9712],[0.059472,-0.6068,6.912334],[0.140321,-0.630493,6.893649],[0.216697,-0.6068,6.92609],[0.24386,-0.5496,6.990653])),
                    #(false,true,#([0.02151,-0.5496,6.9712],[0.061708,-0.5496,6.886771],[0.143484,-0.5496,6.857498],[0.218933,-0.5496,6.900526],[0.24386,-0.5496,6.990653])),
                    #(false,true,#([0.02151,-0.5496,6.9712],[0.059472,-0.4924,6.912334],[0.140321,-0.468707,6.893649],[0.216697,-0.4924,6.92609],[0.24386,-0.5496,6.990653]))
                ) "dark" "mask" true 0.0
                f.cage "WideHatBrim" #(
                    #(true,true,#([-1.031658,0.663467,7.394822],[-1.038195,0.475,7.469537],[-1.040902,0.02,7.500484],[-1.038195,-0.435,7.469537],[-1.031658,-0.623467,7.394822],[-1.025121,-0.435,7.320107],[-1.022414,0.02,7.28916],[-1.025121,0.475,7.320107])),
                    #(true,true,#([-0.115917,0.93,7.474939],[-0.125161,0.663467,7.580601],[-0.12899,0.02,7.624368],[-0.125161,-0.623467,7.580601],[-0.115917,-0.89,7.474939],[-0.106673,-0.623467,7.369277],[-0.102844,0.02,7.32551],[-0.106673,0.663467,7.369277])),
                    #(true,true,#([0.799824,0.663467,7.555056],[0.793287,0.475,7.629771],[0.79058,0.02,7.660718],[0.793287,-0.435,7.629771],[0.799824,-0.623467,7.555056],[0.806361,-0.435,7.480341],[0.809068,0.02,7.449394],[0.806361,0.475,7.480341])),
                    #(false,true,#([-1.41097,0.02,7.361636],[-1.031658,0.663467,7.394822],[-0.115917,0.93,7.474939],[0.799824,0.663467,7.555056],[1.179136,0.02,7.588241])),
                    #(false,true,#([-1.41097,0.02,7.361636],[-1.038195,0.475,7.469537],[-0.125161,0.663467,7.580601],[0.793287,0.475,7.629771],[1.179136,0.02,7.588241])),
                    #(false,true,#([-1.41097,0.02,7.361636],[-1.040902,0.02,7.500484],[-0.12899,0.02,7.624368],[0.79058,0.02,7.660718],[1.179136,0.02,7.588241])),
                    #(false,true,#([-1.41097,0.02,7.361636],[-1.038195,-0.435,7.469537],[-0.125161,-0.623467,7.580601],[0.793287,-0.435,7.629771],[1.179136,0.02,7.588241])),
                    #(false,true,#([-1.41097,0.02,7.361636],[-1.031658,-0.623467,7.394822],[-0.115917,-0.89,7.474939],[0.799824,-0.623467,7.555056],[1.179136,0.02,7.588241])),
                    #(false,true,#([-1.41097,0.02,7.361636],[-1.025121,-0.435,7.320107],[-0.106673,-0.623467,7.369277],[0.806361,-0.435,7.480341],[1.179136,0.02,7.588241])),
                    #(false,true,#([-1.41097,0.02,7.361636],[-1.022414,0.02,7.28916],[-0.102844,0.02,7.32551],[0.809068,0.02,7.449394],[1.179136,0.02,7.588241])),
                    #(false,true,#([-1.41097,0.02,7.361636],[-1.025121,0.475,7.320107],[-0.106673,0.663467,7.369277],[0.806361,0.475,7.480341],[1.179136,0.02,7.588241]))
                ) "dark" "head" true 0.0
                f.cage "HatCrown" #(
                    #(true,true,#([-0.623753,0.488909,7.681464],[-0.641185,0.375,7.880703],[-0.648405,0.1,7.963231],[-0.641185,-0.175,7.880703],[-0.623753,-0.288909,7.681464],[-0.606322,-0.175,7.482225],[-0.599102,0.1,7.399697],[-0.606322,0.375,7.482225])),
                    #(true,true,#([-0.137706,0.65,7.723988],[-0.162357,0.488909,8.005754],[-0.172568,0.1,8.122466],[-0.162357,-0.288909,8.005754],[-0.137706,-0.45,7.723988],[-0.113055,-0.288909,7.442221],[-0.102844,0.1,7.32551],[-0.113055,0.488909,7.442221])),
                    #(true,true,#([0.348341,0.488909,7.766511],[0.33091,0.375,7.96575],[0.32369,0.1,8.048278],[0.33091,-0.175,7.96575],[0.348341,-0.288909,7.766511],[0.365772,-0.175,7.567272],[0.372993,0.1,7.484745],[0.365772,0.375,7.567272])),
                    #(false,true,#([-0.82508,0.1,7.66385],[-0.623753,0.488909,7.681464],[-0.137706,0.65,7.723988],[0.348341,0.488909,7.766511],[0.549668,0.1,7.784125])),
                    #(false,true,#([-0.82508,0.1,7.66385],[-0.641185,0.375,7.880703],[-0.162357,0.488909,8.005754],[0.33091,0.375,7.96575],[0.549668,0.1,7.784125])),
                    #(false,true,#([-0.82508,0.1,7.66385],[-0.648405,0.1,7.963231],[-0.172568,0.1,8.122466],[0.32369,0.1,8.048278],[0.549668,0.1,7.784125])),
                    #(false,true,#([-0.82508,0.1,7.66385],[-0.641185,-0.175,7.880703],[-0.162357,-0.288909,8.005754],[0.33091,-0.175,7.96575],[0.549668,0.1,7.784125])),
                    #(false,true,#([-0.82508,0.1,7.66385],[-0.623753,-0.288909,7.681464],[-0.137706,-0.45,7.723988],[0.348341,-0.288909,7.766511],[0.549668,0.1,7.784125])),
                    #(false,true,#([-0.82508,0.1,7.66385],[-0.606322,-0.175,7.482225],[-0.113055,-0.288909,7.442221],[0.365772,-0.175,7.567272],[0.549668,0.1,7.784125])),
                    #(false,true,#([-0.82508,0.1,7.66385],[-0.599102,0.1,7.399697],[-0.102844,0.1,7.32551],[0.372993,0.1,7.484745],[0.549668,0.1,7.784125])),
                    #(false,true,#([-0.82508,0.1,7.66385],[-0.606322,0.375,7.482225],[-0.113055,0.488909,7.442221],[0.365772,0.375,7.567272],[0.549668,0.1,7.784125]))
                ) "dark" "head" true 0.0
                f.cage "HatFlower" #(
                    #(true,true,#([0.172317,-0.241508,7.841455],[0.16273,-0.285,7.951036],[0.158759,-0.39,7.996426],[0.16273,-0.495,7.951036],[0.172317,-0.538492,7.841455],[0.181904,-0.495,7.731873],[0.185875,-0.39,7.686484],[0.181904,-0.285,7.731873])),
                    #(true,true,#([0.362509,-0.18,7.858095],[0.348951,-0.241508,8.013066],[0.343335,-0.39,8.077257],[0.348951,-0.538492,8.013066],[0.362509,-0.6,7.858095],[0.376067,-0.538492,7.703124],[0.381683,-0.39,7.638932],[0.376067,-0.241508,7.703124])),
                    #(true,true,#([0.552702,-0.241508,7.874734],[0.543115,-0.285,7.984316],[0.539143,-0.39,8.029705],[0.543115,-0.495,7.984316],[0.552702,-0.538492,7.874734],[0.562289,-0.495,7.765153],[0.56626,-0.39,7.719763],[0.562289,-0.285,7.765153])),
                    #(false,true,#([0.093537,-0.39,7.834563],[0.172317,-0.241508,7.841455],[0.362509,-0.18,7.858095],[0.552702,-0.241508,7.874734],[0.631482,-0.39,7.881627])),
                    #(false,true,#([0.093537,-0.39,7.834563],[0.16273,-0.285,7.951036],[0.348951,-0.241508,8.013066],[0.543115,-0.285,7.984316],[0.631482,-0.39,7.881627])),
                    #(false,true,#([0.093537,-0.39,7.834563],[0.158759,-0.39,7.996426],[0.343335,-0.39,8.077257],[0.539143,-0.39,8.029705],[0.631482,-0.39,7.881627])),
                    #(false,true,#([0.093537,-0.39,7.834563],[0.16273,-0.495,7.951036],[0.348951,-0.538492,8.013066],[0.543115,-0.495,7.984316],[0.631482,-0.39,7.881627])),
                    #(false,true,#([0.093537,-0.39,7.834563],[0.172317,-0.538492,7.841455],[0.362509,-0.6,7.858095],[0.552702,-0.538492,7.874734],[0.631482,-0.39,7.881627])),
                    #(false,true,#([0.093537,-0.39,7.834563],[0.181904,-0.495,7.731873],[0.376067,-0.538492,7.703124],[0.562289,-0.495,7.765153],[0.631482,-0.39,7.881627])),
                    #(false,true,#([0.093537,-0.39,7.834563],[0.185875,-0.39,7.686484],[0.381683,-0.39,7.638932],[0.56626,-0.39,7.719763],[0.631482,-0.39,7.881627])),
                    #(false,true,#([0.093537,-0.39,7.834563],[0.181904,-0.285,7.731873],[0.376067,-0.241508,7.703124],[0.562289,-0.285,7.765153],[0.631482,-0.39,7.881627]))
                ) "violet_glow" "head" true 0.0
                f.tube "ShawlEdge" #([-1.04,-0.38,4.3],[-0.56,-0.65,4.4],[0.0,-0.74,4.65],[0.95,-0.4,4.32]) 0.085 5 false true "violet_glow" "body"
                f.finishModel()
                f.startModel "paradedead3" "The robed elder" "dead" 3 0.23 [0.0,-0.22,6.05] "A stooped elder in an old wrap robe, wide sleeves and a tied hair knot." true
                f.cage "LeftSlipper" #(
                    #(true,true,#([-0.683345,0.254264,0.17],[-0.683345,0.13,0.255],[-0.683345,-0.17,0.290208],[-0.683345,-0.47,0.255],[-0.683345,-0.594264,0.17],[-0.683345,-0.47,0.085],[-0.683345,-0.17,0.049792],[-0.683345,0.13,0.085])),
                    #(true,true,#([-0.45,0.43,0.17],[-0.45,0.254264,0.290208],[-0.45,-0.17,0.34],[-0.45,-0.594264,0.290208],[-0.45,-0.77,0.17],[-0.45,-0.594264,0.049792],[-0.45,-0.17,0.0],[-0.45,0.254264,0.049792])),
                    #(true,true,#([-0.216655,0.254264,0.17],[-0.216655,0.13,0.255],[-0.216655,-0.17,0.290208],[-0.216655,-0.47,0.255],[-0.216655,-0.594264,0.17],[-0.216655,-0.47,0.085],[-0.216655,-0.17,0.049792],[-0.216655,0.13,0.085])),
                    #(false,true,#([-0.78,-0.17,0.17],[-0.683345,0.254264,0.17],[-0.45,0.43,0.17],[-0.216655,0.254264,0.17],[-0.12,-0.17,0.17])),
                    #(false,true,#([-0.78,-0.17,0.17],[-0.683345,0.13,0.255],[-0.45,0.254264,0.290208],[-0.216655,0.13,0.255],[-0.12,-0.17,0.17])),
                    #(false,true,#([-0.78,-0.17,0.17],[-0.683345,-0.17,0.290208],[-0.45,-0.17,0.34],[-0.216655,-0.17,0.290208],[-0.12,-0.17,0.17])),
                    #(false,true,#([-0.78,-0.17,0.17],[-0.683345,-0.47,0.255],[-0.45,-0.594264,0.290208],[-0.216655,-0.47,0.255],[-0.12,-0.17,0.17])),
                    #(false,true,#([-0.78,-0.17,0.17],[-0.683345,-0.594264,0.17],[-0.45,-0.77,0.17],[-0.216655,-0.594264,0.17],[-0.12,-0.17,0.17])),
                    #(false,true,#([-0.78,-0.17,0.17],[-0.683345,-0.47,0.085],[-0.45,-0.594264,0.049792],[-0.216655,-0.47,0.085],[-0.12,-0.17,0.17])),
                    #(false,true,#([-0.78,-0.17,0.17],[-0.683345,-0.17,0.049792],[-0.45,-0.17,0.0],[-0.216655,-0.17,0.049792],[-0.12,-0.17,0.17])),
                    #(false,true,#([-0.78,-0.17,0.17],[-0.683345,0.13,0.085],[-0.45,0.254264,0.049792],[-0.216655,0.13,0.085],[-0.12,-0.17,0.17]))
                ) "dark" "body" true 0.0
                f.cage "RightSlipper" #(
                    #(true,true,#([0.216655,0.254264,0.17],[0.216655,0.13,0.255],[0.216655,-0.17,0.290208],[0.216655,-0.47,0.255],[0.216655,-0.594264,0.17],[0.216655,-0.47,0.085],[0.216655,-0.17,0.049792],[0.216655,0.13,0.085])),
                    #(true,true,#([0.45,0.43,0.17],[0.45,0.254264,0.290208],[0.45,-0.17,0.34],[0.45,-0.594264,0.290208],[0.45,-0.77,0.17],[0.45,-0.594264,0.049792],[0.45,-0.17,0.0],[0.45,0.254264,0.049792])),
                    #(true,true,#([0.683345,0.254264,0.17],[0.683345,0.13,0.255],[0.683345,-0.17,0.290208],[0.683345,-0.47,0.255],[0.683345,-0.594264,0.17],[0.683345,-0.47,0.085],[0.683345,-0.17,0.049792],[0.683345,0.13,0.085])),
                    #(false,true,#([0.12,-0.17,0.17],[0.216655,0.254264,0.17],[0.45,0.43,0.17],[0.683345,0.254264,0.17],[0.78,-0.17,0.17])),
                    #(false,true,#([0.12,-0.17,0.17],[0.216655,0.13,0.255],[0.45,0.254264,0.290208],[0.683345,0.13,0.255],[0.78,-0.17,0.17])),
                    #(false,true,#([0.12,-0.17,0.17],[0.216655,-0.17,0.290208],[0.45,-0.17,0.34],[0.683345,-0.17,0.290208],[0.78,-0.17,0.17])),
                    #(false,true,#([0.12,-0.17,0.17],[0.216655,-0.47,0.255],[0.45,-0.594264,0.290208],[0.683345,-0.47,0.255],[0.78,-0.17,0.17])),
                    #(false,true,#([0.12,-0.17,0.17],[0.216655,-0.594264,0.17],[0.45,-0.77,0.17],[0.683345,-0.594264,0.17],[0.78,-0.17,0.17])),
                    #(false,true,#([0.12,-0.17,0.17],[0.216655,-0.47,0.085],[0.45,-0.594264,0.049792],[0.683345,-0.47,0.085],[0.78,-0.17,0.17])),
                    #(false,true,#([0.12,-0.17,0.17],[0.216655,-0.17,0.049792],[0.45,-0.17,0.0],[0.683345,-0.17,0.049792],[0.78,-0.17,0.17])),
                    #(false,true,#([0.12,-0.17,0.17],[0.216655,0.13,0.085],[0.45,0.254264,0.049792],[0.683345,0.13,0.085],[0.78,-0.17,0.17]))
                ) "dark" "body" true 0.0
                f.cage "LongWrappedRobe" #(
                    #(true,true,#([1.1,0.1,0.3],[0.777817,0.594975,0.3],[0.0,0.8,0.3],[-0.777817,0.594975,0.3],[-1.1,0.1,0.3],[-0.777817,-0.394975,0.3],[0.0,-0.6,0.3],[0.777817,-0.394975,0.3])),
                    #(true,true,#([1.04,0.08,2.1],[0.735391,0.560833,2.1],[0.0,0.76,2.1],[-0.735391,0.560833,2.1],[-1.04,0.08,2.1],[-0.735391,-0.400833,2.1],[0.0,-0.6,2.1],[0.735391,-0.400833,2.1])),
                    #(true,true,#([0.86,0.0,4.0],[0.608112,0.410122,4.0],[0.0,0.58,4.0],[-0.608112,0.410122,4.0],[-0.86,0.0,4.0],[-0.608112,-0.410122,4.0],[0.0,-0.58,4.0],[0.608112,-0.410122,4.0])),
                    #(true,true,#([1.12,-0.06,5.4],[0.79196,0.364264,5.4],[0.0,0.54,5.4],[-0.79196,0.364264,5.4],[-1.12,-0.06,5.4],[-0.79196,-0.484264,5.4],[0.0,-0.66,5.4],[0.79196,-0.484264,5.4])),
                    #(true,true,#([0.49,-0.14,5.85],[0.346482,0.128701,5.85],[0.0,0.24,5.85],[-0.346482,0.128701,5.85],[-0.49,-0.14,5.85],[-0.346482,-0.408701,5.85],[0.0,-0.52,5.85],[0.346482,-0.408701,5.85])),
                    #(false,true,#([0.0,0.1,0.3],[1.1,0.1,0.3],[1.04,0.08,2.1],[0.86,0.0,4.0],[1.12,-0.06,5.4],[0.49,-0.14,5.85],[0.0,-0.14,5.85])),
                    #(false,true,#([0.0,0.1,0.3],[0.777817,0.594975,0.3],[0.735391,0.560833,2.1],[0.608112,0.410122,4.0],[0.79196,0.364264,5.4],[0.346482,0.128701,5.85],[0.0,-0.14,5.85])),
                    #(false,true,#([0.0,0.1,0.3],[0.0,0.8,0.3],[0.0,0.76,2.1],[0.0,0.58,4.0],[0.0,0.54,5.4],[0.0,0.24,5.85],[0.0,-0.14,5.85])),
                    #(false,true,#([0.0,0.1,0.3],[-0.777817,0.594975,0.3],[-0.735391,0.560833,2.1],[-0.608112,0.410122,4.0],[-0.79196,0.364264,5.4],[-0.346482,0.128701,5.85],[0.0,-0.14,5.85])),
                    #(false,true,#([0.0,0.1,0.3],[-1.1,0.1,0.3],[-1.04,0.08,2.1],[-0.86,0.0,4.0],[-1.12,-0.06,5.4],[-0.49,-0.14,5.85],[0.0,-0.14,5.85])),
                    #(false,true,#([0.0,0.1,0.3],[-0.777817,-0.394975,0.3],[-0.735391,-0.400833,2.1],[-0.608112,-0.410122,4.0],[-0.79196,-0.484264,5.4],[-0.346482,-0.408701,5.85],[0.0,-0.14,5.85])),
                    #(false,true,#([0.0,0.1,0.3],[0.0,-0.6,0.3],[0.0,-0.6,2.1],[0.0,-0.58,4.0],[0.0,-0.66,5.4],[0.0,-0.52,5.85],[0.0,-0.14,5.85])),
                    #(false,true,#([0.0,0.1,0.3],[0.777817,-0.394975,0.3],[0.735391,-0.400833,2.1],[0.608112,-0.410122,4.0],[0.79196,-0.484264,5.4],[0.346482,-0.408701,5.85],[0.0,-0.14,5.85]))
                ) "dark" "body" true 0.0
                f.cage "RobeSash" #(
                    #(true,true,#([0.92,0.0,3.82],[0.650538,0.445477,3.82],[0.0,0.63,3.82],[-0.650538,0.445477,3.82],[-0.92,0.0,3.82],[-0.650538,-0.445477,3.82],[0.0,-0.63,3.82],[0.650538,-0.445477,3.82])),
                    #(true,true,#([0.93,0.0,4.16],[0.657609,0.452548,4.16],[0.0,0.64,4.16],[-0.657609,0.452548,4.16],[-0.93,0.0,4.16],[-0.657609,-0.452548,4.16],[0.0,-0.64,4.16],[0.657609,-0.452548,4.16])),
                    #(false,true,#([0.0,0.0,3.82],[0.92,0.0,3.82],[0.93,0.0,4.16],[0.0,0.0,4.16])),
                    #(false,true,#([0.0,0.0,3.82],[0.650538,0.445477,3.82],[0.657609,0.452548,4.16],[0.0,0.0,4.16])),
                    #(false,true,#([0.0,0.0,3.82],[0.0,0.63,3.82],[0.0,0.64,4.16],[0.0,0.0,4.16])),
                    #(false,true,#([0.0,0.0,3.82],[-0.650538,0.445477,3.82],[-0.657609,0.452548,4.16],[0.0,0.0,4.16])),
                    #(false,true,#([0.0,0.0,3.82],[-0.92,0.0,3.82],[-0.93,0.0,4.16],[0.0,0.0,4.16])),
                    #(false,true,#([0.0,0.0,3.82],[-0.650538,-0.445477,3.82],[-0.657609,-0.452548,4.16],[0.0,0.0,4.16])),
                    #(false,true,#([0.0,0.0,3.82],[0.0,-0.63,3.82],[0.0,-0.64,4.16],[0.0,0.0,4.16])),
                    #(false,true,#([0.0,0.0,3.82],[0.650538,-0.445477,3.82],[0.657609,-0.452548,4.16],[0.0,0.0,4.16]))
                ) "dark" "body" true 0.0
                f.cage "LeftWideSleeve" #(
                    #(true,true,#([-1.051303,0.48963,5.35],[-0.78604,0.394964,5.090923],[-0.616823,0.068933,4.98361],[-0.642777,-0.297478,5.090923],[-0.848697,-0.48963,5.35],[-1.11396,-0.394964,5.609077],[-1.283177,-0.068933,5.71639],[-1.257223,0.297478,5.609077])),
                    #(true,true,#([-1.760652,0.310768,4.547535],[-1.340059,0.32313,4.535314],[-1.030731,0.075912,4.678143],[-1.013868,-0.286068,4.892354],[-1.299348,-0.550768,5.052465],[-1.719941,-0.56313,5.064686],[-2.029269,-0.315912,4.921857],[-2.046132,0.046068,4.707646])),
                    #(true,true,#([-0.835026,-0.520915,3.937922],[-0.618512,-0.377738,4.100242],[-0.479022,-0.429196,4.367862],[-0.498267,-0.645145,4.584014],[-0.664974,-0.899085,4.622078],[-0.881488,-1.042262,4.459758],[-1.020978,-0.990804,4.192138],[-1.001733,-0.774855,3.975986])),
                    #(false,true,#([-0.95,0.0,5.35],[-1.051303,0.48963,5.35],[-1.760652,0.310768,4.547535],[-0.835026,-0.520915,3.937922],[-0.75,-0.71,4.28])),
                    #(false,true,#([-0.95,0.0,5.35],[-0.78604,0.394964,5.090923],[-1.340059,0.32313,4.535314],[-0.618512,-0.377738,4.100242],[-0.75,-0.71,4.28])),
                    #(false,true,#([-0.95,0.0,5.35],[-0.616823,0.068933,4.98361],[-1.030731,0.075912,4.678143],[-0.479022,-0.429196,4.367862],[-0.75,-0.71,4.28])),
                    #(false,true,#([-0.95,0.0,5.35],[-0.642777,-0.297478,5.090923],[-1.013868,-0.286068,4.892354],[-0.498267,-0.645145,4.584014],[-0.75,-0.71,4.28])),
                    #(false,true,#([-0.95,0.0,5.35],[-0.848697,-0.48963,5.35],[-1.299348,-0.550768,5.052465],[-0.664974,-0.899085,4.622078],[-0.75,-0.71,4.28])),
                    #(false,true,#([-0.95,0.0,5.35],[-1.11396,-0.394964,5.609077],[-1.719941,-0.56313,5.064686],[-0.881488,-1.042262,4.459758],[-0.75,-0.71,4.28])),
                    #(false,true,#([-0.95,0.0,5.35],[-1.283177,-0.068933,5.71639],[-2.029269,-0.315912,4.921857],[-1.020978,-0.990804,4.192138],[-0.75,-0.71,4.28])),
                    #(false,true,#([-0.95,0.0,5.35],[-1.257223,0.297478,5.609077],[-2.046132,0.046068,4.707646],[-1.001733,-0.774855,3.975986],[-0.75,-0.71,4.28]))
                ) "dark" "body" true 0.0
                f.cage "RightWideSleeve" #(
                    #(true,true,#([0.838154,-0.48733,5.35],[0.622682,-0.287623,5.104774],[0.598948,0.080569,5.003198],[0.780856,0.401565,5.104774],[1.061846,0.48733,5.35],[1.277318,0.287623,5.595226],[1.301052,-0.080569,5.696802],[1.119144,-0.401565,5.595226])),
                    #(true,true,#([1.329426,-0.55773,4.973565],[1.044618,-0.285468,4.82538],[1.061714,0.072006,4.60375],[1.370699,0.30529,4.438501],[1.790574,0.27773,4.426435],[2.075382,0.005468,4.57462],[2.058286,-0.352006,4.79625],[1.749301,-0.58529,4.961499])),
                    #(true,true,#([0.685171,-0.880264,4.6361],[0.523747,-0.622915,4.59816],[0.494858,-0.41658,4.373846],[0.615428,-0.382125,4.094558],[0.814829,-0.539736,3.9239],[0.976253,-0.797085,3.96184],[1.005142,-1.00342,4.186154],[0.884572,-1.037875,4.465442])),
                    #(false,true,#([0.95,0.0,5.35],[0.838154,-0.48733,5.35],[1.329426,-0.55773,4.973565],[0.685171,-0.880264,4.6361],[0.75,-0.71,4.28])),
                    #(false,true,#([0.95,0.0,5.35],[0.622682,-0.287623,5.104774],[1.044618,-0.285468,4.82538],[0.523747,-0.622915,4.59816],[0.75,-0.71,4.28])),
                    #(false,true,#([0.95,0.0,5.35],[0.598948,0.080569,5.003198],[1.061714,0.072006,4.60375],[0.494858,-0.41658,4.373846],[0.75,-0.71,4.28])),
                    #(false,true,#([0.95,0.0,5.35],[0.780856,0.401565,5.104774],[1.370699,0.30529,4.438501],[0.615428,-0.382125,4.094558],[0.75,-0.71,4.28])),
                    #(false,true,#([0.95,0.0,5.35],[1.061846,0.48733,5.35],[1.790574,0.27773,4.426435],[0.814829,-0.539736,3.9239],[0.75,-0.71,4.28])),
                    #(false,true,#([0.95,0.0,5.35],[1.277318,0.287623,5.595226],[2.075382,0.005468,4.57462],[0.976253,-0.797085,3.96184],[0.75,-0.71,4.28])),
                    #(false,true,#([0.95,0.0,5.35],[1.301052,-0.080569,5.696802],[2.058286,-0.352006,4.79625],[1.005142,-1.00342,4.186154],[0.75,-0.71,4.28])),
                    #(false,true,#([0.95,0.0,5.35],[1.119144,-0.401565,5.595226],[1.749301,-0.58529,4.961499],[0.884572,-1.037875,4.465442],[0.75,-0.71,4.28]))
                ) "dark" "body" true 0.0
                f.cage "JoinedHands" #(
                    #(true,true,#([-0.487904,-0.564437,4.27],[-0.487904,-0.61,4.405],[-0.487904,-0.72,4.460919],[-0.487904,-0.83,4.405],[-0.487904,-0.875563,4.27],[-0.487904,-0.83,4.135],[-0.487904,-0.72,4.079081],[-0.487904,-0.61,4.135])),
                    #(true,true,#([0.0,-0.5,4.27],[0.0,-0.564437,4.460919],[0.0,-0.72,4.54],[0.0,-0.875563,4.460919],[0.0,-0.94,4.27],[0.0,-0.875563,4.079081],[0.0,-0.72,4.0],[0.0,-0.564437,4.079081])),
                    #(true,true,#([0.487904,-0.564437,4.27],[0.487904,-0.61,4.405],[0.487904,-0.72,4.460919],[0.487904,-0.83,4.405],[0.487904,-0.875563,4.27],[0.487904,-0.83,4.135],[0.487904,-0.72,4.079081],[0.487904,-0.61,4.135])),
                    #(false,true,#([-0.69,-0.72,4.27],[-0.487904,-0.564437,4.27],[0.0,-0.5,4.27],[0.487904,-0.564437,4.27],[0.69,-0.72,4.27])),
                    #(false,true,#([-0.69,-0.72,4.27],[-0.487904,-0.61,4.405],[0.0,-0.564437,4.460919],[0.487904,-0.61,4.405],[0.69,-0.72,4.27])),
                    #(false,true,#([-0.69,-0.72,4.27],[-0.487904,-0.72,4.460919],[0.0,-0.72,4.54],[0.487904,-0.72,4.460919],[0.69,-0.72,4.27])),
                    #(false,true,#([-0.69,-0.72,4.27],[-0.487904,-0.83,4.405],[0.0,-0.875563,4.460919],[0.487904,-0.83,4.405],[0.69,-0.72,4.27])),
                    #(false,true,#([-0.69,-0.72,4.27],[-0.487904,-0.875563,4.27],[0.0,-0.94,4.27],[0.487904,-0.875563,4.27],[0.69,-0.72,4.27])),
                    #(false,true,#([-0.69,-0.72,4.27],[-0.487904,-0.83,4.135],[0.0,-0.875563,4.079081],[0.487904,-0.83,4.135],[0.69,-0.72,4.27])),
                    #(false,true,#([-0.69,-0.72,4.27],[-0.487904,-0.72,4.079081],[0.0,-0.72,4.0],[0.487904,-0.72,4.079081],[0.69,-0.72,4.27])),
                    #(false,true,#([-0.69,-0.72,4.27],[-0.487904,-0.61,4.135],[0.0,-0.564437,4.079081],[0.487904,-0.61,4.135],[0.69,-0.72,4.27]))
                ) "dark" "body" true 0.0
                f.cage "BentNeck" #(
                    #(true,true,#([-0.3,-0.14,5.68],[-0.212132,-0.347488,5.635854],[0.0,-0.433432,5.617568],[0.212132,-0.347488,5.635854],[0.3,-0.14,5.68],[0.212132,0.067488,5.724146],[0.0,0.153432,5.742432],[-0.212132,0.067488,5.724146])),
                    #(true,true,#([-0.3,-0.24,6.15],[-0.212132,-0.441886,6.084869],[0.0,-0.52551,6.05789],[0.212132,-0.441886,6.084869],[0.3,-0.24,6.15],[0.212132,-0.038114,6.215131],[0.0,0.04551,6.24211],[-0.212132,-0.038114,6.215131])),
                    #(true,true,#([-0.28,-0.35,6.4],[-0.19799,-0.531223,6.320262],[0.0,-0.606288,6.287233],[0.19799,-0.531223,6.320262],[0.28,-0.35,6.4],[0.19799,-0.168777,6.479738],[0.0,-0.093712,6.512767],[-0.19799,-0.168777,6.479738])),
                    #(false,true,#([0.0,-0.14,5.68],[-0.3,-0.14,5.68],[-0.3,-0.24,6.15],[-0.28,-0.35,6.4],[0.0,-0.35,6.4])),
                    #(false,true,#([0.0,-0.14,5.68],[-0.212132,-0.347488,5.635854],[-0.212132,-0.441886,6.084869],[-0.19799,-0.531223,6.320262],[0.0,-0.35,6.4])),
                    #(false,true,#([0.0,-0.14,5.68],[0.0,-0.433432,5.617568],[0.0,-0.52551,6.05789],[0.0,-0.606288,6.287233],[0.0,-0.35,6.4])),
                    #(false,true,#([0.0,-0.14,5.68],[0.212132,-0.347488,5.635854],[0.212132,-0.441886,6.084869],[0.19799,-0.531223,6.320262],[0.0,-0.35,6.4])),
                    #(false,true,#([0.0,-0.14,5.68],[0.3,-0.14,5.68],[0.3,-0.24,6.15],[0.28,-0.35,6.4],[0.0,-0.35,6.4])),
                    #(false,true,#([0.0,-0.14,5.68],[0.212132,0.067488,5.724146],[0.212132,-0.038114,6.215131],[0.19799,-0.168777,6.479738],[0.0,-0.35,6.4])),
                    #(false,true,#([0.0,-0.14,5.68],[0.0,0.153432,5.742432],[0.0,0.04551,6.24211],[0.0,-0.093712,6.512767],[0.0,-0.35,6.4])),
                    #(false,true,#([0.0,-0.14,5.68],[-0.212132,0.067488,5.724146],[-0.212132,-0.038114,6.215131],[-0.19799,-0.168777,6.479738],[0.0,-0.35,6.4]))
                ) "dark" "body" true 0.0
                f.cage "Head" #(
                    #(true,true,#([-0.480833,-0.003518,6.96],[-0.480833,-0.105,7.365],[-0.480833,-0.35,7.532756],[-0.480833,-0.595,7.365],[-0.480833,-0.696482,6.96],[-0.480833,-0.595,6.555],[-0.480833,-0.35,6.387244],[-0.480833,-0.105,6.555])),
                    #(true,true,#([0.0,0.14,6.96],[0.0,-0.003518,7.532756],[0.0,-0.35,7.77],[0.0,-0.696482,7.532756],[0.0,-0.84,6.96],[0.0,-0.696482,6.387244],[0.0,-0.35,6.15],[0.0,-0.003518,6.387244])),
                    #(true,true,#([0.480833,-0.003518,6.96],[0.480833,-0.105,7.365],[0.480833,-0.35,7.532756],[0.480833,-0.595,7.365],[0.480833,-0.696482,6.96],[0.480833,-0.595,6.555],[0.480833,-0.35,6.387244],[0.480833,-0.105,6.555])),
                    #(false,true,#([-0.68,-0.35,6.96],[-0.480833,-0.003518,6.96],[0.0,0.14,6.96],[0.480833,-0.003518,6.96],[0.68,-0.35,6.96])),
                    #(false,true,#([-0.68,-0.35,6.96],[-0.480833,-0.105,7.365],[0.0,-0.003518,7.532756],[0.480833,-0.105,7.365],[0.68,-0.35,6.96])),
                    #(false,true,#([-0.68,-0.35,6.96],[-0.480833,-0.35,7.532756],[0.0,-0.35,7.77],[0.480833,-0.35,7.532756],[0.68,-0.35,6.96])),
                    #(false,true,#([-0.68,-0.35,6.96],[-0.480833,-0.595,7.365],[0.0,-0.696482,7.532756],[0.480833,-0.595,7.365],[0.68,-0.35,6.96])),
                    #(false,true,#([-0.68,-0.35,6.96],[-0.480833,-0.696482,6.96],[0.0,-0.84,6.96],[0.480833,-0.696482,6.96],[0.68,-0.35,6.96])),
                    #(false,true,#([-0.68,-0.35,6.96],[-0.480833,-0.595,6.555],[0.0,-0.696482,6.387244],[0.480833,-0.595,6.555],[0.68,-0.35,6.96])),
                    #(false,true,#([-0.68,-0.35,6.96],[-0.480833,-0.35,6.387244],[0.0,-0.35,6.15],[0.480833,-0.35,6.387244],[0.68,-0.35,6.96])),
                    #(false,true,#([-0.68,-0.35,6.96],[-0.480833,-0.105,6.555],[0.0,-0.003518,6.387244],[0.480833,-0.105,6.555],[0.68,-0.35,6.96]))
                ) "dark" "head" true 0.0
                f.cage "FacePlate" #(
                    #(true,true,#([-0.36416,-0.662721,6.88],[-0.36416,-0.7,7.2025],[-0.36416,-0.79,7.336084],[-0.36416,-0.88,7.2025],[-0.36416,-0.917279,6.88],[-0.36416,-0.88,6.5575],[-0.36416,-0.79,6.423916],[-0.36416,-0.7,6.5575])),
                    #(true,true,#([0.0,-0.61,6.88],[0.0,-0.662721,7.336084],[0.0,-0.79,7.525],[0.0,-0.917279,7.336084],[0.0,-0.97,6.88],[0.0,-0.917279,6.423916],[0.0,-0.79,6.235],[0.0,-0.662721,6.423916])),
                    #(true,true,#([0.36416,-0.662721,6.88],[0.36416,-0.7,7.2025],[0.36416,-0.79,7.336084],[0.36416,-0.88,7.2025],[0.36416,-0.917279,6.88],[0.36416,-0.88,6.5575],[0.36416,-0.79,6.423916],[0.36416,-0.7,6.5575])),
                    #(false,true,#([-0.515,-0.79,6.88],[-0.36416,-0.662721,6.88],[0.0,-0.61,6.88],[0.36416,-0.662721,6.88],[0.515,-0.79,6.88])),
                    #(false,true,#([-0.515,-0.79,6.88],[-0.36416,-0.7,7.2025],[0.0,-0.662721,7.336084],[0.36416,-0.7,7.2025],[0.515,-0.79,6.88])),
                    #(false,true,#([-0.515,-0.79,6.88],[-0.36416,-0.79,7.336084],[0.0,-0.79,7.525],[0.36416,-0.79,7.336084],[0.515,-0.79,6.88])),
                    #(false,true,#([-0.515,-0.79,6.88],[-0.36416,-0.88,7.2025],[0.0,-0.917279,7.336084],[0.36416,-0.88,7.2025],[0.515,-0.79,6.88])),
                    #(false,true,#([-0.515,-0.79,6.88],[-0.36416,-0.917279,6.88],[0.0,-0.97,6.88],[0.36416,-0.917279,6.88],[0.515,-0.79,6.88])),
                    #(false,true,#([-0.515,-0.79,6.88],[-0.36416,-0.88,6.5575],[0.0,-0.917279,6.423916],[0.36416,-0.88,6.5575],[0.515,-0.79,6.88])),
                    #(false,true,#([-0.515,-0.79,6.88],[-0.36416,-0.79,6.423916],[0.0,-0.79,6.235],[0.36416,-0.79,6.423916],[0.515,-0.79,6.88])),
                    #(false,true,#([-0.515,-0.79,6.88],[-0.36416,-0.7,6.5575],[0.0,-0.662721,6.423916],[0.36416,-0.7,6.5575],[0.515,-0.79,6.88]))
                ) "ivory_glow" "mask" true 0.0
                f.cage "EyeLeft" #(
                    #(true,true,#([-0.313998,-0.843594,6.9961],[-0.313998,-0.8764,7.0561],[-0.313998,-0.9556,7.080953],[-0.313998,-1.0348,7.0561],[-0.313998,-1.067606,6.9961],[-0.313998,-1.0348,6.9361],[-0.313998,-0.9556,6.911247],[-0.313998,-0.8764,6.9361])),
                    #(true,true,#([-0.2266,-0.7972,6.9961],[-0.2266,-0.843594,7.080953],[-0.2266,-0.9556,7.1161],[-0.2266,-1.067606,7.080953],[-0.2266,-1.114,6.9961],[-0.2266,-1.067606,6.911247],[-0.2266,-0.9556,6.8761],[-0.2266,-0.843594,6.911247])),
                    #(true,true,#([-0.139202,-0.843594,6.9961],[-0.139202,-0.8764,7.0561],[-0.139202,-0.9556,7.080953],[-0.139202,-1.0348,7.0561],[-0.139202,-1.067606,6.9961],[-0.139202,-1.0348,6.9361],[-0.139202,-0.9556,6.911247],[-0.139202,-0.8764,6.9361])),
                    #(false,true,#([-0.3502,-0.9556,6.9961],[-0.313998,-0.843594,6.9961],[-0.2266,-0.7972,6.9961],[-0.139202,-0.843594,6.9961],[-0.103,-0.9556,6.9961])),
                    #(false,true,#([-0.3502,-0.9556,6.9961],[-0.313998,-0.8764,7.0561],[-0.2266,-0.843594,7.080953],[-0.139202,-0.8764,7.0561],[-0.103,-0.9556,6.9961])),
                    #(false,true,#([-0.3502,-0.9556,6.9961],[-0.313998,-0.9556,7.080953],[-0.2266,-0.9556,7.1161],[-0.139202,-0.9556,7.080953],[-0.103,-0.9556,6.9961])),
                    #(false,true,#([-0.3502,-0.9556,6.9961],[-0.313998,-1.0348,7.0561],[-0.2266,-1.067606,7.080953],[-0.139202,-1.0348,7.0561],[-0.103,-0.9556,6.9961])),
                    #(false,true,#([-0.3502,-0.9556,6.9961],[-0.313998,-1.067606,6.9961],[-0.2266,-1.114,6.9961],[-0.139202,-1.067606,6.9961],[-0.103,-0.9556,6.9961])),
                    #(false,true,#([-0.3502,-0.9556,6.9961],[-0.313998,-1.0348,6.9361],[-0.2266,-1.067606,6.911247],[-0.139202,-1.0348,6.9361],[-0.103,-0.9556,6.9961])),
                    #(false,true,#([-0.3502,-0.9556,6.9961],[-0.313998,-0.9556,6.911247],[-0.2266,-0.9556,6.8761],[-0.139202,-0.9556,6.911247],[-0.103,-0.9556,6.9961])),
                    #(false,true,#([-0.3502,-0.9556,6.9961],[-0.313998,-0.8764,6.9361],[-0.2266,-0.843594,6.911247],[-0.139202,-0.8764,6.9361],[-0.103,-0.9556,6.9961]))
                ) "dark" "mask" true 0.0
                f.cage "EyeRight" #(
                    #(true,true,#([0.139202,-0.843594,6.9961],[0.139202,-0.8764,7.0561],[0.139202,-0.9556,7.080953],[0.139202,-1.0348,7.0561],[0.139202,-1.067606,6.9961],[0.139202,-1.0348,6.9361],[0.139202,-0.9556,6.911247],[0.139202,-0.8764,6.9361])),
                    #(true,true,#([0.2266,-0.7972,6.9961],[0.2266,-0.843594,7.080953],[0.2266,-0.9556,7.1161],[0.2266,-1.067606,7.080953],[0.2266,-1.114,6.9961],[0.2266,-1.067606,6.911247],[0.2266,-0.9556,6.8761],[0.2266,-0.843594,6.911247])),
                    #(true,true,#([0.313998,-0.843594,6.9961],[0.313998,-0.8764,7.0561],[0.313998,-0.9556,7.080953],[0.313998,-1.0348,7.0561],[0.313998,-1.067606,6.9961],[0.313998,-1.0348,6.9361],[0.313998,-0.9556,6.911247],[0.313998,-0.8764,6.9361])),
                    #(false,true,#([0.103,-0.9556,6.9961],[0.139202,-0.843594,6.9961],[0.2266,-0.7972,6.9961],[0.313998,-0.843594,6.9961],[0.3502,-0.9556,6.9961])),
                    #(false,true,#([0.103,-0.9556,6.9961],[0.139202,-0.8764,7.0561],[0.2266,-0.843594,7.080953],[0.313998,-0.8764,7.0561],[0.3502,-0.9556,6.9961])),
                    #(false,true,#([0.103,-0.9556,6.9961],[0.139202,-0.9556,7.080953],[0.2266,-0.9556,7.1161],[0.313998,-0.9556,7.080953],[0.3502,-0.9556,6.9961])),
                    #(false,true,#([0.103,-0.9556,6.9961],[0.139202,-1.0348,7.0561],[0.2266,-1.067606,7.080953],[0.313998,-1.0348,7.0561],[0.3502,-0.9556,6.9961])),
                    #(false,true,#([0.103,-0.9556,6.9961],[0.139202,-1.067606,6.9961],[0.2266,-1.114,6.9961],[0.313998,-1.067606,6.9961],[0.3502,-0.9556,6.9961])),
                    #(false,true,#([0.103,-0.9556,6.9961],[0.139202,-1.0348,6.9361],[0.2266,-1.067606,6.911247],[0.313998,-1.0348,6.9361],[0.3502,-0.9556,6.9961])),
                    #(false,true,#([0.103,-0.9556,6.9961],[0.139202,-0.9556,6.911247],[0.2266,-0.9556,6.8761],[0.313998,-0.9556,6.911247],[0.3502,-0.9556,6.9961])),
                    #(false,true,#([0.103,-0.9556,6.9961],[0.139202,-0.8764,6.9361],[0.2266,-0.843594,6.911247],[0.313998,-0.8764,6.9361],[0.3502,-0.9556,6.9961]))
                ) "dark" "mask" true 0.0
                f.cage "RearHairKnot" #(
                    #(true,true,#([-0.289914,0.385772,7.23],[-0.289914,0.305,7.415],[-0.289914,0.11,7.49163],[-0.289914,-0.085,7.415],[-0.289914,-0.165772,7.23],[-0.289914,-0.085,7.045],[-0.289914,0.11,6.96837],[-0.289914,0.305,7.045])),
                    #(true,true,#([0.0,0.5,7.23],[0.0,0.385772,7.49163],[0.0,0.11,7.6],[0.0,-0.165772,7.49163],[0.0,-0.28,7.23],[0.0,-0.165772,6.96837],[0.0,0.11,6.86],[0.0,0.385772,6.96837])),
                    #(true,true,#([0.289914,0.385772,7.23],[0.289914,0.305,7.415],[0.289914,0.11,7.49163],[0.289914,-0.085,7.415],[0.289914,-0.165772,7.23],[0.289914,-0.085,7.045],[0.289914,0.11,6.96837],[0.289914,0.305,7.045])),
                    #(false,true,#([-0.41,0.11,7.23],[-0.289914,0.385772,7.23],[0.0,0.5,7.23],[0.289914,0.385772,7.23],[0.41,0.11,7.23])),
                    #(false,true,#([-0.41,0.11,7.23],[-0.289914,0.305,7.415],[0.0,0.385772,7.49163],[0.289914,0.305,7.415],[0.41,0.11,7.23])),
                    #(false,true,#([-0.41,0.11,7.23],[-0.289914,0.11,7.49163],[0.0,0.11,7.6],[0.289914,0.11,7.49163],[0.41,0.11,7.23])),
                    #(false,true,#([-0.41,0.11,7.23],[-0.289914,-0.085,7.415],[0.0,-0.165772,7.49163],[0.289914,-0.085,7.415],[0.41,0.11,7.23])),
                    #(false,true,#([-0.41,0.11,7.23],[-0.289914,-0.165772,7.23],[0.0,-0.28,7.23],[0.289914,-0.165772,7.23],[0.41,0.11,7.23])),
                    #(false,true,#([-0.41,0.11,7.23],[-0.289914,-0.085,7.045],[0.0,-0.165772,6.96837],[0.289914,-0.085,7.045],[0.41,0.11,7.23])),
                    #(false,true,#([-0.41,0.11,7.23],[-0.289914,0.11,6.96837],[0.0,0.11,6.86],[0.289914,0.11,6.96837],[0.41,0.11,7.23])),
                    #(false,true,#([-0.41,0.11,7.23],[-0.289914,0.305,7.045],[0.0,0.385772,6.96837],[0.289914,0.305,7.045],[0.41,0.11,7.23]))
                ) "dark" "head" true 0.0
                f.cage "OldSkullCap" #(
                    #(true,true,#([-0.459619,0.086482,7.51],[-0.459619,-0.015,7.66],[-0.459619,-0.26,7.722132],[-0.459619,-0.505,7.66],[-0.459619,-0.606482,7.51],[-0.459619,-0.505,7.36],[-0.459619,-0.26,7.297868],[-0.459619,-0.015,7.36])),
                    #(true,true,#([0.0,0.23,7.51],[0.0,0.086482,7.722132],[0.0,-0.26,7.81],[0.0,-0.606482,7.722132],[0.0,-0.75,7.51],[0.0,-0.606482,7.297868],[0.0,-0.26,7.21],[0.0,0.086482,7.297868])),
                    #(true,true,#([0.459619,0.086482,7.51],[0.459619,-0.015,7.66],[0.459619,-0.26,7.722132],[0.459619,-0.505,7.66],[0.459619,-0.606482,7.51],[0.459619,-0.505,7.36],[0.459619,-0.26,7.297868],[0.459619,-0.015,7.36])),
                    #(false,true,#([-0.65,-0.26,7.51],[-0.459619,0.086482,7.51],[0.0,0.23,7.51],[0.459619,0.086482,7.51],[0.65,-0.26,7.51])),
                    #(false,true,#([-0.65,-0.26,7.51],[-0.459619,-0.015,7.66],[0.0,0.086482,7.722132],[0.459619,-0.015,7.66],[0.65,-0.26,7.51])),
                    #(false,true,#([-0.65,-0.26,7.51],[-0.459619,-0.26,7.722132],[0.0,-0.26,7.81],[0.459619,-0.26,7.722132],[0.65,-0.26,7.51])),
                    #(false,true,#([-0.65,-0.26,7.51],[-0.459619,-0.505,7.66],[0.0,-0.606482,7.722132],[0.459619,-0.505,7.66],[0.65,-0.26,7.51])),
                    #(false,true,#([-0.65,-0.26,7.51],[-0.459619,-0.606482,7.51],[0.0,-0.75,7.51],[0.459619,-0.606482,7.51],[0.65,-0.26,7.51])),
                    #(false,true,#([-0.65,-0.26,7.51],[-0.459619,-0.505,7.36],[0.0,-0.606482,7.297868],[0.459619,-0.505,7.36],[0.65,-0.26,7.51])),
                    #(false,true,#([-0.65,-0.26,7.51],[-0.459619,-0.26,7.297868],[0.0,-0.26,7.21],[0.459619,-0.26,7.297868],[0.65,-0.26,7.51])),
                    #(false,true,#([-0.65,-0.26,7.51],[-0.459619,-0.015,7.36],[0.0,0.086482,7.297868],[0.459619,-0.015,7.36],[0.65,-0.26,7.51]))
                ) "dark" "head" true 0.0
                f.tube "RobeCrossing" #([-0.77,-0.47,5.48],[-0.28,-0.64,4.88],[0.74,-0.62,4.0]) 0.085 5 false true "violet_glow" "body"
                f.finishModel()
                f.startModel "paradedead4" "The travelling shade" "dead" 4 0.23 [0.0,0.0,6.17] "A tall period hat, short shoulder cape, crossed arms and trailing scarf." true
                f.cage "LeftBoot" #(
                    #(true,true,#([-0.760416,0.327193,0.25],[-0.760416,0.205,0.375],[-0.760416,-0.09,0.426777],[-0.760416,-0.385,0.375],[-0.760416,-0.507193,0.25],[-0.760416,-0.385,0.125],[-0.760416,-0.09,0.073223],[-0.760416,0.205,0.125])),
                    #(true,true,#([-0.52,0.5,0.25],[-0.52,0.327193,0.426777],[-0.52,-0.09,0.5],[-0.52,-0.507193,0.426777],[-0.52,-0.68,0.25],[-0.52,-0.507193,0.073223],[-0.52,-0.09,0.0],[-0.52,0.327193,0.073223])),
                    #(true,true,#([-0.279584,0.327193,0.25],[-0.279584,0.205,0.375],[-0.279584,-0.09,0.426777],[-0.279584,-0.385,0.375],[-0.279584,-0.507193,0.25],[-0.279584,-0.385,0.125],[-0.279584,-0.09,0.073223],[-0.279584,0.205,0.125])),
                    #(false,true,#([-0.86,-0.09,0.25],[-0.760416,0.327193,0.25],[-0.52,0.5,0.25],[-0.279584,0.327193,0.25],[-0.18,-0.09,0.25])),
                    #(false,true,#([-0.86,-0.09,0.25],[-0.760416,0.205,0.375],[-0.52,0.327193,0.426777],[-0.279584,0.205,0.375],[-0.18,-0.09,0.25])),
                    #(false,true,#([-0.86,-0.09,0.25],[-0.760416,-0.09,0.426777],[-0.52,-0.09,0.5],[-0.279584,-0.09,0.426777],[-0.18,-0.09,0.25])),
                    #(false,true,#([-0.86,-0.09,0.25],[-0.760416,-0.385,0.375],[-0.52,-0.507193,0.426777],[-0.279584,-0.385,0.375],[-0.18,-0.09,0.25])),
                    #(false,true,#([-0.86,-0.09,0.25],[-0.760416,-0.507193,0.25],[-0.52,-0.68,0.25],[-0.279584,-0.507193,0.25],[-0.18,-0.09,0.25])),
                    #(false,true,#([-0.86,-0.09,0.25],[-0.760416,-0.385,0.125],[-0.52,-0.507193,0.073223],[-0.279584,-0.385,0.125],[-0.18,-0.09,0.25])),
                    #(false,true,#([-0.86,-0.09,0.25],[-0.760416,-0.09,0.073223],[-0.52,-0.09,0.0],[-0.279584,-0.09,0.073223],[-0.18,-0.09,0.25])),
                    #(false,true,#([-0.86,-0.09,0.25],[-0.760416,0.205,0.125],[-0.52,0.327193,0.073223],[-0.279584,0.205,0.125],[-0.18,-0.09,0.25]))
                ) "dark" "body" true 0.0
                f.cage "RightBoot" #(
                    #(true,true,#([0.279584,0.447193,0.25],[0.279584,0.325,0.375],[0.279584,0.03,0.426777],[0.279584,-0.265,0.375],[0.279584,-0.387193,0.25],[0.279584,-0.265,0.125],[0.279584,0.03,0.073223],[0.279584,0.325,0.125])),
                    #(true,true,#([0.52,0.62,0.25],[0.52,0.447193,0.426777],[0.52,0.03,0.5],[0.52,-0.387193,0.426777],[0.52,-0.56,0.25],[0.52,-0.387193,0.073223],[0.52,0.03,0.0],[0.52,0.447193,0.073223])),
                    #(true,true,#([0.760416,0.447193,0.25],[0.760416,0.325,0.375],[0.760416,0.03,0.426777],[0.760416,-0.265,0.375],[0.760416,-0.387193,0.25],[0.760416,-0.265,0.125],[0.760416,0.03,0.073223],[0.760416,0.325,0.125])),
                    #(false,true,#([0.18,0.03,0.25],[0.279584,0.447193,0.25],[0.52,0.62,0.25],[0.760416,0.447193,0.25],[0.86,0.03,0.25])),
                    #(false,true,#([0.18,0.03,0.25],[0.279584,0.325,0.375],[0.52,0.447193,0.426777],[0.760416,0.325,0.375],[0.86,0.03,0.25])),
                    #(false,true,#([0.18,0.03,0.25],[0.279584,0.03,0.426777],[0.52,0.03,0.5],[0.760416,0.03,0.426777],[0.86,0.03,0.25])),
                    #(false,true,#([0.18,0.03,0.25],[0.279584,-0.265,0.375],[0.52,-0.387193,0.426777],[0.760416,-0.265,0.375],[0.86,0.03,0.25])),
                    #(false,true,#([0.18,0.03,0.25],[0.279584,-0.387193,0.25],[0.52,-0.56,0.25],[0.760416,-0.387193,0.25],[0.86,0.03,0.25])),
                    #(false,true,#([0.18,0.03,0.25],[0.279584,-0.265,0.125],[0.52,-0.387193,0.073223],[0.760416,-0.265,0.125],[0.86,0.03,0.25])),
                    #(false,true,#([0.18,0.03,0.25],[0.279584,0.03,0.073223],[0.52,0.03,0.0],[0.760416,0.03,0.073223],[0.86,0.03,0.25])),
                    #(false,true,#([0.18,0.03,0.25],[0.279584,0.325,0.125],[0.52,0.447193,0.073223],[0.760416,0.325,0.125],[0.86,0.03,0.25]))
                ) "dark" "body" true 0.0
                f.cage "LeftLeg" #(
                    #(true,true,#([-0.81,0.0,0.35],[-0.725061,-0.205061,0.35],[-0.52,-0.29,0.35],[-0.314939,-0.205061,0.35],[-0.23,0.0,0.35],[-0.314939,0.205061,0.35],[-0.52,0.29,0.35],[-0.725061,0.205061,0.35])),
                    #(true,true,#([-0.839523,0.000241,1.717466],[-0.745766,-0.226017,1.7186],[-0.519759,-0.319878,1.708839],[-0.293892,-0.226358,1.6939],[-0.200477,-0.000241,1.682534],[-0.294234,0.226017,1.6814],[-0.520241,0.319878,1.691161],[-0.746108,0.226358,1.7061])),
                    #(true,true,#([-0.690196,0.101116,3.540314],[-0.581682,-0.160441,3.542932],[-0.321284,-0.269435,3.520402],[-0.06154,-0.162019,3.48592],[0.045396,0.098884,3.459686],[-0.063118,0.360441,3.457068],[-0.323516,0.469435,3.479598],[-0.58326,0.362019,3.51408])),
                    #(false,true,#([-0.52,0.0,0.35],[-0.81,0.0,0.35],[-0.839523,0.000241,1.717466],[-0.690196,0.101116,3.540314],[-0.3224,0.1,3.5])),
                    #(false,true,#([-0.52,0.0,0.35],[-0.725061,-0.205061,0.35],[-0.745766,-0.226017,1.7186],[-0.581682,-0.160441,3.542932],[-0.3224,0.1,3.5])),
                    #(false,true,#([-0.52,0.0,0.35],[-0.52,-0.29,0.35],[-0.519759,-0.319878,1.708839],[-0.321284,-0.269435,3.520402],[-0.3224,0.1,3.5])),
                    #(false,true,#([-0.52,0.0,0.35],[-0.314939,-0.205061,0.35],[-0.293892,-0.226358,1.6939],[-0.06154,-0.162019,3.48592],[-0.3224,0.1,3.5])),
                    #(false,true,#([-0.52,0.0,0.35],[-0.23,0.0,0.35],[-0.200477,-0.000241,1.682534],[0.045396,0.098884,3.459686],[-0.3224,0.1,3.5])),
                    #(false,true,#([-0.52,0.0,0.35],[-0.314939,0.205061,0.35],[-0.294234,0.226017,1.6814],[-0.063118,0.360441,3.457068],[-0.3224,0.1,3.5])),
                    #(false,true,#([-0.52,0.0,0.35],[-0.52,0.29,0.35],[-0.520241,0.319878,1.691161],[-0.323516,0.469435,3.479598],[-0.3224,0.1,3.5])),
                    #(false,true,#([-0.52,0.0,0.35],[-0.725061,0.205061,0.35],[-0.746108,0.226358,1.7061],[-0.58326,0.362019,3.51408],[-0.3224,0.1,3.5]))
                ) "dark" "body" true 0.0
                f.cage "RightLeg" #(
                    #(true,true,#([0.23,0.0,0.35],[0.314939,-0.205061,0.35],[0.52,-0.29,0.35],[0.725061,-0.205061,0.35],[0.81,0.0,0.35],[0.725061,0.205061,0.35],[0.52,0.29,0.35],[0.314939,0.205061,0.35])),
                    #(true,true,#([0.200477,-0.000241,1.682534],[0.293892,-0.226358,1.6939],[0.519759,-0.319878,1.708839],[0.745766,-0.226017,1.7186],[0.839523,0.000241,1.717466],[0.746108,0.226358,1.7061],[0.520241,0.319878,1.691161],[0.294234,0.226017,1.6814])),
                    #(true,true,#([-0.045396,0.098884,3.459686],[0.06154,-0.162019,3.48592],[0.321284,-0.269435,3.520402],[0.581682,-0.160441,3.542932],[0.690196,0.101116,3.540314],[0.58326,0.362019,3.51408],[0.323516,0.469435,3.479598],[0.063118,0.360441,3.457068])),
                    #(false,true,#([0.52,0.0,0.35],[0.23,0.0,0.35],[0.200477,-0.000241,1.682534],[-0.045396,0.098884,3.459686],[0.3224,0.1,3.5])),
                    #(false,true,#([0.52,0.0,0.35],[0.314939,-0.205061,0.35],[0.293892,-0.226358,1.6939],[0.06154,-0.162019,3.48592],[0.3224,0.1,3.5])),
                    #(false,true,#([0.52,0.0,0.35],[0.52,-0.29,0.35],[0.519759,-0.319878,1.708839],[0.321284,-0.269435,3.520402],[0.3224,0.1,3.5])),
                    #(false,true,#([0.52,0.0,0.35],[0.725061,-0.205061,0.35],[0.745766,-0.226017,1.7186],[0.581682,-0.160441,3.542932],[0.3224,0.1,3.5])),
                    #(false,true,#([0.52,0.0,0.35],[0.81,0.0,0.35],[0.839523,0.000241,1.717466],[0.690196,0.101116,3.540314],[0.3224,0.1,3.5])),
                    #(false,true,#([0.52,0.0,0.35],[0.725061,0.205061,0.35],[0.746108,0.226358,1.7061],[0.58326,0.362019,3.51408],[0.3224,0.1,3.5])),
                    #(false,true,#([0.52,0.0,0.35],[0.52,0.29,0.35],[0.520241,0.319878,1.691161],[0.323516,0.469435,3.479598],[0.3224,0.1,3.5])),
                    #(false,true,#([0.52,0.0,0.35],[0.314939,0.205061,0.35],[0.294234,0.226017,1.6814],[0.063118,0.360441,3.457068],[0.3224,0.1,3.5]))
                ) "dark" "body" true 0.0
                f.cage "TravellingGreatcoat" #(
                    #(true,true,#([1.15,0.0,1.0],[0.813173,0.452548,1.0],[0.0,0.64,1.0],[-0.813173,0.452548,1.0],[-1.15,0.0,1.0],[-0.813173,-0.452548,1.0],[0.0,-0.64,1.0],[0.813173,-0.452548,1.0])),
                    #(true,true,#([0.96,0.0,3.5],[0.678823,0.438406,3.5],[0.0,0.62,3.5],[-0.678823,0.438406,3.5],[-0.96,0.0,3.5],[-0.678823,-0.438406,3.5],[0.0,-0.62,3.5],[0.678823,-0.438406,3.5])),
                    #(true,true,#([1.15,0.0,5.7],[0.813173,0.445477,5.7],[0.0,0.63,5.7],[-0.813173,0.445477,5.7],[-1.15,0.0,5.7],[-0.813173,-0.445477,5.7],[0.0,-0.63,5.7],[0.813173,-0.445477,5.7])),
                    #(true,true,#([0.59,0.0,6.1],[0.417193,0.289914,6.1],[0.0,0.41,6.1],[-0.417193,0.289914,6.1],[-0.59,0.0,6.1],[-0.417193,-0.289914,6.1],[0.0,-0.41,6.1],[0.417193,-0.289914,6.1])),
                    #(false,true,#([0.0,0.0,1.0],[1.15,0.0,1.0],[0.96,0.0,3.5],[1.15,0.0,5.7],[0.59,0.0,6.1],[0.0,0.0,6.1])),
                    #(false,true,#([0.0,0.0,1.0],[0.813173,0.452548,1.0],[0.678823,0.438406,3.5],[0.813173,0.445477,5.7],[0.417193,0.289914,6.1],[0.0,0.0,6.1])),
                    #(false,true,#([0.0,0.0,1.0],[0.0,0.64,1.0],[0.0,0.62,3.5],[0.0,0.63,5.7],[0.0,0.41,6.1],[0.0,0.0,6.1])),
                    #(false,true,#([0.0,0.0,1.0],[-0.813173,0.452548,1.0],[-0.678823,0.438406,3.5],[-0.813173,0.445477,5.7],[-0.417193,0.289914,6.1],[0.0,0.0,6.1])),
                    #(false,true,#([0.0,0.0,1.0],[-1.15,0.0,1.0],[-0.96,0.0,3.5],[-1.15,0.0,5.7],[-0.59,0.0,6.1],[0.0,0.0,6.1])),
                    #(false,true,#([0.0,0.0,1.0],[-0.813173,-0.452548,1.0],[-0.678823,-0.438406,3.5],[-0.813173,-0.445477,5.7],[-0.417193,-0.289914,6.1],[0.0,0.0,6.1])),
                    #(false,true,#([0.0,0.0,1.0],[0.0,-0.64,1.0],[0.0,-0.62,3.5],[0.0,-0.63,5.7],[0.0,-0.41,6.1],[0.0,0.0,6.1])),
                    #(false,true,#([0.0,0.0,1.0],[0.813173,-0.452548,1.0],[0.678823,-0.438406,3.5],[0.813173,-0.445477,5.7],[0.417193,-0.289914,6.1],[0.0,0.0,6.1]))
                ) "dark" "body" true 0.0
                f.cage "ShoulderCape" #(
                    #(true,true,#([1.49,0.0,4.7],[1.053589,0.551543,4.7],[0.0,0.78,4.7],[-1.053589,0.551543,4.7],[-1.49,0.0,4.7],[-1.053589,-0.551543,4.7],[0.0,-0.78,4.7],[1.053589,-0.551543,4.7])),
                    #(true,true,#([1.45,0.0,5.5],[1.025305,0.53033,5.5],[0.0,0.75,5.5],[-1.025305,0.53033,5.5],[-1.45,0.0,5.5],[-1.025305,-0.53033,5.5],[0.0,-0.75,5.5],[1.025305,-0.53033,5.5])),
                    #(true,true,#([0.68,0.0,6.13],[0.480833,0.339411,6.13],[0.0,0.48,6.13],[-0.480833,0.339411,6.13],[-0.68,0.0,6.13],[-0.480833,-0.339411,6.13],[0.0,-0.48,6.13],[0.480833,-0.339411,6.13])),
                    #(true,true,#([0.4,0.0,6.3],[0.282843,0.226274,6.3],[0.0,0.32,6.3],[-0.282843,0.226274,6.3],[-0.4,0.0,6.3],[-0.282843,-0.226274,6.3],[0.0,-0.32,6.3],[0.282843,-0.226274,6.3])),
                    #(false,true,#([0.0,0.0,4.7],[1.49,0.0,4.7],[1.45,0.0,5.5],[0.68,0.0,6.13],[0.4,0.0,6.3],[0.0,0.0,6.3])),
                    #(false,true,#([0.0,0.0,4.7],[1.053589,0.551543,4.7],[1.025305,0.53033,5.5],[0.480833,0.339411,6.13],[0.282843,0.226274,6.3],[0.0,0.0,6.3])),
                    #(false,true,#([0.0,0.0,4.7],[0.0,0.78,4.7],[0.0,0.75,5.5],[0.0,0.48,6.13],[0.0,0.32,6.3],[0.0,0.0,6.3])),
                    #(false,true,#([0.0,0.0,4.7],[-1.053589,0.551543,4.7],[-1.025305,0.53033,5.5],[-0.480833,0.339411,6.13],[-0.282843,0.226274,6.3],[0.0,0.0,6.3])),
                    #(false,true,#([0.0,0.0,4.7],[-1.49,0.0,4.7],[-1.45,0.0,5.5],[-0.68,0.0,6.13],[-0.4,0.0,6.3],[0.0,0.0,6.3])),
                    #(false,true,#([0.0,0.0,4.7],[-1.053589,-0.551543,4.7],[-1.025305,-0.53033,5.5],[-0.480833,-0.339411,6.13],[-0.282843,-0.226274,6.3],[0.0,0.0,6.3])),
                    #(false,true,#([0.0,0.0,4.7],[0.0,-0.78,4.7],[0.0,-0.75,5.5],[0.0,-0.48,6.13],[0.0,-0.32,6.3],[0.0,0.0,6.3])),
                    #(false,true,#([0.0,0.0,4.7],[1.053589,-0.551543,4.7],[1.025305,-0.53033,5.5],[0.480833,-0.339411,6.13],[0.282843,-0.226274,6.3],[0.0,0.0,6.3]))
                ) "dark" "body" true 0.0
                f.cage "LeftCrossedSleeve" #(
                    #(true,true,#([-1.367008,-0.03566,5.62],[-1.247347,0.127486,5.468816],[-1.006225,0.16909,5.406193],[-0.784888,0.06478,5.468816],[-0.712992,-0.12434,5.62],[-0.832653,-0.287486,5.771184],[-1.073775,-0.32909,5.833807],[-1.295112,-0.22478,5.771184])),
                    #(true,true,#([-1.353911,-0.755043,4.771159],[-1.268919,-0.564897,4.694442],[-1.096692,-0.436319,4.749853],[-0.938119,-0.444628,4.904934],[-0.886089,-0.584957,5.068841],[-0.971081,-0.775103,5.145558],[-1.143308,-0.903681,5.090147],[-1.301881,-0.895372,4.935066])),
                    #(true,true,#([0.394734,-1.018135,4.424738],[0.4129,-0.838988,4.388437],[0.4528,-0.689724,4.487782],[0.491059,-0.657778,4.664579],[0.505266,-0.761865,4.815262],[0.4871,-0.941012,4.851563],[0.4472,-1.090276,4.752218],[0.408941,-1.122222,4.575421])),
                    #(false,true,#([-1.04,-0.08,5.62],[-1.367008,-0.03566,5.62],[-1.353911,-0.755043,4.771159],[0.394734,-1.018135,4.424738],[0.45,-0.89,4.62])),
                    #(false,true,#([-1.04,-0.08,5.62],[-1.247347,0.127486,5.468816],[-1.268919,-0.564897,4.694442],[0.4129,-0.838988,4.388437],[0.45,-0.89,4.62])),
                    #(false,true,#([-1.04,-0.08,5.62],[-1.006225,0.16909,5.406193],[-1.096692,-0.436319,4.749853],[0.4528,-0.689724,4.487782],[0.45,-0.89,4.62])),
                    #(false,true,#([-1.04,-0.08,5.62],[-0.784888,0.06478,5.468816],[-0.938119,-0.444628,4.904934],[0.491059,-0.657778,4.664579],[0.45,-0.89,4.62])),
                    #(false,true,#([-1.04,-0.08,5.62],[-0.712992,-0.12434,5.62],[-0.886089,-0.584957,5.068841],[0.505266,-0.761865,4.815262],[0.45,-0.89,4.62])),
                    #(false,true,#([-1.04,-0.08,5.62],[-0.832653,-0.287486,5.771184],[-0.971081,-0.775103,5.145558],[0.4871,-0.941012,4.851563],[0.45,-0.89,4.62])),
                    #(false,true,#([-1.04,-0.08,5.62],[-1.073775,-0.32909,5.833807],[-1.143308,-0.903681,5.090147],[0.4472,-1.090276,4.752218],[0.45,-0.89,4.62])),
                    #(false,true,#([-1.04,-0.08,5.62],[-1.295112,-0.22478,5.771184],[-1.301881,-0.895372,4.935066],[0.408941,-1.122222,4.575421],[0.45,-0.89,4.62]))
                ) "dark" "body" true 0.0
                f.cage "RightCrossedSleeve" #(
                    #(true,true,#([0.711878,-0.115156,5.62],[0.78801,0.081552,5.481068],[1.011755,0.183625,5.42352],[1.252045,0.13127,5.481068],[1.368122,-0.044844,5.62],[1.29199,-0.241552,5.758932],[1.068245,-0.343625,5.81648],[0.827955,-0.29127,5.758932])),
                    #(true,true,#([0.861061,-0.565535,5.006502],[0.917711,-0.414534,4.85401],[1.081145,-0.395608,4.705026],[1.255623,-0.519843,4.646824],[1.338939,-0.714465,4.713498],[1.282289,-0.865466,4.86599],[1.118855,-0.884392,5.014974],[0.944377,-0.760157,5.073176])),
                    #(true,true,#([-0.513761,-0.776996,4.628468],[-0.492605,-0.662691,4.486242],[-0.440633,-0.68154,4.311071],[-0.388291,-0.822503,4.205567],[-0.366239,-1.003004,4.231532],[-0.387395,-1.117309,4.373758],[-0.439367,-1.09846,4.548929],[-0.491709,-0.957497,4.654433])),
                    #(false,true,#([1.04,-0.08,5.62],[0.711878,-0.115156,5.62],[0.861061,-0.565535,5.006502],[-0.513761,-0.776996,4.628468],[-0.44,-0.89,4.43])),
                    #(false,true,#([1.04,-0.08,5.62],[0.78801,0.081552,5.481068],[0.917711,-0.414534,4.85401],[-0.492605,-0.662691,4.486242],[-0.44,-0.89,4.43])),
                    #(false,true,#([1.04,-0.08,5.62],[1.011755,0.183625,5.42352],[1.081145,-0.395608,4.705026],[-0.440633,-0.68154,4.311071],[-0.44,-0.89,4.43])),
                    #(false,true,#([1.04,-0.08,5.62],[1.252045,0.13127,5.481068],[1.255623,-0.519843,4.646824],[-0.388291,-0.822503,4.205567],[-0.44,-0.89,4.43])),
                    #(false,true,#([1.04,-0.08,5.62],[1.368122,-0.044844,5.62],[1.338939,-0.714465,4.713498],[-0.366239,-1.003004,4.231532],[-0.44,-0.89,4.43])),
                    #(false,true,#([1.04,-0.08,5.62],[1.29199,-0.241552,5.758932],[1.282289,-0.865466,4.86599],[-0.387395,-1.117309,4.373758],[-0.44,-0.89,4.43])),
                    #(false,true,#([1.04,-0.08,5.62],[1.068245,-0.343625,5.81648],[1.118855,-0.884392,5.014974],[-0.439367,-1.09846,4.548929],[-0.44,-0.89,4.43])),
                    #(false,true,#([1.04,-0.08,5.62],[0.827955,-0.29127,5.758932],[0.944377,-0.760157,5.073176],[-0.491709,-0.957497,4.654433],[-0.44,-0.89,4.43]))
                ) "dark" "body" true 0.0
                f.cage "Head" #(
                    #(true,true,#([-0.403051,0.318198,6.96],[-0.403051,0.225,7.33],[-0.403051,0.0,7.483259],[-0.403051,-0.225,7.33],[-0.403051,-0.318198,6.96],[-0.403051,-0.225,6.59],[-0.403051,0.0,6.436741],[-0.403051,0.225,6.59])),
                    #(true,true,#([0.0,0.45,6.96],[0.0,0.318198,7.483259],[0.0,0.0,7.7],[0.0,-0.318198,7.483259],[0.0,-0.45,6.96],[0.0,-0.318198,6.436741],[0.0,0.0,6.22],[0.0,0.318198,6.436741])),
                    #(true,true,#([0.403051,0.318198,6.96],[0.403051,0.225,7.33],[0.403051,0.0,7.483259],[0.403051,-0.225,7.33],[0.403051,-0.318198,6.96],[0.403051,-0.225,6.59],[0.403051,0.0,6.436741],[0.403051,0.225,6.59])),
                    #(false,true,#([-0.57,0.0,6.96],[-0.403051,0.318198,6.96],[0.0,0.45,6.96],[0.403051,0.318198,6.96],[0.57,0.0,6.96])),
                    #(false,true,#([-0.57,0.0,6.96],[-0.403051,0.225,7.33],[0.0,0.318198,7.483259],[0.403051,0.225,7.33],[0.57,0.0,6.96])),
                    #(false,true,#([-0.57,0.0,6.96],[-0.403051,0.0,7.483259],[0.0,0.0,7.7],[0.403051,0.0,7.483259],[0.57,0.0,6.96])),
                    #(false,true,#([-0.57,0.0,6.96],[-0.403051,-0.225,7.33],[0.0,-0.318198,7.483259],[0.403051,-0.225,7.33],[0.57,0.0,6.96])),
                    #(false,true,#([-0.57,0.0,6.96],[-0.403051,-0.318198,6.96],[0.0,-0.45,6.96],[0.403051,-0.318198,6.96],[0.57,0.0,6.96])),
                    #(false,true,#([-0.57,0.0,6.96],[-0.403051,-0.225,6.59],[0.0,-0.318198,6.436741],[0.403051,-0.225,6.59],[0.57,0.0,6.96])),
                    #(false,true,#([-0.57,0.0,6.96],[-0.403051,0.0,6.436741],[0.0,0.0,6.22],[0.403051,0.0,6.436741],[0.57,0.0,6.96])),
                    #(false,true,#([-0.57,0.0,6.96],[-0.403051,0.225,6.59],[0.0,0.318198,6.436741],[0.403051,0.225,6.59],[0.57,0.0,6.96]))
                ) "dark" "head" true 0.0
                f.cage "FacePlate" #(
                    #(true,true,#([-0.314663,-0.308076,6.93],[-0.314663,-0.335,7.25],[-0.314663,-0.4,7.382548],[-0.314663,-0.465,7.25],[-0.314663,-0.491924,6.93],[-0.314663,-0.465,6.61],[-0.314663,-0.4,6.477452],[-0.314663,-0.335,6.61])),
                    #(true,true,#([0.0,-0.27,6.93],[0.0,-0.308076,7.382548],[0.0,-0.4,7.57],[0.0,-0.491924,7.382548],[0.0,-0.53,6.93],[0.0,-0.491924,6.477452],[0.0,-0.4,6.29],[0.0,-0.308076,6.477452])),
                    #(true,true,#([0.314663,-0.308076,6.93],[0.314663,-0.335,7.25],[0.314663,-0.4,7.382548],[0.314663,-0.465,7.25],[0.314663,-0.491924,6.93],[0.314663,-0.465,6.61],[0.314663,-0.4,6.477452],[0.314663,-0.335,6.61])),
                    #(false,true,#([-0.445,-0.4,6.93],[-0.314663,-0.308076,6.93],[0.0,-0.27,6.93],[0.314663,-0.308076,6.93],[0.445,-0.4,6.93])),
                    #(false,true,#([-0.445,-0.4,6.93],[-0.314663,-0.335,7.25],[0.0,-0.308076,7.382548],[0.314663,-0.335,7.25],[0.445,-0.4,6.93])),
                    #(false,true,#([-0.445,-0.4,6.93],[-0.314663,-0.4,7.382548],[0.0,-0.4,7.57],[0.314663,-0.4,7.382548],[0.445,-0.4,6.93])),
                    #(false,true,#([-0.445,-0.4,6.93],[-0.314663,-0.465,7.25],[0.0,-0.491924,7.382548],[0.314663,-0.465,7.25],[0.445,-0.4,6.93])),
                    #(false,true,#([-0.445,-0.4,6.93],[-0.314663,-0.491924,6.93],[0.0,-0.53,6.93],[0.314663,-0.491924,6.93],[0.445,-0.4,6.93])),
                    #(false,true,#([-0.445,-0.4,6.93],[-0.314663,-0.465,6.61],[0.0,-0.491924,6.477452],[0.314663,-0.465,6.61],[0.445,-0.4,6.93])),
                    #(false,true,#([-0.445,-0.4,6.93],[-0.314663,-0.4,6.477452],[0.0,-0.4,6.29],[0.314663,-0.4,6.477452],[0.445,-0.4,6.93])),
                    #(false,true,#([-0.445,-0.4,6.93],[-0.314663,-0.335,6.61],[0.0,-0.308076,6.477452],[0.314663,-0.335,6.61],[0.445,-0.4,6.93]))
                ) "ivory_glow" "mask" true 0.0
                f.cage "EyeLeft" #(
                    #(true,true,#([-0.271319,-0.438707,7.0452],[-0.271319,-0.4624,7.1124],[-0.271319,-0.5196,7.140235],[-0.271319,-0.5768,7.1124],[-0.271319,-0.600493,7.0452],[-0.271319,-0.5768,6.978],[-0.271319,-0.5196,6.950165],[-0.271319,-0.4624,6.978])),
                    #(true,true,#([-0.1958,-0.4052,7.0452],[-0.1958,-0.438707,7.140235],[-0.1958,-0.5196,7.1796],[-0.1958,-0.600493,7.140235],[-0.1958,-0.634,7.0452],[-0.1958,-0.600493,6.950165],[-0.1958,-0.5196,6.9108],[-0.1958,-0.438707,6.950165])),
                    #(true,true,#([-0.120281,-0.438707,7.0452],[-0.120281,-0.4624,7.1124],[-0.120281,-0.5196,7.140235],[-0.120281,-0.5768,7.1124],[-0.120281,-0.600493,7.0452],[-0.120281,-0.5768,6.978],[-0.120281,-0.5196,6.950165],[-0.120281,-0.4624,6.978])),
                    #(false,true,#([-0.3026,-0.5196,7.0452],[-0.271319,-0.438707,7.0452],[-0.1958,-0.4052,7.0452],[-0.120281,-0.438707,7.0452],[-0.089,-0.5196,7.0452])),
                    #(false,true,#([-0.3026,-0.5196,7.0452],[-0.271319,-0.4624,7.1124],[-0.1958,-0.438707,7.140235],[-0.120281,-0.4624,7.1124],[-0.089,-0.5196,7.0452])),
                    #(false,true,#([-0.3026,-0.5196,7.0452],[-0.271319,-0.5196,7.140235],[-0.1958,-0.5196,7.1796],[-0.120281,-0.5196,7.140235],[-0.089,-0.5196,7.0452])),
                    #(false,true,#([-0.3026,-0.5196,7.0452],[-0.271319,-0.5768,7.1124],[-0.1958,-0.600493,7.140235],[-0.120281,-0.5768,7.1124],[-0.089,-0.5196,7.0452])),
                    #(false,true,#([-0.3026,-0.5196,7.0452],[-0.271319,-0.600493,7.0452],[-0.1958,-0.634,7.0452],[-0.120281,-0.600493,7.0452],[-0.089,-0.5196,7.0452])),
                    #(false,true,#([-0.3026,-0.5196,7.0452],[-0.271319,-0.5768,6.978],[-0.1958,-0.600493,6.950165],[-0.120281,-0.5768,6.978],[-0.089,-0.5196,7.0452])),
                    #(false,true,#([-0.3026,-0.5196,7.0452],[-0.271319,-0.5196,6.950165],[-0.1958,-0.5196,6.9108],[-0.120281,-0.5196,6.950165],[-0.089,-0.5196,7.0452])),
                    #(false,true,#([-0.3026,-0.5196,7.0452],[-0.271319,-0.4624,6.978],[-0.1958,-0.438707,6.950165],[-0.120281,-0.4624,6.978],[-0.089,-0.5196,7.0452]))
                ) "dark" "mask" true 0.0
                f.cage "EyeRight" #(
                    #(true,true,#([0.120281,-0.438707,7.0452],[0.120281,-0.4624,7.1124],[0.120281,-0.5196,7.140235],[0.120281,-0.5768,7.1124],[0.120281,-0.600493,7.0452],[0.120281,-0.5768,6.978],[0.120281,-0.5196,6.950165],[0.120281,-0.4624,6.978])),
                    #(true,true,#([0.1958,-0.4052,7.0452],[0.1958,-0.438707,7.140235],[0.1958,-0.5196,7.1796],[0.1958,-0.600493,7.140235],[0.1958,-0.634,7.0452],[0.1958,-0.600493,6.950165],[0.1958,-0.5196,6.9108],[0.1958,-0.438707,6.950165])),
                    #(true,true,#([0.271319,-0.438707,7.0452],[0.271319,-0.4624,7.1124],[0.271319,-0.5196,7.140235],[0.271319,-0.5768,7.1124],[0.271319,-0.600493,7.0452],[0.271319,-0.5768,6.978],[0.271319,-0.5196,6.950165],[0.271319,-0.4624,6.978])),
                    #(false,true,#([0.089,-0.5196,7.0452],[0.120281,-0.438707,7.0452],[0.1958,-0.4052,7.0452],[0.271319,-0.438707,7.0452],[0.3026,-0.5196,7.0452])),
                    #(false,true,#([0.089,-0.5196,7.0452],[0.120281,-0.4624,7.1124],[0.1958,-0.438707,7.140235],[0.271319,-0.4624,7.1124],[0.3026,-0.5196,7.0452])),
                    #(false,true,#([0.089,-0.5196,7.0452],[0.120281,-0.5196,7.140235],[0.1958,-0.5196,7.1796],[0.271319,-0.5196,7.140235],[0.3026,-0.5196,7.0452])),
                    #(false,true,#([0.089,-0.5196,7.0452],[0.120281,-0.5768,7.1124],[0.1958,-0.600493,7.140235],[0.271319,-0.5768,7.1124],[0.3026,-0.5196,7.0452])),
                    #(false,true,#([0.089,-0.5196,7.0452],[0.120281,-0.600493,7.0452],[0.1958,-0.634,7.0452],[0.271319,-0.600493,7.0452],[0.3026,-0.5196,7.0452])),
                    #(false,true,#([0.089,-0.5196,7.0452],[0.120281,-0.5768,6.978],[0.1958,-0.600493,6.950165],[0.271319,-0.5768,6.978],[0.3026,-0.5196,7.0452])),
                    #(false,true,#([0.089,-0.5196,7.0452],[0.120281,-0.5196,6.950165],[0.1958,-0.5196,6.9108],[0.271319,-0.5196,6.950165],[0.3026,-0.5196,7.0452])),
                    #(false,true,#([0.089,-0.5196,7.0452],[0.120281,-0.4624,6.978],[0.1958,-0.438707,6.950165],[0.271319,-0.4624,6.978],[0.3026,-0.5196,7.0452]))
                ) "dark" "mask" true 0.0
                f.cage "QuietMouth" #(
                    #(true,false,#([-0.12015,-0.621,6.5756],[0.12015,-0.621,6.5756],[0.12015,-0.439,6.5756],[-0.12015,-0.439,6.5756])),
                    #(true,false,#([-0.12015,-0.621,6.6956],[0.12015,-0.621,6.6956],[0.12015,-0.439,6.6956],[-0.12015,-0.439,6.6956])),
                    #(false,false,#([-0.12015,-0.621,6.5756],[-0.12015,-0.621,6.6956])),
                    #(false,false,#([0.12015,-0.621,6.5756],[0.12015,-0.621,6.6956])),
                    #(false,false,#([0.12015,-0.439,6.5756],[0.12015,-0.439,6.6956])),
                    #(false,false,#([-0.12015,-0.439,6.5756],[-0.12015,-0.439,6.6956]))
                ) "dark" "mask" true 0.0
                f.cage "TallHatBrim" #(
                    #(true,true,#([-0.692965,0.494975,7.49],[-0.692965,0.35,7.56],[-0.692965,0.0,7.588995],[-0.692965,-0.35,7.56],[-0.692965,-0.494975,7.49],[-0.692965,-0.35,7.42],[-0.692965,0.0,7.391005],[-0.692965,0.35,7.42])),
                    #(true,true,#([0.0,0.7,7.49],[0.0,0.494975,7.588995],[0.0,0.0,7.63],[0.0,-0.494975,7.588995],[0.0,-0.7,7.49],[0.0,-0.494975,7.391005],[0.0,0.0,7.35],[0.0,0.494975,7.391005])),
                    #(true,true,#([0.692965,0.494975,7.49],[0.692965,0.35,7.56],[0.692965,0.0,7.588995],[0.692965,-0.35,7.56],[0.692965,-0.494975,7.49],[0.692965,-0.35,7.42],[0.692965,0.0,7.391005],[0.692965,0.35,7.42])),
                    #(false,true,#([-0.98,0.0,7.49],[-0.692965,0.494975,7.49],[0.0,0.7,7.49],[0.692965,0.494975,7.49],[0.98,0.0,7.49])),
                    #(false,true,#([-0.98,0.0,7.49],[-0.692965,0.35,7.56],[0.0,0.494975,7.588995],[0.692965,0.35,7.56],[0.98,0.0,7.49])),
                    #(false,true,#([-0.98,0.0,7.49],[-0.692965,0.0,7.588995],[0.0,0.0,7.63],[0.692965,0.0,7.588995],[0.98,0.0,7.49])),
                    #(false,true,#([-0.98,0.0,7.49],[-0.692965,-0.35,7.56],[0.0,-0.494975,7.588995],[0.692965,-0.35,7.56],[0.98,0.0,7.49])),
                    #(false,true,#([-0.98,0.0,7.49],[-0.692965,-0.494975,7.49],[0.0,-0.7,7.49],[0.692965,-0.494975,7.49],[0.98,0.0,7.49])),
                    #(false,true,#([-0.98,0.0,7.49],[-0.692965,-0.35,7.42],[0.0,-0.494975,7.391005],[0.692965,-0.35,7.42],[0.98,0.0,7.49])),
                    #(false,true,#([-0.98,0.0,7.49],[-0.692965,0.0,7.391005],[0.0,0.0,7.35],[0.692965,0.0,7.391005],[0.98,0.0,7.49])),
                    #(false,true,#([-0.98,0.0,7.49],[-0.692965,0.35,7.42],[0.0,0.494975,7.391005],[0.692965,0.35,7.42],[0.98,0.0,7.49]))
                ) "dark" "head" true 0.0
                f.cage "TallHatCrown" #(
                    #(true,false,#([0.6,0.0,7.49],[0.424264,0.318198,7.49],[0.0,0.45,7.49],[-0.424264,0.318198,7.49],[-0.6,0.0,7.49],[-0.424264,-0.318198,7.49],[0.0,-0.45,7.49],[0.424264,-0.318198,7.49])),
                    #(true,false,#([0.53,0.0,8.42],[0.374767,0.282843,8.42],[0.0,0.4,8.42],[-0.374767,0.282843,8.42],[-0.53,0.0,8.42],[-0.374767,-0.282843,8.42],[0.0,-0.4,8.42],[0.374767,-0.282843,8.42])),
                    #(true,false,#([0.63,0.0,8.52],[0.445477,0.325269,8.52],[0.0,0.46,8.52],[-0.445477,0.325269,8.52],[-0.63,0.0,8.52],[-0.445477,-0.325269,8.52],[0.0,-0.46,8.52],[0.445477,-0.325269,8.52])),
                    #(false,false,#([0.0,0.0,7.49],[0.6,0.0,7.49],[0.53,0.0,8.42],[0.63,0.0,8.52],[0.0,0.0,8.52])),
                    #(false,false,#([0.0,0.0,7.49],[0.424264,0.318198,7.49],[0.374767,0.282843,8.42],[0.445477,0.325269,8.52],[0.0,0.0,8.52])),
                    #(false,false,#([0.0,0.0,7.49],[0.0,0.45,7.49],[0.0,0.4,8.42],[0.0,0.46,8.52],[0.0,0.0,8.52])),
                    #(false,false,#([0.0,0.0,7.49],[-0.424264,0.318198,7.49],[-0.374767,0.282843,8.42],[-0.445477,0.325269,8.52],[0.0,0.0,8.52])),
                    #(false,false,#([0.0,0.0,7.49],[-0.6,0.0,7.49],[-0.53,0.0,8.42],[-0.63,0.0,8.52],[0.0,0.0,8.52])),
                    #(false,false,#([0.0,0.0,7.49],[-0.424264,-0.318198,7.49],[-0.374767,-0.282843,8.42],[-0.445477,-0.325269,8.52],[0.0,0.0,8.52])),
                    #(false,false,#([0.0,0.0,7.49],[0.0,-0.45,7.49],[0.0,-0.4,8.42],[0.0,-0.46,8.52],[0.0,0.0,8.52])),
                    #(false,false,#([0.0,0.0,7.49],[0.424264,-0.318198,7.49],[0.374767,-0.282843,8.42],[0.445477,-0.325269,8.52],[0.0,0.0,8.52]))
                ) "dark" "head" true 0.0
                f.cage "TrailingScarf" #(
                    #(false,true,#([0.324902,0.399384,5.719654],[0.327451,0.399692,5.724827],[0.33,0.4,5.73],[0.332549,0.400308,5.735173],[0.335098,0.400616,5.740346])),
                    #(false,true,#([0.712192,0.487947,5.573482],[0.759541,0.49367,5.669564],[0.806891,0.499394,5.765647],[0.85424,0.505117,5.86173],[0.90159,0.510841,5.957812])),
                    #(false,true,#([1.214335,0.572392,5.349413],[1.287167,0.581196,5.497207],[1.36,0.59,5.645],[1.432833,0.598804,5.792793],[1.505665,0.607608,5.940587])),
                    #(false,true,#([1.731392,0.611147,5.063882],[1.778741,0.61687,5.159964],[1.826091,0.622594,5.256047],[1.87344,0.628317,5.35213],[1.92079,0.634041,5.448212])),
                    #(false,true,#([2.144902,0.619384,4.809654],[2.147451,0.619692,4.814827],[2.15,0.62,4.82],[2.152549,0.620308,4.825173],[2.155098,0.620616,4.830346])),
                    #(false,true,#([0.324902,0.399384,5.719654],[0.712192,0.487947,5.573482],[1.214335,0.572392,5.349413],[1.731392,0.611147,5.063882],[2.144902,0.619384,4.809654])),
                    #(false,true,#([0.327451,0.399692,5.724827],[0.759541,0.49367,5.669564],[1.287167,0.581196,5.497207],[1.778741,0.61687,5.159964],[2.147451,0.619692,4.814827])),
                    #(false,true,#([0.33,0.4,5.73],[0.806891,0.499394,5.765647],[1.36,0.59,5.645],[1.826091,0.622594,5.256047],[2.15,0.62,4.82])),
                    #(false,true,#([0.332549,0.400308,5.735173],[0.85424,0.505117,5.86173],[1.432833,0.598804,5.792793],[1.87344,0.628317,5.35213],[2.152549,0.620308,4.825173])),
                    #(false,true,#([0.335098,0.400616,5.740346],[0.90159,0.510841,5.957812],[1.505665,0.607608,5.940587],[1.92079,0.634041,5.448212],[2.155098,0.620616,4.830346]))
                ) "dark" "body" false 0.18
                f.tube "CapeEdge" #([-1.3,-0.39,4.83],[0.0,-0.76,4.71],[1.3,-0.39,4.83]) 0.085 5 false true "violet_glow" "body"
                f.finishModel()
                f.startModel "paradeai1" "Null Lux" "ai" 1 0.3 [0.0,0.03,10.35] "Null Lux: a tall quiet open mantle, split pale mask and sheltered chest lantern." true
                f.cage "LeftMantle" #(
                    #(true,true,#([-0.56,0.17,0.0],[-0.653726,0.403345,0.0],[-0.88,0.5,0.0],[-1.106274,0.403345,0.0],[-1.2,0.17,0.0],[-1.106274,-0.063345,0.0],[-0.88,-0.16,0.0],[-0.653726,-0.063345,0.0])),
                    #(true,true,#([-0.53,0.08,1.5],[-0.702807,0.447696,1.5],[-1.12,0.6,1.5],[-1.537193,0.447696,1.5],[-1.71,0.08,1.5],[-1.537193,-0.287696,1.5],[-1.12,-0.44,1.5],[-0.702807,-0.287696,1.5])),
                    #(true,true,#([-0.64,0.0,5.8],[-0.80402,0.459619,5.8],[-1.2,0.65,5.8],[-1.59598,0.459619,5.8],[-1.76,0.0,5.8],[-1.59598,-0.459619,5.8],[-1.2,-0.65,5.8],[-0.80402,-0.459619,5.8])),
                    #(true,true,#([-0.26,0.0,8.5],[-0.450381,0.445477,8.5],[-0.91,0.63,8.5],[-1.369619,0.445477,8.5],[-1.56,0.0,8.5],[-1.369619,-0.445477,8.5],[-0.91,-0.63,8.5],[-0.450381,-0.445477,8.5])),
                    #(true,true,#([-0.08,0.04,10.3],[-0.182513,0.329914,10.3],[-0.43,0.45,10.3],[-0.677487,0.329914,10.3],[-0.78,0.04,10.3],[-0.677487,-0.249914,10.3],[-0.43,-0.37,10.3],[-0.182513,-0.249914,10.3])),
                    #(false,true,#([-0.88,0.17,0.0],[-0.56,0.17,0.0],[-0.53,0.08,1.5],[-0.64,0.0,5.8],[-0.26,0.0,8.5],[-0.08,0.04,10.3],[-0.43,0.04,10.3])),
                    #(false,true,#([-0.88,0.17,0.0],[-0.653726,0.403345,0.0],[-0.702807,0.447696,1.5],[-0.80402,0.459619,5.8],[-0.450381,0.445477,8.5],[-0.182513,0.329914,10.3],[-0.43,0.04,10.3])),
                    #(false,true,#([-0.88,0.17,0.0],[-0.88,0.5,0.0],[-1.12,0.6,1.5],[-1.2,0.65,5.8],[-0.91,0.63,8.5],[-0.43,0.45,10.3],[-0.43,0.04,10.3])),
                    #(false,true,#([-0.88,0.17,0.0],[-1.106274,0.403345,0.0],[-1.537193,0.447696,1.5],[-1.59598,0.459619,5.8],[-1.369619,0.445477,8.5],[-0.677487,0.329914,10.3],[-0.43,0.04,10.3])),
                    #(false,true,#([-0.88,0.17,0.0],[-1.2,0.17,0.0],[-1.71,0.08,1.5],[-1.76,0.0,5.8],[-1.56,0.0,8.5],[-0.78,0.04,10.3],[-0.43,0.04,10.3])),
                    #(false,true,#([-0.88,0.17,0.0],[-1.106274,-0.063345,0.0],[-1.537193,-0.287696,1.5],[-1.59598,-0.459619,5.8],[-1.369619,-0.445477,8.5],[-0.677487,-0.249914,10.3],[-0.43,0.04,10.3])),
                    #(false,true,#([-0.88,0.17,0.0],[-0.88,-0.16,0.0],[-1.12,-0.44,1.5],[-1.2,-0.65,5.8],[-0.91,-0.63,8.5],[-0.43,-0.37,10.3],[-0.43,0.04,10.3])),
                    #(false,true,#([-0.88,0.17,0.0],[-0.653726,-0.063345,0.0],[-0.702807,-0.287696,1.5],[-0.80402,-0.459619,5.8],[-0.450381,-0.445477,8.5],[-0.182513,-0.249914,10.3],[-0.43,0.04,10.3]))
                ) "dark" "body" true 0.0
                f.cage "RightMantle" #(
                    #(true,true,#([1.2,0.17,0.0],[1.106274,0.403345,0.0],[0.88,0.5,0.0],[0.653726,0.403345,0.0],[0.56,0.17,0.0],[0.653726,-0.063345,0.0],[0.88,-0.16,0.0],[1.106274,-0.063345,0.0])),
                    #(true,true,#([1.71,0.08,1.5],[1.537193,0.447696,1.5],[1.12,0.6,1.5],[0.702807,0.447696,1.5],[0.53,0.08,1.5],[0.702807,-0.287696,1.5],[1.12,-0.44,1.5],[1.537193,-0.287696,1.5])),
                    #(true,true,#([1.76,0.0,5.8],[1.59598,0.459619,5.8],[1.2,0.65,5.8],[0.80402,0.459619,5.8],[0.64,0.0,5.8],[0.80402,-0.459619,5.8],[1.2,-0.65,5.8],[1.59598,-0.459619,5.8])),
                    #(true,true,#([1.56,0.0,8.5],[1.369619,0.445477,8.5],[0.91,0.63,8.5],[0.450381,0.445477,8.5],[0.26,0.0,8.5],[0.450381,-0.445477,8.5],[0.91,-0.63,8.5],[1.369619,-0.445477,8.5])),
                    #(true,true,#([0.78,0.04,10.3],[0.677487,0.329914,10.3],[0.43,0.45,10.3],[0.182513,0.329914,10.3],[0.08,0.04,10.3],[0.182513,-0.249914,10.3],[0.43,-0.37,10.3],[0.677487,-0.249914,10.3])),
                    #(false,true,#([0.88,0.17,0.0],[1.2,0.17,0.0],[1.71,0.08,1.5],[1.76,0.0,5.8],[1.56,0.0,8.5],[0.78,0.04,10.3],[0.43,0.04,10.3])),
                    #(false,true,#([0.88,0.17,0.0],[1.106274,0.403345,0.0],[1.537193,0.447696,1.5],[1.59598,0.459619,5.8],[1.369619,0.445477,8.5],[0.677487,0.329914,10.3],[0.43,0.04,10.3])),
                    #(false,true,#([0.88,0.17,0.0],[0.88,0.5,0.0],[1.12,0.6,1.5],[1.2,0.65,5.8],[0.91,0.63,8.5],[0.43,0.45,10.3],[0.43,0.04,10.3])),
                    #(false,true,#([0.88,0.17,0.0],[0.653726,0.403345,0.0],[0.702807,0.447696,1.5],[0.80402,0.459619,5.8],[0.450381,0.445477,8.5],[0.182513,0.329914,10.3],[0.43,0.04,10.3])),
                    #(false,true,#([0.88,0.17,0.0],[0.56,0.17,0.0],[0.53,0.08,1.5],[0.64,0.0,5.8],[0.26,0.0,8.5],[0.08,0.04,10.3],[0.43,0.04,10.3])),
                    #(false,true,#([0.88,0.17,0.0],[0.653726,-0.063345,0.0],[0.702807,-0.287696,1.5],[0.80402,-0.459619,5.8],[0.450381,-0.445477,8.5],[0.182513,-0.249914,10.3],[0.43,0.04,10.3])),
                    #(false,true,#([0.88,0.17,0.0],[0.88,-0.16,0.0],[1.12,-0.44,1.5],[1.2,-0.65,5.8],[0.91,-0.63,8.5],[0.43,-0.37,10.3],[0.43,0.04,10.3])),
                    #(false,true,#([0.88,0.17,0.0],[1.106274,-0.063345,0.0],[1.537193,-0.287696,1.5],[1.59598,-0.459619,5.8],[1.369619,-0.445477,8.5],[0.677487,-0.249914,10.3],[0.43,0.04,10.3]))
                ) "dark" "body" true 0.0
                f.cage "MantleBack" #(
                    #(false,true,#([-1.02,0.58,1.0],[0.0,0.73,1.0],[1.02,0.58,1.0])),
                    #(false,true,#([-1.1,0.61,5.3],[0.0,0.81,5.3],[1.1,0.61,5.3])),
                    #(false,true,#([-0.4,0.31,10.2],[0.0,0.43,10.4],[0.4,0.31,10.2])),
                    #(false,true,#([-1.02,0.58,1.0],[-1.1,0.61,5.3],[-0.4,0.31,10.2])),
                    #(false,true,#([0.0,0.73,1.0],[0.0,0.81,5.3],[0.0,0.43,10.4])),
                    #(false,true,#([1.02,0.58,1.0],[1.1,0.61,5.3],[0.4,0.31,10.2]))
                ) "dark" "body" false 0.22
                f.cage "QuietShoulders" #(
                    #(true,true,#([-0.714178,0.426482,9.95],[-0.714178,0.325,10.24],[-0.714178,0.08,10.360122],[-0.714178,-0.165,10.24],[-0.714178,-0.266482,9.95],[-0.714178,-0.165,9.66],[-0.714178,0.08,9.539878],[-0.714178,0.325,9.66])),
                    #(true,true,#([0.0,0.57,9.95],[0.0,0.426482,10.360122],[0.0,0.08,10.53],[0.0,-0.266482,10.360122],[0.0,-0.41,9.95],[0.0,-0.266482,9.539878],[0.0,0.08,9.37],[0.0,0.426482,9.539878])),
                    #(true,true,#([0.714178,0.426482,9.95],[0.714178,0.325,10.24],[0.714178,0.08,10.360122],[0.714178,-0.165,10.24],[0.714178,-0.266482,9.95],[0.714178,-0.165,9.66],[0.714178,0.08,9.539878],[0.714178,0.325,9.66])),
                    #(false,true,#([-1.01,0.08,9.95],[-0.714178,0.426482,9.95],[0.0,0.57,9.95],[0.714178,0.426482,9.95],[1.01,0.08,9.95])),
                    #(false,true,#([-1.01,0.08,9.95],[-0.714178,0.325,10.24],[0.0,0.426482,10.360122],[0.714178,0.325,10.24],[1.01,0.08,9.95])),
                    #(false,true,#([-1.01,0.08,9.95],[-0.714178,0.08,10.360122],[0.0,0.08,10.53],[0.714178,0.08,10.360122],[1.01,0.08,9.95])),
                    #(false,true,#([-1.01,0.08,9.95],[-0.714178,-0.165,10.24],[0.0,-0.266482,10.360122],[0.714178,-0.165,10.24],[1.01,0.08,9.95])),
                    #(false,true,#([-1.01,0.08,9.95],[-0.714178,-0.266482,9.95],[0.0,-0.41,9.95],[0.714178,-0.266482,9.95],[1.01,0.08,9.95])),
                    #(false,true,#([-1.01,0.08,9.95],[-0.714178,-0.165,9.66],[0.0,-0.266482,9.539878],[0.714178,-0.165,9.66],[1.01,0.08,9.95])),
                    #(false,true,#([-1.01,0.08,9.95],[-0.714178,0.08,9.539878],[0.0,0.08,9.37],[0.714178,0.08,9.539878],[1.01,0.08,9.95])),
                    #(false,true,#([-1.01,0.08,9.95],[-0.714178,0.325,9.66],[0.0,0.426482,9.539878],[0.714178,0.325,9.66],[1.01,0.08,9.95]))
                ) "dark" "body" true 0.0
                f.cage "ThinNeck" #(
                    #(true,true,#([-0.24,0.03,10.05],[-0.169706,-0.139706,10.05],[0.0,-0.21,10.05],[0.169706,-0.139706,10.05],[0.24,0.03,10.05],[0.169706,0.199706,10.05],[0.0,0.27,10.05],[-0.169706,0.199706,10.05])),
                    #(true,true,#([-0.24,0.03,10.85],[-0.169706,-0.139706,10.85],[0.0,-0.21,10.85],[0.169706,-0.139706,10.85],[0.24,0.03,10.85],[0.169706,0.199706,10.85],[0.0,0.27,10.85],[-0.169706,0.199706,10.85])),
                    #(false,true,#([0.0,0.03,10.05],[-0.24,0.03,10.05],[-0.24,0.03,10.85],[0.0,0.03,10.85])),
                    #(false,true,#([0.0,0.03,10.05],[-0.169706,-0.139706,10.05],[-0.169706,-0.139706,10.85],[0.0,0.03,10.85])),
                    #(false,true,#([0.0,0.03,10.05],[0.0,-0.21,10.05],[0.0,-0.21,10.85],[0.0,0.03,10.85])),
                    #(false,true,#([0.0,0.03,10.05],[0.169706,-0.139706,10.05],[0.169706,-0.139706,10.85],[0.0,0.03,10.85])),
                    #(false,true,#([0.0,0.03,10.05],[0.24,0.03,10.05],[0.24,0.03,10.85],[0.0,0.03,10.85])),
                    #(false,true,#([0.0,0.03,10.05],[0.169706,0.199706,10.05],[0.169706,0.199706,10.85],[0.0,0.03,10.85])),
                    #(false,true,#([0.0,0.03,10.05],[0.0,0.27,10.05],[0.0,0.27,10.85],[0.0,0.03,10.85])),
                    #(false,true,#([0.0,0.03,10.05],[-0.169706,0.199706,10.05],[-0.169706,0.199706,10.85],[0.0,0.03,10.85]))
                ) "dark" "body" true 0.0
                f.cage "Head" #(
                    #(true,true,#([-0.565685,0.376482,11.87],[-0.565685,0.275,12.565],[-0.565685,0.03,12.852878],[-0.565685,-0.215,12.565],[-0.565685,-0.316482,11.87],[-0.565685,-0.215,11.175],[-0.565685,0.03,10.887122],[-0.565685,0.275,11.175])),
                    #(true,true,#([0.0,0.52,11.87],[0.0,0.376482,12.852878],[0.0,0.03,13.26],[0.0,-0.316482,12.852878],[0.0,-0.46,11.87],[0.0,-0.316482,10.887122],[0.0,0.03,10.48],[0.0,0.376482,10.887122])),
                    #(true,true,#([0.565685,0.376482,11.87],[0.565685,0.275,12.565],[0.565685,0.03,12.852878],[0.565685,-0.215,12.565],[0.565685,-0.316482,11.87],[0.565685,-0.215,11.175],[0.565685,0.03,10.887122],[0.565685,0.275,11.175])),
                    #(false,true,#([-0.8,0.03,11.87],[-0.565685,0.376482,11.87],[0.0,0.52,11.87],[0.565685,0.376482,11.87],[0.8,0.03,11.87])),
                    #(false,true,#([-0.8,0.03,11.87],[-0.565685,0.275,12.565],[0.0,0.376482,12.852878],[0.565685,0.275,12.565],[0.8,0.03,11.87])),
                    #(false,true,#([-0.8,0.03,11.87],[-0.565685,0.03,12.852878],[0.0,0.03,13.26],[0.565685,0.03,12.852878],[0.8,0.03,11.87])),
                    #(false,true,#([-0.8,0.03,11.87],[-0.565685,-0.215,12.565],[0.0,-0.316482,12.852878],[0.565685,-0.215,12.565],[0.8,0.03,11.87])),
                    #(false,true,#([-0.8,0.03,11.87],[-0.565685,-0.316482,11.87],[0.0,-0.46,11.87],[0.565685,-0.316482,11.87],[0.8,0.03,11.87])),
                    #(false,true,#([-0.8,0.03,11.87],[-0.565685,-0.215,11.175],[0.0,-0.316482,10.887122],[0.565685,-0.215,11.175],[0.8,0.03,11.87])),
                    #(false,true,#([-0.8,0.03,11.87],[-0.565685,0.03,10.887122],[0.0,0.03,10.48],[0.565685,0.03,10.887122],[0.8,0.03,11.87])),
                    #(false,true,#([-0.8,0.03,11.87],[-0.565685,0.275,11.175],[0.0,0.376482,10.887122],[0.565685,0.275,11.175],[0.8,0.03,11.87]))
                ) "dark" "head" true 0.0
                f.cage "MaskLeft" #(
                    #(true,true,#([-0.586655,-0.272721,11.86],[-0.586655,-0.31,12.4525],[-0.586655,-0.4,12.697922],[-0.586655,-0.49,12.4525],[-0.586655,-0.527279,11.86],[-0.586655,-0.49,11.2675],[-0.586655,-0.4,11.022078],[-0.586655,-0.31,11.2675])),
                    #(true,true,#([-0.426,-0.22,11.86],[-0.426,-0.272721,12.697922],[-0.426,-0.4,13.045],[-0.426,-0.527279,12.697922],[-0.426,-0.58,11.86],[-0.426,-0.527279,11.022078],[-0.426,-0.4,10.675],[-0.426,-0.272721,11.022078])),
                    #(true,true,#([-0.265345,-0.272721,11.86],[-0.265345,-0.31,12.4525],[-0.265345,-0.4,12.697922],[-0.265345,-0.49,12.4525],[-0.265345,-0.527279,11.86],[-0.265345,-0.49,11.2675],[-0.265345,-0.4,11.022078],[-0.265345,-0.31,11.2675])),
                    #(false,true,#([-0.6532,-0.4,11.86],[-0.586655,-0.272721,11.86],[-0.426,-0.22,11.86],[-0.265345,-0.272721,11.86],[-0.1988,-0.4,11.86])),
                    #(false,true,#([-0.6532,-0.4,11.86],[-0.586655,-0.31,12.4525],[-0.426,-0.272721,12.697922],[-0.265345,-0.31,12.4525],[-0.1988,-0.4,11.86])),
                    #(false,true,#([-0.6532,-0.4,11.86],[-0.586655,-0.4,12.697922],[-0.426,-0.4,13.045],[-0.265345,-0.4,12.697922],[-0.1988,-0.4,11.86])),
                    #(false,true,#([-0.6532,-0.4,11.86],[-0.586655,-0.49,12.4525],[-0.426,-0.527279,12.697922],[-0.265345,-0.49,12.4525],[-0.1988,-0.4,11.86])),
                    #(false,true,#([-0.6532,-0.4,11.86],[-0.586655,-0.527279,11.86],[-0.426,-0.58,11.86],[-0.265345,-0.527279,11.86],[-0.1988,-0.4,11.86])),
                    #(false,true,#([-0.6532,-0.4,11.86],[-0.586655,-0.49,11.2675],[-0.426,-0.527279,11.022078],[-0.265345,-0.49,11.2675],[-0.1988,-0.4,11.86])),
                    #(false,true,#([-0.6532,-0.4,11.86],[-0.586655,-0.4,11.022078],[-0.426,-0.4,10.675],[-0.265345,-0.4,11.022078],[-0.1988,-0.4,11.86])),
                    #(false,true,#([-0.6532,-0.4,11.86],[-0.586655,-0.31,11.2675],[-0.426,-0.272721,11.022078],[-0.265345,-0.31,11.2675],[-0.1988,-0.4,11.86]))
                ) "ivory_glow" "mask" true 0.0
                f.cage "MaskRight" #(
                    #(true,true,#([0.265345,-0.272721,11.86],[0.265345,-0.31,12.4525],[0.265345,-0.4,12.697922],[0.265345,-0.49,12.4525],[0.265345,-0.527279,11.86],[0.265345,-0.49,11.2675],[0.265345,-0.4,11.022078],[0.265345,-0.31,11.2675])),
                    #(true,true,#([0.426,-0.22,11.86],[0.426,-0.272721,12.697922],[0.426,-0.4,13.045],[0.426,-0.527279,12.697922],[0.426,-0.58,11.86],[0.426,-0.527279,11.022078],[0.426,-0.4,10.675],[0.426,-0.272721,11.022078])),
                    #(true,true,#([0.586655,-0.272721,11.86],[0.586655,-0.31,12.4525],[0.586655,-0.4,12.697922],[0.586655,-0.49,12.4525],[0.586655,-0.527279,11.86],[0.586655,-0.49,11.2675],[0.586655,-0.4,11.022078],[0.586655,-0.31,11.2675])),
                    #(false,true,#([0.1988,-0.4,11.86],[0.265345,-0.272721,11.86],[0.426,-0.22,11.86],[0.586655,-0.272721,11.86],[0.6532,-0.4,11.86])),
                    #(false,true,#([0.1988,-0.4,11.86],[0.265345,-0.31,12.4525],[0.426,-0.272721,12.697922],[0.586655,-0.31,12.4525],[0.6532,-0.4,11.86])),
                    #(false,true,#([0.1988,-0.4,11.86],[0.265345,-0.4,12.697922],[0.426,-0.4,13.045],[0.586655,-0.4,12.697922],[0.6532,-0.4,11.86])),
                    #(false,true,#([0.1988,-0.4,11.86],[0.265345,-0.49,12.4525],[0.426,-0.527279,12.697922],[0.586655,-0.49,12.4525],[0.6532,-0.4,11.86])),
                    #(false,true,#([0.1988,-0.4,11.86],[0.265345,-0.527279,11.86],[0.426,-0.58,11.86],[0.586655,-0.527279,11.86],[0.6532,-0.4,11.86])),
                    #(false,true,#([0.1988,-0.4,11.86],[0.265345,-0.49,11.2675],[0.426,-0.527279,11.022078],[0.586655,-0.49,11.2675],[0.6532,-0.4,11.86])),
                    #(false,true,#([0.1988,-0.4,11.86],[0.265345,-0.4,11.022078],[0.426,-0.4,10.675],[0.586655,-0.4,11.022078],[0.6532,-0.4,11.86])),
                    #(false,true,#([0.1988,-0.4,11.86],[0.265345,-0.31,11.2675],[0.426,-0.272721,11.022078],[0.586655,-0.31,11.2675],[0.6532,-0.4,11.86]))
                ) "ivory_glow" "mask" true 0.0
                f.cage "EyeLeft" #(
                    #(true,true,#([-0.503891,-0.453594,12.0733],[-0.503891,-0.4864,12.162175],[-0.503891,-0.5656,12.198988],[-0.503891,-0.6448,12.162175],[-0.503891,-0.677606,12.0733],[-0.503891,-0.6448,11.984425],[-0.503891,-0.5656,11.947612],[-0.503891,-0.4864,11.984425])),
                    #(true,true,#([-0.3834,-0.4072,12.0733],[-0.3834,-0.453594,12.198988],[-0.3834,-0.5656,12.25105],[-0.3834,-0.677606,12.198988],[-0.3834,-0.724,12.0733],[-0.3834,-0.677606,11.947612],[-0.3834,-0.5656,11.89555],[-0.3834,-0.453594,11.947612])),
                    #(true,true,#([-0.262909,-0.453594,12.0733],[-0.262909,-0.4864,12.162175],[-0.262909,-0.5656,12.198988],[-0.262909,-0.6448,12.162175],[-0.262909,-0.677606,12.0733],[-0.262909,-0.6448,11.984425],[-0.262909,-0.5656,11.947612],[-0.262909,-0.4864,11.984425])),
                    #(false,true,#([-0.5538,-0.5656,12.0733],[-0.503891,-0.453594,12.0733],[-0.3834,-0.4072,12.0733],[-0.262909,-0.453594,12.0733],[-0.213,-0.5656,12.0733])),
                    #(false,true,#([-0.5538,-0.5656,12.0733],[-0.503891,-0.4864,12.162175],[-0.3834,-0.453594,12.198988],[-0.262909,-0.4864,12.162175],[-0.213,-0.5656,12.0733])),
                    #(false,true,#([-0.5538,-0.5656,12.0733],[-0.503891,-0.5656,12.198988],[-0.3834,-0.5656,12.25105],[-0.262909,-0.5656,12.198988],[-0.213,-0.5656,12.0733])),
                    #(false,true,#([-0.5538,-0.5656,12.0733],[-0.503891,-0.6448,12.162175],[-0.3834,-0.677606,12.198988],[-0.262909,-0.6448,12.162175],[-0.213,-0.5656,12.0733])),
                    #(false,true,#([-0.5538,-0.5656,12.0733],[-0.503891,-0.677606,12.0733],[-0.3834,-0.724,12.0733],[-0.262909,-0.677606,12.0733],[-0.213,-0.5656,12.0733])),
                    #(false,true,#([-0.5538,-0.5656,12.0733],[-0.503891,-0.6448,11.984425],[-0.3834,-0.677606,11.947612],[-0.262909,-0.6448,11.984425],[-0.213,-0.5656,12.0733])),
                    #(false,true,#([-0.5538,-0.5656,12.0733],[-0.503891,-0.5656,11.947612],[-0.3834,-0.5656,11.89555],[-0.262909,-0.5656,11.947612],[-0.213,-0.5656,12.0733])),
                    #(false,true,#([-0.5538,-0.5656,12.0733],[-0.503891,-0.4864,11.984425],[-0.3834,-0.453594,11.947612],[-0.262909,-0.4864,11.984425],[-0.213,-0.5656,12.0733]))
                ) "dark" "mask" true 0.0
                f.cage "EyeRight" #(
                    #(true,true,#([0.262909,-0.453594,12.0733],[0.262909,-0.4864,12.162175],[0.262909,-0.5656,12.198988],[0.262909,-0.6448,12.162175],[0.262909,-0.677606,12.0733],[0.262909,-0.6448,11.984425],[0.262909,-0.5656,11.947612],[0.262909,-0.4864,11.984425])),
                    #(true,true,#([0.3834,-0.4072,12.0733],[0.3834,-0.453594,12.198988],[0.3834,-0.5656,12.25105],[0.3834,-0.677606,12.198988],[0.3834,-0.724,12.0733],[0.3834,-0.677606,11.947612],[0.3834,-0.5656,11.89555],[0.3834,-0.453594,11.947612])),
                    #(true,true,#([0.503891,-0.453594,12.0733],[0.503891,-0.4864,12.162175],[0.503891,-0.5656,12.198988],[0.503891,-0.6448,12.162175],[0.503891,-0.677606,12.0733],[0.503891,-0.6448,11.984425],[0.503891,-0.5656,11.947612],[0.503891,-0.4864,11.984425])),
                    #(false,true,#([0.213,-0.5656,12.0733],[0.262909,-0.453594,12.0733],[0.3834,-0.4072,12.0733],[0.503891,-0.453594,12.0733],[0.5538,-0.5656,12.0733])),
                    #(false,true,#([0.213,-0.5656,12.0733],[0.262909,-0.4864,12.162175],[0.3834,-0.453594,12.198988],[0.503891,-0.4864,12.162175],[0.5538,-0.5656,12.0733])),
                    #(false,true,#([0.213,-0.5656,12.0733],[0.262909,-0.5656,12.198988],[0.3834,-0.5656,12.25105],[0.503891,-0.5656,12.198988],[0.5538,-0.5656,12.0733])),
                    #(false,true,#([0.213,-0.5656,12.0733],[0.262909,-0.6448,12.162175],[0.3834,-0.677606,12.198988],[0.503891,-0.6448,12.162175],[0.5538,-0.5656,12.0733])),
                    #(false,true,#([0.213,-0.5656,12.0733],[0.262909,-0.677606,12.0733],[0.3834,-0.724,12.0733],[0.503891,-0.677606,12.0733],[0.5538,-0.5656,12.0733])),
                    #(false,true,#([0.213,-0.5656,12.0733],[0.262909,-0.6448,11.984425],[0.3834,-0.677606,11.947612],[0.503891,-0.6448,11.984425],[0.5538,-0.5656,12.0733])),
                    #(false,true,#([0.213,-0.5656,12.0733],[0.262909,-0.5656,11.947612],[0.3834,-0.5656,11.89555],[0.503891,-0.5656,11.947612],[0.5538,-0.5656,12.0733])),
                    #(false,true,#([0.213,-0.5656,12.0733],[0.262909,-0.4864,11.984425],[0.3834,-0.453594,11.947612],[0.503891,-0.4864,11.984425],[0.5538,-0.5656,12.0733]))
                ) "dark" "mask" true 0.0
                f.cage "ChestLantern" #(
                    #(true,true,#([0.31,0.0,5.05],[0.219203,0.219203,5.05],[0.0,0.31,5.05],[-0.219203,0.219203,5.05],[-0.31,0.0,5.05],[-0.219203,-0.219203,5.05],[0.0,-0.31,5.05],[0.219203,-0.219203,5.05])),
                    #(true,true,#([0.43,0.0,5.25],[0.304056,0.282843,5.25],[0.0,0.4,5.25],[-0.304056,0.282843,5.25],[-0.43,0.0,5.25],[-0.304056,-0.282843,5.25],[0.0,-0.4,5.25],[0.304056,-0.282843,5.25])),
                    #(true,true,#([0.43,0.0,6.0],[0.304056,0.282843,6.0],[0.0,0.4,6.0],[-0.304056,0.282843,6.0],[-0.43,0.0,6.0],[-0.304056,-0.282843,6.0],[0.0,-0.4,6.0],[0.304056,-0.282843,6.0])),
                    #(true,true,#([0.3,0.0,6.2],[0.212132,0.212132,6.2],[0.0,0.3,6.2],[-0.212132,0.212132,6.2],[-0.3,0.0,6.2],[-0.212132,-0.212132,6.2],[0.0,-0.3,6.2],[0.212132,-0.212132,6.2])),
                    #(false,true,#([0.0,0.0,5.05],[0.31,0.0,5.05],[0.43,0.0,5.25],[0.43,0.0,6.0],[0.3,0.0,6.2],[0.0,0.0,6.2])),
                    #(false,true,#([0.0,0.0,5.05],[0.219203,0.219203,5.05],[0.304056,0.282843,5.25],[0.304056,0.282843,6.0],[0.212132,0.212132,6.2],[0.0,0.0,6.2])),
                    #(false,true,#([0.0,0.0,5.05],[0.0,0.31,5.05],[0.0,0.4,5.25],[0.0,0.4,6.0],[0.0,0.3,6.2],[0.0,0.0,6.2])),
                    #(false,true,#([0.0,0.0,5.05],[-0.219203,0.219203,5.05],[-0.304056,0.282843,5.25],[-0.304056,0.282843,6.0],[-0.212132,0.212132,6.2],[0.0,0.0,6.2])),
                    #(false,true,#([0.0,0.0,5.05],[-0.31,0.0,5.05],[-0.43,0.0,5.25],[-0.43,0.0,6.0],[-0.3,0.0,6.2],[0.0,0.0,6.2])),
                    #(false,true,#([0.0,0.0,5.05],[-0.219203,-0.219203,5.05],[-0.304056,-0.282843,5.25],[-0.304056,-0.282843,6.0],[-0.212132,-0.212132,6.2],[0.0,0.0,6.2])),
                    #(false,true,#([0.0,0.0,5.05],[0.0,-0.31,5.05],[0.0,-0.4,5.25],[0.0,-0.4,6.0],[0.0,-0.3,6.2],[0.0,0.0,6.2])),
                    #(false,true,#([0.0,0.0,5.05],[0.219203,-0.219203,5.05],[0.304056,-0.282843,5.25],[0.304056,-0.282843,6.0],[0.212132,-0.212132,6.2],[0.0,0.0,6.2]))
                ) "gold_glow" "body" true 0.0
                f.cage "LanternCap" #(
                    #(true,true,#([-0.339411,0.311127,6.23],[-0.339411,0.22,6.295],[-0.339411,0.0,6.321924],[-0.339411,-0.22,6.295],[-0.339411,-0.311127,6.23],[-0.339411,-0.22,6.165],[-0.339411,0.0,6.138076],[-0.339411,0.22,6.165])),
                    #(true,true,#([0.0,0.44,6.23],[0.0,0.311127,6.321924],[0.0,0.0,6.36],[0.0,-0.311127,6.321924],[0.0,-0.44,6.23],[0.0,-0.311127,6.138076],[0.0,0.0,6.1],[0.0,0.311127,6.138076])),
                    #(true,true,#([0.339411,0.311127,6.23],[0.339411,0.22,6.295],[0.339411,0.0,6.321924],[0.339411,-0.22,6.295],[0.339411,-0.311127,6.23],[0.339411,-0.22,6.165],[0.339411,0.0,6.138076],[0.339411,0.22,6.165])),
                    #(false,true,#([-0.48,0.0,6.23],[-0.339411,0.311127,6.23],[0.0,0.44,6.23],[0.339411,0.311127,6.23],[0.48,0.0,6.23])),
                    #(false,true,#([-0.48,0.0,6.23],[-0.339411,0.22,6.295],[0.0,0.311127,6.321924],[0.339411,0.22,6.295],[0.48,0.0,6.23])),
                    #(false,true,#([-0.48,0.0,6.23],[-0.339411,0.0,6.321924],[0.0,0.0,6.36],[0.339411,0.0,6.321924],[0.48,0.0,6.23])),
                    #(false,true,#([-0.48,0.0,6.23],[-0.339411,-0.22,6.295],[0.0,-0.311127,6.321924],[0.339411,-0.22,6.295],[0.48,0.0,6.23])),
                    #(false,true,#([-0.48,0.0,6.23],[-0.339411,-0.311127,6.23],[0.0,-0.44,6.23],[0.339411,-0.311127,6.23],[0.48,0.0,6.23])),
                    #(false,true,#([-0.48,0.0,6.23],[-0.339411,-0.22,6.165],[0.0,-0.311127,6.138076],[0.339411,-0.22,6.165],[0.48,0.0,6.23])),
                    #(false,true,#([-0.48,0.0,6.23],[-0.339411,0.0,6.138076],[0.0,0.0,6.1],[0.339411,0.0,6.138076],[0.48,0.0,6.23])),
                    #(false,true,#([-0.48,0.0,6.23],[-0.339411,0.22,6.165],[0.0,0.311127,6.138076],[0.339411,0.22,6.165],[0.48,0.0,6.23]))
                ) "dark" "body" true 0.0
                f.cage "LanternBase" #(
                    #(true,true,#([-0.304056,0.282843,5.04],[-0.304056,0.2,5.105],[-0.304056,0.0,5.131924],[-0.304056,-0.2,5.105],[-0.304056,-0.282843,5.04],[-0.304056,-0.2,4.975],[-0.304056,0.0,4.948076],[-0.304056,0.2,4.975])),
                    #(true,true,#([0.0,0.4,5.04],[0.0,0.282843,5.131924],[0.0,0.0,5.17],[0.0,-0.282843,5.131924],[0.0,-0.4,5.04],[0.0,-0.282843,4.948076],[0.0,0.0,4.91],[0.0,0.282843,4.948076])),
                    #(true,true,#([0.304056,0.282843,5.04],[0.304056,0.2,5.105],[0.304056,0.0,5.131924],[0.304056,-0.2,5.105],[0.304056,-0.282843,5.04],[0.304056,-0.2,4.975],[0.304056,0.0,4.948076],[0.304056,0.2,4.975])),
                    #(false,true,#([-0.43,0.0,5.04],[-0.304056,0.282843,5.04],[0.0,0.4,5.04],[0.304056,0.282843,5.04],[0.43,0.0,5.04])),
                    #(false,true,#([-0.43,0.0,5.04],[-0.304056,0.2,5.105],[0.0,0.282843,5.131924],[0.304056,0.2,5.105],[0.43,0.0,5.04])),
                    #(false,true,#([-0.43,0.0,5.04],[-0.304056,0.0,5.131924],[0.0,0.0,5.17],[0.304056,0.0,5.131924],[0.43,0.0,5.04])),
                    #(false,true,#([-0.43,0.0,5.04],[-0.304056,-0.2,5.105],[0.0,-0.282843,5.131924],[0.304056,-0.2,5.105],[0.43,0.0,5.04])),
                    #(false,true,#([-0.43,0.0,5.04],[-0.304056,-0.282843,5.04],[0.0,-0.4,5.04],[0.304056,-0.282843,5.04],[0.43,0.0,5.04])),
                    #(false,true,#([-0.43,0.0,5.04],[-0.304056,-0.2,4.975],[0.0,-0.282843,4.948076],[0.304056,-0.2,4.975],[0.43,0.0,5.04])),
                    #(false,true,#([-0.43,0.0,5.04],[-0.304056,0.0,4.948076],[0.0,0.0,4.91],[0.304056,0.0,4.948076],[0.43,0.0,5.04])),
                    #(false,true,#([-0.43,0.0,5.04],[-0.304056,0.2,4.975],[0.0,0.282843,4.948076],[0.304056,0.2,4.975],[0.43,0.0,5.04]))
                ) "dark" "body" true 0.0
                f.tube "LanternSuspension" #([0.0,0.0,6.3],[0.0,0.0,7.2],[0.0,0.1,8.0]) 0.1 5 false true "gold_glow" "body"
                f.tube "LeftInnerEdge" #([-0.56,-0.38,1.1],[-0.64,-0.5,5.35],[-0.43,-0.4,8.65]) 0.1 5 false true "cyan_glow" "body"
                f.tube "RightInnerEdge" #([0.56,-0.38,1.1],[0.64,-0.5,5.35],[0.43,-0.4,8.65]) 0.1 5 false true "cyan_glow" "body"
                f.finishModel()
                f.startModel "paradeai2" "The bell-mantled visitor" "ai" 2 0.3 [0.0,0.0,8.28] "A broad bell-shaped ceremonial presence with a tiny elongated masked head." true
                f.cage "BellMantle" #(
                    #(true,true,#([3.35,0.0,0.0],[2.901185,0.66,0.0],[1.675,1.143154,0.0],[0.0,1.32,0.0],[-1.675,1.143154,0.0],[-2.901185,0.66,0.0],[-3.35,0.0,0.0],[-2.901185,-0.66,0.0],[-1.675,-1.143154,0.0],[0.0,-1.32,0.0],[1.675,-1.143154,0.0],[2.901185,-0.66,0.0])),
                    #(true,true,#([3.78,0.0,1.1],[3.273576,0.75,1.1],[1.89,1.299038,1.1],[0.0,1.5,1.1],[-1.89,1.299038,1.1],[-3.273576,0.75,1.1],[-3.78,0.0,1.1],[-3.273576,-0.75,1.1],[-1.89,-1.299038,1.1],[0.0,-1.5,1.1],[1.89,-1.299038,1.1],[3.273576,-0.75,1.1])),
                    #(true,true,#([3.22,0.0,3.7],[2.788602,0.725,3.7],[1.61,1.255737,3.7],[0.0,1.45,3.7],[-1.61,1.255737,3.7],[-2.788602,0.725,3.7],[-3.22,0.0,3.7],[-2.788602,-0.725,3.7],[-1.61,-1.255737,3.7],[0.0,-1.45,3.7],[1.61,-1.255737,3.7],[2.788602,-0.725,3.7])),
                    #(true,true,#([2.16,0.0,6.2],[1.870615,0.565,6.2],[1.08,0.978609,6.2],[0.0,1.13,6.2],[-1.08,0.978609,6.2],[-1.870615,0.565,6.2],[-2.16,0.0,6.2],[-1.870615,-0.565,6.2],[-1.08,-0.978609,6.2],[0.0,-1.13,6.2],[1.08,-0.978609,6.2],[1.870615,-0.565,6.2])),
                    #(true,true,#([0.68,0.0,8.1],[0.588897,0.25,8.1],[0.34,0.433013,8.1],[0.0,0.5,8.1],[-0.34,0.433013,8.1],[-0.588897,0.25,8.1],[-0.68,0.0,8.1],[-0.588897,-0.25,8.1],[-0.34,-0.433013,8.1],[0.0,-0.5,8.1],[0.34,-0.433013,8.1],[0.588897,-0.25,8.1])),
                    #(false,true,#([0.0,0.0,0.0],[3.35,0.0,0.0],[3.78,0.0,1.1],[3.22,0.0,3.7],[2.16,0.0,6.2],[0.68,0.0,8.1],[0.0,0.0,8.1])),
                    #(false,true,#([0.0,0.0,0.0],[2.901185,0.66,0.0],[3.273576,0.75,1.1],[2.788602,0.725,3.7],[1.870615,0.565,6.2],[0.588897,0.25,8.1],[0.0,0.0,8.1])),
                    #(false,true,#([0.0,0.0,0.0],[1.675,1.143154,0.0],[1.89,1.299038,1.1],[1.61,1.255737,3.7],[1.08,0.978609,6.2],[0.34,0.433013,8.1],[0.0,0.0,8.1])),
                    #(false,true,#([0.0,0.0,0.0],[0.0,1.32,0.0],[0.0,1.5,1.1],[0.0,1.45,3.7],[0.0,1.13,6.2],[0.0,0.5,8.1],[0.0,0.0,8.1])),
                    #(false,true,#([0.0,0.0,0.0],[-1.675,1.143154,0.0],[-1.89,1.299038,1.1],[-1.61,1.255737,3.7],[-1.08,0.978609,6.2],[-0.34,0.433013,8.1],[0.0,0.0,8.1])),
                    #(false,true,#([0.0,0.0,0.0],[-2.901185,0.66,0.0],[-3.273576,0.75,1.1],[-2.788602,0.725,3.7],[-1.870615,0.565,6.2],[-0.588897,0.25,8.1],[0.0,0.0,8.1])),
                    #(false,true,#([0.0,0.0,0.0],[-3.35,0.0,0.0],[-3.78,0.0,1.1],[-3.22,0.0,3.7],[-2.16,0.0,6.2],[-0.68,0.0,8.1],[0.0,0.0,8.1])),
                    #(false,true,#([0.0,0.0,0.0],[-2.901185,-0.66,0.0],[-3.273576,-0.75,1.1],[-2.788602,-0.725,3.7],[-1.870615,-0.565,6.2],[-0.588897,-0.25,8.1],[0.0,0.0,8.1])),
                    #(false,true,#([0.0,0.0,0.0],[-1.675,-1.143154,0.0],[-1.89,-1.299038,1.1],[-1.61,-1.255737,3.7],[-1.08,-0.978609,6.2],[-0.34,-0.433013,8.1],[0.0,0.0,8.1])),
                    #(false,true,#([0.0,0.0,0.0],[0.0,-1.32,0.0],[0.0,-1.5,1.1],[0.0,-1.45,3.7],[0.0,-1.13,6.2],[0.0,-0.5,8.1],[0.0,0.0,8.1])),
                    #(false,true,#([0.0,0.0,0.0],[1.675,-1.143154,0.0],[1.89,-1.299038,1.1],[1.61,-1.255737,3.7],[1.08,-0.978609,6.2],[0.34,-0.433013,8.1],[0.0,0.0,8.1])),
                    #(false,true,#([0.0,0.0,0.0],[2.901185,-0.66,0.0],[3.273576,-0.75,1.1],[2.788602,-0.725,3.7],[1.870615,-0.565,6.2],[0.588897,-0.25,8.1],[0.0,0.0,8.1]))
                ) "dark" "body" true 0.0
                f.cage "CeremonialCollar" #(
                    #(true,false,#([3.75,0.0,7.0],[3.247595,0.575,7.0],[1.875,0.995929,7.0],[0.0,1.15,7.0],[-1.875,0.995929,7.0],[-3.247595,0.575,7.0],[-3.75,0.0,7.0],[-3.247595,-0.575,7.0],[-1.875,-0.995929,7.0],[0.0,-1.15,7.0],[1.875,-0.995929,7.0],[3.247595,-0.575,7.0])),
                    #(true,false,#([4.1,0.0,7.32],[3.550704,0.65,7.32],[2.05,1.125833,7.32],[0.0,1.3,7.32],[-2.05,1.125833,7.32],[-3.550704,0.65,7.32],[-4.1,0.0,7.32],[-3.550704,-0.65,7.32],[-2.05,-1.125833,7.32],[0.0,-1.3,7.32],[2.05,-1.125833,7.32],[3.550704,-0.65,7.32])),
                    #(true,false,#([2.85,0.0,7.78],[2.468172,0.455,7.78],[1.425,0.788083,7.78],[0.0,0.91,7.78],[-1.425,0.788083,7.78],[-2.468172,0.455,7.78],[-2.85,0.0,7.78],[-2.468172,-0.455,7.78],[-1.425,-0.788083,7.78],[0.0,-0.91,7.78],[1.425,-0.788083,7.78],[2.468172,-0.455,7.78])),
                    #(true,false,#([0.73,0.0,8.2],[0.632199,0.215,8.2],[0.365,0.372391,8.2],[0.0,0.43,8.2],[-0.365,0.372391,8.2],[-0.632199,0.215,8.2],[-0.73,0.0,8.2],[-0.632199,-0.215,8.2],[-0.365,-0.372391,8.2],[0.0,-0.43,8.2],[0.365,-0.372391,8.2],[0.632199,-0.215,8.2])),
                    #(false,false,#([0.0,0.0,7.0],[3.75,0.0,7.0],[4.1,0.0,7.32],[2.85,0.0,7.78],[0.73,0.0,8.2],[0.0,0.0,8.2])),
                    #(false,false,#([0.0,0.0,7.0],[3.247595,0.575,7.0],[3.550704,0.65,7.32],[2.468172,0.455,7.78],[0.632199,0.215,8.2],[0.0,0.0,8.2])),
                    #(false,false,#([0.0,0.0,7.0],[1.875,0.995929,7.0],[2.05,1.125833,7.32],[1.425,0.788083,7.78],[0.365,0.372391,8.2],[0.0,0.0,8.2])),
                    #(false,false,#([0.0,0.0,7.0],[0.0,1.15,7.0],[0.0,1.3,7.32],[0.0,0.91,7.78],[0.0,0.43,8.2],[0.0,0.0,8.2])),
                    #(false,false,#([0.0,0.0,7.0],[-1.875,0.995929,7.0],[-2.05,1.125833,7.32],[-1.425,0.788083,7.78],[-0.365,0.372391,8.2],[0.0,0.0,8.2])),
                    #(false,false,#([0.0,0.0,7.0],[-3.247595,0.575,7.0],[-3.550704,0.65,7.32],[-2.468172,0.455,7.78],[-0.632199,0.215,8.2],[0.0,0.0,8.2])),
                    #(false,false,#([0.0,0.0,7.0],[-3.75,0.0,7.0],[-4.1,0.0,7.32],[-2.85,0.0,7.78],[-0.73,0.0,8.2],[0.0,0.0,8.2])),
                    #(false,false,#([0.0,0.0,7.0],[-3.247595,-0.575,7.0],[-3.550704,-0.65,7.32],[-2.468172,-0.455,7.78],[-0.632199,-0.215,8.2],[0.0,0.0,8.2])),
                    #(false,false,#([0.0,0.0,7.0],[-1.875,-0.995929,7.0],[-2.05,-1.125833,7.32],[-1.425,-0.788083,7.78],[-0.365,-0.372391,8.2],[0.0,0.0,8.2])),
                    #(false,false,#([0.0,0.0,7.0],[0.0,-1.15,7.0],[0.0,-1.3,7.32],[0.0,-0.91,7.78],[0.0,-0.43,8.2],[0.0,0.0,8.2])),
                    #(false,false,#([0.0,0.0,7.0],[1.875,-0.995929,7.0],[2.05,-1.125833,7.32],[1.425,-0.788083,7.78],[0.365,-0.372391,8.2],[0.0,0.0,8.2])),
                    #(false,false,#([0.0,0.0,7.0],[3.247595,-0.575,7.0],[3.550704,-0.65,7.32],[2.468172,-0.455,7.78],[0.632199,-0.215,8.2],[0.0,0.0,8.2]))
                ) "teal" "body" true 0.0
                f.cage "SlenderNeck" #(
                    #(true,true,#([-0.23,0.0,8.0],[-0.162635,-0.162635,8.0],[0.0,-0.23,8.0],[0.162635,-0.162635,8.0],[0.23,0.0,8.0],[0.162635,0.162635,8.0],[0.0,0.23,8.0],[-0.162635,0.162635,8.0])),
                    #(true,true,#([-0.23,0.0,8.86],[-0.162635,-0.162635,8.86],[0.0,-0.23,8.86],[0.162635,-0.162635,8.86],[0.23,0.0,8.86],[0.162635,0.162635,8.86],[0.0,0.23,8.86],[-0.162635,0.162635,8.86])),
                    #(false,true,#([0.0,0.0,8.0],[-0.23,0.0,8.0],[-0.23,0.0,8.86],[0.0,0.0,8.86])),
                    #(false,true,#([0.0,0.0,8.0],[-0.162635,-0.162635,8.0],[-0.162635,-0.162635,8.86],[0.0,0.0,8.86])),
                    #(false,true,#([0.0,0.0,8.0],[0.0,-0.23,8.0],[0.0,-0.23,8.86],[0.0,0.0,8.86])),
                    #(false,true,#([0.0,0.0,8.0],[0.162635,-0.162635,8.0],[0.162635,-0.162635,8.86],[0.0,0.0,8.86])),
                    #(false,true,#([0.0,0.0,8.0],[0.23,0.0,8.0],[0.23,0.0,8.86],[0.0,0.0,8.86])),
                    #(false,true,#([0.0,0.0,8.0],[0.162635,0.162635,8.0],[0.162635,0.162635,8.86],[0.0,0.0,8.86])),
                    #(false,true,#([0.0,0.0,8.0],[0.0,0.23,8.0],[0.0,0.23,8.86],[0.0,0.0,8.86])),
                    #(false,true,#([0.0,0.0,8.0],[-0.162635,0.162635,8.0],[-0.162635,0.162635,8.86],[0.0,0.0,8.86]))
                ) "dark" "body" true 0.0
                f.cage "Head" #(
                    #(true,true,#([-0.445477,0.311127,9.53],[-0.445477,0.22,10.08],[-0.445477,0.0,10.307817],[-0.445477,-0.22,10.08],[-0.445477,-0.311127,9.53],[-0.445477,-0.22,8.98],[-0.445477,0.0,8.752183],[-0.445477,0.22,8.98])),
                    #(true,true,#([0.0,0.44,9.53],[0.0,0.311127,10.307817],[0.0,0.0,10.63],[0.0,-0.311127,10.307817],[0.0,-0.44,9.53],[0.0,-0.311127,8.752183],[0.0,0.0,8.43],[0.0,0.311127,8.752183])),
                    #(true,true,#([0.445477,0.311127,9.53],[0.445477,0.22,10.08],[0.445477,0.0,10.307817],[0.445477,-0.22,10.08],[0.445477,-0.311127,9.53],[0.445477,-0.22,8.98],[0.445477,0.0,8.752183],[0.445477,0.22,8.98])),
                    #(false,true,#([-0.63,0.0,9.53],[-0.445477,0.311127,9.53],[0.0,0.44,9.53],[0.445477,0.311127,9.53],[0.63,0.0,9.53])),
                    #(false,true,#([-0.63,0.0,9.53],[-0.445477,0.22,10.08],[0.0,0.311127,10.307817],[0.445477,0.22,10.08],[0.63,0.0,9.53])),
                    #(false,true,#([-0.63,0.0,9.53],[-0.445477,0.0,10.307817],[0.0,0.0,10.63],[0.445477,0.0,10.307817],[0.63,0.0,9.53])),
                    #(false,true,#([-0.63,0.0,9.53],[-0.445477,-0.22,10.08],[0.0,-0.311127,10.307817],[0.445477,-0.22,10.08],[0.63,0.0,9.53])),
                    #(false,true,#([-0.63,0.0,9.53],[-0.445477,-0.311127,9.53],[0.0,-0.44,9.53],[0.445477,-0.311127,9.53],[0.63,0.0,9.53])),
                    #(false,true,#([-0.63,0.0,9.53],[-0.445477,-0.22,8.98],[0.0,-0.311127,8.752183],[0.445477,-0.22,8.98],[0.63,0.0,9.53])),
                    #(false,true,#([-0.63,0.0,9.53],[-0.445477,0.0,8.752183],[0.0,0.0,8.43],[0.445477,0.0,8.752183],[0.63,0.0,9.53])),
                    #(false,true,#([-0.63,0.0,9.53],[-0.445477,0.22,8.98],[0.0,0.311127,8.752183],[0.445477,0.22,8.98],[0.63,0.0,9.53]))
                ) "dark" "head" true 0.0
                f.cage "FacePlate" #(
                    #(true,true,#([-0.325269,-0.298076,9.5],[-0.325269,-0.325,9.9775],[-0.325269,-0.39,10.175287],[-0.325269,-0.455,9.9775],[-0.325269,-0.481924,9.5],[-0.325269,-0.455,9.0225],[-0.325269,-0.39,8.824713],[-0.325269,-0.325,9.0225])),
                    #(true,true,#([0.0,-0.26,9.5],[0.0,-0.298076,10.175287],[0.0,-0.39,10.455],[0.0,-0.481924,10.175287],[0.0,-0.52,9.5],[0.0,-0.481924,8.824713],[0.0,-0.39,8.545],[0.0,-0.298076,8.824713])),
                    #(true,true,#([0.325269,-0.298076,9.5],[0.325269,-0.325,9.9775],[0.325269,-0.39,10.175287],[0.325269,-0.455,9.9775],[0.325269,-0.481924,9.5],[0.325269,-0.455,9.0225],[0.325269,-0.39,8.824713],[0.325269,-0.325,9.0225])),
                    #(false,true,#([-0.46,-0.39,9.5],[-0.325269,-0.298076,9.5],[0.0,-0.26,9.5],[0.325269,-0.298076,9.5],[0.46,-0.39,9.5])),
                    #(false,true,#([-0.46,-0.39,9.5],[-0.325269,-0.325,9.9775],[0.0,-0.298076,10.175287],[0.325269,-0.325,9.9775],[0.46,-0.39,9.5])),
                    #(false,true,#([-0.46,-0.39,9.5],[-0.325269,-0.39,10.175287],[0.0,-0.39,10.455],[0.325269,-0.39,10.175287],[0.46,-0.39,9.5])),
                    #(false,true,#([-0.46,-0.39,9.5],[-0.325269,-0.455,9.9775],[0.0,-0.481924,10.175287],[0.325269,-0.455,9.9775],[0.46,-0.39,9.5])),
                    #(false,true,#([-0.46,-0.39,9.5],[-0.325269,-0.481924,9.5],[0.0,-0.52,9.5],[0.325269,-0.481924,9.5],[0.46,-0.39,9.5])),
                    #(false,true,#([-0.46,-0.39,9.5],[-0.325269,-0.455,9.0225],[0.0,-0.481924,8.824713],[0.325269,-0.455,9.0225],[0.46,-0.39,9.5])),
                    #(false,true,#([-0.46,-0.39,9.5],[-0.325269,-0.39,8.824713],[0.0,-0.39,8.545],[0.325269,-0.39,8.824713],[0.46,-0.39,9.5])),
                    #(false,true,#([-0.46,-0.39,9.5],[-0.325269,-0.325,9.0225],[0.0,-0.298076,8.824713],[0.325269,-0.325,9.0225],[0.46,-0.39,9.5]))
                ) "ivory_glow" "mask" true 0.0
                f.cage "EyeLeft" #(
                    #(true,true,#([-0.280465,-0.428707,9.6719],[-0.280465,-0.4524,9.772175],[-0.280465,-0.5096,9.81371],[-0.280465,-0.5668,9.772175],[-0.280465,-0.590493,9.6719],[-0.280465,-0.5668,9.571625],[-0.280465,-0.5096,9.53009],[-0.280465,-0.4524,9.571625])),
                    #(true,true,#([-0.2024,-0.3952,9.6719],[-0.2024,-0.428707,9.81371],[-0.2024,-0.5096,9.87245],[-0.2024,-0.590493,9.81371],[-0.2024,-0.624,9.6719],[-0.2024,-0.590493,9.53009],[-0.2024,-0.5096,9.47135],[-0.2024,-0.428707,9.53009])),
                    #(true,true,#([-0.124335,-0.428707,9.6719],[-0.124335,-0.4524,9.772175],[-0.124335,-0.5096,9.81371],[-0.124335,-0.5668,9.772175],[-0.124335,-0.590493,9.6719],[-0.124335,-0.5668,9.571625],[-0.124335,-0.5096,9.53009],[-0.124335,-0.4524,9.571625])),
                    #(false,true,#([-0.3128,-0.5096,9.6719],[-0.280465,-0.428707,9.6719],[-0.2024,-0.3952,9.6719],[-0.124335,-0.428707,9.6719],[-0.092,-0.5096,9.6719])),
                    #(false,true,#([-0.3128,-0.5096,9.6719],[-0.280465,-0.4524,9.772175],[-0.2024,-0.428707,9.81371],[-0.124335,-0.4524,9.772175],[-0.092,-0.5096,9.6719])),
                    #(false,true,#([-0.3128,-0.5096,9.6719],[-0.280465,-0.5096,9.81371],[-0.2024,-0.5096,9.87245],[-0.124335,-0.5096,9.81371],[-0.092,-0.5096,9.6719])),
                    #(false,true,#([-0.3128,-0.5096,9.6719],[-0.280465,-0.5668,9.772175],[-0.2024,-0.590493,9.81371],[-0.124335,-0.5668,9.772175],[-0.092,-0.5096,9.6719])),
                    #(false,true,#([-0.3128,-0.5096,9.6719],[-0.280465,-0.590493,9.6719],[-0.2024,-0.624,9.6719],[-0.124335,-0.590493,9.6719],[-0.092,-0.5096,9.6719])),
                    #(false,true,#([-0.3128,-0.5096,9.6719],[-0.280465,-0.5668,9.571625],[-0.2024,-0.590493,9.53009],[-0.124335,-0.5668,9.571625],[-0.092,-0.5096,9.6719])),
                    #(false,true,#([-0.3128,-0.5096,9.6719],[-0.280465,-0.5096,9.53009],[-0.2024,-0.5096,9.47135],[-0.124335,-0.5096,9.53009],[-0.092,-0.5096,9.6719])),
                    #(false,true,#([-0.3128,-0.5096,9.6719],[-0.280465,-0.4524,9.571625],[-0.2024,-0.428707,9.53009],[-0.124335,-0.4524,9.571625],[-0.092,-0.5096,9.6719]))
                ) "dark" "mask" true 0.0
                f.cage "EyeRight" #(
                    #(true,true,#([0.124335,-0.428707,9.6719],[0.124335,-0.4524,9.772175],[0.124335,-0.5096,9.81371],[0.124335,-0.5668,9.772175],[0.124335,-0.590493,9.6719],[0.124335,-0.5668,9.571625],[0.124335,-0.5096,9.53009],[0.124335,-0.4524,9.571625])),
                    #(true,true,#([0.2024,-0.3952,9.6719],[0.2024,-0.428707,9.81371],[0.2024,-0.5096,9.87245],[0.2024,-0.590493,9.81371],[0.2024,-0.624,9.6719],[0.2024,-0.590493,9.53009],[0.2024,-0.5096,9.47135],[0.2024,-0.428707,9.53009])),
                    #(true,true,#([0.280465,-0.428707,9.6719],[0.280465,-0.4524,9.772175],[0.280465,-0.5096,9.81371],[0.280465,-0.5668,9.772175],[0.280465,-0.590493,9.6719],[0.280465,-0.5668,9.571625],[0.280465,-0.5096,9.53009],[0.280465,-0.4524,9.571625])),
                    #(false,true,#([0.092,-0.5096,9.6719],[0.124335,-0.428707,9.6719],[0.2024,-0.3952,9.6719],[0.280465,-0.428707,9.6719],[0.3128,-0.5096,9.6719])),
                    #(false,true,#([0.092,-0.5096,9.6719],[0.124335,-0.4524,9.772175],[0.2024,-0.428707,9.81371],[0.280465,-0.4524,9.772175],[0.3128,-0.5096,9.6719])),
                    #(false,true,#([0.092,-0.5096,9.6719],[0.124335,-0.5096,9.81371],[0.2024,-0.5096,9.87245],[0.280465,-0.5096,9.81371],[0.3128,-0.5096,9.6719])),
                    #(false,true,#([0.092,-0.5096,9.6719],[0.124335,-0.5668,9.772175],[0.2024,-0.590493,9.81371],[0.280465,-0.5668,9.772175],[0.3128,-0.5096,9.6719])),
                    #(false,true,#([0.092,-0.5096,9.6719],[0.124335,-0.590493,9.6719],[0.2024,-0.624,9.6719],[0.280465,-0.590493,9.6719],[0.3128,-0.5096,9.6719])),
                    #(false,true,#([0.092,-0.5096,9.6719],[0.124335,-0.5668,9.571625],[0.2024,-0.590493,9.53009],[0.280465,-0.5668,9.571625],[0.3128,-0.5096,9.6719])),
                    #(false,true,#([0.092,-0.5096,9.6719],[0.124335,-0.5096,9.53009],[0.2024,-0.5096,9.47135],[0.280465,-0.5096,9.53009],[0.3128,-0.5096,9.6719])),
                    #(false,true,#([0.092,-0.5096,9.6719],[0.124335,-0.4524,9.571625],[0.2024,-0.428707,9.53009],[0.280465,-0.4524,9.571625],[0.3128,-0.5096,9.6719]))
                ) "dark" "mask" true 0.0
                f.cage "QuietMouth" #(
                    #(true,false,#([-0.1242,-0.611,9.0007],[0.1242,-0.611,9.0007],[0.1242,-0.429,9.0007],[-0.1242,-0.429,9.0007])),
                    #(true,false,#([-0.1242,-0.611,9.1207],[0.1242,-0.611,9.1207],[0.1242,-0.429,9.1207],[-0.1242,-0.429,9.1207])),
                    #(false,false,#([-0.1242,-0.611,9.0007],[-0.1242,-0.611,9.1207])),
                    #(false,false,#([0.1242,-0.611,9.0007],[0.1242,-0.611,9.1207])),
                    #(false,false,#([0.1242,-0.429,9.0007],[0.1242,-0.429,9.1207])),
                    #(false,false,#([-0.1242,-0.429,9.0007],[-0.1242,-0.429,9.1207]))
                ) "dark" "mask" true 0.0
                f.tube "WideCollarEdge" #([-3.68,-0.48,7.31],[-2.08,-1.1,7.27],[0.0,-1.27,7.23],[2.08,-1.1,7.27],[3.68,-0.48,7.31]) 0.12 5 false true "gold_glow" "body"
                f.tube "BellFrontHem" #([-3.08,-0.61,0.3],[-1.75,-1.22,0.23],[0.0,-1.36,0.2],[1.75,-1.22,0.23],[3.08,-0.61,0.3]) 0.11 5 false true "gold_glow" "body"
                f.finishModel()
                f.startModel "paradeai3" "The many-eyed pilgrim" "ai" 3 0.3 [0.0,0.0,7.0] "A narrow pilgrim with an enormous oval three-eyed mask and unequal hanging sleeves." true
                f.cage "PilgrimStem" #(
                    #(true,true,#([0.65,0.0,0.0],[0.459619,0.346482,0.0],[0.0,0.49,0.0],[-0.459619,0.346482,0.0],[-0.65,0.0,0.0],[-0.459619,-0.346482,0.0],[0.0,-0.49,0.0],[0.459619,-0.346482,0.0])),
                    #(true,true,#([0.88,0.0,2.5],[0.622254,0.431335,2.5],[0.0,0.61,2.5],[-0.622254,0.431335,2.5],[-0.88,0.0,2.5],[-0.622254,-0.431335,2.5],[0.0,-0.61,2.5],[0.622254,-0.431335,2.5])),
                    #(true,true,#([0.71,0.0,4.7],[0.502046,0.381838,4.7],[0.0,0.54,4.7],[-0.502046,0.381838,4.7],[-0.71,0.0,4.7],[-0.502046,-0.381838,4.7],[0.0,-0.54,4.7],[0.502046,-0.381838,4.7])),
                    #(true,true,#([1.13,0.0,6.2],[0.799031,0.438406,6.2],[0.0,0.62,6.2],[-0.799031,0.438406,6.2],[-1.13,0.0,6.2],[-0.799031,-0.438406,6.2],[0.0,-0.62,6.2],[0.799031,-0.438406,6.2])),
                    #(true,true,#([0.53,0.0,6.72],[0.374767,0.275772,6.72],[0.0,0.39,6.72],[-0.374767,0.275772,6.72],[-0.53,0.0,6.72],[-0.374767,-0.275772,6.72],[0.0,-0.39,6.72],[0.374767,-0.275772,6.72])),
                    #(false,true,#([0.0,0.0,0.0],[0.65,0.0,0.0],[0.88,0.0,2.5],[0.71,0.0,4.7],[1.13,0.0,6.2],[0.53,0.0,6.72],[0.0,0.0,6.72])),
                    #(false,true,#([0.0,0.0,0.0],[0.459619,0.346482,0.0],[0.622254,0.431335,2.5],[0.502046,0.381838,4.7],[0.799031,0.438406,6.2],[0.374767,0.275772,6.72],[0.0,0.0,6.72])),
                    #(false,true,#([0.0,0.0,0.0],[0.0,0.49,0.0],[0.0,0.61,2.5],[0.0,0.54,4.7],[0.0,0.62,6.2],[0.0,0.39,6.72],[0.0,0.0,6.72])),
                    #(false,true,#([0.0,0.0,0.0],[-0.459619,0.346482,0.0],[-0.622254,0.431335,2.5],[-0.502046,0.381838,4.7],[-0.799031,0.438406,6.2],[-0.374767,0.275772,6.72],[0.0,0.0,6.72])),
                    #(false,true,#([0.0,0.0,0.0],[-0.65,0.0,0.0],[-0.88,0.0,2.5],[-0.71,0.0,4.7],[-1.13,0.0,6.2],[-0.53,0.0,6.72],[0.0,0.0,6.72])),
                    #(false,true,#([0.0,0.0,0.0],[-0.459619,-0.346482,0.0],[-0.622254,-0.431335,2.5],[-0.502046,-0.381838,4.7],[-0.799031,-0.438406,6.2],[-0.374767,-0.275772,6.72],[0.0,0.0,6.72])),
                    #(false,true,#([0.0,0.0,0.0],[0.0,-0.49,0.0],[0.0,-0.61,2.5],[0.0,-0.54,4.7],[0.0,-0.62,6.2],[0.0,-0.39,6.72],[0.0,0.0,6.72])),
                    #(false,true,#([0.0,0.0,0.0],[0.459619,-0.346482,0.0],[0.622254,-0.431335,2.5],[0.502046,-0.381838,4.7],[0.799031,-0.438406,6.2],[0.374767,-0.275772,6.72],[0.0,0.0,6.72]))
                ) "dark" "body" true 0.0
                f.cage "LeftHangingSleeve" #(
                    #(true,true,#([-0.872425,0.499943,6.15],[-0.728373,0.351297,5.828131],[-0.673142,-0.003134,5.694808],[-0.739086,-0.355729,5.828131],[-0.887575,-0.499943,6.15],[-1.031627,-0.351297,6.471869],[-1.086858,0.003134,6.605192],[-1.020914,0.355729,6.471869])),
                    #(true,true,#([-2.172814,0.689332,5.562462],[-1.829343,0.484928,5.241204],[-1.702999,0.008176,5.100834],[-1.867791,-0.46165,5.22358],[-2.227186,-0.649332,5.537538],[-2.570657,-0.444928,5.858796],[-2.697001,0.031824,5.999166],[-2.532209,0.50165,5.87642])),
                    #(true,true,#([-2.803063,0.439207,3.713732],[-2.607201,0.343316,3.641872],[-2.535994,0.128326,3.604062],[-2.631153,-0.079825,3.622452],[-2.836937,-0.159207,3.686268],[-3.032799,-0.063316,3.758128],[-3.104006,0.151674,3.795938],[-3.008847,0.359825,3.777548])),
                    #(false,true,#([-0.88,0.0,6.15],[-0.872425,0.499943,6.15],[-2.172814,0.689332,5.562462],[-2.803063,0.439207,3.713732],[-2.82,0.14,3.7])),
                    #(false,true,#([-0.88,0.0,6.15],[-0.728373,0.351297,5.828131],[-1.829343,0.484928,5.241204],[-2.607201,0.343316,3.641872],[-2.82,0.14,3.7])),
                    #(false,true,#([-0.88,0.0,6.15],[-0.673142,-0.003134,5.694808],[-1.702999,0.008176,5.100834],[-2.535994,0.128326,3.604062],[-2.82,0.14,3.7])),
                    #(false,true,#([-0.88,0.0,6.15],[-0.739086,-0.355729,5.828131],[-1.867791,-0.46165,5.22358],[-2.631153,-0.079825,3.622452],[-2.82,0.14,3.7])),
                    #(false,true,#([-0.88,0.0,6.15],[-0.887575,-0.499943,6.15],[-2.227186,-0.649332,5.537538],[-2.836937,-0.159207,3.686268],[-2.82,0.14,3.7])),
                    #(false,true,#([-0.88,0.0,6.15],[-1.031627,-0.351297,6.471869],[-2.570657,-0.444928,5.858796],[-3.032799,-0.063316,3.758128],[-2.82,0.14,3.7])),
                    #(false,true,#([-0.88,0.0,6.15],[-1.086858,0.003134,6.605192],[-2.697001,0.031824,5.999166],[-3.104006,0.151674,3.795938],[-2.82,0.14,3.7])),
                    #(false,true,#([-0.88,0.0,6.15],[-1.020914,0.355729,6.471869],[-2.532209,0.50165,5.87642],[-3.008847,0.359825,3.777548],[-2.82,0.14,3.7]))
                ) "dark" "body" true 0.0
                f.cage "RightOfferingSleeve" #(
                    #(true,true,#([0.830736,-0.497567,6.15],[0.677536,-0.335236,5.839154],[0.642937,0.023472,5.710398],[0.747206,0.36843,5.839154],[0.929264,0.497567,6.15],[1.082464,0.335236,6.460846],[1.117063,-0.023472,6.589602],[1.012794,-0.36843,6.460846])),
                    #(true,true,#([1.758911,-0.68527,5.616569],[1.815705,-0.52996,5.188157],[1.91602,-0.122786,5.000998],[2.001093,0.297737,5.164725],[2.021089,0.48527,5.583431],[1.964295,0.32996,6.011843],[1.86398,-0.077214,6.199002],[1.778907,-0.497737,6.035275])),
                    #(true,true,#([2.627002,-0.664083,6.196605],[2.759902,-0.621839,6.033882],[2.869428,-0.449645,5.968469],[2.891421,-0.248369,6.038683],[2.812998,-0.135917,6.203395],[2.680098,-0.178161,6.366118],[2.570572,-0.350355,6.431531],[2.548579,-0.551631,6.361317])),
                    #(false,true,#([0.88,0.0,6.15],[0.830736,-0.497567,6.15],[1.758911,-0.68527,5.616569],[2.627002,-0.664083,6.196605],[2.72,-0.4,6.2])),
                    #(false,true,#([0.88,0.0,6.15],[0.677536,-0.335236,5.839154],[1.815705,-0.52996,5.188157],[2.759902,-0.621839,6.033882],[2.72,-0.4,6.2])),
                    #(false,true,#([0.88,0.0,6.15],[0.642937,0.023472,5.710398],[1.91602,-0.122786,5.000998],[2.869428,-0.449645,5.968469],[2.72,-0.4,6.2])),
                    #(false,true,#([0.88,0.0,6.15],[0.747206,0.36843,5.839154],[2.001093,0.297737,5.164725],[2.891421,-0.248369,6.038683],[2.72,-0.4,6.2])),
                    #(false,true,#([0.88,0.0,6.15],[0.929264,0.497567,6.15],[2.021089,0.48527,5.583431],[2.812998,-0.135917,6.203395],[2.72,-0.4,6.2])),
                    #(false,true,#([0.88,0.0,6.15],[1.082464,0.335236,6.460846],[1.964295,0.32996,6.011843],[2.680098,-0.178161,6.366118],[2.72,-0.4,6.2])),
                    #(false,true,#([0.88,0.0,6.15],[1.117063,-0.023472,6.589602],[1.86398,-0.077214,6.199002],[2.570572,-0.350355,6.431531],[2.72,-0.4,6.2])),
                    #(false,true,#([0.88,0.0,6.15],[1.012794,-0.36843,6.460846],[1.778907,-0.497737,6.035275],[2.548579,-0.551631,6.361317],[2.72,-0.4,6.2]))
                ) "dark" "body" true 0.0
                f.cage "OfferingPalm" #(
                    #(true,true,#([2.426447,-0.144228,6.23],[2.426447,-0.225,6.335],[2.426447,-0.42,6.378492],[2.426447,-0.615,6.335],[2.426447,-0.695772,6.23],[2.426447,-0.615,6.125],[2.426447,-0.42,6.081508],[2.426447,-0.225,6.125])),
                    #(true,true,#([2.78,-0.03,6.23],[2.78,-0.144228,6.378492],[2.78,-0.42,6.44],[2.78,-0.695772,6.378492],[2.78,-0.81,6.23],[2.78,-0.695772,6.081508],[2.78,-0.42,6.02],[2.78,-0.144228,6.081508])),
                    #(true,true,#([3.133553,-0.144228,6.23],[3.133553,-0.225,6.335],[3.133553,-0.42,6.378492],[3.133553,-0.615,6.335],[3.133553,-0.695772,6.23],[3.133553,-0.615,6.125],[3.133553,-0.42,6.081508],[3.133553,-0.225,6.125])),
                    #(false,true,#([2.28,-0.42,6.23],[2.426447,-0.144228,6.23],[2.78,-0.03,6.23],[3.133553,-0.144228,6.23],[3.28,-0.42,6.23])),
                    #(false,true,#([2.28,-0.42,6.23],[2.426447,-0.225,6.335],[2.78,-0.144228,6.378492],[3.133553,-0.225,6.335],[3.28,-0.42,6.23])),
                    #(false,true,#([2.28,-0.42,6.23],[2.426447,-0.42,6.378492],[2.78,-0.42,6.44],[3.133553,-0.42,6.378492],[3.28,-0.42,6.23])),
                    #(false,true,#([2.28,-0.42,6.23],[2.426447,-0.615,6.335],[2.78,-0.695772,6.378492],[3.133553,-0.615,6.335],[3.28,-0.42,6.23])),
                    #(false,true,#([2.28,-0.42,6.23],[2.426447,-0.695772,6.23],[2.78,-0.81,6.23],[3.133553,-0.695772,6.23],[3.28,-0.42,6.23])),
                    #(false,true,#([2.28,-0.42,6.23],[2.426447,-0.615,6.125],[2.78,-0.695772,6.081508],[3.133553,-0.615,6.125],[3.28,-0.42,6.23])),
                    #(false,true,#([2.28,-0.42,6.23],[2.426447,-0.42,6.081508],[2.78,-0.42,6.02],[3.133553,-0.42,6.081508],[3.28,-0.42,6.23])),
                    #(false,true,#([2.28,-0.42,6.23],[2.426447,-0.225,6.125],[2.78,-0.144228,6.081508],[3.133553,-0.225,6.125],[3.28,-0.42,6.23]))
                ) "teal" "body" true 0.0
                f.cage "PilgrimNeck" #(
                    #(true,true,#([-0.32,0.0,6.45],[-0.226274,-0.226274,6.45],[0.0,-0.32,6.45],[0.226274,-0.226274,6.45],[0.32,0.0,6.45],[0.226274,0.226274,6.45],[0.0,0.32,6.45],[-0.226274,0.226274,6.45])),
                    #(true,true,#([-0.32,0.0,7.3],[-0.226274,-0.226274,7.3],[0.0,-0.32,7.3],[0.226274,-0.226274,7.3],[0.32,0.0,7.3],[0.226274,0.226274,7.3],[0.0,0.32,7.3],[-0.226274,0.226274,7.3])),
                    #(false,true,#([0.0,0.0,6.45],[-0.32,0.0,6.45],[-0.32,0.0,7.3],[0.0,0.0,7.3])),
                    #(false,true,#([0.0,0.0,6.45],[-0.226274,-0.226274,6.45],[-0.226274,-0.226274,7.3],[0.0,0.0,7.3])),
                    #(false,true,#([0.0,0.0,6.45],[0.0,-0.32,6.45],[0.0,-0.32,7.3],[0.0,0.0,7.3])),
                    #(false,true,#([0.0,0.0,6.45],[0.226274,-0.226274,6.45],[0.226274,-0.226274,7.3],[0.0,0.0,7.3])),
                    #(false,true,#([0.0,0.0,6.45],[0.32,0.0,6.45],[0.32,0.0,7.3],[0.0,0.0,7.3])),
                    #(false,true,#([0.0,0.0,6.45],[0.226274,0.226274,6.45],[0.226274,0.226274,7.3],[0.0,0.0,7.3])),
                    #(false,true,#([0.0,0.0,6.45],[0.0,0.32,6.45],[0.0,0.32,7.3],[0.0,0.0,7.3])),
                    #(false,true,#([0.0,0.0,6.45],[-0.226274,0.226274,6.45],[-0.226274,0.226274,7.3],[0.0,0.0,7.3]))
                ) "dark" "body" true 0.0
                f.cage "Head" #(
                    #(true,true,#([-1.463711,0.559117,8.75],[-1.463711,0.41,9.635],[-1.463711,0.05,10.001579],[-1.463711,-0.31,9.635],[-1.463711,-0.459117,8.75],[-1.463711,-0.31,7.865],[-1.463711,0.05,7.498421],[-1.463711,0.41,7.865])),
                    #(true,true,#([0.0,0.77,8.75],[0.0,0.559117,10.001579],[0.0,0.05,10.52],[0.0,-0.459117,10.001579],[0.0,-0.67,8.75],[0.0,-0.459117,7.498421],[0.0,0.05,6.98],[0.0,0.559117,7.498421])),
                    #(true,true,#([1.463711,0.559117,8.75],[1.463711,0.41,9.635],[1.463711,0.05,10.001579],[1.463711,-0.31,9.635],[1.463711,-0.459117,8.75],[1.463711,-0.31,7.865],[1.463711,0.05,7.498421],[1.463711,0.41,7.865])),
                    #(false,true,#([-2.07,0.05,8.75],[-1.463711,0.559117,8.75],[0.0,0.77,8.75],[1.463711,0.559117,8.75],[2.07,0.05,8.75])),
                    #(false,true,#([-2.07,0.05,8.75],[-1.463711,0.41,9.635],[0.0,0.559117,10.001579],[1.463711,0.41,9.635],[2.07,0.05,8.75])),
                    #(false,true,#([-2.07,0.05,8.75],[-1.463711,0.05,10.001579],[0.0,0.05,10.52],[1.463711,0.05,10.001579],[2.07,0.05,8.75])),
                    #(false,true,#([-2.07,0.05,8.75],[-1.463711,-0.31,9.635],[0.0,-0.459117,10.001579],[1.463711,-0.31,9.635],[2.07,0.05,8.75])),
                    #(false,true,#([-2.07,0.05,8.75],[-1.463711,-0.459117,8.75],[0.0,-0.67,8.75],[1.463711,-0.459117,8.75],[2.07,0.05,8.75])),
                    #(false,true,#([-2.07,0.05,8.75],[-1.463711,-0.31,7.865],[0.0,-0.459117,7.498421],[1.463711,-0.31,7.865],[2.07,0.05,8.75])),
                    #(false,true,#([-2.07,0.05,8.75],[-1.463711,0.05,7.498421],[0.0,0.05,6.98],[1.463711,0.05,7.498421],[2.07,0.05,8.75])),
                    #(false,true,#([-2.07,0.05,8.75],[-1.463711,0.41,7.865],[0.0,0.559117,7.498421],[1.463711,0.41,7.865],[2.07,0.05,8.75]))
                ) "teal" "head" true 0.0
                f.cage "FacePlate" #(
                    #(true,true,#([-0.961665,-0.462721,8.72],[-0.961665,-0.5,9.3575],[-0.961665,-0.59,9.621561],[-0.961665,-0.68,9.3575],[-0.961665,-0.717279,8.72],[-0.961665,-0.68,8.0825],[-0.961665,-0.59,7.818439],[-0.961665,-0.5,8.0825])),
                    #(true,true,#([0.0,-0.41,8.72],[0.0,-0.462721,9.621561],[0.0,-0.59,9.995],[0.0,-0.717279,9.621561],[0.0,-0.77,8.72],[0.0,-0.717279,7.818439],[0.0,-0.59,7.445],[0.0,-0.462721,7.818439])),
                    #(true,true,#([0.961665,-0.462721,8.72],[0.961665,-0.5,9.3575],[0.961665,-0.59,9.621561],[0.961665,-0.68,9.3575],[0.961665,-0.717279,8.72],[0.961665,-0.68,8.0825],[0.961665,-0.59,7.818439],[0.961665,-0.5,8.0825])),
                    #(false,true,#([-1.36,-0.59,8.72],[-0.961665,-0.462721,8.72],[0.0,-0.41,8.72],[0.961665,-0.462721,8.72],[1.36,-0.59,8.72])),
                    #(false,true,#([-1.36,-0.59,8.72],[-0.961665,-0.5,9.3575],[0.0,-0.462721,9.621561],[0.961665,-0.5,9.3575],[1.36,-0.59,8.72])),
                    #(false,true,#([-1.36,-0.59,8.72],[-0.961665,-0.59,9.621561],[0.0,-0.59,9.995],[0.961665,-0.59,9.621561],[1.36,-0.59,8.72])),
                    #(false,true,#([-1.36,-0.59,8.72],[-0.961665,-0.68,9.3575],[0.0,-0.717279,9.621561],[0.961665,-0.68,9.3575],[1.36,-0.59,8.72])),
                    #(false,true,#([-1.36,-0.59,8.72],[-0.961665,-0.717279,8.72],[0.0,-0.77,8.72],[0.961665,-0.717279,8.72],[1.36,-0.59,8.72])),
                    #(false,true,#([-1.36,-0.59,8.72],[-0.961665,-0.68,8.0825],[0.0,-0.717279,7.818439],[0.961665,-0.68,8.0825],[1.36,-0.59,8.72])),
                    #(false,true,#([-1.36,-0.59,8.72],[-0.961665,-0.59,7.818439],[0.0,-0.59,7.445],[0.961665,-0.59,7.818439],[1.36,-0.59,8.72])),
                    #(false,true,#([-1.36,-0.59,8.72],[-0.961665,-0.5,8.0825],[0.0,-0.462721,7.818439],[0.961665,-0.5,8.0825],[1.36,-0.59,8.72]))
                ) "ivory_glow" "mask" true 0.0
                f.cage "EyeLeft" #(
                    #(true,true,#([-0.8292,-0.643594,8.9495],[-0.8292,-0.6764,9.083375],[-0.8292,-0.7556,9.138828],[-0.8292,-0.8348,9.083375],[-0.8292,-0.867606,8.9495],[-0.8292,-0.8348,8.815625],[-0.8292,-0.7556,8.760172],[-0.8292,-0.6764,8.815625])),
                    #(true,true,#([-0.5984,-0.5972,8.9495],[-0.5984,-0.643594,9.138828],[-0.5984,-0.7556,9.21725],[-0.5984,-0.867606,9.138828],[-0.5984,-0.914,8.9495],[-0.5984,-0.867606,8.760172],[-0.5984,-0.7556,8.68175],[-0.5984,-0.643594,8.760172])),
                    #(true,true,#([-0.3676,-0.643594,8.9495],[-0.3676,-0.6764,9.083375],[-0.3676,-0.7556,9.138828],[-0.3676,-0.8348,9.083375],[-0.3676,-0.867606,8.9495],[-0.3676,-0.8348,8.815625],[-0.3676,-0.7556,8.760172],[-0.3676,-0.6764,8.815625])),
                    #(false,true,#([-0.9248,-0.7556,8.9495],[-0.8292,-0.643594,8.9495],[-0.5984,-0.5972,8.9495],[-0.3676,-0.643594,8.9495],[-0.272,-0.7556,8.9495])),
                    #(false,true,#([-0.9248,-0.7556,8.9495],[-0.8292,-0.6764,9.083375],[-0.5984,-0.643594,9.138828],[-0.3676,-0.6764,9.083375],[-0.272,-0.7556,8.9495])),
                    #(false,true,#([-0.9248,-0.7556,8.9495],[-0.8292,-0.7556,9.138828],[-0.5984,-0.7556,9.21725],[-0.3676,-0.7556,9.138828],[-0.272,-0.7556,8.9495])),
                    #(false,true,#([-0.9248,-0.7556,8.9495],[-0.8292,-0.8348,9.083375],[-0.5984,-0.867606,9.138828],[-0.3676,-0.8348,9.083375],[-0.272,-0.7556,8.9495])),
                    #(false,true,#([-0.9248,-0.7556,8.9495],[-0.8292,-0.867606,8.9495],[-0.5984,-0.914,8.9495],[-0.3676,-0.867606,8.9495],[-0.272,-0.7556,8.9495])),
                    #(false,true,#([-0.9248,-0.7556,8.9495],[-0.8292,-0.8348,8.815625],[-0.5984,-0.867606,8.760172],[-0.3676,-0.8348,8.815625],[-0.272,-0.7556,8.9495])),
                    #(false,true,#([-0.9248,-0.7556,8.9495],[-0.8292,-0.7556,8.760172],[-0.5984,-0.7556,8.68175],[-0.3676,-0.7556,8.760172],[-0.272,-0.7556,8.9495])),
                    #(false,true,#([-0.9248,-0.7556,8.9495],[-0.8292,-0.6764,8.815625],[-0.5984,-0.643594,8.760172],[-0.3676,-0.6764,8.815625],[-0.272,-0.7556,8.9495]))
                ) "dark" "mask" true 0.0
                f.cage "EyeRight" #(
                    #(true,true,#([0.3676,-0.643594,8.9495],[0.3676,-0.6764,9.083375],[0.3676,-0.7556,9.138828],[0.3676,-0.8348,9.083375],[0.3676,-0.867606,8.9495],[0.3676,-0.8348,8.815625],[0.3676,-0.7556,8.760172],[0.3676,-0.6764,8.815625])),
                    #(true,true,#([0.5984,-0.5972,8.9495],[0.5984,-0.643594,9.138828],[0.5984,-0.7556,9.21725],[0.5984,-0.867606,9.138828],[0.5984,-0.914,8.9495],[0.5984,-0.867606,8.760172],[0.5984,-0.7556,8.68175],[0.5984,-0.643594,8.760172])),
                    #(true,true,#([0.8292,-0.643594,8.9495],[0.8292,-0.6764,9.083375],[0.8292,-0.7556,9.138828],[0.8292,-0.8348,9.083375],[0.8292,-0.867606,8.9495],[0.8292,-0.8348,8.815625],[0.8292,-0.7556,8.760172],[0.8292,-0.6764,8.815625])),
                    #(false,true,#([0.272,-0.7556,8.9495],[0.3676,-0.643594,8.9495],[0.5984,-0.5972,8.9495],[0.8292,-0.643594,8.9495],[0.9248,-0.7556,8.9495])),
                    #(false,true,#([0.272,-0.7556,8.9495],[0.3676,-0.6764,9.083375],[0.5984,-0.643594,9.138828],[0.8292,-0.6764,9.083375],[0.9248,-0.7556,8.9495])),
                    #(false,true,#([0.272,-0.7556,8.9495],[0.3676,-0.7556,9.138828],[0.5984,-0.7556,9.21725],[0.8292,-0.7556,9.138828],[0.9248,-0.7556,8.9495])),
                    #(false,true,#([0.272,-0.7556,8.9495],[0.3676,-0.8348,9.083375],[0.5984,-0.867606,9.138828],[0.8292,-0.8348,9.083375],[0.9248,-0.7556,8.9495])),
                    #(false,true,#([0.272,-0.7556,8.9495],[0.3676,-0.867606,8.9495],[0.5984,-0.914,8.9495],[0.8292,-0.867606,8.9495],[0.9248,-0.7556,8.9495])),
                    #(false,true,#([0.272,-0.7556,8.9495],[0.3676,-0.8348,8.815625],[0.5984,-0.867606,8.760172],[0.8292,-0.8348,8.815625],[0.9248,-0.7556,8.9495])),
                    #(false,true,#([0.272,-0.7556,8.9495],[0.3676,-0.7556,8.760172],[0.5984,-0.7556,8.68175],[0.8292,-0.7556,8.760172],[0.9248,-0.7556,8.9495])),
                    #(false,true,#([0.272,-0.7556,8.9495],[0.3676,-0.6764,8.815625],[0.5984,-0.643594,8.760172],[0.8292,-0.6764,8.815625],[0.9248,-0.7556,8.9495]))
                ) "dark" "mask" true 0.0
                f.cage "ThirdEye" #(
                    #(true,true,#([-0.18464,-0.654613,9.4595],[-0.18464,-0.6863,9.593375],[-0.18464,-0.7628,9.648828],[-0.18464,-0.8393,9.593375],[-0.18464,-0.870987,9.4595],[-0.18464,-0.8393,9.325625],[-0.18464,-0.7628,9.270172],[-0.18464,-0.6863,9.325625])),
                    #(true,true,#([0.0,-0.6098,9.4595],[0.0,-0.654613,9.648828],[0.0,-0.7628,9.72725],[0.0,-0.870987,9.648828],[0.0,-0.9158,9.4595],[0.0,-0.870987,9.270172],[0.0,-0.7628,9.19175],[0.0,-0.654613,9.270172])),
                    #(true,true,#([0.18464,-0.654613,9.4595],[0.18464,-0.6863,9.593375],[0.18464,-0.7628,9.648828],[0.18464,-0.8393,9.593375],[0.18464,-0.870987,9.4595],[0.18464,-0.8393,9.325625],[0.18464,-0.7628,9.270172],[0.18464,-0.6863,9.325625])),
                    #(false,true,#([-0.26112,-0.7628,9.4595],[-0.18464,-0.654613,9.4595],[0.0,-0.6098,9.4595],[0.18464,-0.654613,9.4595],[0.26112,-0.7628,9.4595])),
                    #(false,true,#([-0.26112,-0.7628,9.4595],[-0.18464,-0.6863,9.593375],[0.0,-0.654613,9.648828],[0.18464,-0.6863,9.593375],[0.26112,-0.7628,9.4595])),
                    #(false,true,#([-0.26112,-0.7628,9.4595],[-0.18464,-0.7628,9.648828],[0.0,-0.7628,9.72725],[0.18464,-0.7628,9.648828],[0.26112,-0.7628,9.4595])),
                    #(false,true,#([-0.26112,-0.7628,9.4595],[-0.18464,-0.8393,9.593375],[0.0,-0.870987,9.648828],[0.18464,-0.8393,9.593375],[0.26112,-0.7628,9.4595])),
                    #(false,true,#([-0.26112,-0.7628,9.4595],[-0.18464,-0.870987,9.4595],[0.0,-0.9158,9.4595],[0.18464,-0.870987,9.4595],[0.26112,-0.7628,9.4595])),
                    #(false,true,#([-0.26112,-0.7628,9.4595],[-0.18464,-0.8393,9.325625],[0.0,-0.870987,9.270172],[0.18464,-0.8393,9.325625],[0.26112,-0.7628,9.4595])),
                    #(false,true,#([-0.26112,-0.7628,9.4595],[-0.18464,-0.7628,9.270172],[0.0,-0.7628,9.19175],[0.18464,-0.7628,9.270172],[0.26112,-0.7628,9.4595])),
                    #(false,true,#([-0.26112,-0.7628,9.4595],[-0.18464,-0.6863,9.325625],[0.0,-0.654613,9.270172],[0.18464,-0.6863,9.325625],[0.26112,-0.7628,9.4595]))
                ) "dark" "mask" true 0.0
                f.tube "CrownArc" #([-1.75,-0.2,9.54],[-1.02,-0.25,10.2],[0.0,-0.25,10.45],[1.02,-0.25,10.2],[1.75,-0.2,9.54]) 0.12 5 false true "cyan_glow" "head"
                f.tube "SleeveEdge" #([-0.94,-0.31,5.94],[-2.19,-0.43,5.35],[-2.78,-0.17,3.72]) 0.105 5 false true "cyan_glow" "body"
                f.cage "HeldLight" #(
                    #(true,true,#([2.653223,-0.253223,6.69],[2.653223,-0.305,6.87],[2.653223,-0.43,6.944558],[2.653223,-0.555,6.87],[2.653223,-0.606777,6.69],[2.653223,-0.555,6.51],[2.653223,-0.43,6.435442],[2.653223,-0.305,6.51])),
                    #(true,true,#([2.83,-0.18,6.69],[2.83,-0.253223,6.944558],[2.83,-0.43,7.05],[2.83,-0.606777,6.944558],[2.83,-0.68,6.69],[2.83,-0.606777,6.435442],[2.83,-0.43,6.33],[2.83,-0.253223,6.435442])),
                    #(true,true,#([3.006777,-0.253223,6.69],[3.006777,-0.305,6.87],[3.006777,-0.43,6.944558],[3.006777,-0.555,6.87],[3.006777,-0.606777,6.69],[3.006777,-0.555,6.51],[3.006777,-0.43,6.435442],[3.006777,-0.305,6.51])),
                    #(false,true,#([2.58,-0.43,6.69],[2.653223,-0.253223,6.69],[2.83,-0.18,6.69],[3.006777,-0.253223,6.69],[3.08,-0.43,6.69])),
                    #(false,true,#([2.58,-0.43,6.69],[2.653223,-0.305,6.87],[2.83,-0.253223,6.944558],[3.006777,-0.305,6.87],[3.08,-0.43,6.69])),
                    #(false,true,#([2.58,-0.43,6.69],[2.653223,-0.43,6.944558],[2.83,-0.43,7.05],[3.006777,-0.43,6.944558],[3.08,-0.43,6.69])),
                    #(false,true,#([2.58,-0.43,6.69],[2.653223,-0.555,6.87],[2.83,-0.606777,6.944558],[3.006777,-0.555,6.87],[3.08,-0.43,6.69])),
                    #(false,true,#([2.58,-0.43,6.69],[2.653223,-0.606777,6.69],[2.83,-0.68,6.69],[3.006777,-0.606777,6.69],[3.08,-0.43,6.69])),
                    #(false,true,#([2.58,-0.43,6.69],[2.653223,-0.555,6.51],[2.83,-0.606777,6.435442],[3.006777,-0.555,6.51],[3.08,-0.43,6.69])),
                    #(false,true,#([2.58,-0.43,6.69],[2.653223,-0.43,6.435442],[2.83,-0.43,6.33],[3.006777,-0.43,6.435442],[3.08,-0.43,6.69])),
                    #(false,true,#([2.58,-0.43,6.69],[2.653223,-0.305,6.51],[2.83,-0.253223,6.435442],[3.006777,-0.305,6.51],[3.08,-0.43,6.69]))
                ) "gold_glow" "body" true 0.0
                f.finishModel()
                f.startModel "paradeai4" "The folded-sail spirit" "ai" 4 0.3 [0.69,-0.06,9.22] "A kite-like folded mantle with unequal ribbon limbs and a tilted narrow mask." true
                f.cage "FoldedSail" #(
                    #(true,false,#([-0.37,0.08,0.0],[-0.416863,0.21435,0.0],[-0.53,0.27,0.0],[-0.643137,0.21435,0.0],[-0.69,0.08,0.0],[-0.643137,-0.05435,0.0],[-0.53,-0.11,0.0],[-0.416863,-0.05435,0.0])),
                    #(true,false,#([0.46,0.04,1.6],[0.21397,0.37234,1.6],[-0.38,0.51,1.6],[-0.97397,0.37234,1.6],[-1.22,0.04,1.6],[-0.97397,-0.29234,1.6],[-0.38,-0.43,1.6],[0.21397,-0.29234,1.6])),
                    #(true,false,#([2.93,0.0,4.78],[2.071823,0.601041,4.78],[0.0,0.85,4.78],[-2.071823,0.601041,4.78],[-2.93,0.0,4.78],[-2.071823,-0.601041,4.78],[0.0,-0.85,4.78],[2.071823,-0.601041,4.78])),
                    #(true,false,#([2.2,0.05,6.6],[1.599569,0.58033,6.6],[0.15,0.8,6.6],[-1.299569,0.58033,6.6],[-1.9,0.05,6.6],[-1.299569,-0.48033,6.6],[0.15,-0.7,6.6],[1.599569,-0.48033,6.6])),
                    #(true,false,#([0.84,0.02,8.86],[0.714056,0.267487,8.86],[0.41,0.37,8.86],[0.105944,0.267487,8.86],[-0.02,0.02,8.86],[0.105944,-0.227487,8.86],[0.41,-0.33,8.86],[0.714056,-0.227487,8.86])),
                    #(false,false,#([-0.53,0.08,0.0],[-0.37,0.08,0.0],[0.46,0.04,1.6],[2.93,0.0,4.78],[2.2,0.05,6.6],[0.84,0.02,8.86],[0.41,0.02,8.86])),
                    #(false,false,#([-0.53,0.08,0.0],[-0.416863,0.21435,0.0],[0.21397,0.37234,1.6],[2.071823,0.601041,4.78],[1.599569,0.58033,6.6],[0.714056,0.267487,8.86],[0.41,0.02,8.86])),
                    #(false,false,#([-0.53,0.08,0.0],[-0.53,0.27,0.0],[-0.38,0.51,1.6],[0.0,0.85,4.78],[0.15,0.8,6.6],[0.41,0.37,8.86],[0.41,0.02,8.86])),
                    #(false,false,#([-0.53,0.08,0.0],[-0.643137,0.21435,0.0],[-0.97397,0.37234,1.6],[-2.071823,0.601041,4.78],[-1.299569,0.58033,6.6],[0.105944,0.267487,8.86],[0.41,0.02,8.86])),
                    #(false,false,#([-0.53,0.08,0.0],[-0.69,0.08,0.0],[-1.22,0.04,1.6],[-2.93,0.0,4.78],[-1.9,0.05,6.6],[-0.02,0.02,8.86],[0.41,0.02,8.86])),
                    #(false,false,#([-0.53,0.08,0.0],[-0.643137,-0.05435,0.0],[-0.97397,-0.29234,1.6],[-2.071823,-0.601041,4.78],[-1.299569,-0.48033,6.6],[0.105944,-0.227487,8.86],[0.41,0.02,8.86])),
                    #(false,false,#([-0.53,0.08,0.0],[-0.53,-0.11,0.0],[-0.38,-0.43,1.6],[0.0,-0.85,4.78],[0.15,-0.7,6.6],[0.41,-0.33,8.86],[0.41,0.02,8.86])),
                    #(false,false,#([-0.53,0.08,0.0],[-0.416863,-0.05435,0.0],[0.21397,-0.29234,1.6],[2.071823,-0.601041,4.78],[1.599569,-0.48033,6.6],[0.714056,-0.227487,8.86],[0.41,0.02,8.86]))
                ) "dark" "body" true 0.0
                f.cage "LeftTrailingFold" #(
                    #(true,true,#([-1.393486,0.18,5.47395],[-1.491439,-0.067404,5.504861],[-1.723281,-0.169881,5.591502],[-1.9532,-0.067404,5.683122],[-2.046514,0.18,5.72605],[-1.948561,0.427404,5.695139],[-1.716719,0.529881,5.608498],[-1.4868,0.427404,5.516878])),
                    #(true,true,#([-2.06058,0.233845,3.426973],[-2.209106,-0.110349,3.416132],[-2.557324,-0.249314,3.425131],[-2.901251,-0.101645,3.448697],[-3.03942,0.246155,3.473027],[-2.890894,0.590349,3.483868],[-2.542676,0.729314,3.474869],[-2.198749,0.581645,3.451303])),
                    #(true,true,#([-1.615297,0.445451,0.667875],[-1.655924,0.348094,0.6491],[-1.751659,0.310432,0.619136],[-1.846422,0.354527,0.595537],[-1.884703,0.454549,0.592125],[-1.844076,0.551906,0.6109],[-1.748341,0.589568,0.640864],[-1.653578,0.545473,0.664463])),
                    #(false,true,#([-1.72,0.18,5.6],[-1.393486,0.18,5.47395],[-2.06058,0.233845,3.426973],[-1.615297,0.445451,0.667875],[-1.75,0.45,0.63])),
                    #(false,true,#([-1.72,0.18,5.6],[-1.491439,-0.067404,5.504861],[-2.209106,-0.110349,3.416132],[-1.655924,0.348094,0.6491],[-1.75,0.45,0.63])),
                    #(false,true,#([-1.72,0.18,5.6],[-1.723281,-0.169881,5.591502],[-2.557324,-0.249314,3.425131],[-1.751659,0.310432,0.619136],[-1.75,0.45,0.63])),
                    #(false,true,#([-1.72,0.18,5.6],[-1.9532,-0.067404,5.683122],[-2.901251,-0.101645,3.448697],[-1.846422,0.354527,0.595537],[-1.75,0.45,0.63])),
                    #(false,true,#([-1.72,0.18,5.6],[-2.046514,0.18,5.72605],[-3.03942,0.246155,3.473027],[-1.884703,0.454549,0.592125],[-1.75,0.45,0.63])),
                    #(false,true,#([-1.72,0.18,5.6],[-1.948561,0.427404,5.695139],[-2.890894,0.590349,3.483868],[-1.844076,0.551906,0.6109],[-1.75,0.45,0.63])),
                    #(false,true,#([-1.72,0.18,5.6],[-1.716719,0.529881,5.608498],[-2.542676,0.729314,3.474869],[-1.748341,0.589568,0.640864],[-1.75,0.45,0.63])),
                    #(false,true,#([-1.72,0.18,5.6],[-1.4868,0.427404,5.516878],[-2.198749,0.581645,3.451303],[-1.653578,0.545473,0.664463],[-1.75,0.45,0.63]))
                ) "teal" "body" true 0.0
                f.cage "RightLiftedFold" #(
                    #(true,true,#([1.88271,-0.266791,5.6],[2.033833,-0.183937,5.394924],[2.124132,0.053528,5.309979],[2.100711,0.306499,5.394924],[1.97729,0.426791,5.6],[1.826167,0.343937,5.805076],[1.735868,0.106472,5.890021],[1.759289,-0.146499,5.805076])),
                    #(true,true,#([3.190334,-0.51573,6.497073],[3.450373,-0.427595,6.329906],[3.593037,-0.14756,6.262379],[3.534754,0.160335,6.334047],[3.309666,0.31573,6.502927],[3.049627,0.227595,6.670094],[2.906963,-0.05244,6.737621],[2.965246,-0.360335,6.665953])),
                    #(true,true,#([3.635183,-0.358157,8.317275],[3.758407,-0.325581,8.291127],[3.823986,-0.213584,8.281892],[3.793504,-0.087772,8.29498],[3.684817,-0.021843,8.322725],[3.561593,-0.054419,8.348873],[3.496014,-0.166416,8.358108],[3.526496,-0.292228,8.34502])),
                    #(false,true,#([1.93,0.08,5.6],[1.88271,-0.266791,5.6],[3.190334,-0.51573,6.497073],[3.635183,-0.358157,8.317275],[3.66,-0.19,8.32])),
                    #(false,true,#([1.93,0.08,5.6],[2.033833,-0.183937,5.394924],[3.450373,-0.427595,6.329906],[3.758407,-0.325581,8.291127],[3.66,-0.19,8.32])),
                    #(false,true,#([1.93,0.08,5.6],[2.124132,0.053528,5.309979],[3.593037,-0.14756,6.262379],[3.823986,-0.213584,8.281892],[3.66,-0.19,8.32])),
                    #(false,true,#([1.93,0.08,5.6],[2.100711,0.306499,5.394924],[3.534754,0.160335,6.334047],[3.793504,-0.087772,8.29498],[3.66,-0.19,8.32])),
                    #(false,true,#([1.93,0.08,5.6],[1.97729,0.426791,5.6],[3.309666,0.31573,6.502927],[3.684817,-0.021843,8.322725],[3.66,-0.19,8.32])),
                    #(false,true,#([1.93,0.08,5.6],[1.826167,0.343937,5.805076],[3.049627,0.227595,6.670094],[3.561593,-0.054419,8.348873],[3.66,-0.19,8.32])),
                    #(false,true,#([1.93,0.08,5.6],[1.735868,0.106472,5.890021],[2.906963,-0.05244,6.737621],[3.496014,-0.166416,8.358108],[3.66,-0.19,8.32])),
                    #(false,true,#([1.93,0.08,5.6],[1.759289,-0.146499,5.805076],[2.965246,-0.360335,6.665953],[3.526496,-0.292228,8.34502],[3.66,-0.19,8.32]))
                ) "dark" "body" true 0.0
                f.cage "CurvedNeck" #(
                    #(true,true,#([0.1897,0.02,8.71609],[0.249769,-0.141894,8.68188],[0.403699,-0.208952,8.628995],[0.56132,-0.141894,8.588415],[0.6303,0.02,8.58391],[0.570231,0.181894,8.61812],[0.416301,0.248952,8.671005],[0.25868,0.181894,8.711585])),
                    #(true,true,#([0.387721,-0.044117,9.35939],[0.443435,-0.205016,9.314718],[0.585005,-0.269251,9.232135],[0.729501,-0.199193,9.160017],[0.792279,-0.035883,9.14061],[0.736565,0.125016,9.185282],[0.594995,0.189251,9.267865],[0.450499,0.119193,9.339983])),
                    #(true,true,#([0.73659,-0.077686,9.794602],[0.788043,-0.244761,9.738213],[0.916794,-0.309464,9.624292],[1.047424,-0.233892,9.519573],[1.10341,-0.062314,9.485398],[1.051957,0.104761,9.541787],[0.923206,0.169464,9.655708],[0.792576,0.093892,9.760427])),
                    #(false,true,#([0.41,0.02,8.65],[0.1897,0.02,8.71609],[0.387721,-0.044117,9.35939],[0.73659,-0.077686,9.794602],[0.92,-0.07,9.64])),
                    #(false,true,#([0.41,0.02,8.65],[0.249769,-0.141894,8.68188],[0.443435,-0.205016,9.314718],[0.788043,-0.244761,9.738213],[0.92,-0.07,9.64])),
                    #(false,true,#([0.41,0.02,8.65],[0.403699,-0.208952,8.628995],[0.585005,-0.269251,9.232135],[0.916794,-0.309464,9.624292],[0.92,-0.07,9.64])),
                    #(false,true,#([0.41,0.02,8.65],[0.56132,-0.141894,8.588415],[0.729501,-0.199193,9.160017],[1.047424,-0.233892,9.519573],[0.92,-0.07,9.64])),
                    #(false,true,#([0.41,0.02,8.65],[0.6303,0.02,8.58391],[0.792279,-0.035883,9.14061],[1.10341,-0.062314,9.485398],[0.92,-0.07,9.64])),
                    #(false,true,#([0.41,0.02,8.65],[0.570231,0.181894,8.61812],[0.736565,0.125016,9.185282],[1.051957,0.104761,9.541787],[0.92,-0.07,9.64])),
                    #(false,true,#([0.41,0.02,8.65],[0.416301,0.248952,8.671005],[0.594995,0.189251,9.267865],[0.923206,0.169464,9.655708],[0.92,-0.07,9.64])),
                    #(false,true,#([0.41,0.02,8.65],[0.25868,0.181894,8.711585],[0.450499,0.119193,9.339983],[0.792576,0.093892,9.760427],[0.92,-0.07,9.64]))
                ) "dark" "body" true 0.0
                f.cage "Head" #(
                    #(true,true,#([0.259657,0.255269,10.17595],[0.094467,0.16,10.716263],[0.026043,-0.07,10.940068],[0.094467,-0.3,10.716263],[0.259657,-0.395269,10.17595],[0.424847,-0.3,9.635638],[0.493271,-0.07,9.411833],[0.424847,0.16,9.635638])),
                    #(true,true,#([0.739766,0.39,10.322734],[0.506152,0.255269,11.086852],[0.409386,-0.07,11.403359],[0.506152,-0.395269,11.086852],[0.739766,-0.53,10.322734],[0.97338,-0.395269,9.558617],[1.070146,-0.07,9.24211],[0.97338,0.255269,9.558617])),
                    #(true,true,#([1.219875,0.255269,10.469519],[1.054685,0.16,11.009831],[0.986261,-0.07,11.233636],[1.054685,-0.3,11.009831],[1.219875,-0.395269,10.469519],[1.385065,-0.3,9.929206],[1.453489,-0.07,9.705401],[1.385065,0.16,9.929206])),
                    #(false,true,#([0.06079,-0.07,10.115151],[0.259657,0.255269,10.17595],[0.739766,0.39,10.322734],[1.219875,0.255269,10.469519],[1.418743,-0.07,10.530318])),
                    #(false,true,#([0.06079,-0.07,10.115151],[0.094467,0.16,10.716263],[0.506152,0.255269,11.086852],[1.054685,0.16,11.009831],[1.418743,-0.07,10.530318])),
                    #(false,true,#([0.06079,-0.07,10.115151],[0.026043,-0.07,10.940068],[0.409386,-0.07,11.403359],[0.986261,-0.07,11.233636],[1.418743,-0.07,10.530318])),
                    #(false,true,#([0.06079,-0.07,10.115151],[0.094467,-0.3,10.716263],[0.506152,-0.395269,11.086852],[1.054685,-0.3,11.009831],[1.418743,-0.07,10.530318])),
                    #(false,true,#([0.06079,-0.07,10.115151],[0.259657,-0.395269,10.17595],[0.739766,-0.53,10.322734],[1.219875,-0.395269,10.469519],[1.418743,-0.07,10.530318])),
                    #(false,true,#([0.06079,-0.07,10.115151],[0.424847,-0.3,9.635638],[0.97338,-0.395269,9.558617],[1.385065,-0.3,9.929206],[1.418743,-0.07,10.530318])),
                    #(false,true,#([0.06079,-0.07,10.115151],[0.493271,-0.07,9.411833],[1.070146,-0.07,9.24211],[1.453489,-0.07,9.705401],[1.418743,-0.07,10.530318])),
                    #(false,true,#([0.06079,-0.07,10.115151],[0.424847,0.16,9.635638],[0.97338,0.255269,9.558617],[1.385065,0.16,9.929206],[1.418743,-0.07,10.530318]))
                ) "dark" "head" true 0.0
                f.cage "FacePlate" #(
                    #(true,true,#([0.391518,-0.352721,10.216264],[0.254104,-0.39,10.665728],[0.197185,-0.48,10.851901],[0.254104,-0.57,10.665728],[0.391518,-0.607279,10.216264],[0.528933,-0.57,9.766801],[0.585852,-0.48,9.580628],[0.528933,-0.39,9.766801])),
                    #(true,true,#([0.739766,-0.3,10.322734],[0.545433,-0.352721,10.958371],[0.464937,-0.48,11.221661],[0.545433,-0.607279,10.958371],[0.739766,-0.66,10.322734],[0.9341,-0.607279,9.687098],[1.014596,-0.48,9.423808],[0.9341,-0.352721,9.687098])),
                    #(true,true,#([1.088014,-0.352721,10.429205],[0.950599,-0.39,10.878668],[0.893681,-0.48,11.064841],[0.950599,-0.57,10.878668],[1.088014,-0.607279,10.429205],[1.225429,-0.57,9.979741],[1.282348,-0.48,9.793568],[1.225429,-0.39,9.979741])),
                    #(false,true,#([0.247269,-0.48,10.172163],[0.391518,-0.352721,10.216264],[0.739766,-0.3,10.322734],[1.088014,-0.352721,10.429205],[1.232263,-0.48,10.473306])),
                    #(false,true,#([0.247269,-0.48,10.172163],[0.254104,-0.39,10.665728],[0.545433,-0.352721,10.958371],[0.950599,-0.39,10.878668],[1.232263,-0.48,10.473306])),
                    #(false,true,#([0.247269,-0.48,10.172163],[0.197185,-0.48,10.851901],[0.464937,-0.48,11.221661],[0.893681,-0.48,11.064841],[1.232263,-0.48,10.473306])),
                    #(false,true,#([0.247269,-0.48,10.172163],[0.254104,-0.57,10.665728],[0.545433,-0.607279,10.958371],[0.950599,-0.57,10.878668],[1.232263,-0.48,10.473306])),
                    #(false,true,#([0.247269,-0.48,10.172163],[0.391518,-0.607279,10.216264],[0.739766,-0.66,10.322734],[1.088014,-0.607279,10.429205],[1.232263,-0.48,10.473306])),
                    #(false,true,#([0.247269,-0.48,10.172163],[0.528933,-0.57,9.766801],[0.9341,-0.607279,9.687098],[1.225429,-0.57,9.979741],[1.232263,-0.48,10.473306])),
                    #(false,true,#([0.247269,-0.48,10.172163],[0.585852,-0.48,9.580628],[1.014596,-0.48,9.423808],[1.282348,-0.48,9.793568],[1.232263,-0.48,10.473306])),
                    #(false,true,#([0.247269,-0.48,10.172163],[0.528933,-0.39,9.766801],[0.9341,-0.352721,9.687098],[1.225429,-0.39,9.979741],[1.232263,-0.48,10.473306]))
                ) "ivory_glow" "mask" true 0.0
                f.cage "EyeLeft" #(
                    #(true,true,#([0.390019,-0.533594,10.392737],[0.369407,-0.5664,10.460157],[0.360869,-0.6456,10.488083],[0.369407,-0.7248,10.460157],[0.390019,-0.757606,10.392737],[0.410631,-0.7248,10.325318],[0.419169,-0.6456,10.297392],[0.410631,-0.5664,10.325318])),
                    #(true,true,#([0.473598,-0.4872,10.41829],[0.444448,-0.533594,10.513635],[0.432374,-0.6456,10.553129],[0.444448,-0.757606,10.513635],[0.473598,-0.804,10.41829],[0.502748,-0.757606,10.322944],[0.514823,-0.6456,10.283451],[0.502748,-0.533594,10.322944])),
                    #(true,true,#([0.557177,-0.533594,10.443843],[0.536565,-0.5664,10.511262],[0.528027,-0.6456,10.539188],[0.536565,-0.7248,10.511262],[0.557177,-0.757606,10.443843],[0.57779,-0.7248,10.376423],[0.586327,-0.6456,10.348497],[0.57779,-0.5664,10.376423])),
                    #(false,true,#([0.355399,-0.6456,10.382153],[0.390019,-0.533594,10.392737],[0.473598,-0.4872,10.41829],[0.557177,-0.533594,10.443843],[0.591798,-0.6456,10.454427])),
                    #(false,true,#([0.355399,-0.6456,10.382153],[0.369407,-0.5664,10.460157],[0.444448,-0.533594,10.513635],[0.536565,-0.5664,10.511262],[0.591798,-0.6456,10.454427])),
                    #(false,true,#([0.355399,-0.6456,10.382153],[0.360869,-0.6456,10.488083],[0.432374,-0.6456,10.553129],[0.528027,-0.6456,10.539188],[0.591798,-0.6456,10.454427])),
                    #(false,true,#([0.355399,-0.6456,10.382153],[0.369407,-0.7248,10.460157],[0.444448,-0.757606,10.513635],[0.536565,-0.7248,10.511262],[0.591798,-0.6456,10.454427])),
                    #(false,true,#([0.355399,-0.6456,10.382153],[0.390019,-0.757606,10.392737],[0.473598,-0.804,10.41829],[0.557177,-0.757606,10.443843],[0.591798,-0.6456,10.454427])),
                    #(false,true,#([0.355399,-0.6456,10.382153],[0.410631,-0.7248,10.325318],[0.502748,-0.757606,10.322944],[0.57779,-0.7248,10.376423],[0.591798,-0.6456,10.454427])),
                    #(false,true,#([0.355399,-0.6456,10.382153],[0.419169,-0.6456,10.297392],[0.514823,-0.6456,10.283451],[0.586327,-0.6456,10.348497],[0.591798,-0.6456,10.454427])),
                    #(false,true,#([0.355399,-0.6456,10.382153],[0.410631,-0.5664,10.325318],[0.502748,-0.533594,10.322944],[0.57779,-0.5664,10.376423],[0.591798,-0.6456,10.454427]))
                ) "dark" "mask" true 0.0
                f.cage "EyeRight" #(
                    #(true,true,#([0.823416,-0.533594,10.52524],[0.802804,-0.5664,10.592659],[0.794266,-0.6456,10.620585],[0.802804,-0.7248,10.592659],[0.823416,-0.757606,10.52524],[0.844029,-0.7248,10.45782],[0.852566,-0.6456,10.429894],[0.844029,-0.5664,10.45782])),
                    #(true,true,#([0.906996,-0.4872,10.550793],[0.877846,-0.533594,10.646138],[0.865771,-0.6456,10.685632],[0.877846,-0.757606,10.646138],[0.906996,-0.804,10.550793],[0.936146,-0.757606,10.455447],[0.94822,-0.6456,10.415954],[0.936146,-0.533594,10.455447])),
                    #(true,true,#([0.990575,-0.533594,10.576345],[0.969962,-0.5664,10.643765],[0.961425,-0.6456,10.671691],[0.969962,-0.7248,10.643765],[0.990575,-0.757606,10.576345],[1.011187,-0.7248,10.508926],[1.019725,-0.6456,10.481],[1.011187,-0.5664,10.508926])),
                    #(false,true,#([0.788796,-0.6456,10.514656],[0.823416,-0.533594,10.52524],[0.906996,-0.4872,10.550793],[0.990575,-0.533594,10.576345],[1.025195,-0.6456,10.58693])),
                    #(false,true,#([0.788796,-0.6456,10.514656],[0.802804,-0.5664,10.592659],[0.877846,-0.533594,10.646138],[0.969962,-0.5664,10.643765],[1.025195,-0.6456,10.58693])),
                    #(false,true,#([0.788796,-0.6456,10.514656],[0.794266,-0.6456,10.620585],[0.865771,-0.6456,10.685632],[0.961425,-0.6456,10.671691],[1.025195,-0.6456,10.58693])),
                    #(false,true,#([0.788796,-0.6456,10.514656],[0.802804,-0.7248,10.592659],[0.877846,-0.757606,10.646138],[0.969962,-0.7248,10.643765],[1.025195,-0.6456,10.58693])),
                    #(false,true,#([0.788796,-0.6456,10.514656],[0.823416,-0.757606,10.52524],[0.906996,-0.804,10.550793],[0.990575,-0.757606,10.576345],[1.025195,-0.6456,10.58693])),
                    #(false,true,#([0.788796,-0.6456,10.514656],[0.844029,-0.7248,10.45782],[0.936146,-0.757606,10.455447],[1.011187,-0.7248,10.508926],[1.025195,-0.6456,10.58693])),
                    #(false,true,#([0.788796,-0.6456,10.514656],[0.852566,-0.6456,10.429894],[0.94822,-0.6456,10.415954],[1.019725,-0.6456,10.481],[1.025195,-0.6456,10.58693])),
                    #(false,true,#([0.788796,-0.6456,10.514656],[0.844029,-0.5664,10.45782],[0.936146,-0.533594,10.455447],[1.011187,-0.5664,10.508926],[1.025195,-0.6456,10.58693]))
                ) "dark" "mask" true 0.0
                f.tube "SailFold" #([-0.52,-0.15,0.32],[-0.1,-0.56,3.0],[0.34,-0.83,5.05],[0.47,-0.4,8.6]) 0.12 5 false true "violet_glow" "body"
                f.tube "SleeveTip" #([3.38,-0.32,7.1],[3.58,-0.36,7.7],[3.69,-0.28,8.3]) 0.11 5 false true "gold_glow" "body"
                f.finishModel()
                f.startModel "paradehelper1" "The lantern tender" "helper" 1 0.13 [-0.03,0.0,1.37] "A pear-shaped attendant stretching both hands to guide a small lantern." true
                f.cage "LeftFoot" #(
                    #(true,true,#([-0.298995,0.139706,0.11],[-0.298995,0.09,0.165],[-0.298995,-0.03,0.187782],[-0.298995,-0.15,0.165],[-0.298995,-0.199706,0.11],[-0.298995,-0.15,0.055],[-0.298995,-0.03,0.032218],[-0.298995,0.09,0.055])),
                    #(true,true,#([-0.2,0.21,0.11],[-0.2,0.139706,0.187782],[-0.2,-0.03,0.22],[-0.2,-0.199706,0.187782],[-0.2,-0.27,0.11],[-0.2,-0.199706,0.032218],[-0.2,-0.03,0.0],[-0.2,0.139706,0.032218])),
                    #(true,true,#([-0.101005,0.139706,0.11],[-0.101005,0.09,0.165],[-0.101005,-0.03,0.187782],[-0.101005,-0.15,0.165],[-0.101005,-0.199706,0.11],[-0.101005,-0.15,0.055],[-0.101005,-0.03,0.032218],[-0.101005,0.09,0.055])),
                    #(false,true,#([-0.34,-0.03,0.11],[-0.298995,0.139706,0.11],[-0.2,0.21,0.11],[-0.101005,0.139706,0.11],[-0.06,-0.03,0.11])),
                    #(false,true,#([-0.34,-0.03,0.11],[-0.298995,0.09,0.165],[-0.2,0.139706,0.187782],[-0.101005,0.09,0.165],[-0.06,-0.03,0.11])),
                    #(false,true,#([-0.34,-0.03,0.11],[-0.298995,-0.03,0.187782],[-0.2,-0.03,0.22],[-0.101005,-0.03,0.187782],[-0.06,-0.03,0.11])),
                    #(false,true,#([-0.34,-0.03,0.11],[-0.298995,-0.15,0.165],[-0.2,-0.199706,0.187782],[-0.101005,-0.15,0.165],[-0.06,-0.03,0.11])),
                    #(false,true,#([-0.34,-0.03,0.11],[-0.298995,-0.199706,0.11],[-0.2,-0.27,0.11],[-0.101005,-0.199706,0.11],[-0.06,-0.03,0.11])),
                    #(false,true,#([-0.34,-0.03,0.11],[-0.298995,-0.15,0.055],[-0.2,-0.199706,0.032218],[-0.101005,-0.15,0.055],[-0.06,-0.03,0.11])),
                    #(false,true,#([-0.34,-0.03,0.11],[-0.298995,-0.03,0.032218],[-0.2,-0.03,0.0],[-0.101005,-0.03,0.032218],[-0.06,-0.03,0.11])),
                    #(false,true,#([-0.34,-0.03,0.11],[-0.298995,0.09,0.055],[-0.2,0.139706,0.032218],[-0.101005,0.09,0.055],[-0.06,-0.03,0.11]))
                ) "ivory_glow" "body" true 0.0
                f.cage "RightFoot" #(
                    #(true,true,#([0.131005,0.249706,0.11],[0.131005,0.2,0.165],[0.131005,0.08,0.187782],[0.131005,-0.04,0.165],[0.131005,-0.089706,0.11],[0.131005,-0.04,0.055],[0.131005,0.08,0.032218],[0.131005,0.2,0.055])),
                    #(true,true,#([0.23,0.32,0.11],[0.23,0.249706,0.187782],[0.23,0.08,0.22],[0.23,-0.089706,0.187782],[0.23,-0.16,0.11],[0.23,-0.089706,0.032218],[0.23,0.08,0.0],[0.23,0.249706,0.032218])),
                    #(true,true,#([0.328995,0.249706,0.11],[0.328995,0.2,0.165],[0.328995,0.08,0.187782],[0.328995,-0.04,0.165],[0.328995,-0.089706,0.11],[0.328995,-0.04,0.055],[0.328995,0.08,0.032218],[0.328995,0.2,0.055])),
                    #(false,true,#([0.09,0.08,0.11],[0.131005,0.249706,0.11],[0.23,0.32,0.11],[0.328995,0.249706,0.11],[0.37,0.08,0.11])),
                    #(false,true,#([0.09,0.08,0.11],[0.131005,0.2,0.165],[0.23,0.249706,0.187782],[0.328995,0.2,0.165],[0.37,0.08,0.11])),
                    #(false,true,#([0.09,0.08,0.11],[0.131005,0.08,0.187782],[0.23,0.08,0.22],[0.328995,0.08,0.187782],[0.37,0.08,0.11])),
                    #(false,true,#([0.09,0.08,0.11],[0.131005,-0.04,0.165],[0.23,-0.089706,0.187782],[0.328995,-0.04,0.165],[0.37,0.08,0.11])),
                    #(false,true,#([0.09,0.08,0.11],[0.131005,-0.089706,0.11],[0.23,-0.16,0.11],[0.328995,-0.089706,0.11],[0.37,0.08,0.11])),
                    #(false,true,#([0.09,0.08,0.11],[0.131005,-0.04,0.055],[0.23,-0.089706,0.032218],[0.328995,-0.04,0.055],[0.37,0.08,0.11])),
                    #(false,true,#([0.09,0.08,0.11],[0.131005,0.08,0.032218],[0.23,0.08,0.0],[0.328995,0.08,0.032218],[0.37,0.08,0.11])),
                    #(false,true,#([0.09,0.08,0.11],[0.131005,0.2,0.055],[0.23,0.249706,0.032218],[0.328995,0.2,0.055],[0.37,0.08,0.11]))
                ) "ivory_glow" "body" true 0.0
                f.cage "LeftLeg" #(
                    #(true,true,#([-0.319918,0.0,0.145559],[-0.285027,-0.084621,0.153119],[-0.200328,-0.119673,0.158852],[-0.115437,-0.084621,0.1594],[-0.080082,0.0,0.154441],[-0.114973,0.084621,0.146881],[-0.199672,0.119673,0.141148],[-0.284563,0.084621,0.1406])),
                    #(true,true,#([-0.339371,0.020569,0.432758],[-0.301964,-0.071517,0.428207],[-0.210685,-0.109993,0.418848],[-0.119005,-0.072321,0.410164],[-0.080629,0.019431,0.407242],[-0.118036,0.111517,0.411793],[-0.209315,0.149993,0.421152],[-0.300995,0.112321,0.429836])),
                    #(true,true,#([-0.305929,-0.000378,0.664709],[-0.265193,-0.10588,0.644962],[-0.162836,-0.14936,0.616451],[-0.058818,-0.105346,0.595876],[-0.014071,0.000378,0.595291],[-0.054807,0.10588,0.615038],[-0.157164,0.14936,0.643549],[-0.261182,0.105346,0.664124])),
                    #(false,true,#([-0.2,0.0,0.15],[-0.319918,0.0,0.145559],[-0.339371,0.020569,0.432758],[-0.305929,-0.000378,0.664709],[-0.16,0.0,0.63])),
                    #(false,true,#([-0.2,0.0,0.15],[-0.285027,-0.084621,0.153119],[-0.301964,-0.071517,0.428207],[-0.265193,-0.10588,0.644962],[-0.16,0.0,0.63])),
                    #(false,true,#([-0.2,0.0,0.15],[-0.200328,-0.119673,0.158852],[-0.210685,-0.109993,0.418848],[-0.162836,-0.14936,0.616451],[-0.16,0.0,0.63])),
                    #(false,true,#([-0.2,0.0,0.15],[-0.115437,-0.084621,0.1594],[-0.119005,-0.072321,0.410164],[-0.058818,-0.105346,0.595876],[-0.16,0.0,0.63])),
                    #(false,true,#([-0.2,0.0,0.15],[-0.080082,0.0,0.154441],[-0.080629,0.019431,0.407242],[-0.014071,0.000378,0.595291],[-0.16,0.0,0.63])),
                    #(false,true,#([-0.2,0.0,0.15],[-0.114973,0.084621,0.146881],[-0.118036,0.111517,0.411793],[-0.054807,0.10588,0.615038],[-0.16,0.0,0.63])),
                    #(false,true,#([-0.2,0.0,0.15],[-0.199672,0.119673,0.141148],[-0.209315,0.149993,0.421152],[-0.157164,0.14936,0.643549],[-0.16,0.0,0.63])),
                    #(false,true,#([-0.2,0.0,0.15],[-0.284563,0.084621,0.1406],[-0.300995,0.112321,0.429836],[-0.261182,0.105346,0.664124],[-0.16,0.0,0.63]))
                ) "ivory_glow" "body" true 0.0
                f.cage "RightLeg" #(
                    #(true,true,#([0.11,0.09,0.15],[0.145147,0.005335,0.144356],[0.23,-0.029734,0.142018],[0.314853,0.005335,0.144356],[0.35,0.09,0.15],[0.314853,0.174665,0.155644],[0.23,0.209734,0.157982],[0.145147,0.174665,0.155644])),
                    #(true,true,#([0.101988,0.072889,0.427535],[0.140464,-0.01825,0.416906],[0.231389,-0.057694,0.425662],[0.3215,-0.022336,0.448675],[0.358012,0.067111,0.472465],[0.319536,0.15825,0.483094],[0.228611,0.197694,0.474338],[0.1385,0.162336,0.451325])),
                    #(true,true,#([0.009072,0.009714,0.609551],[0.05483,-0.094165,0.592356],[0.156337,-0.142883,0.614786],[0.254132,-0.107902,0.663702],[0.290928,-0.009714,0.710449],[0.24517,0.094165,0.727644],[0.143663,0.142883,0.705214],[0.045868,0.107902,0.656298])),
                    #(false,true,#([0.23,0.09,0.15],[0.11,0.09,0.15],[0.101988,0.072889,0.427535],[0.009072,0.009714,0.609551],[0.15,0.0,0.66])),
                    #(false,true,#([0.23,0.09,0.15],[0.145147,0.005335,0.144356],[0.140464,-0.01825,0.416906],[0.05483,-0.094165,0.592356],[0.15,0.0,0.66])),
                    #(false,true,#([0.23,0.09,0.15],[0.23,-0.029734,0.142018],[0.231389,-0.057694,0.425662],[0.156337,-0.142883,0.614786],[0.15,0.0,0.66])),
                    #(false,true,#([0.23,0.09,0.15],[0.314853,0.005335,0.144356],[0.3215,-0.022336,0.448675],[0.254132,-0.107902,0.663702],[0.15,0.0,0.66])),
                    #(false,true,#([0.23,0.09,0.15],[0.35,0.09,0.15],[0.358012,0.067111,0.472465],[0.290928,-0.009714,0.710449],[0.15,0.0,0.66])),
                    #(false,true,#([0.23,0.09,0.15],[0.314853,0.174665,0.155644],[0.319536,0.15825,0.483094],[0.24517,0.094165,0.727644],[0.15,0.0,0.66])),
                    #(false,true,#([0.23,0.09,0.15],[0.23,0.209734,0.157982],[0.228611,0.197694,0.474338],[0.143663,0.142883,0.705214],[0.15,0.0,0.66])),
                    #(false,true,#([0.23,0.09,0.15],[0.145147,0.174665,0.155644],[0.1385,0.162336,0.451325],[0.045868,0.107902,0.656298],[0.15,0.0,0.66]))
                ) "ivory_glow" "body" true 0.0
                f.cage "PearBody" #(
                    #(true,true,#([0.27,0.0,0.43],[0.190919,0.155563,0.43],[0.0,0.22,0.43],[-0.190919,0.155563,0.43],[-0.27,0.0,0.43],[-0.190919,-0.155563,0.43],[0.0,-0.22,0.43],[0.190919,-0.155563,0.43])),
                    #(true,true,#([0.38,0.0,0.71],[0.268701,0.205061,0.71],[0.0,0.29,0.71],[-0.268701,0.205061,0.71],[-0.38,0.0,0.71],[-0.268701,-0.205061,0.71],[0.0,-0.29,0.71],[0.268701,-0.205061,0.71])),
                    #(true,true,#([0.27,0.0,1.12],[0.190919,0.155563,1.12],[0.0,0.22,1.12],[-0.190919,0.155563,1.12],[-0.27,0.0,1.12],[-0.190919,-0.155563,1.12],[0.0,-0.22,1.12],[0.190919,-0.155563,1.12])),
                    #(true,true,#([0.14,0.0,1.37],[0.098995,0.098995,1.37],[0.0,0.14,1.37],[-0.098995,0.098995,1.37],[-0.14,0.0,1.37],[-0.098995,-0.098995,1.37],[0.0,-0.14,1.37],[0.098995,-0.098995,1.37])),
                    #(false,true,#([0.0,0.0,0.43],[0.27,0.0,0.43],[0.38,0.0,0.71],[0.27,0.0,1.12],[0.14,0.0,1.37],[0.0,0.0,1.37])),
                    #(false,true,#([0.0,0.0,0.43],[0.190919,0.155563,0.43],[0.268701,0.205061,0.71],[0.190919,0.155563,1.12],[0.098995,0.098995,1.37],[0.0,0.0,1.37])),
                    #(false,true,#([0.0,0.0,0.43],[0.0,0.22,0.43],[0.0,0.29,0.71],[0.0,0.22,1.12],[0.0,0.14,1.37],[0.0,0.0,1.37])),
                    #(false,true,#([0.0,0.0,0.43],[-0.190919,0.155563,0.43],[-0.268701,0.205061,0.71],[-0.190919,0.155563,1.12],[-0.098995,0.098995,1.37],[0.0,0.0,1.37])),
                    #(false,true,#([0.0,0.0,0.43],[-0.27,0.0,0.43],[-0.38,0.0,0.71],[-0.27,0.0,1.12],[-0.14,0.0,1.37],[0.0,0.0,1.37])),
                    #(false,true,#([0.0,0.0,0.43],[-0.190919,-0.155563,0.43],[-0.268701,-0.205061,0.71],[-0.190919,-0.155563,1.12],[-0.098995,-0.098995,1.37],[0.0,0.0,1.37])),
                    #(false,true,#([0.0,0.0,0.43],[0.0,-0.22,0.43],[0.0,-0.29,0.71],[0.0,-0.22,1.12],[0.0,-0.14,1.37],[0.0,0.0,1.37])),
                    #(false,true,#([0.0,0.0,0.43],[0.190919,-0.155563,0.43],[0.268701,-0.205061,0.71],[0.190919,-0.155563,1.12],[0.098995,-0.098995,1.37],[0.0,0.0,1.37]))
                ) "ivory_glow" "body" true 0.0
                f.cage "NearArm" #(
                    #(true,true,#([0.1964,-0.12176,1.15],[0.275026,-0.129454,1.103159],[0.34485,-0.073031,1.083757],[0.36497,0.014456,1.103159],[0.3236,0.08176,1.15],[0.244974,0.089454,1.196841],[0.17515,0.033031,1.216243],[0.15503,-0.054456,1.196841])),
                    #(true,true,#([0.529391,-0.306137,1.724384],[0.595969,-0.313139,1.687287],[0.653193,-0.265582,1.669353],[0.667541,-0.191323,1.681087],[0.630609,-0.133863,1.715616],[0.564031,-0.126861,1.752713],[0.506807,-0.174418,1.770647],[0.492459,-0.248677,1.758913])),
                    #(true,true,#([0.738957,-0.364049,2.127563],[0.796421,-0.370369,2.097725],[0.844265,-0.32961,2.080936],[0.854464,-0.265648,2.08703],[0.821043,-0.215951,2.112437],[0.763579,-0.209631,2.142275],[0.715735,-0.25039,2.159064],[0.705536,-0.314352,2.15297])),
                    #(false,true,#([0.26,-0.02,1.15],[0.1964,-0.12176,1.15],[0.529391,-0.306137,1.724384],[0.738957,-0.364049,2.127563],[0.78,-0.29,2.12])),
                    #(false,true,#([0.26,-0.02,1.15],[0.275026,-0.129454,1.103159],[0.595969,-0.313139,1.687287],[0.796421,-0.370369,2.097725],[0.78,-0.29,2.12])),
                    #(false,true,#([0.26,-0.02,1.15],[0.34485,-0.073031,1.083757],[0.653193,-0.265582,1.669353],[0.844265,-0.32961,2.080936],[0.78,-0.29,2.12])),
                    #(false,true,#([0.26,-0.02,1.15],[0.36497,0.014456,1.103159],[0.667541,-0.191323,1.681087],[0.854464,-0.265648,2.08703],[0.78,-0.29,2.12])),
                    #(false,true,#([0.26,-0.02,1.15],[0.3236,0.08176,1.15],[0.630609,-0.133863,1.715616],[0.821043,-0.215951,2.112437],[0.78,-0.29,2.12])),
                    #(false,true,#([0.26,-0.02,1.15],[0.244974,0.089454,1.196841],[0.564031,-0.126861,1.752713],[0.763579,-0.209631,2.142275],[0.78,-0.29,2.12])),
                    #(false,true,#([0.26,-0.02,1.15],[0.17515,0.033031,1.216243],[0.506807,-0.174418,1.770647],[0.715735,-0.25039,2.159064],[0.78,-0.29,2.12])),
                    #(false,true,#([0.26,-0.02,1.15],[0.15503,-0.054456,1.196841],[0.492459,-0.248677,1.758913],[0.705536,-0.314352,2.15297],[0.78,-0.29,2.12]))
                ) "ivory_glow" "body" true 0.0
                f.cage "FarArm" #(
                    #(true,true,#([-0.351627,-0.063812,1.12],[-0.293938,-0.089592,1.053346],[-0.210511,-0.06289,1.025738],[-0.150216,0.000652,1.053346],[-0.148373,0.063812,1.12],[-0.206062,0.089592,1.186654],[-0.289489,0.06289,1.214262],[-0.349784,-0.000652,1.186654])),
                    #(true,true,#([-0.04411,-0.502429,1.545377],[0.004153,-0.524089,1.490065],[0.061699,-0.490633,1.452289],[0.094818,-0.421659,1.454177],[0.08411,-0.357571,1.494623],[0.035847,-0.335911,1.549935],[-0.021699,-0.369367,1.587711],[-0.054818,-0.438341,1.585823])),
                    #(true,true,#([0.578658,-0.445909,2.063574],[0.619894,-0.46436,2.016761],[0.655334,-0.433394,1.971845],[0.664218,-0.37115,1.955138],[0.641342,-0.314091,1.976426],[0.600106,-0.29564,2.023239],[0.564666,-0.326606,2.068155],[0.555782,-0.38885,2.084862])),
                    #(false,true,#([-0.25,0.0,1.12],[-0.351627,-0.063812,1.12],[-0.04411,-0.502429,1.545377],[0.578658,-0.445909,2.063574],[0.61,-0.38,2.02])),
                    #(false,true,#([-0.25,0.0,1.12],[-0.293938,-0.089592,1.053346],[0.004153,-0.524089,1.490065],[0.619894,-0.46436,2.016761],[0.61,-0.38,2.02])),
                    #(false,true,#([-0.25,0.0,1.12],[-0.210511,-0.06289,1.025738],[0.061699,-0.490633,1.452289],[0.655334,-0.433394,1.971845],[0.61,-0.38,2.02])),
                    #(false,true,#([-0.25,0.0,1.12],[-0.150216,0.000652,1.053346],[0.094818,-0.421659,1.454177],[0.664218,-0.37115,1.955138],[0.61,-0.38,2.02])),
                    #(false,true,#([-0.25,0.0,1.12],[-0.148373,0.063812,1.12],[0.08411,-0.357571,1.494623],[0.641342,-0.314091,1.976426],[0.61,-0.38,2.02])),
                    #(false,true,#([-0.25,0.0,1.12],[-0.206062,0.089592,1.186654],[0.035847,-0.335911,1.549935],[0.600106,-0.29564,2.023239],[0.61,-0.38,2.02])),
                    #(false,true,#([-0.25,0.0,1.12],[-0.289489,0.06289,1.214262],[-0.021699,-0.369367,1.587711],[0.564666,-0.326606,2.068155],[0.61,-0.38,2.02])),
                    #(false,true,#([-0.25,0.0,1.12],[-0.349784,-0.000652,1.186654],[-0.054818,-0.438341,1.585823],[0.555782,-0.38885,2.084862],[0.61,-0.38,2.02]))
                ) "ivory_glow" "body" true 0.0
                f.cage "NearHand" #(
                    #(true,true,#([0.712218,-0.219289,2.12],[0.712218,-0.24,2.195],[0.712218,-0.29,2.226066],[0.712218,-0.34,2.195],[0.712218,-0.360711,2.12],[0.712218,-0.34,2.045],[0.712218,-0.29,2.013934],[0.712218,-0.24,2.045])),
                    #(true,true,#([0.79,-0.19,2.12],[0.79,-0.219289,2.226066],[0.79,-0.29,2.27],[0.79,-0.360711,2.226066],[0.79,-0.39,2.12],[0.79,-0.360711,2.013934],[0.79,-0.29,1.97],[0.79,-0.219289,2.013934])),
                    #(true,true,#([0.867782,-0.219289,2.12],[0.867782,-0.24,2.195],[0.867782,-0.29,2.226066],[0.867782,-0.34,2.195],[0.867782,-0.360711,2.12],[0.867782,-0.34,2.045],[0.867782,-0.29,2.013934],[0.867782,-0.24,2.045])),
                    #(false,true,#([0.68,-0.29,2.12],[0.712218,-0.219289,2.12],[0.79,-0.19,2.12],[0.867782,-0.219289,2.12],[0.9,-0.29,2.12])),
                    #(false,true,#([0.68,-0.29,2.12],[0.712218,-0.24,2.195],[0.79,-0.219289,2.226066],[0.867782,-0.24,2.195],[0.9,-0.29,2.12])),
                    #(false,true,#([0.68,-0.29,2.12],[0.712218,-0.29,2.226066],[0.79,-0.29,2.27],[0.867782,-0.29,2.226066],[0.9,-0.29,2.12])),
                    #(false,true,#([0.68,-0.29,2.12],[0.712218,-0.34,2.195],[0.79,-0.360711,2.226066],[0.867782,-0.34,2.195],[0.9,-0.29,2.12])),
                    #(false,true,#([0.68,-0.29,2.12],[0.712218,-0.360711,2.12],[0.79,-0.39,2.12],[0.867782,-0.360711,2.12],[0.9,-0.29,2.12])),
                    #(false,true,#([0.68,-0.29,2.12],[0.712218,-0.34,2.045],[0.79,-0.360711,2.013934],[0.867782,-0.34,2.045],[0.9,-0.29,2.12])),
                    #(false,true,#([0.68,-0.29,2.12],[0.712218,-0.29,2.013934],[0.79,-0.29,1.97],[0.867782,-0.29,2.013934],[0.9,-0.29,2.12])),
                    #(false,true,#([0.68,-0.29,2.12],[0.712218,-0.24,2.045],[0.79,-0.219289,2.013934],[0.867782,-0.24,2.045],[0.9,-0.29,2.12]))
                ) "ivory_glow" "body" true 0.0
                f.cage "FarHand" #(
                    #(true,true,#([0.545147,-0.309289,2.04],[0.545147,-0.33,2.105],[0.545147,-0.38,2.131924],[0.545147,-0.43,2.105],[0.545147,-0.450711,2.04],[0.545147,-0.43,1.975],[0.545147,-0.38,1.948076],[0.545147,-0.33,1.975])),
                    #(true,true,#([0.63,-0.28,2.04],[0.63,-0.309289,2.131924],[0.63,-0.38,2.17],[0.63,-0.450711,2.131924],[0.63,-0.48,2.04],[0.63,-0.450711,1.948076],[0.63,-0.38,1.91],[0.63,-0.309289,1.948076])),
                    #(true,true,#([0.714853,-0.309289,2.04],[0.714853,-0.33,2.105],[0.714853,-0.38,2.131924],[0.714853,-0.43,2.105],[0.714853,-0.450711,2.04],[0.714853,-0.43,1.975],[0.714853,-0.38,1.948076],[0.714853,-0.33,1.975])),
                    #(false,true,#([0.51,-0.38,2.04],[0.545147,-0.309289,2.04],[0.63,-0.28,2.04],[0.714853,-0.309289,2.04],[0.75,-0.38,2.04])),
                    #(false,true,#([0.51,-0.38,2.04],[0.545147,-0.33,2.105],[0.63,-0.309289,2.131924],[0.714853,-0.33,2.105],[0.75,-0.38,2.04])),
                    #(false,true,#([0.51,-0.38,2.04],[0.545147,-0.38,2.131924],[0.63,-0.38,2.17],[0.714853,-0.38,2.131924],[0.75,-0.38,2.04])),
                    #(false,true,#([0.51,-0.38,2.04],[0.545147,-0.43,2.105],[0.63,-0.450711,2.131924],[0.714853,-0.43,2.105],[0.75,-0.38,2.04])),
                    #(false,true,#([0.51,-0.38,2.04],[0.545147,-0.450711,2.04],[0.63,-0.48,2.04],[0.714853,-0.450711,2.04],[0.75,-0.38,2.04])),
                    #(false,true,#([0.51,-0.38,2.04],[0.545147,-0.43,1.975],[0.63,-0.450711,1.948076],[0.714853,-0.43,1.975],[0.75,-0.38,2.04])),
                    #(false,true,#([0.51,-0.38,2.04],[0.545147,-0.38,1.948076],[0.63,-0.38,1.91],[0.714853,-0.38,1.948076],[0.75,-0.38,2.04])),
                    #(false,true,#([0.51,-0.38,2.04],[0.545147,-0.33,1.975],[0.63,-0.309289,1.948076],[0.714853,-0.33,1.975],[0.75,-0.38,2.04]))
                ) "ivory_glow" "body" true 0.0
                f.cage "Head" #(
                    #(true,true,#([-0.57513,0.282843,1.893289],[-0.633302,0.2,2.2232],[-0.657398,0.0,2.359854],[-0.633302,-0.2,2.2232],[-0.57513,-0.282843,1.893289],[-0.516958,-0.2,1.563379],[-0.492862,0.0,1.426725],[-0.516958,0.2,1.563379])),
                    #(true,true,#([-0.185166,0.4,1.96205],[-0.267434,0.282843,2.428615],[-0.30151,0.0,2.621872],[-0.267434,-0.282843,2.428615],[-0.185166,-0.4,1.96205],[-0.102898,-0.282843,1.495486],[-0.068821,0.0,1.302229],[-0.102898,0.282843,1.495486])),
                    #(true,true,#([0.204798,0.282843,2.030812],[0.146626,0.2,2.360722],[0.12253,0.0,2.497376],[0.146626,-0.2,2.360722],[0.204798,-0.282843,2.030812],[0.262971,-0.2,1.700901],[0.287066,0.0,1.564247],[0.262971,0.2,1.700901])),
                    #(false,true,#([-0.736658,0.0,1.864807],[-0.57513,0.282843,1.893289],[-0.185166,0.4,1.96205],[0.204798,0.282843,2.030812],[0.366327,0.0,2.059293])),
                    #(false,true,#([-0.736658,0.0,1.864807],[-0.633302,0.2,2.2232],[-0.267434,0.282843,2.428615],[0.146626,0.2,2.360722],[0.366327,0.0,2.059293])),
                    #(false,true,#([-0.736658,0.0,1.864807],[-0.657398,0.0,2.359854],[-0.30151,0.0,2.621872],[0.12253,0.0,2.497376],[0.366327,0.0,2.059293])),
                    #(false,true,#([-0.736658,0.0,1.864807],[-0.633302,-0.2,2.2232],[-0.267434,-0.282843,2.428615],[0.146626,-0.2,2.360722],[0.366327,0.0,2.059293])),
                    #(false,true,#([-0.736658,0.0,1.864807],[-0.57513,-0.282843,1.893289],[-0.185166,-0.4,1.96205],[0.204798,-0.282843,2.030812],[0.366327,0.0,2.059293])),
                    #(false,true,#([-0.736658,0.0,1.864807],[-0.516958,-0.2,1.563379],[-0.102898,-0.282843,1.495486],[0.262971,-0.2,1.700901],[0.366327,0.0,2.059293])),
                    #(false,true,#([-0.736658,0.0,1.864807],[-0.492862,0.0,1.426725],[-0.068821,0.0,1.302229],[0.287066,0.0,1.564247],[0.366327,0.0,2.059293])),
                    #(false,true,#([-0.736658,0.0,1.864807],[-0.516958,0.2,1.563379],[-0.102898,0.282843,1.495486],[0.262971,0.2,1.700901],[0.366327,0.0,2.059293]))
                ) "cream" "head" true 0.0
                f.cage "FacePlate" #(
                    #(true,true,#([-0.470675,-0.258076,1.911707],[-0.515824,-0.285,2.167757],[-0.534525,-0.35,2.273817],[-0.515824,-0.415,2.167757],[-0.470675,-0.441924,1.911707],[-0.425527,-0.415,1.655657],[-0.406826,-0.35,1.549597],[-0.425527,-0.285,1.655657])),
                    #(true,true,#([-0.185166,-0.22,1.96205],[-0.249016,-0.258076,2.32416],[-0.275463,-0.35,2.47415],[-0.249016,-0.441924,2.32416],[-0.185166,-0.48,1.96205],[-0.121316,-0.441924,1.59994],[-0.094869,-0.35,1.44995],[-0.121316,-0.258076,1.59994])),
                    #(true,true,#([0.100344,-0.258076,2.012393],[0.055195,-0.285,2.268443],[0.036494,-0.35,2.374503],[0.055195,-0.415,2.268443],[0.100344,-0.441924,2.012393],[0.145492,-0.415,1.756343],[0.164194,-0.35,1.650283],[0.145492,-0.285,1.756343])),
                    #(false,true,#([-0.588937,-0.35,1.890855],[-0.470675,-0.258076,1.911707],[-0.185166,-0.22,1.96205],[0.100344,-0.258076,2.012393],[0.218605,-0.35,2.033246])),
                    #(false,true,#([-0.588937,-0.35,1.890855],[-0.515824,-0.285,2.167757],[-0.249016,-0.258076,2.32416],[0.055195,-0.285,2.268443],[0.218605,-0.35,2.033246])),
                    #(false,true,#([-0.588937,-0.35,1.890855],[-0.534525,-0.35,2.273817],[-0.275463,-0.35,2.47415],[0.036494,-0.35,2.374503],[0.218605,-0.35,2.033246])),
                    #(false,true,#([-0.588937,-0.35,1.890855],[-0.515824,-0.415,2.167757],[-0.249016,-0.441924,2.32416],[0.055195,-0.415,2.268443],[0.218605,-0.35,2.033246])),
                    #(false,true,#([-0.588937,-0.35,1.890855],[-0.470675,-0.441924,1.911707],[-0.185166,-0.48,1.96205],[0.100344,-0.441924,2.012393],[0.218605,-0.35,2.033246])),
                    #(false,true,#([-0.588937,-0.35,1.890855],[-0.425527,-0.415,1.655657],[-0.121316,-0.441924,1.59994],[0.145492,-0.415,1.756343],[0.218605,-0.35,2.033246])),
                    #(false,true,#([-0.588937,-0.35,1.890855],[-0.406826,-0.35,1.549597],[-0.094869,-0.35,1.44995],[0.164194,-0.35,1.650283],[0.218605,-0.35,2.033246])),
                    #(false,true,#([-0.588937,-0.35,1.890855],[-0.425527,-0.285,1.655657],[-0.121316,-0.258076,1.59994],[0.145492,-0.285,1.756343],[0.218605,-0.35,2.033246]))
                ) "ivory_glow" "mask" true 0.0
                f.cage "EyeLeft" #(
                    #(true,true,#([-0.447601,-0.388707,2.01082],[-0.458019,-0.4124,2.069908],[-0.462335,-0.4696,2.094384],[-0.458019,-0.5268,2.069908],[-0.447601,-0.550493,2.01082],[-0.437182,-0.5268,1.951731],[-0.432866,-0.4696,1.927256],[-0.437182,-0.4124,1.951731])),
                    #(true,true,#([-0.379079,-0.3552,2.022902],[-0.393813,-0.388707,2.106466],[-0.399916,-0.4696,2.141079],[-0.393813,-0.550493,2.106466],[-0.379079,-0.584,2.022902],[-0.364344,-0.550493,1.939338],[-0.358241,-0.4696,1.904725],[-0.364344,-0.388707,1.939338])),
                    #(true,true,#([-0.310557,-0.388707,2.034984],[-0.320976,-0.4124,2.094073],[-0.325291,-0.4696,2.118548],[-0.320976,-0.5268,2.094073],[-0.310557,-0.550493,2.034984],[-0.300138,-0.5268,1.975896],[-0.295822,-0.4696,1.951421],[-0.300138,-0.4124,1.975896])),
                    #(false,true,#([-0.475984,-0.4696,2.005815],[-0.447601,-0.388707,2.01082],[-0.379079,-0.3552,2.022902],[-0.310557,-0.388707,2.034984],[-0.282173,-0.4696,2.039989])),
                    #(false,true,#([-0.475984,-0.4696,2.005815],[-0.458019,-0.4124,2.069908],[-0.393813,-0.388707,2.106466],[-0.320976,-0.4124,2.094073],[-0.282173,-0.4696,2.039989])),
                    #(false,true,#([-0.475984,-0.4696,2.005815],[-0.462335,-0.4696,2.094384],[-0.399916,-0.4696,2.141079],[-0.325291,-0.4696,2.118548],[-0.282173,-0.4696,2.039989])),
                    #(false,true,#([-0.475984,-0.4696,2.005815],[-0.458019,-0.5268,2.069908],[-0.393813,-0.550493,2.106466],[-0.320976,-0.5268,2.094073],[-0.282173,-0.4696,2.039989])),
                    #(false,true,#([-0.475984,-0.4696,2.005815],[-0.447601,-0.550493,2.01082],[-0.379079,-0.584,2.022902],[-0.310557,-0.550493,2.034984],[-0.282173,-0.4696,2.039989])),
                    #(false,true,#([-0.475984,-0.4696,2.005815],[-0.437182,-0.5268,1.951731],[-0.364344,-0.550493,1.939338],[-0.300138,-0.5268,1.975896],[-0.282173,-0.4696,2.039989])),
                    #(false,true,#([-0.475984,-0.4696,2.005815],[-0.432866,-0.4696,1.927256],[-0.358241,-0.4696,1.904725],[-0.295822,-0.4696,1.951421],[-0.282173,-0.4696,2.039989])),
                    #(false,true,#([-0.475984,-0.4696,2.005815],[-0.437182,-0.4124,1.951731],[-0.364344,-0.388707,1.939338],[-0.300138,-0.4124,1.975896],[-0.282173,-0.4696,2.039989]))
                ) "dark" "mask" true 0.0
                f.cage "EyeRight" #(
                    #(true,true,#([-0.092282,-0.388707,2.073472],[-0.102701,-0.4124,2.132561],[-0.107016,-0.4696,2.157036],[-0.102701,-0.5268,2.132561],[-0.092282,-0.550493,2.073472],[-0.081863,-0.5268,2.014384],[-0.077547,-0.4696,1.989908],[-0.081863,-0.4124,2.014384])),
                    #(true,true,#([-0.02376,-0.3552,2.085554],[-0.038494,-0.388707,2.169118],[-0.044598,-0.4696,2.203731],[-0.038494,-0.550493,2.169118],[-0.02376,-0.584,2.085554],[-0.009025,-0.550493,2.001991],[-0.002922,-0.4696,1.967378],[-0.009025,-0.388707,2.001991])),
                    #(true,true,#([0.044762,-0.388707,2.097637],[0.034343,-0.4124,2.156725],[0.030027,-0.4696,2.181201],[0.034343,-0.5268,2.156725],[0.044762,-0.550493,2.097637],[0.055181,-0.5268,2.038548],[0.059497,-0.4696,2.014073],[0.055181,-0.4124,2.038548])),
                    #(false,true,#([-0.120665,-0.4696,2.068467],[-0.092282,-0.388707,2.073472],[-0.02376,-0.3552,2.085554],[0.044762,-0.388707,2.097637],[0.073145,-0.4696,2.102641])),
                    #(false,true,#([-0.120665,-0.4696,2.068467],[-0.102701,-0.4124,2.132561],[-0.038494,-0.388707,2.169118],[0.034343,-0.4124,2.156725],[0.073145,-0.4696,2.102641])),
                    #(false,true,#([-0.120665,-0.4696,2.068467],[-0.107016,-0.4696,2.157036],[-0.044598,-0.4696,2.203731],[0.030027,-0.4696,2.181201],[0.073145,-0.4696,2.102641])),
                    #(false,true,#([-0.120665,-0.4696,2.068467],[-0.102701,-0.5268,2.132561],[-0.038494,-0.550493,2.169118],[0.034343,-0.5268,2.156725],[0.073145,-0.4696,2.102641])),
                    #(false,true,#([-0.120665,-0.4696,2.068467],[-0.092282,-0.550493,2.073472],[-0.02376,-0.584,2.085554],[0.044762,-0.550493,2.097637],[0.073145,-0.4696,2.102641])),
                    #(false,true,#([-0.120665,-0.4696,2.068467],[-0.081863,-0.5268,2.014384],[-0.009025,-0.550493,2.001991],[0.055181,-0.5268,2.038548],[0.073145,-0.4696,2.102641])),
                    #(false,true,#([-0.120665,-0.4696,2.068467],[-0.077547,-0.4696,1.989908],[-0.002922,-0.4696,1.967378],[0.059497,-0.4696,2.014073],[0.073145,-0.4696,2.102641])),
                    #(false,true,#([-0.120665,-0.4696,2.068467],[-0.081863,-0.4124,2.014384],[-0.009025,-0.388707,2.001991],[0.055181,-0.4124,2.038548],[0.073145,-0.4696,2.102641]))
                ) "dark" "mask" true 0.0
                f.cage "SmallMouth" #(
                    #(true,true,#([-0.139589,-0.411215,1.769438],[-0.145666,-0.4306,1.803907],[-0.148184,-0.4774,1.818184],[-0.145666,-0.5242,1.803907],[-0.139589,-0.543585,1.769438],[-0.133511,-0.5242,1.73497],[-0.130994,-0.4774,1.720693],[-0.133511,-0.4306,1.73497])),
                    #(true,true,#([-0.094325,-0.3838,1.77742],[-0.10292,-0.411215,1.826165],[-0.10648,-0.4774,1.846356],[-0.10292,-0.543585,1.826165],[-0.094325,-0.571,1.77742],[-0.08573,-0.543585,1.728675],[-0.08217,-0.4774,1.708483],[-0.08573,-0.411215,1.728675])),
                    #(true,true,#([-0.049061,-0.411215,1.785401],[-0.055139,-0.4306,1.819869],[-0.057656,-0.4774,1.834146],[-0.055139,-0.5242,1.819869],[-0.049061,-0.543585,1.785401],[-0.042984,-0.5242,1.750933],[-0.040466,-0.4774,1.736656],[-0.042984,-0.4306,1.750933])),
                    #(false,true,#([-0.158337,-0.4774,1.766133],[-0.139589,-0.411215,1.769438],[-0.094325,-0.3838,1.77742],[-0.049061,-0.411215,1.785401],[-0.030312,-0.4774,1.788707])),
                    #(false,true,#([-0.158337,-0.4774,1.766133],[-0.145666,-0.4306,1.803907],[-0.10292,-0.411215,1.826165],[-0.055139,-0.4306,1.819869],[-0.030312,-0.4774,1.788707])),
                    #(false,true,#([-0.158337,-0.4774,1.766133],[-0.148184,-0.4774,1.818184],[-0.10648,-0.4774,1.846356],[-0.057656,-0.4774,1.834146],[-0.030312,-0.4774,1.788707])),
                    #(false,true,#([-0.158337,-0.4774,1.766133],[-0.145666,-0.5242,1.803907],[-0.10292,-0.543585,1.826165],[-0.055139,-0.5242,1.819869],[-0.030312,-0.4774,1.788707])),
                    #(false,true,#([-0.158337,-0.4774,1.766133],[-0.139589,-0.543585,1.769438],[-0.094325,-0.571,1.77742],[-0.049061,-0.543585,1.785401],[-0.030312,-0.4774,1.788707])),
                    #(false,true,#([-0.158337,-0.4774,1.766133],[-0.133511,-0.5242,1.73497],[-0.08573,-0.543585,1.728675],[-0.042984,-0.5242,1.750933],[-0.030312,-0.4774,1.788707])),
                    #(false,true,#([-0.158337,-0.4774,1.766133],[-0.130994,-0.4774,1.720693],[-0.08217,-0.4774,1.708483],[-0.040466,-0.4774,1.736656],[-0.030312,-0.4774,1.788707])),
                    #(false,true,#([-0.158337,-0.4774,1.766133],[-0.133511,-0.4306,1.73497],[-0.08573,-0.411215,1.728675],[-0.042984,-0.4306,1.750933],[-0.030312,-0.4774,1.788707]))
                ) "dark" "mask" true 0.0
                f.tube "LanternTassel" #([0.83,-0.26,2.1],[0.87,-0.23,2.38]) 0.065 5 false true "gold_glow" "body"
                f.cage "SmallLantern" #(
                    #(true,true,#([0.663726,-0.01201,2.72],[0.663726,-0.07,2.91],[0.663726,-0.21,2.988701],[0.663726,-0.35,2.91],[0.663726,-0.40799,2.72],[0.663726,-0.35,2.53],[0.663726,-0.21,2.451299],[0.663726,-0.07,2.53])),
                    #(true,true,#([0.89,0.07,2.72],[0.89,-0.01201,2.988701],[0.89,-0.21,3.1],[0.89,-0.40799,2.988701],[0.89,-0.49,2.72],[0.89,-0.40799,2.451299],[0.89,-0.21,2.34],[0.89,-0.01201,2.451299])),
                    #(true,true,#([1.116274,-0.01201,2.72],[1.116274,-0.07,2.91],[1.116274,-0.21,2.988701],[1.116274,-0.35,2.91],[1.116274,-0.40799,2.72],[1.116274,-0.35,2.53],[1.116274,-0.21,2.451299],[1.116274,-0.07,2.53])),
                    #(false,true,#([0.57,-0.21,2.72],[0.663726,-0.01201,2.72],[0.89,0.07,2.72],[1.116274,-0.01201,2.72],[1.21,-0.21,2.72])),
                    #(false,true,#([0.57,-0.21,2.72],[0.663726,-0.07,2.91],[0.89,-0.01201,2.988701],[1.116274,-0.07,2.91],[1.21,-0.21,2.72])),
                    #(false,true,#([0.57,-0.21,2.72],[0.663726,-0.21,2.988701],[0.89,-0.21,3.1],[1.116274,-0.21,2.988701],[1.21,-0.21,2.72])),
                    #(false,true,#([0.57,-0.21,2.72],[0.663726,-0.35,2.91],[0.89,-0.40799,2.988701],[1.116274,-0.35,2.91],[1.21,-0.21,2.72])),
                    #(false,true,#([0.57,-0.21,2.72],[0.663726,-0.40799,2.72],[0.89,-0.49,2.72],[1.116274,-0.40799,2.72],[1.21,-0.21,2.72])),
                    #(false,true,#([0.57,-0.21,2.72],[0.663726,-0.35,2.53],[0.89,-0.40799,2.451299],[1.116274,-0.35,2.53],[1.21,-0.21,2.72])),
                    #(false,true,#([0.57,-0.21,2.72],[0.663726,-0.21,2.451299],[0.89,-0.21,2.34],[1.116274,-0.21,2.451299],[1.21,-0.21,2.72])),
                    #(false,true,#([0.57,-0.21,2.72],[0.663726,-0.07,2.53],[0.89,-0.01201,2.451299],[1.116274,-0.07,2.53],[1.21,-0.21,2.72]))
                ) "gold_glow" "body" true 0.0
                f.cage "LanternTop" #(
                    #(true,true,#([0.69201,-0.033223,3.08],[0.69201,-0.085,3.1175],[0.69201,-0.21,3.133033],[0.69201,-0.335,3.1175],[0.69201,-0.386777,3.08],[0.69201,-0.335,3.0425],[0.69201,-0.21,3.026967],[0.69201,-0.085,3.0425])),
                    #(true,true,#([0.89,0.04,3.08],[0.89,-0.033223,3.133033],[0.89,-0.21,3.155],[0.89,-0.386777,3.133033],[0.89,-0.46,3.08],[0.89,-0.386777,3.026967],[0.89,-0.21,3.005],[0.89,-0.033223,3.026967])),
                    #(true,true,#([1.08799,-0.033223,3.08],[1.08799,-0.085,3.1175],[1.08799,-0.21,3.133033],[1.08799,-0.335,3.1175],[1.08799,-0.386777,3.08],[1.08799,-0.335,3.0425],[1.08799,-0.21,3.026967],[1.08799,-0.085,3.0425])),
                    #(false,true,#([0.61,-0.21,3.08],[0.69201,-0.033223,3.08],[0.89,0.04,3.08],[1.08799,-0.033223,3.08],[1.17,-0.21,3.08])),
                    #(false,true,#([0.61,-0.21,3.08],[0.69201,-0.085,3.1175],[0.89,-0.033223,3.133033],[1.08799,-0.085,3.1175],[1.17,-0.21,3.08])),
                    #(false,true,#([0.61,-0.21,3.08],[0.69201,-0.21,3.133033],[0.89,-0.21,3.155],[1.08799,-0.21,3.133033],[1.17,-0.21,3.08])),
                    #(false,true,#([0.61,-0.21,3.08],[0.69201,-0.335,3.1175],[0.89,-0.386777,3.133033],[1.08799,-0.335,3.1175],[1.17,-0.21,3.08])),
                    #(false,true,#([0.61,-0.21,3.08],[0.69201,-0.386777,3.08],[0.89,-0.46,3.08],[1.08799,-0.386777,3.08],[1.17,-0.21,3.08])),
                    #(false,true,#([0.61,-0.21,3.08],[0.69201,-0.335,3.0425],[0.89,-0.386777,3.026967],[1.08799,-0.335,3.0425],[1.17,-0.21,3.08])),
                    #(false,true,#([0.61,-0.21,3.08],[0.69201,-0.21,3.026967],[0.89,-0.21,3.005],[1.08799,-0.21,3.026967],[1.17,-0.21,3.08])),
                    #(false,true,#([0.61,-0.21,3.08],[0.69201,-0.085,3.0425],[0.89,-0.033223,3.026967],[1.08799,-0.085,3.0425],[1.17,-0.21,3.08]))
                ) "dark" "body" true 0.0
                f.cage "LanternBottom" #(
                    #(true,true,#([0.720294,-0.047365,2.36],[0.720294,-0.095,2.3925],[0.720294,-0.21,2.405962],[0.720294,-0.325,2.3925],[0.720294,-0.372635,2.36],[0.720294,-0.325,2.3275],[0.720294,-0.21,2.314038],[0.720294,-0.095,2.3275])),
                    #(true,true,#([0.89,0.02,2.36],[0.89,-0.047365,2.405962],[0.89,-0.21,2.425],[0.89,-0.372635,2.405962],[0.89,-0.44,2.36],[0.89,-0.372635,2.314038],[0.89,-0.21,2.295],[0.89,-0.047365,2.314038])),
                    #(true,true,#([1.059706,-0.047365,2.36],[1.059706,-0.095,2.3925],[1.059706,-0.21,2.405962],[1.059706,-0.325,2.3925],[1.059706,-0.372635,2.36],[1.059706,-0.325,2.3275],[1.059706,-0.21,2.314038],[1.059706,-0.095,2.3275])),
                    #(false,true,#([0.65,-0.21,2.36],[0.720294,-0.047365,2.36],[0.89,0.02,2.36],[1.059706,-0.047365,2.36],[1.13,-0.21,2.36])),
                    #(false,true,#([0.65,-0.21,2.36],[0.720294,-0.095,2.3925],[0.89,-0.047365,2.405962],[1.059706,-0.095,2.3925],[1.13,-0.21,2.36])),
                    #(false,true,#([0.65,-0.21,2.36],[0.720294,-0.21,2.405962],[0.89,-0.21,2.425],[1.059706,-0.21,2.405962],[1.13,-0.21,2.36])),
                    #(false,true,#([0.65,-0.21,2.36],[0.720294,-0.325,2.3925],[0.89,-0.372635,2.405962],[1.059706,-0.325,2.3925],[1.13,-0.21,2.36])),
                    #(false,true,#([0.65,-0.21,2.36],[0.720294,-0.372635,2.36],[0.89,-0.44,2.36],[1.059706,-0.372635,2.36],[1.13,-0.21,2.36])),
                    #(false,true,#([0.65,-0.21,2.36],[0.720294,-0.325,2.3275],[0.89,-0.372635,2.314038],[1.059706,-0.325,2.3275],[1.13,-0.21,2.36])),
                    #(false,true,#([0.65,-0.21,2.36],[0.720294,-0.21,2.314038],[0.89,-0.21,2.295],[1.059706,-0.21,2.314038],[1.13,-0.21,2.36])),
                    #(false,true,#([0.65,-0.21,2.36],[0.720294,-0.095,2.3275],[0.89,-0.047365,2.314038],[1.059706,-0.095,2.3275],[1.13,-0.21,2.36]))
                ) "dark" "body" true 0.0
                f.finishModel()
                f.startModel "paradehelper2" "The outline mender" "helper" 2 0.13 [-0.02,-0.07,1.25] "A crouching broad-headed helper stitching a loose luminous outline." true
                f.cage "TuckedFoot" #(
                    #(true,true,#([-0.348995,0.419706,0.1],[-0.348995,0.37,0.15],[-0.348995,0.25,0.170711],[-0.348995,0.13,0.15],[-0.348995,0.080294,0.1],[-0.348995,0.13,0.05],[-0.348995,0.25,0.029289],[-0.348995,0.37,0.05])),
                    #(true,true,#([-0.25,0.49,0.1],[-0.25,0.419706,0.170711],[-0.25,0.25,0.2],[-0.25,0.080294,0.170711],[-0.25,0.01,0.1],[-0.25,0.080294,0.029289],[-0.25,0.25,0.0],[-0.25,0.419706,0.029289])),
                    #(true,true,#([-0.151005,0.419706,0.1],[-0.151005,0.37,0.15],[-0.151005,0.25,0.170711],[-0.151005,0.13,0.15],[-0.151005,0.080294,0.1],[-0.151005,0.13,0.05],[-0.151005,0.25,0.029289],[-0.151005,0.37,0.05])),
                    #(false,true,#([-0.39,0.25,0.1],[-0.348995,0.419706,0.1],[-0.25,0.49,0.1],[-0.151005,0.419706,0.1],[-0.11,0.25,0.1])),
                    #(false,true,#([-0.39,0.25,0.1],[-0.348995,0.37,0.15],[-0.25,0.419706,0.170711],[-0.151005,0.37,0.15],[-0.11,0.25,0.1])),
                    #(false,true,#([-0.39,0.25,0.1],[-0.348995,0.25,0.170711],[-0.25,0.25,0.2],[-0.151005,0.25,0.170711],[-0.11,0.25,0.1])),
                    #(false,true,#([-0.39,0.25,0.1],[-0.348995,0.13,0.15],[-0.25,0.080294,0.170711],[-0.151005,0.13,0.15],[-0.11,0.25,0.1])),
                    #(false,true,#([-0.39,0.25,0.1],[-0.348995,0.080294,0.1],[-0.25,0.01,0.1],[-0.151005,0.080294,0.1],[-0.11,0.25,0.1])),
                    #(false,true,#([-0.39,0.25,0.1],[-0.348995,0.13,0.05],[-0.25,0.080294,0.029289],[-0.151005,0.13,0.05],[-0.11,0.25,0.1])),
                    #(false,true,#([-0.39,0.25,0.1],[-0.348995,0.25,0.029289],[-0.25,0.25,0.0],[-0.151005,0.25,0.029289],[-0.11,0.25,0.1])),
                    #(false,true,#([-0.39,0.25,0.1],[-0.348995,0.37,0.05],[-0.25,0.419706,0.029289],[-0.151005,0.37,0.05],[-0.11,0.25,0.1]))
                ) "ivory_glow" "body" true 0.0
                f.cage "KneelingFoot" #(
                    #(true,true,#([0.251005,0.656777,0.1],[0.251005,0.605,0.15],[0.251005,0.48,0.170711],[0.251005,0.355,0.15],[0.251005,0.303223,0.1],[0.251005,0.355,0.05],[0.251005,0.48,0.029289],[0.251005,0.605,0.05])),
                    #(true,true,#([0.35,0.73,0.1],[0.35,0.656777,0.170711],[0.35,0.48,0.2],[0.35,0.303223,0.170711],[0.35,0.23,0.1],[0.35,0.303223,0.029289],[0.35,0.48,0.0],[0.35,0.656777,0.029289])),
                    #(true,true,#([0.448995,0.656777,0.1],[0.448995,0.605,0.15],[0.448995,0.48,0.170711],[0.448995,0.355,0.15],[0.448995,0.303223,0.1],[0.448995,0.355,0.05],[0.448995,0.48,0.029289],[0.448995,0.605,0.05])),
                    #(false,true,#([0.21,0.48,0.1],[0.251005,0.656777,0.1],[0.35,0.73,0.1],[0.448995,0.656777,0.1],[0.49,0.48,0.1])),
                    #(false,true,#([0.21,0.48,0.1],[0.251005,0.605,0.15],[0.35,0.656777,0.170711],[0.448995,0.605,0.15],[0.49,0.48,0.1])),
                    #(false,true,#([0.21,0.48,0.1],[0.251005,0.48,0.170711],[0.35,0.48,0.2],[0.448995,0.48,0.170711],[0.49,0.48,0.1])),
                    #(false,true,#([0.21,0.48,0.1],[0.251005,0.355,0.15],[0.35,0.303223,0.170711],[0.448995,0.355,0.15],[0.49,0.48,0.1])),
                    #(false,true,#([0.21,0.48,0.1],[0.251005,0.303223,0.1],[0.35,0.23,0.1],[0.448995,0.303223,0.1],[0.49,0.48,0.1])),
                    #(false,true,#([0.21,0.48,0.1],[0.251005,0.355,0.05],[0.35,0.303223,0.029289],[0.448995,0.355,0.05],[0.49,0.48,0.1])),
                    #(false,true,#([0.21,0.48,0.1],[0.251005,0.48,0.029289],[0.35,0.48,0.0],[0.448995,0.48,0.029289],[0.49,0.48,0.1])),
                    #(false,true,#([0.21,0.48,0.1],[0.251005,0.605,0.05],[0.35,0.656777,0.029289],[0.448995,0.605,0.05],[0.49,0.48,0.1]))
                ) "ivory_glow" "body" true 0.0
                f.cage "LeftKnee" #(
                    #(true,true,#([-0.482635,0.09799,0.28],[-0.482635,0.04,0.395],[-0.482635,-0.1,0.442635],[-0.482635,-0.24,0.395],[-0.482635,-0.29799,0.28],[-0.482635,-0.24,0.165],[-0.482635,-0.1,0.117365],[-0.482635,0.04,0.165])),
                    #(true,true,#([-0.32,0.18,0.28],[-0.32,0.09799,0.442635],[-0.32,-0.1,0.51],[-0.32,-0.29799,0.442635],[-0.32,-0.38,0.28],[-0.32,-0.29799,0.117365],[-0.32,-0.1,0.05],[-0.32,0.09799,0.117365])),
                    #(true,true,#([-0.157365,0.09799,0.28],[-0.157365,0.04,0.395],[-0.157365,-0.1,0.442635],[-0.157365,-0.24,0.395],[-0.157365,-0.29799,0.28],[-0.157365,-0.24,0.165],[-0.157365,-0.1,0.117365],[-0.157365,0.04,0.165])),
                    #(false,true,#([-0.55,-0.1,0.28],[-0.482635,0.09799,0.28],[-0.32,0.18,0.28],[-0.157365,0.09799,0.28],[-0.09,-0.1,0.28])),
                    #(false,true,#([-0.55,-0.1,0.28],[-0.482635,0.04,0.395],[-0.32,0.09799,0.442635],[-0.157365,0.04,0.395],[-0.09,-0.1,0.28])),
                    #(false,true,#([-0.55,-0.1,0.28],[-0.482635,-0.1,0.442635],[-0.32,-0.1,0.51],[-0.157365,-0.1,0.442635],[-0.09,-0.1,0.28])),
                    #(false,true,#([-0.55,-0.1,0.28],[-0.482635,-0.24,0.395],[-0.32,-0.29799,0.442635],[-0.157365,-0.24,0.395],[-0.09,-0.1,0.28])),
                    #(false,true,#([-0.55,-0.1,0.28],[-0.482635,-0.29799,0.28],[-0.32,-0.38,0.28],[-0.157365,-0.29799,0.28],[-0.09,-0.1,0.28])),
                    #(false,true,#([-0.55,-0.1,0.28],[-0.482635,-0.24,0.165],[-0.32,-0.29799,0.117365],[-0.157365,-0.24,0.165],[-0.09,-0.1,0.28])),
                    #(false,true,#([-0.55,-0.1,0.28],[-0.482635,-0.1,0.117365],[-0.32,-0.1,0.05],[-0.157365,-0.1,0.117365],[-0.09,-0.1,0.28])),
                    #(false,true,#([-0.55,-0.1,0.28],[-0.482635,0.04,0.165],[-0.32,0.09799,0.117365],[-0.157365,0.04,0.165],[-0.09,-0.1,0.28]))
                ) "ivory_glow" "body" true 0.0
                f.cage "BentShin" #(
                    #(true,true,#([0.218429,0.382156,0.15],[0.268711,0.363868,0.057163],[0.366611,0.38432,0.018709],[0.454781,0.43153,0.057163],[0.481571,0.477844,0.15],[0.431289,0.496132,0.242837],[0.333389,0.47568,0.281291],[0.245219,0.42847,0.242837])),
                    #(true,true,#([0.311651,0.095375,0.257548],[0.373673,0.045897,0.164267],[0.492123,0.028111,0.138782],[0.597613,0.052437,0.19602],[0.628349,0.104625,0.302452],[0.566327,0.154103,0.395733],[0.447877,0.171889,0.421218],[0.342387,0.147563,0.36398])),
                    #(true,true,#([0.145438,-0.172085,0.425015],[0.207459,-0.258076,0.337047],[0.329548,-0.321762,0.332819],[0.440186,-0.325838,0.414808],[0.474562,-0.267915,0.534985],[0.412541,-0.181924,0.622953],[0.290452,-0.118238,0.627181],[0.179814,-0.114162,0.545192])),
                    #(false,true,#([0.35,0.43,0.15],[0.218429,0.382156,0.15],[0.311651,0.095375,0.257548],[0.145438,-0.172085,0.425015],[0.31,-0.22,0.48])),
                    #(false,true,#([0.35,0.43,0.15],[0.268711,0.363868,0.057163],[0.373673,0.045897,0.164267],[0.207459,-0.258076,0.337047],[0.31,-0.22,0.48])),
                    #(false,true,#([0.35,0.43,0.15],[0.366611,0.38432,0.018709],[0.492123,0.028111,0.138782],[0.329548,-0.321762,0.332819],[0.31,-0.22,0.48])),
                    #(false,true,#([0.35,0.43,0.15],[0.454781,0.43153,0.057163],[0.597613,0.052437,0.19602],[0.440186,-0.325838,0.414808],[0.31,-0.22,0.48])),
                    #(false,true,#([0.35,0.43,0.15],[0.481571,0.477844,0.15],[0.628349,0.104625,0.302452],[0.474562,-0.267915,0.534985],[0.31,-0.22,0.48])),
                    #(false,true,#([0.35,0.43,0.15],[0.431289,0.496132,0.242837],[0.566327,0.154103,0.395733],[0.412541,-0.181924,0.622953],[0.31,-0.22,0.48])),
                    #(false,true,#([0.35,0.43,0.15],[0.333389,0.47568,0.281291],[0.447877,0.171889,0.421218],[0.290452,-0.118238,0.627181],[0.31,-0.22,0.48])),
                    #(false,true,#([0.35,0.43,0.15],[0.245219,0.42847,0.242837],[0.342387,0.147563,0.36398],[0.179814,-0.114162,0.545192],[0.31,-0.22,0.48]))
                ) "ivory_glow" "body" true 0.0
                f.cage "CrouchedBody" #(
                    #(true,true,#([-0.282843,0.233345,0.82],[-0.282843,0.165,1.08],[-0.282843,0.0,1.187696],[-0.282843,-0.165,1.08],[-0.282843,-0.233345,0.82],[-0.282843,-0.165,0.56],[-0.282843,0.0,0.452304],[-0.282843,0.165,0.56])),
                    #(true,true,#([0.0,0.33,0.82],[0.0,0.233345,1.187696],[0.0,0.0,1.34],[0.0,-0.233345,1.187696],[0.0,-0.33,0.82],[0.0,-0.233345,0.452304],[0.0,0.0,0.3],[0.0,0.233345,0.452304])),
                    #(true,true,#([0.282843,0.233345,0.82],[0.282843,0.165,1.08],[0.282843,0.0,1.187696],[0.282843,-0.165,1.08],[0.282843,-0.233345,0.82],[0.282843,-0.165,0.56],[0.282843,0.0,0.452304],[0.282843,0.165,0.56])),
                    #(false,true,#([-0.4,0.0,0.82],[-0.282843,0.233345,0.82],[0.0,0.33,0.82],[0.282843,0.233345,0.82],[0.4,0.0,0.82])),
                    #(false,true,#([-0.4,0.0,0.82],[-0.282843,0.165,1.08],[0.0,0.233345,1.187696],[0.282843,0.165,1.08],[0.4,0.0,0.82])),
                    #(false,true,#([-0.4,0.0,0.82],[-0.282843,0.0,1.187696],[0.0,0.0,1.34],[0.282843,0.0,1.187696],[0.4,0.0,0.82])),
                    #(false,true,#([-0.4,0.0,0.82],[-0.282843,-0.165,1.08],[0.0,-0.233345,1.187696],[0.282843,-0.165,1.08],[0.4,0.0,0.82])),
                    #(false,true,#([-0.4,0.0,0.82],[-0.282843,-0.233345,0.82],[0.0,-0.33,0.82],[0.282843,-0.233345,0.82],[0.4,0.0,0.82])),
                    #(false,true,#([-0.4,0.0,0.82],[-0.282843,-0.165,0.56],[0.0,-0.233345,0.452304],[0.282843,-0.165,0.56],[0.4,0.0,0.82])),
                    #(false,true,#([-0.4,0.0,0.82],[-0.282843,0.0,0.452304],[0.0,0.0,0.3],[0.282843,0.0,0.452304],[0.4,0.0,0.82])),
                    #(false,true,#([-0.4,0.0,0.82],[-0.282843,0.165,0.56],[0.0,0.233345,0.452304],[0.282843,0.165,0.56],[0.4,0.0,0.82]))
                ) "ivory_glow" "body" true 0.0
                f.cage "WorkingArm" #(
                    #(true,true,#([-0.403908,0.032649,1.1],[-0.34177,0.066618,1.030108],[-0.249306,0.043989,1.001158],[-0.18068,-0.021982,1.030108],[-0.176092,-0.092649,1.1],[-0.23823,-0.126618,1.169892],[-0.330694,-0.103989,1.198842],[-0.39932,-0.038018,1.169892])),
                    #(true,true,#([-0.603705,-0.382741,0.706697],[-0.552246,-0.35281,0.652712],[-0.47604,-0.368096,0.632286],[-0.419727,-0.419644,0.657383],[-0.416295,-0.477259,0.713303],[-0.467754,-0.50719,0.767288],[-0.54396,-0.491904,0.787714],[-0.600273,-0.440356,0.762617])),
                    #(true,true,#([-0.727023,-0.754462,0.334566],[-0.684495,-0.728202,0.292924],[-0.62176,-0.738142,0.278858],[-0.575568,-0.77846,0.300608],[-0.572977,-0.825538,0.345434],[-0.615505,-0.851798,0.387076],[-0.67824,-0.841858,0.401142],[-0.724432,-0.80154,0.379392])),
                    #(false,true,#([-0.29,-0.03,1.1],[-0.403908,0.032649,1.1],[-0.603705,-0.382741,0.706697],[-0.727023,-0.754462,0.334566],[-0.65,-0.79,0.34])),
                    #(false,true,#([-0.29,-0.03,1.1],[-0.34177,0.066618,1.030108],[-0.552246,-0.35281,0.652712],[-0.684495,-0.728202,0.292924],[-0.65,-0.79,0.34])),
                    #(false,true,#([-0.29,-0.03,1.1],[-0.249306,0.043989,1.001158],[-0.47604,-0.368096,0.632286],[-0.62176,-0.738142,0.278858],[-0.65,-0.79,0.34])),
                    #(false,true,#([-0.29,-0.03,1.1],[-0.18068,-0.021982,1.030108],[-0.419727,-0.419644,0.657383],[-0.575568,-0.77846,0.300608],[-0.65,-0.79,0.34])),
                    #(false,true,#([-0.29,-0.03,1.1],[-0.176092,-0.092649,1.1],[-0.416295,-0.477259,0.713303],[-0.572977,-0.825538,0.345434],[-0.65,-0.79,0.34])),
                    #(false,true,#([-0.29,-0.03,1.1],[-0.23823,-0.126618,1.169892],[-0.467754,-0.50719,0.767288],[-0.615505,-0.851798,0.387076],[-0.65,-0.79,0.34])),
                    #(false,true,#([-0.29,-0.03,1.1],[-0.330694,-0.103989,1.198842],[-0.54396,-0.491904,0.787714],[-0.67824,-0.841858,0.401142],[-0.65,-0.79,0.34])),
                    #(false,true,#([-0.29,-0.03,1.1],[-0.39932,-0.038018,1.169892],[-0.600273,-0.440356,0.762617],[-0.724432,-0.80154,0.379392],[-0.65,-0.79,0.34]))
                ) "ivory_glow" "body" true 0.0
                f.cage "HoldingArm" #(
                    #(true,true,#([0.167574,-0.043724,1.1],[0.18878,0.010106,1.019053],[0.26928,0.058015,0.985523],[0.361917,0.07194,1.019053],[0.412426,0.043724,1.1],[0.39122,-0.010106,1.180947],[0.31072,-0.058015,1.214477],[0.218083,-0.07194,1.180947])),
                    #(true,true,#([0.338894,-0.410928,0.886837],[0.356249,-0.371968,0.818725],[0.422664,-0.361145,0.774791],[0.499234,-0.384798,0.780772],[0.541106,-0.429072,0.833163],[0.523751,-0.468032,0.901275],[0.457336,-0.478855,0.945209],[0.380766,-0.455202,0.939228])),
                    #(true,true,#([-0.03271,-0.751667,0.632696],[-0.020609,-0.723282,0.575423],[0.021138,-0.73398,0.526689],[0.068077,-0.777494,0.515042],[0.09271,-0.828333,0.547304],[0.080609,-0.856718,0.604577],[0.038862,-0.84602,0.653311],[-0.008077,-0.802506,0.664958])),
                    #(false,true,#([0.29,0.0,1.1],[0.167574,-0.043724,1.1],[0.338894,-0.410928,0.886837],[-0.03271,-0.751667,0.632696],[0.03,-0.79,0.59])),
                    #(false,true,#([0.29,0.0,1.1],[0.18878,0.010106,1.019053],[0.356249,-0.371968,0.818725],[-0.020609,-0.723282,0.575423],[0.03,-0.79,0.59])),
                    #(false,true,#([0.29,0.0,1.1],[0.26928,0.058015,0.985523],[0.422664,-0.361145,0.774791],[0.021138,-0.73398,0.526689],[0.03,-0.79,0.59])),
                    #(false,true,#([0.29,0.0,1.1],[0.361917,0.07194,1.019053],[0.499234,-0.384798,0.780772],[0.068077,-0.777494,0.515042],[0.03,-0.79,0.59])),
                    #(false,true,#([0.29,0.0,1.1],[0.412426,0.043724,1.1],[0.541106,-0.429072,0.833163],[0.09271,-0.828333,0.547304],[0.03,-0.79,0.59])),
                    #(false,true,#([0.29,0.0,1.1],[0.39122,-0.010106,1.180947],[0.523751,-0.468032,0.901275],[0.080609,-0.856718,0.604577],[0.03,-0.79,0.59])),
                    #(false,true,#([0.29,0.0,1.1],[0.31072,-0.058015,1.214477],[0.457336,-0.478855,0.945209],[0.038862,-0.84602,0.653311],[0.03,-0.79,0.59])),
                    #(false,true,#([0.29,0.0,1.1],[0.218083,-0.07194,1.180947],[0.380766,-0.455202,0.939228],[-0.008077,-0.802506,0.664958],[0.03,-0.79,0.59]))
                ) "ivory_glow" "body" true 0.0
                f.cage "WorkingHand" #(
                    #(true,true,#([-0.748995,-0.735754,0.32],[-0.748995,-0.7575,0.375],[-0.748995,-0.81,0.397782],[-0.748995,-0.8625,0.375],[-0.748995,-0.884246,0.32],[-0.748995,-0.8625,0.265],[-0.748995,-0.81,0.242218],[-0.748995,-0.7575,0.265])),
                    #(true,true,#([-0.65,-0.705,0.32],[-0.65,-0.735754,0.397782],[-0.65,-0.81,0.43],[-0.65,-0.884246,0.397782],[-0.65,-0.915,0.32],[-0.65,-0.884246,0.242218],[-0.65,-0.81,0.21],[-0.65,-0.735754,0.242218])),
                    #(true,true,#([-0.551005,-0.735754,0.32],[-0.551005,-0.7575,0.375],[-0.551005,-0.81,0.397782],[-0.551005,-0.8625,0.375],[-0.551005,-0.884246,0.32],[-0.551005,-0.8625,0.265],[-0.551005,-0.81,0.242218],[-0.551005,-0.7575,0.265])),
                    #(false,true,#([-0.79,-0.81,0.32],[-0.748995,-0.735754,0.32],[-0.65,-0.705,0.32],[-0.551005,-0.735754,0.32],[-0.51,-0.81,0.32])),
                    #(false,true,#([-0.79,-0.81,0.32],[-0.748995,-0.7575,0.375],[-0.65,-0.735754,0.397782],[-0.551005,-0.7575,0.375],[-0.51,-0.81,0.32])),
                    #(false,true,#([-0.79,-0.81,0.32],[-0.748995,-0.81,0.397782],[-0.65,-0.81,0.43],[-0.551005,-0.81,0.397782],[-0.51,-0.81,0.32])),
                    #(false,true,#([-0.79,-0.81,0.32],[-0.748995,-0.8625,0.375],[-0.65,-0.884246,0.397782],[-0.551005,-0.8625,0.375],[-0.51,-0.81,0.32])),
                    #(false,true,#([-0.79,-0.81,0.32],[-0.748995,-0.884246,0.32],[-0.65,-0.915,0.32],[-0.551005,-0.884246,0.32],[-0.51,-0.81,0.32])),
                    #(false,true,#([-0.79,-0.81,0.32],[-0.748995,-0.8625,0.265],[-0.65,-0.884246,0.242218],[-0.551005,-0.8625,0.265],[-0.51,-0.81,0.32])),
                    #(false,true,#([-0.79,-0.81,0.32],[-0.748995,-0.81,0.242218],[-0.65,-0.81,0.21],[-0.551005,-0.81,0.242218],[-0.51,-0.81,0.32])),
                    #(false,true,#([-0.79,-0.81,0.32],[-0.748995,-0.7575,0.265],[-0.65,-0.735754,0.242218],[-0.551005,-0.7575,0.265],[-0.51,-0.81,0.32]))
                ) "ivory_glow" "body" true 0.0
                f.cage "HoldingHand" #(
                    #(true,true,#([-0.088995,-0.735754,0.59],[-0.088995,-0.7575,0.645],[-0.088995,-0.81,0.667782],[-0.088995,-0.8625,0.645],[-0.088995,-0.884246,0.59],[-0.088995,-0.8625,0.535],[-0.088995,-0.81,0.512218],[-0.088995,-0.7575,0.535])),
                    #(true,true,#([0.01,-0.705,0.59],[0.01,-0.735754,0.667782],[0.01,-0.81,0.7],[0.01,-0.884246,0.667782],[0.01,-0.915,0.59],[0.01,-0.884246,0.512218],[0.01,-0.81,0.48],[0.01,-0.735754,0.512218])),
                    #(true,true,#([0.108995,-0.735754,0.59],[0.108995,-0.7575,0.645],[0.108995,-0.81,0.667782],[0.108995,-0.8625,0.645],[0.108995,-0.884246,0.59],[0.108995,-0.8625,0.535],[0.108995,-0.81,0.512218],[0.108995,-0.7575,0.535])),
                    #(false,true,#([-0.13,-0.81,0.59],[-0.088995,-0.735754,0.59],[0.01,-0.705,0.59],[0.108995,-0.735754,0.59],[0.15,-0.81,0.59])),
                    #(false,true,#([-0.13,-0.81,0.59],[-0.088995,-0.7575,0.645],[0.01,-0.735754,0.667782],[0.108995,-0.7575,0.645],[0.15,-0.81,0.59])),
                    #(false,true,#([-0.13,-0.81,0.59],[-0.088995,-0.81,0.667782],[0.01,-0.81,0.7],[0.108995,-0.81,0.667782],[0.15,-0.81,0.59])),
                    #(false,true,#([-0.13,-0.81,0.59],[-0.088995,-0.8625,0.645],[0.01,-0.884246,0.667782],[0.108995,-0.8625,0.645],[0.15,-0.81,0.59])),
                    #(false,true,#([-0.13,-0.81,0.59],[-0.088995,-0.884246,0.59],[0.01,-0.915,0.59],[0.108995,-0.884246,0.59],[0.15,-0.81,0.59])),
                    #(false,true,#([-0.13,-0.81,0.59],[-0.088995,-0.8625,0.535],[0.01,-0.884246,0.512218],[0.108995,-0.8625,0.535],[0.15,-0.81,0.59])),
                    #(false,true,#([-0.13,-0.81,0.59],[-0.088995,-0.81,0.512218],[0.01,-0.81,0.48],[0.108995,-0.81,0.512218],[0.15,-0.81,0.59])),
                    #(false,true,#([-0.13,-0.81,0.59],[-0.088995,-0.7575,0.535],[0.01,-0.735754,0.512218],[0.108995,-0.7575,0.535],[0.15,-0.81,0.59]))
                ) "ivory_glow" "body" true 0.0
                f.cage "Head" #(
                    #(true,true,#([-0.372941,0.176985,1.872561],[-0.297884,0.09,2.15268],[-0.266794,-0.12,2.268709],[-0.297884,-0.33,2.15268],[-0.372941,-0.416985,1.872561],[-0.447999,-0.33,1.592443],[-0.479089,-0.12,1.476414],[-0.447999,0.09,1.592443])),
                    #(true,true,#([0.111998,0.3,1.742622],[0.218145,0.176985,2.13877],[0.262113,-0.12,2.302859],[0.218145,-0.416985,2.13877],[0.111998,-0.54,1.742622],[0.00585,-0.416985,1.346475],[-0.038117,-0.12,1.182385],[0.00585,0.176985,1.346475])),
                    #(true,true,#([0.596937,0.176985,1.612683],[0.671994,0.09,1.892802],[0.703084,-0.12,2.008831],[0.671994,-0.33,1.892802],[0.596937,-0.416985,1.612683],[0.521879,-0.33,1.332565],[0.49079,-0.12,1.216536],[0.521879,0.09,1.332565])),
                    #(false,true,#([-0.57381,-0.12,1.926384],[-0.372941,0.176985,1.872561],[0.111998,0.3,1.742622],[0.596937,0.176985,1.612683],[0.797805,-0.12,1.558861])),
                    #(false,true,#([-0.57381,-0.12,1.926384],[-0.297884,0.09,2.15268],[0.218145,0.176985,2.13877],[0.671994,0.09,1.892802],[0.797805,-0.12,1.558861])),
                    #(false,true,#([-0.57381,-0.12,1.926384],[-0.266794,-0.12,2.268709],[0.262113,-0.12,2.302859],[0.703084,-0.12,2.008831],[0.797805,-0.12,1.558861])),
                    #(false,true,#([-0.57381,-0.12,1.926384],[-0.297884,-0.33,2.15268],[0.218145,-0.416985,2.13877],[0.671994,-0.33,1.892802],[0.797805,-0.12,1.558861])),
                    #(false,true,#([-0.57381,-0.12,1.926384],[-0.372941,-0.416985,1.872561],[0.111998,-0.54,1.742622],[0.596937,-0.416985,1.612683],[0.797805,-0.12,1.558861])),
                    #(false,true,#([-0.57381,-0.12,1.926384],[-0.447999,-0.33,1.592443],[0.00585,-0.416985,1.346475],[0.521879,-0.33,1.332565],[0.797805,-0.12,1.558861])),
                    #(false,true,#([-0.57381,-0.12,1.926384],[-0.479089,-0.12,1.476414],[-0.038117,-0.12,1.182385],[0.49079,-0.12,1.216536],[0.797805,-0.12,1.558861])),
                    #(false,true,#([-0.57381,-0.12,1.926384],[-0.447999,0.09,1.592443],[0.00585,0.176985,1.346475],[0.521879,0.09,1.332565],[0.797805,-0.12,1.558861]))
                ) "cream" "head" true 0.0
                f.cage "FacePlate" #(
                    #(true,true,#([-0.238927,-0.352721,1.826299],[-0.179398,-0.39,2.048462],[-0.154741,-0.48,2.140485],[-0.179398,-0.57,2.048462],[-0.238927,-0.607279,1.826299],[-0.298455,-0.57,1.604136],[-0.323112,-0.48,1.512114],[-0.298455,-0.39,1.604136])),
                    #(true,true,#([0.10941,-0.3,1.732963],[0.193595,-0.352721,2.047149],[0.228466,-0.48,2.177289],[0.193595,-0.607279,2.047149],[0.10941,-0.66,1.732963],[0.025224,-0.607279,1.418777],[-0.009647,-0.48,1.288637],[0.025224,-0.352721,1.418777])),
                    #(true,true,#([0.457746,-0.352721,1.639627],[0.517274,-0.39,1.861789],[0.541931,-0.48,1.953812],[0.517274,-0.57,1.861789],[0.457746,-0.607279,1.639627],[0.398217,-0.57,1.417464],[0.37356,-0.48,1.325441],[0.398217,-0.39,1.417464])),
                    #(false,true,#([-0.383213,-0.48,1.864961],[-0.238927,-0.352721,1.826299],[0.10941,-0.3,1.732963],[0.457746,-0.352721,1.639627],[0.602032,-0.48,1.600965])),
                    #(false,true,#([-0.383213,-0.48,1.864961],[-0.179398,-0.39,2.048462],[0.193595,-0.352721,2.047149],[0.517274,-0.39,1.861789],[0.602032,-0.48,1.600965])),
                    #(false,true,#([-0.383213,-0.48,1.864961],[-0.154741,-0.48,2.140485],[0.228466,-0.48,2.177289],[0.541931,-0.48,1.953812],[0.602032,-0.48,1.600965])),
                    #(false,true,#([-0.383213,-0.48,1.864961],[-0.179398,-0.57,2.048462],[0.193595,-0.607279,2.047149],[0.517274,-0.57,1.861789],[0.602032,-0.48,1.600965])),
                    #(false,true,#([-0.383213,-0.48,1.864961],[-0.238927,-0.607279,1.826299],[0.10941,-0.66,1.732963],[0.457746,-0.607279,1.639627],[0.602032,-0.48,1.600965])),
                    #(false,true,#([-0.383213,-0.48,1.864961],[-0.298455,-0.57,1.604136],[0.025224,-0.607279,1.418777],[0.398217,-0.57,1.417464],[0.602032,-0.48,1.600965])),
                    #(false,true,#([-0.383213,-0.48,1.864961],[-0.323112,-0.48,1.512114],[-0.009647,-0.48,1.288637],[0.37356,-0.48,1.325441],[0.602032,-0.48,1.600965])),
                    #(false,true,#([-0.383213,-0.48,1.864961],[-0.298455,-0.39,1.604136],[0.025224,-0.352721,1.418777],[0.398217,-0.39,1.417464],[0.602032,-0.48,1.600965]))
                ) "ivory_glow" "mask" true 0.0
                f.cage "EyeLeft" #(
                    #(true,true,#([-0.169515,-0.533594,1.893421],[-0.153986,-0.5664,1.951377],[-0.147553,-0.6456,1.975383],[-0.153986,-0.7248,1.951377],[-0.169515,-0.757606,1.893421],[-0.185044,-0.7248,1.835466],[-0.191476,-0.6456,1.81146],[-0.185044,-0.5664,1.835466])),
                    #(true,true,#([-0.085914,-0.4872,1.871021],[-0.063952,-0.533594,1.952982],[-0.054856,-0.6456,1.986932],[-0.063952,-0.757606,1.952982],[-0.085914,-0.804,1.871021],[-0.107876,-0.757606,1.789059],[-0.116972,-0.6456,1.755109],[-0.107876,-0.533594,1.789059])),
                    #(true,true,#([-0.002313,-0.533594,1.84862],[0.013216,-0.5664,1.906575],[0.019648,-0.6456,1.930581],[0.013216,-0.7248,1.906575],[-0.002313,-0.757606,1.84862],[-0.017842,-0.7248,1.790664],[-0.024275,-0.6456,1.766658],[-0.017842,-0.5664,1.790664])),
                    #(false,true,#([-0.204143,-0.6456,1.9027],[-0.169515,-0.533594,1.893421],[-0.085914,-0.4872,1.871021],[-0.002313,-0.533594,1.84862],[0.032315,-0.6456,1.839341])),
                    #(false,true,#([-0.204143,-0.6456,1.9027],[-0.153986,-0.5664,1.951377],[-0.063952,-0.533594,1.952982],[0.013216,-0.5664,1.906575],[0.032315,-0.6456,1.839341])),
                    #(false,true,#([-0.204143,-0.6456,1.9027],[-0.147553,-0.6456,1.975383],[-0.054856,-0.6456,1.986932],[0.019648,-0.6456,1.930581],[0.032315,-0.6456,1.839341])),
                    #(false,true,#([-0.204143,-0.6456,1.9027],[-0.153986,-0.7248,1.951377],[-0.063952,-0.757606,1.952982],[0.013216,-0.7248,1.906575],[0.032315,-0.6456,1.839341])),
                    #(false,true,#([-0.204143,-0.6456,1.9027],[-0.169515,-0.757606,1.893421],[-0.085914,-0.804,1.871021],[-0.002313,-0.757606,1.84862],[0.032315,-0.6456,1.839341])),
                    #(false,true,#([-0.204143,-0.6456,1.9027],[-0.185044,-0.7248,1.835466],[-0.107876,-0.757606,1.789059],[-0.017842,-0.7248,1.790664],[0.032315,-0.6456,1.839341])),
                    #(false,true,#([-0.204143,-0.6456,1.9027],[-0.191476,-0.6456,1.81146],[-0.116972,-0.6456,1.755109],[-0.024275,-0.6456,1.766658],[0.032315,-0.6456,1.839341])),
                    #(false,true,#([-0.204143,-0.6456,1.9027],[-0.185044,-0.5664,1.835466],[-0.107876,-0.533594,1.789059],[-0.017842,-0.5664,1.790664],[0.032315,-0.6456,1.839341]))
                ) "dark" "mask" true 0.0
                f.cage "EyeRight" #(
                    #(true,true,#([0.263993,-0.533594,1.777263],[0.279522,-0.5664,1.835219],[0.285954,-0.6456,1.859225],[0.279522,-0.7248,1.835219],[0.263993,-0.757606,1.777263],[0.248463,-0.7248,1.719308],[0.242031,-0.6456,1.695302],[0.248463,-0.5664,1.719308])),
                    #(true,true,#([0.347593,-0.4872,1.754863],[0.369555,-0.533594,1.836824],[0.378652,-0.6456,1.870774],[0.369555,-0.757606,1.836824],[0.347593,-0.804,1.754863],[0.325632,-0.757606,1.672901],[0.316535,-0.6456,1.638951],[0.325632,-0.533594,1.672901])),
                    #(true,true,#([0.431194,-0.533594,1.732462],[0.446724,-0.5664,1.790417],[0.453156,-0.6456,1.814423],[0.446724,-0.7248,1.790417],[0.431194,-0.757606,1.732462],[0.415665,-0.7248,1.674506],[0.409233,-0.6456,1.6505],[0.415665,-0.5664,1.674506])),
                    #(false,true,#([0.229364,-0.6456,1.786542],[0.263993,-0.533594,1.777263],[0.347593,-0.4872,1.754863],[0.431194,-0.533594,1.732462],[0.465823,-0.6456,1.723183])),
                    #(false,true,#([0.229364,-0.6456,1.786542],[0.279522,-0.5664,1.835219],[0.369555,-0.533594,1.836824],[0.446724,-0.5664,1.790417],[0.465823,-0.6456,1.723183])),
                    #(false,true,#([0.229364,-0.6456,1.786542],[0.285954,-0.6456,1.859225],[0.378652,-0.6456,1.870774],[0.453156,-0.6456,1.814423],[0.465823,-0.6456,1.723183])),
                    #(false,true,#([0.229364,-0.6456,1.786542],[0.279522,-0.7248,1.835219],[0.369555,-0.757606,1.836824],[0.446724,-0.7248,1.790417],[0.465823,-0.6456,1.723183])),
                    #(false,true,#([0.229364,-0.6456,1.786542],[0.263993,-0.757606,1.777263],[0.347593,-0.804,1.754863],[0.431194,-0.757606,1.732462],[0.465823,-0.6456,1.723183])),
                    #(false,true,#([0.229364,-0.6456,1.786542],[0.248463,-0.7248,1.719308],[0.325632,-0.757606,1.672901],[0.415665,-0.7248,1.674506],[0.465823,-0.6456,1.723183])),
                    #(false,true,#([0.229364,-0.6456,1.786542],[0.242031,-0.6456,1.695302],[0.316535,-0.6456,1.638951],[0.409233,-0.6456,1.6505],[0.465823,-0.6456,1.723183])),
                    #(false,true,#([0.229364,-0.6456,1.786542],[0.248463,-0.5664,1.719308],[0.325632,-0.533594,1.672901],[0.415665,-0.5664,1.674506],[0.465823,-0.6456,1.723183]))
                ) "dark" "mask" true 0.0
                f.cage "SmallMouth" #(
                    #(true,true,#([0.087851,-0.564759,1.557773],[0.09691,-0.5916,1.59158],[0.100662,-0.6564,1.605584],[0.09691,-0.7212,1.59158],[0.087851,-0.748041,1.557773],[0.078793,-0.7212,1.523966],[0.075041,-0.6564,1.509963],[0.078793,-0.5916,1.523966])),
                    #(true,true,#([0.133135,-0.5268,1.545639],[0.145946,-0.564759,1.59345],[0.151252,-0.6564,1.613254],[0.145946,-0.748041,1.59345],[0.133135,-0.786,1.545639],[0.120324,-0.748041,1.497829],[0.115018,-0.6564,1.478025],[0.120324,-0.564759,1.497829])),
                    #(true,true,#([0.178419,-0.564759,1.533506],[0.187477,-0.5916,1.567313],[0.191229,-0.6564,1.581316],[0.187477,-0.7212,1.567313],[0.178419,-0.748041,1.533506],[0.16936,-0.7212,1.499698],[0.165608,-0.6564,1.485695],[0.16936,-0.5916,1.499698])),
                    #(false,true,#([0.069094,-0.6564,1.562799],[0.087851,-0.564759,1.557773],[0.133135,-0.5268,1.545639],[0.178419,-0.564759,1.533506],[0.197176,-0.6564,1.52848])),
                    #(false,true,#([0.069094,-0.6564,1.562799],[0.09691,-0.5916,1.59158],[0.145946,-0.564759,1.59345],[0.187477,-0.5916,1.567313],[0.197176,-0.6564,1.52848])),
                    #(false,true,#([0.069094,-0.6564,1.562799],[0.100662,-0.6564,1.605584],[0.151252,-0.6564,1.613254],[0.191229,-0.6564,1.581316],[0.197176,-0.6564,1.52848])),
                    #(false,true,#([0.069094,-0.6564,1.562799],[0.09691,-0.7212,1.59158],[0.145946,-0.748041,1.59345],[0.187477,-0.7212,1.567313],[0.197176,-0.6564,1.52848])),
                    #(false,true,#([0.069094,-0.6564,1.562799],[0.087851,-0.748041,1.557773],[0.133135,-0.786,1.545639],[0.178419,-0.748041,1.533506],[0.197176,-0.6564,1.52848])),
                    #(false,true,#([0.069094,-0.6564,1.562799],[0.078793,-0.7212,1.523966],[0.120324,-0.748041,1.497829],[0.16936,-0.7212,1.499698],[0.197176,-0.6564,1.52848])),
                    #(false,true,#([0.069094,-0.6564,1.562799],[0.075041,-0.6564,1.509963],[0.115018,-0.6564,1.478025],[0.165608,-0.6564,1.485695],[0.197176,-0.6564,1.52848])),
                    #(false,true,#([0.069094,-0.6564,1.562799],[0.078793,-0.5916,1.523966],[0.120324,-0.564759,1.497829],[0.16936,-0.5916,1.499698],[0.197176,-0.6564,1.52848]))
                ) "dark" "mask" true 0.0
                f.tube "RepairThread" #([-0.67,-0.84,0.31],[-0.44,-0.86,0.42],[-0.15,-0.85,0.47],[0.02,-0.83,0.58]) 0.067 5 false true "cyan_glow" "body"
                f.cage "FirstStitch" #(
                    #(true,false,#([-0.6,-0.94,0.23],[-0.44,-0.94,0.23],[-0.44,-0.8,0.23],[-0.6,-0.8,0.23])),
                    #(true,false,#([-0.6,-0.94,0.37],[-0.44,-0.94,0.37],[-0.44,-0.8,0.37],[-0.6,-0.8,0.37])),
                    #(false,false,#([-0.6,-0.94,0.23],[-0.6,-0.94,0.37])),
                    #(false,false,#([-0.44,-0.94,0.23],[-0.44,-0.94,0.37])),
                    #(false,false,#([-0.44,-0.8,0.23],[-0.44,-0.8,0.37])),
                    #(false,false,#([-0.6,-0.8,0.23],[-0.6,-0.8,0.37]))
                ) "gold_glow" "body" true 0.0
                f.cage "SecondStitch" #(
                    #(true,false,#([-0.38,-0.94,0.26],[-0.22,-0.94,0.26],[-0.22,-0.8,0.26],[-0.38,-0.8,0.26])),
                    #(true,false,#([-0.38,-0.94,0.4],[-0.22,-0.94,0.4],[-0.22,-0.8,0.4],[-0.38,-0.8,0.4])),
                    #(false,false,#([-0.38,-0.94,0.26],[-0.38,-0.94,0.4])),
                    #(false,false,#([-0.22,-0.94,0.26],[-0.22,-0.94,0.4])),
                    #(false,false,#([-0.22,-0.8,0.26],[-0.22,-0.8,0.4])),
                    #(false,false,#([-0.38,-0.8,0.26],[-0.38,-0.8,0.4]))
                ) "gold_glow" "body" true 0.0
                f.finishModel()
                f.startModel "paradehelper3" "The crane courier" "helper" 3 0.13 [0.0,-0.02,1.33] "A hurrying round-bodied courier carrying a folded crane above its head." true
                f.cage "PlantedFoot" #(
                    #(true,true,#([-0.298995,0.053848,0.11],[-0.298995,0.0,0.165],[-0.298995,-0.13,0.187782],[-0.298995,-0.26,0.165],[-0.298995,-0.313848,0.11],[-0.298995,-0.26,0.055],[-0.298995,-0.13,0.032218],[-0.298995,0.0,0.055])),
                    #(true,true,#([-0.2,0.13,0.11],[-0.2,0.053848,0.187782],[-0.2,-0.13,0.22],[-0.2,-0.313848,0.187782],[-0.2,-0.39,0.11],[-0.2,-0.313848,0.032218],[-0.2,-0.13,0.0],[-0.2,0.053848,0.032218])),
                    #(true,true,#([-0.101005,0.053848,0.11],[-0.101005,0.0,0.165],[-0.101005,-0.13,0.187782],[-0.101005,-0.26,0.165],[-0.101005,-0.313848,0.11],[-0.101005,-0.26,0.055],[-0.101005,-0.13,0.032218],[-0.101005,0.0,0.055])),
                    #(false,true,#([-0.34,-0.13,0.11],[-0.298995,0.053848,0.11],[-0.2,0.13,0.11],[-0.101005,0.053848,0.11],[-0.06,-0.13,0.11])),
                    #(false,true,#([-0.34,-0.13,0.11],[-0.298995,0.0,0.165],[-0.2,0.053848,0.187782],[-0.101005,0.0,0.165],[-0.06,-0.13,0.11])),
                    #(false,true,#([-0.34,-0.13,0.11],[-0.298995,-0.13,0.187782],[-0.2,-0.13,0.22],[-0.101005,-0.13,0.187782],[-0.06,-0.13,0.11])),
                    #(false,true,#([-0.34,-0.13,0.11],[-0.298995,-0.26,0.165],[-0.2,-0.313848,0.187782],[-0.101005,-0.26,0.165],[-0.06,-0.13,0.11])),
                    #(false,true,#([-0.34,-0.13,0.11],[-0.298995,-0.313848,0.11],[-0.2,-0.39,0.11],[-0.101005,-0.313848,0.11],[-0.06,-0.13,0.11])),
                    #(false,true,#([-0.34,-0.13,0.11],[-0.298995,-0.26,0.055],[-0.2,-0.313848,0.032218],[-0.101005,-0.26,0.055],[-0.06,-0.13,0.11])),
                    #(false,true,#([-0.34,-0.13,0.11],[-0.298995,-0.13,0.032218],[-0.2,-0.13,0.0],[-0.101005,-0.13,0.032218],[-0.06,-0.13,0.11])),
                    #(false,true,#([-0.34,-0.13,0.11],[-0.298995,0.0,0.055],[-0.2,0.053848,0.032218],[-0.101005,0.0,0.055],[-0.06,-0.13,0.11]))
                ) "ivory_glow" "body" true 0.0
                f.cage "LiftedFoot" #(
                    #(true,true,#([0.301005,0.379706,0.34],[0.301005,0.33,0.395],[0.301005,0.21,0.417782],[0.301005,0.09,0.395],[0.301005,0.040294,0.34],[0.301005,0.09,0.285],[0.301005,0.21,0.262218],[0.301005,0.33,0.285])),
                    #(true,true,#([0.4,0.45,0.34],[0.4,0.379706,0.417782],[0.4,0.21,0.45],[0.4,0.040294,0.417782],[0.4,-0.03,0.34],[0.4,0.040294,0.262218],[0.4,0.21,0.23],[0.4,0.379706,0.262218])),
                    #(true,true,#([0.498995,0.379706,0.34],[0.498995,0.33,0.395],[0.498995,0.21,0.417782],[0.498995,0.09,0.395],[0.498995,0.040294,0.34],[0.498995,0.09,0.285],[0.498995,0.21,0.262218],[0.498995,0.33,0.285])),
                    #(false,true,#([0.26,0.21,0.34],[0.301005,0.379706,0.34],[0.4,0.45,0.34],[0.498995,0.379706,0.34],[0.54,0.21,0.34])),
                    #(false,true,#([0.26,0.21,0.34],[0.301005,0.33,0.395],[0.4,0.379706,0.417782],[0.498995,0.33,0.395],[0.54,0.21,0.34])),
                    #(false,true,#([0.26,0.21,0.34],[0.301005,0.21,0.417782],[0.4,0.21,0.45],[0.498995,0.21,0.417782],[0.54,0.21,0.34])),
                    #(false,true,#([0.26,0.21,0.34],[0.301005,0.09,0.395],[0.4,0.040294,0.417782],[0.498995,0.09,0.395],[0.54,0.21,0.34])),
                    #(false,true,#([0.26,0.21,0.34],[0.301005,0.040294,0.34],[0.4,-0.03,0.34],[0.498995,0.040294,0.34],[0.54,0.21,0.34])),
                    #(false,true,#([0.26,0.21,0.34],[0.301005,0.09,0.285],[0.4,0.040294,0.262218],[0.498995,0.09,0.285],[0.54,0.21,0.34])),
                    #(false,true,#([0.26,0.21,0.34],[0.301005,0.21,0.262218],[0.4,0.21,0.23],[0.498995,0.21,0.262218],[0.54,0.21,0.34])),
                    #(false,true,#([0.26,0.21,0.34],[0.301005,0.33,0.285],[0.4,0.379706,0.262218],[0.498995,0.33,0.285],[0.54,0.21,0.34]))
                ) "ivory_glow" "body" true 0.0
                f.cage "PlantedLeg" #(
                    #(true,true,#([-0.319834,-0.06,0.153693],[-0.285762,-0.142575,0.175043],[-0.201452,-0.176778,0.187582],[-0.116291,-0.142575,0.183963],[-0.080166,-0.06,0.166307],[-0.114238,0.022575,0.144957],[-0.198548,0.056778,0.132418],[-0.283709,0.022575,0.136037])),
                    #(true,true,#([-0.358236,0.034178,0.561758],[-0.319879,-0.065868,0.560818],[-0.223015,-0.109756,0.547683],[-0.124385,-0.071777,0.530047],[-0.081764,0.025822,0.518242],[-0.120121,0.125868,0.519182],[-0.216985,0.169756,0.532317],[-0.315615,0.131777,0.549953])),
                    #(true,true,#([-0.27999,0.003179,0.803784],[-0.246102,-0.102862,0.775725],[-0.150061,-0.148647,0.732598],[-0.048126,-0.107357,0.699664],[-0.00001,-0.003179,0.696216],[-0.033898,0.102862,0.724275],[-0.129939,0.148647,0.767402],[-0.231874,0.107357,0.800336])),
                    #(false,true,#([-0.2,-0.06,0.16],[-0.319834,-0.06,0.153693],[-0.358236,0.034178,0.561758],[-0.27999,0.003179,0.803784],[-0.14,0.0,0.75])),
                    #(false,true,#([-0.2,-0.06,0.16],[-0.285762,-0.142575,0.175043],[-0.319879,-0.065868,0.560818],[-0.246102,-0.102862,0.775725],[-0.14,0.0,0.75])),
                    #(false,true,#([-0.2,-0.06,0.16],[-0.201452,-0.176778,0.187582],[-0.223015,-0.109756,0.547683],[-0.150061,-0.148647,0.732598],[-0.14,0.0,0.75])),
                    #(false,true,#([-0.2,-0.06,0.16],[-0.116291,-0.142575,0.183963],[-0.124385,-0.071777,0.530047],[-0.048126,-0.107357,0.699664],[-0.14,0.0,0.75])),
                    #(false,true,#([-0.2,-0.06,0.16],[-0.080166,-0.06,0.166307],[-0.081764,0.025822,0.518242],[-0.00001,-0.003179,0.696216],[-0.14,0.0,0.75])),
                    #(false,true,#([-0.2,-0.06,0.16],[-0.114238,0.022575,0.144957],[-0.120121,0.125868,0.519182],[-0.033898,0.102862,0.724275],[-0.14,0.0,0.75])),
                    #(false,true,#([-0.2,-0.06,0.16],[-0.198548,0.056778,0.132418],[-0.216985,0.169756,0.532317],[-0.129939,0.148647,0.767402],[-0.14,0.0,0.75])),
                    #(false,true,#([-0.2,-0.06,0.16],[-0.283709,0.022575,0.136037],[-0.315615,0.131777,0.549953],[-0.231874,0.107357,0.800336],[-0.14,0.0,0.75]))
                ) "ivory_glow" "body" true 0.0
                f.cage "LiftedLeg" #(
                    #(true,true,#([0.444567,0.351417,0.4],[0.363908,0.345826,0.356432],[0.304391,0.278244,0.338385],[0.300881,0.188258,0.356432],[0.355433,0.128583,0.4],[0.436092,0.134174,0.443568],[0.495609,0.201756,0.461615],[0.499119,0.291742,0.443568])),
                    #(true,true,#([0.316674,0.406051,0.638594],[0.228154,0.40015,0.578503],[0.181721,0.323867,0.51929],[0.204574,0.221887,0.495639],[0.283326,0.153949,0.521406],[0.371846,0.15985,0.581497],[0.418279,0.236133,0.64071],[0.395426,0.338113,0.664361])),
                    #(true,true,#([0.111531,0.096329,0.903488],[0.022431,0.096128,0.831091],[-0.003656,0.039616,0.734623],[0.04855,-0.040103,0.670594],[0.148469,-0.096329,0.676512],[0.237569,-0.096128,0.748909],[0.263656,-0.039616,0.845377],[0.21145,0.040103,0.909406])),
                    #(false,true,#([0.4,0.24,0.4],[0.444567,0.351417,0.4],[0.316674,0.406051,0.638594],[0.111531,0.096329,0.903488],[0.13,0.0,0.79])),
                    #(false,true,#([0.4,0.24,0.4],[0.363908,0.345826,0.356432],[0.228154,0.40015,0.578503],[0.022431,0.096128,0.831091],[0.13,0.0,0.79])),
                    #(false,true,#([0.4,0.24,0.4],[0.304391,0.278244,0.338385],[0.181721,0.323867,0.51929],[-0.003656,0.039616,0.734623],[0.13,0.0,0.79])),
                    #(false,true,#([0.4,0.24,0.4],[0.300881,0.188258,0.356432],[0.204574,0.221887,0.495639],[0.04855,-0.040103,0.670594],[0.13,0.0,0.79])),
                    #(false,true,#([0.4,0.24,0.4],[0.355433,0.128583,0.4],[0.283326,0.153949,0.521406],[0.148469,-0.096329,0.676512],[0.13,0.0,0.79])),
                    #(false,true,#([0.4,0.24,0.4],[0.436092,0.134174,0.443568],[0.371846,0.15985,0.581497],[0.237569,-0.096128,0.748909],[0.13,0.0,0.79])),
                    #(false,true,#([0.4,0.24,0.4],[0.495609,0.201756,0.461615],[0.418279,0.236133,0.64071],[0.263656,-0.039616,0.845377],[0.13,0.0,0.79])),
                    #(false,true,#([0.4,0.24,0.4],[0.499119,0.291742,0.443568],[0.395426,0.338113,0.664361],[0.21145,0.040103,0.909406],[0.13,0.0,0.79]))
                ) "ivory_glow" "body" true 0.0
                f.cage "RoundBody" #(
                    #(true,true,#([-0.268701,0.205061,0.99],[-0.268701,0.145,1.22],[-0.268701,0.0,1.315269],[-0.268701,-0.145,1.22],[-0.268701,-0.205061,0.99],[-0.268701,-0.145,0.76],[-0.268701,0.0,0.664731],[-0.268701,0.145,0.76])),
                    #(true,true,#([0.0,0.29,0.99],[0.0,0.205061,1.315269],[0.0,0.0,1.45],[0.0,-0.205061,1.315269],[0.0,-0.29,0.99],[0.0,-0.205061,0.664731],[0.0,0.0,0.53],[0.0,0.205061,0.664731])),
                    #(true,true,#([0.268701,0.205061,0.99],[0.268701,0.145,1.22],[0.268701,0.0,1.315269],[0.268701,-0.145,1.22],[0.268701,-0.205061,0.99],[0.268701,-0.145,0.76],[0.268701,0.0,0.664731],[0.268701,0.145,0.76])),
                    #(false,true,#([-0.38,0.0,0.99],[-0.268701,0.205061,0.99],[0.0,0.29,0.99],[0.268701,0.205061,0.99],[0.38,0.0,0.99])),
                    #(false,true,#([-0.38,0.0,0.99],[-0.268701,0.145,1.22],[0.0,0.205061,1.315269],[0.268701,0.145,1.22],[0.38,0.0,0.99])),
                    #(false,true,#([-0.38,0.0,0.99],[-0.268701,0.0,1.315269],[0.0,0.0,1.45],[0.268701,0.0,1.315269],[0.38,0.0,0.99])),
                    #(false,true,#([-0.38,0.0,0.99],[-0.268701,-0.145,1.22],[0.0,-0.205061,1.315269],[0.268701,-0.145,1.22],[0.38,0.0,0.99])),
                    #(false,true,#([-0.38,0.0,0.99],[-0.268701,-0.205061,0.99],[0.0,-0.29,0.99],[0.268701,-0.205061,0.99],[0.38,0.0,0.99])),
                    #(false,true,#([-0.38,0.0,0.99],[-0.268701,-0.145,0.76],[0.0,-0.205061,0.664731],[0.268701,-0.145,0.76],[0.38,0.0,0.99])),
                    #(false,true,#([-0.38,0.0,0.99],[-0.268701,0.0,0.664731],[0.0,0.0,0.53],[0.268701,0.0,0.664731],[0.38,0.0,0.99])),
                    #(false,true,#([-0.38,0.0,0.99],[-0.268701,0.145,0.76],[0.0,0.205061,0.664731],[0.268701,0.145,0.76],[0.38,0.0,0.99]))
                ) "ivory_glow" "body" true 0.0
                f.cage "LeftRaisedArm" #(
                    #(true,true,#([-0.379838,0.0,1.171671],[-0.345793,-0.084725,1.181568],[-0.26735,-0.119819,1.213977],[-0.190459,-0.084725,1.249915],[-0.160162,0.0,1.268329],[-0.194207,0.084725,1.258432],[-0.27265,0.119819,1.226023],[-0.349541,0.084725,1.190085])),
                    #(true,true,#([-0.58838,-0.030979,1.7021],[-0.558527,-0.101372,1.705505],[-0.488532,-0.129955,1.717401],[-0.419397,-0.099987,1.730819],[-0.39162,-0.029021,1.7379],[-0.421473,0.041372,1.734495],[-0.491468,0.069955,1.722599],[-0.560603,0.039987,1.709181])),
                    #(true,true,#([-0.529873,-0.031049,2.454377],[-0.505738,-0.087306,2.453054],[-0.448952,-0.109993,2.449943],[-0.39278,-0.085822,2.446865],[-0.370127,-0.028951,2.445623],[-0.394262,0.027306,2.446946],[-0.451048,0.049993,2.450057],[-0.50722,0.025822,2.453135])),
                    #(false,true,#([-0.27,0.0,1.22],[-0.379838,0.0,1.171671],[-0.58838,-0.030979,1.7021],[-0.529873,-0.031049,2.454377],[-0.45,-0.03,2.45])),
                    #(false,true,#([-0.27,0.0,1.22],[-0.345793,-0.084725,1.181568],[-0.558527,-0.101372,1.705505],[-0.505738,-0.087306,2.453054],[-0.45,-0.03,2.45])),
                    #(false,true,#([-0.27,0.0,1.22],[-0.26735,-0.119819,1.213977],[-0.488532,-0.129955,1.717401],[-0.448952,-0.109993,2.449943],[-0.45,-0.03,2.45])),
                    #(false,true,#([-0.27,0.0,1.22],[-0.190459,-0.084725,1.249915],[-0.419397,-0.099987,1.730819],[-0.39278,-0.085822,2.446865],[-0.45,-0.03,2.45])),
                    #(false,true,#([-0.27,0.0,1.22],[-0.160162,0.0,1.268329],[-0.39162,-0.029021,1.7379],[-0.370127,-0.028951,2.445623],[-0.45,-0.03,2.45])),
                    #(false,true,#([-0.27,0.0,1.22],[-0.194207,0.084725,1.258432],[-0.421473,0.041372,1.734495],[-0.394262,0.027306,2.446946],[-0.45,-0.03,2.45])),
                    #(false,true,#([-0.27,0.0,1.22],[-0.27265,0.119819,1.226023],[-0.491468,0.069955,1.722599],[-0.451048,0.049993,2.450057],[-0.45,-0.03,2.45])),
                    #(false,true,#([-0.27,0.0,1.22],[-0.349541,0.084725,1.190085],[-0.560603,0.039987,1.709181],[-0.50722,0.025822,2.453135],[-0.45,-0.03,2.45]))
                ) "ivory_glow" "body" true 0.0
                f.cage "RightRaisedArm" #(
                    #(true,true,#([0.156991,0.0,1.26036],[0.187225,-0.084424,1.240517],[0.265948,-0.119394,1.208655],[0.347044,-0.084424,1.183439],[0.383009,0.0,1.17964],[0.352775,0.084424,1.199483],[0.274052,0.119394,1.231345],[0.192956,0.084424,1.256561])),
                    #(true,true,#([0.37123,-0.058792,1.79559],[0.399003,-0.129823,1.789173],[0.468365,-0.159952,1.777382],[0.538685,-0.131531,1.767125],[0.56877,-0.061208,1.76441],[0.540997,0.009823,1.770827],[0.471635,0.039952,1.782618],[0.401315,0.011531,1.792875])),
                    #(true,true,#([0.370041,-0.029156,2.447575],[0.392788,-0.085912,2.450796],[0.449049,-0.109916,2.45355],[0.505867,-0.087105,2.454225],[0.529959,-0.030844,2.452425],[0.507212,0.025912,2.449204],[0.450951,0.049916,2.44645],[0.394133,0.027105,2.445775])),
                    #(false,true,#([0.27,0.0,1.22],[0.156991,0.0,1.26036],[0.37123,-0.058792,1.79559],[0.370041,-0.029156,2.447575],[0.45,-0.03,2.45])),
                    #(false,true,#([0.27,0.0,1.22],[0.187225,-0.084424,1.240517],[0.399003,-0.129823,1.789173],[0.392788,-0.085912,2.450796],[0.45,-0.03,2.45])),
                    #(false,true,#([0.27,0.0,1.22],[0.265948,-0.119394,1.208655],[0.468365,-0.159952,1.777382],[0.449049,-0.109916,2.45355],[0.45,-0.03,2.45])),
                    #(false,true,#([0.27,0.0,1.22],[0.347044,-0.084424,1.183439],[0.538685,-0.131531,1.767125],[0.505867,-0.087105,2.454225],[0.45,-0.03,2.45])),
                    #(false,true,#([0.27,0.0,1.22],[0.383009,0.0,1.17964],[0.56877,-0.061208,1.76441],[0.529959,-0.030844,2.452425],[0.45,-0.03,2.45])),
                    #(false,true,#([0.27,0.0,1.22],[0.352775,0.084424,1.199483],[0.540997,0.009823,1.770827],[0.507212,0.025912,2.449204],[0.45,-0.03,2.45])),
                    #(false,true,#([0.27,0.0,1.22],[0.274052,0.119394,1.231345],[0.471635,0.039952,1.782618],[0.450951,0.049916,2.44645],[0.45,-0.03,2.45])),
                    #(false,true,#([0.27,0.0,1.22],[0.192956,0.084424,1.256561],[0.401315,0.011531,1.792875],[0.394133,0.027105,2.445775],[0.45,-0.03,2.45]))
                ) "ivory_glow" "body" true 0.0
                f.cage "LeftHand" #(
                    #(true,true,#([-0.534853,0.040711,2.44],[-0.534853,0.02,2.505],[-0.534853,-0.03,2.531924],[-0.534853,-0.08,2.505],[-0.534853,-0.100711,2.44],[-0.534853,-0.08,2.375],[-0.534853,-0.03,2.348076],[-0.534853,0.02,2.375])),
                    #(true,true,#([-0.45,0.07,2.44],[-0.45,0.040711,2.531924],[-0.45,-0.03,2.57],[-0.45,-0.100711,2.531924],[-0.45,-0.13,2.44],[-0.45,-0.100711,2.348076],[-0.45,-0.03,2.31],[-0.45,0.040711,2.348076])),
                    #(true,true,#([-0.365147,0.040711,2.44],[-0.365147,0.02,2.505],[-0.365147,-0.03,2.531924],[-0.365147,-0.08,2.505],[-0.365147,-0.100711,2.44],[-0.365147,-0.08,2.375],[-0.365147,-0.03,2.348076],[-0.365147,0.02,2.375])),
                    #(false,true,#([-0.57,-0.03,2.44],[-0.534853,0.040711,2.44],[-0.45,0.07,2.44],[-0.365147,0.040711,2.44],[-0.33,-0.03,2.44])),
                    #(false,true,#([-0.57,-0.03,2.44],[-0.534853,0.02,2.505],[-0.45,0.040711,2.531924],[-0.365147,0.02,2.505],[-0.33,-0.03,2.44])),
                    #(false,true,#([-0.57,-0.03,2.44],[-0.534853,-0.03,2.531924],[-0.45,-0.03,2.57],[-0.365147,-0.03,2.531924],[-0.33,-0.03,2.44])),
                    #(false,true,#([-0.57,-0.03,2.44],[-0.534853,-0.08,2.505],[-0.45,-0.100711,2.531924],[-0.365147,-0.08,2.505],[-0.33,-0.03,2.44])),
                    #(false,true,#([-0.57,-0.03,2.44],[-0.534853,-0.100711,2.44],[-0.45,-0.13,2.44],[-0.365147,-0.100711,2.44],[-0.33,-0.03,2.44])),
                    #(false,true,#([-0.57,-0.03,2.44],[-0.534853,-0.08,2.375],[-0.45,-0.100711,2.348076],[-0.365147,-0.08,2.375],[-0.33,-0.03,2.44])),
                    #(false,true,#([-0.57,-0.03,2.44],[-0.534853,-0.03,2.348076],[-0.45,-0.03,2.31],[-0.365147,-0.03,2.348076],[-0.33,-0.03,2.44])),
                    #(false,true,#([-0.57,-0.03,2.44],[-0.534853,0.02,2.375],[-0.45,0.040711,2.348076],[-0.365147,0.02,2.375],[-0.33,-0.03,2.44]))
                ) "ivory_glow" "body" true 0.0
                f.cage "RightHand" #(
                    #(true,true,#([0.365147,0.040711,2.44],[0.365147,0.02,2.505],[0.365147,-0.03,2.531924],[0.365147,-0.08,2.505],[0.365147,-0.100711,2.44],[0.365147,-0.08,2.375],[0.365147,-0.03,2.348076],[0.365147,0.02,2.375])),
                    #(true,true,#([0.45,0.07,2.44],[0.45,0.040711,2.531924],[0.45,-0.03,2.57],[0.45,-0.100711,2.531924],[0.45,-0.13,2.44],[0.45,-0.100711,2.348076],[0.45,-0.03,2.31],[0.45,0.040711,2.348076])),
                    #(true,true,#([0.534853,0.040711,2.44],[0.534853,0.02,2.505],[0.534853,-0.03,2.531924],[0.534853,-0.08,2.505],[0.534853,-0.100711,2.44],[0.534853,-0.08,2.375],[0.534853,-0.03,2.348076],[0.534853,0.02,2.375])),
                    #(false,true,#([0.33,-0.03,2.44],[0.365147,0.040711,2.44],[0.45,0.07,2.44],[0.534853,0.040711,2.44],[0.57,-0.03,2.44])),
                    #(false,true,#([0.33,-0.03,2.44],[0.365147,0.02,2.505],[0.45,0.040711,2.531924],[0.534853,0.02,2.505],[0.57,-0.03,2.44])),
                    #(false,true,#([0.33,-0.03,2.44],[0.365147,-0.03,2.531924],[0.45,-0.03,2.57],[0.534853,-0.03,2.531924],[0.57,-0.03,2.44])),
                    #(false,true,#([0.33,-0.03,2.44],[0.365147,-0.08,2.505],[0.45,-0.100711,2.531924],[0.534853,-0.08,2.505],[0.57,-0.03,2.44])),
                    #(false,true,#([0.33,-0.03,2.44],[0.365147,-0.100711,2.44],[0.45,-0.13,2.44],[0.534853,-0.100711,2.44],[0.57,-0.03,2.44])),
                    #(false,true,#([0.33,-0.03,2.44],[0.365147,-0.08,2.375],[0.45,-0.100711,2.348076],[0.534853,-0.08,2.375],[0.57,-0.03,2.44])),
                    #(false,true,#([0.33,-0.03,2.44],[0.365147,-0.03,2.348076],[0.45,-0.03,2.31],[0.534853,-0.03,2.348076],[0.57,-0.03,2.44])),
                    #(false,true,#([0.33,-0.03,2.44],[0.365147,0.02,2.375],[0.45,0.040711,2.348076],[0.534853,0.02,2.375],[0.57,-0.03,2.44]))
                ) "ivory_glow" "body" true 0.0
                f.cage "Head" #(
                    #(true,true,#([-0.492434,0.205772,1.801655],[-0.542792,0.125,2.087249],[-0.563651,-0.07,2.205547],[-0.542792,-0.265,2.087249],[-0.492434,-0.345772,1.801655],[-0.442076,-0.265,1.516061],[-0.421217,-0.07,1.397764],[-0.442076,0.125,1.516061])),
                    #(true,true,#([-0.095506,0.32,1.871644],[-0.166723,0.205772,2.275536],[-0.196222,-0.07,2.442833],[-0.166723,-0.345772,2.275536],[-0.095506,-0.46,1.871644],[-0.02429,-0.345772,1.467753],[0.005209,-0.07,1.300456],[-0.02429,0.205772,1.467753])),
                    #(true,true,#([0.301421,0.205772,1.941633],[0.251063,0.125,2.227228],[0.230204,-0.07,2.345525],[0.251063,-0.265,2.227228],[0.301421,-0.345772,1.941633],[0.351779,-0.265,1.656039],[0.372638,-0.07,1.537742],[0.351779,0.125,1.656039])),
                    #(false,true,#([-0.656847,-0.07,1.772665],[-0.492434,0.205772,1.801655],[-0.095506,0.32,1.871644],[0.301421,0.205772,1.941633],[0.465834,-0.07,1.970624])),
                    #(false,true,#([-0.656847,-0.07,1.772665],[-0.542792,0.125,2.087249],[-0.166723,0.205772,2.275536],[0.251063,0.125,2.227228],[0.465834,-0.07,1.970624])),
                    #(false,true,#([-0.656847,-0.07,1.772665],[-0.563651,-0.07,2.205547],[-0.196222,-0.07,2.442833],[0.230204,-0.07,2.345525],[0.465834,-0.07,1.970624])),
                    #(false,true,#([-0.656847,-0.07,1.772665],[-0.542792,-0.265,2.087249],[-0.166723,-0.345772,2.275536],[0.251063,-0.265,2.227228],[0.465834,-0.07,1.970624])),
                    #(false,true,#([-0.656847,-0.07,1.772665],[-0.492434,-0.345772,1.801655],[-0.095506,-0.46,1.871644],[0.301421,-0.345772,1.941633],[0.465834,-0.07,1.970624])),
                    #(false,true,#([-0.656847,-0.07,1.772665],[-0.442076,-0.265,1.516061],[-0.02429,-0.345772,1.467753],[0.351779,-0.265,1.656039],[0.465834,-0.07,1.970624])),
                    #(false,true,#([-0.656847,-0.07,1.772665],[-0.421217,-0.07,1.397764],[0.005209,-0.07,1.300456],[0.372638,-0.07,1.537742],[0.465834,-0.07,1.970624])),
                    #(false,true,#([-0.656847,-0.07,1.772665],[-0.442076,0.125,1.516061],[-0.02429,0.205772,1.467753],[0.351779,0.125,1.656039],[0.465834,-0.07,1.970624]))
                ) "cream" "head" true 0.0
                f.cage "FacePlate" #(
                    #(true,true,#([-0.381016,-0.318076,1.821301],[-0.420955,-0.345,2.047807],[-0.437498,-0.41,2.141629],[-0.420955,-0.475,2.047807],[-0.381016,-0.501924,1.821301],[-0.341077,-0.475,1.594795],[-0.324534,-0.41,1.500974],[-0.341077,-0.345,1.594795])),
                    #(true,true,#([-0.095506,-0.28,1.871644],[-0.151989,-0.318076,2.191972],[-0.175385,-0.41,2.324656],[-0.151989,-0.501924,2.191972],[-0.095506,-0.54,1.871644],[-0.039024,-0.501924,1.551317],[-0.015628,-0.41,1.418633],[-0.039024,-0.318076,1.551317])),
                    #(true,true,#([0.190003,-0.318076,1.921987],[0.150064,-0.345,2.148493],[0.133521,-0.41,2.242315],[0.150064,-0.475,2.148493],[0.190003,-0.501924,1.921987],[0.229942,-0.475,1.695482],[0.246485,-0.41,1.60166],[0.229942,-0.345,1.695482])),
                    #(false,true,#([-0.499278,-0.41,1.800449],[-0.381016,-0.318076,1.821301],[-0.095506,-0.28,1.871644],[0.190003,-0.318076,1.921987],[0.308265,-0.41,1.94284])),
                    #(false,true,#([-0.499278,-0.41,1.800449],[-0.420955,-0.345,2.047807],[-0.151989,-0.318076,2.191972],[0.150064,-0.345,2.148493],[0.308265,-0.41,1.94284])),
                    #(false,true,#([-0.499278,-0.41,1.800449],[-0.437498,-0.41,2.141629],[-0.175385,-0.41,2.324656],[0.133521,-0.41,2.242315],[0.308265,-0.41,1.94284])),
                    #(false,true,#([-0.499278,-0.41,1.800449],[-0.420955,-0.475,2.047807],[-0.151989,-0.501924,2.191972],[0.150064,-0.475,2.148493],[0.308265,-0.41,1.94284])),
                    #(false,true,#([-0.499278,-0.41,1.800449],[-0.381016,-0.501924,1.821301],[-0.095506,-0.54,1.871644],[0.190003,-0.501924,1.921987],[0.308265,-0.41,1.94284])),
                    #(false,true,#([-0.499278,-0.41,1.800449],[-0.341077,-0.475,1.594795],[-0.039024,-0.501924,1.551317],[0.229942,-0.475,1.695482],[0.308265,-0.41,1.94284])),
                    #(false,true,#([-0.499278,-0.41,1.800449],[-0.324534,-0.41,1.500974],[-0.015628,-0.41,1.418633],[0.246485,-0.41,1.60166],[0.308265,-0.41,1.94284])),
                    #(false,true,#([-0.499278,-0.41,1.800449],[-0.341077,-0.345,1.594795],[-0.039024,-0.318076,1.551317],[0.229942,-0.345,1.695482],[0.308265,-0.41,1.94284]))
                ) "ivory_glow" "mask" true 0.0
                f.cage "EyeLeft" #(
                    #(true,true,#([-0.356066,-0.448707,1.909778],[-0.366485,-0.4724,1.968866],[-0.3708,-0.5296,1.993342],[-0.366485,-0.5868,1.968866],[-0.356066,-0.610493,1.909778],[-0.345647,-0.5868,1.850689],[-0.341331,-0.5296,1.826214],[-0.345647,-0.4724,1.850689])),
                    #(true,true,#([-0.287544,-0.4152,1.92186],[-0.302278,-0.448707,2.005424],[-0.308382,-0.5296,2.040037],[-0.302278,-0.610493,2.005424],[-0.287544,-0.644,1.92186],[-0.272809,-0.610493,1.838296],[-0.266706,-0.5296,1.803683],[-0.272809,-0.448707,1.838296])),
                    #(true,true,#([-0.219022,-0.448707,1.933942],[-0.229441,-0.4724,1.993031],[-0.233757,-0.5296,2.017506],[-0.229441,-0.5868,1.993031],[-0.219022,-0.610493,1.933942],[-0.208603,-0.5868,1.874854],[-0.204287,-0.5296,1.850379],[-0.208603,-0.4724,1.874854])),
                    #(false,true,#([-0.384449,-0.5296,1.904773],[-0.356066,-0.448707,1.909778],[-0.287544,-0.4152,1.92186],[-0.219022,-0.448707,1.933942],[-0.190639,-0.5296,1.938947])),
                    #(false,true,#([-0.384449,-0.5296,1.904773],[-0.366485,-0.4724,1.968866],[-0.302278,-0.448707,2.005424],[-0.229441,-0.4724,1.993031],[-0.190639,-0.5296,1.938947])),
                    #(false,true,#([-0.384449,-0.5296,1.904773],[-0.3708,-0.5296,1.993342],[-0.308382,-0.5296,2.040037],[-0.233757,-0.5296,2.017506],[-0.190639,-0.5296,1.938947])),
                    #(false,true,#([-0.384449,-0.5296,1.904773],[-0.366485,-0.5868,1.968866],[-0.302278,-0.610493,2.005424],[-0.229441,-0.5868,1.993031],[-0.190639,-0.5296,1.938947])),
                    #(false,true,#([-0.384449,-0.5296,1.904773],[-0.356066,-0.610493,1.909778],[-0.287544,-0.644,1.92186],[-0.219022,-0.610493,1.933942],[-0.190639,-0.5296,1.938947])),
                    #(false,true,#([-0.384449,-0.5296,1.904773],[-0.345647,-0.5868,1.850689],[-0.272809,-0.610493,1.838296],[-0.208603,-0.5868,1.874854],[-0.190639,-0.5296,1.938947])),
                    #(false,true,#([-0.384449,-0.5296,1.904773],[-0.341331,-0.5296,1.826214],[-0.266706,-0.5296,1.803683],[-0.204287,-0.5296,1.850379],[-0.190639,-0.5296,1.938947])),
                    #(false,true,#([-0.384449,-0.5296,1.904773],[-0.345647,-0.4724,1.850689],[-0.272809,-0.448707,1.838296],[-0.208603,-0.4724,1.874854],[-0.190639,-0.5296,1.938947]))
                ) "dark" "mask" true 0.0
                f.cage "EyeRight" #(
                    #(true,true,#([-0.000747,-0.448707,1.97243],[-0.011166,-0.4724,2.031519],[-0.015482,-0.5296,2.055994],[-0.011166,-0.5868,2.031519],[-0.000747,-0.610493,1.97243],[0.009672,-0.5868,1.913342],[0.013987,-0.5296,1.888866],[0.009672,-0.4724,1.913342])),
                    #(true,true,#([0.067775,-0.4152,1.984512],[0.05304,-0.448707,2.068076],[0.046937,-0.5296,2.102689],[0.05304,-0.610493,2.068076],[0.067775,-0.644,1.984512],[0.082509,-0.610493,1.900949],[0.088613,-0.5296,1.866336],[0.082509,-0.448707,1.900949])),
                    #(true,true,#([0.136297,-0.448707,1.996595],[0.125878,-0.4724,2.055683],[0.121562,-0.5296,2.080159],[0.125878,-0.5868,2.055683],[0.136297,-0.610493,1.996595],[0.146716,-0.5868,1.937506],[0.151031,-0.5296,1.913031],[0.146716,-0.4724,1.937506])),
                    #(false,true,#([-0.02913,-0.5296,1.967425],[-0.000747,-0.448707,1.97243],[0.067775,-0.4152,1.984512],[0.136297,-0.448707,1.996595],[0.16468,-0.5296,2.001599])),
                    #(false,true,#([-0.02913,-0.5296,1.967425],[-0.011166,-0.4724,2.031519],[0.05304,-0.448707,2.068076],[0.125878,-0.4724,2.055683],[0.16468,-0.5296,2.001599])),
                    #(false,true,#([-0.02913,-0.5296,1.967425],[-0.015482,-0.5296,2.055994],[0.046937,-0.5296,2.102689],[0.121562,-0.5296,2.080159],[0.16468,-0.5296,2.001599])),
                    #(false,true,#([-0.02913,-0.5296,1.967425],[-0.011166,-0.5868,2.031519],[0.05304,-0.610493,2.068076],[0.125878,-0.5868,2.055683],[0.16468,-0.5296,2.001599])),
                    #(false,true,#([-0.02913,-0.5296,1.967425],[-0.000747,-0.610493,1.97243],[0.067775,-0.644,1.984512],[0.136297,-0.610493,1.996595],[0.16468,-0.5296,2.001599])),
                    #(false,true,#([-0.02913,-0.5296,1.967425],[0.009672,-0.5868,1.913342],[0.082509,-0.610493,1.900949],[0.146716,-0.5868,1.937506],[0.16468,-0.5296,2.001599])),
                    #(false,true,#([-0.02913,-0.5296,1.967425],[0.013987,-0.5296,1.888866],[0.088613,-0.5296,1.866336],[0.151031,-0.5296,1.913031],[0.16468,-0.5296,2.001599])),
                    #(false,true,#([-0.02913,-0.5296,1.967425],[0.009672,-0.4724,1.913342],[0.082509,-0.448707,1.900949],[0.146716,-0.4724,1.937506],[0.16468,-0.5296,2.001599]))
                ) "dark" "mask" true 0.0
                f.cage "SmallMouth" #(
                    #(true,true,#([-0.053889,-0.471215,1.701486],[-0.059966,-0.4906,1.735954],[-0.062484,-0.5374,1.750231],[-0.059966,-0.5842,1.735954],[-0.053889,-0.603585,1.701486],[-0.047811,-0.5842,1.667018],[-0.045294,-0.5374,1.652741],[-0.047811,-0.4906,1.667018])),
                    #(true,true,#([-0.008625,-0.4438,1.709467],[-0.01722,-0.471215,1.758212],[-0.02078,-0.5374,1.778404],[-0.01722,-0.603585,1.758212],[-0.008625,-0.631,1.709467],[-0.00003,-0.603585,1.660722],[0.003531,-0.5374,1.640531],[-0.00003,-0.471215,1.660722])),
                    #(true,true,#([0.036639,-0.471215,1.717448],[0.030561,-0.4906,1.751917],[0.028044,-0.5374,1.766194],[0.030561,-0.5842,1.751917],[0.036639,-0.603585,1.717448],[0.042717,-0.5842,1.68298],[0.045234,-0.5374,1.668703],[0.042717,-0.4906,1.68298])),
                    #(false,true,#([-0.072637,-0.5374,1.69818],[-0.053889,-0.471215,1.701486],[-0.008625,-0.4438,1.709467],[0.036639,-0.471215,1.717448],[0.055388,-0.5374,1.720754])),
                    #(false,true,#([-0.072637,-0.5374,1.69818],[-0.059966,-0.4906,1.735954],[-0.01722,-0.471215,1.758212],[0.030561,-0.4906,1.751917],[0.055388,-0.5374,1.720754])),
                    #(false,true,#([-0.072637,-0.5374,1.69818],[-0.062484,-0.5374,1.750231],[-0.02078,-0.5374,1.778404],[0.028044,-0.5374,1.766194],[0.055388,-0.5374,1.720754])),
                    #(false,true,#([-0.072637,-0.5374,1.69818],[-0.059966,-0.5842,1.735954],[-0.01722,-0.603585,1.758212],[0.030561,-0.5842,1.751917],[0.055388,-0.5374,1.720754])),
                    #(false,true,#([-0.072637,-0.5374,1.69818],[-0.053889,-0.603585,1.701486],[-0.008625,-0.631,1.709467],[0.036639,-0.603585,1.717448],[0.055388,-0.5374,1.720754])),
                    #(false,true,#([-0.072637,-0.5374,1.69818],[-0.047811,-0.5842,1.667018],[-0.00003,-0.603585,1.660722],[0.042717,-0.5842,1.68298],[0.055388,-0.5374,1.720754])),
                    #(false,true,#([-0.072637,-0.5374,1.69818],[-0.045294,-0.5374,1.652741],[0.003531,-0.5374,1.640531],[0.045234,-0.5374,1.668703],[0.055388,-0.5374,1.720754])),
                    #(false,true,#([-0.072637,-0.5374,1.69818],[-0.047811,-0.4906,1.667018],[-0.00003,-0.471215,1.660722],[0.042717,-0.4906,1.68298],[0.055388,-0.5374,1.720754]))
                ) "dark" "mask" true 0.0
                f.cage "CraneBody" #(
                    #(true,false,#([-0.185582,-0.205371,2.425],[0.268404,-0.083726,2.425],[0.185582,0.225371,2.425],[-0.268404,0.103726,2.425])),
                    #(true,false,#([-0.185582,-0.205371,2.675],[0.268404,-0.083726,2.675],[0.185582,0.225371,2.675],[-0.268404,0.103726,2.675])),
                    #(false,false,#([-0.185582,-0.205371,2.425],[-0.185582,-0.205371,2.675])),
                    #(false,false,#([0.268404,-0.083726,2.425],[0.268404,-0.083726,2.675])),
                    #(false,false,#([0.185582,0.225371,2.425],[0.185582,0.225371,2.675])),
                    #(false,false,#([-0.268404,0.103726,2.425],[-0.268404,0.103726,2.675]))
                ) "gold_glow" "body" true 0.0
                f.cage "CraneLeftWing" #(
                    #(false,true,#([-0.150394,0.001613,2.560249],[-0.150197,0.005806,2.560125],[-0.15,0.01,2.56],[-0.149803,0.014194,2.559875],[-0.149606,0.018387,2.559751])),
                    #(false,true,#([-0.324527,-0.160284,2.721221],[-0.320863,-0.08239,2.718908],[-0.3172,-0.004497,2.716594],[-0.313537,0.073396,2.71428],[-0.309873,0.15129,2.711967])),
                    #(false,true,#([-0.54127,-0.24463,2.887118],[-0.535635,-0.124815,2.883559],[-0.53,-0.005,2.88],[-0.524365,0.114815,2.876441],[-0.51873,0.23463,2.872882])),
                    #(false,true,#([-0.750127,-0.132284,2.990021],[-0.746463,-0.05439,2.987708],[-0.7428,0.023503,2.985394],[-0.739137,0.101396,2.98308],[-0.735473,0.17929,2.980767])),
                    #(false,true,#([-0.910394,0.051613,3.040249],[-0.910197,0.055806,3.040125],[-0.91,0.06,3.04],[-0.909803,0.064194,3.039875],[-0.909606,0.068387,3.039751])),
                    #(false,true,#([-0.150394,0.001613,2.560249],[-0.324527,-0.160284,2.721221],[-0.54127,-0.24463,2.887118],[-0.750127,-0.132284,2.990021],[-0.910394,0.051613,3.040249])),
                    #(false,true,#([-0.150197,0.005806,2.560125],[-0.320863,-0.08239,2.718908],[-0.535635,-0.124815,2.883559],[-0.746463,-0.05439,2.987708],[-0.910197,0.055806,3.040125])),
                    #(false,true,#([-0.15,0.01,2.56],[-0.3172,-0.004497,2.716594],[-0.53,-0.005,2.88],[-0.7428,0.023503,2.985394],[-0.91,0.06,3.04])),
                    #(false,true,#([-0.149803,0.014194,2.559875],[-0.313537,0.073396,2.71428],[-0.524365,0.114815,2.876441],[-0.739137,0.101396,2.98308],[-0.909803,0.064194,3.039875])),
                    #(false,true,#([-0.149606,0.018387,2.559751],[-0.309873,0.15129,2.711967],[-0.51873,0.23463,2.872882],[-0.735473,0.17929,2.980767],[-0.909606,0.068387,3.039751]))
                ) "ivory_glow" "body" false 0.11
                f.cage "CraneRightWing" #(
                    #(false,true,#([0.150394,0.001613,2.560249],[0.150197,0.005806,2.560125],[0.15,0.01,2.56],[0.149803,0.014194,2.559875],[0.149606,0.018387,2.559751])),
                    #(false,true,#([0.324527,-0.160284,2.721221],[0.320863,-0.08239,2.718908],[0.3172,-0.004497,2.716594],[0.313537,0.073396,2.71428],[0.309873,0.15129,2.711967])),
                    #(false,true,#([0.54127,-0.24463,2.887118],[0.535635,-0.124815,2.883559],[0.53,-0.005,2.88],[0.524365,0.114815,2.876441],[0.51873,0.23463,2.872882])),
                    #(false,true,#([0.750127,-0.132284,2.990021],[0.746463,-0.05439,2.987708],[0.7428,0.023503,2.985394],[0.739137,0.101396,2.98308],[0.735473,0.17929,2.980767])),
                    #(false,true,#([0.910394,0.051613,3.040249],[0.910197,0.055806,3.040125],[0.91,0.06,3.04],[0.909803,0.064194,3.039875],[0.909606,0.068387,3.039751])),
                    #(false,true,#([0.150394,0.001613,2.560249],[0.324527,-0.160284,2.721221],[0.54127,-0.24463,2.887118],[0.750127,-0.132284,2.990021],[0.910394,0.051613,3.040249])),
                    #(false,true,#([0.150197,0.005806,2.560125],[0.320863,-0.08239,2.718908],[0.535635,-0.124815,2.883559],[0.746463,-0.05439,2.987708],[0.910197,0.055806,3.040125])),
                    #(false,true,#([0.15,0.01,2.56],[0.3172,-0.004497,2.716594],[0.53,-0.005,2.88],[0.7428,0.023503,2.985394],[0.91,0.06,3.04])),
                    #(false,true,#([0.149803,0.014194,2.559875],[0.313537,0.073396,2.71428],[0.524365,0.114815,2.876441],[0.739137,0.101396,2.98308],[0.909803,0.064194,3.039875])),
                    #(false,true,#([0.149606,0.018387,2.559751],[0.309873,0.15129,2.711967],[0.51873,0.23463,2.872882],[0.735473,0.17929,2.980767],[0.909606,0.068387,3.039751]))
                ) "ivory_glow" "body" false 0.11
                f.cage "CraneNeck" #(
                    #(true,true,#([-0.095,-0.1,2.57],[-0.067175,-0.142829,2.518249],[0.0,-0.160569,2.496813],[0.067175,-0.142829,2.518249],[0.095,-0.1,2.57],[0.067175,-0.057171,2.621751],[0.0,-0.039431,2.643187],[-0.067175,-0.057171,2.621751])),
                    #(true,true,#([-0.075,-0.39,2.81],[-0.053033,-0.400533,2.758023],[0.0,-0.404896,2.736494],[0.053033,-0.400533,2.758023],[0.075,-0.39,2.81],[0.053033,-0.379467,2.861977],[0.0,-0.375104,2.883506],[-0.053033,-0.379467,2.861977])),
                    #(true,true,#([-0.045,-0.49,2.78],[-0.03182,-0.480857,2.749522],[0.0,-0.477069,2.736898],[0.03182,-0.480857,2.749522],[0.045,-0.49,2.78],[0.03182,-0.499143,2.810478],[0.0,-0.502931,2.823102],[-0.03182,-0.499143,2.810478])),
                    #(false,true,#([0.0,-0.1,2.57],[-0.095,-0.1,2.57],[-0.075,-0.39,2.81],[-0.045,-0.49,2.78],[0.0,-0.49,2.78])),
                    #(false,true,#([0.0,-0.1,2.57],[-0.067175,-0.142829,2.518249],[-0.053033,-0.400533,2.758023],[-0.03182,-0.480857,2.749522],[0.0,-0.49,2.78])),
                    #(false,true,#([0.0,-0.1,2.57],[0.0,-0.160569,2.496813],[0.0,-0.404896,2.736494],[0.0,-0.477069,2.736898],[0.0,-0.49,2.78])),
                    #(false,true,#([0.0,-0.1,2.57],[0.067175,-0.142829,2.518249],[0.053033,-0.400533,2.758023],[0.03182,-0.480857,2.749522],[0.0,-0.49,2.78])),
                    #(false,true,#([0.0,-0.1,2.57],[0.095,-0.1,2.57],[0.075,-0.39,2.81],[0.045,-0.49,2.78],[0.0,-0.49,2.78])),
                    #(false,true,#([0.0,-0.1,2.57],[0.067175,-0.057171,2.621751],[0.053033,-0.379467,2.861977],[0.03182,-0.499143,2.810478],[0.0,-0.49,2.78])),
                    #(false,true,#([0.0,-0.1,2.57],[0.0,-0.039431,2.643187],[0.0,-0.375104,2.883506],[0.0,-0.502931,2.823102],[0.0,-0.49,2.78])),
                    #(false,true,#([0.0,-0.1,2.57],[-0.067175,-0.057171,2.621751],[-0.053033,-0.379467,2.861977],[-0.03182,-0.499143,2.810478],[0.0,-0.49,2.78]))
                ) "gold_glow" "body" true 0.0
                f.finishModel()
                f.startModel "paradehelper4" "The curious lookout" "helper" 4 0.13 [0.0,0.0,1.64] "A long-necked lookout with hands behind its back and a curious tilted mask." true
                f.cage "LeftFoot" #(
                    #(true,true,#([-0.326066,0.129706,0.11],[-0.326066,0.08,0.165],[-0.326066,-0.04,0.187782],[-0.326066,-0.16,0.165],[-0.326066,-0.209706,0.11],[-0.326066,-0.16,0.055],[-0.326066,-0.04,0.032218],[-0.326066,0.08,0.055])),
                    #(true,true,#([-0.22,0.2,0.11],[-0.22,0.129706,0.187782],[-0.22,-0.04,0.22],[-0.22,-0.209706,0.187782],[-0.22,-0.28,0.11],[-0.22,-0.209706,0.032218],[-0.22,-0.04,0.0],[-0.22,0.129706,0.032218])),
                    #(true,true,#([-0.113934,0.129706,0.11],[-0.113934,0.08,0.165],[-0.113934,-0.04,0.187782],[-0.113934,-0.16,0.165],[-0.113934,-0.209706,0.11],[-0.113934,-0.16,0.055],[-0.113934,-0.04,0.032218],[-0.113934,0.08,0.055])),
                    #(false,true,#([-0.37,-0.04,0.11],[-0.326066,0.129706,0.11],[-0.22,0.2,0.11],[-0.113934,0.129706,0.11],[-0.07,-0.04,0.11])),
                    #(false,true,#([-0.37,-0.04,0.11],[-0.326066,0.08,0.165],[-0.22,0.129706,0.187782],[-0.113934,0.08,0.165],[-0.07,-0.04,0.11])),
                    #(false,true,#([-0.37,-0.04,0.11],[-0.326066,-0.04,0.187782],[-0.22,-0.04,0.22],[-0.113934,-0.04,0.187782],[-0.07,-0.04,0.11])),
                    #(false,true,#([-0.37,-0.04,0.11],[-0.326066,-0.16,0.165],[-0.22,-0.209706,0.187782],[-0.113934,-0.16,0.165],[-0.07,-0.04,0.11])),
                    #(false,true,#([-0.37,-0.04,0.11],[-0.326066,-0.209706,0.11],[-0.22,-0.28,0.11],[-0.113934,-0.209706,0.11],[-0.07,-0.04,0.11])),
                    #(false,true,#([-0.37,-0.04,0.11],[-0.326066,-0.16,0.055],[-0.22,-0.209706,0.032218],[-0.113934,-0.16,0.055],[-0.07,-0.04,0.11])),
                    #(false,true,#([-0.37,-0.04,0.11],[-0.326066,-0.04,0.032218],[-0.22,-0.04,0.0],[-0.113934,-0.04,0.032218],[-0.07,-0.04,0.11])),
                    #(false,true,#([-0.37,-0.04,0.11],[-0.326066,0.08,0.055],[-0.22,0.129706,0.032218],[-0.113934,0.08,0.055],[-0.07,-0.04,0.11]))
                ) "ivory_glow" "body" true 0.0
                f.cage "RightFoot" #(
                    #(true,true,#([0.123934,0.199706,0.11],[0.123934,0.15,0.165],[0.123934,0.03,0.187782],[0.123934,-0.09,0.165],[0.123934,-0.139706,0.11],[0.123934,-0.09,0.055],[0.123934,0.03,0.032218],[0.123934,0.15,0.055])),
                    #(true,true,#([0.23,0.27,0.11],[0.23,0.199706,0.187782],[0.23,0.03,0.22],[0.23,-0.139706,0.187782],[0.23,-0.21,0.11],[0.23,-0.139706,0.032218],[0.23,0.03,0.0],[0.23,0.199706,0.032218])),
                    #(true,true,#([0.336066,0.199706,0.11],[0.336066,0.15,0.165],[0.336066,0.03,0.187782],[0.336066,-0.09,0.165],[0.336066,-0.139706,0.11],[0.336066,-0.09,0.055],[0.336066,0.03,0.032218],[0.336066,0.15,0.055])),
                    #(false,true,#([0.08,0.03,0.11],[0.123934,0.199706,0.11],[0.23,0.27,0.11],[0.336066,0.199706,0.11],[0.38,0.03,0.11])),
                    #(false,true,#([0.08,0.03,0.11],[0.123934,0.15,0.165],[0.23,0.199706,0.187782],[0.336066,0.15,0.165],[0.38,0.03,0.11])),
                    #(false,true,#([0.08,0.03,0.11],[0.123934,0.03,0.187782],[0.23,0.03,0.22],[0.336066,0.03,0.187782],[0.38,0.03,0.11])),
                    #(false,true,#([0.08,0.03,0.11],[0.123934,-0.09,0.165],[0.23,-0.139706,0.187782],[0.336066,-0.09,0.165],[0.38,0.03,0.11])),
                    #(false,true,#([0.08,0.03,0.11],[0.123934,-0.139706,0.11],[0.23,-0.21,0.11],[0.336066,-0.139706,0.11],[0.38,0.03,0.11])),
                    #(false,true,#([0.08,0.03,0.11],[0.123934,-0.09,0.055],[0.23,-0.139706,0.032218],[0.336066,-0.09,0.055],[0.38,0.03,0.11])),
                    #(false,true,#([0.08,0.03,0.11],[0.123934,0.03,0.032218],[0.23,0.03,0.0],[0.336066,0.03,0.032218],[0.38,0.03,0.11])),
                    #(false,true,#([0.08,0.03,0.11],[0.123934,0.15,0.055],[0.23,0.199706,0.032218],[0.336066,0.15,0.055],[0.38,0.03,0.11]))
                ) "ivory_glow" "body" true 0.0
                f.cage "LeftLeg" #(
                    #(true,true,#([-0.339656,0.0,0.159077],[-0.303735,-0.084061,0.167947],[-0.218763,-0.118881,0.166304],[-0.134516,-0.084061,0.15511],[-0.100344,0.0,0.140923],[-0.136265,0.084061,0.132053],[-0.221237,0.118881,0.133696],[-0.305484,0.084061,0.14489])),
                    #(true,true,#([-0.315623,0.040915,0.46375],[-0.282033,-0.044195,0.4558],[-0.199217,-0.079986,0.438595],[-0.115689,-0.04549,0.422213],[-0.080377,0.039085,0.41625],[-0.113967,0.124195,0.4242],[-0.196783,0.159986,0.441405],[-0.280311,0.12549,0.457787])),
                    #(true,true,#([-0.263266,-0.000498,0.717542],[-0.226738,-0.105004,0.687138],[-0.12827,-0.148,0.646695],[-0.025544,-0.1043,0.619904],[0.021266,0.000498,0.622458],[-0.015262,0.105004,0.652862],[-0.11373,0.148,0.693305],[-0.216456,0.1043,0.720096])),
                    #(false,true,#([-0.22,0.0,0.15],[-0.339656,0.0,0.159077],[-0.315623,0.040915,0.46375],[-0.263266,-0.000498,0.717542],[-0.121,0.0,0.67])),
                    #(false,true,#([-0.22,0.0,0.15],[-0.303735,-0.084061,0.167947],[-0.282033,-0.044195,0.4558],[-0.226738,-0.105004,0.687138],[-0.121,0.0,0.67])),
                    #(false,true,#([-0.22,0.0,0.15],[-0.218763,-0.118881,0.166304],[-0.199217,-0.079986,0.438595],[-0.12827,-0.148,0.646695],[-0.121,0.0,0.67])),
                    #(false,true,#([-0.22,0.0,0.15],[-0.134516,-0.084061,0.15511],[-0.115689,-0.04549,0.422213],[-0.025544,-0.1043,0.619904],[-0.121,0.0,0.67])),
                    #(false,true,#([-0.22,0.0,0.15],[-0.100344,0.0,0.140923],[-0.080377,0.039085,0.41625],[0.021266,0.000498,0.622458],[-0.121,0.0,0.67])),
                    #(false,true,#([-0.22,0.0,0.15],[-0.136265,0.084061,0.132053],[-0.113967,0.124195,0.4242],[-0.015262,0.105004,0.652862],[-0.121,0.0,0.67])),
                    #(false,true,#([-0.22,0.0,0.15],[-0.221237,0.118881,0.133696],[-0.196783,0.159986,0.441405],[-0.11373,0.148,0.693305],[-0.121,0.0,0.67])),
                    #(false,true,#([-0.22,0.0,0.15],[-0.305484,0.084061,0.14489],[-0.280311,0.12549,0.457787],[-0.216456,0.1043,0.720096],[-0.121,0.0,0.67]))
                ) "ivory_glow" "body" true 0.0
                f.cage "RightLeg" #(
                    #(true,true,#([0.110376,0.0,0.140513],[0.144499,-0.084062,0.154814],[0.228708,-0.118881,0.166295],[0.313673,-0.084062,0.168231],[0.349624,0.0,0.159487],[0.315501,0.084062,0.145186],[0.231292,0.118881,0.133705],[0.146327,0.084062,0.131769])),
                    #(true,true,#([0.089584,0.039044,0.415249],[0.124866,-0.045519,0.421547],[0.20826,-0.079986,0.438655],[0.290917,-0.044167,0.456551],[0.324416,0.040956,0.464751],[0.289134,0.125519,0.458453],[0.20574,0.159986,0.441345],[0.123083,0.124167,0.423449])),
                    #(true,true,#([-0.015105,0.000505,0.620526],[0.031704,-0.104308,0.618681],[0.134044,-0.148018,0.646898],[0.231964,-0.105022,0.688648],[0.268105,-0.000505,0.719474],[0.221296,0.104308,0.721319],[0.118956,0.148018,0.693102],[0.021036,0.105022,0.651352])),
                    #(false,true,#([0.23,0.0,0.15],[0.110376,0.0,0.140513],[0.089584,0.039044,0.415249],[-0.015105,0.000505,0.620526],[0.1265,0.0,0.67])),
                    #(false,true,#([0.23,0.0,0.15],[0.144499,-0.084062,0.154814],[0.124866,-0.045519,0.421547],[0.031704,-0.104308,0.618681],[0.1265,0.0,0.67])),
                    #(false,true,#([0.23,0.0,0.15],[0.228708,-0.118881,0.166295],[0.20826,-0.079986,0.438655],[0.134044,-0.148018,0.646898],[0.1265,0.0,0.67])),
                    #(false,true,#([0.23,0.0,0.15],[0.313673,-0.084062,0.168231],[0.290917,-0.044167,0.456551],[0.231964,-0.105022,0.688648],[0.1265,0.0,0.67])),
                    #(false,true,#([0.23,0.0,0.15],[0.349624,0.0,0.159487],[0.324416,0.040956,0.464751],[0.268105,-0.000505,0.719474],[0.1265,0.0,0.67])),
                    #(false,true,#([0.23,0.0,0.15],[0.315501,0.084062,0.145186],[0.289134,0.125519,0.458453],[0.221296,0.104308,0.721319],[0.1265,0.0,0.67])),
                    #(false,true,#([0.23,0.0,0.15],[0.231292,0.118881,0.133705],[0.20574,0.159986,0.441345],[0.118956,0.148018,0.693102],[0.1265,0.0,0.67])),
                    #(false,true,#([0.23,0.0,0.15],[0.146327,0.084062,0.131769],[0.123083,0.124167,0.423449],[0.021036,0.105022,0.651352],[0.1265,0.0,0.67]))
                ) "ivory_glow" "body" true 0.0
                f.cage "SmallBody" #(
                    #(true,true,#([0.26,0.0,0.48],[0.183848,0.155563,0.48],[0.0,0.22,0.48],[-0.183848,0.155563,0.48],[-0.26,0.0,0.48],[-0.183848,-0.155563,0.48],[0.0,-0.22,0.48],[0.183848,-0.155563,0.48])),
                    #(true,true,#([0.31,0.0,0.79],[0.219203,0.176777,0.79],[0.0,0.25,0.79],[-0.219203,0.176777,0.79],[-0.31,0.0,0.79],[-0.219203,-0.176777,0.79],[0.0,-0.25,0.79],[0.219203,-0.176777,0.79])),
                    #(true,true,#([0.22,0.0,1.12],[0.155563,0.13435,1.12],[0.0,0.19,1.12],[-0.155563,0.13435,1.12],[-0.22,0.0,1.12],[-0.155563,-0.13435,1.12],[0.0,-0.19,1.12],[0.155563,-0.13435,1.12])),
                    #(true,true,#([0.13,0.0,1.28],[0.091924,0.091924,1.28],[0.0,0.13,1.28],[-0.091924,0.091924,1.28],[-0.13,0.0,1.28],[-0.091924,-0.091924,1.28],[0.0,-0.13,1.28],[0.091924,-0.091924,1.28])),
                    #(false,true,#([0.0,0.0,0.48],[0.26,0.0,0.48],[0.31,0.0,0.79],[0.22,0.0,1.12],[0.13,0.0,1.28],[0.0,0.0,1.28])),
                    #(false,true,#([0.0,0.0,0.48],[0.183848,0.155563,0.48],[0.219203,0.176777,0.79],[0.155563,0.13435,1.12],[0.091924,0.091924,1.28],[0.0,0.0,1.28])),
                    #(false,true,#([0.0,0.0,0.48],[0.0,0.22,0.48],[0.0,0.25,0.79],[0.0,0.19,1.12],[0.0,0.13,1.28],[0.0,0.0,1.28])),
                    #(false,true,#([0.0,0.0,0.48],[-0.183848,0.155563,0.48],[-0.219203,0.176777,0.79],[-0.155563,0.13435,1.12],[-0.091924,0.091924,1.28],[0.0,0.0,1.28])),
                    #(false,true,#([0.0,0.0,0.48],[-0.26,0.0,0.48],[-0.31,0.0,0.79],[-0.22,0.0,1.12],[-0.13,0.0,1.28],[0.0,0.0,1.28])),
                    #(false,true,#([0.0,0.0,0.48],[-0.183848,-0.155563,0.48],[-0.219203,-0.176777,0.79],[-0.155563,-0.13435,1.12],[-0.091924,-0.091924,1.28],[0.0,0.0,1.28])),
                    #(false,true,#([0.0,0.0,0.48],[0.0,-0.22,0.48],[0.0,-0.25,0.79],[0.0,-0.19,1.12],[0.0,-0.13,1.28],[0.0,0.0,1.28])),
                    #(false,true,#([0.0,0.0,0.48],[0.183848,-0.155563,0.48],[0.219203,-0.176777,0.79],[0.155563,-0.13435,1.12],[0.091924,-0.091924,1.28],[0.0,0.0,1.28]))
                ) "ivory_glow" "body" true 0.0
                f.cage "LongNeck" #(
                    #(true,true,#([-0.115,0.0,1.13],[-0.081317,-0.081317,1.13],[0.0,-0.115,1.13],[0.081317,-0.081317,1.13],[0.115,0.0,1.13],[0.081317,0.081317,1.13],[0.0,0.115,1.13],[-0.081317,0.081317,1.13])),
                    #(true,true,#([-0.11,0.0,1.48],[-0.077782,-0.077771,1.478704],[0.0,-0.109985,1.478167],[0.077782,-0.077771,1.478704],[0.11,0.0,1.48],[0.077782,0.077771,1.481296],[0.0,0.109985,1.481833],[-0.077782,0.077771,1.481296])),
                    #(true,true,#([-0.12,-0.01,1.78],[-0.084853,-0.094806,1.777173],[0.0,-0.129933,1.776002],[0.084853,-0.094806,1.777173],[0.12,-0.01,1.78],[0.084853,0.074806,1.782827],[0.0,0.109933,1.783998],[-0.084853,0.074806,1.782827])),
                    #(false,true,#([0.0,0.0,1.13],[-0.115,0.0,1.13],[-0.11,0.0,1.48],[-0.12,-0.01,1.78],[0.0,-0.01,1.78])),
                    #(false,true,#([0.0,0.0,1.13],[-0.081317,-0.081317,1.13],[-0.077782,-0.077771,1.478704],[-0.084853,-0.094806,1.777173],[0.0,-0.01,1.78])),
                    #(false,true,#([0.0,0.0,1.13],[0.0,-0.115,1.13],[0.0,-0.109985,1.478167],[0.0,-0.129933,1.776002],[0.0,-0.01,1.78])),
                    #(false,true,#([0.0,0.0,1.13],[0.081317,-0.081317,1.13],[0.077782,-0.077771,1.478704],[0.084853,-0.094806,1.777173],[0.0,-0.01,1.78])),
                    #(false,true,#([0.0,0.0,1.13],[0.115,0.0,1.13],[0.11,0.0,1.48],[0.12,-0.01,1.78],[0.0,-0.01,1.78])),
                    #(false,true,#([0.0,0.0,1.13],[0.081317,0.081317,1.13],[0.077782,0.077771,1.481296],[0.084853,0.074806,1.782827],[0.0,-0.01,1.78])),
                    #(false,true,#([0.0,0.0,1.13],[0.0,0.115,1.13],[0.0,0.109985,1.481833],[0.0,0.109933,1.783998],[0.0,-0.01,1.78])),
                    #(false,true,#([0.0,0.0,1.13],[-0.081317,0.081317,1.13],[-0.077782,0.077771,1.481296],[-0.084853,0.074806,1.782827],[0.0,-0.01,1.78]))
                ) "ivory_glow" "body" true 0.0
                f.cage "LeftBehindArm" #(
                    #(true,true,#([-0.137587,0.075063,1.11],[-0.130037,0.015867,1.056175],[-0.175185,-0.046766,1.03388],[-0.246586,-0.076146,1.056175],[-0.302413,-0.055063,1.11],[-0.309963,0.004133,1.163825],[-0.264815,0.066766,1.18612],[-0.193414,0.096146,1.163825])),
                    #(true,true,#([-0.293048,0.218372,0.922906],[-0.286418,0.166693,0.877848],[-0.328748,0.134525,0.834051],[-0.395244,0.140711,0.81717],[-0.446952,0.181628,0.837094],[-0.453582,0.233307,0.882152],[-0.411252,0.265475,0.925949],[-0.344756,0.259289,0.94283])),
                    #(true,true,#([-0.040355,0.337076,0.808274],[-0.035184,0.290404,0.76898],[-0.056265,0.278642,0.71271],[-0.09125,0.308681,0.672426],[-0.119645,0.362924,0.671726],[-0.124816,0.409596,0.71102],[-0.103735,0.421358,0.76729],[-0.06875,0.391319,0.807574])),
                    #(false,true,#([-0.22,0.01,1.11],[-0.137587,0.075063,1.11],[-0.293048,0.218372,0.922906],[-0.040355,0.337076,0.808274],[-0.08,0.35,0.74])),
                    #(false,true,#([-0.22,0.01,1.11],[-0.130037,0.015867,1.056175],[-0.286418,0.166693,0.877848],[-0.035184,0.290404,0.76898],[-0.08,0.35,0.74])),
                    #(false,true,#([-0.22,0.01,1.11],[-0.175185,-0.046766,1.03388],[-0.328748,0.134525,0.834051],[-0.056265,0.278642,0.71271],[-0.08,0.35,0.74])),
                    #(false,true,#([-0.22,0.01,1.11],[-0.246586,-0.076146,1.056175],[-0.395244,0.140711,0.81717],[-0.09125,0.308681,0.672426],[-0.08,0.35,0.74])),
                    #(false,true,#([-0.22,0.01,1.11],[-0.302413,-0.055063,1.11],[-0.446952,0.181628,0.837094],[-0.119645,0.362924,0.671726],[-0.08,0.35,0.74])),
                    #(false,true,#([-0.22,0.01,1.11],[-0.309963,0.004133,1.163825],[-0.453582,0.233307,0.882152],[-0.124816,0.409596,0.71102],[-0.08,0.35,0.74])),
                    #(false,true,#([-0.22,0.01,1.11],[-0.264815,0.066766,1.18612],[-0.411252,0.265475,0.925949],[-0.103735,0.421358,0.76729],[-0.08,0.35,0.74])),
                    #(false,true,#([-0.22,0.01,1.11],[-0.193414,0.096146,1.163825],[-0.344756,0.259289,0.94283],[-0.06875,0.391319,0.807574],[-0.08,0.35,0.74]))
                ) "ivory_glow" "body" true 0.0
                f.cage "RightBehindArm" #(
                    #(true,true,#([0.300316,-0.057634,1.11],[0.244299,-0.07641,1.055522],[0.174048,-0.044568,1.032956],[0.130715,0.019239,1.055522],[0.139684,0.077634,1.11],[0.195701,0.09641,1.164478],[0.265952,0.064568,1.187044],[0.309285,0.000761,1.164478])),
                    #(true,true,#([0.456177,0.179988,0.83645],[0.403532,0.13993,0.817247],[0.337102,0.13506,0.834804],[0.295802,0.168231,0.878836],[0.303823,0.220012,0.92355],[0.356468,0.26007,0.942753],[0.422898,0.26494,0.925196],[0.464198,0.231769,0.881164])),
                    #(true,true,#([0.118241,0.361836,0.670736],[0.090051,0.307527,0.672955],[0.055973,0.278098,0.714448],[0.03597,0.290789,0.770909],[0.041759,0.338164,0.809264],[0.069949,0.392473,0.807045],[0.104027,0.421902,0.765552],[0.12403,0.409211,0.709091])),
                    #(false,true,#([0.22,0.01,1.11],[0.300316,-0.057634,1.11],[0.456177,0.179988,0.83645],[0.118241,0.361836,0.670736],[0.08,0.35,0.74])),
                    #(false,true,#([0.22,0.01,1.11],[0.244299,-0.07641,1.055522],[0.403532,0.13993,0.817247],[0.090051,0.307527,0.672955],[0.08,0.35,0.74])),
                    #(false,true,#([0.22,0.01,1.11],[0.174048,-0.044568,1.032956],[0.337102,0.13506,0.834804],[0.055973,0.278098,0.714448],[0.08,0.35,0.74])),
                    #(false,true,#([0.22,0.01,1.11],[0.130715,0.019239,1.055522],[0.295802,0.168231,0.878836],[0.03597,0.290789,0.770909],[0.08,0.35,0.74])),
                    #(false,true,#([0.22,0.01,1.11],[0.139684,0.077634,1.11],[0.303823,0.220012,0.92355],[0.041759,0.338164,0.809264],[0.08,0.35,0.74])),
                    #(false,true,#([0.22,0.01,1.11],[0.195701,0.09641,1.164478],[0.356468,0.26007,0.942753],[0.069949,0.392473,0.807045],[0.08,0.35,0.74])),
                    #(false,true,#([0.22,0.01,1.11],[0.265952,0.064568,1.187044],[0.422898,0.26494,0.925196],[0.104027,0.421902,0.765552],[0.08,0.35,0.74])),
                    #(false,true,#([0.22,0.01,1.11],[0.309285,0.000761,1.164478],[0.464198,0.231769,0.881164],[0.12403,0.409211,0.709091],[0.08,0.35,0.74]))
                ) "ivory_glow" "body" true 0.0
                f.cage "JoinedHands" #(
                    #(true,true,#([-0.141421,0.437782,0.73],[-0.141421,0.415,0.79],[-0.141421,0.36,0.814853],[-0.141421,0.305,0.79],[-0.141421,0.282218,0.73],[-0.141421,0.305,0.67],[-0.141421,0.36,0.645147],[-0.141421,0.415,0.67])),
                    #(true,true,#([0.0,0.47,0.73],[0.0,0.437782,0.814853],[0.0,0.36,0.85],[0.0,0.282218,0.814853],[0.0,0.25,0.73],[0.0,0.282218,0.645147],[0.0,0.36,0.61],[0.0,0.437782,0.645147])),
                    #(true,true,#([0.141421,0.437782,0.73],[0.141421,0.415,0.79],[0.141421,0.36,0.814853],[0.141421,0.305,0.79],[0.141421,0.282218,0.73],[0.141421,0.305,0.67],[0.141421,0.36,0.645147],[0.141421,0.415,0.67])),
                    #(false,true,#([-0.2,0.36,0.73],[-0.141421,0.437782,0.73],[0.0,0.47,0.73],[0.141421,0.437782,0.73],[0.2,0.36,0.73])),
                    #(false,true,#([-0.2,0.36,0.73],[-0.141421,0.415,0.79],[0.0,0.437782,0.814853],[0.141421,0.415,0.79],[0.2,0.36,0.73])),
                    #(false,true,#([-0.2,0.36,0.73],[-0.141421,0.36,0.814853],[0.0,0.36,0.85],[0.141421,0.36,0.814853],[0.2,0.36,0.73])),
                    #(false,true,#([-0.2,0.36,0.73],[-0.141421,0.305,0.79],[0.0,0.282218,0.814853],[0.141421,0.305,0.79],[0.2,0.36,0.73])),
                    #(false,true,#([-0.2,0.36,0.73],[-0.141421,0.282218,0.73],[0.0,0.25,0.73],[0.141421,0.282218,0.73],[0.2,0.36,0.73])),
                    #(false,true,#([-0.2,0.36,0.73],[-0.141421,0.305,0.67],[0.0,0.282218,0.645147],[0.141421,0.305,0.67],[0.2,0.36,0.73])),
                    #(false,true,#([-0.2,0.36,0.73],[-0.141421,0.36,0.645147],[0.0,0.36,0.61],[0.141421,0.36,0.645147],[0.2,0.36,0.73])),
                    #(false,true,#([-0.2,0.36,0.73],[-0.141421,0.415,0.67],[0.0,0.437782,0.645147],[0.141421,0.415,0.67],[0.2,0.36,0.73]))
                ) "ivory_glow" "body" true 0.0
                f.cage "Head" #(
                    #(true,true,#([-0.108553,0.282843,2.354609],[0.04872,0.2,2.650397],[0.113865,0.0,2.772916],[0.04872,-0.2,2.650397],[-0.108553,-0.282843,2.354609],[-0.265826,-0.2,2.058822],[-0.33097,0.0,1.936302],[-0.265826,0.2,2.058822])),
                    #(true,true,#([0.272294,0.4,2.15211],[0.494711,0.282843,2.570417],[0.586839,0.0,2.743684],[0.494711,-0.282843,2.570417],[0.272294,-0.4,2.15211],[0.049876,-0.282843,1.733803],[-0.042252,0.0,1.560535],[0.049876,0.282843,1.733803])),
                    #(true,true,#([0.65314,0.282843,1.94961],[0.810413,0.2,2.245398],[0.875557,0.0,2.367917],[0.810413,-0.2,2.245398],[0.65314,-0.282843,1.94961],[0.495867,-0.2,1.653823],[0.430722,0.0,1.531303],[0.495867,0.2,1.653823])),
                    #(false,true,#([-0.266305,0.0,2.438487],[-0.108553,0.282843,2.354609],[0.272294,0.4,2.15211],[0.65314,0.282843,1.94961],[0.810892,0.0,1.865732])),
                    #(false,true,#([-0.266305,0.0,2.438487],[0.04872,0.2,2.650397],[0.494711,0.282843,2.570417],[0.810413,0.2,2.245398],[0.810892,0.0,1.865732])),
                    #(false,true,#([-0.266305,0.0,2.438487],[0.113865,0.0,2.772916],[0.586839,0.0,2.743684],[0.875557,0.0,2.367917],[0.810892,0.0,1.865732])),
                    #(false,true,#([-0.266305,0.0,2.438487],[0.04872,-0.2,2.650397],[0.494711,-0.282843,2.570417],[0.810413,-0.2,2.245398],[0.810892,0.0,1.865732])),
                    #(false,true,#([-0.266305,0.0,2.438487],[-0.108553,-0.282843,2.354609],[0.272294,-0.4,2.15211],[0.65314,-0.282843,1.94961],[0.810892,0.0,1.865732])),
                    #(false,true,#([-0.266305,0.0,2.438487],[-0.265826,-0.2,2.058822],[0.049876,-0.282843,1.733803],[0.495867,-0.2,1.653823],[0.810892,0.0,1.865732])),
                    #(false,true,#([-0.266305,0.0,2.438487],[-0.33097,0.0,1.936302],[-0.042252,0.0,1.560535],[0.430722,0.0,1.531303],[0.810892,0.0,1.865732])),
                    #(false,true,#([-0.266305,0.0,2.438487],[-0.265826,0.2,2.058822],[0.049876,0.282843,1.733803],[0.495867,0.2,1.653823],[0.810892,0.0,1.865732]))
                ) "cream" "head" true 0.0
                f.cage "FacePlate" #(
                    #(true,true,#([0.002279,-0.258076,2.307004],[0.126689,-0.285,2.540985],[0.178222,-0.35,2.637904],[0.126689,-0.415,2.540985],[0.002279,-0.441924,2.307004],[-0.122131,-0.415,2.073023],[-0.173663,-0.35,1.976105],[-0.122131,-0.285,2.073023])),
                    #(true,true,#([0.276988,-0.22,2.160939],[0.452931,-0.258076,2.491839],[0.525808,-0.35,2.628901],[0.452931,-0.441924,2.491839],[0.276988,-0.48,2.160939],[0.101046,-0.441924,1.830039],[0.028168,-0.35,1.692977],[0.101046,-0.258076,1.830039])),
                    #(true,true,#([0.551697,-0.258076,2.014874],[0.676107,-0.285,2.248855],[0.72764,-0.35,2.345773],[0.676107,-0.415,2.248855],[0.551697,-0.441924,2.014874],[0.427287,-0.415,1.780893],[0.375755,-0.35,1.683974],[0.427287,-0.285,1.780893])),
                    #(false,true,#([-0.111509,-0.35,2.367507],[0.002279,-0.258076,2.307004],[0.276988,-0.22,2.160939],[0.551697,-0.258076,2.014874],[0.665485,-0.35,1.954372])),
                    #(false,true,#([-0.111509,-0.35,2.367507],[0.126689,-0.285,2.540985],[0.452931,-0.258076,2.491839],[0.676107,-0.285,2.248855],[0.665485,-0.35,1.954372])),
                    #(false,true,#([-0.111509,-0.35,2.367507],[0.178222,-0.35,2.637904],[0.525808,-0.35,2.628901],[0.72764,-0.35,2.345773],[0.665485,-0.35,1.954372])),
                    #(false,true,#([-0.111509,-0.35,2.367507],[0.126689,-0.415,2.540985],[0.452931,-0.441924,2.491839],[0.676107,-0.415,2.248855],[0.665485,-0.35,1.954372])),
                    #(false,true,#([-0.111509,-0.35,2.367507],[0.002279,-0.441924,2.307004],[0.276988,-0.48,2.160939],[0.551697,-0.441924,2.014874],[0.665485,-0.35,1.954372])),
                    #(false,true,#([-0.111509,-0.35,2.367507],[-0.122131,-0.415,2.073023],[0.101046,-0.441924,1.830039],[0.427287,-0.415,1.780893],[0.665485,-0.35,1.954372])),
                    #(false,true,#([-0.111509,-0.35,2.367507],[-0.173663,-0.35,1.976105],[0.028168,-0.35,1.692977],[0.375755,-0.35,1.683974],[0.665485,-0.35,1.954372])),
                    #(false,true,#([-0.111509,-0.35,2.367507],[-0.122131,-0.285,2.073023],[0.101046,-0.258076,1.830039],[0.427287,-0.285,1.780893],[0.665485,-0.35,1.954372]))
                ) "ivory_glow" "mask" true 0.0
                f.cage "EyeLeft" #(
                    #(true,true,#([0.084907,-0.388707,2.371117],[0.113076,-0.4124,2.424094],[0.124744,-0.4696,2.446038],[0.113076,-0.5268,2.424094],[0.084907,-0.550493,2.371117],[0.056739,-0.5268,2.318141],[0.045071,-0.4696,2.296197],[0.056739,-0.4124,2.318141])),
                    #(true,true,#([0.150837,-0.3552,2.336062],[0.190673,-0.388707,2.410983],[0.207174,-0.4696,2.442016],[0.190673,-0.550493,2.410983],[0.150837,-0.584,2.336062],[0.111001,-0.550493,2.261141],[0.094501,-0.4696,2.230108],[0.111001,-0.388707,2.261141])),
                    #(true,true,#([0.216767,-0.388707,2.301007],[0.244935,-0.4124,2.353983],[0.256603,-0.4696,2.375927],[0.244935,-0.5268,2.353983],[0.216767,-0.550493,2.301007],[0.188599,-0.5268,2.24803],[0.176931,-0.4696,2.226086],[0.188599,-0.4124,2.24803])),
                    #(false,true,#([0.057598,-0.4696,2.385638],[0.084907,-0.388707,2.371117],[0.150837,-0.3552,2.336062],[0.216767,-0.388707,2.301007],[0.244076,-0.4696,2.286486])),
                    #(false,true,#([0.057598,-0.4696,2.385638],[0.113076,-0.4124,2.424094],[0.190673,-0.388707,2.410983],[0.244935,-0.4124,2.353983],[0.244076,-0.4696,2.286486])),
                    #(false,true,#([0.057598,-0.4696,2.385638],[0.124744,-0.4696,2.446038],[0.207174,-0.4696,2.442016],[0.256603,-0.4696,2.375927],[0.244076,-0.4696,2.286486])),
                    #(false,true,#([0.057598,-0.4696,2.385638],[0.113076,-0.5268,2.424094],[0.190673,-0.550493,2.410983],[0.244935,-0.5268,2.353983],[0.244076,-0.4696,2.286486])),
                    #(false,true,#([0.057598,-0.4696,2.385638],[0.084907,-0.550493,2.371117],[0.150837,-0.584,2.336062],[0.216767,-0.550493,2.301007],[0.244076,-0.4696,2.286486])),
                    #(false,true,#([0.057598,-0.4696,2.385638],[0.056739,-0.5268,2.318141],[0.111001,-0.550493,2.261141],[0.188599,-0.5268,2.24803],[0.244076,-0.4696,2.286486])),
                    #(false,true,#([0.057598,-0.4696,2.385638],[0.045071,-0.4696,2.296197],[0.094501,-0.4696,2.230108],[0.176931,-0.4696,2.226086],[0.244076,-0.4696,2.286486])),
                    #(false,true,#([0.057598,-0.4696,2.385638],[0.056739,-0.4124,2.318141],[0.111001,-0.388707,2.261141],[0.188599,-0.4124,2.24803],[0.244076,-0.4696,2.286486]))
                ) "dark" "mask" true 0.0
                f.cage "EyeRight" #(
                    #(true,true,#([0.426785,-0.388707,2.189338],[0.454953,-0.4124,2.242315],[0.466621,-0.4696,2.264259],[0.454953,-0.5268,2.242315],[0.426785,-0.550493,2.189338],[0.398616,-0.5268,2.136361],[0.386949,-0.4696,2.114417],[0.398616,-0.4124,2.136361])),
                    #(true,true,#([0.492714,-0.3552,2.154283],[0.532551,-0.388707,2.229203],[0.549051,-0.4696,2.260236],[0.532551,-0.550493,2.229203],[0.492714,-0.584,2.154283],[0.452878,-0.550493,2.079362],[0.436378,-0.4696,2.048329],[0.452878,-0.388707,2.079362])),
                    #(true,true,#([0.558644,-0.388707,2.119227],[0.586812,-0.4124,2.172204],[0.59848,-0.4696,2.194148],[0.586812,-0.5268,2.172204],[0.558644,-0.550493,2.119227],[0.530476,-0.5268,2.06625],[0.518808,-0.4696,2.044306],[0.530476,-0.4124,2.06625])),
                    #(false,true,#([0.399475,-0.4696,2.203859],[0.426785,-0.388707,2.189338],[0.492714,-0.3552,2.154283],[0.558644,-0.388707,2.119227],[0.585954,-0.4696,2.104706])),
                    #(false,true,#([0.399475,-0.4696,2.203859],[0.454953,-0.4124,2.242315],[0.532551,-0.388707,2.229203],[0.586812,-0.4124,2.172204],[0.585954,-0.4696,2.104706])),
                    #(false,true,#([0.399475,-0.4696,2.203859],[0.466621,-0.4696,2.264259],[0.549051,-0.4696,2.260236],[0.59848,-0.4696,2.194148],[0.585954,-0.4696,2.104706])),
                    #(false,true,#([0.399475,-0.4696,2.203859],[0.454953,-0.5268,2.242315],[0.532551,-0.550493,2.229203],[0.586812,-0.5268,2.172204],[0.585954,-0.4696,2.104706])),
                    #(false,true,#([0.399475,-0.4696,2.203859],[0.426785,-0.550493,2.189338],[0.492714,-0.584,2.154283],[0.558644,-0.550493,2.119227],[0.585954,-0.4696,2.104706])),
                    #(false,true,#([0.399475,-0.4696,2.203859],[0.398616,-0.5268,2.136361],[0.452878,-0.550493,2.079362],[0.530476,-0.5268,2.06625],[0.585954,-0.4696,2.104706])),
                    #(false,true,#([0.399475,-0.4696,2.203859],[0.386949,-0.4696,2.114417],[0.436378,-0.4696,2.048329],[0.518808,-0.4696,2.044306],[0.585954,-0.4696,2.104706])),
                    #(false,true,#([0.399475,-0.4696,2.203859],[0.398616,-0.4124,2.136361],[0.452878,-0.388707,2.079362],[0.530476,-0.4124,2.06625],[0.585954,-0.4696,2.104706]))
                ) "dark" "mask" true 0.0
                f.cage "SmallMouth" #(
                    #(true,true,#([0.196244,-0.411215,1.975772],[0.212676,-0.4306,2.006675],[0.219482,-0.4774,2.019475],[0.212676,-0.5242,2.006675],[0.196244,-0.543585,1.975772],[0.179813,-0.5242,1.944869],[0.173007,-0.4774,1.932069],[0.179813,-0.4306,1.944869])),
                    #(true,true,#([0.236826,-0.3838,1.954194],[0.260064,-0.411215,1.997897],[0.269689,-0.4774,2.016],[0.260064,-0.543585,1.997897],[0.236826,-0.571,1.954194],[0.213589,-0.543585,1.910491],[0.203963,-0.4774,1.892388],[0.213589,-0.411215,1.910491])),
                    #(true,true,#([0.277408,-0.411215,1.932616],[0.29384,-0.4306,1.963519],[0.300646,-0.4774,1.976319],[0.29384,-0.5242,1.963519],[0.277408,-0.543585,1.932616],[0.260977,-0.5242,1.901713],[0.254171,-0.4774,1.888913],[0.260977,-0.4306,1.901713])),
                    #(false,true,#([0.179435,-0.4774,1.98471],[0.196244,-0.411215,1.975772],[0.236826,-0.3838,1.954194],[0.277408,-0.411215,1.932616],[0.294218,-0.4774,1.923678])),
                    #(false,true,#([0.179435,-0.4774,1.98471],[0.212676,-0.4306,2.006675],[0.260064,-0.411215,1.997897],[0.29384,-0.4306,1.963519],[0.294218,-0.4774,1.923678])),
                    #(false,true,#([0.179435,-0.4774,1.98471],[0.219482,-0.4774,2.019475],[0.269689,-0.4774,2.016],[0.300646,-0.4774,1.976319],[0.294218,-0.4774,1.923678])),
                    #(false,true,#([0.179435,-0.4774,1.98471],[0.212676,-0.5242,2.006675],[0.260064,-0.543585,1.997897],[0.29384,-0.5242,1.963519],[0.294218,-0.4774,1.923678])),
                    #(false,true,#([0.179435,-0.4774,1.98471],[0.196244,-0.543585,1.975772],[0.236826,-0.571,1.954194],[0.277408,-0.543585,1.932616],[0.294218,-0.4774,1.923678])),
                    #(false,true,#([0.179435,-0.4774,1.98471],[0.179813,-0.5242,1.944869],[0.213589,-0.543585,1.910491],[0.260977,-0.5242,1.901713],[0.294218,-0.4774,1.923678])),
                    #(false,true,#([0.179435,-0.4774,1.98471],[0.173007,-0.4774,1.932069],[0.203963,-0.4774,1.892388],[0.254171,-0.4774,1.888913],[0.294218,-0.4774,1.923678])),
                    #(false,true,#([0.179435,-0.4774,1.98471],[0.179813,-0.4306,1.944869],[0.213589,-0.411215,1.910491],[0.260977,-0.4306,1.901713],[0.294218,-0.4774,1.923678]))
                ) "dark" "mask" true 0.0
                f.finishModel()
                f.startModel "paradecandle" "Ground candle" "prop" 1 0.13 [0.0,0.0,0.0] "" false
                f.cage "Holder" #(
                    #(true,false,#([-0.53,0.0,0.05],[-0.458993,-0.265,0.05],[-0.265,-0.458993,0.05],[0.0,-0.53,0.05],[0.265,-0.458993,0.05],[0.458993,-0.265,0.05],[0.53,0.0,0.05],[0.458993,0.265,0.05],[0.265,0.458993,0.05],[0.0,0.53,0.05],[-0.265,0.458993,0.05],[-0.458993,0.265,0.05])),
                    #(true,false,#([-0.53,0.0,0.14],[-0.458993,-0.265,0.14],[-0.265,-0.458993,0.14],[0.0,-0.53,0.14],[0.265,-0.458993,0.14],[0.458993,-0.265,0.14],[0.53,0.0,0.14],[0.458993,0.265,0.14],[0.265,0.458993,0.14],[0.0,0.53,0.14],[-0.265,0.458993,0.14],[-0.458993,0.265,0.14])),
                    #(true,false,#([-0.53,0.0,0.23],[-0.458993,-0.265,0.23],[-0.265,-0.458993,0.23],[0.0,-0.53,0.23],[0.265,-0.458993,0.23],[0.458993,-0.265,0.23],[0.53,0.0,0.23],[0.458993,0.265,0.23],[0.265,0.458993,0.23],[0.0,0.53,0.23],[-0.265,0.458993,0.23],[-0.458993,0.265,0.23])),
                    #(false,false,#([0.0,0.0,0.05],[-0.53,0.0,0.05],[-0.53,0.0,0.14],[-0.53,0.0,0.23],[0.0,0.0,0.23])),
                    #(false,false,#([0.0,0.0,0.05],[-0.458993,-0.265,0.05],[-0.458993,-0.265,0.14],[-0.458993,-0.265,0.23],[0.0,0.0,0.23])),
                    #(false,false,#([0.0,0.0,0.05],[-0.265,-0.458993,0.05],[-0.265,-0.458993,0.14],[-0.265,-0.458993,0.23],[0.0,0.0,0.23])),
                    #(false,false,#([0.0,0.0,0.05],[0.0,-0.53,0.05],[0.0,-0.53,0.14],[0.0,-0.53,0.23],[0.0,0.0,0.23])),
                    #(false,false,#([0.0,0.0,0.05],[0.265,-0.458993,0.05],[0.265,-0.458993,0.14],[0.265,-0.458993,0.23],[0.0,0.0,0.23])),
                    #(false,false,#([0.0,0.0,0.05],[0.458993,-0.265,0.05],[0.458993,-0.265,0.14],[0.458993,-0.265,0.23],[0.0,0.0,0.23])),
                    #(false,false,#([0.0,0.0,0.05],[0.53,0.0,0.05],[0.53,0.0,0.14],[0.53,0.0,0.23],[0.0,0.0,0.23])),
                    #(false,false,#([0.0,0.0,0.05],[0.458993,0.265,0.05],[0.458993,0.265,0.14],[0.458993,0.265,0.23],[0.0,0.0,0.23])),
                    #(false,false,#([0.0,0.0,0.05],[0.265,0.458993,0.05],[0.265,0.458993,0.14],[0.265,0.458993,0.23],[0.0,0.0,0.23])),
                    #(false,false,#([0.0,0.0,0.05],[0.0,0.53,0.05],[0.0,0.53,0.14],[0.0,0.53,0.23],[0.0,0.0,0.23])),
                    #(false,false,#([0.0,0.0,0.05],[-0.265,0.458993,0.05],[-0.265,0.458993,0.14],[-0.265,0.458993,0.23],[0.0,0.0,0.23])),
                    #(false,false,#([0.0,0.0,0.05],[-0.458993,0.265,0.05],[-0.458993,0.265,0.14],[-0.458993,0.265,0.23],[0.0,0.0,0.23]))
                ) "gold_glow" "body" true 0.0
                f.cage "Wax" #(
                    #(true,false,#([-0.31,0.0,0.23],[-0.268468,-0.155,0.23],[-0.155,-0.268468,0.23],[0.0,-0.31,0.23],[0.155,-0.268468,0.23],[0.268468,-0.155,0.23],[0.31,0.0,0.23],[0.268468,0.155,0.23],[0.155,0.268468,0.23],[0.0,0.31,0.23],[-0.155,0.268468,0.23],[-0.268468,0.155,0.23])),
                    #(true,false,#([-0.31,0.0,0.84],[-0.268468,-0.155,0.84],[-0.155,-0.268468,0.84],[0.0,-0.31,0.84],[0.155,-0.268468,0.84],[0.268468,-0.155,0.84],[0.31,0.0,0.84],[0.268468,0.155,0.84],[0.155,0.268468,0.84],[0.0,0.31,0.84],[-0.155,0.268468,0.84],[-0.268468,0.155,0.84])),
                    #(true,false,#([-0.31,0.0,1.45],[-0.268468,-0.155,1.45],[-0.155,-0.268468,1.45],[0.0,-0.31,1.45],[0.155,-0.268468,1.45],[0.268468,-0.155,1.45],[0.31,0.0,1.45],[0.268468,0.155,1.45],[0.155,0.268468,1.45],[0.0,0.31,1.45],[-0.155,0.268468,1.45],[-0.268468,0.155,1.45])),
                    #(false,false,#([0.0,0.0,0.23],[-0.31,0.0,0.23],[-0.31,0.0,0.84],[-0.31,0.0,1.45],[0.0,0.0,1.45])),
                    #(false,false,#([0.0,0.0,0.23],[-0.268468,-0.155,0.23],[-0.268468,-0.155,0.84],[-0.268468,-0.155,1.45],[0.0,0.0,1.45])),
                    #(false,false,#([0.0,0.0,0.23],[-0.155,-0.268468,0.23],[-0.155,-0.268468,0.84],[-0.155,-0.268468,1.45],[0.0,0.0,1.45])),
                    #(false,false,#([0.0,0.0,0.23],[0.0,-0.31,0.23],[0.0,-0.31,0.84],[0.0,-0.31,1.45],[0.0,0.0,1.45])),
                    #(false,false,#([0.0,0.0,0.23],[0.155,-0.268468,0.23],[0.155,-0.268468,0.84],[0.155,-0.268468,1.45],[0.0,0.0,1.45])),
                    #(false,false,#([0.0,0.0,0.23],[0.268468,-0.155,0.23],[0.268468,-0.155,0.84],[0.268468,-0.155,1.45],[0.0,0.0,1.45])),
                    #(false,false,#([0.0,0.0,0.23],[0.31,0.0,0.23],[0.31,0.0,0.84],[0.31,0.0,1.45],[0.0,0.0,1.45])),
                    #(false,false,#([0.0,0.0,0.23],[0.268468,0.155,0.23],[0.268468,0.155,0.84],[0.268468,0.155,1.45],[0.0,0.0,1.45])),
                    #(false,false,#([0.0,0.0,0.23],[0.155,0.268468,0.23],[0.155,0.268468,0.84],[0.155,0.268468,1.45],[0.0,0.0,1.45])),
                    #(false,false,#([0.0,0.0,0.23],[0.0,0.31,0.23],[0.0,0.31,0.84],[0.0,0.31,1.45],[0.0,0.0,1.45])),
                    #(false,false,#([0.0,0.0,0.23],[-0.155,0.268468,0.23],[-0.155,0.268468,0.84],[-0.155,0.268468,1.45],[0.0,0.0,1.45])),
                    #(false,false,#([0.0,0.0,0.23],[-0.268468,0.155,0.23],[-0.268468,0.155,0.84],[-0.268468,0.155,1.45],[0.0,0.0,1.45]))
                ) "ivory_glow" "body" true 0.0
                f.cage "Wick" #(
                    #(true,false,#([-0.055,0.0,1.42],[-0.038891,-0.038891,1.42],[0.0,-0.055,1.42],[0.038891,-0.038891,1.42],[0.055,0.0,1.42],[0.038891,0.038891,1.42],[0.0,0.055,1.42],[-0.038891,0.038891,1.42])),
                    #(true,false,#([-0.055,0.0,1.52],[-0.038891,-0.038891,1.52],[0.0,-0.055,1.52],[0.038891,-0.038891,1.52],[0.055,0.0,1.52],[0.038891,0.038891,1.52],[0.0,0.055,1.52],[-0.038891,0.038891,1.52])),
                    #(true,false,#([-0.055,0.0,1.62],[-0.038891,-0.038891,1.62],[0.0,-0.055,1.62],[0.038891,-0.038891,1.62],[0.055,0.0,1.62],[0.038891,0.038891,1.62],[0.0,0.055,1.62],[-0.038891,0.038891,1.62])),
                    #(false,false,#([0.0,0.0,1.42],[-0.055,0.0,1.42],[-0.055,0.0,1.52],[-0.055,0.0,1.62],[0.0,0.0,1.62])),
                    #(false,false,#([0.0,0.0,1.42],[-0.038891,-0.038891,1.42],[-0.038891,-0.038891,1.52],[-0.038891,-0.038891,1.62],[0.0,0.0,1.62])),
                    #(false,false,#([0.0,0.0,1.42],[0.0,-0.055,1.42],[0.0,-0.055,1.52],[0.0,-0.055,1.62],[0.0,0.0,1.62])),
                    #(false,false,#([0.0,0.0,1.42],[0.038891,-0.038891,1.42],[0.038891,-0.038891,1.52],[0.038891,-0.038891,1.62],[0.0,0.0,1.62])),
                    #(false,false,#([0.0,0.0,1.42],[0.055,0.0,1.42],[0.055,0.0,1.52],[0.055,0.0,1.62],[0.0,0.0,1.62])),
                    #(false,false,#([0.0,0.0,1.42],[0.038891,0.038891,1.42],[0.038891,0.038891,1.52],[0.038891,0.038891,1.62],[0.0,0.0,1.62])),
                    #(false,false,#([0.0,0.0,1.42],[0.0,0.055,1.42],[0.0,0.055,1.52],[0.0,0.055,1.62],[0.0,0.0,1.62])),
                    #(false,false,#([0.0,0.0,1.42],[-0.038891,0.038891,1.42],[-0.038891,0.038891,1.52],[-0.038891,0.038891,1.62],[0.0,0.0,1.62]))
                ) "dark" "body" true 0.0
                f.cage "Flame" #(
                    #(true,true,#([0.22,0.0,1.64],[0.190526,0.09,1.64],[0.11,0.155885,1.64],[0.0,0.18,1.64],[-0.11,0.155885,1.64],[-0.190526,0.09,1.64],[-0.22,0.0,1.64],[-0.190526,-0.09,1.64],[-0.11,-0.155885,1.64],[0.0,-0.18,1.64],[0.11,-0.155885,1.64],[0.190526,-0.09,1.64])),
                    #(true,true,#([0.15,0.0,1.93],[0.129904,0.06,1.93],[0.075,0.103923,1.93],[0.0,0.12,1.93],[-0.075,0.103923,1.93],[-0.129904,0.06,1.93],[-0.15,0.0,1.93],[-0.129904,-0.06,1.93],[-0.075,-0.103923,1.93],[0.0,-0.12,1.93],[0.075,-0.103923,1.93],[0.129904,-0.06,1.93])),
                    #(false,true,#([0.0,0.0,1.48],[0.22,0.0,1.64],[0.15,0.0,1.93],[0.0,0.0,2.24])),
                    #(false,true,#([0.0,0.0,1.48],[0.190526,0.09,1.64],[0.129904,0.06,1.93],[0.0,0.0,2.24])),
                    #(false,true,#([0.0,0.0,1.48],[0.11,0.155885,1.64],[0.075,0.103923,1.93],[0.0,0.0,2.24])),
                    #(false,true,#([0.0,0.0,1.48],[0.0,0.18,1.64],[0.0,0.12,1.93],[0.0,0.0,2.24])),
                    #(false,true,#([0.0,0.0,1.48],[-0.11,0.155885,1.64],[-0.075,0.103923,1.93],[0.0,0.0,2.24])),
                    #(false,true,#([0.0,0.0,1.48],[-0.190526,0.09,1.64],[-0.129904,0.06,1.93],[0.0,0.0,2.24])),
                    #(false,true,#([0.0,0.0,1.48],[-0.22,0.0,1.64],[-0.15,0.0,1.93],[0.0,0.0,2.24])),
                    #(false,true,#([0.0,0.0,1.48],[-0.190526,-0.09,1.64],[-0.129904,-0.06,1.93],[0.0,0.0,2.24])),
                    #(false,true,#([0.0,0.0,1.48],[-0.11,-0.155885,1.64],[-0.075,-0.103923,1.93],[0.0,0.0,2.24])),
                    #(false,true,#([0.0,0.0,1.48],[0.0,-0.18,1.64],[0.0,-0.12,1.93],[0.0,0.0,2.24])),
                    #(false,true,#([0.0,0.0,1.48],[0.11,-0.155885,1.64],[0.075,-0.103923,1.93],[0.0,0.0,2.24])),
                    #(false,true,#([0.0,0.0,1.48],[0.190526,-0.09,1.64],[0.129904,-0.06,1.93],[0.0,0.0,2.24]))
                ) "gold_glow" "body" true 0.0
                f.cage "FlameHeart" #(
                    #(true,true,#([-0.086603,-0.095,1.7],[-0.086603,-0.101029,1.745],[-0.086603,-0.1175,1.777942],[-0.086603,-0.14,1.79],[-0.086603,-0.1625,1.777942],[-0.086603,-0.178971,1.745],[-0.086603,-0.185,1.7],[-0.086603,-0.178971,1.655],[-0.086603,-0.1625,1.622058],[-0.086603,-0.14,1.61],[-0.086603,-0.1175,1.622058],[-0.086603,-0.101029,1.655])),
                    #(true,true,#([-0.05,-0.062058,1.7],[-0.05,-0.0725,1.777942],[-0.05,-0.101029,1.835],[-0.05,-0.14,1.855885],[-0.05,-0.178971,1.835],[-0.05,-0.2075,1.777942],[-0.05,-0.217942,1.7],[-0.05,-0.2075,1.622058],[-0.05,-0.178971,1.565],[-0.05,-0.14,1.544115],[-0.05,-0.101029,1.565],[-0.05,-0.0725,1.622058])),
                    #(true,true,#([0.0,-0.05,1.7],[0.0,-0.062058,1.79],[0.0,-0.095,1.855885],[0.0,-0.14,1.88],[0.0,-0.185,1.855885],[0.0,-0.217942,1.79],[0.0,-0.23,1.7],[0.0,-0.217942,1.61],[0.0,-0.185,1.544115],[0.0,-0.14,1.52],[0.0,-0.095,1.544115],[0.0,-0.062058,1.61])),
                    #(true,true,#([0.05,-0.062058,1.7],[0.05,-0.0725,1.777942],[0.05,-0.101029,1.835],[0.05,-0.14,1.855885],[0.05,-0.178971,1.835],[0.05,-0.2075,1.777942],[0.05,-0.217942,1.7],[0.05,-0.2075,1.622058],[0.05,-0.178971,1.565],[0.05,-0.14,1.544115],[0.05,-0.101029,1.565],[0.05,-0.0725,1.622058])),
                    #(true,true,#([0.086603,-0.095,1.7],[0.086603,-0.101029,1.745],[0.086603,-0.1175,1.777942],[0.086603,-0.14,1.79],[0.086603,-0.1625,1.777942],[0.086603,-0.178971,1.745],[0.086603,-0.185,1.7],[0.086603,-0.178971,1.655],[0.086603,-0.1625,1.622058],[0.086603,-0.14,1.61],[0.086603,-0.1175,1.622058],[0.086603,-0.101029,1.655])),
                    #(false,true,#([-0.1,-0.14,1.7],[-0.086603,-0.095,1.7],[-0.05,-0.062058,1.7],[0.0,-0.05,1.7],[0.05,-0.062058,1.7],[0.086603,-0.095,1.7],[0.1,-0.14,1.7])),
                    #(false,true,#([-0.1,-0.14,1.7],[-0.086603,-0.101029,1.745],[-0.05,-0.0725,1.777942],[0.0,-0.062058,1.79],[0.05,-0.0725,1.777942],[0.086603,-0.101029,1.745],[0.1,-0.14,1.7])),
                    #(false,true,#([-0.1,-0.14,1.7],[-0.086603,-0.1175,1.777942],[-0.05,-0.101029,1.835],[0.0,-0.095,1.855885],[0.05,-0.101029,1.835],[0.086603,-0.1175,1.777942],[0.1,-0.14,1.7])),
                    #(false,true,#([-0.1,-0.14,1.7],[-0.086603,-0.14,1.79],[-0.05,-0.14,1.855885],[0.0,-0.14,1.88],[0.05,-0.14,1.855885],[0.086603,-0.14,1.79],[0.1,-0.14,1.7])),
                    #(false,true,#([-0.1,-0.14,1.7],[-0.086603,-0.1625,1.777942],[-0.05,-0.178971,1.835],[0.0,-0.185,1.855885],[0.05,-0.178971,1.835],[0.086603,-0.1625,1.777942],[0.1,-0.14,1.7])),
                    #(false,true,#([-0.1,-0.14,1.7],[-0.086603,-0.178971,1.745],[-0.05,-0.2075,1.777942],[0.0,-0.217942,1.79],[0.05,-0.2075,1.777942],[0.086603,-0.178971,1.745],[0.1,-0.14,1.7])),
                    #(false,true,#([-0.1,-0.14,1.7],[-0.086603,-0.185,1.7],[-0.05,-0.217942,1.7],[0.0,-0.23,1.7],[0.05,-0.217942,1.7],[0.086603,-0.185,1.7],[0.1,-0.14,1.7])),
                    #(false,true,#([-0.1,-0.14,1.7],[-0.086603,-0.178971,1.655],[-0.05,-0.2075,1.622058],[0.0,-0.217942,1.61],[0.05,-0.2075,1.622058],[0.086603,-0.178971,1.655],[0.1,-0.14,1.7])),
                    #(false,true,#([-0.1,-0.14,1.7],[-0.086603,-0.1625,1.622058],[-0.05,-0.178971,1.565],[0.0,-0.185,1.544115],[0.05,-0.178971,1.565],[0.086603,-0.1625,1.622058],[0.1,-0.14,1.7])),
                    #(false,true,#([-0.1,-0.14,1.7],[-0.086603,-0.14,1.61],[-0.05,-0.14,1.544115],[0.0,-0.14,1.52],[0.05,-0.14,1.544115],[0.086603,-0.14,1.61],[0.1,-0.14,1.7])),
                    #(false,true,#([-0.1,-0.14,1.7],[-0.086603,-0.1175,1.622058],[-0.05,-0.101029,1.565],[0.0,-0.095,1.544115],[0.05,-0.101029,1.565],[0.086603,-0.1175,1.622058],[0.1,-0.14,1.7])),
                    #(false,true,#([-0.1,-0.14,1.7],[-0.086603,-0.101029,1.655],[-0.05,-0.0725,1.622058],[0.0,-0.062058,1.61],[0.05,-0.0725,1.622058],[0.086603,-0.101029,1.655],[0.1,-0.14,1.7]))
                ) "ivory_glow" "body" true 0.0
                f.finishModel()
                f.startModel "paradelantern" "Floating paper lantern" "prop" 1 0.17 [0.0,0.0,0.0] "" false
                f.cage "PaperShell" #(
                    #(true,true,#([-0.883346,0.385,2.0],[-0.883346,0.33342,2.2625],[-0.883346,0.1925,2.454663],[-0.883346,0.0,2.525],[-0.883346,-0.1925,2.454663],[-0.883346,-0.33342,2.2625],[-0.883346,-0.385,2.0],[-0.883346,-0.33342,1.7375],[-0.883346,-0.1925,1.545337],[-0.883346,0.0,1.475],[-0.883346,0.1925,1.545337],[-0.883346,0.33342,1.7375])),
                    #(true,true,#([-0.51,0.66684,2.0],[-0.51,0.5775,2.454663],[-0.51,0.33342,2.7875],[-0.51,0.0,2.909327],[-0.51,-0.33342,2.7875],[-0.51,-0.5775,2.454663],[-0.51,-0.66684,2.0],[-0.51,-0.5775,1.545337],[-0.51,-0.33342,1.2125],[-0.51,0.0,1.090673],[-0.51,0.33342,1.2125],[-0.51,0.5775,1.545337])),
                    #(true,true,#([0.0,0.77,2.0],[0.0,0.66684,2.525],[0.0,0.385,2.909327],[0.0,0.0,3.05],[0.0,-0.385,2.909327],[0.0,-0.66684,2.525],[0.0,-0.77,2.0],[0.0,-0.66684,1.475],[0.0,-0.385,1.090673],[0.0,0.0,0.95],[0.0,0.385,1.090673],[0.0,0.66684,1.475])),
                    #(true,true,#([0.51,0.66684,2.0],[0.51,0.5775,2.454663],[0.51,0.33342,2.7875],[0.51,0.0,2.909327],[0.51,-0.33342,2.7875],[0.51,-0.5775,2.454663],[0.51,-0.66684,2.0],[0.51,-0.5775,1.545337],[0.51,-0.33342,1.2125],[0.51,0.0,1.090673],[0.51,0.33342,1.2125],[0.51,0.5775,1.545337])),
                    #(true,true,#([0.883346,0.385,2.0],[0.883346,0.33342,2.2625],[0.883346,0.1925,2.454663],[0.883346,0.0,2.525],[0.883346,-0.1925,2.454663],[0.883346,-0.33342,2.2625],[0.883346,-0.385,2.0],[0.883346,-0.33342,1.7375],[0.883346,-0.1925,1.545337],[0.883346,0.0,1.475],[0.883346,0.1925,1.545337],[0.883346,0.33342,1.7375])),
                    #(false,true,#([-1.02,0.0,2.0],[-0.883346,0.385,2.0],[-0.51,0.66684,2.0],[0.0,0.77,2.0],[0.51,0.66684,2.0],[0.883346,0.385,2.0],[1.02,0.0,2.0])),
                    #(false,true,#([-1.02,0.0,2.0],[-0.883346,0.33342,2.2625],[-0.51,0.5775,2.454663],[0.0,0.66684,2.525],[0.51,0.5775,2.454663],[0.883346,0.33342,2.2625],[1.02,0.0,2.0])),
                    #(false,true,#([-1.02,0.0,2.0],[-0.883346,0.1925,2.454663],[-0.51,0.33342,2.7875],[0.0,0.385,2.909327],[0.51,0.33342,2.7875],[0.883346,0.1925,2.454663],[1.02,0.0,2.0])),
                    #(false,true,#([-1.02,0.0,2.0],[-0.883346,0.0,2.525],[-0.51,0.0,2.909327],[0.0,0.0,3.05],[0.51,0.0,2.909327],[0.883346,0.0,2.525],[1.02,0.0,2.0])),
                    #(false,true,#([-1.02,0.0,2.0],[-0.883346,-0.1925,2.454663],[-0.51,-0.33342,2.7875],[0.0,-0.385,2.909327],[0.51,-0.33342,2.7875],[0.883346,-0.1925,2.454663],[1.02,0.0,2.0])),
                    #(false,true,#([-1.02,0.0,2.0],[-0.883346,-0.33342,2.2625],[-0.51,-0.5775,2.454663],[0.0,-0.66684,2.525],[0.51,-0.5775,2.454663],[0.883346,-0.33342,2.2625],[1.02,0.0,2.0])),
                    #(false,true,#([-1.02,0.0,2.0],[-0.883346,-0.385,2.0],[-0.51,-0.66684,2.0],[0.0,-0.77,2.0],[0.51,-0.66684,2.0],[0.883346,-0.385,2.0],[1.02,0.0,2.0])),
                    #(false,true,#([-1.02,0.0,2.0],[-0.883346,-0.33342,1.7375],[-0.51,-0.5775,1.545337],[0.0,-0.66684,1.475],[0.51,-0.5775,1.545337],[0.883346,-0.33342,1.7375],[1.02,0.0,2.0])),
                    #(false,true,#([-1.02,0.0,2.0],[-0.883346,-0.1925,1.545337],[-0.51,-0.33342,1.2125],[0.0,-0.385,1.090673],[0.51,-0.33342,1.2125],[0.883346,-0.1925,1.545337],[1.02,0.0,2.0])),
                    #(false,true,#([-1.02,0.0,2.0],[-0.883346,0.0,1.475],[-0.51,0.0,1.090673],[0.0,0.0,0.95],[0.51,0.0,1.090673],[0.883346,0.0,1.475],[1.02,0.0,2.0])),
                    #(false,true,#([-1.02,0.0,2.0],[-0.883346,0.1925,1.545337],[-0.51,0.33342,1.2125],[0.0,0.385,1.090673],[0.51,0.33342,1.2125],[0.883346,0.1925,1.545337],[1.02,0.0,2.0])),
                    #(false,true,#([-1.02,0.0,2.0],[-0.883346,0.33342,1.7375],[-0.51,0.5775,1.545337],[0.0,0.66684,1.475],[0.51,0.5775,1.545337],[0.883346,0.33342,1.7375],[1.02,0.0,2.0]))
                ) "gold_glow" "body" true 0.0
                f.cage "BottomRim" #(
                    #(true,false,#([-0.62,0.0,0.9],[-0.536936,-0.31,0.9],[-0.31,-0.536936,0.9],[0.0,-0.62,0.9],[0.31,-0.536936,0.9],[0.536936,-0.31,0.9],[0.62,0.0,0.9],[0.536936,0.31,0.9],[0.31,0.536936,0.9],[0.0,0.62,0.9],[-0.31,0.536936,0.9],[-0.536936,0.31,0.9])),
                    #(true,false,#([-0.62,0.0,0.985],[-0.536936,-0.31,0.985],[-0.31,-0.536936,0.985],[0.0,-0.62,0.985],[0.31,-0.536936,0.985],[0.536936,-0.31,0.985],[0.62,0.0,0.985],[0.536936,0.31,0.985],[0.31,0.536936,0.985],[0.0,0.62,0.985],[-0.31,0.536936,0.985],[-0.536936,0.31,0.985])),
                    #(true,false,#([-0.62,0.0,1.07],[-0.536936,-0.31,1.07],[-0.31,-0.536936,1.07],[0.0,-0.62,1.07],[0.31,-0.536936,1.07],[0.536936,-0.31,1.07],[0.62,0.0,1.07],[0.536936,0.31,1.07],[0.31,0.536936,1.07],[0.0,0.62,1.07],[-0.31,0.536936,1.07],[-0.536936,0.31,1.07])),
                    #(false,false,#([0.0,0.0,0.9],[-0.62,0.0,0.9],[-0.62,0.0,0.985],[-0.62,0.0,1.07],[0.0,0.0,1.07])),
                    #(false,false,#([0.0,0.0,0.9],[-0.536936,-0.31,0.9],[-0.536936,-0.31,0.985],[-0.536936,-0.31,1.07],[0.0,0.0,1.07])),
                    #(false,false,#([0.0,0.0,0.9],[-0.31,-0.536936,0.9],[-0.31,-0.536936,0.985],[-0.31,-0.536936,1.07],[0.0,0.0,1.07])),
                    #(false,false,#([0.0,0.0,0.9],[0.0,-0.62,0.9],[0.0,-0.62,0.985],[0.0,-0.62,1.07],[0.0,0.0,1.07])),
                    #(false,false,#([0.0,0.0,0.9],[0.31,-0.536936,0.9],[0.31,-0.536936,0.985],[0.31,-0.536936,1.07],[0.0,0.0,1.07])),
                    #(false,false,#([0.0,0.0,0.9],[0.536936,-0.31,0.9],[0.536936,-0.31,0.985],[0.536936,-0.31,1.07],[0.0,0.0,1.07])),
                    #(false,false,#([0.0,0.0,0.9],[0.62,0.0,0.9],[0.62,0.0,0.985],[0.62,0.0,1.07],[0.0,0.0,1.07])),
                    #(false,false,#([0.0,0.0,0.9],[0.536936,0.31,0.9],[0.536936,0.31,0.985],[0.536936,0.31,1.07],[0.0,0.0,1.07])),
                    #(false,false,#([0.0,0.0,0.9],[0.31,0.536936,0.9],[0.31,0.536936,0.985],[0.31,0.536936,1.07],[0.0,0.0,1.07])),
                    #(false,false,#([0.0,0.0,0.9],[0.0,0.62,0.9],[0.0,0.62,0.985],[0.0,0.62,1.07],[0.0,0.0,1.07])),
                    #(false,false,#([0.0,0.0,0.9],[-0.31,0.536936,0.9],[-0.31,0.536936,0.985],[-0.31,0.536936,1.07],[0.0,0.0,1.07])),
                    #(false,false,#([0.0,0.0,0.9],[-0.536936,0.31,0.9],[-0.536936,0.31,0.985],[-0.536936,0.31,1.07],[0.0,0.0,1.07]))
                ) "dark" "body" true 0.0
                f.cage "TopRim" #(
                    #(true,false,#([-0.64,0.0,2.92],[-0.554256,-0.32,2.92],[-0.32,-0.554256,2.92],[0.0,-0.64,2.92],[0.32,-0.554256,2.92],[0.554256,-0.32,2.92],[0.64,0.0,2.92],[0.554256,0.32,2.92],[0.32,0.554256,2.92],[0.0,0.64,2.92],[-0.32,0.554256,2.92],[-0.554256,0.32,2.92])),
                    #(true,false,#([-0.64,0.0,3.0],[-0.554256,-0.32,3.0],[-0.32,-0.554256,3.0],[0.0,-0.64,3.0],[0.32,-0.554256,3.0],[0.554256,-0.32,3.0],[0.64,0.0,3.0],[0.554256,0.32,3.0],[0.32,0.554256,3.0],[0.0,0.64,3.0],[-0.32,0.554256,3.0],[-0.554256,0.32,3.0])),
                    #(true,false,#([-0.64,0.0,3.08],[-0.554256,-0.32,3.08],[-0.32,-0.554256,3.08],[0.0,-0.64,3.08],[0.32,-0.554256,3.08],[0.554256,-0.32,3.08],[0.64,0.0,3.08],[0.554256,0.32,3.08],[0.32,0.554256,3.08],[0.0,0.64,3.08],[-0.32,0.554256,3.08],[-0.554256,0.32,3.08])),
                    #(false,false,#([0.0,0.0,2.92],[-0.64,0.0,2.92],[-0.64,0.0,3.0],[-0.64,0.0,3.08],[0.0,0.0,3.08])),
                    #(false,false,#([0.0,0.0,2.92],[-0.554256,-0.32,2.92],[-0.554256,-0.32,3.0],[-0.554256,-0.32,3.08],[0.0,0.0,3.08])),
                    #(false,false,#([0.0,0.0,2.92],[-0.32,-0.554256,2.92],[-0.32,-0.554256,3.0],[-0.32,-0.554256,3.08],[0.0,0.0,3.08])),
                    #(false,false,#([0.0,0.0,2.92],[0.0,-0.64,2.92],[0.0,-0.64,3.0],[0.0,-0.64,3.08],[0.0,0.0,3.08])),
                    #(false,false,#([0.0,0.0,2.92],[0.32,-0.554256,2.92],[0.32,-0.554256,3.0],[0.32,-0.554256,3.08],[0.0,0.0,3.08])),
                    #(false,false,#([0.0,0.0,2.92],[0.554256,-0.32,2.92],[0.554256,-0.32,3.0],[0.554256,-0.32,3.08],[0.0,0.0,3.08])),
                    #(false,false,#([0.0,0.0,2.92],[0.64,0.0,2.92],[0.64,0.0,3.0],[0.64,0.0,3.08],[0.0,0.0,3.08])),
                    #(false,false,#([0.0,0.0,2.92],[0.554256,0.32,2.92],[0.554256,0.32,3.0],[0.554256,0.32,3.08],[0.0,0.0,3.08])),
                    #(false,false,#([0.0,0.0,2.92],[0.32,0.554256,2.92],[0.32,0.554256,3.0],[0.32,0.554256,3.08],[0.0,0.0,3.08])),
                    #(false,false,#([0.0,0.0,2.92],[0.0,0.64,2.92],[0.0,0.64,3.0],[0.0,0.64,3.08],[0.0,0.0,3.08])),
                    #(false,false,#([0.0,0.0,2.92],[-0.32,0.554256,2.92],[-0.32,0.554256,3.0],[-0.32,0.554256,3.08],[0.0,0.0,3.08])),
                    #(false,false,#([0.0,0.0,2.92],[-0.554256,0.32,2.92],[-0.554256,0.32,3.0],[-0.554256,0.32,3.08],[0.0,0.0,3.08]))
                ) "dark" "body" true 0.0
                f.tube "PaperRib0" #([0.401101,0.0,2.967114],[0.731856,0.0,2.73884],[0.952552,0.0,2.399456],[1.03,0.0,2.0],[0.952552,0.0,1.600544],[0.731856,0.0,1.26116],[0.401101,0.0,1.032886]) 0.045 4 false true "ivory_glow" "body"
                f.tube "PaperRib1" #([0.20055,0.263052,2.967114],[0.365928,0.47997,2.73884],[0.476276,0.624708,2.399456],[0.515,0.6755,2.0],[0.476276,0.624708,1.600544],[0.365928,0.47997,1.26116],[0.20055,0.263052,1.032886]) 0.045 4 false true "ivory_glow" "body"
                f.tube "PaperRib2" #([-0.20055,0.263052,2.967114],[-0.365928,0.47997,2.73884],[-0.476276,0.624708,2.399456],[-0.515,0.6755,2.0],[-0.476276,0.624708,1.600544],[-0.365928,0.47997,1.26116],[-0.20055,0.263052,1.032886]) 0.045 4 false true "ivory_glow" "body"
                f.tube "PaperRib3" #([-0.401101,0.0,2.967114],[-0.731856,0.0,2.73884],[-0.952552,0.0,2.399456],[-1.03,0.0,2.0],[-0.952552,0.0,1.600544],[-0.731856,0.0,1.26116],[-0.401101,0.0,1.032886]) 0.045 4 false true "ivory_glow" "body"
                f.tube "PaperRib4" #([-0.20055,-0.263052,2.967114],[-0.365928,-0.47997,2.73884],[-0.476276,-0.624708,2.399456],[-0.515,-0.6755,2.0],[-0.476276,-0.624708,1.600544],[-0.365928,-0.47997,1.26116],[-0.20055,-0.263052,1.032886]) 0.045 4 false true "ivory_glow" "body"
                f.tube "PaperRib5" #([0.20055,-0.263052,2.967114],[0.365928,-0.47997,2.73884],[0.476276,-0.624708,2.399456],[0.515,-0.6755,2.0],[0.476276,-0.624708,1.600544],[0.365928,-0.47997,1.26116],[0.20055,-0.263052,1.032886]) 0.045 4 false true "ivory_glow" "body"
                f.tube "Tassel" #([0.0,0.0,0.98],[0.07,0.0,0.65],[-0.07,0.0,0.34],[0.0,0.0,0.02]) 0.08 5 false true "gold_glow" "body"
                f.finishModel()
                f.startModel "parademoon" "Flying crescent moon" "prop" 1 0.19 [0.0,0.0,0.0] "" false
                f.cage "Crescent" #(
                    #(true,true,#([0.329932,0.246749,4.469616],[0.303547,0.199624,4.327],[0.28724,0.07625,4.238859],[0.28724,-0.07625,4.238859],[0.303547,-0.199624,4.327],[0.329932,-0.246749,4.469616],[0.356316,-0.199624,4.612231],[0.372623,-0.07625,4.700372],[0.372623,0.07625,4.700372],[0.356316,0.199624,4.612231])),
                    #(true,true,#([-0.329932,0.40433,4.469616],[-0.286697,0.32711,4.235922],[-0.259976,0.124945,4.091491],[-0.259976,-0.124945,4.091491],[-0.286697,-0.32711,4.235922],[-0.329932,-0.40433,4.469616],[-0.373166,-0.32711,4.703309],[-0.399887,-0.124945,4.84774],[-0.399887,0.124945,4.84774],[-0.373166,0.32711,4.703309])),
                    #(true,true,#([-0.95,0.524352,4.232051],[-0.790304,0.424209,3.968445],[-0.691606,0.162034,3.805527],[-0.691606,-0.162034,3.805527],[-0.790304,-0.424209,3.968445],[-0.95,-0.524352,4.232051],[-1.109696,-0.424209,4.495657],[-1.208394,-0.162034,4.658574],[-1.208394,0.162034,4.658574],[-1.109696,0.424209,4.495657])),
                    #(true,true,#([-1.455484,0.61046,3.785575],[-1.175238,0.493872,3.561493],[-1.002036,0.188642,3.423002],[-1.002036,-0.188642,3.423002],[-1.175238,-0.493872,3.561493],[-1.455484,-0.61046,3.785575],[-1.735731,-0.493872,4.009658],[-1.908933,-0.188642,4.148149],[-1.908933,0.188642,4.148149],[-1.735731,0.493872,4.009658])),
                    #(true,true,#([-1.785416,0.662547,3.18404],[-1.417479,0.536012,3.056439],[-1.190081,0.204738,2.977577],[-1.190081,-0.204738,2.977577],[-1.417479,-0.536012,3.056439],[-1.785416,-0.662547,3.18404],[-2.153353,-0.536012,3.311642],[-2.380751,-0.204738,3.390504],[-2.380751,0.204738,3.390504],[-2.153353,0.536012,3.311642])),
                    #(true,true,#([-1.9,0.68,2.5],[-1.500306,0.550132,2.5],[-1.253282,0.210132,2.5],[-1.253282,-0.210132,2.5],[-1.500306,-0.550132,2.5],[-1.9,-0.68,2.5],[-2.299694,-0.550132,2.5],[-2.546718,-0.210132,2.5],[-2.546718,0.210132,2.5],[-2.299694,0.550132,2.5])),
                    #(true,true,#([-1.785416,0.662547,1.81596],[-1.417479,0.536012,1.943561],[-1.190081,0.204738,2.022423],[-1.190081,-0.204738,2.022423],[-1.417479,-0.536012,1.943561],[-1.785416,-0.662547,1.81596],[-2.153353,-0.536012,1.688358],[-2.380751,-0.204738,1.609496],[-2.380751,0.204738,1.609496],[-2.153353,0.536012,1.688358])),
                    #(true,true,#([-1.455484,0.61046,1.214425],[-1.175238,0.493872,1.438507],[-1.002036,0.188642,1.576998],[-1.002036,-0.188642,1.576998],[-1.175238,-0.493872,1.438507],[-1.455484,-0.61046,1.214425],[-1.735731,-0.493872,0.990342],[-1.908933,-0.188642,0.851851],[-1.908933,0.188642,0.851851],[-1.735731,0.493872,0.990342])),
                    #(true,true,#([-0.95,0.524352,0.767949],[-0.790304,0.424209,1.031555],[-0.691606,0.162034,1.194473],[-0.691606,-0.162034,1.194473],[-0.790304,-0.424209,1.031555],[-0.95,-0.524352,0.767949],[-1.109696,-0.424209,0.504343],[-1.208394,-0.162034,0.341426],[-1.208394,0.162034,0.341426],[-1.109696,0.424209,0.504343])),
                    #(true,true,#([-0.329932,0.40433,0.530384],[-0.286697,0.32711,0.764078],[-0.259976,0.124945,0.908509],[-0.259976,-0.124945,0.908509],[-0.286697,-0.32711,0.764078],[-0.329932,-0.40433,0.530384],[-0.373166,-0.32711,0.296691],[-0.399887,-0.124945,0.15226],[-0.399887,0.124945,0.15226],[-0.373166,0.32711,0.296691])),
                    #(true,true,#([0.329932,0.246749,0.530384],[0.303547,0.199624,0.673],[0.28724,0.07625,0.761141],[0.28724,-0.07625,0.761141],[0.303547,-0.199624,0.673],[0.329932,-0.246749,0.530384],[0.356316,-0.199624,0.387769],[0.372623,-0.07625,0.299628],[0.372623,0.07625,0.299628],[0.356316,0.199624,0.387769])),
                    #(false,true,#([0.95,0.0,4.232051],[0.329932,0.246749,4.469616],[-0.329932,0.40433,4.469616],[-0.95,0.524352,4.232051],[-1.455484,0.61046,3.785575],[-1.785416,0.662547,3.18404],[-1.9,0.68,2.5],[-1.785416,0.662547,1.81596],[-1.455484,0.61046,1.214425],[-0.95,0.524352,0.767949],[-0.329932,0.40433,0.530384],[0.329932,0.246749,0.530384],[0.95,0.0,0.767949])),
                    #(false,true,#([0.95,0.0,4.232051],[0.303547,0.199624,4.327],[-0.286697,0.32711,4.235922],[-0.790304,0.424209,3.968445],[-1.175238,0.493872,3.561493],[-1.417479,0.536012,3.056439],[-1.500306,0.550132,2.5],[-1.417479,0.536012,1.943561],[-1.175238,0.493872,1.438507],[-0.790304,0.424209,1.031555],[-0.286697,0.32711,0.764078],[0.303547,0.199624,0.673],[0.95,0.0,0.767949])),
                    #(false,true,#([0.95,0.0,4.232051],[0.28724,0.07625,4.238859],[-0.259976,0.124945,4.091491],[-0.691606,0.162034,3.805527],[-1.002036,0.188642,3.423002],[-1.190081,0.204738,2.977577],[-1.253282,0.210132,2.5],[-1.190081,0.204738,2.022423],[-1.002036,0.188642,1.576998],[-0.691606,0.162034,1.194473],[-0.259976,0.124945,0.908509],[0.28724,0.07625,0.761141],[0.95,0.0,0.767949])),
                    #(false,true,#([0.95,0.0,4.232051],[0.28724,-0.07625,4.238859],[-0.259976,-0.124945,4.091491],[-0.691606,-0.162034,3.805527],[-1.002036,-0.188642,3.423002],[-1.190081,-0.204738,2.977577],[-1.253282,-0.210132,2.5],[-1.190081,-0.204738,2.022423],[-1.002036,-0.188642,1.576998],[-0.691606,-0.162034,1.194473],[-0.259976,-0.124945,0.908509],[0.28724,-0.07625,0.761141],[0.95,0.0,0.767949])),
                    #(false,true,#([0.95,0.0,4.232051],[0.303547,-0.199624,4.327],[-0.286697,-0.32711,4.235922],[-0.790304,-0.424209,3.968445],[-1.175238,-0.493872,3.561493],[-1.417479,-0.536012,3.056439],[-1.500306,-0.550132,2.5],[-1.417479,-0.536012,1.943561],[-1.175238,-0.493872,1.438507],[-0.790304,-0.424209,1.031555],[-0.286697,-0.32711,0.764078],[0.303547,-0.199624,0.673],[0.95,0.0,0.767949])),
                    #(false,true,#([0.95,0.0,4.232051],[0.329932,-0.246749,4.469616],[-0.329932,-0.40433,4.469616],[-0.95,-0.524352,4.232051],[-1.455484,-0.61046,3.785575],[-1.785416,-0.662547,3.18404],[-1.9,-0.68,2.5],[-1.785416,-0.662547,1.81596],[-1.455484,-0.61046,1.214425],[-0.95,-0.524352,0.767949],[-0.329932,-0.40433,0.530384],[0.329932,-0.246749,0.530384],[0.95,0.0,0.767949])),
                    #(false,true,#([0.95,0.0,4.232051],[0.356316,-0.199624,4.612231],[-0.373166,-0.32711,4.703309],[-1.109696,-0.424209,4.495657],[-1.735731,-0.493872,4.009658],[-2.153353,-0.536012,3.311642],[-2.299694,-0.550132,2.5],[-2.153353,-0.536012,1.688358],[-1.735731,-0.493872,0.990342],[-1.109696,-0.424209,0.504343],[-0.373166,-0.32711,0.296691],[0.356316,-0.199624,0.387769],[0.95,0.0,0.767949])),
                    #(false,true,#([0.95,0.0,4.232051],[0.372623,-0.07625,4.700372],[-0.399887,-0.124945,4.84774],[-1.208394,-0.162034,4.658574],[-1.908933,-0.188642,4.148149],[-2.380751,-0.204738,3.390504],[-2.546718,-0.210132,2.5],[-2.380751,-0.204738,1.609496],[-1.908933,-0.188642,0.851851],[-1.208394,-0.162034,0.341426],[-0.399887,-0.124945,0.15226],[0.372623,-0.07625,0.299628],[0.95,0.0,0.767949])),
                    #(false,true,#([0.95,0.0,4.232051],[0.372623,0.07625,4.700372],[-0.399887,0.124945,4.84774],[-1.208394,0.162034,4.658574],[-1.908933,0.188642,4.148149],[-2.380751,0.204738,3.390504],[-2.546718,0.210132,2.5],[-2.380751,0.204738,1.609496],[-1.908933,0.188642,0.851851],[-1.208394,0.162034,0.341426],[-0.399887,0.124945,0.15226],[0.372623,0.07625,0.299628],[0.95,0.0,0.767949])),
                    #(false,true,#([0.95,0.0,4.232051],[0.356316,0.199624,4.612231],[-0.373166,0.32711,4.703309],[-1.109696,0.424209,4.495657],[-1.735731,0.493872,4.009658],[-2.153353,0.536012,3.311642],[-2.299694,0.550132,2.5],[-2.153353,0.536012,1.688358],[-1.735731,0.493872,0.990342],[-1.109696,0.424209,0.504343],[-0.373166,0.32711,0.296691],[0.356316,0.199624,0.387769],[0.95,0.0,0.767949]))
                ) "ivory_glow" "body" true 0.0
                f.finishModel()
                f.startModel "paradeenvelope" "Flying folded envelope" "prop" 1 0.15 [0.0,0.0,0.0] "" false
                f.cage "Paper" #(
                    #(true,false,#([-1.8,-0.12,0.025],[1.8,-0.12,0.025],[1.8,0.12,0.025],[-1.8,0.12,0.025])),
                    #(true,false,#([-1.8,-0.12,2.275],[1.8,-0.12,2.275],[1.8,0.12,2.275],[-1.8,0.12,2.275])),
                    #(false,false,#([-1.8,-0.12,0.025],[-1.8,-0.12,2.275])),
                    #(false,false,#([1.8,-0.12,0.025],[1.8,-0.12,2.275])),
                    #(false,false,#([1.8,0.12,0.025],[1.8,0.12,2.275])),
                    #(false,false,#([-1.8,0.12,0.025],[-1.8,0.12,2.275]))
                ) "ivory_glow" "body" true 0.0
                f.tube "Fold" #([-1.72,-0.19,2.2],[0.0,-0.21,1.12],[1.72,-0.19,2.2]) 0.075 4 false false "dark" "body"
                f.tube "LowerFold" #([-1.72,-0.19,0.1],[0.0,-0.21,1.12],[1.72,-0.19,0.1]) 0.06 4 false false "gold_glow" "body"
                f.cage "Seal" #(
                    #(true,true,#([-0.207846,-0.185,1.12],[-0.207846,-0.192369,1.18],[-0.207846,-0.2125,1.223923],[-0.207846,-0.24,1.24],[-0.207846,-0.2675,1.223923],[-0.207846,-0.287631,1.18],[-0.207846,-0.295,1.12],[-0.207846,-0.287631,1.06],[-0.207846,-0.2675,1.016077],[-0.207846,-0.24,1.0],[-0.207846,-0.2125,1.016077],[-0.207846,-0.192369,1.06])),
                    #(true,true,#([-0.12,-0.144737,1.12],[-0.12,-0.1575,1.223923],[-0.12,-0.192369,1.3],[-0.12,-0.24,1.327846],[-0.12,-0.287631,1.3],[-0.12,-0.3225,1.223923],[-0.12,-0.335263,1.12],[-0.12,-0.3225,1.016077],[-0.12,-0.287631,0.94],[-0.12,-0.24,0.912154],[-0.12,-0.192369,0.94],[-0.12,-0.1575,1.016077])),
                    #(true,true,#([0.0,-0.13,1.12],[0.0,-0.144737,1.24],[0.0,-0.185,1.327846],[0.0,-0.24,1.36],[0.0,-0.295,1.327846],[0.0,-0.335263,1.24],[0.0,-0.35,1.12],[0.0,-0.335263,1.0],[0.0,-0.295,0.912154],[0.0,-0.24,0.88],[0.0,-0.185,0.912154],[0.0,-0.144737,1.0])),
                    #(true,true,#([0.12,-0.144737,1.12],[0.12,-0.1575,1.223923],[0.12,-0.192369,1.3],[0.12,-0.24,1.327846],[0.12,-0.287631,1.3],[0.12,-0.3225,1.223923],[0.12,-0.335263,1.12],[0.12,-0.3225,1.016077],[0.12,-0.287631,0.94],[0.12,-0.24,0.912154],[0.12,-0.192369,0.94],[0.12,-0.1575,1.016077])),
                    #(true,true,#([0.207846,-0.185,1.12],[0.207846,-0.192369,1.18],[0.207846,-0.2125,1.223923],[0.207846,-0.24,1.24],[0.207846,-0.2675,1.223923],[0.207846,-0.287631,1.18],[0.207846,-0.295,1.12],[0.207846,-0.287631,1.06],[0.207846,-0.2675,1.016077],[0.207846,-0.24,1.0],[0.207846,-0.2125,1.016077],[0.207846,-0.192369,1.06])),
                    #(false,true,#([-0.24,-0.24,1.12],[-0.207846,-0.185,1.12],[-0.12,-0.144737,1.12],[0.0,-0.13,1.12],[0.12,-0.144737,1.12],[0.207846,-0.185,1.12],[0.24,-0.24,1.12])),
                    #(false,true,#([-0.24,-0.24,1.12],[-0.207846,-0.192369,1.18],[-0.12,-0.1575,1.223923],[0.0,-0.144737,1.24],[0.12,-0.1575,1.223923],[0.207846,-0.192369,1.18],[0.24,-0.24,1.12])),
                    #(false,true,#([-0.24,-0.24,1.12],[-0.207846,-0.2125,1.223923],[-0.12,-0.192369,1.3],[0.0,-0.185,1.327846],[0.12,-0.192369,1.3],[0.207846,-0.2125,1.223923],[0.24,-0.24,1.12])),
                    #(false,true,#([-0.24,-0.24,1.12],[-0.207846,-0.24,1.24],[-0.12,-0.24,1.327846],[0.0,-0.24,1.36],[0.12,-0.24,1.327846],[0.207846,-0.24,1.24],[0.24,-0.24,1.12])),
                    #(false,true,#([-0.24,-0.24,1.12],[-0.207846,-0.2675,1.223923],[-0.12,-0.287631,1.3],[0.0,-0.295,1.327846],[0.12,-0.287631,1.3],[0.207846,-0.2675,1.223923],[0.24,-0.24,1.12])),
                    #(false,true,#([-0.24,-0.24,1.12],[-0.207846,-0.287631,1.18],[-0.12,-0.3225,1.223923],[0.0,-0.335263,1.24],[0.12,-0.3225,1.223923],[0.207846,-0.287631,1.18],[0.24,-0.24,1.12])),
                    #(false,true,#([-0.24,-0.24,1.12],[-0.207846,-0.295,1.12],[-0.12,-0.335263,1.12],[0.0,-0.35,1.12],[0.12,-0.335263,1.12],[0.207846,-0.295,1.12],[0.24,-0.24,1.12])),
                    #(false,true,#([-0.24,-0.24,1.12],[-0.207846,-0.287631,1.06],[-0.12,-0.3225,1.016077],[0.0,-0.335263,1.0],[0.12,-0.3225,1.016077],[0.207846,-0.287631,1.06],[0.24,-0.24,1.12])),
                    #(false,true,#([-0.24,-0.24,1.12],[-0.207846,-0.2675,1.016077],[-0.12,-0.287631,0.94],[0.0,-0.295,0.912154],[0.12,-0.287631,0.94],[0.207846,-0.2675,1.016077],[0.24,-0.24,1.12])),
                    #(false,true,#([-0.24,-0.24,1.12],[-0.207846,-0.24,1.0],[-0.12,-0.24,0.912154],[0.0,-0.24,0.88],[0.12,-0.24,0.912154],[0.207846,-0.24,1.0],[0.24,-0.24,1.12])),
                    #(false,true,#([-0.24,-0.24,1.12],[-0.207846,-0.2125,1.016077],[-0.12,-0.192369,0.94],[0.0,-0.185,0.912154],[0.12,-0.192369,0.94],[0.207846,-0.2125,1.016077],[0.24,-0.24,1.12])),
                    #(false,true,#([-0.24,-0.24,1.12],[-0.207846,-0.192369,1.06],[-0.12,-0.1575,1.016077],[0.0,-0.144737,1.0],[0.12,-0.1575,1.016077],[0.207846,-0.192369,1.06],[0.24,-0.24,1.12]))
                ) "red_glow" "body" true 0.0
                f.finishModel()
                f.startModel "parademoney" "Flying hyperinflation banknote" "prop" 1 0.13 [0.0,0.0,0.0] "" false
                f.cage "Banknote" #(
                    #(false,true,#([-2.2,0.0,0.05],[-1.65,-0.084853,0.05],[-1.1,-0.12,0.05],[-0.55,-0.084853,0.05],[0.0,0.0,0.05],[0.55,0.084853,0.05],[1.1,0.12,0.05],[1.65,0.084853,0.05],[2.2,0.0,0.05])),
                    #(false,true,#([-2.2,0.0,0.6],[-1.65,-0.084853,0.6],[-1.1,-0.12,0.6],[-0.55,-0.084853,0.6],[0.0,0.0,0.6],[0.55,0.084853,0.6],[1.1,0.12,0.6],[1.65,0.084853,0.6],[2.2,0.0,0.6])),
                    #(false,true,#([-2.2,0.0,1.15],[-1.65,-0.084853,1.15],[-1.1,-0.12,1.15],[-0.55,-0.084853,1.15],[0.0,0.0,1.15],[0.55,0.084853,1.15],[1.1,0.12,1.15],[1.65,0.084853,1.15],[2.2,0.0,1.15])),
                    #(false,true,#([-2.2,0.0,1.7],[-1.65,-0.084853,1.7],[-1.1,-0.12,1.7],[-0.55,-0.084853,1.7],[0.0,0.0,1.7],[0.55,0.084853,1.7],[1.1,0.12,1.7],[1.65,0.084853,1.7],[2.2,0.0,1.7])),
                    #(false,true,#([-2.2,0.0,2.25],[-1.65,-0.084853,2.25],[-1.1,-0.12,2.25],[-0.55,-0.084853,2.25],[0.0,0.0,2.25],[0.55,0.084853,2.25],[1.1,0.12,2.25],[1.65,0.084853,2.25],[2.2,0.0,2.25])),
                    #(false,true,#([-2.2,0.0,0.05],[-2.2,0.0,0.6],[-2.2,0.0,1.15],[-2.2,0.0,1.7],[-2.2,0.0,2.25])),
                    #(false,true,#([-1.65,-0.084853,0.05],[-1.65,-0.084853,0.6],[-1.65,-0.084853,1.15],[-1.65,-0.084853,1.7],[-1.65,-0.084853,2.25])),
                    #(false,true,#([-1.1,-0.12,0.05],[-1.1,-0.12,0.6],[-1.1,-0.12,1.15],[-1.1,-0.12,1.7],[-1.1,-0.12,2.25])),
                    #(false,true,#([-0.55,-0.084853,0.05],[-0.55,-0.084853,0.6],[-0.55,-0.084853,1.15],[-0.55,-0.084853,1.7],[-0.55,-0.084853,2.25])),
                    #(false,true,#([0.0,0.0,0.05],[0.0,0.0,0.6],[0.0,0.0,1.15],[0.0,0.0,1.7],[0.0,0.0,2.25])),
                    #(false,true,#([0.55,0.084853,0.05],[0.55,0.084853,0.6],[0.55,0.084853,1.15],[0.55,0.084853,1.7],[0.55,0.084853,2.25])),
                    #(false,true,#([1.1,0.12,0.05],[1.1,0.12,0.6],[1.1,0.12,1.15],[1.1,0.12,1.7],[1.1,0.12,2.25])),
                    #(false,true,#([1.65,0.084853,0.05],[1.65,0.084853,0.6],[1.65,0.084853,1.15],[1.65,0.084853,1.7],[1.65,0.084853,2.25])),
                    #(false,true,#([2.2,0.0,0.05],[2.2,0.0,0.6],[2.2,0.0,1.15],[2.2,0.0,1.7],[2.2,0.0,2.25]))
                ) "green_glow" "body" false 0.18
                f.tube "Border" #([-2.03,-0.21,0.23],[2.03,-0.21,0.23],[2.03,-0.21,2.06],[-2.03,-0.21,2.06]) 0.065 4 true false "gold_glow" "body"
                f.cage "LeadingOne" #(
                    #(true,false,#([-1.68,-0.34,0.795],[-1.56,-0.34,0.795],[-1.56,-0.2,0.795],[-1.68,-0.2,0.795])),
                    #(true,false,#([-1.68,-0.34,1.545],[-1.56,-0.34,1.545],[-1.56,-0.2,1.545],[-1.68,-0.2,1.545])),
                    #(false,false,#([-1.68,-0.34,0.795],[-1.68,-0.34,1.545])),
                    #(false,false,#([-1.56,-0.34,0.795],[-1.56,-0.34,1.545])),
                    #(false,false,#([-1.56,-0.2,0.795],[-1.56,-0.2,1.545])),
                    #(false,false,#([-1.68,-0.2,0.795],[-1.68,-0.2,1.545]))
                ) "dark" "body" true 0.0
                f.tube "Zero0" #([-1.01,-0.28,1.17],[-1.059792,-0.28,1.410416],[-1.18,-0.28,1.51],[-1.300208,-0.28,1.410416],[-1.35,-0.28,1.17],[-1.300208,-0.28,0.929584],[-1.18,-0.28,0.83],[-1.059792,-0.28,0.929584]) 0.065 4 true false "dark" "body"
                f.tube "Zero1" #([-0.5,-0.28,1.17],[-0.549792,-0.28,1.410416],[-0.67,-0.28,1.51],[-0.790208,-0.28,1.410416],[-0.84,-0.28,1.17],[-0.790208,-0.28,0.929584],[-0.67,-0.28,0.83],[-0.549792,-0.28,0.929584]) 0.065 4 true false "dark" "body"
                f.tube "Zero2" #([0.01,-0.28,1.17],[-0.039792,-0.28,1.410416],[-0.16,-0.28,1.51],[-0.280208,-0.28,1.410416],[-0.33,-0.28,1.17],[-0.280208,-0.28,0.929584],[-0.16,-0.28,0.83],[-0.039792,-0.28,0.929584]) 0.065 4 true false "dark" "body"
                f.tube "Zero3" #([0.52,-0.28,1.17],[0.470208,-0.28,1.410416],[0.35,-0.28,1.51],[0.229792,-0.28,1.410416],[0.18,-0.28,1.17],[0.229792,-0.28,0.929584],[0.35,-0.28,0.83],[0.470208,-0.28,0.929584]) 0.065 4 true false "dark" "body"
                f.tube "Zero4" #([1.03,-0.28,1.17],[0.980208,-0.28,1.410416],[0.86,-0.28,1.51],[0.739792,-0.28,1.410416],[0.69,-0.28,1.17],[0.739792,-0.28,0.929584],[0.86,-0.28,0.83],[0.980208,-0.28,0.929584]) 0.065 4 true false "dark" "body"
                f.tube "Zero5" #([1.54,-0.28,1.17],[1.490208,-0.28,1.410416],[1.37,-0.28,1.51],[1.249792,-0.28,1.410416],[1.2,-0.28,1.17],[1.249792,-0.28,0.929584],[1.37,-0.28,0.83],[1.490208,-0.28,0.929584]) 0.065 4 true false "dark" "body"
                f.finishModel()
                f.startModel "paradekoi" "Flying lantern koi" "prop" 1 0.15 [0.0,0.0,0.0] "" false
                f.cage "Body" #(
                    #(true,true,#([-1.402961,0.24,1.1],[-1.402961,0.207846,1.2525],[-1.402961,0.12,1.364138],[-1.402961,0.0,1.405],[-1.402961,-0.12,1.364138],[-1.402961,-0.207846,1.2525],[-1.402961,-0.24,1.1],[-1.402961,-0.207846,0.9475],[-1.402961,-0.12,0.835862],[-1.402961,0.0,0.795],[-1.402961,0.12,0.835862],[-1.402961,0.207846,0.9475])),
                    #(true,true,#([-0.81,0.415692,1.1],[-0.81,0.36,1.364138],[-0.81,0.207846,1.5575],[-0.81,0.0,1.628275],[-0.81,-0.207846,1.5575],[-0.81,-0.36,1.364138],[-0.81,-0.415692,1.1],[-0.81,-0.36,0.835862],[-0.81,-0.207846,0.6425],[-0.81,0.0,0.571725],[-0.81,0.207846,0.6425],[-0.81,0.36,0.835862])),
                    #(true,true,#([0.0,0.48,1.1],[0.0,0.415692,1.405],[0.0,0.24,1.628275],[0.0,0.0,1.71],[0.0,-0.24,1.628275],[0.0,-0.415692,1.405],[0.0,-0.48,1.1],[0.0,-0.415692,0.795],[0.0,-0.24,0.571725],[0.0,0.0,0.49],[0.0,0.24,0.571725],[0.0,0.415692,0.795])),
                    #(true,true,#([0.81,0.415692,1.1],[0.81,0.36,1.364138],[0.81,0.207846,1.5575],[0.81,0.0,1.628275],[0.81,-0.207846,1.5575],[0.81,-0.36,1.364138],[0.81,-0.415692,1.1],[0.81,-0.36,0.835862],[0.81,-0.207846,0.6425],[0.81,0.0,0.571725],[0.81,0.207846,0.6425],[0.81,0.36,0.835862])),
                    #(true,true,#([1.402961,0.24,1.1],[1.402961,0.207846,1.2525],[1.402961,0.12,1.364138],[1.402961,0.0,1.405],[1.402961,-0.12,1.364138],[1.402961,-0.207846,1.2525],[1.402961,-0.24,1.1],[1.402961,-0.207846,0.9475],[1.402961,-0.12,0.835862],[1.402961,0.0,0.795],[1.402961,0.12,0.835862],[1.402961,0.207846,0.9475])),
                    #(false,true,#([-1.62,0.0,1.1],[-1.402961,0.24,1.1],[-0.81,0.415692,1.1],[0.0,0.48,1.1],[0.81,0.415692,1.1],[1.402961,0.24,1.1],[1.62,0.0,1.1])),
                    #(false,true,#([-1.62,0.0,1.1],[-1.402961,0.207846,1.2525],[-0.81,0.36,1.364138],[0.0,0.415692,1.405],[0.81,0.36,1.364138],[1.402961,0.207846,1.2525],[1.62,0.0,1.1])),
                    #(false,true,#([-1.62,0.0,1.1],[-1.402961,0.12,1.364138],[-0.81,0.207846,1.5575],[0.0,0.24,1.628275],[0.81,0.207846,1.5575],[1.402961,0.12,1.364138],[1.62,0.0,1.1])),
                    #(false,true,#([-1.62,0.0,1.1],[-1.402961,0.0,1.405],[-0.81,0.0,1.628275],[0.0,0.0,1.71],[0.81,0.0,1.628275],[1.402961,0.0,1.405],[1.62,0.0,1.1])),
                    #(false,true,#([-1.62,0.0,1.1],[-1.402961,-0.12,1.364138],[-0.81,-0.207846,1.5575],[0.0,-0.24,1.628275],[0.81,-0.207846,1.5575],[1.402961,-0.12,1.364138],[1.62,0.0,1.1])),
                    #(false,true,#([-1.62,0.0,1.1],[-1.402961,-0.207846,1.2525],[-0.81,-0.36,1.364138],[0.0,-0.415692,1.405],[0.81,-0.36,1.364138],[1.402961,-0.207846,1.2525],[1.62,0.0,1.1])),
                    #(false,true,#([-1.62,0.0,1.1],[-1.402961,-0.24,1.1],[-0.81,-0.415692,1.1],[0.0,-0.48,1.1],[0.81,-0.415692,1.1],[1.402961,-0.24,1.1],[1.62,0.0,1.1])),
                    #(false,true,#([-1.62,0.0,1.1],[-1.402961,-0.207846,0.9475],[-0.81,-0.36,0.835862],[0.0,-0.415692,0.795],[0.81,-0.36,0.835862],[1.402961,-0.207846,0.9475],[1.62,0.0,1.1])),
                    #(false,true,#([-1.62,0.0,1.1],[-1.402961,-0.12,0.835862],[-0.81,-0.207846,0.6425],[0.0,-0.24,0.571725],[0.81,-0.207846,0.6425],[1.402961,-0.12,0.835862],[1.62,0.0,1.1])),
                    #(false,true,#([-1.62,0.0,1.1],[-1.402961,0.0,0.795],[-0.81,0.0,0.571725],[0.0,0.0,0.49],[0.81,0.0,0.571725],[1.402961,0.0,0.795],[1.62,0.0,1.1])),
                    #(false,true,#([-1.62,0.0,1.1],[-1.402961,0.12,0.835862],[-0.81,0.207846,0.6425],[0.0,0.24,0.571725],[0.81,0.207846,0.6425],[1.402961,0.12,0.835862],[1.62,0.0,1.1])),
                    #(false,true,#([-1.62,0.0,1.1],[-1.402961,0.207846,0.9475],[-0.81,0.36,0.835862],[0.0,0.415692,0.795],[0.81,0.36,0.835862],[1.402961,0.207846,0.9475],[1.62,0.0,1.1]))
                ) "ivory_glow" "body" true 0.0
                f.cage "HeadPatch" #(
                    #(true,true,#([0.571628,0.255,1.27],[0.571628,0.220836,1.385],[0.571628,0.1275,1.469186],[0.571628,0.0,1.5],[0.571628,-0.1275,1.469186],[0.571628,-0.220836,1.385],[0.571628,-0.255,1.27],[0.571628,-0.220836,1.155],[0.571628,-0.1275,1.070814],[0.571628,0.0,1.04],[0.571628,0.1275,1.070814],[0.571628,0.220836,1.155])),
                    #(true,true,#([0.74,0.441673,1.27],[0.74,0.3825,1.469186],[0.74,0.220836,1.615],[0.74,0.0,1.668372],[0.74,-0.220836,1.615],[0.74,-0.3825,1.469186],[0.74,-0.441673,1.27],[0.74,-0.3825,1.070814],[0.74,-0.220836,0.925],[0.74,0.0,0.871628],[0.74,0.220836,0.925],[0.74,0.3825,1.070814])),
                    #(true,true,#([0.97,0.51,1.27],[0.97,0.441673,1.5],[0.97,0.255,1.668372],[0.97,0.0,1.73],[0.97,-0.255,1.668372],[0.97,-0.441673,1.5],[0.97,-0.51,1.27],[0.97,-0.441673,1.04],[0.97,-0.255,0.871628],[0.97,0.0,0.81],[0.97,0.255,0.871628],[0.97,0.441673,1.04])),
                    #(true,true,#([1.2,0.441673,1.27],[1.2,0.3825,1.469186],[1.2,0.220836,1.615],[1.2,0.0,1.668372],[1.2,-0.220836,1.615],[1.2,-0.3825,1.469186],[1.2,-0.441673,1.27],[1.2,-0.3825,1.070814],[1.2,-0.220836,0.925],[1.2,0.0,0.871628],[1.2,0.220836,0.925],[1.2,0.3825,1.070814])),
                    #(true,true,#([1.368372,0.255,1.27],[1.368372,0.220836,1.385],[1.368372,0.1275,1.469186],[1.368372,0.0,1.5],[1.368372,-0.1275,1.469186],[1.368372,-0.220836,1.385],[1.368372,-0.255,1.27],[1.368372,-0.220836,1.155],[1.368372,-0.1275,1.070814],[1.368372,0.0,1.04],[1.368372,0.1275,1.070814],[1.368372,0.220836,1.155])),
                    #(false,true,#([0.51,0.0,1.27],[0.571628,0.255,1.27],[0.74,0.441673,1.27],[0.97,0.51,1.27],[1.2,0.441673,1.27],[1.368372,0.255,1.27],[1.43,0.0,1.27])),
                    #(false,true,#([0.51,0.0,1.27],[0.571628,0.220836,1.385],[0.74,0.3825,1.469186],[0.97,0.441673,1.5],[1.2,0.3825,1.469186],[1.368372,0.220836,1.385],[1.43,0.0,1.27])),
                    #(false,true,#([0.51,0.0,1.27],[0.571628,0.1275,1.469186],[0.74,0.220836,1.615],[0.97,0.255,1.668372],[1.2,0.220836,1.615],[1.368372,0.1275,1.469186],[1.43,0.0,1.27])),
                    #(false,true,#([0.51,0.0,1.27],[0.571628,0.0,1.5],[0.74,0.0,1.668372],[0.97,0.0,1.73],[1.2,0.0,1.668372],[1.368372,0.0,1.5],[1.43,0.0,1.27])),
                    #(false,true,#([0.51,0.0,1.27],[0.571628,-0.1275,1.469186],[0.74,-0.220836,1.615],[0.97,-0.255,1.668372],[1.2,-0.220836,1.615],[1.368372,-0.1275,1.469186],[1.43,0.0,1.27])),
                    #(false,true,#([0.51,0.0,1.27],[0.571628,-0.220836,1.385],[0.74,-0.3825,1.469186],[0.97,-0.441673,1.5],[1.2,-0.3825,1.469186],[1.368372,-0.220836,1.385],[1.43,0.0,1.27])),
                    #(false,true,#([0.51,0.0,1.27],[0.571628,-0.255,1.27],[0.74,-0.441673,1.27],[0.97,-0.51,1.27],[1.2,-0.441673,1.27],[1.368372,-0.255,1.27],[1.43,0.0,1.27])),
                    #(false,true,#([0.51,0.0,1.27],[0.571628,-0.220836,1.155],[0.74,-0.3825,1.070814],[0.97,-0.441673,1.04],[1.2,-0.3825,1.070814],[1.368372,-0.220836,1.155],[1.43,0.0,1.27])),
                    #(false,true,#([0.51,0.0,1.27],[0.571628,-0.1275,1.070814],[0.74,-0.220836,0.925],[0.97,-0.255,0.871628],[1.2,-0.220836,0.925],[1.368372,-0.1275,1.070814],[1.43,0.0,1.27])),
                    #(false,true,#([0.51,0.0,1.27],[0.571628,0.0,1.04],[0.74,0.0,0.871628],[0.97,0.0,0.81],[1.2,0.0,0.871628],[1.368372,0.0,1.04],[1.43,0.0,1.27])),
                    #(false,true,#([0.51,0.0,1.27],[0.571628,0.1275,1.070814],[0.74,0.220836,0.925],[0.97,0.255,0.871628],[1.2,0.220836,0.925],[1.368372,0.1275,1.070814],[1.43,0.0,1.27])),
                    #(false,true,#([0.51,0.0,1.27],[0.571628,0.220836,1.155],[0.74,0.3825,1.070814],[0.97,0.441673,1.04],[1.2,0.3825,1.070814],[1.368372,0.220836,1.155],[1.43,0.0,1.27]))
                ) "orange_glow" "body" true 0.0
                f.cage "BackPatch" #(
                    #(true,true,#([-0.983013,0.2,1.46],[-0.983013,0.173205,1.53],[-0.983013,0.1,1.581244],[-0.983013,0.0,1.6],[-0.983013,-0.1,1.581244],[-0.983013,-0.173205,1.53],[-0.983013,-0.2,1.46],[-0.983013,-0.173205,1.39],[-0.983013,-0.1,1.338756],[-0.983013,0.0,1.32],[-0.983013,0.1,1.338756],[-0.983013,0.173205,1.39])),
                    #(true,true,#([-0.8,0.34641,1.46],[-0.8,0.3,1.581244],[-0.8,0.173205,1.67],[-0.8,0.0,1.702487],[-0.8,-0.173205,1.67],[-0.8,-0.3,1.581244],[-0.8,-0.34641,1.46],[-0.8,-0.3,1.338756],[-0.8,-0.173205,1.25],[-0.8,0.0,1.217513],[-0.8,0.173205,1.25],[-0.8,0.3,1.338756])),
                    #(true,true,#([-0.55,0.4,1.46],[-0.55,0.34641,1.6],[-0.55,0.2,1.702487],[-0.55,0.0,1.74],[-0.55,-0.2,1.702487],[-0.55,-0.34641,1.6],[-0.55,-0.4,1.46],[-0.55,-0.34641,1.32],[-0.55,-0.2,1.217513],[-0.55,0.0,1.18],[-0.55,0.2,1.217513],[-0.55,0.34641,1.32])),
                    #(true,true,#([-0.3,0.34641,1.46],[-0.3,0.3,1.581244],[-0.3,0.173205,1.67],[-0.3,0.0,1.702487],[-0.3,-0.173205,1.67],[-0.3,-0.3,1.581244],[-0.3,-0.34641,1.46],[-0.3,-0.3,1.338756],[-0.3,-0.173205,1.25],[-0.3,0.0,1.217513],[-0.3,0.173205,1.25],[-0.3,0.3,1.338756])),
                    #(true,true,#([-0.116987,0.2,1.46],[-0.116987,0.173205,1.53],[-0.116987,0.1,1.581244],[-0.116987,0.0,1.6],[-0.116987,-0.1,1.581244],[-0.116987,-0.173205,1.53],[-0.116987,-0.2,1.46],[-0.116987,-0.173205,1.39],[-0.116987,-0.1,1.338756],[-0.116987,0.0,1.32],[-0.116987,0.1,1.338756],[-0.116987,0.173205,1.39])),
                    #(false,true,#([-1.05,0.0,1.46],[-0.983013,0.2,1.46],[-0.8,0.34641,1.46],[-0.55,0.4,1.46],[-0.3,0.34641,1.46],[-0.116987,0.2,1.46],[-0.05,0.0,1.46])),
                    #(false,true,#([-1.05,0.0,1.46],[-0.983013,0.173205,1.53],[-0.8,0.3,1.581244],[-0.55,0.34641,1.6],[-0.3,0.3,1.581244],[-0.116987,0.173205,1.53],[-0.05,0.0,1.46])),
                    #(false,true,#([-1.05,0.0,1.46],[-0.983013,0.1,1.581244],[-0.8,0.173205,1.67],[-0.55,0.2,1.702487],[-0.3,0.173205,1.67],[-0.116987,0.1,1.581244],[-0.05,0.0,1.46])),
                    #(false,true,#([-1.05,0.0,1.46],[-0.983013,0.0,1.6],[-0.8,0.0,1.702487],[-0.55,0.0,1.74],[-0.3,0.0,1.702487],[-0.116987,0.0,1.6],[-0.05,0.0,1.46])),
                    #(false,true,#([-1.05,0.0,1.46],[-0.983013,-0.1,1.581244],[-0.8,-0.173205,1.67],[-0.55,-0.2,1.702487],[-0.3,-0.173205,1.67],[-0.116987,-0.1,1.581244],[-0.05,0.0,1.46])),
                    #(false,true,#([-1.05,0.0,1.46],[-0.983013,-0.173205,1.53],[-0.8,-0.3,1.581244],[-0.55,-0.34641,1.6],[-0.3,-0.3,1.581244],[-0.116987,-0.173205,1.53],[-0.05,0.0,1.46])),
                    #(false,true,#([-1.05,0.0,1.46],[-0.983013,-0.2,1.46],[-0.8,-0.34641,1.46],[-0.55,-0.4,1.46],[-0.3,-0.34641,1.46],[-0.116987,-0.2,1.46],[-0.05,0.0,1.46])),
                    #(false,true,#([-1.05,0.0,1.46],[-0.983013,-0.173205,1.39],[-0.8,-0.3,1.338756],[-0.55,-0.34641,1.32],[-0.3,-0.3,1.338756],[-0.116987,-0.173205,1.39],[-0.05,0.0,1.46])),
                    #(false,true,#([-1.05,0.0,1.46],[-0.983013,-0.1,1.338756],[-0.8,-0.173205,1.25],[-0.55,-0.2,1.217513],[-0.3,-0.173205,1.25],[-0.116987,-0.1,1.338756],[-0.05,0.0,1.46])),
                    #(false,true,#([-1.05,0.0,1.46],[-0.983013,0.0,1.32],[-0.8,0.0,1.217513],[-0.55,0.0,1.18],[-0.3,0.0,1.217513],[-0.116987,0.0,1.32],[-0.05,0.0,1.46])),
                    #(false,true,#([-1.05,0.0,1.46],[-0.983013,0.1,1.338756],[-0.8,0.173205,1.25],[-0.55,0.2,1.217513],[-0.3,0.173205,1.25],[-0.116987,0.1,1.338756],[-0.05,0.0,1.46])),
                    #(false,true,#([-1.05,0.0,1.46],[-0.983013,0.173205,1.39],[-0.8,0.3,1.338756],[-0.55,0.34641,1.32],[-0.3,0.3,1.338756],[-0.116987,0.173205,1.39],[-0.05,0.0,1.46]))
                ) "orange_glow" "body" true 0.0
                f.cage "Tail0" #(
                    #(false,true,#([-1.292527,0.0,1.087545],[-1.296263,0.0,1.093772],[-1.3,0.0,1.1],[-1.303737,0.0,1.106228],[-1.307473,0.0,1.112455])),
                    #(false,true,#([-1.43619,0.04462,0.703651],[-1.505595,0.04462,0.819325],[-1.575,0.04462,0.935],[-1.644405,0.04462,1.050675],[-1.71381,0.04462,1.166349])),
                    #(false,true,#([-1.711484,0.07,0.36914],[-1.818242,0.07,0.54707],[-1.925,0.07,0.725],[-2.031758,0.07,0.90293],[-2.138516,0.07,1.08086])),
                    #(false,true,#([-2.13619,0.04462,0.283651],[-2.205595,0.04462,0.399325],[-2.275,0.04462,0.515],[-2.344405,0.04462,0.630675],[-2.41381,0.04462,0.746349])),
                    #(false,true,#([-2.542527,0.0,0.337545],[-2.546263,0.0,0.343772],[-2.55,0.0,0.35],[-2.553737,0.0,0.356228],[-2.557473,0.0,0.362455])),
                    #(false,true,#([-1.292527,0.0,1.087545],[-1.43619,0.04462,0.703651],[-1.711484,0.07,0.36914],[-2.13619,0.04462,0.283651],[-2.542527,0.0,0.337545])),
                    #(false,true,#([-1.296263,0.0,1.093772],[-1.505595,0.04462,0.819325],[-1.818242,0.07,0.54707],[-2.205595,0.04462,0.399325],[-2.546263,0.0,0.343772])),
                    #(false,true,#([-1.3,0.0,1.1],[-1.575,0.04462,0.935],[-1.925,0.07,0.725],[-2.275,0.04462,0.515],[-2.55,0.0,0.35])),
                    #(false,true,#([-1.303737,0.0,1.106228],[-1.644405,0.04462,1.050675],[-2.031758,0.07,0.90293],[-2.344405,0.04462,0.630675],[-2.553737,0.0,0.356228])),
                    #(false,true,#([-1.307473,0.0,1.112455],[-1.71381,0.04462,1.166349],[-2.138516,0.07,1.08086],[-2.41381,0.04462,0.746349],[-2.557473,0.0,0.362455]))
                ) "orange_glow" "body" false 0.18
                f.cage "Tail1" #(
                    #(false,true,#([-1.307473,0.0,1.087545],[-1.303737,0.0,1.093772],[-1.3,0.0,1.1],[-1.296263,0.0,1.106228],[-1.292527,0.0,1.112455])),
                    #(false,true,#([-1.71381,0.04462,1.033651],[-1.644405,0.04462,1.149325],[-1.575,0.04462,1.265],[-1.505595,0.04462,1.380675],[-1.43619,0.04462,1.496349])),
                    #(false,true,#([-2.138516,0.07,1.11914],[-2.031758,0.07,1.29707],[-1.925,0.07,1.475],[-1.818242,0.07,1.65293],[-1.711484,0.07,1.83086])),
                    #(false,true,#([-2.41381,0.04462,1.453651],[-2.344405,0.04462,1.569325],[-2.275,0.04462,1.685],[-2.205595,0.04462,1.800675],[-2.13619,0.04462,1.916349])),
                    #(false,true,#([-2.557473,0.0,1.837545],[-2.553737,0.0,1.843772],[-2.55,0.0,1.85],[-2.546263,0.0,1.856228],[-2.542527,0.0,1.862455])),
                    #(false,true,#([-1.307473,0.0,1.087545],[-1.71381,0.04462,1.033651],[-2.138516,0.07,1.11914],[-2.41381,0.04462,1.453651],[-2.557473,0.0,1.837545])),
                    #(false,true,#([-1.303737,0.0,1.093772],[-1.644405,0.04462,1.149325],[-2.031758,0.07,1.29707],[-2.344405,0.04462,1.569325],[-2.553737,0.0,1.843772])),
                    #(false,true,#([-1.3,0.0,1.1],[-1.575,0.04462,1.265],[-1.925,0.07,1.475],[-2.275,0.04462,1.685],[-2.55,0.0,1.85])),
                    #(false,true,#([-1.296263,0.0,1.106228],[-1.505595,0.04462,1.380675],[-1.818242,0.07,1.65293],[-2.205595,0.04462,1.800675],[-2.546263,0.0,1.856228])),
                    #(false,true,#([-1.292527,0.0,1.112455],[-1.43619,0.04462,1.496349],[-1.711484,0.07,1.83086],[-2.13619,0.04462,1.916349],[-2.542527,0.0,1.862455]))
                ) "orange_glow" "body" false 0.18
                f.cage "Fin0" #(
                    #(false,true,#([0.292369,-0.30254,1.003937],[0.296185,-0.30627,1.001969],[0.3,-0.31,1.0],[0.303815,-0.31373,0.998031],[0.307631,-0.31746,0.996063])),
                    #(false,true,#([-0.03974,-0.329825,0.989537],[0.03113,-0.399113,0.952968],[0.102,-0.4684,0.9164],[0.17287,-0.537687,0.879832],[0.24374,-0.606975,0.843263])),
                    #(false,true,#([-0.368023,-0.456845,0.922498],[-0.259012,-0.563423,0.866249],[-0.15,-0.67,0.81],[-0.040988,-0.776577,0.753751],[0.068023,-0.883155,0.697502])),
                    #(false,true,#([-0.54374,-0.733025,0.776737],[-0.47287,-0.802313,0.740168],[-0.402,-0.8716,0.7036],[-0.33113,-0.940887,0.667032],[-0.26026,-1.010175,0.630463])),
                    #(false,true,#([-0.607631,-1.02254,0.623937],[-0.603815,-1.02627,0.621969],[-0.6,-1.03,0.62],[-0.596185,-1.03373,0.618031],[-0.592369,-1.03746,0.616063])),
                    #(false,true,#([0.292369,-0.30254,1.003937],[-0.03974,-0.329825,0.989537],[-0.368023,-0.456845,0.922498],[-0.54374,-0.733025,0.776737],[-0.607631,-1.02254,0.623937])),
                    #(false,true,#([0.296185,-0.30627,1.001969],[0.03113,-0.399113,0.952968],[-0.259012,-0.563423,0.866249],[-0.47287,-0.802313,0.740168],[-0.603815,-1.02627,0.621969])),
                    #(false,true,#([0.3,-0.31,1.0],[0.102,-0.4684,0.9164],[-0.15,-0.67,0.81],[-0.402,-0.8716,0.7036],[-0.6,-1.03,0.62])),
                    #(false,true,#([0.303815,-0.31373,0.998031],[0.17287,-0.537687,0.879832],[-0.040988,-0.776577,0.753751],[-0.33113,-0.940887,0.667032],[-0.596185,-1.03373,0.618031])),
                    #(false,true,#([0.307631,-0.31746,0.996063],[0.24374,-0.606975,0.843263],[0.068023,-0.883155,0.697502],[-0.26026,-1.010175,0.630463],[-0.592369,-1.03746,0.616063]))
                ) "ivory_glow" "body" false 0.18
                f.cage "Eye0" #(
                    #(true,true,#([1.209067,-0.345,1.23],[1.209067,-0.351029,1.25625],[1.209067,-0.3675,1.275466],[1.209067,-0.39,1.2825],[1.209067,-0.4125,1.275466],[1.209067,-0.428971,1.25625],[1.209067,-0.435,1.23],[1.209067,-0.428971,1.20375],[1.209067,-0.4125,1.184534],[1.209067,-0.39,1.1775],[1.209067,-0.3675,1.184534],[1.209067,-0.351029,1.20375])),
                    #(true,true,#([1.2475,-0.312058,1.23],[1.2475,-0.3225,1.275466],[1.2475,-0.351029,1.30875],[1.2475,-0.39,1.320933],[1.2475,-0.428971,1.30875],[1.2475,-0.4575,1.275466],[1.2475,-0.467942,1.23],[1.2475,-0.4575,1.184534],[1.2475,-0.428971,1.15125],[1.2475,-0.39,1.139067],[1.2475,-0.351029,1.15125],[1.2475,-0.3225,1.184534])),
                    #(true,true,#([1.3,-0.3,1.23],[1.3,-0.312058,1.2825],[1.3,-0.345,1.320933],[1.3,-0.39,1.335],[1.3,-0.435,1.320933],[1.3,-0.467942,1.2825],[1.3,-0.48,1.23],[1.3,-0.467942,1.1775],[1.3,-0.435,1.139067],[1.3,-0.39,1.125],[1.3,-0.345,1.139067],[1.3,-0.312058,1.1775])),
                    #(true,true,#([1.3525,-0.312058,1.23],[1.3525,-0.3225,1.275466],[1.3525,-0.351029,1.30875],[1.3525,-0.39,1.320933],[1.3525,-0.428971,1.30875],[1.3525,-0.4575,1.275466],[1.3525,-0.467942,1.23],[1.3525,-0.4575,1.184534],[1.3525,-0.428971,1.15125],[1.3525,-0.39,1.139067],[1.3525,-0.351029,1.15125],[1.3525,-0.3225,1.184534])),
                    #(true,true,#([1.390933,-0.345,1.23],[1.390933,-0.351029,1.25625],[1.390933,-0.3675,1.275466],[1.390933,-0.39,1.2825],[1.390933,-0.4125,1.275466],[1.390933,-0.428971,1.25625],[1.390933,-0.435,1.23],[1.390933,-0.428971,1.20375],[1.390933,-0.4125,1.184534],[1.390933,-0.39,1.1775],[1.390933,-0.3675,1.184534],[1.390933,-0.351029,1.20375])),
                    #(false,true,#([1.195,-0.39,1.23],[1.209067,-0.345,1.23],[1.2475,-0.312058,1.23],[1.3,-0.3,1.23],[1.3525,-0.312058,1.23],[1.390933,-0.345,1.23],[1.405,-0.39,1.23])),
                    #(false,true,#([1.195,-0.39,1.23],[1.209067,-0.351029,1.25625],[1.2475,-0.3225,1.275466],[1.3,-0.312058,1.2825],[1.3525,-0.3225,1.275466],[1.390933,-0.351029,1.25625],[1.405,-0.39,1.23])),
                    #(false,true,#([1.195,-0.39,1.23],[1.209067,-0.3675,1.275466],[1.2475,-0.351029,1.30875],[1.3,-0.345,1.320933],[1.3525,-0.351029,1.30875],[1.390933,-0.3675,1.275466],[1.405,-0.39,1.23])),
                    #(false,true,#([1.195,-0.39,1.23],[1.209067,-0.39,1.2825],[1.2475,-0.39,1.320933],[1.3,-0.39,1.335],[1.3525,-0.39,1.320933],[1.390933,-0.39,1.2825],[1.405,-0.39,1.23])),
                    #(false,true,#([1.195,-0.39,1.23],[1.209067,-0.4125,1.275466],[1.2475,-0.428971,1.30875],[1.3,-0.435,1.320933],[1.3525,-0.428971,1.30875],[1.390933,-0.4125,1.275466],[1.405,-0.39,1.23])),
                    #(false,true,#([1.195,-0.39,1.23],[1.209067,-0.428971,1.25625],[1.2475,-0.4575,1.275466],[1.3,-0.467942,1.2825],[1.3525,-0.4575,1.275466],[1.390933,-0.428971,1.25625],[1.405,-0.39,1.23])),
                    #(false,true,#([1.195,-0.39,1.23],[1.209067,-0.435,1.23],[1.2475,-0.467942,1.23],[1.3,-0.48,1.23],[1.3525,-0.467942,1.23],[1.390933,-0.435,1.23],[1.405,-0.39,1.23])),
                    #(false,true,#([1.195,-0.39,1.23],[1.209067,-0.428971,1.20375],[1.2475,-0.4575,1.184534],[1.3,-0.467942,1.1775],[1.3525,-0.4575,1.184534],[1.390933,-0.428971,1.20375],[1.405,-0.39,1.23])),
                    #(false,true,#([1.195,-0.39,1.23],[1.209067,-0.4125,1.184534],[1.2475,-0.428971,1.15125],[1.3,-0.435,1.139067],[1.3525,-0.428971,1.15125],[1.390933,-0.4125,1.184534],[1.405,-0.39,1.23])),
                    #(false,true,#([1.195,-0.39,1.23],[1.209067,-0.39,1.1775],[1.2475,-0.39,1.139067],[1.3,-0.39,1.125],[1.3525,-0.39,1.139067],[1.390933,-0.39,1.1775],[1.405,-0.39,1.23])),
                    #(false,true,#([1.195,-0.39,1.23],[1.209067,-0.3675,1.184534],[1.2475,-0.351029,1.15125],[1.3,-0.345,1.139067],[1.3525,-0.351029,1.15125],[1.390933,-0.3675,1.184534],[1.405,-0.39,1.23])),
                    #(false,true,#([1.195,-0.39,1.23],[1.209067,-0.351029,1.20375],[1.2475,-0.3225,1.184534],[1.3,-0.312058,1.1775],[1.3525,-0.3225,1.184534],[1.390933,-0.351029,1.20375],[1.405,-0.39,1.23]))
                ) "dark" "body" true 0.0
                f.cage "Fin1" #(
                    #(false,true,#([0.292369,0.30254,1.003937],[0.296185,0.30627,1.001969],[0.3,0.31,1.0],[0.303815,0.31373,0.998031],[0.307631,0.31746,0.996063])),
                    #(false,true,#([-0.03974,0.329825,0.989537],[0.03113,0.399113,0.952968],[0.102,0.4684,0.9164],[0.17287,0.537687,0.879832],[0.24374,0.606975,0.843263])),
                    #(false,true,#([-0.368023,0.456845,0.922498],[-0.259012,0.563423,0.866249],[-0.15,0.67,0.81],[-0.040988,0.776577,0.753751],[0.068023,0.883155,0.697502])),
                    #(false,true,#([-0.54374,0.733025,0.776737],[-0.47287,0.802313,0.740168],[-0.402,0.8716,0.7036],[-0.33113,0.940887,0.667032],[-0.26026,1.010175,0.630463])),
                    #(false,true,#([-0.607631,1.02254,0.623937],[-0.603815,1.02627,0.621969],[-0.6,1.03,0.62],[-0.596185,1.03373,0.618031],[-0.592369,1.03746,0.616063])),
                    #(false,true,#([0.292369,0.30254,1.003937],[-0.03974,0.329825,0.989537],[-0.368023,0.456845,0.922498],[-0.54374,0.733025,0.776737],[-0.607631,1.02254,0.623937])),
                    #(false,true,#([0.296185,0.30627,1.001969],[0.03113,0.399113,0.952968],[-0.259012,0.563423,0.866249],[-0.47287,0.802313,0.740168],[-0.603815,1.02627,0.621969])),
                    #(false,true,#([0.3,0.31,1.0],[0.102,0.4684,0.9164],[-0.15,0.67,0.81],[-0.402,0.8716,0.7036],[-0.6,1.03,0.62])),
                    #(false,true,#([0.303815,0.31373,0.998031],[0.17287,0.537687,0.879832],[-0.040988,0.776577,0.753751],[-0.33113,0.940887,0.667032],[-0.596185,1.03373,0.618031])),
                    #(false,true,#([0.307631,0.31746,0.996063],[0.24374,0.606975,0.843263],[0.068023,0.883155,0.697502],[-0.26026,1.010175,0.630463],[-0.592369,1.03746,0.616063]))
                ) "ivory_glow" "body" false 0.18
                f.cage "Eye1" #(
                    #(true,true,#([1.209067,0.435,1.23],[1.209067,0.428971,1.25625],[1.209067,0.4125,1.275466],[1.209067,0.39,1.2825],[1.209067,0.3675,1.275466],[1.209067,0.351029,1.25625],[1.209067,0.345,1.23],[1.209067,0.351029,1.20375],[1.209067,0.3675,1.184534],[1.209067,0.39,1.1775],[1.209067,0.4125,1.184534],[1.209067,0.428971,1.20375])),
                    #(true,true,#([1.2475,0.467942,1.23],[1.2475,0.4575,1.275466],[1.2475,0.428971,1.30875],[1.2475,0.39,1.320933],[1.2475,0.351029,1.30875],[1.2475,0.3225,1.275466],[1.2475,0.312058,1.23],[1.2475,0.3225,1.184534],[1.2475,0.351029,1.15125],[1.2475,0.39,1.139067],[1.2475,0.428971,1.15125],[1.2475,0.4575,1.184534])),
                    #(true,true,#([1.3,0.48,1.23],[1.3,0.467942,1.2825],[1.3,0.435,1.320933],[1.3,0.39,1.335],[1.3,0.345,1.320933],[1.3,0.312058,1.2825],[1.3,0.3,1.23],[1.3,0.312058,1.1775],[1.3,0.345,1.139067],[1.3,0.39,1.125],[1.3,0.435,1.139067],[1.3,0.467942,1.1775])),
                    #(true,true,#([1.3525,0.467942,1.23],[1.3525,0.4575,1.275466],[1.3525,0.428971,1.30875],[1.3525,0.39,1.320933],[1.3525,0.351029,1.30875],[1.3525,0.3225,1.275466],[1.3525,0.312058,1.23],[1.3525,0.3225,1.184534],[1.3525,0.351029,1.15125],[1.3525,0.39,1.139067],[1.3525,0.428971,1.15125],[1.3525,0.4575,1.184534])),
                    #(true,true,#([1.390933,0.435,1.23],[1.390933,0.428971,1.25625],[1.390933,0.4125,1.275466],[1.390933,0.39,1.2825],[1.390933,0.3675,1.275466],[1.390933,0.351029,1.25625],[1.390933,0.345,1.23],[1.390933,0.351029,1.20375],[1.390933,0.3675,1.184534],[1.390933,0.39,1.1775],[1.390933,0.4125,1.184534],[1.390933,0.428971,1.20375])),
                    #(false,true,#([1.195,0.39,1.23],[1.209067,0.435,1.23],[1.2475,0.467942,1.23],[1.3,0.48,1.23],[1.3525,0.467942,1.23],[1.390933,0.435,1.23],[1.405,0.39,1.23])),
                    #(false,true,#([1.195,0.39,1.23],[1.209067,0.428971,1.25625],[1.2475,0.4575,1.275466],[1.3,0.467942,1.2825],[1.3525,0.4575,1.275466],[1.390933,0.428971,1.25625],[1.405,0.39,1.23])),
                    #(false,true,#([1.195,0.39,1.23],[1.209067,0.4125,1.275466],[1.2475,0.428971,1.30875],[1.3,0.435,1.320933],[1.3525,0.428971,1.30875],[1.390933,0.4125,1.275466],[1.405,0.39,1.23])),
                    #(false,true,#([1.195,0.39,1.23],[1.209067,0.39,1.2825],[1.2475,0.39,1.320933],[1.3,0.39,1.335],[1.3525,0.39,1.320933],[1.390933,0.39,1.2825],[1.405,0.39,1.23])),
                    #(false,true,#([1.195,0.39,1.23],[1.209067,0.3675,1.275466],[1.2475,0.351029,1.30875],[1.3,0.345,1.320933],[1.3525,0.351029,1.30875],[1.390933,0.3675,1.275466],[1.405,0.39,1.23])),
                    #(false,true,#([1.195,0.39,1.23],[1.209067,0.351029,1.25625],[1.2475,0.3225,1.275466],[1.3,0.312058,1.2825],[1.3525,0.3225,1.275466],[1.390933,0.351029,1.25625],[1.405,0.39,1.23])),
                    #(false,true,#([1.195,0.39,1.23],[1.209067,0.345,1.23],[1.2475,0.312058,1.23],[1.3,0.3,1.23],[1.3525,0.312058,1.23],[1.390933,0.345,1.23],[1.405,0.39,1.23])),
                    #(false,true,#([1.195,0.39,1.23],[1.209067,0.351029,1.20375],[1.2475,0.3225,1.184534],[1.3,0.312058,1.1775],[1.3525,0.3225,1.184534],[1.390933,0.351029,1.20375],[1.405,0.39,1.23])),
                    #(false,true,#([1.195,0.39,1.23],[1.209067,0.3675,1.184534],[1.2475,0.351029,1.15125],[1.3,0.345,1.139067],[1.3525,0.351029,1.15125],[1.390933,0.3675,1.184534],[1.405,0.39,1.23])),
                    #(false,true,#([1.195,0.39,1.23],[1.209067,0.39,1.1775],[1.2475,0.39,1.139067],[1.3,0.39,1.125],[1.3525,0.39,1.139067],[1.390933,0.39,1.1775],[1.405,0.39,1.23])),
                    #(false,true,#([1.195,0.39,1.23],[1.209067,0.4125,1.184534],[1.2475,0.428971,1.15125],[1.3,0.435,1.139067],[1.3525,0.428971,1.15125],[1.390933,0.4125,1.184534],[1.405,0.39,1.23])),
                    #(false,true,#([1.195,0.39,1.23],[1.209067,0.428971,1.20375],[1.2475,0.4575,1.184534],[1.3,0.467942,1.1775],[1.3525,0.4575,1.184534],[1.390933,0.428971,1.20375],[1.405,0.39,1.23]))
                ) "dark" "body" true 0.0
                f.finishModel()
                f.startModel "paradelotus" "Flying lotus blossom" "prop" 1 0.15 [0.0,0.0,0.0] "" false
                f.cage "Petal0_0" #(
                    #(false,true,#([0.0,-0.018725,0.2],[0.0,-0.009363,0.2],[0.0,0.0,0.2],[0.0,0.009363,0.2],[0.0,0.018725,0.2])),
                    #(false,true,#([0.363,-0.347811,0.707854],[0.363,-0.173906,0.707854],[0.363,0.0,0.707854],[0.363,0.173906,0.707854],[0.363,0.347811,0.707854])),
                    #(false,true,#([0.825,-0.535,1.085],[0.825,-0.2675,1.085],[0.825,0.0,1.085],[0.825,0.2675,1.085],[0.825,0.535,1.085])),
                    #(false,true,#([1.287,-0.347811,1.027054],[1.287,-0.173906,1.027054],[1.287,0.0,1.027054],[1.287,0.173906,1.027054],[1.287,0.347811,1.027054])),
                    #(false,true,#([1.65,-0.018725,0.77],[1.65,-0.009363,0.77],[1.65,0.0,0.77],[1.65,0.009363,0.77],[1.65,0.018725,0.77])),
                    #(false,true,#([0.0,-0.018725,0.2],[0.363,-0.347811,0.707854],[0.825,-0.535,1.085],[1.287,-0.347811,1.027054],[1.65,-0.018725,0.77])),
                    #(false,true,#([0.0,-0.009363,0.2],[0.363,-0.173906,0.707854],[0.825,-0.2675,1.085],[1.287,-0.173906,1.027054],[1.65,-0.009363,0.77])),
                    #(false,true,#([0.0,0.0,0.2],[0.363,0.0,0.707854],[0.825,0.0,1.085],[1.287,0.0,1.027054],[1.65,0.0,0.77])),
                    #(false,true,#([0.0,0.009363,0.2],[0.363,0.173906,0.707854],[0.825,0.2675,1.085],[1.287,0.173906,1.027054],[1.65,0.009363,0.77])),
                    #(false,true,#([0.0,0.018725,0.2],[0.363,0.347811,0.707854],[0.825,0.535,1.085],[1.287,0.347811,1.027054],[1.65,0.018725,0.77]))
                ) "pink_glow" "body" false 0.18
                f.cage "Petal0_1" #(
                    #(false,true,#([0.016216,-0.009363,0.2],[0.008108,-0.004681,0.2],[0.0,0.0,0.2],[-0.008108,0.004681,0.2],[-0.016216,0.009363,0.2])),
                    #(false,true,#([0.482713,0.140462,0.707854],[0.332107,0.227414,0.707854],[0.1815,0.314367,0.707854],[0.030893,0.40132,0.707854],[-0.119713,0.488273,0.707854])),
                    #(false,true,#([0.875824,0.446971,1.085],[0.644162,0.580721,1.085],[0.4125,0.714471,1.085],[0.180838,0.848221,1.085],[-0.050824,0.981971,1.085])),
                    #(false,true,#([0.944713,0.940669,1.027054],[0.794107,1.027622,1.027054],[0.6435,1.114575,1.027054],[0.492893,1.201527,1.027054],[0.342287,1.28848,1.027054])),
                    #(false,true,#([0.841216,1.419579,0.77],[0.833108,1.424261,0.77],[0.825,1.428942,0.77],[0.816892,1.433623,0.77],[0.808784,1.438304,0.77])),
                    #(false,true,#([0.016216,-0.009363,0.2],[0.482713,0.140462,0.707854],[0.875824,0.446971,1.085],[0.944713,0.940669,1.027054],[0.841216,1.419579,0.77])),
                    #(false,true,#([0.008108,-0.004681,0.2],[0.332107,0.227414,0.707854],[0.644162,0.580721,1.085],[0.794107,1.027622,1.027054],[0.833108,1.424261,0.77])),
                    #(false,true,#([0.0,0.0,0.2],[0.1815,0.314367,0.707854],[0.4125,0.714471,1.085],[0.6435,1.114575,1.027054],[0.825,1.428942,0.77])),
                    #(false,true,#([-0.008108,0.004681,0.2],[0.030893,0.40132,0.707854],[0.180838,0.848221,1.085],[0.492893,1.201527,1.027054],[0.816892,1.433623,0.77])),
                    #(false,true,#([-0.016216,0.009363,0.2],[-0.119713,0.488273,0.707854],[-0.050824,0.981971,1.085],[0.342287,1.28848,1.027054],[0.808784,1.438304,0.77]))
                ) "pink_glow" "body" false 0.18
                f.cage "Petal0_2" #(
                    #(false,true,#([0.016216,0.009362,0.2],[0.008108,0.004681,0.2],[0.0,0.0,0.2],[-0.008108,-0.004681,0.2],[-0.016216,-0.009362,0.2])),
                    #(false,true,#([0.119713,0.488273,0.707854],[-0.030893,0.40132,0.707854],[-0.1815,0.314367,0.707854],[-0.332107,0.227414,0.707854],[-0.482713,0.140462,0.707854])),
                    #(false,true,#([0.050824,0.981971,1.085],[-0.180838,0.848221,1.085],[-0.4125,0.714471,1.085],[-0.644162,0.580721,1.085],[-0.875824,0.446971,1.085])),
                    #(false,true,#([-0.342287,1.28848,1.027054],[-0.492893,1.201527,1.027054],[-0.6435,1.114575,1.027054],[-0.794107,1.027622,1.027054],[-0.944713,0.940669,1.027054])),
                    #(false,true,#([-0.808784,1.438304,0.77],[-0.816892,1.433623,0.77],[-0.825,1.428942,0.77],[-0.833108,1.424261,0.77],[-0.841216,1.419579,0.77])),
                    #(false,true,#([0.016216,0.009362,0.2],[0.119713,0.488273,0.707854],[0.050824,0.981971,1.085],[-0.342287,1.28848,1.027054],[-0.808784,1.438304,0.77])),
                    #(false,true,#([0.008108,0.004681,0.2],[-0.030893,0.40132,0.707854],[-0.180838,0.848221,1.085],[-0.492893,1.201527,1.027054],[-0.816892,1.433623,0.77])),
                    #(false,true,#([0.0,0.0,0.2],[-0.1815,0.314367,0.707854],[-0.4125,0.714471,1.085],[-0.6435,1.114575,1.027054],[-0.825,1.428942,0.77])),
                    #(false,true,#([-0.008108,-0.004681,0.2],[-0.332107,0.227414,0.707854],[-0.644162,0.580721,1.085],[-0.794107,1.027622,1.027054],[-0.833108,1.424261,0.77])),
                    #(false,true,#([-0.016216,-0.009362,0.2],[-0.482713,0.140462,0.707854],[-0.875824,0.446971,1.085],[-0.944713,0.940669,1.027054],[-0.841216,1.419579,0.77]))
                ) "pink_glow" "body" false 0.18
                f.cage "Petal0_3" #(
                    #(false,true,#([0.0,0.018725,0.2],[0.0,0.009363,0.2],[0.0,0.0,0.2],[0.0,-0.009363,0.2],[0.0,-0.018725,0.2])),
                    #(false,true,#([-0.363,0.347811,0.707854],[-0.363,0.173906,0.707854],[-0.363,0.0,0.707854],[-0.363,-0.173906,0.707854],[-0.363,-0.347811,0.707854])),
                    #(false,true,#([-0.825,0.535,1.085],[-0.825,0.2675,1.085],[-0.825,0.0,1.085],[-0.825,-0.2675,1.085],[-0.825,-0.535,1.085])),
                    #(false,true,#([-1.287,0.347811,1.027054],[-1.287,0.173906,1.027054],[-1.287,0.0,1.027054],[-1.287,-0.173906,1.027054],[-1.287,-0.347811,1.027054])),
                    #(false,true,#([-1.65,0.018725,0.77],[-1.65,0.009363,0.77],[-1.65,0.0,0.77],[-1.65,-0.009362,0.77],[-1.65,-0.018725,0.77])),
                    #(false,true,#([0.0,0.018725,0.2],[-0.363,0.347811,0.707854],[-0.825,0.535,1.085],[-1.287,0.347811,1.027054],[-1.65,0.018725,0.77])),
                    #(false,true,#([0.0,0.009363,0.2],[-0.363,0.173906,0.707854],[-0.825,0.2675,1.085],[-1.287,0.173906,1.027054],[-1.65,0.009363,0.77])),
                    #(false,true,#([0.0,0.0,0.2],[-0.363,0.0,0.707854],[-0.825,0.0,1.085],[-1.287,0.0,1.027054],[-1.65,0.0,0.77])),
                    #(false,true,#([0.0,-0.009363,0.2],[-0.363,-0.173906,0.707854],[-0.825,-0.2675,1.085],[-1.287,-0.173906,1.027054],[-1.65,-0.009362,0.77])),
                    #(false,true,#([0.0,-0.018725,0.2],[-0.363,-0.347811,0.707854],[-0.825,-0.535,1.085],[-1.287,-0.347811,1.027054],[-1.65,-0.018725,0.77]))
                ) "pink_glow" "body" false 0.18
                f.cage "Petal0_4" #(
                    #(false,true,#([-0.016216,0.009363,0.2],[-0.008108,0.004681,0.2],[0.0,0.0,0.2],[0.008108,-0.004681,0.2],[0.016216,-0.009363,0.2])),
                    #(false,true,#([-0.482713,-0.140462,0.707854],[-0.332107,-0.227414,0.707854],[-0.1815,-0.314367,0.707854],[-0.030893,-0.40132,0.707854],[0.119713,-0.488273,0.707854])),
                    #(false,true,#([-0.875824,-0.446971,1.085],[-0.644162,-0.580721,1.085],[-0.4125,-0.714471,1.085],[-0.180838,-0.848221,1.085],[0.050824,-0.981971,1.085])),
                    #(false,true,#([-0.944713,-0.940669,1.027054],[-0.794107,-1.027622,1.027054],[-0.6435,-1.114575,1.027054],[-0.492893,-1.201527,1.027054],[-0.342287,-1.28848,1.027054])),
                    #(false,true,#([-0.841216,-1.419579,0.77],[-0.833108,-1.424261,0.77],[-0.825,-1.428942,0.77],[-0.816892,-1.433623,0.77],[-0.808784,-1.438304,0.77])),
                    #(false,true,#([-0.016216,0.009363,0.2],[-0.482713,-0.140462,0.707854],[-0.875824,-0.446971,1.085],[-0.944713,-0.940669,1.027054],[-0.841216,-1.419579,0.77])),
                    #(false,true,#([-0.008108,0.004681,0.2],[-0.332107,-0.227414,0.707854],[-0.644162,-0.580721,1.085],[-0.794107,-1.027622,1.027054],[-0.833108,-1.424261,0.77])),
                    #(false,true,#([0.0,0.0,0.2],[-0.1815,-0.314367,0.707854],[-0.4125,-0.714471,1.085],[-0.6435,-1.114575,1.027054],[-0.825,-1.428942,0.77])),
                    #(false,true,#([0.008108,-0.004681,0.2],[-0.030893,-0.40132,0.707854],[-0.180838,-0.848221,1.085],[-0.492893,-1.201527,1.027054],[-0.816892,-1.433623,0.77])),
                    #(false,true,#([0.016216,-0.009363,0.2],[0.119713,-0.488273,0.707854],[0.050824,-0.981971,1.085],[-0.342287,-1.28848,1.027054],[-0.808784,-1.438304,0.77]))
                ) "pink_glow" "body" false 0.18
                f.cage "Petal0_5" #(
                    #(false,true,#([-0.016216,-0.009363,0.2],[-0.008108,-0.004681,0.2],[0.0,0.0,0.2],[0.008108,0.004681,0.2],[0.016216,0.009363,0.2])),
                    #(false,true,#([-0.119713,-0.488273,0.707854],[0.030893,-0.40132,0.707854],[0.1815,-0.314367,0.707854],[0.332107,-0.227414,0.707854],[0.482713,-0.140462,0.707854])),
                    #(false,true,#([-0.050824,-0.981971,1.085],[0.180838,-0.848221,1.085],[0.4125,-0.714471,1.085],[0.644162,-0.580721,1.085],[0.875824,-0.446971,1.085])),
                    #(false,true,#([0.342287,-1.28848,1.027054],[0.492893,-1.201527,1.027054],[0.6435,-1.114575,1.027054],[0.794107,-1.027622,1.027054],[0.944713,-0.940669,1.027054])),
                    #(false,true,#([0.808784,-1.438304,0.77],[0.816892,-1.433623,0.77],[0.825,-1.428942,0.77],[0.833108,-1.424261,0.77],[0.841216,-1.419579,0.77])),
                    #(false,true,#([-0.016216,-0.009363,0.2],[-0.119713,-0.488273,0.707854],[-0.050824,-0.981971,1.085],[0.342287,-1.28848,1.027054],[0.808784,-1.438304,0.77])),
                    #(false,true,#([-0.008108,-0.004681,0.2],[0.030893,-0.40132,0.707854],[0.180838,-0.848221,1.085],[0.492893,-1.201527,1.027054],[0.816892,-1.433623,0.77])),
                    #(false,true,#([0.0,0.0,0.2],[0.1815,-0.314367,0.707854],[0.4125,-0.714471,1.085],[0.6435,-1.114575,1.027054],[0.825,-1.428942,0.77])),
                    #(false,true,#([0.008108,0.004681,0.2],[0.332107,-0.227414,0.707854],[0.644162,-0.580721,1.085],[0.794107,-1.027622,1.027054],[0.833108,-1.424261,0.77])),
                    #(false,true,#([0.016216,0.009363,0.2],[0.482713,-0.140462,0.707854],[0.875824,-0.446971,1.085],[0.944713,-0.940669,1.027054],[0.841216,-1.419579,0.77]))
                ) "pink_glow" "body" false 0.18
                f.cage "Petal1_0" #(
                    #(false,true,#([0.007263,-0.012579,0.4],[0.003631,-0.00629,0.4],[0.0,0.0,0.4],[-0.003631,0.00629,0.4],[-0.007263,0.012579,0.4])),
                    #(false,true,#([0.334951,-0.118151,1.048654],[0.267501,-0.001326,1.048654],[0.200052,0.1155,1.048654],[0.132603,0.232326,1.048654],[0.065153,0.349151,1.048654])),
                    #(false,true,#([0.662163,-0.096901,1.605],[0.558413,0.0828,1.605],[0.454663,0.2625,1.605],[0.350913,0.4422,1.605],[0.247163,0.621901,1.605])),
                    #(false,true,#([0.844173,0.175849,1.726254],[0.776724,0.292674,1.726254],[0.709275,0.4095,1.726254],[0.641825,0.526326,1.726254],[0.574376,0.643151,1.726254])),
                    #(false,true,#([0.916589,0.512421,1.61],[0.912958,0.51871,1.61],[0.909327,0.525,1.61],[0.905695,0.53129,1.61],[0.902064,0.537579,1.61])),
                    #(false,true,#([0.007263,-0.012579,0.4],[0.334951,-0.118151,1.048654],[0.662163,-0.096901,1.605],[0.844173,0.175849,1.726254],[0.916589,0.512421,1.61])),
                    #(false,true,#([0.003631,-0.00629,0.4],[0.267501,-0.001326,1.048654],[0.558413,0.0828,1.605],[0.776724,0.292674,1.726254],[0.912958,0.51871,1.61])),
                    #(false,true,#([0.0,0.0,0.4],[0.200052,0.1155,1.048654],[0.454663,0.2625,1.605],[0.709275,0.4095,1.726254],[0.909327,0.525,1.61])),
                    #(false,true,#([-0.003631,0.00629,0.4],[0.132603,0.232326,1.048654],[0.350913,0.4422,1.605],[0.641825,0.526326,1.726254],[0.905695,0.53129,1.61])),
                    #(false,true,#([-0.007263,0.012579,0.4],[0.065153,0.349151,1.048654],[0.247163,0.621901,1.605],[0.574376,0.643151,1.726254],[0.902064,0.537579,1.61]))
                ) "ivory_glow" "body" false 0.18
                f.cage "Petal1_1" #(
                    #(false,true,#([0.014525,0.0,0.4],[0.007263,0.0,0.4],[0.0,0.0,0.4],[-0.007263,0.0,0.4],[-0.014525,0.0,0.4])),
                    #(false,true,#([0.269797,0.231,1.048654],[0.134899,0.231,1.048654],[0.0,0.231,1.048654],[-0.134899,0.231,1.048654],[-0.269797,0.231,1.048654])),
                    #(false,true,#([0.415,0.525,1.605],[0.2075,0.525,1.605],[0.0,0.525,1.605],[-0.2075,0.525,1.605],[-0.415,0.525,1.605])),
                    #(false,true,#([0.269797,0.819,1.726254],[0.134899,0.819,1.726254],[0.0,0.819,1.726254],[-0.134899,0.819,1.726254],[-0.269797,0.819,1.726254])),
                    #(false,true,#([0.014525,1.05,1.61],[0.007263,1.05,1.61],[0.0,1.05,1.61],[-0.007262,1.05,1.61],[-0.014525,1.05,1.61])),
                    #(false,true,#([0.014525,0.0,0.4],[0.269797,0.231,1.048654],[0.415,0.525,1.605],[0.269797,0.819,1.726254],[0.014525,1.05,1.61])),
                    #(false,true,#([0.007263,0.0,0.4],[0.134899,0.231,1.048654],[0.2075,0.525,1.605],[0.134899,0.819,1.726254],[0.007263,1.05,1.61])),
                    #(false,true,#([0.0,0.0,0.4],[0.0,0.231,1.048654],[0.0,0.525,1.605],[0.0,0.819,1.726254],[0.0,1.05,1.61])),
                    #(false,true,#([-0.007263,0.0,0.4],[-0.134899,0.231,1.048654],[-0.2075,0.525,1.605],[-0.134899,0.819,1.726254],[-0.007262,1.05,1.61])),
                    #(false,true,#([-0.014525,0.0,0.4],[-0.269797,0.231,1.048654],[-0.415,0.525,1.605],[-0.269797,0.819,1.726254],[-0.014525,1.05,1.61]))
                ) "ivory_glow" "body" false 0.18
                f.cage "Petal1_2" #(
                    #(false,true,#([0.007263,0.012579,0.4],[0.003631,0.00629,0.4],[0.0,0.0,0.4],[-0.003631,-0.00629,0.4],[-0.007263,-0.012579,0.4])),
                    #(false,true,#([-0.065153,0.349151,1.048654],[-0.132603,0.232326,1.048654],[-0.200052,0.1155,1.048654],[-0.267501,-0.001326,1.048654],[-0.334951,-0.118151,1.048654])),
                    #(false,true,#([-0.247163,0.621901,1.605],[-0.350913,0.4422,1.605],[-0.454663,0.2625,1.605],[-0.558413,0.0828,1.605],[-0.662163,-0.096901,1.605])),
                    #(false,true,#([-0.574376,0.643151,1.726254],[-0.641825,0.526326,1.726254],[-0.709275,0.4095,1.726254],[-0.776724,0.292674,1.726254],[-0.844173,0.175849,1.726254])),
                    #(false,true,#([-0.902064,0.537579,1.61],[-0.905695,0.53129,1.61],[-0.909327,0.525,1.61],[-0.912958,0.51871,1.61],[-0.916589,0.512421,1.61])),
                    #(false,true,#([0.007263,0.012579,0.4],[-0.065153,0.349151,1.048654],[-0.247163,0.621901,1.605],[-0.574376,0.643151,1.726254],[-0.902064,0.537579,1.61])),
                    #(false,true,#([0.003631,0.00629,0.4],[-0.132603,0.232326,1.048654],[-0.350913,0.4422,1.605],[-0.641825,0.526326,1.726254],[-0.905695,0.53129,1.61])),
                    #(false,true,#([0.0,0.0,0.4],[-0.200052,0.1155,1.048654],[-0.454663,0.2625,1.605],[-0.709275,0.4095,1.726254],[-0.909327,0.525,1.61])),
                    #(false,true,#([-0.003631,-0.00629,0.4],[-0.267501,-0.001326,1.048654],[-0.558413,0.0828,1.605],[-0.776724,0.292674,1.726254],[-0.912958,0.51871,1.61])),
                    #(false,true,#([-0.007263,-0.012579,0.4],[-0.334951,-0.118151,1.048654],[-0.662163,-0.096901,1.605],[-0.844173,0.175849,1.726254],[-0.916589,0.512421,1.61]))
                ) "ivory_glow" "body" false 0.18
                f.cage "Petal1_3" #(
                    #(false,true,#([-0.007262,0.012579,0.4],[-0.003631,0.00629,0.4],[0.0,0.0,0.4],[0.003631,-0.00629,0.4],[0.007262,-0.012579,0.4])),
                    #(false,true,#([-0.334951,0.118151,1.048654],[-0.267501,0.001326,1.048654],[-0.200052,-0.1155,1.048654],[-0.132603,-0.232326,1.048654],[-0.065153,-0.349151,1.048654])),
                    #(false,true,#([-0.662163,0.096901,1.605],[-0.558413,-0.0828,1.605],[-0.454663,-0.2625,1.605],[-0.350913,-0.4422,1.605],[-0.247163,-0.621901,1.605])),
                    #(false,true,#([-0.844173,-0.175849,1.726254],[-0.776724,-0.292674,1.726254],[-0.709275,-0.4095,1.726254],[-0.641825,-0.526326,1.726254],[-0.574376,-0.643151,1.726254])),
                    #(false,true,#([-0.916589,-0.512421,1.61],[-0.912958,-0.51871,1.61],[-0.909327,-0.525,1.61],[-0.905695,-0.53129,1.61],[-0.902064,-0.537579,1.61])),
                    #(false,true,#([-0.007262,0.012579,0.4],[-0.334951,0.118151,1.048654],[-0.662163,0.096901,1.605],[-0.844173,-0.175849,1.726254],[-0.916589,-0.512421,1.61])),
                    #(false,true,#([-0.003631,0.00629,0.4],[-0.267501,0.001326,1.048654],[-0.558413,-0.0828,1.605],[-0.776724,-0.292674,1.726254],[-0.912958,-0.51871,1.61])),
                    #(false,true,#([0.0,0.0,0.4],[-0.200052,-0.1155,1.048654],[-0.454663,-0.2625,1.605],[-0.709275,-0.4095,1.726254],[-0.909327,-0.525,1.61])),
                    #(false,true,#([0.003631,-0.00629,0.4],[-0.132603,-0.232326,1.048654],[-0.350913,-0.4422,1.605],[-0.641825,-0.526326,1.726254],[-0.905695,-0.53129,1.61])),
                    #(false,true,#([0.007262,-0.012579,0.4],[-0.065153,-0.349151,1.048654],[-0.247163,-0.621901,1.605],[-0.574376,-0.643151,1.726254],[-0.902064,-0.537579,1.61]))
                ) "ivory_glow" "body" false 0.18
                f.cage "Petal1_4" #(
                    #(false,true,#([-0.014525,0.0,0.4],[-0.007263,0.0,0.4],[0.0,0.0,0.4],[0.007263,0.0,0.4],[0.014525,0.0,0.4])),
                    #(false,true,#([-0.269797,-0.231,1.048654],[-0.134899,-0.231,1.048654],[0.0,-0.231,1.048654],[0.134899,-0.231,1.048654],[0.269797,-0.231,1.048654])),
                    #(false,true,#([-0.415,-0.525,1.605],[-0.2075,-0.525,1.605],[0.0,-0.525,1.605],[0.2075,-0.525,1.605],[0.415,-0.525,1.605])),
                    #(false,true,#([-0.269797,-0.819,1.726254],[-0.134899,-0.819,1.726254],[0.0,-0.819,1.726254],[0.134899,-0.819,1.726254],[0.269797,-0.819,1.726254])),
                    #(false,true,#([-0.014525,-1.05,1.61],[-0.007263,-1.05,1.61],[0.0,-1.05,1.61],[0.007262,-1.05,1.61],[0.014525,-1.05,1.61])),
                    #(false,true,#([-0.014525,0.0,0.4],[-0.269797,-0.231,1.048654],[-0.415,-0.525,1.605],[-0.269797,-0.819,1.726254],[-0.014525,-1.05,1.61])),
                    #(false,true,#([-0.007263,0.0,0.4],[-0.134899,-0.231,1.048654],[-0.2075,-0.525,1.605],[-0.134899,-0.819,1.726254],[-0.007263,-1.05,1.61])),
                    #(false,true,#([0.0,0.0,0.4],[0.0,-0.231,1.048654],[0.0,-0.525,1.605],[0.0,-0.819,1.726254],[0.0,-1.05,1.61])),
                    #(false,true,#([0.007263,0.0,0.4],[0.134899,-0.231,1.048654],[0.2075,-0.525,1.605],[0.134899,-0.819,1.726254],[0.007262,-1.05,1.61])),
                    #(false,true,#([0.014525,0.0,0.4],[0.269797,-0.231,1.048654],[0.415,-0.525,1.605],[0.269797,-0.819,1.726254],[0.014525,-1.05,1.61]))
                ) "ivory_glow" "body" false 0.18
                f.cage "Petal1_5" #(
                    #(false,true,#([-0.007262,-0.012579,0.4],[-0.003631,-0.00629,0.4],[0.0,0.0,0.4],[0.003631,0.00629,0.4],[0.007262,0.012579,0.4])),
                    #(false,true,#([0.065153,-0.349151,1.048654],[0.132603,-0.232326,1.048654],[0.200052,-0.1155,1.048654],[0.267501,0.001326,1.048654],[0.334951,0.118151,1.048654])),
                    #(false,true,#([0.247163,-0.621901,1.605],[0.350913,-0.4422,1.605],[0.454663,-0.2625,1.605],[0.558413,-0.0828,1.605],[0.662163,0.096901,1.605])),
                    #(false,true,#([0.574376,-0.643151,1.726254],[0.641825,-0.526326,1.726254],[0.709275,-0.4095,1.726254],[0.776724,-0.292674,1.726254],[0.844173,-0.175849,1.726254])),
                    #(false,true,#([0.902064,-0.537579,1.61],[0.905695,-0.53129,1.61],[0.909327,-0.525,1.61],[0.912958,-0.51871,1.61],[0.916589,-0.512421,1.61])),
                    #(false,true,#([-0.007262,-0.012579,0.4],[0.065153,-0.349151,1.048654],[0.247163,-0.621901,1.605],[0.574376,-0.643151,1.726254],[0.902064,-0.537579,1.61])),
                    #(false,true,#([-0.003631,-0.00629,0.4],[0.132603,-0.232326,1.048654],[0.350913,-0.4422,1.605],[0.641825,-0.526326,1.726254],[0.905695,-0.53129,1.61])),
                    #(false,true,#([0.0,0.0,0.4],[0.200052,-0.1155,1.048654],[0.454663,-0.2625,1.605],[0.709275,-0.4095,1.726254],[0.909327,-0.525,1.61])),
                    #(false,true,#([0.003631,0.00629,0.4],[0.267501,0.001326,1.048654],[0.558413,-0.0828,1.605],[0.776724,-0.292674,1.726254],[0.912958,-0.51871,1.61])),
                    #(false,true,#([0.007262,0.012579,0.4],[0.334951,0.118151,1.048654],[0.662163,0.096901,1.605],[0.844173,-0.175849,1.726254],[0.916589,-0.512421,1.61]))
                ) "ivory_glow" "body" false 0.18
                f.cage "Heart" #(
                    #(true,true,#([-0.389711,0.225,0.77],[-0.389711,0.194856,0.845],[-0.389711,0.1125,0.899904],[-0.389711,0.0,0.92],[-0.389711,-0.1125,0.899904],[-0.389711,-0.194856,0.845],[-0.389711,-0.225,0.77],[-0.389711,-0.194856,0.695],[-0.389711,-0.1125,0.640096],[-0.389711,0.0,0.62],[-0.389711,0.1125,0.640096],[-0.389711,0.194856,0.695])),
                    #(true,true,#([-0.225,0.389711,0.77],[-0.225,0.3375,0.899904],[-0.225,0.194856,0.995],[-0.225,0.0,1.029808],[-0.225,-0.194856,0.995],[-0.225,-0.3375,0.899904],[-0.225,-0.389711,0.77],[-0.225,-0.3375,0.640096],[-0.225,-0.194856,0.545],[-0.225,0.0,0.510192],[-0.225,0.194856,0.545],[-0.225,0.3375,0.640096])),
                    #(true,true,#([0.0,0.45,0.77],[0.0,0.389711,0.92],[0.0,0.225,1.029808],[0.0,0.0,1.07],[0.0,-0.225,1.029808],[0.0,-0.389711,0.92],[0.0,-0.45,0.77],[0.0,-0.389711,0.62],[0.0,-0.225,0.510192],[0.0,0.0,0.47],[0.0,0.225,0.510192],[0.0,0.389711,0.62])),
                    #(true,true,#([0.225,0.389711,0.77],[0.225,0.3375,0.899904],[0.225,0.194856,0.995],[0.225,0.0,1.029808],[0.225,-0.194856,0.995],[0.225,-0.3375,0.899904],[0.225,-0.389711,0.77],[0.225,-0.3375,0.640096],[0.225,-0.194856,0.545],[0.225,0.0,0.510192],[0.225,0.194856,0.545],[0.225,0.3375,0.640096])),
                    #(true,true,#([0.389711,0.225,0.77],[0.389711,0.194856,0.845],[0.389711,0.1125,0.899904],[0.389711,0.0,0.92],[0.389711,-0.1125,0.899904],[0.389711,-0.194856,0.845],[0.389711,-0.225,0.77],[0.389711,-0.194856,0.695],[0.389711,-0.1125,0.640096],[0.389711,0.0,0.62],[0.389711,0.1125,0.640096],[0.389711,0.194856,0.695])),
                    #(false,true,#([-0.45,0.0,0.77],[-0.389711,0.225,0.77],[-0.225,0.389711,0.77],[0.0,0.45,0.77],[0.225,0.389711,0.77],[0.389711,0.225,0.77],[0.45,0.0,0.77])),
                    #(false,true,#([-0.45,0.0,0.77],[-0.389711,0.194856,0.845],[-0.225,0.3375,0.899904],[0.0,0.389711,0.92],[0.225,0.3375,0.899904],[0.389711,0.194856,0.845],[0.45,0.0,0.77])),
                    #(false,true,#([-0.45,0.0,0.77],[-0.389711,0.1125,0.899904],[-0.225,0.194856,0.995],[0.0,0.225,1.029808],[0.225,0.194856,0.995],[0.389711,0.1125,0.899904],[0.45,0.0,0.77])),
                    #(false,true,#([-0.45,0.0,0.77],[-0.389711,0.0,0.92],[-0.225,0.0,1.029808],[0.0,0.0,1.07],[0.225,0.0,1.029808],[0.389711,0.0,0.92],[0.45,0.0,0.77])),
                    #(false,true,#([-0.45,0.0,0.77],[-0.389711,-0.1125,0.899904],[-0.225,-0.194856,0.995],[0.0,-0.225,1.029808],[0.225,-0.194856,0.995],[0.389711,-0.1125,0.899904],[0.45,0.0,0.77])),
                    #(false,true,#([-0.45,0.0,0.77],[-0.389711,-0.194856,0.845],[-0.225,-0.3375,0.899904],[0.0,-0.389711,0.92],[0.225,-0.3375,0.899904],[0.389711,-0.194856,0.845],[0.45,0.0,0.77])),
                    #(false,true,#([-0.45,0.0,0.77],[-0.389711,-0.225,0.77],[-0.225,-0.389711,0.77],[0.0,-0.45,0.77],[0.225,-0.389711,0.77],[0.389711,-0.225,0.77],[0.45,0.0,0.77])),
                    #(false,true,#([-0.45,0.0,0.77],[-0.389711,-0.194856,0.695],[-0.225,-0.3375,0.640096],[0.0,-0.389711,0.62],[0.225,-0.3375,0.640096],[0.389711,-0.194856,0.695],[0.45,0.0,0.77])),
                    #(false,true,#([-0.45,0.0,0.77],[-0.389711,-0.1125,0.640096],[-0.225,-0.194856,0.545],[0.0,-0.225,0.510192],[0.225,-0.194856,0.545],[0.389711,-0.1125,0.640096],[0.45,0.0,0.77])),
                    #(false,true,#([-0.45,0.0,0.77],[-0.389711,0.0,0.62],[-0.225,0.0,0.510192],[0.0,0.0,0.47],[0.225,0.0,0.510192],[0.389711,0.0,0.62],[0.45,0.0,0.77])),
                    #(false,true,#([-0.45,0.0,0.77],[-0.389711,0.1125,0.640096],[-0.225,0.194856,0.545],[0.0,0.225,0.510192],[0.225,0.194856,0.545],[0.389711,0.1125,0.640096],[0.45,0.0,0.77])),
                    #(false,true,#([-0.45,0.0,0.77],[-0.389711,0.194856,0.695],[-0.225,0.3375,0.640096],[0.0,0.389711,0.62],[0.225,0.3375,0.640096],[0.389711,0.194856,0.695],[0.45,0.0,0.77]))
                ) "gold_glow" "body" true 0.0
                f.finishModel()
                f.startModel "paradeleaf" "Flying leaf" "prop" 1 0.13 [0.0,0.0,0.0] "" false
                f.cage "Blade" #(
                    #(false,true,#([-0.02663,0.0,0.165157],[-0.013315,0.0,0.162579],[0.0,0.0,0.16],[0.013315,0.0,0.157421],[0.02663,0.0,0.154843])),
                    #(false,true,#([-0.373648,0.114736,0.880595],[-0.126324,0.114736,0.832697],[0.121,0.114736,0.7848],[0.368324,0.114736,0.736903],[0.615648,0.114736,0.689005])),
                    #(false,true,#([-0.485863,0.18,1.72735],[-0.105432,0.18,1.653675],[0.275,0.18,1.58],[0.655432,0.18,1.506325],[1.035863,0.18,1.43265])),
                    #(false,true,#([-0.065648,0.114736,2.470995],[0.181676,0.114736,2.423097],[0.429,0.114736,2.3752],[0.676324,0.114736,2.327303],[0.923648,0.114736,2.279405])),
                    #(false,true,#([0.52337,0.0,3.005157],[0.536685,0.0,3.002579],[0.55,0.0,3.0],[0.563315,0.0,2.997421],[0.57663,0.0,2.994843])),
                    #(false,true,#([-0.02663,0.0,0.165157],[-0.373648,0.114736,0.880595],[-0.485863,0.18,1.72735],[-0.065648,0.114736,2.470995],[0.52337,0.0,3.005157])),
                    #(false,true,#([-0.013315,0.0,0.162579],[-0.126324,0.114736,0.832697],[-0.105432,0.18,1.653675],[0.181676,0.114736,2.423097],[0.536685,0.0,3.002579])),
                    #(false,true,#([0.0,0.0,0.16],[0.121,0.114736,0.7848],[0.275,0.18,1.58],[0.429,0.114736,2.3752],[0.55,0.0,3.0])),
                    #(false,true,#([0.013315,0.0,0.157421],[0.368324,0.114736,0.736903],[0.655432,0.18,1.506325],[0.676324,0.114736,2.327303],[0.563315,0.0,2.997421])),
                    #(false,true,#([0.02663,0.0,0.154843],[0.615648,0.114736,0.689005],[1.035863,0.18,1.43265],[0.923648,0.114736,2.279405],[0.57663,0.0,2.994843]))
                ) "green_glow" "body" false 0.16
                f.tube "Vein" #([0.0,-0.13,0.03],[0.08,-0.13,0.73],[0.27,-0.13,1.53],[0.55,-0.13,2.94]) 0.06 4 false true "gold_glow" "body"
                f.tube "Branch0_L" #([0.0845,-0.13,0.65],[-0.3655,-0.11,0.93]) 0.035 4 false true "gold_glow" "body"
                f.tube "Branch0_R" #([0.0845,-0.13,0.65],[0.5345,-0.11,0.93]) 0.035 4 false true "gold_glow" "body"
                f.tube "Branch1_L" #([0.1521,-0.13,1.17],[-0.2979,-0.11,1.45]) 0.035 4 false true "gold_glow" "body"
                f.tube "Branch1_R" #([0.1521,-0.13,1.17],[0.6021,-0.11,1.45]) 0.035 4 false true "gold_glow" "body"
                f.tube "Branch2_L" #([0.2197,-0.13,1.69],[-0.2303,-0.11,1.97]) 0.035 4 false true "gold_glow" "body"
                f.tube "Branch2_R" #([0.2197,-0.13,1.69],[0.6697,-0.11,1.97]) 0.035 4 false true "gold_glow" "body"
                f.finishModel()
                f.startModel "paradestar" "Flying five-pointed star" "prop" 1 0.16 [0.0,0.0,0.0] "" false
                f.cage "Star" #(
                    #(true,false,#([0.0,-0.22,3.37],[0.423205,-0.22,2.302492],[1.569243,-0.22,2.229878],[0.684761,-0.22,1.497508],[0.969846,-0.22,0.385122],[0.0,-0.22,1.0],[-0.969846,-0.22,0.385122],[-0.684761,-0.22,1.497508],[-1.569243,-0.22,2.229878],[-0.423205,-0.22,2.302492])),
                    #(true,false,#([0.0,0.22,3.37],[0.423205,0.22,2.302492],[1.569243,0.22,2.229878],[0.684761,0.22,1.497508],[0.969846,0.22,0.385122],[0.0,0.22,1.0],[-0.969846,0.22,0.385122],[-0.684761,0.22,1.497508],[-1.569243,0.22,2.229878],[-0.423205,0.22,2.302492])),
                    #(false,false,#([0.0,-0.22,1.72],[0.0,-0.22,3.37],[0.0,0.22,3.37],[0.0,0.22,1.72])),
                    #(false,false,#([0.0,-0.22,1.72],[0.423205,-0.22,2.302492],[0.423205,0.22,2.302492],[0.0,0.22,1.72])),
                    #(false,false,#([0.0,-0.22,1.72],[1.569243,-0.22,2.229878],[1.569243,0.22,2.229878],[0.0,0.22,1.72])),
                    #(false,false,#([0.0,-0.22,1.72],[0.684761,-0.22,1.497508],[0.684761,0.22,1.497508],[0.0,0.22,1.72])),
                    #(false,false,#([0.0,-0.22,1.72],[0.969846,-0.22,0.385122],[0.969846,0.22,0.385122],[0.0,0.22,1.72])),
                    #(false,false,#([0.0,-0.22,1.72],[0.0,-0.22,1.0],[0.0,0.22,1.0],[0.0,0.22,1.72])),
                    #(false,false,#([0.0,-0.22,1.72],[-0.969846,-0.22,0.385122],[-0.969846,0.22,0.385122],[0.0,0.22,1.72])),
                    #(false,false,#([0.0,-0.22,1.72],[-0.684761,-0.22,1.497508],[-0.684761,0.22,1.497508],[0.0,0.22,1.72])),
                    #(false,false,#([0.0,-0.22,1.72],[-1.569243,-0.22,2.229878],[-1.569243,0.22,2.229878],[0.0,0.22,1.72])),
                    #(false,false,#([0.0,-0.22,1.72],[-0.423205,-0.22,2.302492],[-0.423205,0.22,2.302492],[0.0,0.22,1.72]))
                ) "gold_glow" "body" true 0.0
                f.finishModel()
                f.startModel "paradecloud" "Floating cloud" "prop" 1 0.18 [0.0,0.0,0.0] "" false
                f.cage "Lobe0" #(
                    #(true,true,#([-1.736122,0.275,0.8],[-1.736122,0.238157,0.9625],[-1.736122,0.1375,1.081458],[-1.736122,0.0,1.125],[-1.736122,-0.1375,1.081458],[-1.736122,-0.238157,0.9625],[-1.736122,-0.275,0.8],[-1.736122,-0.238157,0.6375],[-1.736122,-0.1375,0.518542],[-1.736122,0.0,0.475],[-1.736122,0.1375,0.518542],[-1.736122,0.238157,0.6375])),
                    #(true,true,#([-1.425,0.476314,0.8],[-1.425,0.4125,1.081458],[-1.425,0.238157,1.2875],[-1.425,0.0,1.362917],[-1.425,-0.238157,1.2875],[-1.425,-0.4125,1.081458],[-1.425,-0.476314,0.8],[-1.425,-0.4125,0.518542],[-1.425,-0.238157,0.3125],[-1.425,0.0,0.237083],[-1.425,0.238157,0.3125],[-1.425,0.4125,0.518542])),
                    #(true,true,#([-1.0,0.55,0.8],[-1.0,0.476314,1.125],[-1.0,0.275,1.362917],[-1.0,0.0,1.45],[-1.0,-0.275,1.362917],[-1.0,-0.476314,1.125],[-1.0,-0.55,0.8],[-1.0,-0.476314,0.475],[-1.0,-0.275,0.237083],[-1.0,0.0,0.15],[-1.0,0.275,0.237083],[-1.0,0.476314,0.475])),
                    #(true,true,#([-0.575,0.476314,0.8],[-0.575,0.4125,1.081458],[-0.575,0.238157,1.2875],[-0.575,0.0,1.362917],[-0.575,-0.238157,1.2875],[-0.575,-0.4125,1.081458],[-0.575,-0.476314,0.8],[-0.575,-0.4125,0.518542],[-0.575,-0.238157,0.3125],[-0.575,0.0,0.237083],[-0.575,0.238157,0.3125],[-0.575,0.4125,0.518542])),
                    #(true,true,#([-0.263878,0.275,0.8],[-0.263878,0.238157,0.9625],[-0.263878,0.1375,1.081458],[-0.263878,0.0,1.125],[-0.263878,-0.1375,1.081458],[-0.263878,-0.238157,0.9625],[-0.263878,-0.275,0.8],[-0.263878,-0.238157,0.6375],[-0.263878,-0.1375,0.518542],[-0.263878,0.0,0.475],[-0.263878,0.1375,0.518542],[-0.263878,0.238157,0.6375])),
                    #(false,true,#([-1.85,0.0,0.8],[-1.736122,0.275,0.8],[-1.425,0.476314,0.8],[-1.0,0.55,0.8],[-0.575,0.476314,0.8],[-0.263878,0.275,0.8],[-0.15,0.0,0.8])),
                    #(false,true,#([-1.85,0.0,0.8],[-1.736122,0.238157,0.9625],[-1.425,0.4125,1.081458],[-1.0,0.476314,1.125],[-0.575,0.4125,1.081458],[-0.263878,0.238157,0.9625],[-0.15,0.0,0.8])),
                    #(false,true,#([-1.85,0.0,0.8],[-1.736122,0.1375,1.081458],[-1.425,0.238157,1.2875],[-1.0,0.275,1.362917],[-0.575,0.238157,1.2875],[-0.263878,0.1375,1.081458],[-0.15,0.0,0.8])),
                    #(false,true,#([-1.85,0.0,0.8],[-1.736122,0.0,1.125],[-1.425,0.0,1.362917],[-1.0,0.0,1.45],[-0.575,0.0,1.362917],[-0.263878,0.0,1.125],[-0.15,0.0,0.8])),
                    #(false,true,#([-1.85,0.0,0.8],[-1.736122,-0.1375,1.081458],[-1.425,-0.238157,1.2875],[-1.0,-0.275,1.362917],[-0.575,-0.238157,1.2875],[-0.263878,-0.1375,1.081458],[-0.15,0.0,0.8])),
                    #(false,true,#([-1.85,0.0,0.8],[-1.736122,-0.238157,0.9625],[-1.425,-0.4125,1.081458],[-1.0,-0.476314,1.125],[-0.575,-0.4125,1.081458],[-0.263878,-0.238157,0.9625],[-0.15,0.0,0.8])),
                    #(false,true,#([-1.85,0.0,0.8],[-1.736122,-0.275,0.8],[-1.425,-0.476314,0.8],[-1.0,-0.55,0.8],[-0.575,-0.476314,0.8],[-0.263878,-0.275,0.8],[-0.15,0.0,0.8])),
                    #(false,true,#([-1.85,0.0,0.8],[-1.736122,-0.238157,0.6375],[-1.425,-0.4125,0.518542],[-1.0,-0.476314,0.475],[-0.575,-0.4125,0.518542],[-0.263878,-0.238157,0.6375],[-0.15,0.0,0.8])),
                    #(false,true,#([-1.85,0.0,0.8],[-1.736122,-0.1375,0.518542],[-1.425,-0.238157,0.3125],[-1.0,-0.275,0.237083],[-0.575,-0.238157,0.3125],[-0.263878,-0.1375,0.518542],[-0.15,0.0,0.8])),
                    #(false,true,#([-1.85,0.0,0.8],[-1.736122,0.0,0.475],[-1.425,0.0,0.237083],[-1.0,0.0,0.15],[-0.575,0.0,0.237083],[-0.263878,0.0,0.475],[-0.15,0.0,0.8])),
                    #(false,true,#([-1.85,0.0,0.8],[-1.736122,0.1375,0.518542],[-1.425,0.238157,0.3125],[-1.0,0.275,0.237083],[-0.575,0.238157,0.3125],[-0.263878,0.1375,0.518542],[-0.15,0.0,0.8])),
                    #(false,true,#([-1.85,0.0,0.8],[-1.736122,0.238157,0.6375],[-1.425,0.4125,0.518542],[-1.0,0.476314,0.475],[-0.575,0.4125,0.518542],[-0.263878,0.238157,0.6375],[-0.15,0.0,0.8]))
                ) "ivory_glow" "body" true 0.0
                f.cage "Lobe1" #(
                    #(true,true,#([-0.866025,0.275,1.2],[-0.866025,0.238157,1.4625],[-0.866025,0.1375,1.654663],[-0.866025,0.0,1.725],[-0.866025,-0.1375,1.654663],[-0.866025,-0.238157,1.4625],[-0.866025,-0.275,1.2],[-0.866025,-0.238157,0.9375],[-0.866025,-0.1375,0.745337],[-0.866025,0.0,0.675],[-0.866025,0.1375,0.745337],[-0.866025,0.238157,0.9375])),
                    #(true,true,#([-0.5,0.476314,1.2],[-0.5,0.4125,1.654663],[-0.5,0.238157,1.9875],[-0.5,0.0,2.109327],[-0.5,-0.238157,1.9875],[-0.5,-0.4125,1.654663],[-0.5,-0.476314,1.2],[-0.5,-0.4125,0.745337],[-0.5,-0.238157,0.4125],[-0.5,0.0,0.290673],[-0.5,0.238157,0.4125],[-0.5,0.4125,0.745337])),
                    #(true,true,#([0.0,0.55,1.2],[0.0,0.476314,1.725],[0.0,0.275,2.109327],[0.0,0.0,2.25],[0.0,-0.275,2.109327],[0.0,-0.476314,1.725],[0.0,-0.55,1.2],[0.0,-0.476314,0.675],[0.0,-0.275,0.290673],[0.0,0.0,0.15],[0.0,0.275,0.290673],[0.0,0.476314,0.675])),
                    #(true,true,#([0.5,0.476314,1.2],[0.5,0.4125,1.654663],[0.5,0.238157,1.9875],[0.5,0.0,2.109327],[0.5,-0.238157,1.9875],[0.5,-0.4125,1.654663],[0.5,-0.476314,1.2],[0.5,-0.4125,0.745337],[0.5,-0.238157,0.4125],[0.5,0.0,0.290673],[0.5,0.238157,0.4125],[0.5,0.4125,0.745337])),
                    #(true,true,#([0.866025,0.275,1.2],[0.866025,0.238157,1.4625],[0.866025,0.1375,1.654663],[0.866025,0.0,1.725],[0.866025,-0.1375,1.654663],[0.866025,-0.238157,1.4625],[0.866025,-0.275,1.2],[0.866025,-0.238157,0.9375],[0.866025,-0.1375,0.745337],[0.866025,0.0,0.675],[0.866025,0.1375,0.745337],[0.866025,0.238157,0.9375])),
                    #(false,true,#([-1.0,0.0,1.2],[-0.866025,0.275,1.2],[-0.5,0.476314,1.2],[0.0,0.55,1.2],[0.5,0.476314,1.2],[0.866025,0.275,1.2],[1.0,0.0,1.2])),
                    #(false,true,#([-1.0,0.0,1.2],[-0.866025,0.238157,1.4625],[-0.5,0.4125,1.654663],[0.0,0.476314,1.725],[0.5,0.4125,1.654663],[0.866025,0.238157,1.4625],[1.0,0.0,1.2])),
                    #(false,true,#([-1.0,0.0,1.2],[-0.866025,0.1375,1.654663],[-0.5,0.238157,1.9875],[0.0,0.275,2.109327],[0.5,0.238157,1.9875],[0.866025,0.1375,1.654663],[1.0,0.0,1.2])),
                    #(false,true,#([-1.0,0.0,1.2],[-0.866025,0.0,1.725],[-0.5,0.0,2.109327],[0.0,0.0,2.25],[0.5,0.0,2.109327],[0.866025,0.0,1.725],[1.0,0.0,1.2])),
                    #(false,true,#([-1.0,0.0,1.2],[-0.866025,-0.1375,1.654663],[-0.5,-0.238157,1.9875],[0.0,-0.275,2.109327],[0.5,-0.238157,1.9875],[0.866025,-0.1375,1.654663],[1.0,0.0,1.2])),
                    #(false,true,#([-1.0,0.0,1.2],[-0.866025,-0.238157,1.4625],[-0.5,-0.4125,1.654663],[0.0,-0.476314,1.725],[0.5,-0.4125,1.654663],[0.866025,-0.238157,1.4625],[1.0,0.0,1.2])),
                    #(false,true,#([-1.0,0.0,1.2],[-0.866025,-0.275,1.2],[-0.5,-0.476314,1.2],[0.0,-0.55,1.2],[0.5,-0.476314,1.2],[0.866025,-0.275,1.2],[1.0,0.0,1.2])),
                    #(false,true,#([-1.0,0.0,1.2],[-0.866025,-0.238157,0.9375],[-0.5,-0.4125,0.745337],[0.0,-0.476314,0.675],[0.5,-0.4125,0.745337],[0.866025,-0.238157,0.9375],[1.0,0.0,1.2])),
                    #(false,true,#([-1.0,0.0,1.2],[-0.866025,-0.1375,0.745337],[-0.5,-0.238157,0.4125],[0.0,-0.275,0.290673],[0.5,-0.238157,0.4125],[0.866025,-0.1375,0.745337],[1.0,0.0,1.2])),
                    #(false,true,#([-1.0,0.0,1.2],[-0.866025,0.0,0.675],[-0.5,0.0,0.290673],[0.0,0.0,0.15],[0.5,0.0,0.290673],[0.866025,0.0,0.675],[1.0,0.0,1.2])),
                    #(false,true,#([-1.0,0.0,1.2],[-0.866025,0.1375,0.745337],[-0.5,0.238157,0.4125],[0.0,0.275,0.290673],[0.5,0.238157,0.4125],[0.866025,0.1375,0.745337],[1.0,0.0,1.2])),
                    #(false,true,#([-1.0,0.0,1.2],[-0.866025,0.238157,0.9375],[-0.5,0.4125,0.745337],[0.0,0.476314,0.675],[0.5,0.4125,0.745337],[0.866025,0.238157,0.9375],[1.0,0.0,1.2]))
                ) "ivory_glow" "body" true 0.0
                f.cage "Lobe2" #(
                    #(true,true,#([0.363878,0.275,0.78],[0.363878,0.238157,0.95],[0.363878,0.1375,1.074449],[0.363878,0.0,1.12],[0.363878,-0.1375,1.074449],[0.363878,-0.238157,0.95],[0.363878,-0.275,0.78],[0.363878,-0.238157,0.61],[0.363878,-0.1375,0.485551],[0.363878,0.0,0.44],[0.363878,0.1375,0.485551],[0.363878,0.238157,0.61])),
                    #(true,true,#([0.675,0.476314,0.78],[0.675,0.4125,1.074449],[0.675,0.238157,1.29],[0.675,0.0,1.368897],[0.675,-0.238157,1.29],[0.675,-0.4125,1.074449],[0.675,-0.476314,0.78],[0.675,-0.4125,0.485551],[0.675,-0.238157,0.27],[0.675,0.0,0.191103],[0.675,0.238157,0.27],[0.675,0.4125,0.485551])),
                    #(true,true,#([1.1,0.55,0.78],[1.1,0.476314,1.12],[1.1,0.275,1.368897],[1.1,0.0,1.46],[1.1,-0.275,1.368897],[1.1,-0.476314,1.12],[1.1,-0.55,0.78],[1.1,-0.476314,0.44],[1.1,-0.275,0.191103],[1.1,0.0,0.1],[1.1,0.275,0.191103],[1.1,0.476314,0.44])),
                    #(true,true,#([1.525,0.476314,0.78],[1.525,0.4125,1.074449],[1.525,0.238157,1.29],[1.525,0.0,1.368897],[1.525,-0.238157,1.29],[1.525,-0.4125,1.074449],[1.525,-0.476314,0.78],[1.525,-0.4125,0.485551],[1.525,-0.238157,0.27],[1.525,0.0,0.191103],[1.525,0.238157,0.27],[1.525,0.4125,0.485551])),
                    #(true,true,#([1.836122,0.275,0.78],[1.836122,0.238157,0.95],[1.836122,0.1375,1.074449],[1.836122,0.0,1.12],[1.836122,-0.1375,1.074449],[1.836122,-0.238157,0.95],[1.836122,-0.275,0.78],[1.836122,-0.238157,0.61],[1.836122,-0.1375,0.485551],[1.836122,0.0,0.44],[1.836122,0.1375,0.485551],[1.836122,0.238157,0.61])),
                    #(false,true,#([0.25,0.0,0.78],[0.363878,0.275,0.78],[0.675,0.476314,0.78],[1.1,0.55,0.78],[1.525,0.476314,0.78],[1.836122,0.275,0.78],[1.95,0.0,0.78])),
                    #(false,true,#([0.25,0.0,0.78],[0.363878,0.238157,0.95],[0.675,0.4125,1.074449],[1.1,0.476314,1.12],[1.525,0.4125,1.074449],[1.836122,0.238157,0.95],[1.95,0.0,0.78])),
                    #(false,true,#([0.25,0.0,0.78],[0.363878,0.1375,1.074449],[0.675,0.238157,1.29],[1.1,0.275,1.368897],[1.525,0.238157,1.29],[1.836122,0.1375,1.074449],[1.95,0.0,0.78])),
                    #(false,true,#([0.25,0.0,0.78],[0.363878,0.0,1.12],[0.675,0.0,1.368897],[1.1,0.0,1.46],[1.525,0.0,1.368897],[1.836122,0.0,1.12],[1.95,0.0,0.78])),
                    #(false,true,#([0.25,0.0,0.78],[0.363878,-0.1375,1.074449],[0.675,-0.238157,1.29],[1.1,-0.275,1.368897],[1.525,-0.238157,1.29],[1.836122,-0.1375,1.074449],[1.95,0.0,0.78])),
                    #(false,true,#([0.25,0.0,0.78],[0.363878,-0.238157,0.95],[0.675,-0.4125,1.074449],[1.1,-0.476314,1.12],[1.525,-0.4125,1.074449],[1.836122,-0.238157,0.95],[1.95,0.0,0.78])),
                    #(false,true,#([0.25,0.0,0.78],[0.363878,-0.275,0.78],[0.675,-0.476314,0.78],[1.1,-0.55,0.78],[1.525,-0.476314,0.78],[1.836122,-0.275,0.78],[1.95,0.0,0.78])),
                    #(false,true,#([0.25,0.0,0.78],[0.363878,-0.238157,0.61],[0.675,-0.4125,0.485551],[1.1,-0.476314,0.44],[1.525,-0.4125,0.485551],[1.836122,-0.238157,0.61],[1.95,0.0,0.78])),
                    #(false,true,#([0.25,0.0,0.78],[0.363878,-0.1375,0.485551],[0.675,-0.238157,0.27],[1.1,-0.275,0.191103],[1.525,-0.238157,0.27],[1.836122,-0.1375,0.485551],[1.95,0.0,0.78])),
                    #(false,true,#([0.25,0.0,0.78],[0.363878,0.0,0.44],[0.675,0.0,0.191103],[1.1,0.0,0.1],[1.525,0.0,0.191103],[1.836122,0.0,0.44],[1.95,0.0,0.78])),
                    #(false,true,#([0.25,0.0,0.78],[0.363878,0.1375,0.485551],[0.675,0.238157,0.27],[1.1,0.275,0.191103],[1.525,0.238157,0.27],[1.836122,0.1375,0.485551],[1.95,0.0,0.78])),
                    #(false,true,#([0.25,0.0,0.78],[0.363878,0.238157,0.61],[0.675,0.4125,0.485551],[1.1,0.476314,0.44],[1.525,0.4125,0.485551],[1.836122,0.238157,0.61],[1.95,0.0,0.78]))
                ) "ivory_glow" "body" true 0.0
                f.finishModel()
                f.startModel "paradepinwheel" "Flying pinwheel" "prop" 1 0.14 [0.0,0.0,0.0] "" false
                f.cage "Stem" #(
                    #(true,false,#([-0.09,0.0,0.06],[-0.06364,-0.06364,0.06],[0.0,-0.09,0.06],[0.06364,-0.06364,0.06],[0.09,0.0,0.06],[0.06364,0.06364,0.06],[0.0,0.09,0.06],[-0.06364,0.06364,0.06])),
                    #(true,false,#([-0.09,0.0,1.23],[-0.06364,-0.06364,1.23],[0.0,-0.09,1.23],[0.06364,-0.06364,1.23],[0.09,0.0,1.23],[0.06364,0.06364,1.23],[0.0,0.09,1.23],[-0.06364,0.06364,1.23])),
                    #(true,false,#([-0.09,0.0,2.4],[-0.06364,-0.06364,2.4],[0.0,-0.09,2.4],[0.06364,-0.06364,2.4],[0.09,0.0,2.4],[0.06364,0.06364,2.4],[0.0,0.09,2.4],[-0.06364,0.06364,2.4])),
                    #(false,false,#([0.0,0.0,0.06],[-0.09,0.0,0.06],[-0.09,0.0,1.23],[-0.09,0.0,2.4],[0.0,0.0,2.4])),
                    #(false,false,#([0.0,0.0,0.06],[-0.06364,-0.06364,0.06],[-0.06364,-0.06364,1.23],[-0.06364,-0.06364,2.4],[0.0,0.0,2.4])),
                    #(false,false,#([0.0,0.0,0.06],[0.0,-0.09,0.06],[0.0,-0.09,1.23],[0.0,-0.09,2.4],[0.0,0.0,2.4])),
                    #(false,false,#([0.0,0.0,0.06],[0.06364,-0.06364,0.06],[0.06364,-0.06364,1.23],[0.06364,-0.06364,2.4],[0.0,0.0,2.4])),
                    #(false,false,#([0.0,0.0,0.06],[0.09,0.0,0.06],[0.09,0.0,1.23],[0.09,0.0,2.4],[0.0,0.0,2.4])),
                    #(false,false,#([0.0,0.0,0.06],[0.06364,0.06364,0.06],[0.06364,0.06364,1.23],[0.06364,0.06364,2.4],[0.0,0.0,2.4])),
                    #(false,false,#([0.0,0.0,0.06],[0.0,0.09,0.06],[0.0,0.09,1.23],[0.0,0.09,2.4],[0.0,0.0,2.4])),
                    #(false,false,#([0.0,0.0,0.06],[-0.06364,0.06364,0.06],[-0.06364,0.06364,1.23],[-0.06364,0.06364,2.4],[0.0,0.0,2.4]))
                ) "gold_glow" "body" true 0.0
                f.cage "Blade0" #(
                    #(false,true,#([0.0,0.0,2.386525],[0.0,0.0,2.393263],[0.0,0.0,2.4],[0.0,0.0,2.406737],[0.0,0.0,2.413475])),
                    #(false,true,#([0.253,-0.108362,2.149706],[0.253,-0.108362,2.274853],[0.253,-0.108362,2.4],[0.253,-0.108362,2.525147],[0.253,-0.108362,2.650294])),
                    #(false,true,#([0.575,-0.17,2.015],[0.575,-0.17,2.2075],[0.575,-0.17,2.4],[0.575,-0.17,2.5925],[0.575,-0.17,2.785])),
                    #(false,true,#([0.897,-0.108362,2.149706],[0.897,-0.108362,2.274853],[0.897,-0.108362,2.4],[0.897,-0.108362,2.525147],[0.897,-0.108362,2.650294])),
                    #(false,true,#([1.15,0.0,2.386525],[1.15,0.0,2.393263],[1.15,0.0,2.4],[1.15,0.0,2.406737],[1.15,0.0,2.413475])),
                    #(false,true,#([0.0,0.0,2.386525],[0.253,-0.108362,2.149706],[0.575,-0.17,2.015],[0.897,-0.108362,2.149706],[1.15,0.0,2.386525])),
                    #(false,true,#([0.0,0.0,2.393263],[0.253,-0.108362,2.274853],[0.575,-0.17,2.2075],[0.897,-0.108362,2.274853],[1.15,0.0,2.393263])),
                    #(false,true,#([0.0,0.0,2.4],[0.253,-0.108362,2.4],[0.575,-0.17,2.4],[0.897,-0.108362,2.4],[1.15,0.0,2.4])),
                    #(false,true,#([0.0,0.0,2.406737],[0.253,-0.108362,2.525147],[0.575,-0.17,2.5925],[0.897,-0.108362,2.525147],[1.15,0.0,2.406737])),
                    #(false,true,#([0.0,0.0,2.413475],[0.253,-0.108362,2.650294],[0.575,-0.17,2.785],[0.897,-0.108362,2.650294],[1.15,0.0,2.413475]))
                ) "cyan_glow" "body" false 0.17
                f.cage "Blade1" #(
                    #(false,true,#([0.013475,0.0,2.4],[0.006738,0.0,2.4],[0.0,0.0,2.4],[-0.006738,0.0,2.4],[-0.013475,0.0,2.4])),
                    #(false,true,#([0.250294,-0.108362,2.653],[0.125147,-0.108362,2.653],[0.0,-0.108362,2.653],[-0.125147,-0.108362,2.653],[-0.250294,-0.108362,2.653])),
                    #(false,true,#([0.385,-0.17,2.975],[0.1925,-0.17,2.975],[0.0,-0.17,2.975],[-0.1925,-0.17,2.975],[-0.385,-0.17,2.975])),
                    #(false,true,#([0.250294,-0.108362,3.297],[0.125147,-0.108362,3.297],[0.0,-0.108362,3.297],[-0.125147,-0.108362,3.297],[-0.250294,-0.108362,3.297])),
                    #(false,true,#([0.013475,0.0,3.55],[0.006738,0.0,3.55],[0.0,0.0,3.55],[-0.006737,0.0,3.55],[-0.013475,0.0,3.55])),
                    #(false,true,#([0.013475,0.0,2.4],[0.250294,-0.108362,2.653],[0.385,-0.17,2.975],[0.250294,-0.108362,3.297],[0.013475,0.0,3.55])),
                    #(false,true,#([0.006738,0.0,2.4],[0.125147,-0.108362,2.653],[0.1925,-0.17,2.975],[0.125147,-0.108362,3.297],[0.006738,0.0,3.55])),
                    #(false,true,#([0.0,0.0,2.4],[0.0,-0.108362,2.653],[0.0,-0.17,2.975],[0.0,-0.108362,3.297],[0.0,0.0,3.55])),
                    #(false,true,#([-0.006738,0.0,2.4],[-0.125147,-0.108362,2.653],[-0.1925,-0.17,2.975],[-0.125147,-0.108362,3.297],[-0.006737,0.0,3.55])),
                    #(false,true,#([-0.013475,0.0,2.4],[-0.250294,-0.108362,2.653],[-0.385,-0.17,2.975],[-0.250294,-0.108362,3.297],[-0.013475,0.0,3.55]))
                ) "pink_glow" "body" false 0.17
                f.cage "Blade2" #(
                    #(false,true,#([0.0,0.0,2.413475],[0.0,0.0,2.406737],[0.0,0.0,2.4],[0.0,0.0,2.393263],[0.0,0.0,2.386525])),
                    #(false,true,#([-0.253,-0.108362,2.650294],[-0.253,-0.108362,2.525147],[-0.253,-0.108362,2.4],[-0.253,-0.108362,2.274853],[-0.253,-0.108362,2.149706])),
                    #(false,true,#([-0.575,-0.17,2.785],[-0.575,-0.17,2.5925],[-0.575,-0.17,2.4],[-0.575,-0.17,2.2075],[-0.575,-0.17,2.015])),
                    #(false,true,#([-0.897,-0.108362,2.650294],[-0.897,-0.108362,2.525147],[-0.897,-0.108362,2.4],[-0.897,-0.108362,2.274853],[-0.897,-0.108362,2.149706])),
                    #(false,true,#([-1.15,0.0,2.413475],[-1.15,0.0,2.406737],[-1.15,0.0,2.4],[-1.15,0.0,2.393263],[-1.15,0.0,2.386525])),
                    #(false,true,#([0.0,0.0,2.413475],[-0.253,-0.108362,2.650294],[-0.575,-0.17,2.785],[-0.897,-0.108362,2.650294],[-1.15,0.0,2.413475])),
                    #(false,true,#([0.0,0.0,2.406737],[-0.253,-0.108362,2.525147],[-0.575,-0.17,2.5925],[-0.897,-0.108362,2.525147],[-1.15,0.0,2.406737])),
                    #(false,true,#([0.0,0.0,2.4],[-0.253,-0.108362,2.4],[-0.575,-0.17,2.4],[-0.897,-0.108362,2.4],[-1.15,0.0,2.4])),
                    #(false,true,#([0.0,0.0,2.393263],[-0.253,-0.108362,2.274853],[-0.575,-0.17,2.2075],[-0.897,-0.108362,2.274853],[-1.15,0.0,2.393263])),
                    #(false,true,#([0.0,0.0,2.386525],[-0.253,-0.108362,2.149706],[-0.575,-0.17,2.015],[-0.897,-0.108362,2.149706],[-1.15,0.0,2.386525]))
                ) "gold_glow" "body" false 0.17
                f.cage "Blade3" #(
                    #(false,true,#([-0.013475,0.0,2.4],[-0.006738,0.0,2.4],[0.0,0.0,2.4],[0.006738,0.0,2.4],[0.013475,0.0,2.4])),
                    #(false,true,#([-0.250294,-0.108362,2.147],[-0.125147,-0.108362,2.147],[0.0,-0.108362,2.147],[0.125147,-0.108362,2.147],[0.250294,-0.108362,2.147])),
                    #(false,true,#([-0.385,-0.17,1.825],[-0.1925,-0.17,1.825],[0.0,-0.17,1.825],[0.1925,-0.17,1.825],[0.385,-0.17,1.825])),
                    #(false,true,#([-0.250294,-0.108362,1.503],[-0.125147,-0.108362,1.503],[0.0,-0.108362,1.503],[0.125147,-0.108362,1.503],[0.250294,-0.108362,1.503])),
                    #(false,true,#([-0.013475,0.0,1.25],[-0.006738,0.0,1.25],[0.0,0.0,1.25],[0.006737,0.0,1.25],[0.013475,0.0,1.25])),
                    #(false,true,#([-0.013475,0.0,2.4],[-0.250294,-0.108362,2.147],[-0.385,-0.17,1.825],[-0.250294,-0.108362,1.503],[-0.013475,0.0,1.25])),
                    #(false,true,#([-0.006738,0.0,2.4],[-0.125147,-0.108362,2.147],[-0.1925,-0.17,1.825],[-0.125147,-0.108362,1.503],[-0.006738,0.0,1.25])),
                    #(false,true,#([0.0,0.0,2.4],[0.0,-0.108362,2.147],[0.0,-0.17,1.825],[0.0,-0.108362,1.503],[0.0,0.0,1.25])),
                    #(false,true,#([0.006738,0.0,2.4],[0.125147,-0.108362,2.147],[0.1925,-0.17,1.825],[0.125147,-0.108362,1.503],[0.006737,0.0,1.25])),
                    #(false,true,#([0.013475,0.0,2.4],[0.250294,-0.108362,2.147],[0.385,-0.17,1.825],[0.250294,-0.108362,1.503],[0.013475,0.0,1.25]))
                ) "green_glow" "body" false 0.17
                f.cage "Hub" #(
                    #(true,true,#([-0.164545,-0.06,2.4],[-0.164545,-0.072058,2.4475],[-0.164545,-0.105,2.482272],[-0.164545,-0.15,2.495],[-0.164545,-0.195,2.482272],[-0.164545,-0.227942,2.4475],[-0.164545,-0.24,2.4],[-0.164545,-0.227942,2.3525],[-0.164545,-0.195,2.317728],[-0.164545,-0.15,2.305],[-0.164545,-0.105,2.317728],[-0.164545,-0.072058,2.3525])),
                    #(true,true,#([-0.095,0.005885,2.4],[-0.095,-0.015,2.482272],[-0.095,-0.072058,2.5425],[-0.095,-0.15,2.564545],[-0.095,-0.227942,2.5425],[-0.095,-0.285,2.482272],[-0.095,-0.305885,2.4],[-0.095,-0.285,2.317728],[-0.095,-0.227942,2.2575],[-0.095,-0.15,2.235455],[-0.095,-0.072058,2.2575],[-0.095,-0.015,2.317728])),
                    #(true,true,#([0.0,0.03,2.4],[0.0,0.005885,2.495],[0.0,-0.06,2.564545],[0.0,-0.15,2.59],[0.0,-0.24,2.564545],[0.0,-0.305885,2.495],[0.0,-0.33,2.4],[0.0,-0.305885,2.305],[0.0,-0.24,2.235455],[0.0,-0.15,2.21],[0.0,-0.06,2.235455],[0.0,0.005885,2.305])),
                    #(true,true,#([0.095,0.005885,2.4],[0.095,-0.015,2.482272],[0.095,-0.072058,2.5425],[0.095,-0.15,2.564545],[0.095,-0.227942,2.5425],[0.095,-0.285,2.482272],[0.095,-0.305885,2.4],[0.095,-0.285,2.317728],[0.095,-0.227942,2.2575],[0.095,-0.15,2.235455],[0.095,-0.072058,2.2575],[0.095,-0.015,2.317728])),
                    #(true,true,#([0.164545,-0.06,2.4],[0.164545,-0.072058,2.4475],[0.164545,-0.105,2.482272],[0.164545,-0.15,2.495],[0.164545,-0.195,2.482272],[0.164545,-0.227942,2.4475],[0.164545,-0.24,2.4],[0.164545,-0.227942,2.3525],[0.164545,-0.195,2.317728],[0.164545,-0.15,2.305],[0.164545,-0.105,2.317728],[0.164545,-0.072058,2.3525])),
                    #(false,true,#([-0.19,-0.15,2.4],[-0.164545,-0.06,2.4],[-0.095,0.005885,2.4],[0.0,0.03,2.4],[0.095,0.005885,2.4],[0.164545,-0.06,2.4],[0.19,-0.15,2.4])),
                    #(false,true,#([-0.19,-0.15,2.4],[-0.164545,-0.072058,2.4475],[-0.095,-0.015,2.482272],[0.0,0.005885,2.495],[0.095,-0.015,2.482272],[0.164545,-0.072058,2.4475],[0.19,-0.15,2.4])),
                    #(false,true,#([-0.19,-0.15,2.4],[-0.164545,-0.105,2.482272],[-0.095,-0.072058,2.5425],[0.0,-0.06,2.564545],[0.095,-0.072058,2.5425],[0.164545,-0.105,2.482272],[0.19,-0.15,2.4])),
                    #(false,true,#([-0.19,-0.15,2.4],[-0.164545,-0.15,2.495],[-0.095,-0.15,2.564545],[0.0,-0.15,2.59],[0.095,-0.15,2.564545],[0.164545,-0.15,2.495],[0.19,-0.15,2.4])),
                    #(false,true,#([-0.19,-0.15,2.4],[-0.164545,-0.195,2.482272],[-0.095,-0.227942,2.5425],[0.0,-0.24,2.564545],[0.095,-0.227942,2.5425],[0.164545,-0.195,2.482272],[0.19,-0.15,2.4])),
                    #(false,true,#([-0.19,-0.15,2.4],[-0.164545,-0.227942,2.4475],[-0.095,-0.285,2.482272],[0.0,-0.305885,2.495],[0.095,-0.285,2.482272],[0.164545,-0.227942,2.4475],[0.19,-0.15,2.4])),
                    #(false,true,#([-0.19,-0.15,2.4],[-0.164545,-0.24,2.4],[-0.095,-0.305885,2.4],[0.0,-0.33,2.4],[0.095,-0.305885,2.4],[0.164545,-0.24,2.4],[0.19,-0.15,2.4])),
                    #(false,true,#([-0.19,-0.15,2.4],[-0.164545,-0.227942,2.3525],[-0.095,-0.285,2.317728],[0.0,-0.305885,2.305],[0.095,-0.285,2.317728],[0.164545,-0.227942,2.3525],[0.19,-0.15,2.4])),
                    #(false,true,#([-0.19,-0.15,2.4],[-0.164545,-0.195,2.317728],[-0.095,-0.227942,2.2575],[0.0,-0.24,2.235455],[0.095,-0.227942,2.2575],[0.164545,-0.195,2.317728],[0.19,-0.15,2.4])),
                    #(false,true,#([-0.19,-0.15,2.4],[-0.164545,-0.15,2.305],[-0.095,-0.15,2.235455],[0.0,-0.15,2.21],[0.095,-0.15,2.235455],[0.164545,-0.15,2.305],[0.19,-0.15,2.4])),
                    #(false,true,#([-0.19,-0.15,2.4],[-0.164545,-0.105,2.317728],[-0.095,-0.072058,2.2575],[0.0,-0.06,2.235455],[0.095,-0.072058,2.2575],[0.164545,-0.105,2.317728],[0.19,-0.15,2.4])),
                    #(false,true,#([-0.19,-0.15,2.4],[-0.164545,-0.072058,2.3525],[-0.095,-0.015,2.317728],[0.0,0.005885,2.305],[0.095,-0.015,2.317728],[0.164545,-0.072058,2.3525],[0.19,-0.15,2.4]))
                ) "ivory_glow" "body" true 0.0
                f.finishModel()
                f.startModel "parademoth" "Flying night-post moth" "prop" 1 0.16 [0.0,0.0,0.0] "" false
                f.cage "Body" #(
                    #(true,true,#([-0.190526,0.125,1.35],[-0.190526,0.108253,1.5575],[-0.190526,0.0625,1.709401],[-0.190526,0.0,1.765],[-0.190526,-0.0625,1.709401],[-0.190526,-0.108253,1.5575],[-0.190526,-0.125,1.35],[-0.190526,-0.108253,1.1425],[-0.190526,-0.0625,0.990599],[-0.190526,0.0,0.935],[-0.190526,0.0625,0.990599],[-0.190526,0.108253,1.1425])),
                    #(true,true,#([-0.11,0.216506,1.35],[-0.11,0.1875,1.709401],[-0.11,0.108253,1.9725],[-0.11,0.0,2.068801],[-0.11,-0.108253,1.9725],[-0.11,-0.1875,1.709401],[-0.11,-0.216506,1.35],[-0.11,-0.1875,0.990599],[-0.11,-0.108253,0.7275],[-0.11,0.0,0.631199],[-0.11,0.108253,0.7275],[-0.11,0.1875,0.990599])),
                    #(true,true,#([0.0,0.25,1.35],[0.0,0.216506,1.765],[0.0,0.125,2.068801],[0.0,0.0,2.18],[0.0,-0.125,2.068801],[0.0,-0.216506,1.765],[0.0,-0.25,1.35],[0.0,-0.216506,0.935],[0.0,-0.125,0.631199],[0.0,0.0,0.52],[0.0,0.125,0.631199],[0.0,0.216506,0.935])),
                    #(true,true,#([0.11,0.216506,1.35],[0.11,0.1875,1.709401],[0.11,0.108253,1.9725],[0.11,0.0,2.068801],[0.11,-0.108253,1.9725],[0.11,-0.1875,1.709401],[0.11,-0.216506,1.35],[0.11,-0.1875,0.990599],[0.11,-0.108253,0.7275],[0.11,0.0,0.631199],[0.11,0.108253,0.7275],[0.11,0.1875,0.990599])),
                    #(true,true,#([0.190526,0.125,1.35],[0.190526,0.108253,1.5575],[0.190526,0.0625,1.709401],[0.190526,0.0,1.765],[0.190526,-0.0625,1.709401],[0.190526,-0.108253,1.5575],[0.190526,-0.125,1.35],[0.190526,-0.108253,1.1425],[0.190526,-0.0625,0.990599],[0.190526,0.0,0.935],[0.190526,0.0625,0.990599],[0.190526,0.108253,1.1425])),
                    #(false,true,#([-0.22,0.0,1.35],[-0.190526,0.125,1.35],[-0.11,0.216506,1.35],[0.0,0.25,1.35],[0.11,0.216506,1.35],[0.190526,0.125,1.35],[0.22,0.0,1.35])),
                    #(false,true,#([-0.22,0.0,1.35],[-0.190526,0.108253,1.5575],[-0.11,0.1875,1.709401],[0.0,0.216506,1.765],[0.11,0.1875,1.709401],[0.190526,0.108253,1.5575],[0.22,0.0,1.35])),
                    #(false,true,#([-0.22,0.0,1.35],[-0.190526,0.0625,1.709401],[-0.11,0.108253,1.9725],[0.0,0.125,2.068801],[0.11,0.108253,1.9725],[0.190526,0.0625,1.709401],[0.22,0.0,1.35])),
                    #(false,true,#([-0.22,0.0,1.35],[-0.190526,0.0,1.765],[-0.11,0.0,2.068801],[0.0,0.0,2.18],[0.11,0.0,2.068801],[0.190526,0.0,1.765],[0.22,0.0,1.35])),
                    #(false,true,#([-0.22,0.0,1.35],[-0.190526,-0.0625,1.709401],[-0.11,-0.108253,1.9725],[0.0,-0.125,2.068801],[0.11,-0.108253,1.9725],[0.190526,-0.0625,1.709401],[0.22,0.0,1.35])),
                    #(false,true,#([-0.22,0.0,1.35],[-0.190526,-0.108253,1.5575],[-0.11,-0.1875,1.709401],[0.0,-0.216506,1.765],[0.11,-0.1875,1.709401],[0.190526,-0.108253,1.5575],[0.22,0.0,1.35])),
                    #(false,true,#([-0.22,0.0,1.35],[-0.190526,-0.125,1.35],[-0.11,-0.216506,1.35],[0.0,-0.25,1.35],[0.11,-0.216506,1.35],[0.190526,-0.125,1.35],[0.22,0.0,1.35])),
                    #(false,true,#([-0.22,0.0,1.35],[-0.190526,-0.108253,1.1425],[-0.11,-0.1875,0.990599],[0.0,-0.216506,0.935],[0.11,-0.1875,0.990599],[0.190526,-0.108253,1.1425],[0.22,0.0,1.35])),
                    #(false,true,#([-0.22,0.0,1.35],[-0.190526,-0.0625,0.990599],[-0.11,-0.108253,0.7275],[0.0,-0.125,0.631199],[0.11,-0.108253,0.7275],[0.190526,-0.0625,0.990599],[0.22,0.0,1.35])),
                    #(false,true,#([-0.22,0.0,1.35],[-0.190526,0.0,0.935],[-0.11,0.0,0.631199],[0.0,0.0,0.52],[0.11,0.0,0.631199],[0.190526,0.0,0.935],[0.22,0.0,1.35])),
                    #(false,true,#([-0.22,0.0,1.35],[-0.190526,0.0625,0.990599],[-0.11,0.108253,0.7275],[0.0,0.125,0.631199],[0.11,0.108253,0.7275],[0.190526,0.0625,0.990599],[0.22,0.0,1.35])),
                    #(false,true,#([-0.22,0.0,1.35],[-0.190526,0.108253,1.1425],[-0.11,0.1875,0.990599],[0.0,0.216506,0.935],[0.11,0.1875,0.990599],[0.190526,0.108253,1.1425],[0.22,0.0,1.35]))
                ) "gold_glow" "body" true 0.0
                f.cage "ForewingL" #(
                    #(false,true,#([-0.010835,0.0,1.503041],[-0.005418,0.0,1.51152],[0.0,0.0,1.52],[0.005418,0.0,1.52848],[0.010835,0.0,1.536959])),
                    #(false,true,#([-0.597258,0.089239,1.457987],[-0.496629,0.089239,1.615493],[-0.396,0.089239,1.773],[-0.295371,0.089239,1.930507],[-0.194742,0.089239,2.088013])),
                    #(false,true,#([-1.209574,0.14,1.61045],[-1.054787,0.14,1.852725],[-0.9,0.14,2.095],[-0.745213,0.14,2.337275],[-0.590426,0.14,2.57955])),
                    #(false,true,#([-1.605258,0.089239,2.101987],[-1.504629,0.089239,2.259493],[-1.404,0.089239,2.417],[-1.303371,0.089239,2.574507],[-1.202742,0.089239,2.732013])),
                    #(false,true,#([-1.810835,0.0,2.653041],[-1.805418,0.0,2.66152],[-1.8,0.0,2.67],[-1.794582,0.0,2.67848],[-1.789165,0.0,2.686959])),
                    #(false,true,#([-0.010835,0.0,1.503041],[-0.597258,0.089239,1.457987],[-1.209574,0.14,1.61045],[-1.605258,0.089239,2.101987],[-1.810835,0.0,2.653041])),
                    #(false,true,#([-0.005418,0.0,1.51152],[-0.496629,0.089239,1.615493],[-1.054787,0.14,1.852725],[-1.504629,0.089239,2.259493],[-1.805418,0.0,2.66152])),
                    #(false,true,#([0.0,0.0,1.52],[-0.396,0.089239,1.773],[-0.9,0.14,2.095],[-1.404,0.089239,2.417],[-1.8,0.0,2.67])),
                    #(false,true,#([0.005418,0.0,1.52848],[-0.295371,0.089239,1.930507],[-0.745213,0.14,2.337275],[-1.303371,0.089239,2.574507],[-1.794582,0.0,2.67848])),
                    #(false,true,#([0.010835,0.0,1.536959],[-0.194742,0.089239,2.088013],[-0.590426,0.14,2.57955],[-1.202742,0.089239,2.732013],[-1.789165,0.0,2.686959]))
                ) "ivory_glow" "body" false 0.17
                f.cage "HindwingL" #(
                    #(false,true,#([-0.009707,0.0,1.162403],[-0.004853,0.0,1.156202],[0.0,0.0,1.15],[0.004853,0.0,1.143798],[0.009707,0.0,1.137597])),
                    #(false,true,#([-0.433302,0.063742,1.182386],[-0.343151,0.063742,1.067193],[-0.253,0.063742,0.952],[-0.162849,0.063742,0.836807],[-0.072698,0.063742,0.721614])),
                    #(false,true,#([-0.852339,0.1,1.054377],[-0.713669,0.1,0.877189],[-0.575,0.1,0.7],[-0.436331,0.1,0.522811],[-0.297661,0.1,0.345623])),
                    #(false,true,#([-1.077302,0.063742,0.678386],[-0.987151,0.063742,0.563193],[-0.897,0.063742,0.448],[-0.806849,0.063742,0.332807],[-0.716698,0.063742,0.217614])),
                    #(false,true,#([-1.159707,0.0,0.262403],[-1.154853,0.0,0.256202],[-1.15,0.0,0.25],[-1.145147,0.0,0.243798],[-1.140293,0.0,0.237597])),
                    #(false,true,#([-0.009707,0.0,1.162403],[-0.433302,0.063742,1.182386],[-0.852339,0.1,1.054377],[-1.077302,0.063742,0.678386],[-1.159707,0.0,0.262403])),
                    #(false,true,#([-0.004853,0.0,1.156202],[-0.343151,0.063742,1.067193],[-0.713669,0.1,0.877189],[-0.987151,0.063742,0.563193],[-1.154853,0.0,0.256202])),
                    #(false,true,#([0.0,0.0,1.15],[-0.253,0.063742,0.952],[-0.575,0.1,0.7],[-0.897,0.063742,0.448],[-1.15,0.0,0.25])),
                    #(false,true,#([0.004853,0.0,1.143798],[-0.162849,0.063742,0.836807],[-0.436331,0.1,0.522811],[-0.806849,0.063742,0.332807],[-1.145147,0.0,0.243798])),
                    #(false,true,#([0.009707,0.0,1.137597],[-0.072698,0.063742,0.721614],[-0.297661,0.1,0.345623],[-0.716698,0.063742,0.217614],[-1.140293,0.0,0.237597]))
                ) "pink_glow" "body" false 0.17
                f.tube "AntennaL" #([-0.1,0.0,2.08],[-0.28,0.0,2.42],[-0.4,0.0,2.57]) 0.045 4 false true "gold_glow" "body"
                f.cage "ForewingR" #(
                    #(false,true,#([0.010835,0.0,1.503041],[0.005418,0.0,1.51152],[0.0,0.0,1.52],[-0.005418,0.0,1.52848],[-0.010835,0.0,1.536959])),
                    #(false,true,#([0.597258,0.089239,1.457987],[0.496629,0.089239,1.615493],[0.396,0.089239,1.773],[0.295371,0.089239,1.930507],[0.194742,0.089239,2.088013])),
                    #(false,true,#([1.209574,0.14,1.61045],[1.054787,0.14,1.852725],[0.9,0.14,2.095],[0.745213,0.14,2.337275],[0.590426,0.14,2.57955])),
                    #(false,true,#([1.605258,0.089239,2.101987],[1.504629,0.089239,2.259493],[1.404,0.089239,2.417],[1.303371,0.089239,2.574507],[1.202742,0.089239,2.732013])),
                    #(false,true,#([1.810835,0.0,2.653041],[1.805418,0.0,2.66152],[1.8,0.0,2.67],[1.794582,0.0,2.67848],[1.789165,0.0,2.686959])),
                    #(false,true,#([0.010835,0.0,1.503041],[0.597258,0.089239,1.457987],[1.209574,0.14,1.61045],[1.605258,0.089239,2.101987],[1.810835,0.0,2.653041])),
                    #(false,true,#([0.005418,0.0,1.51152],[0.496629,0.089239,1.615493],[1.054787,0.14,1.852725],[1.504629,0.089239,2.259493],[1.805418,0.0,2.66152])),
                    #(false,true,#([0.0,0.0,1.52],[0.396,0.089239,1.773],[0.9,0.14,2.095],[1.404,0.089239,2.417],[1.8,0.0,2.67])),
                    #(false,true,#([-0.005418,0.0,1.52848],[0.295371,0.089239,1.930507],[0.745213,0.14,2.337275],[1.303371,0.089239,2.574507],[1.794582,0.0,2.67848])),
                    #(false,true,#([-0.010835,0.0,1.536959],[0.194742,0.089239,2.088013],[0.590426,0.14,2.57955],[1.202742,0.089239,2.732013],[1.789165,0.0,2.686959]))
                ) "ivory_glow" "body" false 0.17
                f.cage "HindwingR" #(
                    #(false,true,#([-0.009707,0.0,1.137597],[-0.004853,0.0,1.143798],[0.0,0.0,1.15],[0.004853,0.0,1.156202],[0.009707,0.0,1.162403])),
                    #(false,true,#([0.072698,0.063742,0.721614],[0.162849,0.063742,0.836807],[0.253,0.063742,0.952],[0.343151,0.063742,1.067193],[0.433302,0.063742,1.182386])),
                    #(false,true,#([0.297661,0.1,0.345623],[0.436331,0.1,0.522811],[0.575,0.1,0.7],[0.713669,0.1,0.877189],[0.852339,0.1,1.054377])),
                    #(false,true,#([0.716698,0.063742,0.217614],[0.806849,0.063742,0.332807],[0.897,0.063742,0.448],[0.987151,0.063742,0.563193],[1.077302,0.063742,0.678386])),
                    #(false,true,#([1.140293,0.0,0.237597],[1.145147,0.0,0.243798],[1.15,0.0,0.25],[1.154853,0.0,0.256202],[1.159707,0.0,0.262403])),
                    #(false,true,#([-0.009707,0.0,1.137597],[0.072698,0.063742,0.721614],[0.297661,0.1,0.345623],[0.716698,0.063742,0.217614],[1.140293,0.0,0.237597])),
                    #(false,true,#([-0.004853,0.0,1.143798],[0.162849,0.063742,0.836807],[0.436331,0.1,0.522811],[0.806849,0.063742,0.332807],[1.145147,0.0,0.243798])),
                    #(false,true,#([0.0,0.0,1.15],[0.253,0.063742,0.952],[0.575,0.1,0.7],[0.897,0.063742,0.448],[1.15,0.0,0.25])),
                    #(false,true,#([0.004853,0.0,1.156202],[0.343151,0.063742,1.067193],[0.713669,0.1,0.877189],[0.987151,0.063742,0.563193],[1.154853,0.0,0.256202])),
                    #(false,true,#([0.009707,0.0,1.162403],[0.433302,0.063742,1.182386],[0.852339,0.1,1.054377],[1.077302,0.063742,0.678386],[1.159707,0.0,0.262403]))
                ) "pink_glow" "body" false 0.17
                f.tube "AntennaR" #([0.1,0.0,2.08],[0.28,0.0,2.42],[0.4,0.0,2.57]) 0.045 4 false true "gold_glow" "body"
                f.finishModel()
                f.validateAll()
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
