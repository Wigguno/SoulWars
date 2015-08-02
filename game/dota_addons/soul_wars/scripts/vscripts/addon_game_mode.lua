-- Soul Wars
-- By Richard Morrison (2015)
-- wigguno@gmail.com
-- http://steamcommunity.com/id/wigguno/

require ( "soul_wars_spawner" )	
require ( "debug_menu" )
require ( "libraries/timers" )
require ( "libraries/util" )

if CSoulWarsGameMode == nil then
	CSoulWarsGameMode = class({})
end

function Precache( context )
	--PrecacheResource( "model", "models/props_debris/spike_fence_fx_b.vmdl", context)
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
	self.bDebug = true
	
	if self.bDebug then
		print ("Debug Mode enabled")
	end
	
	self.dDebugMenu = DebugMenu()
	self.dDebugMenu:Enable()	

	GameRules:SetPreGameTime( 10.0 )
	GameRules:SetPostGameTime( 60.0 )
	GameRules:SetTreeRegrowTime( 20.0 )
	GameRules:SetGoldTickTime( 1.0 )
	GameRules:SetGoldPerTick( 1 )
	GameRules:SetCustomGameEndDelay( 0.1 )
		
	if self.bDebug then
		mode = GameRules:GetGameModeEntity()    
		--mode:SetFogOfWarDisabled(true)
	end

	Convars:RegisterCommand("sw_reset_cp_count", function(...) return self:CapturePointReset( ... ) end, "Reset the capture point count", FCVAR_CHEAT)
	Convars:RegisterCommand("sw_spawner_status", function(...) return self:SpawnerStatusReport( ... ) end, "Print status about the Soul Wars Spawners", FCVAR_CHEAT)

	-- Read the config files.
	self:ReadGameConfiguration()
	self:InitialiseSpawners()

	-- Initialise the monolith capture point 
	self.CPValue 	= 0
	self.CPCapValue = 30
	self.CPMax 		= 50

	ListenToGameEvent("dota_player_pick_hero", 	Dynamic_Wrap(CSoulWarsGameMode, "OnHeroPick"), self)
	ListenToGameEvent("last_hit", 				Dynamic_Wrap(CSoulWarsGameMode, "OnLastHit"), self)
	ListenToGameEvent("entity_hurt", 			Dynamic_Wrap(CSoulWarsGameMode, "OnEntityHit"), self)

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

	print(self.sRSSTrigger .. " - Radiant secret shop trigger")
	print(self.sDSSTrigger .. " - Dire secret shop trigger")

	if self.eRSSTrigger then print("Radiant ss trigger found!") else print("Radiant ss trigger not found!") end
	if self.eDSSTrigger then print("Dire ss trigger found!") else print("Dire ss trigger not found!") end

	self.SpawnerConfig = kv.Spawners

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

--------------------------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------------------------

-- Status Report Console Command
function CSoulWarsGameMode:SpawnerStatusReport()
	print("Displaying status report")
	for _, spawner in pairs(self.SpawnerList) do
		spawner:PrintStatus()
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
	end
end

-- NPC First Spawn
function CSoulWarsGameMode:OnHeroPick(keys)
	PrintTable(keys)
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
					print("Nom, radiant souls")
					hero:SetModifierStackCount("modifier_soul_shard_count", hero, 0)
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
					print("Nom, dire souls")
					hero:SetModifierStackCount("modifier_soul_shard_count", hero, 0)
				end
			end


		else
			self.eDSSTrigger:Disable()
		end


		-- Transmit the capture point information to the clients
		CustomNetTables:SetTableValue( "soul_wars_state", "cp_state", { value = self.CPValue } );

	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end

	return 1
end