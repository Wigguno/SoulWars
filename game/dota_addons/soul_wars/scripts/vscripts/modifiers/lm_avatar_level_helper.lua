--[[ lm_avatar_level_helper.lua ]]

lm_avatar_level_helper = class({})

modifier_table = {
	health_per_level 		= 1500,
	mana_per_level 			= 100,
	health_regen_per_level 	= 0.5,
	mana_regen_per_level 	= 0.5,
	damage_per_level 		= 15,
}

function lm_avatar_level_helper:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
		MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
	}
 
	return funcs
end

function lm_avatar_level_helper:OnCreated( keys )
	if IsServer() then
	end
	self.level = keys.stack_count
end

function lm_avatar_level_helper:IsHidden()
	return true 
end

function lm_avatar_level_helper:GetModifierExtraHealthBonus( keys )
	--print("GetModifierExtraHealthBonus")
	--PrintTable(keys)
	--print("level: " 	.. self.level)
	--print("HP Bonus: " 	.. self.level * modifier_table.health_per_level)
	--[[
	if IsServer() then
		return self.level * modifier_table.health_per_level
	end
	]]
	return self.level * modifier_table.health_per_level
end

function lm_avatar_level_helper:GetModifierExtraManaBonus( keys )
	--print("GetModifierExtraManaBonus")
	--PrintTable(keys)
	--print("level: " .. self.level)
	--print("Mana Bonus: " .. self.level * modifier_table.mana_per_level
	--[[
	if IsServer() then
		return self.level * modifier_table.mana_per_level
	end
	]]
	return self.level * modifier_table.mana_per_level
end

function lm_avatar_level_helper:GetModifierConstantHealthRegen( keys )
	--print("GetModifierConstantHealthRegen")
	--PrintTable(keys)
	--print("level: " 		.. self.level)
	--print("Health Regen: " 	.. self.level * modifier_table.health_regen_per_level)
	--[[
	if IsServer() then
		return self.level * modifier_table.health_regen_per_level
	end
	]]
	return self.level * modifier_table.health_regen_per_level
end

function lm_avatar_level_helper:GetModifierConstantManaRegen( keys )
	--print("GetModifierConstantManaRegen")
	--PrintTable(keys)
	--print("level: " 		.. self.level)
	--print("Mana Regen: " 	.. self.level * modifier_table.mana_regen_per_level)
	--[[
	if IsServer() then
		return self.level * modifier_table.mana_regen_per_level
	end
	]]
	return self.level * modifier_table.mana_regen_per_level
end

function lm_avatar_level_helper:GetModifierBaseAttack_BonusDamage( keys )
	--print("GetModifierBaseAttack_BonusDamage")
	--PrintTable(keys)
	--print("level: " 		.. self.level)
	--print("Base Damage: " 	.. self.level * modifier_table.damage_per_level)
	
	--[[
	if IsServer() then
		return self.level * modifier_table.damage_per_level
	end
	]]
	return self.level * modifier_table.damage_per_level
end

