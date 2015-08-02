-- Soul Wars
-- By Richard Morrison (2015)
-- wigguno@gmail.com
-- http://steamcommunity.com/id/wigguno/

require ( "soul_wars_spawner" )
require ( "soul_wars_avatar" )
require ( "timers" )
require ( "util" )

if CSoulWarsGameMode == nil then
	CSoulWarsGameMode = class({})
end

function Precache( context )
	PrecacheResource( "model", "models/props_debris/spike_fence_fx_b.vmdl", context)
end

-- Create the game mode when we activate
function Activate()
	CSoulWarsGameMode:InitGameMode()
end

function CSoulWarsGameMode:InitGameMode()
	
	print( "Soul Wars is loaded, starting init code..." )
	self._debug_mode = 0
	
	if self._debug_mode == 1 then
		print ("Debug Mode enabled")
	end
	
	-- Find some entities on the map and store their locations.
	self._entMonolith = Entities:FindByName(nil, "soul_wars_monolith")
	self._trigDefaultMonolithState = Entities:FindByName(nil, "MonolithTrigger_Default")
	self._trigRadiantMonolithState = Entities:FindByName(nil, "MonolithTrigger_Radiant")
	self._trigDireMonolithState = Entities:FindByName(nil, "MonolithTrigger_Dire")
	
	self._vMonolithVector = ""
	
	self._entDireBase = Entities:FindByName(nil, "ent_dire_base_center")
	self._entRadiantBase = Entities:FindByName(nil, "ent_radiant_base_center")
		
	self._vRadiantBaseTeleport = Entities:FindByName(nil, "ent_radiant_base_teleport"):GetAbsOrigin()
	self._vDireBaseTeleport = Entities:FindByName(nil, "ent_dire_base_teleport"):GetAbsOrigin()
	
	self._bRadiantOwnsMonolith = false;
	self._bDireOwnsMonolith = false;
	
	self._nRadiantSoulCount = 0
	self._nDireSoulCount = 0
	
	self._KOTHMonolithState = 0
	
	if not self._entMonolith then
		print("Monolith not found!");
	else
		self._vMonolithVector = self._entMonolith:GetAbsOrigin()
	end
	------------------------------------------------------------------------------------
	if not self._trigDefaultMonolithState then
		print("Default Monolith Trigger not found!")
	else
		--print("Found Default Monolith Trigger")
		self._trigDefaultMonolithState:Disable()
	end
	
	if not self._trigRadiantMonolithState then
		print("Radiant Monolith Trigger not found!")
	else
		--print("Found Radiant Monolith Trigger")
		self._trigRadiantMonolithState:Disable()
	end
	
	if not self._trigDireMonolithState then
		print("Dire Monolith Trigger not found!")
	else
		--print("Found Dire Monolith Trigger")
		self._trigDireMonolithState:Disable()
	end
	-------------------------------------------------------------------------------------
	if not self._entDireBase then
		print("Dire base not found!")
	end
	
	if not self._entRadiantBase then
		print("Radiant base not found")
	end
	
	-- Read the config files.
	self:_ReadGameConfiguration()
		
	GameRules:SetHeroRespawnEnabled( true )
	GameRules:SetUseUniversalShopMode( false )
	GameRules:SetPreGameTime( 10.0 )
	GameRules:SetPostGameTime( 60.0 )
	GameRules:SetTreeRegrowTime( 20.0 )
	GameRules:SetHeroMinimapIconScale( 1.3 )
	GameRules:SetCreepMinimapIconScale( 1 )
	GameRules:SetGoldTickTime( 1.0 )
	GameRules:SetGoldPerTick( 1 )
	GameRules:SetCustomGameEndDelay( 0.1 )
	
	GameRules:GetGameModeEntity():SetRemoveIllusionsOnDeath( true )
	
	if self._debug_mode == 1 then
		mode = GameRules:GetGameModeEntity()    
		mode:SetFogOfWarDisabled(true)
	end
	
	Convars:RegisterCommand("soul_wars_status_report",function(...) return self:_StatusReport( ... ) end, "Report the status of all the spawners", FCVAR_CHEAT)
	Convars:RegisterCommand("soul_wars_give_souls", function(...) return self:_GiveSouls( ... ) end, "Give souls", FCVAR_CHEAT)
	Convars:RegisterCommand("soul_wars_fake", function(...) return self:_FakeClients( ... ) end, "Add fake clients to soul wars", FCVAR_CHEAT)

	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 1 )

	ListenToGameEvent('npc_spawned', Dynamic_Wrap(CSoulWarsGameMode, 'OnNPCSpawn'), self)
	ListenToGameEvent('entity_killed', Dynamic_Wrap(CSoulWarsGameMode, 'OnEntityKill'), self)
	ListenToGameEvent('entity_hurt', Dynamic_Wrap(CSoulWarsGameMode, 'OnHit'), self)
	ListenToGameEvent('last_hit', Dynamic_Wrap(CSoulWarsGameMode, 'OnLastHit'), self)
	
	-- start the roshan spawners
	self._avatarRadiant:Precache()
	self._avatarDire:Precache()
	
	-- start the spawners
	for _,spawner in pairs(self._vSpawners) do
		--print("Starting Spawner " .. _)
		spawner:Precache()
		spawner:Begin()
	end
	
	-- Set the triggers for the do-once events
	self._bPreGameEventsCompleted = false
	self._bGameEventsCompleted = false
	 
	print( "Soul Wars is loaded." )

end

function CSoulWarsGameMode:OnNPCSpawn(keys)
	-- check if unit is a hero
	npc = EntIndexToHScript(keys.entindex)
	if (npc:IsRealHero() == true) then
		-- check if the hero has the soul wars helper ability
		
		local sw_helper_abil = npc:FindAbilityByName( "soul_wars_helper" ) 
		if not sw_helper_abil then
			npc:AddAbility("soul_wars_helper")
			sw_helper_abil = npc:FindAbilityByName( "soul_wars_helper" ) 
			-- double check the ability has been added correctly
			if not sw_helper_abil then
				print("Ability cannot be added... :(")
				return
			else
				sw_helper_abil:SetLevel(1)
				--print("Succesfully added soul wars helper ability to a hero!")
			end
		end
		
		-- set the soul counter to 0
		npc:SetModifierStackCount("modifier_soul_shard_count", npc, 0)
	end
end

function CSoulWarsGameMode:OnEntityKill(keys)
	if keys.entindex_attacker and keys.entindex_killed then
	
		killer = EntIndexToHScript(keys.entindex_attacker)
		target = EntIndexToHScript(keys.entindex_killed)
		
		if target:GetUnitName() == "npc_soul_wars_avatar" then		
			if target:GetTeam() == DOTA_TEAM_GOODGUYS then
				self._bRadiantAvatarAlive = false
				GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
			elseif target:GetTeam() == DOTA_TEAM_BADGUYS then
				self._bDireAvatarAlive = false
				GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)	
			end
		end		
	end
end

function CSoulWarsGameMode:OnLastHit(keys)

	if keys.PlayerID and keys.EntKilled then
		killer = PlayerResource:GetPlayer(keys.PlayerID):GetAssignedHero()
		target = EntIndexToHScript(keys.EntKilled)
		
		if keys.HeroKill == 1 then
			target:SetTimeUntilRespawn(15)
		end
		
		if killer:IsRealHero() and not target:IsRealHero() and target:GetUnitName() ~= "npc_sw_barricade" then
			killer:SetModifierStackCount("modifier_soul_shard_count", killer, killer:GetModifierStackCount("modifier_soul_shard_count", killer) + 1)
		end
		
		if killer:IsRealHero() and target:IsRealHero() then
			--print("PLAYER KILL")
			local tSouls = math.floor(target:GetModifierStackCount("modifier_soul_shard_count", target) * self._flPVPKillReward)
			local kSouls = killer:GetModifierStackCount("modifier_soul_shard_count", killer)
			killer:SetModifierStackCount("modifier_soul_shard_count", killer, tSouls + kSouls)
		end
		
		if target:GetUnitName() == "npc_shaman_wars_avatar" then		
			if target:GetTeam() == DOTA_TEAM_GOODGUYS then
				self._bRadiantAvatarAlive = false
				GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
			elseif target:GetTeam() == DOTA_TEAM_BADGUYS then
				self._bDireAvatarAlive = false
				GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)	
			end
		end
	end
	--]]
end

function CSoulWarsGameMode:OnHit(keys)
	if keys.entindex_attacker and keys.entindex_killed then
		local attacker = EntIndexToHScript(keys.entindex_attacker)
		--local killed = EntIndexToHScript(keys.entindex_killed)
		local inflictor = EntIndexToHScript(keys.entindex_killed)
		
		--print("attacker: " .. attacker:GetUnitName())
		--print("killed: " .. killed:GetUnitName())
		--print("inflictor: " .. inflictor:GetUnitName())
		
		if not inflictor:IsRealHero() and not inflictor:IsAttacking() then
			--print("Target not attacking, setting new target")
			inflictor:SetIdleAcquire(true)
			inflictor:MoveToTargetToAttack(attacker)
		else
			--print("Target already attacking!")
		end
	end
end

-- load the settings from a text file
function CSoulWarsGameMode:_ReadGameConfiguration()
	--print( "Loading KV Configuration" )
	--print( "scripts/maps/" .. GetMapName() .. ".txt" )
	local kv = LoadKeyValues( "scripts/maps/" .. GetMapName() .. ".txt" )
	
	kv = kv or {}

	-- load the integers
	self._nAvatarStartingLevel = tonumber(kv.AvatarProperties.AvatarStartingLevel or 50)
	self._nAvatarSoulDivider = tonumber(kv.AvatarSoulDivider or 20)
	self._nPlayerStartingLevel = tonumber(kv.PlayerStartingLevel or 1)
	self._nPlayerLevelCap = tonumber(kv.PlayerLevelCap or 50)
	self._nSoulsPerMob = tonumber(kv.SoulsPerMob or 1)
	
	self._nRadiantBaseRadius = tonumber(kv.RadiantBaseRadius or 800)
	self._nDireBaseRadius = tonumber(kv.DireBaseRadius or 800)
	
	self._nRadiantAvatarLeashRange = tonumber(kv.RadiantAvatarLeashRadius or 300)
	self._nDireAvatarLeashRange = tonumber(kv.DireAvatarLeashRadius or 300)

	-- load the floats
	self._flPVPKillReward = tonumber(kv.PVPKillReward or 0.9)
	
	-- load the koth values
	self._nKOTHCaptureRadius 			= tonumber(kv.KOTHCaptureRadius or 1200)
	self._nKOTHHandinRadius 			= tonumber(kv.KOTHHandinRadius or 300)
	self._nKOTHMonolithThreshold 		= tonumber(kv.KOTHCaptureThreshold or 30)
	self._nKOTHMonolithMax 				= tonumber(kv.KOTHMonolithMax or 50)
	
	-- load the spawners
	self._vSpawners = {}
	for k, v in pairs( kv ) do
		if type (v) == "table" and k == "Spawners" then
			for kk, vv in pairs(v) do
				local spawner = CSoulWarsGameSpawner()
				spawner:ReadConfiguration( kk, vv)
				self._vSpawners[kk] = spawner
			end
		end
	end
	
	self._avatarRadiant = CSoulWarsGameAvatar()	
	local AvatarPropertiesRadiant 			= kv.AvatarProperties
	AvatarPropertiesRadiant.Team 			= tostring(DOTA_TEAM_GOODGUYS)
	AvatarPropertiesRadiant.SpawnerName 	= "roshan_spawner_radiant"
	self._avatarRadiant:ReadConfiguration("Radiant", AvatarPropertiesRadiant)
	
	self._avatarDire = CSoulWarsGameAvatar()
	local AvatarPropertiesDire 			= kv.AvatarProperties
	AvatarPropertiesDire.Team 			= tostring(DOTA_TEAM_BADGUYS)
	AvatarPropertiesDire.SpawnerName 	= "roshan_spawner_dire"
	self._avatarDire:ReadConfiguration("Dire", AvatarPropertiesDire)
	
	self._bRadiantAvatarAlive = true
	self._bDireAvatarAlive = true
end
	
function CSoulWarsGameMode:_StatusReport( cmdName )
	print("Displaying status report")
	for _, spawner in pairs(self._vSpawners) do
		spawner:StatusReport()
	end

end

function CSoulWarsGameMode:_GiveSouls( cmdName , num)
	PrintTable(cmdName)
	if not num then
		num = 100
	end
	print("Soul Wars Give Souls: " .. num)

	for _, hero in pairs(HeroList:GetAllHeroes()) do
		hero:SetModifierStackCount("modifier_soul_shard_count", hero, hero:GetModifierStackCount("modifier_soul_shard_count", hero) + num)
	end
end

function CSoulWarsGameMode:_SpawnDummy(location, model, vision, team)
	dummy = CreateUnitByName(model, location, true, nil, nil, team)
	
	if dummy then
		dummy:SetDayTimeVisionRange(vision)
		dummy:SetNightTimeVisionRange(vision)
	
		local ab1 = Entities:FindByName(nil, "healthbar_hider")
		ab1:UpgradeAbility(false)
	end	
end

function CSoulWarsGameMode:_FakeClients( cmdname )
	SendToServerConsole('dota_create_fake_clients')
	local players = Entities:FindAllByClassname("player")

	for i = 0, 9 do
		-- Check if this player is a fake one
		if PlayerResource:IsFakeClient(i) then
			print(i .. " is a fake client")
			-- Grab player instance
			local ply = PlayerResource:GetPlayer(i)
			-- Make sure we actually found a player instance
			if ply then
				CreateHeroForPlayer('npc_dota_hero_windrunner', ply)
				ply:GetAssignedHero():SetControllableByPlayer(0, true)
			end
		end
	end
end

-- Evaluate the state of the game
function CSoulWarsGameMode:OnThink()
	--print( "Shaman Wars Main Thinker script is running." )
		
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_PRE_GAME then
	
		-- single shot events
		if self._bPreGameEventsCompleted == false then
			-- Fire these game events to initialise the HUD
			FireGameEvent("sw_update_monolith_state", {monolith_state = self._KOTHMonolithState, monolith_max = self._nKOTHMonolithMax, monolith_thresh = self._nKOTHMonolithThreshold, radiant_owns_monolith = self._bRadiantOwnsMonolith, dire_owns_monolith = self._bDireOwnsMonolith, num_radiant_capturing = 0, num_dire_capturing = 0})
			FireGameEvent("sw_radiant_update_soul_score", {soul_score = self._nRadiantSoulCount})
			FireGameEvent("sw_dire_update_soul_score", {soul_score = self._nDireSoulCount})
			
			self._bPreGameEventsCompleted = true
		end
		
	elseif GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		
	
		if self._debug_mode == 1 then
			--
			-- Draw some debug things
			-- DebugDrawSphere(Location, Colour Vector(R, G, B), alpha, radius, ztest(??), duration )
			DebugDrawSphere(self._vMonolithVector, Vector(255, 0, 0), 0.5, self._nKOTHCaptureRadius, false, 1)
			DebugDrawSphere(self._vMonolithVector, Vector(0, 255, 0), 0.5, self._nKOTHHandinRadius, false, 1)
			
			DebugDrawSphere(self._entRadiantBase:GetAbsOrigin(), Vector(255, 255, 255), 0.5, self._nRadiantBaseRadius, false, 1)
			DebugDrawSphere(self._entDireBase:GetAbsOrigin(),    Vector(255, 255, 255), 0.5, self._nDireBaseRadius, false, 1)
			
			--testhud = CustomUI:DynamicHud_Create(-1, "0", "file://{resources}/layout/custom_game/soul_wars_ingame_status.xml", nil)
			--CustomGameEventManager:Send_ServerToAllClients( "sw_avatar_test", {text = "Hello"} )
			--
		end

		
		-- single shot events
		if self._bGameEventsCompleted == false then
		
			-- Spawn each team's Roshan
			self._avatarRadiant:Begin()
			self._avatarDire:Begin()
				
			-- spawn the vision giving dummy units
			self:_SpawnDummy(Vector(5680, 5800, -128), 	"dummy_vision", 550, DOTA_TEAM_BADGUYS)
			self:_SpawnDummy(Vector(5320, 5440, 0), 	"dummy_vision", 550, DOTA_TEAM_BADGUYS)
			self:_SpawnDummy(Vector(4950, 5070, 128), 	"dummy_vision", 1000, DOTA_TEAM_BADGUYS)
			
			self:_SpawnDummy(Vector(-6135, -6035, -128), 	"dummy_vision", 550, DOTA_TEAM_GOODGUYS)
			self:_SpawnDummy(Vector(-5825, -5695, 0), 		"dummy_vision", 550, DOTA_TEAM_GOODGUYS)
			self:_SpawnDummy(Vector(-5430, -5295, 128), 	"dummy_vision", 1000, DOTA_TEAM_GOODGUYS)
			
			self:_SpawnDummy(self._entDireBase:GetAbsOrigin(), 		"dummy_vision", 1500, DOTA_TEAM_BADGUYS)
			self:_SpawnDummy(self._entRadiantBase:GetAbsOrigin(), 	"dummy_vision", 1500, DOTA_TEAM_GOODGUYS)
			
			-- don't trigger these again.
			self._bGameEventsCompleted = true
		end
		
		-- do the spawner thinking
		for _, spawner in pairs(self._vSpawners) do
			spawner:Think()
		end
		
		self._avatarRadiant:Think()
		self._avatarDire:Think()
		
		-- check for any enemies in teams bases
		local entHerosInRadiantBase = Entities:FindAllByClassnameWithin("npc_dota_hero*", self._entRadiantBase:GetAbsOrigin(), self._nRadiantBaseRadius)
		local entHerosInDireBase    = Entities:FindAllByClassnameWithin("npc_dota_hero*", self._entDireBase:GetAbsOrigin(), self._nDireBaseRadius)
		
		for _, hero in pairs(entHerosInRadiantBase) do
			if hero:GetTeam() == DOTA_TEAM_BADGUYS then 
				--print("Found Dire hero in radiant base!")
				FindClearSpaceForUnit(hero, self._vRadiantBaseTeleport, false)
				hero:Stop()
				SendToConsole("dota_camera_center")
			elseif hero:GetTeam() == DOTA_TEAM_GOODGUYS then				
				hero:Heal(50, hero)
				hero:GiveMana(50)
			end
		end
		
		for _, hero in pairs(entHerosInDireBase) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				--print("Found Radiant hero in dire base!")
				FindClearSpaceForUnit(hero, self._vDireBaseTeleport, false)
				hero:Stop()
				SendToConsole("dota_camera_center")
			elseif hero:GetTeam() == DOTA_TEAM_BADGUYS then				
				hero:Heal(50, hero)
				hero:GiveMana(50)
			end
		end
		
		
		--KING OF THE HILL LOGIC
		
		-- get the monolith location and find all entities within 1000 units
		local entsInCaptureRadius = Entities:FindAllByClassnameWithin("npc_dota_hero*", self._vMonolithVector, self._nKOTHCaptureRadius)
		local entsInHandinRadius = Entities:FindAllByClassnameWithin("npc_dota_hero*", self._vMonolithVector, self._nKOTHHandinRadius)
		
		local radiantCount = 0
		local direCount = 0
		local winningTeam = 0
		
		-- count the number of units near the monolith
		for k, ent in pairs(entsInCaptureRadius) do
			if ent:IsRealHero() and ent:IsAlive() then
				if ent:GetTeam() == 2 then
					radiantCount = radiantCount + 1
				elseif ent:GetTeam() == 3 then
					direCount = direCount + 1 
				end
			end		
		end
		
		local oldMonolithState = self._KOTHMonolithState
				
		-- swing the meter depending by the difference in bodies
		self._KOTHMonolithState = self._KOTHMonolithState + radiantCount - direCount
		if self._KOTHMonolithState < (self._nKOTHMonolithMax * -1) then
			self._KOTHMonolithState = (self._nKOTHMonolithMax * -1)
		end
		if self._KOTHMonolithState > (self._nKOTHMonolithMax) then
			self._KOTHMonolithState = (self._nKOTHMonolithMax)
		end
		
		-- State one: Nobody owns the monolith
		if self._bRadiantOwnsMonolith == false and self._bDireOwnsMonolith == false then
			
			-- Check if the monolith state is above the radiant threshold
			if self._KOTHMonolithState >= self._nKOTHMonolithThreshold then
				self._bRadiantOwnsMonolith = true
				winningTeam = 2
				self:_RadiantKOTHTrigger()
			end
			
			-- Check if the monolith state is below the dire threshold
			if self._KOTHMonolithState <= (self._nKOTHMonolithThreshold * -1) then
				self._bDireOwnsMonolith = true
				winningTeam = 3
				self:_DireKOTHTrigger()
			end
			
			-- Otherwise it's between the two, so leave it alone
			
			
		-- State Two: Radiant owns the monolith
		elseif self._bRadiantOwnsMonolith == true and self._bDireOwnsMonolith == false then
			
			--Default to radiant having ownership
			winningTeam = 2
			
			-- Check if the state is below zero (the threshold to lose control of the monolith
			if self._KOTHMonolithState <= 0 then
				self._bRadiantOwnsMonolith = false		
				winningTeam = 0		
				self:_DefaultKOTHTrigger()
			end
				
			-- Check if the state is below the dire threshold
			if self._KOTHMonolithState <= (self._nKOTHMonolithThreshold * -1) then
				self._bDireOwnsMonolith = true
				winningTeam = 3
				self:_DireKOTHTrigger()
			end
			
			-- otherwise it's still above zero - and in radiant's control
			
		-- State Three: Dire owns the monolith	
		elseif self._bDireOwnsMonolith == true and self._bRadiantOwnsMonolith == false then
			
			--Default to dire having ownership
			winningTeam = 3
			
			-- check if the state is above zero (the threshold to lose control of the monolith)
			if self._KOTHMonolithState >= 0 then
				self._bDireOwnsMonolith = false
				winningTeam = 0		
				self:_DefaultKOTHTrigger()
			end
		
			-- Check if the state is above the radiant threshold
			if self._KOTHMonolithState >= self._nKOTHMonolithThreshold then
				self._bRadiantOwnsMonolith = true
				winningTeam = 2
				self:_RadiantKOTHTrigger()
			end
			
		else
			-- Some invalid state (both true somehow?)
			-- set owner to false
			print("Invalid Monolith State")
			self._bRadiantOwnsMonolith = false
			self._bDireOwnsMonolith = false
			self._KOTHMonolithState = 0
		
			self:_DefaultKOTHTrigger()
		end
		
		-- Debug
		if oldMonolithState ~= self._KOTHMonolithState then
			--print("Monolith State: " .. self._KOTHMonolithState)
			FireGameEvent("sw_update_monolith_state", {monolith_state = self._KOTHMonolithState, monolith_max = self._nKOTHMonolithMax, monolith_thresh = self._nKOTHMonolithThreshold, radiant_owns_monolith = self._bRadiantOwnsMonolith, dire_owns_monolith = self._bDireOwnsMonolith, num_radiant_capturing = radiantCount, num_dire_capturing = direCount})

		end
		
		local oldRadScore = self._nRadiantSoulCount
		local oldDireScore = self._nDireSoulCount
		
		-- Take any souls from the winning team and add it to their score
		-- Also do some bonus things in here - Heal 10 to any units on the winning team
		-- if they've got max ownership
		
		for k, ent in pairs(entsInHandinRadius) do
			if ent:IsRealHero() and ent:GetTeam() == winningTeam then
				--DebugDrawLine(self._vMonolithVector, ent:GetAbsOrigin(), 0, 0, 255, false, 1)
				
				if winningTeam == 2 then
					self._nRadiantSoulCount = self._nRadiantSoulCount + ent:GetModifierStackCount("modifier_soul_shard_count", ent)
					
					-- check for maximum positive monolith state
					if self._KOTHMonolithState == self._nKOTHMonolithMax then
						ent:Heal(20,self._entMonolith)
						ent:GiveMana(10)
					end
					
				elseif winningTeam == 3 then
					self._nDireSoulCount = self._nDireSoulCount + ent:GetModifierStackCount("modifier_soul_shard_count", ent)
					
					-- check for maximum negative monolith state
					if self._KOTHMonolithState == (self._nKOTHMonolithMax * -1) then
						ent:Heal(20,self._entMonolith)
						ent:GiveMana(10)
					end
				end
				ent:SetModifierStackCount("modifier_soul_shard_count", ent, 0)
				
			end
		end
		
		-- if the scores have changed
		if self._nRadiantSoulCount ~= oldRadScore or self._nDireSoulCount ~= oldDireScore then

			local level =  self._nAvatarStartingLevel - math.floor(self._nDireSoulCount / self._nAvatarSoulDivider)
			local scale = level / 20
			if level < 1 then level = 1	end			
			if scale < 1 then scale = 1 end
			self._avatarRadiant:SetScale(scale)
			self._avatarRadiant:ChangeLevel(level)
			print("Set Radiant Avatar to Level " .. level)
			
			level = self._nAvatarStartingLevel - math.floor(self._nRadiantSoulCount / self._nAvatarSoulDivider)
			local scale = level / 20
			if level < 1 then level = 1	end			
			if scale < 1 then scale = 1 end
			self._avatarDire:SetScale(scale)			
			self._avatarDire:ChangeLevel(level)
			print("Set Dire Avatar to Level " .. level)
				
			FireGameEvent("sw_radiant_update_soul_score", {soul_score = self._nRadiantSoulCount})
			FireGameEvent("sw_dire_update_soul_score", {soul_score = self._nDireSoulCount})
			--print("(" .. GameRules:GetGameTime() .. ") " .. self._nRadiantSoulCount .. " Radiant - Dire " .. self._nDireSoulCount)
		end
	
	FireGameEvent("sw_radiant_update_avatar", {health_percent = self._avatarRadiant:GetHealthPerc(), avatar_level = self._avatarRadiant:GetLevel()})
	FireGameEvent("sw_dire_update_avatar", {health_percent = self._avatarDire:GetHealthPerc(), avatar_level = self._avatarDire:GetLevel()})
	
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end
	
	return 1
end

function CSoulWarsGameMode:_DefaultKOTHTrigger()
	local activator = Entities:FindByClassnameNearest("npc_dota_hero*", self._vMonolithVector, self._nKOTHCaptureRadius)
	local caller = self._trigDefaultMonolithState
	
	DoEntFire("WorldLayer_DefaultMonolithState", 	"ShowWorldLayerAndSpawnEntities", "", 0.0,   activator, caller)
	DoEntFire("WorldLayer_RadiantMonolithState", 	"HideWorldLayerAndDestroyEntities", "", 0.0, activator, caller)
	DoEntFire("WorldLayer_DireMonolithState", 		"HideWorldLayerAndDestroyEntities", "", 0.0, activator, caller)
	
	print("Default Monolith State triggered")
end

function CSoulWarsGameMode:_RadiantKOTHTrigger()
	local activator = Entities:FindByClassnameNearest("npc_dota_hero*", self._vMonolithVector, self._nKOTHCaptureRadius)
	local caller = self._trigRadiantMonolithState
	
	DoEntFire("WorldLayer_DefaultMonolithState", 	"HideWorldLayerAndDestroyEntities", "", 0.0, activator, caller)
	DoEntFire("WorldLayer_RadiantMonolithState", 	"ShowWorldLayerAndSpawnEntities", "", 0.0,   activator, caller)
	DoEntFire("WorldLayer_DireMonolithState", 		"HideWorldLayerAndDestroyEntities", "", 0.0, activator, caller)
	
	print("Default Radiant State triggered")
	
	self:_SpawnDummy(Vector(-192, 448, 256), "monolith_crowd_radiant_creep", 0, DOTA_TEAM_GOODGUYS)
end
			
function CSoulWarsGameMode:_DireKOTHTrigger()
	local activator = Entities:FindByClassnameNearest("npc_dota_hero*", self._vMonolithVector, self._nKOTHCaptureRadius)
	local caller = self._trigDireMonolithState
	
	DoEntFire("WorldLayer_DefaultMonolithState", 	"HideWorldLayerAndDestroyEntities", "", 0.0, activator, caller)
	DoEntFire("WorldLayer_RadiantMonolithState", 	"HideWorldLayerAndDestroyEntities", "", 0.0, activator, caller)
	DoEntFire("WorldLayer_DireMonolithState", 		"ShowWorldLayerAndSpawnEntities", "", 0.0,   activator, caller)
	
	print("Default Dire State triggered")
	
	self:_SpawnDummy(Vector(-192, 448, 256), "monolith_crowd_dire_creep", 0, DOTA_TEAM_BADGUYS)
end
				
function CSoulWarsGameMode:_Test(cmdname)
			
end