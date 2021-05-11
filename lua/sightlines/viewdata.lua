


if SERVER then 
AddCSLuaFile()
util.AddNetworkString("sightlines_get_viewdata")


sightlines = sightlines or {} 
package.seeall(sightlines)
setfenv(1,sightlines)



local math = math
local abs = math.abs

local Vector = Vector()


function realTransform(matrix, vector,buffer)
    local m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44 = matrix:Unpack()
    local x,y,z = vector:Unpack()
    local w = 1
    local newX = x*m11+y*m12+z*m13+w*m14
    local newY = x*m21+y*m22+z*m23+w*m24
    local newZ = x*m31+y*m32+z*m33+w*m34
    local newW = x*m41+y*m42+z*m43+w*m44

    if(not buffer) then buffer = Vector() end
    return buffer:SetUnpacked(newX/newW,newY/newW,newZ/newW)
end

local function GetProjectionMatrix(fov, realAspectRatio, matrix)
    local f = 1.0/math.tan(fov/2.0)*(4.0/3.0)
    realAspectRatio=realAspectRatio
    local zFar = 32768.0
    local zNear=0.1
    matrix:SetField(1,2,-f/realAspectRatio)
    matrix:SetField(2,3,f)
    matrix:SetField(3,1, -(zFar+zNear)/(zNear-zFar))
    matrix:SetField(3,4,(2*zFar*zNear)/(zNear-zFar))
    matrix:SetField(4,1,1)
    return matrix
end



function checkVectorBounds(vector,maxValue)
    return abs(vector.x)<maxValue and abs(vector.y)<maxValue and abs(vector.z)<maxValue
end




function CalculatePlayerPositions(ply)
    local viewdata = ply.viewdata
    if(viewdata.positionUpdateTicks >= engine.TickCount()) then return end
    viewdata.positionUpdateTicks = engine.TickCount()
    local aimShoot = ply:GetAimVector()
    viewdata.aimDir = aimShoot
    local aimPos = ply:EyePos()
    viewdata.aimPos = aimPos
end

function CalculatePlayerMatrices(ply)
    local viewdata = ply.viewdata
    if(viewdata.matrixUpdateTicks >= engine.TickCount()) then return end
    viewdata.matrixUpdateTicks = engine.TickCount()

    local matrix = viewdata.localMatrix

    matrix:Identity()
    matrix:Rotate(viewdata.aimDir:Angle())
    matrix:SetTranslation(viewdata.aimPos)
    matrix:Invert()

    viewdata.localProjection = viewdata.projectionMatrix * matrix
end


MakeViewData = function(ply, aspectratio)
    local data = ply.viewdata or {}
    ply.viewdata = data
    data.tracer = {}
    data.tracerInput = {}
    data.fov = math.rad(ply:GetFOV())
    data.halfFov = data.fov/2.0
    data.realVerticalFov = math.atan(math.tan(data.halfFov)*3/4)
    data.realHorizontalFov = math.atan(math.tan(data.realVerticalFov)*aspectratio)
    data.aspectRatio = aspectratio
    data.projectionMatrix = data.projectionMatrix or Matrix({{0,0,0,0},{0,0,0,0},{0,0,0,0},{0,0,0,0}})
    GetProjectionMatrix(data.fov,aspectratio,data.projectionMatrix)
    data.localMatrix = Matrix()
    data.trackerStates = {}
    data.positionUpdateTicks = 0
    data.matrixUpdateTicks = 0
    CalculatePlayerPositions(ply)
    CalculatePlayerMatrices(ply)

end





net.Receive("sightlines_get_viewdata", function(num, ply)
        
    local aspect = net.ReadFloat()
    MakeViewData(ply,aspect)
end)

end


if(CLIENT) then
local function SendViewData()
    print("Sending")
    net.Start("sightlines_get_viewdata")
    net.WriteFloat(ScrW()/ScrH())
    net.SendToServer()
end

hook.Add("InitPostEntity","sightlines_send_view_data",function(ply)
    SendViewData()
end)

hook.Add("OnScreenSizeChanged","sightlines_screen_changed",function()

    SendViewData()
end)

end