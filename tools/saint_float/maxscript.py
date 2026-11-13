"""Emit one textured mesh or one editable SplineShape, for 3ds Max 2018.
Native Max execution is a separate manual check; no .max file is fabricated.
"""
import json
from pathlib import Path
import numpy as np


def point(p):return '['+','.join(format(float(x),'.8g') for x in p)+']'
def array(values):return '#('+',\n'.join(values)+')'


def write(model,data,path):
    # Deduplicate geometry positions while retaining independent UV indices.
    lookup={}; vertices=[];faces=[];uvs=[]
    for tri in np.asarray(data['records']).reshape(-1,3,8):
        face=[]
        for row in tri:
            game=row[:3];p=(game[0],-game[2],game[1]);key=tuple(round(float(v),7) for v in p)
            if key not in lookup:lookup[key]=len(vertices)+1;vertices.append(p)
            face.append(lookup[key]);uvs.append((row[6],row[7],0))
        faces.append(face)
    curves=[]
    for part in model['parts']:
        for c in part['curves']:
            curves.append('#('+('true' if c['closed'] else 'false')+','+array(point(p) for p in c['points'])+')')
    header=r'''/* MOSAIC saint: one object per build, 3ds Max 2018.
   Mesh mode: exact atlas UVs and final cage-evaluated geometry.
   Cage mode: one SplineShape containing all rings/rails, with live Surface.
   Cage mode is a neutral geometry editing source; its surface is not atlas-unwrapped.
   Build either version; existing scene nodes are never deleted or reset.
*/
global MOSAIC_SaintAtlasDir
if MOSAIC_SaintAtlasDir == undefined do MOSAIC_SaintAtlasDir = ""
global MOSAIC_SaintDialog
try(destroyDialog MOSAIC_SaintDialog)catch()
(
local scriptFolder = getFilenamePath (getSourceFileName())
'''
    text=header+'local saintVerts = '+array(point(p) for p in vertices)+'\n'
    text+='local saintFaces = '+array(point(p) for p in faces)+'\n'
    text+='local saintUV = '+array(point(p) for p in uvs)+'\n'
    text+='local saintCurves = '+array(curves)+'\n'
    text+=r'''
fn saintMaterial =
(
    local folder = if MOSAIC_SaintAtlasDir != "" then MOSAIC_SaintAtlasDir else (pathConfig.appendPath scriptFolder "..\\..\\unittextures")
    local diffusePath = pathConfig.appendPath folder "house_asian_diffuse.dds"
    local packedPath = pathConfig.appendPath folder "house_asian_selfilu_reflection.png"
    if not doesFileExist diffusePath or not doesFileExist packedPath do
        throw "Set MOSAIC_SaintAtlasDir to the MOSAIC unittextures folder, then run again."
    local diffuseMap = bitmapTexture filename:diffusePath
    diffuseMap.alphaSource = 2
    local packed = bitmapTexture filename:packedPath
    packed.bitmap = openBitmap packedPath gamma:1.0
    local emissionMap = RGB_Tint map1:packed red:(color 255 255 255) green:(color 0 0 0) blue:(color 0 0 0)
    local mat = standardMaterial name:"MOSAIC Saint Asian Atlas"
    mat.diffuseMap = diffuseMap
    mat.diffuseMapEnable = true
    mat.useSelfIllumColor = false
    mat.selfIllumAmount = 100
    mat.selfIllumMap = emissionMap
    mat.selfIllumMapEnable = true
    mat.selfIllumMapAmount = 100
    mat.specularLevel = 0
    showTextureMap mat diffuseMap true
    mat
)
fn buildSaintMesh =
(
    local mat = saintMaterial()
    local obj = undefined
    undo "MOSAIC Build Saint Mesh" on
    (
        try
        (
            obj = mesh name:(uniqueName "paradesaintmother") vertices:saintVerts faces:saintFaces
            obj.transform = matrix3 1
            setNumTVerts obj saintUV.count
            buildTVFaces obj false
            for i=1 to saintUV.count do setTVert obj i saintUV[i]
            for i=1 to saintFaces.count do
            (
                local v=(i-1)*3+1
                setTVFace obj i [v,v+1,v+2]
                setFaceSmoothGroup obj i 0
            )
            obj.material = mat
            setUserProp obj "MOSAIC_source" "Spline cage: tools/saint_float/source.json"
            setUserProp obj "MOSAIC_tex1" "house_asian_diffuse.dds"
            setUserProp obj "MOSAIC_tex2" "house_asian_selfilu_reflection.png"
            update obj
            if obj.numFaces != saintFaces.count do throw "Unexpected final face count."
            select obj
        )
        catch
        (
            if isValidNode obj do delete obj
            throw (getCurrentException())
        )
    )
    obj
)
fn buildSaintCage =
(
    local obj = undefined
    undo "MOSAIC Build Saint Cage" on
    (
        try
        (
            obj = splineShape name:(uniqueName "paradesaintmother_cage")
            obj.transform = matrix3 1
            for c in saintCurves do
            (
                addNewSpline obj
                local si=numSplines obj
                for p in c[2] do addKnot obj si #corner #line p
                if c[1] do close obj si
            )
            updateShape obj
            obj.steps = 0
            obj.optimize = false
            obj.adaptive = false
            local surf = Surface threshold:0.00001 steps:0
            surf.name = "Live surface from connected saint cage"
            addModifier obj surf
            obj.material = standardMaterial name:"Saint cage geometry review" diffuse:(color 160 168 175) twoSided:true
            setUserProp obj "MOSAIC_editing" "Edit base spline knots. Exact atlas mapping belongs to the mesh build."
            setUserProp obj "MOSAIC_source" "tools/saint_float/source.json"
            select obj
        )
        catch
        (
            if isValidNode obj do delete obj
            throw (getCurrentException())
        )
    )
    obj
)
rollout MOSAIC_SaintDialog "MOSAIC Saint / one object" width:340
(
    label title "Mother and child - spline-cage model" align:#center
    button finalMesh "Build one textured mesh" width:300 height:34
    button editCage "Build one editable spline cage" width:300 height:34
    label note "The cage is a neutral editing source." align:#center
    label note2 "The mesh has the exact illuminated atlas UVs." align:#center
    on finalMesh pressed do try(buildSaintMesh())catch(messageBox (getCurrentException()) title:"Saint mesh")
    on editCage pressed do try(buildSaintCage())catch(messageBox (getCurrentException()) title:"Saint cage")
)
createDialog MOSAIC_SaintDialog
)
'''
    path.write_text(text,encoding='utf-8-sig')
    return {'unique_vertices':len(vertices),'triangles':len(faces),'splines':len(curves)}
