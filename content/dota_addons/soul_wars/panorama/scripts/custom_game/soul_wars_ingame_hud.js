"use strict";


// Update the control point bar
function OnHUDUpdate( table_name, key, data )
{
	//$.Msg( "Table ", table_name, " changed: '", key, "' = ", data );
	if (key == "cp_state")
	{
		var val = data.value
		var radiant_width = val + 50;
		var dire_width = (val - 50) * -1;
		//$.Msg("Radiant Width: " + radiant_width);
		$("#MonolithRadiant").style.transform = "scaleX(" + (radiant_width * 10) + ");";

		$("#AvatarObeliskInfoRadiant").text = "OB " + radiant_width + "%";
		$("#AvatarObeliskInfoDire").text = "OB " + dire_width + "%";
	}
	else if (key == "soul_count")
	{
		$("#AvatarSoulInfoRadiant").text = data.radiant_souls;
		$("#AvatarSoulInfoDire").text = data.dire_souls;
	}
	else if (key == "avatar_status")
	{
		$("#AvatarLevelInfoRadiant").text = "Lvl " + Math.ceil(data.radiant_avatar_level);
		$("#AvatarHealthInfoRadiant").text = "HP " + data.radiant_avatar_health + "%";
		$("#AvatarLevelInfoDire").text = "Lvl " +  Math.ceil(data.dire_avatar_level);
		$("#AvatarHealthInfoDire").text = "HP " + data.dire_avatar_health + "%";

		$("#AvatarLevelTextRadiant").text = Math.ceil(data.radiant_avatar_level);
		$("#AvatarLevelTextDire").text = Math.ceil(data.dire_avatar_level);
	}
}

function OnCPUpdate(val)
{
	//$.Msg(keys);
}

(function () {
	$.Msg("Soul Wars HUD Panormama JS Loaded.");
	CustomNetTables.SubscribeNetTableListener( "soul_wars_state", OnHUDUpdate ); 
})();