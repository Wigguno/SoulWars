-- Soul Wars
-- By wigguno
-- http://steamcommunity.com/id/wigguno/

require ( "libraries/timers" )
require ( "libraries/util" )

require ( "soul_wars_spawner" )	
require ( "soul_wars_avatar" )	
require ( "debug_menu" )

LinkLuaModifier( "lm_avatar_level_helper", "modifiers/lm_avatar_level_helper.lua", LUA_MODIFIER_MOTION_NONE )
SOULS_PER_LEVEL = 25

if CSoulWarsGameMode == nil then
	_G.CSoulWarsGameMode = class({})
end

function Precache( context )
	--PrecacheResource( "model", "models/props_debris/spike_fence_fx_b.vmdl", context)
	PrecacheResource( "particle", "particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_necro_souls_hero.vpcf", context)
	PrecacheResource( "particle", "particles/units/heroes/hero_terrorblade/terrorblade_sunder.vpcf", context)
	PrecacheResource( "soundfile", "sounds/weapons/hero/terrorblade/sunder_cast.vsnd", context)
	PrecacheResource( "soundfile", "sounds/weapons/hero/terrorblade/sunder_target.vsnd", context)
end

-- Create the game mode when we activate
function Activate()
	CSoulWarsGameMode:InitGameMode()
end

--------------------------------------------------------------------------------------------------
-- Initial Config
--------------------------------------------------------------------------------------------------

function CSoulWarsGameMode:InitGameMode()

	print( "Loading Soul Wars..." )
	self.bDebug = false
	
	if self.bDebug then
		print ("Debug Mode enabled")

		self.dDebugMenu = DebugMenu()
		self.dDebugMenu:Enable()	
	end
	

	GameRules:SetPreGameTime( 10.0 )
	GameRules:SetPostGameTime( 60.0 )
	GameRules:SetTreeRegrowTime( 20.0 )
	GameRules:SetGoldTickTime( 1.0 )
	GameRules:SetGoldPerTick( 1 )
	GameRules:SetCustomGameEndDelay( 0.1 )

	if GetMapName() == "small" then
		GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 5)
		GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 5)
	elseif GetMapName() == "large" then
		GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 12)
		GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 12)
	end

	Convars:RegisterCommand("sw_reset_cp_count", function(...) return self:CapturePointReset( ... ) end, "Reset the capture point count", FCVAR_CHEAT)
	Convars:RegisterCommand("sw_spawner_status", function(...) return self:SpawnerStatusReport( ... ) end, "Print status about the Soul Wars Spawners", FCVAR_CHEAT)

	-- Read the config files.
	self:ReadGameConfiguration()
	self:InitialiseSpawners()
	self:InitialiseAvatars()
	self:SpawnVisionDummies()

	-- Initialise the monolith capture point 
	self.CPValue 		= 0
	self.CPCapValue 	= 30
	self.CPMax 			= 50
	self.RadiantSouls 	= 0
	self.DireSouls 		= 0

	self.RadiantAvatarHealth 	= 100
	self.DireAvatarHealth		= 100

	ListenToGameEvent("dota_player_pick_hero", 	Dynamic_Wrap(CSoulWarsGameMode, "OnHeroPick"), self)
	ListenToGameEvent("last_hit", 				Dynamic_Wrap(CSoulWarsGameMode, "OnLastHit"), self)
	ListenToGameEvent("entity_hurt", 			Dynamic_Wrap(CSoulWarsGameMode, "OnEntityHit"), self)
	ListenToGameEvent("entity_killed", 			Dynamic_Wrap(CSoulWarsGameMode, "OnEntityKill"), self)

	-- stop the avatars being attacked outside their pits using these two filters
	local mode = GameRules:GetGameModeEntity()
	mode:SetExecuteOrderFilter( Dynamic_Wrap (CSoulWarsGameMode, "ExecuteOrderFilter" ), self )
	mode:SetDamageFilter( Dynamic_Wrap (CSoulWarsGameMode, "DamageFilter" ), self )


	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 1 )

	print( "Soul Wars is loaded." )

end

-- load the settings from a text file
function CSoulWarsGameMode:ReadGameConfiguration()
	print( "Loading KV Configuration" )
	if self.bDebug then print( "scripts/maps/" .. GetMapName() .. ".txt" ) end
	local kv = LoadKeyValues( "scripts/maps/" .. GetMapName() .. ".txt" )
	
	kv = kv or {}
	self.kvRAW = kv

	-- Find some triggers
	self.sCPTrigger = kv.CPTrigger or ""
	self.eCPTrigger = Entities:FindByName(nil, self.sCPTrigger)

	self.sRSSTrigger = kv.RadiantSSTrigger or ""
	self.eRSSTrigger = Entities:FindByName(nil, self.sRSSTrigger)

	self.sDSSTrigger = kv.DireSSTrigger or ""
	self.eDSSTrigger = Entities:FindByName(nil, self.sDSSTrigger)

	--print(self.sRSSTrigger .. " - Radiant secret shop trigger")
	--print(self.sDSSTrigger .. " - Dire secret shop trigger")

	--if self.eRSSTrigger then print("Radiant ss trigger found!") else print("Radiant ss trigger not found!") end
	--if self.eDSSTrigger then print("Dire ss trigger found!") else print("Dire ss trigger not found!") end

	self.SpawnerConfig = kv.Spawners
	self.AvatarConfig = kv.Avatars

end

function CSoulWarsGameMode:InitialiseSpawners()
	if not self.SpawnerConfig then 
		print("ERROR: NO SPAWNER CONFIG LOADED")
	end

	self.SpawnerList = {}

	-- loop over all spawner configs and try to start them
	for k, v in pairs(self.SpawnerConfig) do
		if self.bDebug then print("Loading spawner: " .. v.Name) end
		local spawner = SoulWarsSpawner()

		if spawner:Init(v) then 
			if self.bDebug then print("Spawner loaded succesfully") end
			spawner:Precache()
			table.insert(self.SpawnerList, spawner)
		else
			print("ERROR LOADING SPANWER: " .. v.Name)
		end
	end
end

function CSoulWarsGameMode:InitialiseAvatars()
	if not self.AvatarConfig then
		print("ERROR: NO AVATAR CONFIG LOADED")
	end

	self.AvatarList = {}

	for k, v in pairs(self.AvatarConfig) do
		if self.bDebug then print("Loading avatar: " .. v.Name) end
		local avatar = SoulWarsAvatar()

		if avatar:Init(v) then 
			if self.bDebug then print("Avatar loaded succesfully") end
			avatar:Precache()
			table.insert(self.AvatarList, avatar)
		else
			print("ERROR LOADING AVATAR: " .. v.Name)
		end
	end
end

function CSoulWarsGameMode:SpawnVisionDummies()
	CreateUnitByName("dummy_vision", Vector(-4096, -2432, 512), false, nil, nil, DOTA_TEAM_GOODGUYS)
	CreateUnitByName("dummy_vision", Vector(-3584, -2496, 384), false, nil, nil, DOTA_TEAM_GOODGUYS)
	CreateUnitByName("dummy_vision", Vector(-2624, -1088, 0), false, nil, nil, DOTA_TEAM_GOODGUYS)
	CreateUnitByName("dummy_vision", Vector(-3684, -1280, 0), false, nil, nil, DOTA_TEAM_GOODGUYS)

	CreateUnitByName("dummy_vision", Vector(4096, 2496, 512), false, nil, nil, DOTA_TEAM_BADGUYS)
	CreateUnitByName("dummy_vision", Vector(3712, 2560, 384), false, nil, nil, DOTA_TEAM_BADGUYS)
	CreateUnitByName("dummy_vision", Vector(2624, 1024, 0), false, nil, nil, DOTA_TEAM_BADGUYS)
	CreateUnitByName("dummy_vision", Vector(3684, 1280, 0), false, nil, nil, DOTA_TEAM_BADGUYS)
end

--------------------------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------------------------

-- Status Report Console Command
function CSoulWarsGameMode:SpawnerStatusReport()
	print("Displaying status report")
	for _, spawner in pairs(self.SpawnerList) do
		spawner:PrintStatus()
	end
	for _, avatar in pairs(self.AvatarList) do
		avatar:PrintStatus()
	end
end

-- Reset CP
function CSoulWarsGameMode:CapturePointReset()
	self.CPValue = 0
end

-- Last Hit
function CSoulWarsGameMode:OnLastHit(keys)
	--PrintTable(keys)
	local creep = EntIndexToHScript(keys.EntKilled)
	local playerKiller = PlayerResource:GetPlayer(keys.PlayerID)
	local heroKiller = playerKiller:GetAssignedHero()

	if creep.SoulBounty then
		local oldstack = heroKiller:GetModifierStackCount("modifier_soul_shard_count", heroKiller) or 0
		--print(heroKiller:GetUnitName() .. ": " .. oldstack .. " + " .. creep.SoulBounty)
		local newstack = oldstack + creep.SoulBounty

		heroKiller:SetModifierStackCount("modifier_soul_shard_count", nil, newstack)

		local soulPart = ParticleManager:CreateParticle("particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_necro_souls_hero.vpcf", PATTACH_POINT_FOLLOW, heroKiller)
		ParticleManager:SetParticleControlEnt(soulPart, 0, creep, PATTACH_POINT_FOLLOW, "attach_hitloc", heroKiller:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(soulPart, 1, heroKiller, PATTACH_POINT_FOLLOW, "attach_hitloc", heroKiller:GetAbsOrigin(), true)
	end
end

-- NPC First Spawn
function CSoulWarsGameMode:OnHeroPick(keys)
	--PrintTable(keys)
	local hero 		= EntIndexToHScript(keys.heroindex)
	local player 	= EntIndexToHScript(keys.player)

	if not hero:HasAbility("soul_wars_helper") then
		hero:AddAbility("soul_wars_helper")

		local abil = hero:FindAbilityByName("soul_wars_helper")
		if abil then
			abil:SetLevel(1)
		end
	end
	--soul_wars_helper
end

-- Unit is hit
function CSoulWarsGameMode:OnEntityHit(keys)
	-- Manually code aggression / behaviour (because default is bad)
	-- Part 1 - Retialliate on hit - this code
	-- Part 2 is to return passive if drawn out of wander bounds, and is checked inside the spawner thinker

	--PrintTable(keys)
	--print("On Entity Hit!")
	if not keys.entindex_attacker then return end
	local ent_killed 	= EntIndexToHScript(keys.entindex_killed)
	local ent_attacker 	= EntIndexToHScript(keys.entindex_attacker)

	if ent_killed.SoulBounty ~= nil then
		--print("Hit entity has soul bounty (therefore is creep)")
		if ent_killed:IsAlive() then
			ent_killed:MoveToTargetToAttack(ent_attacker)

			-- set this variable to the entity so the thinker knows to check bounds
			ent_killed.Attacking = true
		end
	end
end

-- player dies
function CSoulWarsGameMode:OnEntityKill(keys)
	-- Transfer the killed persons souls to the killer
	--PrintTable(keys)
	local attacker = EntIndexToHScript(keys.entindex_attacker)
	local killed = EntIndexToHScript(keys.entindex_killed)
	if attacker:IsRealHero() and killed:IsRealHero() then

		local attacker_souls = attacker:GetModifierStackCount("modifier_soul_shard_count", attacker)
		local killed_souls = killed:GetModifierStackCount("modifier_soul_shard_count", killed)

		attacker:SetModifierStackCount("modifier_soul_shard_count", attacker, attacker_souls + killed_souls)
		
		local soulPart = ParticleManager:CreateParticle("particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_necro_souls_hero.vpcf", PATTACH_POINT_FOLLOW, attacker)
		ParticleManager:SetParticleControlEnt(soulPart, 0, killed, PATTACH_POINT_FOLLOW, "attach_hitloc", attacker:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(soulPart, 1, attacker, PATTACH_POINT_FOLLOW, "attach_hitloc", attacker:GetAbsOrigin(), true)
	end


end

-- obelisk takes souls (effect function)
function CSoulWarsGameMode:sunder(hero)
			
	EmitSoundOn("Hero_Terrorblade.Sunder.Cast", hero)
	EmitSoundOn("Hero_Terrorblade.Sunder.Target", hero)

	-- Show the particle caster-> target
	local particleName = "particles/units/heroes/hero_terrorblade/terrorblade_sunder.vpcf"	
	local particle = ParticleManager:CreateParticle( particleName, PATTACH_POINT_FOLLOW, hero )
	
	ParticleManager:SetParticleControl(particle, 0, Vector(0, 0, 768))
	ParticleManager:SetParticleControlEnt(particle, 1, hero, PATTACH_POINT_FOLLOW, "attach_hitloc", hero:GetAbsOrigin(), true)
	
	-- Show the particle target-> caster
	local particleName = "particles/units/heroes/hero_terrorblade/terrorblade_sunder.vpcf"	
	local particle = ParticleManager:CreateParticle( particleName, PATTACH_POINT_FOLLOW, hero )
	
	ParticleManager:SetParticleControlEnt(particle, 0, hero, PATTACH_POINT_FOLLOW, "attach_hitloc", hero:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(particle, 1, Vector(0, 0, 768))
end

--------------------------------------------------------------------------------------------------
-- Order Filter
--------------------------------------------------------------------------------------------------

function CSoulWarsGameMode:ExecuteOrderFilter(filterTable)

	--print("-------------------------------------------------")
	--PrintTable(filterTable)

	if filterTable.order_type == DOTA_UNIT_ORDER_ATTACK_TARGET or filterTable.order_type == DOTA_UNIT_ORDER_CAST_TARGET then 

		local order_unit = EntIndexToHScript(filterTable.units['0'])
		local target_unit = EntIndexToHScript(filterTable.entindex_target)

		if target_unit.unitType and target_unit.unitType == "Avatar" then
			local attackTrigger = Entities:FindByName(nil, target_unit.attackTrigger)
			if not attackTrigger:IsTouching(order_unit) then
				return false
			end
		end
	end
	
	return true

end

--------------------------------------------------------------------------------------------------
-- Damage Filter
--------------------------------------------------------------------------------------------------

function CSoulWarsGameMode:DamageFilter(filterTable)

	--print("-------------------------------------------------")
	--PrintTable(filterTable)

	if filterTable.entindex_attacker_const == nil then return true end

	local attack_unit = EntIndexToHScript(filterTable.entindex_attacker_const)
	local target_unit = EntIndexToHScript(filterTable.entindex_victim_const)

	if target_unit.unitType and target_unit.unitType == "Avatar" then

		local attackTrigger = Entities:FindByName(nil, target_unit.attackTrigger)

		--print("DAMAGE TO AVATAR")
		--print (attackTrigger:IsTouching(attack_unit)) 
		if not attackTrigger:IsTouching(attack_unit) then
			return false
		end
	end

	return true

end

--------------------------------------------------------------------------------------------------
-- Thinker
--------------------------------------------------------------------------------------------------

-- Evaluate the state of the game
function CSoulWarsGameMode:OnThink()
	--print( "Shaman Wars Main Thinker script is running." )
		
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_PRE_GAME then
	

	elseif GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		
		-- do the spawner thinking
		for _, spawner in pairs(self.SpawnerList) do
			spawner:Think()
		end		

		for _, avatar in pairs(self.AvatarList) do
			local avatar_health = avatar:Think()
			if not avatar_health then
				if avatar.Team == DOTA_TEAM_GOODGUYS then
					GameRules:SetGameWinner( DOTA_TEAM_BADGUYS )
				elseif avatar.Team == DOTA_TEAM_BADGUYS then
					GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
				end
			else
				if avatar.Team == DOTA_TEAM_GOODGUYS then
					self.RadiantAvatarHealth = avatar_health
				elseif avatar.Team == DOTA_TEAM_BADGUYS then
					self.DireAvatarHealth = avatar_health
				end
			end
		end
		
		-----------------------------------------------
		-- KOTH thinking
		-----------------------------------------------
		local CPCount = {}
		CPCount[DOTA_TEAM_GOODGUYS] 	= 0
		CPCount[DOTA_TEAM_BADGUYS] 		= 0

		for _, hero in pairs(HeroList:GetAllHeroes()) do
			if self.eCPTrigger:IsTouching(hero) and not hero:IsClone() then -- Make sure only the main meepo counts
				--print(hero:GetUnitName())
				CPCount[hero:GetTeam()] = CPCount[hero:GetTeam()] + 1
			end
		end 

		--	PrintTable(CPCount)
		self.CPValue = self.CPValue + CPCount[DOTA_TEAM_GOODGUYS] - CPCount[DOTA_TEAM_BADGUYS]
		--print(self.CPValue)

		-- Radiant has full control
		if self.CPValue > self.CPMax then
			self.CPValue = self.CPMax
		end

		-- Dire has full control
		if self.CPValue < (-1 * self.CPMax) then
			self.CPValue = (-1 * self.CPMax) 
		end

		-- Dire has pulled the control point away from radiant
		if self.CPValue < 0 then
			self.bRadiantCaptured = false

		-- Radiant has pulled control away from dire
		elseif self.CPValue > 0 then
			self.bDireCaptured = false

		else
			self.bRadiantCaptured = false
			self.bDireCaptured = false
			
		end

		-- Radiant has captured the control point
		if self.CPValue > self.CPCapValue then
			self.bRadiantCaptured = true
		end

		-- Dire has captured the control point
		if self.CPValue < (self.CPCapValue * -1) then
			self.bDireCaptured = true
		end

		if self.bRadiantCaptured == true then
			-- Turn the secret shop on
			self.eRSSTrigger:Enable()

			-- Take any souls from any radiant players
			for _, hero in pairs(HeroList:GetAllHeroes()) do
				if hero:GetTeam() == DOTA_TEAM_GOODGUYS and self.eCPTrigger:IsTouching(hero) and hero:GetModifierStackCount("modifier_soul_shard_count", hero) > 0 then
					--print("Nom, radiant souls")
					self.RadiantSouls = self.RadiantSouls + hero:GetModifierStackCount("modifier_soul_shard_count", hero)
					hero:SetModifierStackCount("modifier_soul_shard_count", hero, 0)

					self:sunder(hero)
				end
			end
		else
			self.eRSSTrigger:Disable()
		end

		if self.bDireCaptured == true then
			-- Turn the secret shop on
			self.eDSSTrigger:Enable()

			-- Take any souls from any dire players
			for _, hero in pairs(HeroList:GetAllHeroes()) do
				if hero:GetTeam() == DOTA_TEAM_BADGUYS and self.eCPTrigger:IsTouching(hero) and hero:GetModifierStackCount("modifier_soul_shard_count", hero) > 0 then
					--print("Nom, dire souls")
					self.DireSouls = self.DireSouls + hero:GetModifierStackCount("modifier_soul_shard_count", hero)
					hero:SetModifierStackCount("modifier_soul_shard_count", hero, 0)

					self:sunder(hero)
				end
			end
		else
			self.eDSSTrigger:Disable()
		end

		local DireAvatarLevel = 99 - ( self.RadiantSouls / SOULS_PER_LEVEL )
		local RadiantAvatarLevel = 99 - ( self.DireSouls / SOULS_PER_LEVEL ) 

		if DireAvatarLevel < 1 then DireAvatarLevel = 1 end
		if RadiantAvatarLevel < 1 then RadiantAvatarLevel = 1 end
		
		for _, avatar in pairs(self.AvatarList) do
			if avatar.Team == DOTA_TEAM_GOODGUYS and avatar.Level ~= RadiantAvatarLevel then
				avatar:SetLevel(RadiantAvatarLevel)
			elseif avatar.Team == DOTA_TEAM_BADGUYS and avatar.level ~= DireAvatarLevel then
				avatar:SetLevel(DireAvatarLevel)
			end
		end


		-- Transmit the capture point information to the clients
		CustomNetTables:SetTableValue( "soul_wars_state", "cp_state", { value = self.CPValue, radiantCaptured = self.bRadiantCaptured, direCaptured = self.bDireCaptured} );
		CustomNetTables:SetTableValue( "soul_wars_state", "soul_count", { radiant_souls = self.RadiantSouls, dire_souls = self.DireSouls} );
		CustomNetTables:SetTableValue( "soul_wars_state", "avatar_status", { 
			radiant_avatar_level = RadiantAvatarLevel,
			radiant_avatar_health = self.RadiantAvatarHealth,
			dire_avatar_level = DireAvatarLevel,
			dire_avatar_health = self.DireAvatarHealth,
			});

	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end

	return 1
end