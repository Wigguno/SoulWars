"use strict";


// Update the control point bar
function OnHUDUpdate( table_name, key, data )
{
	$.Msg( "Table ", table_name, " changed: '", key, "' = ", data );
	if (key == "cp_state")
		OnCPUpdate(data.value);
}

function OnCPUpdate(val)
{
	//$.Msg(keys);
	var radiant_width = val + 50;
	var dire_width = (val - 50) * -1;

	$("#SWHUDMonolithRadiant").style.width = "".concat(radiant_width, "%;")
	$("#SWHUDMonolithDire").style.width = "".concat(dire_width, "%;")
}

(function () {
	$.Msg("Soul Wars HUD Panormama JS Loaded.");
	GameEvents.Subscribe( "control_point_update", OnCPUpdate );
	CustomNetTables.SubscribeNetTableListener( "soul_wars_state", OnHUDUpdate );
})();