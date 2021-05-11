AddCSLuaFile()
DEFINE_BASECLASS("base_anim")

ENT.Spawnable = true
ENT.AdminOnly = false


function ENT:Initialize()
 
	self:SetModel( "models/hunter/blocks/cube05x05x05.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )      -- Make us work with physics,
	self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
	self:SetSolid( SOLID_VPHYSICS )         -- Toolbox
 
    local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
    if(CLIENT) then return end
    print("TEST")
    sightlines.AddTracker(sightlines.MakeTracker(nil,self))
    self:CallOnRemove("remove_tracker",function()
        sightlines.RemoveTracker(self.Tracker)
    end)

end

function ENT:StartLooking(ply)
    print("looking ")
end

function ENT:StopLooking(ply)
    print("Not looking")

end
