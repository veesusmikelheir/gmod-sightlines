
sightlines = sightlines or {} 
package.seeall(sightlines)
setfenv(1,sightlines)


require("dualtable")


AddCSLuaFile("sightlines/viewdata.lua")

if CLIENT then
    include("sightlines/viewdata.lua")
    return
end



local coroutine = coroutine
local table = table
local ipairs = ipairs


trackers = trackers or {}
local trackers = trackers


include("sightlines/viewdata.lua")

include("sightlines/vision.lua")


include("sightlines/tracker.lua")

include("sightlines/playermanager.lua")





local broadPlayerRoutine = coroutine.wrap(CheckBroadPlayersRoutine)
local resume = coroutine.resume
hook.Add("Think","sightlines",function()
    broadPlayerRoutine()
    
    for _,t in ipairs(trackers) do
        t.Routine()
    end


    
end)


