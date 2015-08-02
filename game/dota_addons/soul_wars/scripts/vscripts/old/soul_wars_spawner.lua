--[[
	CSoulWarsGameSpawner - A Class to manage a spawn point for Soul Wars
]]
if CSoulWarsGameSpawner == nil then
	CSoulWarsGameSpawner = class({})
end


function CSoulWarsGameSpawner:ReadConfiguration( name, kv )
	self._szName = name
	self._szNPCClassName = kv.NPCName or ""

	self._nCreatureLevel 	= tonumber( kv.CreatureLevel or 1 )
	self._nMinUnits 		= tonumber( kv.MinUnits or 8 )
	self._nUnitsPerSpawn 	= tonumber( kv.UnitsPerSpawn or 1 )
	self._nWaypointVariation = tonumber( kv.WaypointVariation or 450)
	
	self._flInitialSpawnTime 	= tonumber( kv.InitialWait or 0 )
	self._flFinalSpawnTime 	= tonumber( kv.FinalSpawn or -1 )
	
	self._flMoveIntervalMin	= tonumber( kv._flMoveIntervalMin or 3 )
	self._flMoveIntervalMax	= tonumber( kv._flMoveIntervalMax or 10 )
	
	self._entWaypoints = {}
	self._nWaypoints = 0
	
	for _, wp_file in pairs(kv.Waypoints) do
		local wp_list = LoadKeyValues( "scripts/maps/" .. GetMapName() .. wp_file .. ".txt" )
		wp_list = wp_list or {}
		
		for key, val in pairs(wp_list) do
			table.insert(self._entWaypoints, Entities:FindByName(nil, val))
			self._nWaypoints = self._nWaypoints + 1
		end
	end
end

function CSoulWarsGameSpawner:Precache()
	PrecacheUnitByNameAsync( self._szNPCClassName, function( sg ) self._sg = sg end )
end


function CSoulWarsGameSpawner:Begin()
	-- Initialise some variables to keep track
	-- of how many units we've spawned,
	-- and how many are alive
	self._nUnitsSpawned = 0
	self._nUnitsCurrentlyAlive = 0
	self._vUnitList = {}
		
	self._flNextMoveTime = -1
		
	--print("Loaded " .. self._nWaypoints .. " waypoints")
	--print(self._szName .. ". "  .. self._nWaypoints .. " waypoints, Starting spawning at " .. self._flInitialSpawnTime)
end

function CSoulWarsGameSpawner:Think()

	-- check through the entity list to make sure they still exist
	for _, ent in pairs(self._vUnitList) do
		--print("[".. self._szName .. "] Entity: " .. _)
		if ent:IsNull() or not ent:IsAlive() then
			table.remove(self._vUnitList,_)
			self._nUnitsCurrentlyAlive = self._nUnitsCurrentlyAlive - 1
		end
	end
	
	if GameRules:GetDOTATime(false, false) >= self._flInitialSpawnTime  then 
			
		if self._flNextMoveTime == -1 then
			self._flNextMoveTime = GameRules:GetDOTATime(false, false) + math.random(self._flMoveIntervalMin, self._flMoveIntervalMax)
		end
			
		-- check if we have to move any units around
		if GameRules:GetDOTATime(false, false) >= self._flNextMoveTime then
		
			local randUnit = math.random(self._nUnitsCurrentlyAlive)
			--local unitToMove = self._vUnitList[tostring(randUnit)]
			local unitToMove = self._vUnitList[randUnit]
			
			if unitToMove == nil then
				--print("Dud unit selected")
			else
				--print("Moving unit")		
				unitToMove:MoveToPosition(self:_GetRandomWaypointVector())
			end
			
			self._flNextMoveTime = GameRules:GetDOTATime(false, false) + math.random(self._flMoveIntervalMin, self._flMoveIntervalMax)
		end
	end
	
	-- check if we've waited long enough to start spawning
	if GameRules:GetDOTATime(false, false) >= self._flInitialSpawnTime and (self._flFinalSpawnTime == -1 or GameRules:GetDOTATime(false, false) <= self._flFinalSpawnTime) then

		-- check if the required number of units are alive
		if self._nUnitsCurrentlyAlive < self._nMinUnits then
			for i = 1,self._nUnitsPerSpawn do
				self:_DoSpawn()
			end
		end

	end
end

function CSoulWarsGameSpawner:_DoSpawn()
	local targetSpawnLocation = self:_GetRandomWaypointVector()
	local entUnit = CreateUnitByName( self._szNPCClassName, targetSpawnLocation, true, nil, nil, DOTA_TEAM_NEUTRALS )
	
	if entUnit then
		entUnit:CreatureLevelUp( self._nCreatureLevel - 1 )
		entUnit:SetIdleAcquire(false)
		--entUnit:AddNewModifier(entUnit, nil, "modifier_phased", nil)
		self._nUnitsSpawned = self._nUnitsSpawned + 1
		self._nUnitsCurrentlyAlive = self._nUnitsCurrentlyAlive + 1
		table.insert(self._vUnitList, entUnit)
	else
		print("Spawned unit failed!")
	end
end

function CSoulWarsGameSpawner:_GetRandomWaypointVector()
	local max_wp = self._nWaypoints
	local random_wp = math.random(max_wp)
	--print('Entity going to waypoint: ' .. random_wp)
	
	local wp =  self._entWaypoints[random_wp]
	if wp == nil then
		print("Waypoint " .. random_wp .. " not found...")
		wp = self._entWaypoints[1]
	end
	ao = wp:GetAbsOrigin()
	
	ao[1] = math.random(ao[1] - self._nWaypointVariation, ao[1] + self._nWaypointVariation)
	ao[2] = math.random(ao[2] - self._nWaypointVariation, ao[2] + self._nWaypointVariation)
	return ao
end

function CSoulWarsGameSpawner:StatusReport()
	print( " ** " .. self._szName .. " - " .. self._nUnitsSpawned .. " units spawned")
end