if CLIENT then return end


sightlines = sightlines or {} 
package.seeall(sightlines)
setfenv(1,sightlines)


local math = math
local acos = math.acos
local atan = math.atan

local CalculatePlayerPositions = CalculatePlayerPositions
local CalculatePlayerMatrices = CalculatePlayerMatrices

local TraceLine = util.TraceLine

local tolerance = math.rad(1)
local checkVectorBounds = checkVectorBounds
local realTransform = realTransform

function CheckBroadVision(tracker, player)
    tracker.ViewShape:UpdateCoordinates()
    return player:IsValid() 
    and player:Alive() 
    and player:TestPVS(tracker.Entity) 
    and (tracker.BroadSqrDistance == 0 
    or tracker.ViewShape.WorldOrigin:DistToSqr(player:GetPos()) < tracker.BroadSqrDistance)


end


local function TracePoint(player, endpos)
    local viewdata = player.viewdata
    local tracerOutput = viewdata.tracer
    local tracerInput = viewdata.tracerInput

    tracerInput.start = viewdata.aimPos
    tracerInput.endpos = endpos
    tracerInput.filter = player
    tracerInput.output = tracerOutput

    TraceLine(tracerInput)

    return tracerOutput.Hit
end


local bounds = Vector()
function TestPointWithProjection(player, viewshape, point, donttrace)

    realTransform(player.viewdata.localProjection, point,bounds)

    if not checkVectorBounds(bounds,1) then return false end
    if(not donttrace) then 
        TracePoint(player,point)
        local entity = player.viewdata.tracer.Entity

        return (entity == viewshape.Entity or (not entity:IsWorld() and not entity:IsValid()))
    else return true end
    return false
    
end

local TestPoint = TestPointWithProjection

local delta = Vector()
function SpecificVisionChecks(viewshape,player)
    --is broad checks still valid
    viewshape:UpdateCoordinates()
    CalculatePlayerPositions(player) 
    local viewdata = player.viewdata
    local aimPos = viewdata.aimPos
    local aimDir = viewdata.aimDir
    local trackerPos = viewshape.WorldBoundingCenter
    delta:SetUnpacked(trackerPos.x-aimPos.x,trackerPos.y-aimPos.y,trackerPos.z-aimPos.z)
    local deltaLength = delta:Length()
    delta:Div(deltaLength)
    -- helps avoiding edge cases at close distances
    local bigRadian = 2*atan(0.5 * viewshape.BoundingCrossSection / (deltaLength-viewshape.BoundingCrossSection))

    local angle = acos(delta:Dot(aimDir))


    --is main pos within horizontal field of view + tolerance + bounding box diagonal
    --this eliminates a good percentage of the fov when you're looking away from the tracker
    -- tolerance helps avoid edge cases at far distances (yeah idk)
    if(angle>(viewdata.realHorizontalFov+bigRadian+tolerance)) then return false end


    local smallRadian = 2*atan(0.5 * viewshape.BoundingSmallestSize / deltaLength)

    local tracerOutput = viewdata.tracer

    TracePoint(player,trackerPos)
    
    --if main pos is within vertical field of view and we have a clear trace to it, return early, we most likely see it
    --this eliminates a good percentage of inner field of view
    local hit = tracerOutput.Hit and tracerOutput.Entity==viewshape.Entity
    if(hit and angle<=(viewdata.realVerticalFov+smallRadian)) then return true end

    CalculatePlayerMatrices(player)

    --use projection matrix, and trace from earlier, to see if entity pos is on screen, if so, return

    if(hit and TestPoint(player,viewshape,trackerPos,true)) then return true end
    --print("thing failed")
    viewshape:UpdateShapes()
    
    --check bounding box against our epic little frustum
    for _,t in ipairs(viewshape.WorldBoundingCorners) do
        local testp = TestPoint(player,viewshape,t)
        if(testp) then return true end
    end

    return false
end

local plymeta = FindMetaTable("Player")