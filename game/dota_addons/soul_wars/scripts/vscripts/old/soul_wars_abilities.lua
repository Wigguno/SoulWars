--[[
	Soul Wars Abilities - A lua script to handle custom scripted abilities
--]]
require( "timers" ) 

function itemBarricade(keys)
	local caster = keys.caster
	-- click location
	local vecLocation = keys.target_points[1]
	local castLocation = caster:GetAbsOrigin()
	
	-- work out what angle to set it up at
	local dx = castLocation[1] - vecLocation[1]
	local dy = vecLocation[2] - castLocation[2]
	
	castAngle = math.deg(math.atan2(dx, dy)) + 90
	
	--print("Placing barricade at " .. castAngle .. " Degrees")
	
	-- these statements produce oppositely sided units	
	--[[
	if caster:GetTeam() == DOTA_TEAM_GOODGUYS then
		team = DOTA_TEAM_BADGUYS
	else
		team = DOTA_TEAM_GOODGUYS
	end
	barricade = CreateUnitByName( "npc_sw_barricade", vecLocation, false, caster, caster, team  )
	--]]
	
	-- This line produces correctly sided units
	barricade = CreateUnitByName( "npc_sw_barricade", vecLocation, false, caster, caster, caster:GetTeam()  )
	
	FindClearSpaceForUnit(caster, castLocation, false)
	barricade:SetControllableByPlayer(caster:GetPlayerID(), true)
	barricade:AddNewModifier(caster, nil, "modifier_kill", {duration = 90})
	
	-- use a timer with a callback to set the angles (some timing bug)
	Timers:CreateTimer({
		callback = function()			
			barricade:SetAngles(0.0, castAngle, 0.0)
			barricade:SetMoveCapability(DOTA_UNIT_CAP_MOVE_NONE)
		end
	})
	
	--Check if any units are stuck inside the fence
	-- DebugDrawSphere(Location, Colour Vector(R, G, B), alpha, radius, ztest(??), duration )
	--DebugDrawSphere(barricade:GetAbsOrigin(), Vector(0, 0, 0), 255, 220, false, 20)
	local stuckHeros = Entities:FindAllByClassnameWithin("npc_dota_hero*", barricade:GetAbsOrigin(), 220 )	
	
	for _, hero in pairs(stuckHeros) do
		hero:AddNewModifier(hero, nil, "modifier_phased", nil)
		Timers:CreateTimer({
			callback = function()
				if not barricade:IsNull() and vDist(hero:GetAbsOrigin(), barricade:GetAbsOrigin()) <= 220 then
					return 0.1
				else
					hero:RemoveModifierByName("modifier_phased")
					return nil
				end
			end
		})
	
	end
end

function vDist(v1 ,v2)
	return math.sqrt(math.pow(v1[1] - v2[1], 2) + math.pow(v1[2] - v2[2], 2))
end

function abilityBarricadeDestruct(keys)
	keys.caster:ForceKill(true)
end

function abilityBarricadeDying(keys)
	--print("Barricade Dying!")
end

function heroAttackStart(keys)
	--print("Hero Started Attack!")
	local avatarAttackRadius = 800
	local direAvatarCenter = Entities:FindByName(nil, "roshan_spawner_dire")
	local radiantAvatarCenter = Entities:FindByName(nil, "roshan_spawner_radiant")
	
	local direDist = vDist(keys.attacker:GetAbsOrigin(), direAvatarCenter:GetAbsOrigin())
	local radiantDist = vDist(keys.attacker:GetAbsOrigin(), radiantAvatarCenter:GetAbsOrigin())
	
	if keys.target:GetUnitName() == "npc_soul_wars_avatar" and direDist > avatarAttackRadius and radiantDist > avatarAttackRadius then
		keys.attacker:Stop()
	
	end
end

function heroDie(keys)
end