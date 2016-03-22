if SERVER then
	AddCSLuaFile( "shared.lua" )
end

if CLIENT then
	SWEP.PrintName			= "Gun"
end

SWEP.Base				= "tf_weapon_base"

SWEP.ViewModel			= "models/weapons/v_models/v_scattergun_scout.mdl"
SWEP.WorldModel			= "models/weapons/w_models/w_scattergun.mdl"

SWEP.MuzzleEffect = "muzzle_flash"
SWEP.MuzzleOffset = Vector(0,0,0)

SWEP.ShootSound = Sound("")
SWEP.ShootCritSound = Sound("")
SWEP.ReloadSound = Sound("")

SWEP.TracerEffect = "bullet_tracer01"
PrecacheParticleSystem("muzzle_flash")

SWEP.BulletsPerShot = 1
SWEP.BulletSpread = 0.2

SWEP.PunchView = Angle( 0, 0, 0 )

SWEP.HoldType = "PRIMARY"

SWEP.AutoReloadTime = 0

idle_timer = 1
end_timer = 1
post_timer = 5.30

inspecting = false
inspecting_post = false

CreateClientConVar("cl_autoreload", "1")

function SWEP:ShootPos()
	--local vm = self.Owner:GetViewModel()
	--return vm:GetAttachment(vm:LookupAttachment("muzzle"))
	
	return self:GetAttachment(self:LookupAttachment("muzzle")).Pos
end

function SWEP:PrimaryAttack()
	self:StopTimers()

	if not self:CallBaseFunction("PrimaryAttack") then return false end
	
	auto_reload = GetConVar("cl_autoreload"):GetBool()
	
	self:SendWeaponAnim(self.VM_PRIMARYATTACK)
	self.Owner:DoAttackEvent()
	
	self.NextIdle = CurTime() + self:SequenceDuration()
	
	if auto_reload then
		timer.Create("AutoReload", (self:SequenceDuration() + self.AutoReloadTime), 1, function() self:Reload() end)
	end
	
	self:ShootProjectile(self.BulletsPerShot, self.BulletSpread)
	self:TakePrimaryAmmo(1)
	
	if self:Clip1() <= 0 then
		self:Reload()
	end
	
	self:RollCritical() -- Roll and check for criticals first
	
	self.Owner:ViewPunch( self.PunchView )
	
	self.NextReloadStart = nil
	self.NextReload = nil
	self.Reloading = false
	
	return true
end

--local force_bullets_lagcomp = CreateConVar("force_bullets_lagcomp", 0, {FCVAR_REPLICATED})

function SWEP:ShootProjectile(num_bullets, aimcone)
	self:StopTimers()
	--local b = force_bullets_lagcomp:GetBool()
	
	--if b then
		self.Owner:LagCompensation(true)
	--end
	
	self:FireTFBullets{
		Num = num_bullets,
		Src = self.Owner:GetShootPos(),
		--Src = self:ShootPos(),
		Dir = self.Owner:GetAimVector(),
		Spread = Vector(aimcone, aimcone, 0),
		Attacker = self.Owner,
		
		Team = GAMEMODE:EntityTeam(self.Owner),
		Damage = self.BaseDamage,
		RampUp = self.MaxDamageRampUp,
		Falloff = self.MaxDamageFalloff,
		Critical = self:Critical(),
		CritMultiplier = self.CritDamageMultiplier,
		DamageModifier = self.DamageModifier,
		DamageRandomize = self.DamageRandomize,
		
		Tracer = 1,
		TracerName = self.TracerEffect,
		Force = 1,
	}
	
	--if b then
		self.Owner:LagCompensation(false)
	--end
	
	self:ShootEffects()
end

function SWEP:ShootEffects()
	if self:Critical() then
		self:EmitSound(self.ShootCritSound)
	else
		self:EmitSound(self.ShootSound, self.ShootSoundLevel, self.ShootSoundPitch)
	end
	
	if SERVER then
		if self.MuzzleEffect and self.MuzzleEffect~="" then
			umsg.Start("DoMuzzleFlash")
				umsg.Entity(self)
			umsg.End()
		end
	end
end