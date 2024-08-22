-- cdtweaks, Yeslick (axes): remove f/c unusability flag from all axes --

EEex_GameState_AddInitializedListener(function()
	local itmFileList = Infinity_GetFilesOfType("itm")
	-- for some unknown reason, we need two nested loops in order to get the resref...
	for _, temp in ipairs(itmFileList) do
		for _, res in pairs(temp) do
			local header = EEex_Resource_Demand(res, "ITM")
			if header.itemType == 0x19 then -- axe
				local headerUnusabilityFlags = header.notUsableBy
				header.notUsableBy = EEex_UnsetBit(headerUnusabilityFlags, 14) -- remove f/c bit
			end
		end
	end
end)

-- cdtweaks, Yeslick (axes): make sure only Yeslick can equip axes --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- internal function that applies the actual restriction
	local apply = function()
		-- Mark the creature as 'condition applied'
		sprite:setLocalInt("cdtweaksYeslickAxes", 1)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove spell
			["durationType"] = 1,
			["res"] = "CDYSLAXE",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 181, -- Restrict item
			["durationType"] = 9,
			["special"] = %feedback_strref%,
			["effectAmount"] = 0x19, -- axes
			["m_sourceRes"] = "CDYSLAXE",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's class / flags
	local spriteClassStr = GT_Resource_IDSToSymbol["class"][sprite.m_typeAI.m_Class]
	--
	local spriteFlags = sprite.m_baseStats.m_flags
	-- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local spriteLevel1 = sprite.m_derivedStats.m_nLevel1
	local spriteLevel2 = sprite.m_derivedStats.m_nLevel2
	-- Check if F/C (all but Yeslick)
	local applyCondition = spriteClassStr == "FIGHTER_CLERIC" and (EEex_IsBitUnset(spriteFlags, 0x5) or spriteLevel1 > spriteLevel2) and not (string.upper(sprite.m_scriptName:get()) == "YESLICK")
	--
	if sprite:getLocalInt("cdtweaksYeslickAxes") == 0 then
		if applyCondition then
			apply()
		end
	else
		if applyCondition then
			-- do nothing
		else
			-- Mark the creature as 'condition removed'
			sprite:setLocalInt("cdtweaksYeslickAxes", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["durationType"] = 1,
				["res"] = "CDYSLAXE",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)
