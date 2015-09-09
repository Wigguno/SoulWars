"use strict";

var localPID;
var localHero;


// Update the control point bar
function OnHUDUpdate( table_name, key, data )
{
	//$.Msg( "Table ", table_name, " changed: '", key, "' = ", data );
	if (key == "cp_state")
	{
		var val = data.value
		var radiant_width = val + 50;
		//$.Msg("Radiant Width: " + radiant_width);
		$("#SWHUDStatusBarRadiant").style.width = radiant_width + "%;";

		//$.Msg("Radiant Owned: " + data.radiantCaptured);
		//$.Msg("Dire Owned: " + data.direCaptured);

		if (Game.GetLocalPlayerInfo().player_team_id == DOTATeam_t.DOTA_TEAM_GOODGUYS)
			$("#SWHUDStatusBarText").text = radiant_width + "%";

		else if (Game.GetLocalPlayerInfo().player_team_id == DOTATeam_t.DOTA_TEAM_BADGUYS)
			$("#SWHUDStatusBarText").text = ( 100 - radiant_width) + "%";

		if (data.radiantCaptured == 1)
			$("#SWHUDStatusText").text = "Radiant Owned";
		else if (data.direCaptured == 1)
			$("#SWHUDStatusText").text = "Dire Owned";
		else
			$("#SWHUDStatusText").text = "Unowned";

		$("#StatusRowObeliskRadiant").text = radiant_width + "%";
		$("#StatusRowObeliskDire").text = (100 - radiant_width) + "%";

	}
	else if (key == "soul_count")
	{
		$("#StatusRowSoulCountRadiant").text = data.radiant_souls;
		$("#StatusRowSoulCountDire").text = data.dire_souls;
	}
	else if (key == "avatar_status")
	{
		$("#StatusRowAvatarLevelRadiant").text = "" + Math.ceil(data.radiant_avatar_level);
		$("#StatusRowAvatarLevelDire").text = "" +  Math.ceil(data.dire_avatar_level);

		$("#StatusRowAvatarHealthRadiant").text = data.radiant_avatar_health + "%";
		$("#StatusRowAvatarHealthDire").text = data.dire_avatar_health + "%";
	}
}

function OnCPUpdate(val)
{
	//$.Msg(keys);
}

function OnShowStatus()
{
	$("#SWHUDStatusHover").SetHasClass("SWHUDStatusHoverVisible", true);
}

function OnHideStatus()
{
	$("#SWHUDStatusHover").SetHasClass("SWHUDStatusHoverVisible", false);
}

(function () {
	$.Msg("Soul Wars HUD Panormama JS Loaded.");

	localPID = Players.GetLocalPlayer();
	localHero = Players.GetPlayerHeroEntityIndex(localPID);

	CustomNetTables.SubscribeNetTableListener( "soul_wars_state", OnHUDUpdate ); 
})();