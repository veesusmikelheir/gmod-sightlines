AddCSLuaFile()
module("dualtable",package.seeall)

local extraPairs = {}
local function makeThing(seq,value,key)
    local epicTable = table.remove(extraPairs) 
    if not epicTable then return {seq = seq, value = value, key = key} end
    epicTable.seq = seq
    epicTable.value = value
    epicTable.key = key
    return epicTable
end

local insert = table.insert
local remove = table.remove

-- little construct for making tables faster 
local dualTable = {
    __index = function(t,k)
        local lookup = t.lookupTable[k]
        return lookup and lookup.value
        
    end,
    __newindex = function(t,k,v)
        local lookupTable = t.lookupTable
        local lookup = lookupTable[k]
        local seqTable = t.seqTable
        if(lookup) then 
            if(v==nil) then
                
                for i=lookup.seq,#seqTable do
               
                    seqTable[i].seq = seqTable[i].seq-1
                end
                local seq = lookup.seq+1
                insert(extraPairs,lookup)
                remove(seqTable,seq)
                lookupTable[k] = nil
                local giterator = t.globalIterator
                if(giterator <= seq) then t.globalIterator = giterator-1 end
            else
                lookup.value = v

            end
            return
        end
        if(v == nil) then return end
        local y = makeThing(#seqTable+1, v, k)
        lookupTable[k] = y
        insert(seqTable,y)

    end
}
local function dualiterate(a,k)
    k = k+1
    local val = a.seqTable[k]
    if val then
        return k,val.key,val.value
    end
end

local function deletetrackingiterate(a,k)
    local iterator = a.globalIterator 
    iterator = iterator + 1
    local val = a.seqTable[iterator]
    a.globalIterator = iterator
    if val then
        return k,val.key,val.value
    end
end

function idualpairs(a)
    return dualiterate,a,0
end

function ideletetrackingpairs(a)
    a.globalIterator=0
    return deletetrackingiterate,a,0

end
function MakeDualTable()
    local newTable = {
        lookupTable = {},
        seqTable = {},
        globalIterator = 0
    }
    setmetatable(newTable,dualTable)
    return newTable
end