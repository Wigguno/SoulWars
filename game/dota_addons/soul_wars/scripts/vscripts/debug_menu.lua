-- Panorama Debug Menu
-- By wigguno
-- http://steamcommunity.com/id/wigguno/


if DebugMenu == nil then
	_G.DebugMenu = class({})
end

function DebugMenu:Enable()
	self.eventToggleFog 	= CustomGameEventManager:RegisterListener("toggle_fog", function( ... ) return self:OnFogToggle( ... ) end)
	self.eventForceDay 		= CustomGameEventManager:RegisterListener("force_day", function( ... ) return self:OnForceDay( ... ) end)
	self.eventForceNight 	= CustomGameEventManager:RegisterListener("force_night", function( ... ) return self:OnForceNight( ... ) end)
	self.eventToggleNav 	= CustomGameEventManager:RegisterListener("toggle_nav", function( ... ) return self:OnToggleNav( ... ) end)
	self.eventClose 		= CustomGameEventManager:RegisterListener("close_debug", function( ... ) return self:Disable( ... ) end)
	
	self.DayNightForced = false
	self.DayNightState = ""
	self.ThinkerTime = 1
	
	GameRules:GetGameModeEntity():SetThink( "DayNightThinker", self, "DayNightThinker", 1 )
	CustomGameEventManager:Send_ServerToAllClients("debug_menu_enable",{enable="true"})
end

function DebugMenu:Disable()
	CustomGameEventManager:UnregisterListener(self.eventToggleFog)
	CustomGameEventManager:UnregisterListener(self.eventForceDay)
	CustomGameEventManager:UnregisterListener(self.eventForceNight)	
	CustomGameEventManager:UnregisterListener(self.eventToggleNav)
	CustomGameEventManager:UnregisterListener(self.eventClose)
	
	self.ThinkerTime = nil
	CustomGameEventManager:Send_ServerToAllClients("debug_menu_enable",{enable="false"})
end

function DebugMenu:DayNightThinker()
	if self.DayNightForced == true then
		timeofday = GameRules:GetTimeOfDay()
		if self.DayNightState == "Day" then
			if not GameRules:IsDaytime() then
				GameRules:SetTimeOfDay(0.26)
			end
		
		elseif self.DayNightState == "Night" then
			if GameRules:IsDaytime() then
				GameRules:SetTimeOfDay(0.76)
			end
		end
	end
	return self.ThinkerTime
end

function DebugMenu:OnFogToggle( eventSourceIndex, args )
	local mode = GameRules:GetGameModeEntity() 
	if args.fogState == 0 then
		mode:SetFogOfWarDisabled(true)	
	else
		mode:SetFogOfWarDisabled(false)	
	end
end

function DebugMenu:OnForceDay( eventSourceIndex, args )
	if args.ForceDay == 1 then
		if self.DayNightForced == false then
			self.DayNightForced = true
		end
		self.DayNightState = "Day"
	else
		self.DayNightForced = false	
	end
end

function DebugMenu:OnForceNight( eventSourceIndex, args )
	if args.ForceNight == 1 then
		if self.DayNightForced == false then
			self.DayNightForced = true
		end
		self.DayNightState = "Night"
	else
		self.DayNightForced = false	
	end	
end

function DebugMenu:OnToggleNav( eventSourceIndex, args )
	if args.navState == 1 then		
		SendToConsole("dota_gridnav_show 1")	
	else
		SendToConsole("dota_gridnav_show 0")
	end

end