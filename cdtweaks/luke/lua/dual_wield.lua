-- cdtweaks, dual-wield feat for rangers: Force the targeted creature to wield light armors (or no armor) in order to benefit from Two-Weapon Style --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual penalty
	local apply = function(spriteProficiency2Weapon)
		-- Update var
		sprite:setLocalInt("cdtweaksDualWieldHelper", spriteProficiency2Weapon)
		--
		local stylbonu = GT_Resource_2DA["stylbonu"]
		local maxThac0RightPenalty = tonumber(stylbonu["TWOWEAPON-0"]["THAC0_RIGHT"])
		local maxThac0LeftPenalty = tonumber(stylbonu["TWOWEAPON-0"]["THAC0_LEFT"])
		local curThac0RightPenalty = tonumber(stylbonu[string.format("TWOWEAPON-%s", spriteProficiency2Weapon)]["THAC0_RIGHT"])
		local curThac0LeftPenalty = tonumber(stylbonu[string.format("TWOWEAPON-%s", spriteProficiency2Weapon)]["THAC0_LEFT"])
		-- Mark the creature as 'malus applied'
		sprite:setLocalInt("cdtweaksDualWield", 1)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["durationType"] = 1,
			["res"] = "CDDLWLD",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 306, -- Main-hand THAC0 bonus
			["durationType"] = 9,
			["effectAmount"] = curThac0RightPenalty - maxThac0RightPenalty,
			["m_sourceRes"] = "CDDLWLD",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 305, -- Off-hand THAC0 bonus
			["durationType"] = 9,
			["effectAmount"] = curThac0LeftPenalty - maxThac0LeftPenalty,
			["m_sourceRes"] = "CDDLWLD",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 142, -- Display portrait icon
			["durationType"] = 9,
			["dwFlags"] = %feedback_icon%,
			["m_sourceRes"] = "CDDLWLD",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's equipment / class
	local equipment = sprite.m_equipment
	local selectedItem = equipment.m_items:get(equipment.m_selectedWeapon)
	local itemHeader = selectedItem.pRes.pHeader
	--
	local mainHandFlags = itemHeader.itemFlags
	local itemAbility = EEex_Resource_GetItemAbility(itemHeader, equipment.m_selectedWeaponAbility) -- Item_ability_st
	local mainHandAbilityType = itemAbility.type
	--
	local items = sprite.m_equipment.m_items -- Array<CItem*,39>
	--
	local armor = items:get(1) -- CItem (index from "slots.ids")
	local armorTypeStr = nil
	local armorAnimation = nil
	if armor then -- if the character is equipped with an armor...
		local itemHeader = armor.pRes.pHeader -- Item_Header_st
		armorTypeStr = GT_Resource_IDSToSymbol["itemcat"][itemHeader.itemType]
		armorAnimation = EEex_CastUD(itemHeader.animationType, "CResRef"):get() -- certain engine types are nonsensical. We usually create fixups for the bindings whenever we run into them. We'll need to cast the value to properly read them
	end
	--
	local offHand = items:get(9) -- CItem (index from "slots.ids")
	local offHandTypeStr = nil
	if offHand then
		local itemHeader = offHand.pRes.pHeader -- Item_Header_st
		offHandTypeStr = GT_Resource_IDSToSymbol["itemcat"][itemHeader.itemType]
	end
	--
	local spriteClassStr = GT_Resource_IDSToSymbol["class"][sprite.m_typeAI.m_Class]
	--
	local itemflag = GT_Resource_SymbolToIDS["itemflag"]
	--
	local spriteFlags = sprite.m_baseStats.m_flags
	--
	local spriteLevel1 = sprite.m_derivedStats.m_nLevel1
	local spriteLevel2 = sprite.m_derivedStats.m_nLevel2
	-- If the Ranger is dual-wielding and is equipped with medium or heavy armor...
	local applyCondition = EEex_BAnd(mainHandFlags, itemflag["TWOHANDED"]) == 0
		and mainHandAbilityType == 1 -- type: melee
		and offHand and offHandTypeStr ~= "SHIELD"
		and armor and armorTypeStr == "ARMOR" and (armorAnimation == "3A" or armorAnimation == "4A")
		and (spriteClassStr == "RANGER"
			-- incomplete dual-class characters are not supposed to benefit from Dual-Wield
			or (spriteClassStr == "CLERIC_RANGER" and (EEex_IsBitUnset(spriteFlags, 0x8) or spriteLevel1 > spriteLevel2)))
		and EEex_IsBitUnset(spriteFlags, 10) -- not Fallen Ranger
	--
	if sprite:getLocalInt("cdtweaksDualWield") == 0 then
		if applyCondition then
			apply(sprite.m_derivedStats.m_nProficiency2Weapon) -- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
		end
	else
		if applyCondition then
			-- Check if ``m_nProficiency2Weapon`` has changed since the last application
			local spriteProficiency2Weapon = sprite.m_derivedStats.m_nProficiency2Weapon
			--
			if spriteProficiency2Weapon ~= sprite:getLocalInt("cdtweaksDualWieldHelper") then
				apply(spriteProficiency2Weapon)
			end
		else
			-- Mark the creature as 'malus removed'
			sprite:setLocalInt("cdtweaksDualWield", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["durationType"] = 1,
				["res"] = "CDDLWLD",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)
