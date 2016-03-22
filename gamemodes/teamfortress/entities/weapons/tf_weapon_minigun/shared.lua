if SERVER then
	AddCSLuaFile( "shared.lua" )
	
function SWEP:SetMinigunEffect(i)
	if self.LastEffect==i then return end
	
	umsg.Start("SetMinigunEffect")
		umsg.Entity(self)
		umsg.Char(i)
	umsg.End()
	
	self.LastEffect = i
end

end

if CLIENT then

SWEP.PrintName			= "Minigun"
SWEP.Slot				= 0
SWEP.barrelRotation 		= 0
SWEP.barrelSpeed 			= 1
SWEP.barrelValue1 			= 0

function SWEP:SetMinigunEffect(i)
	if self.LastEffect==i then return end
	
	local effect
	
	if i==1 then
		effect = "muzzle_minigun_constant"
	end
	
	if self.Owner==LocalPlayer() and IsValid(self.Owner:GetViewModel()) and self.DrawingViewModel then
		local vm = self:GetViewModelEntity()
		vm:StopParticles()
		if effect then
			ParticleEffectAttach(effect, PATTACH_POINT_FOLLOW, vm, vm:LookupAttachment("muzzle"))
		end
	else
		local ent = self:GetWorldModelEntity()
		ent:StopParticles()
		if effect then
			ParticleEffectAttach(effect, PATTACH_POINT_FOLLOW, ent, ent:LookupAttachment("muzzle"))
		end
	end
	
	self.LastEffect = i
end

usermessage.Hook("SetMinigunEffect", function(msg)
	local w = msg:ReadEntity()
	local i = msg:ReadChar()
	if IsValid(w) and w.SetMinigunEffect then
		w:SetMinigunEffect(i)
	end
end)


SWEP.MinigunMaxSpinSpeed = 10
SWEP.MinigunSpinAcceleration = 0.07

function SWEP:InitializeCModel()
	self:CallBaseFunction("InitializeCModel")
	
	if IsValid(self.CModel) then
		if string.lower(self.CModel:GetModel()) == "models/weapons/c_models/c_leviathan/c_leviathan.mdl" then
			self.CModel.LeviathanBarrelFix = true
		end
	end
end

function SWEP:InitializeWModel2()
	self:CallBaseFunction("InitializeWModel2")
	
	if IsValid(self.WModel2) then
		if string.lower(self.WModel2:GetModel()) == "models/weapons/c_models/c_leviathan/c_leviathan.mdl" then
			self.WModel2.LeviathanBarrelFix = true
		end
	end
end

function SWEP:MinigunViewmodelReset()
	if self.Owner==LocalPlayer() then
		self:GetViewModelEntity():RemoveBuildBoneHook("MinigunSpin")
	end
end

end

SWEP.Base				= "tf_weapon_gun_base"

SWEP.ViewModel			= "models/weapons/v_models/v_minigun_heavy.mdl"
SWEP.WorldModel			= "models/weapons/w_models/w_minigun.mdl"
SWEP.Crosshair = "tf_crosshair4"

SWEP.MuzzleEffect = "muzzle_minigun_constant"
SWEP.MuzzleOffset = Vector(20, 3, -10)
SWEP.TracerEffect = "bullet_tracer01"
PrecacheParticleSystem("muzzle_minigun_constant")
PrecacheParticleSystem("bullet_tracer01_red")
PrecacheParticleSystem("bullet_tracer01_red_crit")
PrecacheParticleSystem("bullet_tracer01_blue")
PrecacheParticleSystem("bullet_tracer01_blue_crit")

SWEP.BaseDamage = 9
SWEP.DamageRandomize = 0
SWEP.MaxDamageRampUp = 0.5
SWEP.MaxDamageFalloff = 0.5

SWEP.BulletsPerShot = 4
SWEP.BulletSpread = 0.08

SWEP.Primary.ClipSize		= -1
SWEP.Primary.Ammo			= TF_PRIMARY
SWEP.Primary.Delay          = 0.1

SWEP.Secondary.Delay          = 0.1

SWEP.IsRapidFire = true

SWEP.HoldType = "PRIMARY"

SWEP.ReloadSound = Sound("Weapon_Minigun.Reload")
SWEP.EmptySound = Sound("Weapon_Minigun.ClipEmpty")
SWEP.ShootSound2 = Sound("Weapon_Minigun.Fire")
SWEP.SpecialSound1 = Sound("Weapon_Minigun.WindUp")
SWEP.SpecialSound2 = Sound("Weapon_Minigun.WindDown")
SWEP.SpecialSound3 = Sound("Weapon_Minigun.Spin")
SWEP.ShootCritSound = Sound("Weapon_Minigun.FireCrit")

function SWEP:CreateSounds()
	self.SpinUpSound = CreateSound(self.Owner, self.SpecialSound1)
	self.SpinDownSound = CreateSound(self.Owner, self.SpecialSound2)
	self.SpinSound = CreateSound(self.Owner, self.SpecialSound3)
	self.ShootSoundLoop = CreateSound(self.Owner, self.ShootSound2)
	self.ShootCritSoundLoop = CreateSound(self.Owner, self.ShootCritSound)
	
	self.SoundsCreated = true
end

function SWEP:SpinUp()
	if SERVER then
		self.Owner.minigunfiretime = 0
		self.Owner:Speak("TLK_WINDMINIGUN", true)
	end
	
	--self.Owner:SetAnimation(10004)
	
	if SERVER then
		self.Owner:DoAnimationEvent(ACT_MP_ATTACK_STAND_PREFIRE, true)
	end
	
	self:SendWeaponAnim(self.VM_PREFIRE)
	
	self:SetNetworkedBool("Spinning", true)
	
	self.Spinning = true
	
	self.NextEndSpinUp = CurTime() + 0.87 * (self.MinigunSpinupMultiplier or 1)
	self.NextEndSpinUpSound = CurTime() + 0.87
	self.NextEndSpinDown = nil
	self.NextIdle = nil
	
	self.SpinDownSound:Stop()
	self.SpinSound:Stop()
	self.SpinUpSound:Play()
end

function SWEP:SpinDown()
	--self.Owner:SetAnimation(10005)
	self.Owner:DoAnimationEvent(ACT_MP_ATTACK_STAND_POSTFIRE, true)
	self:SendWeaponAnim(self.VM_POSTFIRE)
	
	self.Ready = false
	self.NextEndSpinUp = nil
	self.NextEndSpinUpSound = nil
	self.NextEndSpinDown = CurTime() + self:SequenceDuration()
	self.NextIdle = CurTime() + self:SequenceDuration()
	
	self.Owner:SetNWBool("MinigunReady", false)
	--self.Owner:DoAnimationEvent(ACT_MP_STAND_PRIMARY, true)
	self:SetNetworkedBool("Spinning", false)
	self.Spinning = false
	
	self.SpinUpSound:Stop()
	self.SpinSound:Stop()
	self.SpinDownSound:Play()
end

function SWEP:ShootEffects()
end

function SWEP:StopFiring()
	if SERVER then
		self:SetMinigunEffect(0)
		self.Owner.minigunfiretime = 0
		self.StartTime = nil
		self.Owner:SetAnimation(PLAYER_IDLE)
	end
	
	self.SpinSound:Play()
	self.ShootSoundLoop:Stop()
	self.ShootCritSoundLoop:Stop()
	self.Firing = false
end

function SWEP:CanPrimaryAttack()
	if self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0 then
	
		self:EmitSound( "Weapon_Pistol.Empty" )
		self:SetNextPrimaryFire( CurTime() + 0.2 )
		self:Reload()
		return false
		
	end

	return true
end

function SWEP:PrimaryAttack(vampire)
	if not self.IsDeployed then return false end
	
	if not self.Spinning then
		self.IsVampire = vampire
		self:SpinUp()
	end
	
	if not self.Ready then return end
	
	if not self:CanPrimaryAttack() then
		if self.Firing then self:StopFiring() end
		return
	end
	
	local Delay = self.Delay or -1
	
	if Delay>=0 and CurTime()<Delay then return end
	self.Delay = CurTime() + self.Primary.Delay
	
	if SERVER then
		if not self.StartTime then
			self.StartTime = CurTime()
			self.Owner:Speak("TLK_FIREMINIGUN", true)
		end
		
		self.Owner.minigunfiretime = CurTime() - self.StartTime
		
		if not self.NextPlayerTalk or CurTime()>self.NextPlayerTalk then
			self.Owner:Speak("TLK_MINIGUN_FIREWEAPON")
			self.NextPlayerTalk = CurTime() + 1
		end
	end
	
	if self:RollCritical() then
		if not self.Critting or not self.Firing then
			self:SetMinigunEffect(1)
			self.SpinSound:Stop()
			self.ShootSoundLoop:Stop()
			self.ShootCritSoundLoop:Play()
			self.Firing = true
		end
		self.Critting = true
	else
		if self.Critting or not self.Firing then
			self:SetMinigunEffect(1)
			self.SpinSound:Stop()
			self.ShootCritSoundLoop:Stop()
			self.ShootSoundLoop:Play()
			self.Firing = true
		end
		self.Critting = false
	end
	
	self:SendWeaponAnim(self.VM_PRIMARYATTACK)
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	
	self:ShootProjectile(self.BulletsPerShot, self.BulletSpread)
	self:TakePrimaryAmmo(1)
end

function SWEP:SecondaryAttack()
	if self.AltFireMode == 1 then
		return self:PrimaryAttack(true)
	end
	
	if not self.IsDeployed then return false end
	
	if not self.Spinning then
		self:SpinUp()
	end
end

function SWEP:Reload()
end

function SWEP:Think()
	self:TFViewModelFOV()

	if SERVER and self.NextReplayDeployAnim then
		if CurTime() > self.NextReplayDeployAnim then
			--MsgFN("Replaying deploy animation %d", self.VM_DRAW)
			timer.Simple(0.1, function() self:SendWeaponAnim(self.VM_DRAW) end)
			self.NextReplayDeployAnim = nil
		end
	end
	
	if not self.IsDeployed and self.NextDeployed and CurTime()>=self.NextDeployed then
		self.IsDeployed = true
	end
	 
	if SERVER then
		if self.Spinning then
			self.Owner:SetClassSpeed(37 * (self.DeployMoveSpeedMultiplier or 1))
			self.Owner:SetCrouchedWalkSpeed(0)
		else
			self.Owner:ResetClassSpeed()
		end
	end
	
	if not self.SoundsCreated then
		self:CreateSounds()
	end
	
	
	if self.NextIdle and CurTime()>=self.NextIdle then
		self:SendWeaponAnim(self.VM_IDLE)
		self.NextIdle = nil
	end
	
	if self.NextEndSpinUpSound and CurTime()>=self.NextEndSpinUpSound then
		self.SpinUpSound:Stop()
		self.SpinSound:Play()
		self.NextEndSpinUpSound = nil
	end
	
	if self.NextEndSpinUp and CurTime()>=self.NextEndSpinUp then
		self.Ready = true
		self.Owner:SetNWBool("MinigunReady", true)
		--self.Owner:DoAnimationEvent(ACT_MP_DEPLOYED, true)
		self.NextEndSpinUp = nil
	end
	
	if self.NextEndSpinDown and CurTime()>=self.NextEndSpinDown then
		self.NextEndSpinDown = nil
	end
	
	if self.Firing and not self.Owner:KeyDown(IN_ATTACK) and (self.AltFireMode ~= 1 or not self.Owner:KeyDown(IN_ATTACK2)) then
		self:StopFiring()
		self:SendWeaponAnim(self.VM_SECONDARYATTACK)
	end
	
	if self.Spinning and not self.NextEndSpinDown and not self.Owner:KeyDown(IN_ATTACK) and not self.Owner:KeyDown(IN_ATTACK2) then
		if not self.NextEndSpinUp or CurTime() > self.NextEndSpinUp then
			self:SpinDown()
		end
	end
	
	if CLIENT then
	
		if self:GetNetworkedBool("Spinning") then
			--[[if self:GetItemData().attach_to_hands == 1 then
				return
			end]]
			
			if self.barrelSpeed <= 12 then
			
				self.barrelRotation = self.barrelRotation + self.barrelSpeed
				self.barrelSpeed = self.barrelSpeed + ( CurTime() - self.barrelValue1 ) * 22
					
			end
				
			if self.barrelSpeed > 12 then
				
				self.barrelSpeed = 12
					
			end
				
			if self.barrelRotation > 360 then
				
				self.barrelRotation = self.barrelRotation - 360
					
			end
				
		end
		
		if not self:GetNetworkedBool("Spinning") then
		
			if self.barrelSpeed > 0 then
			
				self.barrelRotation = self.barrelRotation + self.barrelSpeed
				self.barrelSpeed = self.barrelSpeed - ( CurTime() - self.barrelValue1 ) * 30
				
			end
			
			if self.barrelSpeed < 0 then
			
				self.barrelSpeed = 0
				
			end
			
		end
		
	end
	
	if self.barrelSpeed == 0 then
		if self:GetItemData().attach_to_hands == 1 then
			if CLIENT and self.CModel:LookupBone("barrel") then
				self:StopSound(self.SpecialSound2)
			end
		else
			self.Owner:GetViewModel():ManipulateBoneAngles( 2, Angle(0,0,self.barrelRotation) )
		end
	end
	
	if ( CLIENT ) then
		if self:GetItemData().attach_to_hands == 1 then
		bone = self.CModel:LookupBone("barrel")
			if bone then
				self.CModel:ManipulateBoneAngles( bone, Angle(0,self.barrelRotation,0) )
				self.WModel2:ManipulateBoneAngles( bone, Angle(0,self.barrelRotation,0) )
			else
				return
			end
			else
				self.Owner:GetViewModel():ManipulateBoneAngles( 2, Angle(0,0,self.barrelRotation) )
		end
		
	else
		//self.WModel2:ManipulateBoneAngles( bone, Angle(0,self.barrelRotation,0) )
	end

	self.barrelValue1 = CurTime()
	
	self:Inspect()
	
end

function SWEP:Holster()
	if IsValid(self.Owner) and self:GetNetworkedBool("Spinning") then
		self.Owner:DoAnimationEvent(ACT_MP_ATTACK_STAND_POSTFIRE, true)
	end
	
	if not self.Removed and (self.Spinning or (self.NextEndSpinDown and CurTime() < self.NextEndSpinDown)) then
		return false
	end
	
	if self.SoundsCreated then
		self.SpinUpSound:Stop()
		self.SpinDownSound:Stop()
		self.SpinSound:Stop()
		self.ShootSoundLoop:Stop()
		self.ShootCritSoundLoop:Stop()
	end
	
	self.Spinning = nil
	self.Ready = nil
	self.NextEndSpinUp = nil
	self.NextEndSpinDown = nil
	
	if SERVER and IsValid(self.Owner) then
		self.Owner:SetNWBool("MinigunReady", false)
		--self.Owner:DoAnimationEvent(ACT_MP_STAND_PRIMARY, true)
		self.Owner:ResetClassSpeed()
	end
	
	if CLIENT then
		if self.Owner==LocalPlayer() then
			self.ViewmodelInitialized = false
			self:MinigunViewmodelReset()
		end
	end
	
	if self:GetItemData().attach_to_hands == 1 then

	else
		self.Owner:GetViewModel():ManipulateBoneAngles( 2, Angle(0,0,0) )
	end
	
	return self:CallBaseFunction("Holster")
end

function SWEP:OnRemove()
	self.Owner = self.CurrentOwner
	self.Removed = true
	self:Holster()
end

if SERVER then

hook.Add("PreScaleDamage", "MinigunVampirePreDamage", function(ent, hitgroup, dmginfo)
	local inf = dmginfo:GetInflictor()
	local att = dmginfo:GetAttacker()
	
	if inf.IsVampire and ent ~= att and ent:IsTFPlayer() and ent:Health()>0 and not ent:IsBuilding() then
		if not att.LastHealthBuffTime or CurTime() ~= att.LastHealthBuffTime then
			GAMEMODE:HealPlayer(att, att, 3, true, false)
			att.LastHealthBuffTime = CurTime()
		end
	end
end)

hook.Add("PostScaleDamage", "MinigunVampirePostDamage", function(ent, hitgroup, dmginfo)
	local inf = dmginfo:GetInflictor()
	
	if inf.IsVampire then
		dmginfo:ScaleDamage(0.25)
	end
end)

end
