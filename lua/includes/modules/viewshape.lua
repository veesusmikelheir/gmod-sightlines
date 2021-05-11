AddCSLuaFile()
module("viewshape",package.seeall)

ViewShape = {}
ViewShape.__index = ViewShape

function ViewShape:CalculateWorldBoundings()
    for i,v in ipairs(self.BoundingCorners) do
        self.WorldBoundingCorners[i] = self:LocalToWorld(v)
    end
    self.WorldBoundingMax = self:LocalToWorld(self.BoundingMax)
    self.WorldBoundingMin = self:LocalToWorld(self.BoundingMin)
end

local rotateVec = Vector()
function ViewShape:LocalToWorld(pos)
    rotateVec:Set(pos)
    rotateVec:Rotate(self.WorldAngles)
    return self.WorldOrigin + rotateVec

end

function ViewShape:UpdateWorldPositions()

end

function ViewShape:UpdateCoordinates()
    local ticks = engine.TickCount()
    if(ticks <= self.LastPositionUpdateTime) then return end
    self.LastPositionUpdateTime = ticks
    self:UpdateWorldPositions()
    self.WorldBoundingCenter = self:LocalToWorld(self.BoundingCenter)


end

function ViewShape:UpdateShapes()
    local ticks = engine.TickCount()
    if(ticks <= self.LastCornersUpdateTime) then return end
    self.LastCornersUpdateTime = ticks 

    self:CalculateWorldBoundings()


end

function ViewShape:UpdateEverything()
    self:UpdateCoordinates()
    self:UpdateShapes()

end

function ViewShape:new(worldPos, boundingMax,boundingMin,angles)


    local viewshape = {
        WorldBoundingCorners = {},
        WorldOrigin = worldPos,
        WorldAngles = angles or Angle(),
        LastPositionUpdateTime = 0,
        LastCornersUpdateTime = 0
    }
    
    setmetatable(viewshape,self)

    viewshape:SetBounds(boundingMin,boundingMax)
    viewshape:UpdateEverything()


    return viewshape

end

function ViewShape:SetBounds(boundingMin,boundingMax)
    local min = boundingMin
    local max = boundingMax
    

    local center = (max + min)/2


    local boundingDelta = max - center
    local BoundingSmallestSize = boundingDelta.x
    if(BoundingSmallestSize > boundingDelta.y) then BoundingSmallestSize = boundingDelta.y end
    if(BoundingSmallestSize > boundingDelta.z) then BoundingSmallestSize = boundingDelta.z end


    self.BoundingCorners = {Vector(min.x,min.y,min.z),Vector(max.x,min.y,min.z),Vector(max.x,max.y,min.z),Vector(min.x,max.y,min.z),Vector(min.x,min.y,max.z),Vector(max.x,min.y,max.z),Vector(max.x,max.y,max.z),Vector(min.x,max.y,max.z)}

    self.BoundingCrossSection = boundingDelta:Length()
    self.BoundingSmallestSize = BoundingSmallestSize
    self.BoundingMax = max
    self.BoundingCenter = center
    self.BoundingMin = min
end

EntityViewShape = {}
EntityViewShape.__index = EntityViewShape
setmetatable(EntityViewShape,ViewShape)

function EntityViewShape:new(entity)

    local newShape = ViewShape:new(entity:GetPos(),entity:OBBMaxs(),entity:OBBMins(),entity:GetAngles())
    newShape.Entity = entity
    setmetatable(newShape, EntityViewShape)
    return newShape
end

function EntityViewShape:LocalToWorld(pos)
    return self.Entity:LocalToWorld(pos)

end

function EntityViewShape:UpdateWorldPositions()
    self.WorldAngles = self.Entity:GetAngles()
    self.WorldOrigin = self.Entity:GetPos()

end
