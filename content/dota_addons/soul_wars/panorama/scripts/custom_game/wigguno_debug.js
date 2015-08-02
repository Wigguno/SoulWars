"use strict";
// Notifications for Overthrow
 
var fog_disabled = false;
var day_forced = false;
var night_forced = false;
var nav_on = false;

function OnToggleFog()
{
	//$.Msg("[Debug Menu] Fog Toggled");
	if (fog_disabled == true)
	{
		fog_disabled = false;
		$("#ButtonFogToggle").style.backgroundColor = "gradient( linear, 0% 0%, 0% 100%, from( red ), to( black ) );";
		GameEvents.SendCustomGameEventToServer( "toggle_fog", { "fogState" : 1 } );
	}
	else
	{
		fog_disabled = true;
		$("#ButtonFogToggle").style.backgroundColor = "gradient( linear, 0% 0%, 0% 100%, from( green ), to( black ) );";
		GameEvents.SendCustomGameEventToServer( "toggle_fog", { "fogState" : 0 } );
	}	 
} 

function OnToggleNav()
{
	//$.Msg("[Debug Menu] Nav Toggled");
	if (nav_on == true) 
	{
		nav_on = false;
		$("#ButtonDisplayNav").style.backgroundColor = "gradient( linear, 0% 0%, 0% 100%, from( red ), to( black ) );";
		GameEvents.SendCustomGameEventToServer( "toggle_nav", { "navState" : 0 } );
	}
	else
	{
	nav_on = true;
	$("#ButtonDisplayNav").style.backgroundColor = "gradient( linear, 0% 0%, 0% 100%, from( green ), to( black ) );";
	GameEvents.SendCustomGameEventToServer( "toggle_nav", { "navState" : 1 } );
	}	 
} 


function OnForceDay()
{
	//$.Msg("[Debug Menu] Force Day");
	if (day_forced == false) 
	{
		day_forced = true;
		night_forced = false;
		$("#ButtonForceDay").style.backgroundColor 	= "gradient( linear, 0% 0%, 0% 100%, from( green ), to( black ) );";
		$("#ButtonForceNight").style.backgroundColor 	= "gradient( linear, 0% 0%, 0% 100%, from( red ), to( black ) );";
		GameEvents.SendCustomGameEventToServer( "force_day", { "ForceDay" : 1 });
	}
	else
	{
		day_forced = false;
		$("#ButtonForceDay").style.backgroundColor 	= "gradient( linear, 0% 0%, 0% 100%, from( red ), to( black ) );";
		GameEvents.SendCustomGameEventToServer( "toggle_nav", { "navState" : 0 } );
	}	 
} 

function OnForceNight()
{
	// $.Msg("[Debug Menu] Force Night");
	if (night_forced == false) 
	{
		night_forced = true;
		day_forced = false;
		$("#ButtonForceNight").style.backgroundColor 	= "gradient( linear, 0% 0%, 0% 100%, from( green ), to( black ) );";
		$("#ButtonForceDay").style.backgroundColor 	= "gradient( linear, 0% 0%, 0% 100%, from( red ), to( black ) );";
		GameEvents.SendCustomGameEventToServer( "force_night", { "ForceNight" : 1 });
	}
	else
	{
		night_forced = false;
		$("#ButtonForceNight").style.backgroundColor 	= "gradient( linear, 0% 0%, 0% 100%, from( red ), to( black ) );";
		GameEvents.SendCustomGameEventToServer( "force_night", { "ForceNight" : 0 } );
	}	 
} 
 
function OnRegenForest()
{
	GameEvents.SendCustomGameEventToServer( "regen_forest", {} );
} 
 
function OnRemoveForest()
{
	GameEvents.SendCustomGameEventToServer( "remove_forest", {} );
} 

function GenerateGreevil()
{
	GameEvents.SendCustomGameEventToServer( "generate_ai_greevil", {} );
} 
 
function ReloadKV()
{
	GameEvents.SendCustomGameEventToServer( "reload_kv", {} );
 
}

function WraithCreep()
{
	GameEvents.SendCustomGameEventToServer( "wraithify_creep", {})
}

function ToggleMenu()
{
	$("#DebugMenuContainer").SetHasClass("DebugMenuEnabled", !($("#DebugMenuContainer").BHasClass("DebugMenuEnabled")))
}

function EnableDebugMenu(data)
{
	if (data["enable"] == "true")
	{
		$("#DebugMenuContainer").SetHasClass("DebugMenuEnabled", true);
	}
	else
	{
		$("#DebugMenuContainer").SetHasClass("DebugMenuEnabled", false);
	}
}

(function () {	
	GameEvents.Subscribe( "debug_menu_enable", EnableDebugMenu );
})();

