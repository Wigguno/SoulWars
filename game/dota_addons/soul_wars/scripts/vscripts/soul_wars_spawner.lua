-- Soul Wars Spawner
-- By wigguno
-- http://steamcommunity.com/id/wigguno/

if SoulWarsSpawner == nil then
	_G.SoulWarsSpawner = class({})
end


function SoulWarsSpawner:Init( kv )

	-- Load some things from KV
	self.Name 			= kv.Name
	self.Creature 		= kv.Creature
	self.SoulCount 		= tonumber(kv.SoulCount)
	self.Count 			= tonumber(kv.Count)
	self.WanderBounds 	= kv.WanderBounds
	self.WanderMin 		= tonumber(kv.WanderMin)
	self.WanderMax 		= tonumber(kv.WanderMax)

	-- get X and Y coordinates from the strings
	if self.WanderBounds.Type == "Rect" then
		local coords = {}
		for word in self.WanderBounds.BL:gmatch("%S+") do table.insert(coords, word) end
		self.WanderBounds.BLx 	= tonumber(coords[1])
		self.WanderBounds.BLy 	= tonumber(coords[2])

		local coords = {}
		for word in self.WanderBounds.TR:gmatch("%S+") do table.insert(coords, word) end
		self.WanderBounds.TRx 	= tonumber(coords[1])
		self.WanderBounds.TRy 	= tonumber(coords[2])

	elseif self.WanderBounds.Type == "Circle" then
		local coords = {}
		for word in self.WanderBounds.Center:gmatch("%S+") do table.insert(coords, word) end
		self.WanderBounds.Cx 	= tonumber(coords[1])
		self.WanderBounds.Cy 	= tonumber(coords[2])

		self.WanderBounds.R 	= tonumber(self.WanderBounds.Radius)

	end

	-- Start some variables
	self.NumSpawned = 0
	self.NumAlive 	= 0

	self.CreatureList = {}

	-- check we got all required parameters
	if not self.Name or not self.Creature or not self.SoulCount or not self.Count or not self.WanderBounds then
		return false
	else
		return true
	end
end

function SoulWarsSpawner:Precache()
	-- precache our unit
	PrecacheUnitByNameAsync( self.Creature, function( sg ) self.pc = sg end )
end

function SoulWarsSpawner:GetRandomWaypoint()
	-- find a random waypoint within our Wander Bounds
	if self.WanderBounds.Type == "Rect" then
		local x = math.random(self.WanderBounds.BLx, self.WanderBounds.TRx)
		local y = math.random(self.WanderBounds.BLy, self.WanderBounds.TRy)
		local z = GetGroundHeight(Vector(x, y, 0), nil)
		return Vector(x, y, z)

	elseif self.WanderBounds.Type == "Circle" then
		local a = math.rad(math.random(360))
		local r = math.random(self.WanderBounds.R)

		local x = self.WanderBounds.Cx + (math.cos(a) * r)
		local y = self.WanderBounds.Cy + (math.sin(a) * r)
		local z = GetGroundHeight(Vector(x, y, 0), nil)
		return Vector(x, y, z)
	end
end

function SoulWarsSpawner:DoSpawn()
	-- Spawn a single unit
	local entUnit = CreateUnitByName( self.Creature, self:GetRandomWaypoint(), true, nil, nil, DOTA_TEAM_NEUTRALS )

	if entUnit then

		-- attach some variables to the entity
		entUnit.NextWander = GameRules:GetGameTime() + math.random(self.WanderMin, self.WanderMax)
		entUnit.SoulBounty = self.SoulCount
		entUnit.Attacking  = false

		entUnit:SetIdleAcquire(false)

		table.insert(self.CreatureList, entUnit)
	end
end


function SoulWarsSpawner:CheckLocation(creature)
	-- Check if the given creature is within this spawne1rs bounds

	local creature_loc = creature:GetAbsOrigin()

	if self.WanderBounds.Type == "Rect" then
		if creature_loc.x < self.WanderBounds.BLx or creature_loc.x > self.WanderBounds.TRx or creature_loc.y < self.WanderBounds.BLy or creature_loc.y > self.WanderBounds.TRy then
			return false
		else
			return true
		end

	elseif self.WanderBounds.Type == "Circle" then
		-- get the distance to the center of the circle
		-- and check the distances is not > the radius

		local wander_dist = (creature_loc - Vector(self.WanderBounds.Cx, self.WanderBounds.Cy, 128)):Length2D()
		if wander_dist > self.WanderBounds.R then
			return false
		else
			return true
		end
	end
end

function SoulWarsSpawner:Think()
	-- Thinker function, gets called from the main gamemode thinker
	-- ONLY RUN THIS ON THE SERVER
	if IsServer() then 
	
		-- check for any dead creatures and decrement the alive counter
		local deadcount = 0 -- Record how many are killed to index the array properly
		for _, creature in pairs(self.CreatureList) do
			if creature:IsNull() or not creature:IsAlive() then
				self.NumAlive = self.NumAlive - 1
				table.remove(self.CreatureList, _ - deadcount)
				deadcount = deadcount + 1

			elseif creature.Attacking == true then
				-- Part 2 of the manual creep aggression code
				-- Check if the creature has wandered out of bounds to de-aggro
				-- otherwise leave the creature attacking the target

				if not self:CheckLocation(creature) then
					creature.Attacking = false
					creature:MoveToPosition(self:GetRandomWaypoint())
					creature.NextWander = GameRules:GetGameTime() + math.random(self.WanderMin, self.WanderMax)
				end

			elseif GameRules:GetGameTime() > creature.NextWander then

				creature:MoveToPosition(self:GetRandomWaypoint())
				creature.NextWander = GameRules:GetGameTime() + math.random(self.WanderMin, self.WanderMax)
			end
		end

		if self.NumAlive < self.Count then
			self.NumAlive = self.NumAlive + 1
			self.NumSpawned = self.NumSpawned + 1
			self:DoSpawn()	
		end
	end
end

function SoulWarsSpawner:PrintStatus()
	print(self.Name 	.. " ----------------------")
	print("Spawned: " 	.. self.NumSpawned)
	print("Alive: " 	.. self.NumAlive)
end