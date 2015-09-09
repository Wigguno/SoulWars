-- Soul Wars Avatar
-- By wigguno
-- http://steamcommunity.com/id/wigguno/

if SoulWarsAvatar == nil then
	_G.SoulWarsAvatar = class({})
end


function SoulWarsAvatar:Init( kv )

	local spawnerEnt = Entities:FindByName(nil, kv.Location)
	self.SpawnLocation = spawnerEnt:GetAbsOrigin()

	self.attackTrigger = kv.Trigger

	self.Creature = kv.Creature
	self.Name = kv.Name

	self.NumAlive = 0

	self.Level = 99

	self.Team = DOTA_TEAM_NEUTRALS
	if kv.Team == "Radiant" then
		self.Team = DOTA_TEAM_GOODGUYS
	elseif kv.Team == "Dire" then
		self.Team = DOTA_TEAM_BADGUYS
	end
	return true
end

function SoulWarsAvatar:Precache()
	-- precache our unit
	PrecacheUnitByNameAsync( self.Creature, function( sg ) self.pc = sg end )
end

function SoulWarsAvatar:SetLevel(level)
	self.Level = level
	local health_perc = self.entUnit:GetHealthPercent()
	local mana_perc = self.entUnit:GetManaPercent()

	if self.entUnit:FindModifierByName("lm_avatar_level_helper") then
		self.entUnit:RemoveModifierByName("lm_avatar_level_helper")
	end

	self.entUnit:AddNewModifier(self.entUnit, nil, "lm_avatar_level_helper", {stack_count = level - 1})

	self.entUnit:SetHealth((self.entUnit:GetMaxHealth()) * (health_perc / 100))
	self.entUnit:SetMana((self.entUnit:GetMaxMana()) * (mana_perc / 100))
end

function SoulWarsAvatar:DoSpawn()
	-- Spawn a single unit
	self.entUnit = CreateUnitByName( self.Creature, self.SpawnLocation, true, nil, nil, self.Team )
	self:SetLevel(self.Level)
	self.entUnit.unitType = "Avatar"
	self.entUnit.attackTrigger = self.attackTrigger
end

function SoulWarsAvatar:Think()
	-- Thinker function, gets called from the main gamemode thinker
	-- ONLY RUN THIS ON THE SERVER
	if IsServer() then 
	
		if not self.entUnit then
			self:DoSpawn()
			self.NumAlive = 1
		end

		if self.entUnit:IsNull() or not self.entUnit:IsAlive() then
			return false
		end

		local attackTrigger = Entities:FindByName(nil, self.attackTrigger)
		
		if not attackTrigger:IsTouching(self.entUnit) then
		--if (self.entUnit:GetAbsOrigin() - self.SpawnLocation):Length2D() > 512 then
			--print("TP BACK TO SPAWN")
			self.entUnit:MoveToPosition(self.SpawnLocation)
		else
			--print("POSITION IS OKAY")
		end

	end
	return self.entUnit:GetHealthPercent()
end

function SoulWarsAvatar:PrintStatus()
	print(self.Name 	.. " ----------------------")
	print("Alive: " 	.. self.NumAlive)
end