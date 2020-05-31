----------------------------------------------------------------------------------------------------
--                                          TACTICAL GRID                                         --
--                         Widget display tactical grid and border fade.                          --
----------------------------------------------------------------------------------------------------
function widget:GetInfo()
        return {
                name      = "TacticalGrid",
                desc      = "Tactical Grid Tool",
                author    = "a1983",
                date      = "21 12 2012",
                license   = "xxx",
                layer     = math.huge,
                --handler   = true, -- used widget handlers
                enabled   = true  -- loaded by default
        }
end
----------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------
--                          Shortcut to used global functions to speedup                          --
----------------------------------------------------------------------------------------------------
local glSmoothing = gl.Smoothing

local glPushMatrix      = gl.PushMatrix
local glPopMatrix       = gl.PopMatrix
local glTranslate       = gl.Translate

local glCreateList      = gl.CreateList
local glCallList        = gl.CallList
local glDeleteList      = gl.DeleteList

local GLLINES = GL.LINES
local GLLINE_STRIP = GL.LINE_STRIP

local glLineWidth = gl.LineWidth

local glBeginEnd = gl.BeginEnd
local glVertex = gl.Vertex

local glColor   = gl.Color
local glRect    = gl.Rect
local glTexRect = gl.TexRect
local glTexture = gl.Texture
local glText    = gl.Text

local SpGetGroundHeight = Spring.GetGroundHeight

local SpWorldToScreenCoords             = Spring.WorldToScreenCoords

local SpGetCameraPosition               = Spring.GetCameraPosition

local math_ceil = math.ceil
local math_abs  = math.abs
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
--                                        Local constants                                         --
----------------------------------------------------------------------------------------------------
local textureBegin = ":n:luaui/images/TacticalGrid/"

local texTopLeft                = textureBegin .. "top_left.png"
local texTopRight               = textureBegin .. "top_right.png"
local texBottomRight    = textureBegin .. "bottom_right.png"
local texBottomLeft             = textureBegin .. "bottom_left.png"

local texTop    =  textureBegin .. "top.png"
local texBottom =  textureBegin .. "bottom.png"
local texLeft   =  textureBegin .. "left.png"
local texRight  =  textureBegin .. "right.png"

local borderSize = 150

local smallStep = 20
local bigStep = smallStep * 4
local thin = 1
local fat = 1.5

local alpha = 0.1
local maxAlpha = alpha

local minViewHeight = 5000
local maxViewHeight = 9000
local deltaH = 1 / ( maxViewHeight - minViewHeight )

----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
--                                        Local variables                                         --
----------------------------------------------------------------------------------------------------
local screenW, screenH
local drawing2DList
local needRedraw
local drawing3DList
local needRedraw3D
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
--                                        Local functions                                         --
----------------------------------------------------------------------------------------------------
local DrawAll
local Draw3D
local Draw2DGrid
local Draw3DGrid
local DrawFlatGrid
local DrawFrame

----------------------------------------------------------------------------------------------------
--                                         WIDGET CALLLINS                                        --
----------------------------------------------------------------------------------------------------

local mapW, mapH = Game.mapSizeX , Game.mapSizeZ

----------------------------------------------------------------------------------------------------
function widget:Initialize()
        screenW, screenH = widgetHandler:GetViewSizes()
        needRedraw = true
       
        --Spring.Echo( Game.mapSizeX , Game.mapSizeZ )
end

function widget:Shotdown()
        if( drawing2DList ) then
                glDeleteList( drawing2DList )
        end

        if( drawing3DList ) then
                glDeleteList( drawing3DList )
        end
end

----------------------------------------------------------------------------------------------------
local oldY = 0.0
function widget:DrawScreen()

        local _, y, _ = SpGetCameraPosition()
       
        if( y > maxViewHeight ) then
                y = maxViewHeight
        end
       
        if( math_abs( oldY - y ) > 10 ) then
                oldY = y
                alpha = ( y - minViewHeight )
                if( alpha > 0 ) then
                        alpha = maxAlpha * alpha * deltaH
                else
                        alpha = 0
                end
               
                needRedraw = true
                needRedraw3D = true
        end
       
        if( needRedraw ) then
                if( drawing2DList ) then
                        glDeleteList( drawing2DList )
                end
               
                drawing2DList = ( alpha > 0 ) and glCreateList( DrawAll ) or nil
                needRedraw = false
        end
       
        if( drawing2DList ) then
                glPushMatrix()
                --glCallList( drawing2DList )
                glPopMatrix()
        end
end

function widget:DrawWorld()
        if( needRedraw3D ) then
                if( drawing3DList ) then
                        glDeleteList( drawing3DList )
                end
               
                needRedraw3D = false
                drawing3DList = ( alpha > 0 ) and glCreateList( Draw3D ) or nil
        end
       
        if( drawing3DList ) then
                glPushMatrix()
                glCallList( drawing3DList )
                glPopMatrix()
                glColor( 0, 1, 1, 1 )
        end
end

----------------------------------------------------------------------------------------------------
function widget:ViewResize( w, h )
        screenW, screenH = w, h
end

----------------------------------------------------------------------------------------------------
DrawAll = function()
        glLineWidth( 1 )
        --glSmoothing( false, false, false )
        --glBeginEnd( GLLINES, Draw2DGrid )
        DrawFrame()
end

Draw3D = function()
        glLineWidth( 1 )
        --glSmoothing( false, false, false )
        glBeginEnd( GLLINES, Draw3DGrid )
end

----------------------------------------------------------------------------------------------------
Draw2DGrid = function()
        local doubleAlpha = alpha * 2
        local bigSmallStep = bigStep - smallStep
       
        for x = 0, screenW, bigStep do
                glColor( 0.0, 1.0, 1.0, doubleAlpha )
                glVertex( x, 0 )
                glVertex( x, screenH )
               
                glColor( 0.0, 1.0, 1.0, alpha )
                for smallX = x + smallStep, x + bigSmallStep, smallStep do
                        glVertex( smallX, 0 )
                        glVertex( smallX, screenH )
                end
        end
       
        for y = 0, screenH, bigStep do
                glColor( 0.0, 1.0, 1.0, doubleAlpha )
                glVertex( 0, y )
                glVertex( screenW, y )
               
                glColor( 0.0, 1.0, 1.0, alpha )
                for smallY = y + smallStep, y + bigSmallStep, smallStep do
                        glVertex( 0, smallY )
                        glVertex( screenW, smallY )
                end
        end
end

----------------------------------------------------------------------------------------------------
Draw3DGrid = function()
        local doubleAlpha = alpha * 2
        local smallStep = 128
        local bigStep = smallStep * 4
        local bigSmallStep = bigStep - smallStep
       
        local y

        glColor( 0.0, 1.0, 1.0, doubleAlpha )
        for x = 0, mapW - bigStep, bigStep do
                for smallZ = 0, mapH, smallStep do
                        y = SpGetGroundHeight( x, smallZ )
                        glVertex( x, y, smallZ )
                        y = SpGetGroundHeight( x, smallZ + smallStep )
                        glVertex( x, y, smallZ + smallStep )
                end
        end
       
        for z = 0, mapH - bigStep, bigStep do
                for smallX = 0, mapW, smallStep do
                        y = SpGetGroundHeight( smallX, z )
                        glVertex( smallX, y, z )
                        y = SpGetGroundHeight( smallX + smallStep, z )
                        glVertex( smallX + smallStep, y, z )
                end
        end
       
        glColor( 0.0, 1.0, 1.0, alpha )
        for x = 0, mapW - bigStep, bigStep do
                for z = 0, mapH - bigStep, bigStep do
                        for smallX = x, x + bigSmallStep, smallStep do
                               
                                for smallZ = z, z + bigSmallStep, smallStep do
                                        y = SpGetGroundHeight( smallX, smallZ )
                                        glVertex( smallX, y, smallZ )
                                        y = SpGetGroundHeight( smallX, smallZ + smallStep )
                                        glVertex( smallX, y, smallZ + smallStep )
                                       
                                        y = SpGetGroundHeight( smallX, smallZ )
                                        glVertex( smallX, y, smallZ )
                                        y = SpGetGroundHeight( smallX + smallStep, smallZ )
                                        glVertex( smallX + smallStep, y, smallZ )
                                end
                               
                        end
                end
        end
       
end

----------------------------------------------------------------------------------------------------
DrawFrame = function()
        local frameAlpha = alpha * 10
        if( frameAlpha > 1 ) then
                frameAlpha = 1.0
        end
               
        glColor( 0, 1, 1, frameAlpha )
        glTexture( texBottomLeft )
        glTexRect( 0, 0, borderSize, borderSize )
       
        glTexture( texBottom )
        glTexRect( borderSize, 0, screenW - borderSize, borderSize )
       
        glTexture( texBottomRight )
        glTexRect( screenW - borderSize, 0, screenW, borderSize )
       
        glTexture( texRight )
        glTexRect( screenW - borderSize, borderSize, screenW, screenH - borderSize )
       
        glTexture( texTopRight )
        glTexRect( screenW - borderSize, screenH - borderSize, screenW, screenH )
       
        glTexture( texTop )
        glTexRect( borderSize, screenH - borderSize, screenW - borderSize, screenH )
       
        glTexture( texTopLeft )
        glTexRect( 0, screenH - borderSize, borderSize, screenH )
       
        glTexture( texLeft )
        glTexRect( 0, borderSize, borderSize, screenH - borderSize )
       
        glTexture( false )
end

----------------------------------------------------------------------------------------------------
DrawFlatGrid = function()
        local doubleAlpha = alpha * 2
        local smallStep = 128
        local bigStep = smallStep * 4
        local bigSmallStep = bigStep - smallStep

        local y
       
        for x = 0, mapW - bigStep, bigStep do
                glColor( 0.0, 1.0, 1.0, doubleAlpha )
               
                glVertex( x, 20, 0 )
                glVertex( x, 20, mapH )
               
                glColor( 0.0, 1.0, 1.0, alpha )
                for smallX = x + smallStep, x + bigSmallStep, smallStep do
                        glVertex( smallX, 20, 0 )
                        glVertex( smallX, 20, mapH )
                end
        end
       
        for y = 0, mapH - bigStep, bigStep do
                glColor( 0.0, 1.0, 1.0, doubleAlpha )
                glVertex( 0,    20, y )
                glVertex( mapW, 20, y )
               
                glColor( 0.0, 1.0, 1.0, alpha )
                for smallY = y + smallStep, y + bigSmallStep, smallStep do
                        glVertex( 0,    20, smallY )
                        glVertex( mapW, 20, smallY )
                end
        end
       
        glColor( 0.0, 1.0, 1.0, doubleAlpha )
        glVertex( mapW, 20, 0 )
        glVertex( mapW, 20, mapH )
       
        glVertex( 0,    20, mapH )
        glVertex( mapW, 20, mapH )
end

----------------------------------------------------------------------------------------------------
