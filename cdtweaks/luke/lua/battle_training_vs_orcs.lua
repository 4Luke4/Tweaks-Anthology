-- cdtweaks, battle training vs. orcs racial feat for dwarves --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- internal function that applies the actual bonus
	local apply = function()
		-- Mark the creature as 'bonus applied'
		sprite:setLocalInt("cdtweaksBattleTrainingVsOrcs", 1)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["durationType"] = 1,
			["res"] = "CDDWORCS",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 219, -- Attack and Saving Throw roll penalty
			["effectAmount"] = GT_Resource_SymbolToIDS["race"]["HALFORC"],
			["dwFlags"] = 4,
			["durationType"] = 9,
			["m_sourceRes"] = "CDDWORCS",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 219, -- Attack and Saving Throw roll penalty
			["effectAmount"] = GT_Resource_SymbolToIDS["race"]["ORC"],
			["dwFlags"] = 4,
			["durationType"] = 9,
			["m_sourceRes"] = "CDDWORCS",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's race
	local spriteRaceStr = GT_Resource_IDSToSymbol["race"][sprite.m_typeAI.m_Race]
	-- This feat grants a +2 AC / save bonus against orcs and half-orcs
	local applyCondition = spriteRaceStr == "DWARF" or spriteRaceStr == "DUERGAR"
	--
	if sprite:getLocalInt("cdtweaksBattleTrainingVsOrcs") == 0 then
		if applyCondition then
			apply()
		end
	else
		if applyCondition then
			-- do nothing
		else
			-- Mark the creature as 'bonus removed'
			sprite:setLocalInt("cdtweaksBattleTrainingVsOrcs", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["durationType"] = 1,
				["res"] = "CDDWORCS",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)
