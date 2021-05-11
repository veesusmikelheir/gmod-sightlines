if CLIENT then return end


sightlines = sightlines or {} 
package.seeall(sightlines)
setfenv(1,sightlines)

require("dualtable")

PlayersWeNeedToUpdate = dualtable.MakeDualTable()
PlayersWeDontNeedToUpdate = dualtable.MakeDualTable()


function AddPlayerToTracker(tracker,player)
    local activeTrackers = PlayersWeNeedToUpdate[player] or {}
    activeTrackers[tracker] = true
    PlayersWeNeedToUpdate[player] = activeTrackers
    PlayersWeDontNeedToUpdate[player] = nil
    tracker.PlayersToCheck[player] = true
end

function RemovePlayerFromTracker(tracker,player)
    local activeTrackers = PlayersWeNeedToUpdate[player]
    if not activeTrackers then return end
    activeTrackers[tracker] = nil
    tracker.PlayersToCheck[player] = nil

    if next(activeTrackers) == nil then
        PlayersWeNeedToUpdate[player] = nil
        PlayersWeDontNeedToUpdate[player] = activeTrackers
    else
        
        PlayersWeNeedToUpdate[player] = activeTrackers
    end
end

function RemovePlayerFromAllTrackers(player)
    local activeTrackers = PlayersWeNeedToUpdate[player]
    if not activeTrackers then return end
    for v in pairs(activeTrackers) do
        v.PlayersToCheck[player] = nil
    end
    PlayersWeNeedToUpdate[player] = nil
    PlayersWeDontNeedToUpdate[player] = activeTrackers
end

function AddTracker(tracker)
    table.insert(trackers,tracker)

end



function OnPlayerDisconnect(ply)
    RemovePlayerFromAllTrackers(ply)
    PlayersWeDontNeedToUpdate[ply] = nil
end
hook.Add("PlayerDisconnected","sightlines",OnPlayerDisconnect)

function OnPlayerConnect(playerEntity)
    PlayersWeDontNeedToUpdate[playerEntity] = true

end
function RemoveTracker(tracker)
    table.RemoveByValue(trackers, tracker)
    tracker.Entity.Tracker = nil
    for _,t in dualtable.idualpairs(tracker.PlayersToCheck) do
        OnPlayerConnect(t)
    end
end
hook.Add("PlayerInitialSpawn","sightlines",OnPlayerConnect)

for i,v in ipairs(player.GetAll()) do
    PlayersWeDontNeedToUpdate[v] = true
end
