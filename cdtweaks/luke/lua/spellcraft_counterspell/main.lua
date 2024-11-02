--[[
+-------------------------------------------------------------------------+
| cdtweaks: NWN-ish Spellcraft / Counterspell class feat for spellcasters |
+-------------------------------------------------------------------------+
--]]

local cdtweaks_Counterspell_ResRef = {
	["%INNATE_COUNTERSPELL%A"] = true,
	["%INNATE_COUNTERSPELL%B"] = true,
	["%INNATE_COUNTERSPELL%C"] = true,
	["%INNATE_COUNTERSPELL%D"] = true,
	["%INNATE_COUNTERSPELL%E"] = true,
	["%INNATE_COUNTERSPELL%F"] = true,
	["%INNATE_COUNTERSPELL%G"] = true,
	["%INNATE_COUNTERSPELL%H"] = true,
}

--

local cdtweaks_Counterspell_OppositionSchool = { -- based on iwdee
	[1] = {{5, 8}, "%INNATE_COUNTERSPELL%A"}, -- ABJURER countered by ILLUSIONIST and TRANSMUTER
	[2] = {{3, 6}, "%INNATE_COUNTERSPELL%B"}, -- CONJURER countered by DIVINER and INVOKER
	[3] = {{6}, "%INNATE_COUNTERSPELL%C"}, -- DIVINER countered by INVOKER
	[4] = {{7}, "%INNATE_COUNTERSPELL%D"}, -- ENCHANTER countered by NECROMANCER
	[5] = {{1, 7}, "%INNATE_COUNTERSPELL%E"}, -- ILLUSIONIST countered by ABJURER and NECROMANCER
	[6] = {{2, 4}, "%INNATE_COUNTERSPELL%F"}, -- INVOKER countered by CONJURER and ENCHANTER
	[7] = {{5, 8}, "%INNATE_COUNTERSPELL%G"}, -- NECROMANCER countered by ILLUSIONIST and TRANSMUTER
	[8] = {{1}, "%INNATE_COUNTERSPELL%H"}, -- TRANSMUTER countered by ABJURER
}

--

local cdtweaks_Counterspell_UniversalCounter = {
	["CLERIC_DISPEL_MAGIC"] = true,
	["WIZARD_REMOVE_MAGIC"] = true,
	["WIZARD_DISPEL_MAGIC"] = true,
	["WIZARD_TRUE_DISPEL_MAGIC"] = true,
}

-- check if there is someone casting a wizard/priest spell --
-- perform a counterspell if appropriate --

EEex_Action_AddSpriteStartedActionListener(function(sprite, action)
	local state = GT_Resource_SymbolToIDS["state"]
	local stats = GT_Resource_SymbolToIDS["stats"]
	--
	local spriteActiveStats = EEex_Sprite_GetActiveStats(sprite)
	--
	local actionSources = {
		[31] = true, -- Spell()
		[95] = true, -- SpellPoint()
		[191] = true, -- SpellNoDec()
		[192] = true, -- SpellPointNoDec()
		[113] = true, -- ForceSpell()
		[114] = true, -- ForceSpellPoint()
		[181] = true, -- ReallyForceSpell()
		[337] = true, -- ReallyForceSpellPoint()
		[476] = true, -- EEex_SpellObjectOffset()
		[477] = true, -- EEex_SpellObjectOffsetNoDec()
		[478] = true, -- EEex_ForceSpellObjectOffset()
		[479] = true, -- EEex_ReallyForceSpellObjectOffset()
	}
	--
	if actionSources[action.m_actionID] then
		local spriteArray = {}
		--
		local spellResRef = action.m_string1.m_pchData:get()
		if spellResRef == "" then
			spellResRef = GT_Utility_DecodeSpell(action.m_specificID)
		end
		local spellHeader = EEex_Resource_Demand(spellResRef, "SPL")
		local spellType = spellHeader.itemType
		local spellSchool = spellHeader.school
		local spellLevel = spellHeader.spellLevel
		--
		if (spellType == 1 or spellType == 2) and (spellSchool > 0 and spellSchool <= 8) then
			--
			if sprite.m_typeAI.m_EnemyAlly > 200 then -- EVILCUTOFF
				spriteArray = EEex_Sprite_GetAllOfTypeInRange(sprite, GT_AI_ObjectType["GOODCUTOFF"], 448, nil, nil, nil) -- we ignore STATE_BLIND
			elseif sprite.m_typeAI.m_EnemyAlly < 30 then -- GOODCUTOFF
				spriteArray = EEex_Sprite_GetAllOfTypeInRange(sprite, GT_AI_ObjectType["EVILCUTOFF"], 448, nil, nil, nil) -- we ignore STATE_BLIND
			end
			--
			local found = -1
			--
			for _, itrSprite in ipairs(spriteArray) do
				if itrSprite:getLocalInt("cdtweaksSpellcraft") == 1 then
					local itrSpriteActiveStats = EEex_Sprite_GetActiveStats(itrSprite)
					-- lore-based check (a lore score of 240+ => automatic success)
					if itrSpriteActiveStats.m_nLore >= spellLevel * 10 + math.random(150) then
						if EEex_BAnd(itrSpriteActiveStats.m_generalState, state["CD_STATE_NOTVALID"]) == 0 then
							if EEex_IsBitUnset(spriteActiveStats.m_generalState, 0x4) or itrSpriteActiveStats.m_bSeeInvisible > 0 then
								-- deafness => extra check
								if not GT_Utility_Sprite_CheckForEffect(itrSprite, {["m_effectId"] = 0x50}) or math.random(0, 1) == 1 then 
									-- provide feedback if PC
									if itrSprite.m_typeAI.m_EnemyAlly == 2 then
										Infinity_DisplayString(itrSprite:getName() .. ": " .. Infinity_FetchString(%feedback_strref_spellcraft%) .. sprite:getName() .. Infinity_FetchString(%feedback_strref_is_casting%) .. Infinity_FetchString(spellHeader.genericName))
									end
									-- check if ``itrSprite`` is counterspelling...
									if spriteActiveStats.m_bSanctuary == 0 and EEex_Sprite_GetCastTimer(itrSprite) == -1 and itrSprite:getLocalInt("gtCounterspellMode") == 1 and EEex_IsBitUnset(itrSpriteActiveStats.m_generalState, 12) then
										local spellLevelMemListTable = {[7] = itrSprite.m_memorizedSpellsPriest, [9] = itrSprite.m_memorizedSpellsMage}
										--
										for maxLevel, spellLevelMemListArray in pairs(spellLevelMemListTable) do
											for i = spellLevel, maxLevel do
												local memList = spellLevelMemListArray:getReference(i - 1) -- count starts from 0, that's why ``-1``
												--
												EEex_Utility_IterateCPtrList(memList, function(memInstance)
													local memInstanceResref = memInstance.m_spellId:get()
													local memFlags = memInstance.m_flags
													--
													if EEex_IsBitSet(memFlags, 0x0) then -- if memorized, ...
														local memInstanceHeader = EEex_Resource_Demand(memInstanceResref, "SPL")
														-- universal counters
														if string.match(memInstanceResref:upper(), "^SPPR[1-7][0-9][0-9]$") or string.match(memInstanceResref:upper(), "^SPWI[1-9][0-9][0-9]$") then
															local memIDS = memInstanceHeader.itemType == 1 and 2 .. memInstanceResref:sub(-3) or 1 .. memInstanceResref:sub(-3)
															local memSymbol = GT_Resource_IDSToSymbol["spell"][tonumber(memIDS)]
															--
															if memSymbol and cdtweaks_Counterspell_UniversalCounter[memSymbol] then
																memInstance.m_flags = EEex_UnsetBit(memFlags, 0x0) -- ... unmemorize
																found = memInstanceHeader.school
																return true
															end
														end
														-- resref counter
														if memInstanceResref == spellResRef then
															memInstance.m_flags = EEex_UnsetBit(memFlags, 0x0) -- ... unmemorize
															found = memInstanceHeader.school
															return true
														end
														-- mschool counter
														for _, mschool in ipairs(cdtweaks_Counterspell_OppositionSchool[spellSchool][1]) do
															if mschool == memInstanceHeader.school then
																memInstance.m_flags = EEex_UnsetBit(memFlags, 0x0) -- ... unmemorize
																found = memInstanceHeader.school
																return true
															end
														end
													end
												end)
												--
												if found > 0 then
													-- check for Spell Immunity and friends
													if not GT_Utility_Sprite_CheckForEffect(sprite, {["m_effectId"] = 0xCA, ["m_dWFlags"] = found}) then -- Reflect spell school (202)
														if not GT_Utility_Sprite_CheckForEffect(sprite, {["m_effectId"] = 0xCC, ["m_dWFlags"] = found}) then -- Protection from spell school (204)
															if not GT_Utility_Sprite_CheckForEffect(sprite, {["m_effectId"] = 0xDF, ["m_dWFlags"] = found}) then -- Spell school deflection (223)
																if not GT_Utility_Sprite_CheckForEffect(sprite, {["m_effectId"] = 0xE3, ["m_dWFlags"] = found}) then -- Spell school turning (227)
																	-- remove spell (so as to cancel the spell being cast)
																	action.m_actionID = 147
																end
															end
														end
													end
													-- perform counterspell
													sprite:applyEffect({
														["effectID"] = 146, -- Cast spell
														["res"] = cdtweaks_Counterspell_OppositionSchool[found][2],
														["sourceID"] = itrSprite.m_id,
														["sourceTarget"] = sprite.m_id,
													})
													-- op146*p2=0 corresponds to 'ForceSpell()', so we have to manually set the aura
													itrSprite.m_castCounter = 0
													--
													goto continue
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
			--
			::continue::
		end
	end
end)

-- Mark the sprite as being in counterspell mode. Automatically cancel mode upon death --

function %INNATE_COUNTERSPELL%(CGameEffect, CGameSprite)
	if CGameEffect.m_effectAmount == 1 then
		-- we apply effects here due to op232's presence (which for best results requires EFF V2.0)
		local effectCodes = {
			{["op"] = 321, ["res"] = "%INNATE_COUNTERSPELL%"}, -- remove effects by resource
			{["op"] = 232, ["p2"] = 16, ["res"] = "%INNATE_COUNTERSPELL%Z"}, -- cast spl on condition (condition: Die(); target: self)
			{["op"] = 142, ["p2"] = %feedback_icon%}, -- feedback icon
		}
		--
		for _, attributes in ipairs(effectCodes) do
			CGameSprite:applyEffect({
				["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
				["dwFlags"] = attributes["p2"] or 0,
				["res"] = attributes["res"] or "",
				["durationType"] = 1,
				["m_sourceRes"] = "%INNATE_COUNTERSPELL%",
				["sourceID"] = CGameSprite.m_id,
				["sourceTarget"] = CGameSprite.m_id,
			})
		end
		--
		CGameSprite:setLocalInt("gtCounterspellMode", 1)
	elseif CGameEffect.m_effectAmount == 2 then
		CGameSprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "%INNATE_COUNTERSPELL%",
			["sourceID"] = CGameSprite.m_id,
			["sourceTarget"] = CGameSprite.m_id,
		})
		--
		CGameSprite:setLocalInt("gtCounterspellMode", 0)
	end
end

-- Make sure it cannot be disrupted. Cancel mode if no longer idle --

EEex_Action_AddSpriteStartedActionListener(function(sprite, action)
	if sprite:getLocalInt("cdtweaksSpellcraft") == 1 then
		if sprite:getLocalInt("gtCounterspellMode") == 0 then
			if action.m_actionID == 31 and action.m_string1.m_pchData:get() == "%INNATE_COUNTERSPELL%" then
				action.m_actionID = 113 -- ForceSpell()
			end
		else
			if not (action.m_actionID == 113 and (cdtweaks_Counterspell_ResRef[action.m_string1.m_pchData:get()] or action.m_string1.m_pchData:get() == "%INNATE_COUNTERSPELL%Y")) then
				sprite:applyEffect({
					["effectID"] = 146, -- Cast spell
					["dwFlags"] = 1, -- instant/ignore level
					["res"] = "%INNATE_COUNTERSPELL%Z",
					["sourceID"] = sprite.m_id,
					["sourceTarget"] = sprite.m_id,
				})
			end
		end
	end
end)
