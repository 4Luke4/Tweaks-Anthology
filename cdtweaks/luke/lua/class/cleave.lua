--[[
+--------------------------------------------------+
| cdtweaks, NWN-ish Cleave class feat for Fighters |
+--------------------------------------------------+
--]]

-- Apply Ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual feat
	local apply = function()
		-- Mark the creature as 'feat applied'
		sprite:setLocalInt("cdtweaksCleave", 1)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "%FIGHTER_CLEAVE%",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 248, -- Melee hit effect
			["durationType"] = 9,
			["res"] = "%FIGHTER_CLEAVE%B", -- EFF file
			["m_sourceRes"] = "%FIGHTER_CLEAVE%",
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
	-- any fighter class (single/multi/(complete)dual)
	local applyAbility = spriteClassStr == "FIGHTER" or spriteClassStr == "FIGHTER_MAGE_THIEF" or spriteClassStr == "FIGHTER_MAGE_CLERIC"
		or (spriteClassStr == "FIGHTER_MAGE" and (EEex_IsBitUnset(spriteFlags, 0x3) or spriteLevel2 > spriteLevel1))
		or (spriteClassStr == "FIGHTER_CLERIC" and (EEex_IsBitUnset(spriteFlags, 0x3) or spriteLevel2 > spriteLevel1))
		or (spriteClassStr == "FIGHTER_THIEF" and (EEex_IsBitUnset(spriteFlags, 0x3) or spriteLevel2 > spriteLevel1))
		or (spriteClassStr == "FIGHTER_DRUID" and (EEex_IsBitUnset(spriteFlags, 0x3) or spriteLevel2 > spriteLevel1))
	--
	if sprite:getLocalInt("cdtweaksCleave") == 0 then
		if applyAbility then
			apply()
		end
	else
		if applyAbility then
			-- do nothing
		else
			-- Mark the creature as 'feat removed'
			sprite:setLocalInt("cdtweaksCleave", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "%FIGHTER_CLEAVE%",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

-- Core function --

function %FIGHTER_CLEAVE%(CGameEffect, CGameSprite)
	if CGameEffect.m_effectAmount == 1 then -- check if can perform Cleave
		local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId)
		local sourceActiveStats = EEex_Sprite_GetActiveStats(sourceSprite)
		--
		local inWeaponRange = EEex_Trigger_ParseConditionalString('InWeaponRange(EEex_Target("GT_FighterCleaveTarget"))')
		local reallyForceSpell = EEex_Action_ParseResponseString('ReallyForceSpellRES("%FIGHTER_CLEAVE%B",EEex_Target("GT_FighterCleaveTarget"))')
		--
		local targetActiveStats = EEex_Sprite_GetActiveStats(CGameSprite)
		--
		if EEex_IsBitSet(targetActiveStats.m_generalState, 11) then -- if STATE_DEAD (BIT11)
			local spriteArray = {}
			if sourceSprite.m_typeAI.m_EnemyAlly > 200 then -- EVILCUTOFF
				spriteArray = EEex_Sprite_GetAllOfTypeInRange(sourceSprite, GT_AI_ObjectType["GOODCUTOFF"], sourceSprite:virtual_GetVisualRange(), nil, nil, nil)
			elseif sourceSprite.m_typeAI.m_EnemyAlly < 30 then -- GOODCUTOFF
				spriteArray = EEex_Sprite_GetAllOfTypeInRange(sourceSprite, GT_AI_ObjectType["EVILCUTOFF"], sourceSprite:virtual_GetVisualRange(), nil, nil, nil)
			end
			--
			for _, itrSprite in ipairs(spriteArray) do
				sourceSprite:setStoredScriptingTarget("GT_FighterCleaveTarget", itrSprite)
				--
				local itrSpriteActiveStats = EEex_Sprite_GetActiveStats(itrSprite)
				--
				if inWeaponRange:evalConditionalAsAIBase(sourceSprite) and EEex_IsBitUnset(itrSpriteActiveStats.m_generalState, 11) then -- if not dead
					if EEex_IsBitUnset(itrSpriteActiveStats.m_generalState, 0x4) or sourceActiveStats.m_bSeeInvisible > 0 then
						if itrSpriteActiveStats.m_bSanctuary == 0 then
							reallyForceSpell:executeResponseAsAIBaseInstantly(sourceSprite)
							break
						end
					end
				end
			end
		end
		--
		inWeaponRange:free()
		reallyForceSpell:free()
	elseif CGameEffect.m_effectAmount == 2 then -- actual feat
		local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId)
		--
		local equipment = sourceSprite.m_equipment -- CGameSpriteEquipment
		local selectedWeapon = equipment.m_items:get(equipment.m_selectedWeapon) -- CItem
		local selectedWeaponHeader = selectedWeapon.pRes.pHeader -- Item_Header_st
		local selectedWeaponAbility = EEex_Resource_GetItemAbility(selectedWeaponHeader, equipment.m_selectedWeaponAbility) -- Item_ability_st
		--
		local immunityToDamage = EEex_Trigger_ParseConditionalString("EEex_IsImmuneToOpcode(Myself,12)")
		--
		local targetActiveStats = EEex_Sprite_GetActiveStats(CGameSprite)
		--
		local itmAbilityDamageTypeToIDS = {
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
		if itmAbilityDamageTypeToIDS[selectedWeaponAbility.damageType] then -- sanity check
			if not immunityToDamage:evalConditionalAsAIBase(CGameSprite) then
				EEex_GameObject_ApplyEffect(CGameSprite,
				{
					["effectID"] = 0xC, -- Damage
					["dwFlags"] = itmAbilityDamageTypeToIDS[selectedWeaponAbility.damageType] * 0x10000, -- mode: normal
					["numDice"] = selectedWeaponAbility.damageDiceCount,
					["diceSize"] = selectedWeaponAbility.damageDice,
					["effectAmount"] = selectedWeaponAbility.damageDiceBonus,
					["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
					["m_sourceType"] = CGameEffect.m_sourceType,
					["sourceID"] = CGameEffect.m_sourceId,
					["sourceTarget"] = CGameEffect.m_sourceTarget,
				})
			else
				EEex_GameObject_ApplyEffect(CGameSprite,
				{
					["effectID"] = 324, -- Immunity to resource and message
					["res"] = CGameEffect.m_sourceRes:get(),
					["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
					["m_sourceType"] = CGameEffect.m_sourceType,
					["sourceID"] = CGameEffect.m_sourceId,
					["sourceTarget"] = CGameEffect.m_sourceTarget,
				})
			end
		end
		--
		immunityToDamage:free()
	end
end
