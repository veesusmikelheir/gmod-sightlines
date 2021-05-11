if CLIENT then return end


sightlines = sightlines or {} 
package.seeall(sightlines)
setfenv(1,sightlines)

require("dualtable")
require("viewshape")

local DefaultSettings = {
    ViewDistance = 3000, --if players are over this distance, ignore them entirely (0 for infinite)
    SpecificChecksPerTick = 32 -- used to stagger the broader checks that then adds people to the more specific checks
}

function MakeTrackerSettings(settings)
    local newSettings = settings or {}
    setmetatable(newSettings, {__index = DefaultSettings})
    return newSettings
end

local Tracker = {

}
Tracker.__index = Tracker



function ProcessLookingState(tracker, player, state)
    local epic = player.viewdata.trackerStates
    local previousTrackerState = epic[tracker] or false
    epic[tracker] = state

    local entity = tracker.Entity
    if(previousTrackerState ~= state) then
        if(state) then 
            entity:StartLooking(player)
            entity.SightCounter = entity.SightCounter + 1
            hook.Run("StartLooking",tracker,player)

        else 
            entity:StopLooking(player) 
            entity.SightCounter = entity.SightCounter - 1

            hook.Run("StopLooking",tracker,player)

        end
    end
end

local trackers = trackers
local coroutine = coroutine
local yield = coroutine.yield
local ipairs = ipairs
local ideletetrackingpairs = dualtable.ideletetrackingpairs
local function CheckPlayerSpecificCoroutine(tracker)
    local SpecificChecks = tracker.Settings.SpecificChecksPerTick
    local PlayersToCheck = tracker.PlayersToCheck
    local seqTable = PlayersToCheck.seqTable
    return function()
    
        local limit = SpecificChecks+1
        local skippedTick = true
        while true do
            skippedTick = false
            if(#seqTable > 0) then
            for i,k in ideletetrackingpairs(PlayersToCheck) do
                if not CheckBroadVision(tracker,k) then 
                    RemovePlayerFromTracker(tracker,k)
                else
                    ProcessLookingState(tracker,k,SpecificVisionChecks(tracker.ViewShape,k))
                end
                -- make sure we only process up to the limit each tick
                limit = limit - 1
                if(limit==1) then
                    yield()
                    limit = SpecificChecks+1
                    skippedTick = true
                end
            end
            end
            if not skippedTick then yield() end
        end
    end
    
end

local BroadChecks = 3



function CheckBroadPlayersRoutine()
    local limit = BroadChecks+1
    local skippedTick = true
    while true do
        skippedTick = false
        if(#trackers > 0) then 
        for i,k in ideletetrackingpairs(PlayersWeDontNeedToUpdate) do
            -- check if the broad checks are valid
            for _,t in ipairs(trackers) do

                if(k.viewdata and CheckBroadVision(t,k)) then

                    AddPlayerToTracker(t,k)
                end

            end
            -- make sure we only process up to the limit each tick
            limit = limit - 1
            if(limit==1) then
                yield()
                limit = BroadChecks+1
                skippedTick = true
            end
        end
        end
        if not skippedTick then yield() end
    end
end

function MakeTracker(settings,entity,localBoundingExtents,localBoundingCenter)
    settings = MakeTrackerSettings(settings)

    localBoundingExtents = localBoundingExtents or entity:OBBMaxs()
    localBoundingCenter = localBoundingCenter or entity:OBBCenter()


    local min = localBoundingCenter-(localBoundingExtents-localBoundingCenter)
    local max = localBoundingExtents


    local boundingDelta = localBoundingExtents-localBoundingCenter
    local BoundingSmallestSize = boundingDelta.x
    if(BoundingSmallestSize > boundingDelta.y) then BoundingSmallestSize = boundingDelta.y end
    if(BoundingSmallestSize > boundingDelta.z) then BoundingSmallestSize = boundingDelta.z end

    local shape = viewshape.EntityViewShape:new(entity)

    shape:SetBounds(min,max)

    local tracker = {
        Settings = settings,
        Entity = entity,
        ViewShape = shape,
        PlayersToCheck = dualtable.MakeDualTable(),
        BroadSqrDistance = settings.ViewDistance*settings.ViewDistance,
        Routine = 0
    }
    tracker.Routine = coroutine.wrap(CheckPlayerSpecificCoroutine(tracker) )
    entity.Tracker = tracker
    entity.SightCounter = 0
    setmetatable(tracker,Tracker)
    return tracker
end

