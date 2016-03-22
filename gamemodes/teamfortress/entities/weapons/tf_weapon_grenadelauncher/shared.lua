if SERVER then
	AddCSLuaFile( "shared.lua" )
	
end

if CLIENT then

SWEP.PrintName			= "Grenade Launcher"
SWEP.Slot				= 0

function SWEP:InitializeCModel()
	self:CallBaseFunction("InitializeCModel")
	
	if IsValid(self.CModel) then
		self.CModel:SetBodygroup(1, 1)
	end
end

function SWEP:InitializeWModel2()
	self:CallBaseFunction("InitializeWModel2")
	
	--[[if IsValid(self.WModel2) then
		self.WModel2:SetBodygroup(1, 1)
	end]]
end

end

SWEP.Base				= "tf_weapon_gun_base"

SWEP.ViewModel			= "models/weapons/v_models/v_grenadelauncher_demo.mdl"
SWEP.WorldModel			= "models/weapons/w_models/w_grenadelauncher.mdl"
SWEP.Crosshair = "tf_crosshair3"

--[[ --Viewmodel Settings Override (left-over from testing; works well)
SWEP.ViewModelFOV	= 70
SWEP.ViewModelFlip	= false
]]

SWEP.MuzzleEffect = "muzzle_grenadelauncher"
PrecacheParticleSystem("muzzle_grenadelauncher")

SWEP.ShootSound = Sound("Weapon_GrenadeLauncher.Single")
SWEP.ShootCritSound = Sound("Weapon_GrenadeLauncher.SingleCrit")
SWEP.ReloadSound = Sound("Weapon_GrenadeLauncher.WorldReload")

SWEP.Primary.ClipSize		= 4
SWEP.Primary.DefaultClip	= SWEP.Primary.ClipSize
SWEP.Primary.Ammo			= TF_PRIMARY
SWEP.Primary.Delay          = 0.6

SWEP.IsRapidFire = false
SWEP.ReloadSingle = true

SWEP.HoldType = "SECONDARY"

SWEP.ProjectileShootOffset = Vector(0, 7, -6)
SWEP.Force = 1100
SWEP.AddPitch = -4

SWEP.PunchView = Angle( -2, 0, 0 )

SWEP.Properties = {}

SWEP.SpinSound = true

function SWEP:OnEquipAttribute(a, owner)
	if a.attribute_class == "mult_clipsize" then
		self.SpinSound = false
	end
end

function SWEP:InspectAnimCheck()
self.VM_INSPECT_START = ACT_PRIMARY_VM_INSPECT_START
self.VM_INSPECT_IDLE = ACT_PRIMARY_VM_INSPECT_IDLE
self.VM_INSPECT_END = ACT_PRIMARY_VM_INSPECT_END

	if ( self:GetOwner():KeyPressed( IN_SPEED ) and inspecting == false and GetConVar("tf_caninspect"):GetBool() ) then
		timer.Create("StartInspection", self:SequenceDuration(), 1,function()
			if self:GetOwner():KeyDown( IN_SPEED ) then 
				inspecting_idle = true
			else
				if CLIENT then
					timer.Create("PlaySpin", 1.07, 1, function() surface.PlaySound( "player/taunt_clip_spin_long.wav" ) end)
				end
				inspecting_idle = false
			end
		end )
	end

	if ( self:GetOwner():KeyReleased( IN_SPEED ) and inspecting_idle == true and GetConVar("tf_caninspect"):GetBool() ) then
		if CLIENT then
			timer.Create("PlaySpin", 1.07, 1, function() surface.PlaySound( "player/taunt_clip_spin_long.wav" ) end)
		end
	end
	
	--[[	if ( self:GetOwner():GetNWString("inspect") == "inspecting_released" and inspecting_post == false and GetConVar("tf_caninspect"):GetBool() and self.SpinSound == true and !(self.Owner:GetMoveType()==MOVETYPE_NOCLIP) ) then
		if CLIENT then
			timer.Create("PlaySpin", 2.06, 1, function() surface.PlaySound( "player/taunt_clip_spin_long.wav" ) end)
		end
	end]]
end

function SWEP:StopTimers()
	self:CallBaseFunction("StopTimers")
	timer.Remove("PlaySpin")
end

function SWEP:ShootProjectile()
	if SERVER then
		local grenade = ents.Create("tf_projectile_pipe")
		grenade:SetPos(self:ProjectileShootPos())
		grenade:SetAngles(self.Owner:EyeAngles())
		
		if self:Critical() then
			grenade.critical = true
		end
		
		for k,v in pairs(self.Properties) do
			grenade[k] = v
		end
		
		grenade:SetOwner(self.Owner)
		
		self:InitProjectileAttributes(grenade)
		
		grenade.NameOverride = self:GetItemData().item_iconname
		grenade:Spawn()
		
		if self.VM_RELOAD == ACT_PRIMARY_VM_RELOAD_2 then
			grenade.DetonateMode = 2
			else
			grenade.DetonateMode = 0
		end
		
		local vel = self.Owner:GetAimVector():Angle()
		vel.p = vel.p + self.AddPitch
		vel = vel:Forward() * self.Force * (grenade.Mass or 10)
		
		if self.Owner.TempAttributes.ProjectileModelModifier == 1 then
			grenade:GetPhysicsObject():AddAngleVelocity(Vector(math.random(-800,800),math.random(-800,800),math.random(-800,800)))
		else
			grenade:GetPhysicsObject():AddAngleVelocity(Vector(math.random(-2000,2000),math.random(-2000,2000),math.random(-2000,2000)))
		end
		grenade:GetPhysicsObject():ApplyForceCenter(vel)
	end
	
	
	self:StopTimers()
	self:ShootEffects()
end