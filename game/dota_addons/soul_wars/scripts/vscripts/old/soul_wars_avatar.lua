--[[
	CSoulWarsGameAvatar - A Class to manage a spawn point for the Avatars in Soul Wars
]]
if CSoulWarsGameAvatar == nil then
	CSoulWarsGameAvatar = class({})
end


function CSoulWarsGameAvatar:ReadConfiguration( name, kv)
	self._szName = name
	self._szSpawnerName = kv.SpawnerName or ""	
	
	self._nAvatarLeashRadius = tonumber(kv.LeashRange or 2000)
	self._nAvatarAttackRadius = tonumber(kv.AttackRadius or 800)
	self._nAvatarTeam = tonumber(kv.Team or DOTA_TEAM_NEUTRALS)
	
	self._nAvatarStartingLevel = tonumber(kv.AvatarStartingLevel or 50)

	self._nBaseHP = tonumber(kv.BaseHP or 2000)
	self._nHPGain = tonumber(kv.HPGain or 50)
	self._nHPRegen = tonumber(kv.HPRegen or 1)
	
	self._nBaseDamage = tonumber(kv.BaseDamage or 100)
	self._nDamageGain = tonumber(kv.DamageGain or 5)
	
	self._nBaseMana = tonumber(kv.BaseMana or 200)
	self._nManaGain = tonumber(kv.ManaGain or 50)
	
	self._nBaseArmour = tonumber(kv.BaseArmor or 1)
	self._nArmourGain = tonumber(kv.ArmorGain or 0.25)
	
	self._nBaseMagicResist = tonumber(kv.BaseMagicResist or 0)
	self._nMagicResistGain = tonumber(kv.MagicResistGain or 0.1)
end

function CSoulWarsGameAvatar:Precache()
	PrecacheUnitByNameAsync( self._szNPCClassName, function( sg ) self._sg = sg end )
end

function CSoulWarsGameAvatar:Begin()
	-- Initialise some variables to keep track
	-- of how many units we've spawned,
	-- and how many are alive
	self._entSpawner = Entities:FindByName( nil, self._szSpawnerName )
	--self._entAvatar = Entities:FindByNameNearest("npc_dota_roshan", self._entSpawner:GetAbsOrigin(), 1000)
	self._entAvatar = CreateUnitByName("npc_soul_wars_avatar", self._entSpawner:GetAbsOrigin(), true, nil, nil, self._nAvatarTeam)

	if self._entAvatar then
		
		self._entAvatar:AddNewModifier(self._entAvatar, nil, "modifier_phased", nil)
		-- Set the level to something high to avoid enigma conversions n stuff
		self._entAvatar:CreatureLevelUp(49)
		self:SetScale(self._nAvatarStartingLevel / 20)
		self:ChangeLevel(self._nAvatarStartingLevel)
		self._entAvatar:Heal(99999, self._entAvatar)
	end
	
	-- Get the spawner location ( And make sure we can find the entity)
	self._vecSpawnLocation = nil
	if self._szSpawnerName ~= "" then
		if not self._entSpawner then
			print( string.format( "Failed to find spawner named %s for %s\n", self._szSpawnerName, self._szName ) )
		end
		self._vecSpawnLocation = self._entSpawner:GetAbsOrigin()
	end
			
	--print(self._szName .. " avatar spawner loaded")
end

-- Volvo doesn't provide a way to reduce the level of a unit, so 
-- we just leave it	 at level one and change the properties
function CSoulWarsGameAvatar:ChangeLevel(level)
	self._entAvatar:SetMaxHealth(self._nBaseHP + (level * self._nHPGain))
	
	local damage = (self._nBaseDamage + (level * self._nDamageGain))
	self._entAvatar:SetBaseDamageMax(math.ceil(damage * 1.1))
	self._entAvatar:SetBaseDamageMin(math.floor(damage * 0.9))
	
	self._entAvatar:SetPhysicalArmorBaseValue(self._nBaseArmour + (level * self._nArmourGain))
	self._entAvatar:SetBaseMagicalResistanceValue(self._nBaseMagicResist + (level * self._nMagicResistGain))
	self._entAvatarLevel = level
end

function CSoulWarsGameAvatar:SetScale(scale)
	self._entAvatar:SetModelScale(scale)
end

function CSoulWarsGameAvatar:Think()
	--DebugDrawSphere(self._vecSpawnLocation, Vector(0, 255, 0), 0.5, self._nAvatarAttackRadius, false, 1)
	--DebugDrawSphere(self._vecSpawnLocation, Vector(255, 0, 0), 0.5, self._nAvatarLeashRadius, false, 1)
		
	if self._entAvatar:IsPositionInRange(self._vecSpawnLocation, self._nAvatarLeashRadius) == false then
		self._entAvatar:MoveToPosition(self._vecSpawnLocation)
	end
end

function CSoulWarsGameAvatar:GetHealthPerc()
	local hp = self._entAvatar:GetHealthPercent()
	if hp > 100 then
		hp = 100
	end
	return hp
end

function CSoulWarsGameAvatar:GetLevel()
	return self._entAvatarLevel
end

function CSoulWarsGameAvatar:IsDead()
	return self._entAvatar:IsNull() or not self._entAvatar:IsAlive()
end