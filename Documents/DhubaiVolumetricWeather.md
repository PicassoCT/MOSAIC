# Atmospheric clouds moved to Dhubai

The disabled `luaui/widgets_mosaic/gfx_volumetric_clouds.lua` and its
`shaders/fogShader.vert` / `shaders/fogShader.frag` now live in the Dhubai map:
`PicassoCT/MOSAIC_LastDayOfDubai`, branch `map/dhubai-volumetric-weather`.

The map enables its own **Dhubai volumetric weather** widget, with occasional
morning fog, smog and sandstorms. MOSAIC already loads `LuaUI/Widgets_Map/` from
the map archive. The map contains the noise texture needed by its renderer.

`luarules/gadgets/gfx_cloud_volumes.lua` remains the independent unit-effect
renderer for pump smoke, launch clouds, explosions and aerosol volumes. Shared
game noise textures also remain for other shaders.
