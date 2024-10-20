--[[
	***************************************************************************************************************************
--]]

-- cdtweaks, Overwhelming/Devastating Critical class feat for Trueclass Fighters --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual feat
	local apply = function(mainHandResRef)
		-- Update tracking var
		sprite:setLocalString("cdtweaksTrueFigCritMainHand", mainHandResRef)
		-- Mark the creature as 'feat applied'
		sprite:setLocalInt("cdtweaksTrueFigCrit", 1)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "CDTFCRIT",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 182, -- Use EFF file while ITM is equipped
			["durationType"] = 9,
			["res"] = string.upper(mainHandResRef), -- ITM
			["m_res2"] = "%TRUECLASS_FIGHTER_CRITICAL%B", -- EFF
			["m_sourceRes"] = "CDTFCRIT",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's equipment / class / pips
	local equipment = sprite.m_equipment -- CGameSpriteEquipment
	local selectedWeapon = equipment.m_items:get(equipment.m_selectedWeapon) -- CItem
	local selectedWeaponHeader = selectedWeapon.pRes.pHeader -- Item_Header_st
	local selectedWeaponResRef = selectedWeapon.pRes.resref:get()
	--
	local selectedWeaponProficiencyType = selectedWeaponHeader.proficiencyType
	-- get launcher if needed
	local launcher = sprite:getLauncher(selectedWeapon:getAbility(equipment.m_selectedWeaponAbility)) -- CItem
	if launcher ~= nil then
		local pHeader = launcher.pRes.pHeader -- Item_Header_st
		selectedWeaponProficiencyType = pHeader.proficiencyType
	end
	--
	local spriteClassStr = GT_Resource_IDSToSymbol["class"][sprite.m_typeAI.m_Class]
	-- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local spriteKitStr = sprite.m_derivedStats.m_nKit == 0 and "TRUECLASS" or GT_Resource_IDSToSymbol["kit"][sprite.m_derivedStats.m_nKit]
	--
	local grandmastery = EEex_Trigger_ParseConditionalString(string.format("ProficiencyGT(Myself,%d,4)", selectedWeaponProficiencyType))
	--
	local applyAbility = spriteClassStr == "FIGHTER" and (spriteKitStr == "TRUECLASS" or spriteKitStr == "MAGESCHOOL_GENERALIST") and grandmastery:evalConditionalAsAIBase(sprite)
	--
	if sprite:getLocalInt("cdtweaksTrueFigCrit") == 0 then
		if applyAbility then
			apply(selectedWeaponResRef)
		end
	else
		if applyCondition then
			-- Check if weapon resref has changed since the last application
			if selectedWeaponResRef ~= sprite:getLocalString("cdtweaksTrueFigCritMainHand") then
				apply(selectedWeaponResRef)
			end
		else
			-- Mark the creature as 'feat removed'
			sprite:setLocalInt("cdtweaksTrueFigCrit", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "CDTFCRIT",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
	--
	grandmastery:free()
end)

-- cdtweaks, Overwhelming/Devastating Critical class feat for Trueclass Fighters --

function %TRUECLASS_FIGHTER_CRITICAL%(CGameEffect, CGameSprite)
	local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId)
	--
	local equipment = sourceSprite.m_equipment -- CGameSpriteEquipment
	local selectedWeapon = equipment.m_items:get(equipment.m_selectedWeapon) -- CItem
	local selectedWeaponHeader = selectedWeapon.pRes.pHeader -- Item_Header_st
	local selectedWeaponAbility = EEex_Resource_GetItemAbility(selectedWeaponHeader, equipment.m_selectedWeaponAbility) -- Item_ability_st
	--
	if CGameEffect.m_effectAmount == 1 then
		-- Overwhelming Critical
		local immunityToDamage = EEex_Trigger_ParseConditionalString("EEex_IsImmuneToOpcode(Myself,12)")
		--
		local targetActiveStats = EEex_Sprite_GetActiveStats(CGameSprite)
		--
		local itmDamageTypeToIDS = {
			0x10, -- piercing
			0x0, -- crushing
			0x100, -- slashing
			0x80, -- missile
			0x800, -- non-lethal
			targetActiveStats.m_nResistPiercing > targetActiveStats.m_nResistCrushing and 0x0 or 0x10, -- piercing/crushing (better)
			targetActiveStats.m_nResistPiercing > targetActiveStats.m_nResistSlashing and 0x100 or 0x10, -- piercing/slashing (better)
			targetActiveStats.m_nResistCrushing > targetActiveStats.m_nResistSlashing and 0x0 or 0x100, -- slashing/crushing (worse)
		}
		--
		if itmDamageTypeToIDS[selectedWeaponAbility.damageType] then -- sanity check
			if not immunityToDamage:evalConditionalAsAIBase(CGameSprite) then
				EEex_GameObject_ApplyEffect(sourceSprite,
				{
					["effectID"] = 139, -- Display string
					["effectAmount"] = %feedback_strref_overwhelming_crit_hit%,
					["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
					["m_sourceType"] = CGameEffect.m_sourceType,
					["sourceID"] = sourceSprite.m_id,
					["sourceTarget"] = sourceSprite.m_id,
				})
				--
				EEex_GameObject_ApplyEffect(CGameSprite,
				{
					["effectID"] = 12, -- Damage
					["dwFlags"] = itmDamageTypeToIDS[selectedWeaponAbility.damageType] * 0x10000,
					["numDice"] = 2,
					["diceSize"] = 6,
					["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
					["m_sourceType"] = CGameEffect.m_sourceType,
					["sourceID"] = CGameEffect.m_sourceId,
					["sourceTarget"] = CGameEffect.m_sourceTarget,
				})
			else
				EEex_GameObject_ApplyEffect(CGameSprite,
				{
					["effectID"] = 139, -- Display string
					["effectAmount"] = %feedback_strref_overwhelming_crit_immune%,
					["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
					["m_sourceType"] = CGameEffect.m_sourceType,
					["sourceID"] = CGameEffect.m_sourceId,
					["sourceTarget"] = CGameEffect.m_sourceTarget,
				})
			end
		end
		--
		immunityToDamage:free()
	elseif CGameEffect.m_effectAmount == 2 then
		-- Devastating Critical
		local sourceActiveStats = EEex_Sprite_GetActiveStats(sourceSprite)
		--
		local savebonus = math.floor((sourceActiveStats.m_nSTR - 10) / 2)
		if selectedWeaponAbility.type == 2 then -- if ranged, make it scale with Dexterity
			savebonus = math.floor((sourceActiveStats.m_nDEX - 10) / 2)
		end
		--
		local immunityToKillTarget = EEex_Trigger_ParseConditionalString("EEex_IsImmuneToOpcode(Myself,13)")
		--
		if not immunityToKillTarget:evalConditionalAsAIBase(CGameSprite) then
			EEex_GameObject_ApplyEffect(sourceSprite,
			{
				["effectID"] = 139, -- Display string
				["effectAmount"] = %feedback_strref_devastating_crit_hit%,
				["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
				["m_sourceType"] = CGameEffect.m_sourceType,
				["sourceID"] = sourceSprite.m_id,
				["sourceTarget"] = sourceSprite.m_id,
			})
			--
			local effectCodes = {
				{["op"] = 0xD7, ["tmg"] = 1, ["res"] = "SPBOLTGL"}, -- feedback vfx
				{["op"] = 0xD, ["tmg"] = 4, ["p2"] = 0x4} -- kill target (normal death)
			}
			--
			for _, attributes in ipairs(effectCodes) do
				CGameSprite:applyEffect({
					["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
					["dwFlags"] = attributes["p2"] or 0,
					["durationType"] = attributes["tmg"] or 0,
					["res"] = attributes["res"] or "",
					["savingThrow"] = 0x4, -- save vs. death
					["saveMod"] = -1 * savebonus,
					["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
					["m_sourceType"] = CGameEffect.m_sourceType,
					["sourceID"] = CGameEffect.m_sourceId,
					["sourceTarget"] = CGameEffect.m_sourceTarget,
				})
			end
		else
			EEex_GameObject_ApplyEffect(CGameSprite,
			{
				["effectID"] = 139, -- Display string
				["effectAmount"] = %feedback_strref_devastating_crit_immune%,
				["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
				["m_sourceType"] = CGameEffect.m_sourceType,
				["sourceID"] = CGameEffect.m_sourceId,
				["sourceTarget"] = CGameEffect.m_sourceTarget,
			})
		end
		--
		immunityToKillTarget:free()
	end
end
