require("util")

function MyFunction(trigger)
	print(trigger.activator:GetClassname())
	print(trigger.caller:GetClassname())	
end