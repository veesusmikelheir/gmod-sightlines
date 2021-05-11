AddCSLuaFile()
SWEP.PrintName = "SCP-096"

SWEP.Author = "Veesus"

SWEP.Slot = 0
SWEP.SlotPos = 0

SWEP.Spawnable = true
SWEP.DrawAmmo = false

SWEP.WorldModel = ""

SWEP.DrawCrosshair = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

SWEP.Config = {}

local SWEP = SWEP

if SERVER then
    util.AddNetworkString("096_deploy")
end



local function CreateBackedConvar(name, defaultValue)
    SWEP.Config[name] = defaultValue
    local convarName = "scp096_"..name
    CreateConVar(convarName, defaultValue)
    cvars.AddChangeCallback(convarName, function(_, _, new)
        SWEP.Config[name] = tonumber(new)
    end)
end

CreateBackedConvar("rage_start_delay",2)
CreateBackedConvar("rage_duration",15)
CreateBackedConvar("rage_speed_multiplier",3)
CreateBackedConvar("rage_start_speed_multiplier",.2)
CreateBackedConvar("idle_speed_multiplier",.2)
CreateBackedConvar("rage_cooldown_time",2)
CreateBackedConvar("rage_cooldown_speed_multiplier",.1)

function SWEP:Initialize()
	self:SetHoldType( "normal" )
	
	self.ActivityTranslate[ ACT_MP_STAND_IDLE ]					= ACT_HL2MP_IDLE_ZOMBIE
	self.ActivityTranslate[ ACT_MP_WALK ]						= ACT_HL2MP_WALK_ZOMBIE_01
	self.ActivityTranslate[ ACT_MP_RUN ]						= ACT_HL2MP_WALK_ZOMBIE_01
	self.ActivityTranslate[ ACT_MP_CROUCH_IDLE ]				= ACT_HL2MP_IDLE_CROUCH_ZOMBIE
	self.ActivityTranslate[ ACT_MP_CROUCHWALK ]					= ACT_HL2MP_WALK_CROUCH_ZOMBIE_01
	self.ActivityTranslate[ ACT_MP_ATTACK_STAND_PRIMARYFIRE ]	= ACT_GMOD_GESTURE_RANGE_ZOMBIE
	self.ActivityTranslate[ ACT_MP_ATTACK_CROUCH_PRIMARYFIRE ]	= ACT_GMOD_GESTURE_RANGE_ZOMBIE
	self.ActivityTranslate[ ACT_MP_JUMP ]						= ACT_ZOMBIE_LEAPING
	self.ActivityTranslate[ ACT_RANGE_ATTACK1 ]					= ACT_GMOD_GESTURE_RANGE_ZOMBIE

end


function SWEP:Deploy()

    if not IsValid(self:GetOwner()) or not self:GetOwner():IsPlayer() then return end

    self.DefaultSpeeds = self:GenerateSpeeds(self:GetOwner(),self.DefaultSpeeds)
    self:ResetToIdle()
    self.Deployed = true
    return true
end

function SWEP:Holster()
    self:ResetToNormal()
    self.Deployed = nil
    return true
end

function SWEP:GenerateSpeeds(owner, speeds)
    local Speeds = speeds or {}
    Speeds.CrouchWalk = owner:GetCrouchedWalkSpeed()
    Speeds.Max = owner:GetMaxSpeed()
    Speeds.Walk = owner:GetWalkSpeed()
    Speeds.Run = owner:GetRunSpeed()
    Speeds.SlowWalk = owner:GetSlowWalkSpeed()
    Speeds.Jump = owner:GetJumpPower()
    return Speeds
    
end

function SWEP:ApplySpeeds(speeds,multiplier)
    multiplier = multiplier or 1
    local owner = self:GetOwner()
    owner:SetCrouchedWalkSpeed(speeds.CrouchWalk*multiplier)
    owner:SetMaxSpeed(speeds.Max*multiplier)
    owner:SetWalkSpeed(speeds.Walk*multiplier)
    owner:SetRunSpeed(speeds.Run*multiplier)
    owner:SetSlowWalkSpeed(speeds.SlowWalk*multiplier)
    owner:SetJumpPower(speeds.Jump*multiplier)

end
function SWEP:ApplySpeedMultiplier(multiplier)
    self:ApplySpeeds(self.DefaultSpeeds,multiplier)
end

function SWEP:ResetToIdle()
    self:ExecuteState(0)



end

function SWEP:ResetToNormal()
    self:ApplySpeedMultiplier(1)

end



function SWEP:SetState(state)
    if state == 0 then --idle
        self:ApplySpeedMultiplier(SWEP.Config.idle_speed_multiplier)
        self:GetOwner():AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
        self.ActivityTranslate[ ACT_MP_WALK ] = ACT_HL2MP_WALK_ZOMBIE_01
        self.ActivityTranslate[ ACT_MP_RUN ] = ACT_HL2MP_WALK_ZOMBIE_01
        return 0
    elseif state == 1 then --wind up for rage
        self.ActivityTranslate[ ACT_MP_WALK ] = ACT_HL2MP_RUN_ZOMBIE
        self.ActivityTranslate[ ACT_MP_RUN ] = ACT_HL2MP_RUN_ZOMBIE
        self:GetOwner():AnimRestartGesture(GESTURE_SLOT_CUSTOM, ACT_GMOD_GESTURE_TAUNT_ZOMBIE,true)
        self:SetPlaybackRate(SWEP.Config.rage_start_speed_multiplier)
        self:ApplySpeedMultiplier(SWEP.Config.rage_start_speed_multiplier)
        return SWEP.Config.rage_start_delay
    elseif state == 2 then --in rage
        self:ApplySpeedMultiplier(SWEP.Config.rage_speed_multiplier)
        self:SetPlaybackRate(1)
        return SWEP.Config.rage_duration
    elseif state == 3 then --rage cooldown
        self:ApplySpeedMultiplier(SWEP.Config.rage_cooldown_speed_multiplier)
        return SWEP.Config.rage_cooldown_time
    end

end

SWEP.MaxStates = 3


function SWEP:Think()
    
    if not self.Deployed then self:Deploy() end
    self:CycleStates()

end

 
function SWEP:PrimaryAttack()

    if not self.Deployed then self:Deploy() end
    self:StartCycle()
    self:SetNextPrimaryFire(CurTime()+1)

end


function SWEP:CycleStates()
    if(self:GetCurrentState() == 0) then return end
    if((CurTime()<self:GetNextStateTime())) then return end
    local nextState = self:GetCurrentState()+1
    if(nextState>self.MaxStates) then nextState = 0 end
    self:ExecuteState(nextState)
end

function SWEP:ExecuteState(state)
    local nextTime = self:SetState(state)
    self:SetCurrentState(state)
    self:SetNextStateTime(CurTime()+nextTime)
end

function SWEP:StartCycle()
    self:ExecuteState(1)
end



function SWEP:SetupDataTables()
    self:NetworkVar("Float",0,"NextStateTime")
    self:NetworkVar("Int",0,"CurrentState")
end
