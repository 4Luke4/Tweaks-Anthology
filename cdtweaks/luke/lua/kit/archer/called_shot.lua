--[[
+--------------------------------------------+
| cdtweaks, Revised Archer Kit (Called Shot) |
+--------------------------------------------+
--]]

-- NWN-ish Called Shot ability. Creatures with no arms --

local cdtweaks_CalledShot_NoArms = {
	{"WEAPON"}, -- GENERAL.IDS
	{"DOG", "WOLF", "ANKHEG", "BASILISK", "CARRIONCRAWLER", "SPIDER", "WYVERN", "SLIME", "BEHOLDER", "DEMILICH", "BEETLE", "BIRD", "WILL-O-WISP"}, -- RACE.IDS
	{"WOLF_WORG", "ELEMENTAL_AIR", "WIZARD_EYE"}, -- CLASS.IDS
	-- ANIMATE.IDS
	{
		"DOOM_GUARD", "DOOM_GUARD_LARGER",
		"SNAKE", "DANCING_SWORD", "BLOB_MIST_CREATURE", "HAKEASHAR", "NISHRUU", "SNAKE_WATER",
		"BOAR_ARCTIC", "BOAR_WILD", "BONEBAT", "WATER_WEIRD"
	},
}

-- NWN-ish Called Shot ability. Creatures with no legs --

local cdtweaks_CalledShot_NoLegs = {
	{"WEAPON"}, -- GENERAL.IDS
	{"ANKHEG", "WYVERN", "SLIME", "BEHOLDER", "MEPHIT", "IMP", "YUANTI", "DEMILICH", "FEYR", "SALAMANDER", "BIRD", "WILL-O-WISP"}, -- RACE.IDS
	{"MEPHIT", "ELEMENTAL_AIR", "WIZARD_EYE"}, -- CLASS.IDS
	-- ANIMATE.IDS
	{
		"DOOM_GUARD", "DOOM_GUARD_LARGER", -- 0x6000
		"IMP", "SNAKE", "DANCING_SWORD", "MIST_CREATURE", "BLOB_MIST_CREATURE", "HAKEASHAR", "NISHRUU", "SNAKE_WATER", -- 0x7000
		"LEMURE", "BONEBAT", "SHADOW_SMALL", "SHADOW_LARGE", "WATER_WEIRD" -- 0xE000
	},
}

-- NWN-ish Called Shot ability (main) --

function %ARCHER_CALLED_SHOT%(CGameEffect, CGameSprite)
	if CGameEffect.m_effectAmount == 0 then
		-- do nothing (AoE missile!)
	else
		local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId) -- CGameSprite
		local sourceActiveStats = EEex_Sprite_GetActiveStats(sourceSprite)
		-- Get level
		local sourceLevel = sourceActiveStats.m_nLevel1
		if sourceSprite.m_typeAI.m_Class == 18 then -- CLERIC_RANGER
			sourceLevel = sourceActiveStats.m_nLevel2
		end
		--
		local savebonus = math.floor((sourceLevel - 1) / 4) -- +1 every 4 levels, starting at 0
		if savebonus > 7 then
			savebonus = 7 -- cap at 7
		end
		--
		local targetGeneralStr = GT_Resource_IDSToSymbol["general"][CGameSprite.m_typeAI.m_General]
		local targetRaceStr = GT_Resource_IDSToSymbol["race"][CGameSprite.m_typeAI.m_Race]
		local targetClassStr = GT_Resource_IDSToSymbol["class"][CGameSprite.m_typeAI.m_Class]
		local targetAnimateStr = GT_Resource_IDSToSymbol["animate"][CGameSprite.m_animation.m_animation.m_animationID]
		--
		local targetIDS = {targetGeneralStr, targetRaceStr, targetClassStr, targetAnimateStr}
		--
		if CGameEffect.m_effectAmount == 1 then
			-- Called Shot (Arms): -2 thac0 penalty
			local found = false
			--
			do
				for index, symbolList in ipairs(cdtweaks_CalledShot_NoArms) do
					for _, symbol in ipairs(symbolList) do
						if targetIDS[index] == symbol then
							found = true
							break
						end
					end
				end
			end
			--
			if not found then
				local effectCodes = {
					{["op"] = 54, ["p1"] = -2, ["dur"] = 24}, -- base thac0 bonus
					{["op"] = 139, ["p1"] = %feedback_strref_thac0_mod%} -- feedback string
				}
				--
				for _, attributes in ipairs(effectCodes) do
					CGameSprite:applyEffect({
						["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
						["effectAmount"] = attributes["p1"] or 0,
						["duration"] = attributes["dur"] or 0,
						["savingThrow"] = 0x2, -- save vs. breath
						["saveMod"] = -1 * savebonus,
						["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
						["m_sourceType"] = CGameEffect.m_sourceType,
						["sourceID"] = CGameEffect.m_sourceId,
						["sourceTarget"] = CGameEffect.m_sourceTarget,
					})
				end
			else
				CGameSprite:applyEffect({
					["effectID"] = 139, -- display string
					["effectAmount"] = %feedback_strref_immune%,
					["sourceID"] = CGameEffect.m_sourceId,
					["sourceTarget"] = CGameEffect.m_sourceTarget,
				})
			end
		elseif CGameEffect.m_effectAmount == 2 then
			-- Called Shot (Legs): -2 dex penalty, 20% movement rate penalty
			local found = false
			--
			do
				for index, symbolList in ipairs(cdtweaks_CalledShot_NoLegs) do
					for _, symbol in ipairs(symbolList) do
						if targetIDS[index] == symbol then
							found = true
							break
						end
					end
				end
			end
			--
			if not found then
				local targetDEX = CGameSprite:getActiveStats().m_nDEX
				--
				local effectCodes = {
					{["op"] = 15, ["p1"] = (targetDEX <= 1) and 0 or ((targetDEX > 2) and -2 or -1), ["dur"] = 24}, -- dex bonus
					{["op"] = 176, ["p1"] = 80, ["p2"] = 5, ["dur"] = 24} -- movement rate bonus (mode: multiply %)
					{["op"] = 139, ["p1"] = %feedback_strref_dex_mod%} -- feedback string
				}
				--
				for _, attributes in ipairs(effectCodes) do
					CGameSprite:applyEffect({
						["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
						["effectAmount"] = attributes["p1"] or 0,
						["dwFlags"] = attributes["p2"] or 0,
						["duration"] = attributes["dur"] or 0,
						["savingThrow"] = 0x2, -- save vs. breath
						["saveMod"] = -1 * savebonus,
						["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
						["m_sourceType"] = CGameEffect.m_sourceType,
						["sourceID"] = CGameEffect.m_sourceId,
						["sourceTarget"] = CGameEffect.m_sourceTarget,
					})
				end
			else
				CGameSprite:applyEffect({
					["effectID"] = 139, -- display string
					["effectAmount"] = %feedback_strref_immune%,
					["sourceID"] = CGameEffect.m_sourceId,
					["sourceTarget"] = CGameEffect.m_sourceTarget,
				})
			end
		end
	end
end

-- Make it castable at will. Prevent spell disruption. Check if bow equipped --

EEex_Sprite_AddQuickListsCheckedListener(function(sprite, resref, changeAmount)
	local curAction = sprite.m_curAction
	local spriteAux = EEex_GetUDAux(sprite)

	local resToAux = {
		["%ARCHER_CALLED_SHOT%B"] = "gtCallShotArmTargetID",
		["%ARCHER_CALLED_SHOT%C"] = "gtCallShotLegTargetID",
	}

	if not (sprite:getLocalInt("gtArcherCalledShot") == 1 and curAction.m_actionID == 31 and resToAux[resref] and changeAmount < 0) then
		return
	end

	-- recast as ``ForceSpell()`` (so as to prevent spell disruption)
	curAction.m_actionID = 113

	local spellHeader = EEex_Resource_Demand(resref, "SPL")
	local spellLevelMemListArray = sprite.m_memorizedSpellsInnate
	local memList = spellLevelMemListArray:getReference(spellHeader.spellLevel - 1) -- !!!count starts from 0!!!

	-- restore memorization bit
	EEex_Utility_IterateCPtrList(memList, function(memInstance)
		local memInstanceResref = memInstance.m_spellId:get()
		if memInstanceResref == resref then
			local memFlags = memInstance.m_flags
			if EEex_IsBitUnset(memFlags, 0x0) then
				memInstance.m_flags = EEex_SetBit(memFlags, 0x0)
			end
		end
	end)

	-- make sure the creature is equipped with a bow
	local equipment = sprite.m_equipment
	local selectedWeapon = equipment.m_items:get(equipment.m_selectedWeapon) -- CItem
	local selectedWeaponHeader = selectedWeapon.pRes.pHeader -- Item_Header_st
	local selectedWeaponTypeStr = GT_Resource_IDSToSymbol["itemcat"][selectedWeaponHeader.itemType]
	-- Bow with arrows equipped || bow with unlimited ammo equipped
	if selectedWeaponTypeStr == "ARROW" or selectedWeaponTypeStr == "BOW" then
		-- store target id
		spriteAux[resToAux[resref]] = curAction.m_acteeID.m_Instance
		-- initialize the attack frame counter
		sprite.m_attackFrame = 0
	else
		sprite:applyEffect({
			["effectID"] = 139, -- Display string
			["effectAmount"] = %feedback_strref_bow_only%,
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
end)

-- Cast the "real" spl (ability) when the attack frame counter is 6 --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	--
	local spriteAux = EEex_GetUDAux(sprite)
	--
	local auxToRes = {
		["gtCallShotArmTargetID"] = "%ARCHER_CALLED_SHOT%D",
		["gtCallShotLegTargetID"] = "%ARCHER_CALLED_SHOT%E",
	}
	-- make sure the creature is equipped with a bow
	local equipment = sprite.m_equipment
	local selectedWeapon = equipment.m_items:get(equipment.m_selectedWeapon) -- CItem
	local selectedWeaponHeader = selectedWeapon.pRes.pHeader -- Item_Header_st
	local selectedWeaponTypeStr = GT_Resource_IDSToSymbol["itemcat"][selectedWeaponHeader.itemType]
	--
	if sprite:getLocalInt("gtArcherCalledShot") == 1 then
		if selectedWeaponTypeStr == "ARROW" or selectedWeaponTypeStr == "BOW" then
			if sprite.m_nSequence == 8 and sprite.m_attackFrame == 6 then -- SetSequence(SEQ_SHOOT)
				for aux, res in pairs(auxToRes) do
					if spriteAux[aux] then
						-- retrieve / forget target sprite
						local targetSprite = EEex_GameObject_Get(spriteAux[aux])
						spriteAux[aux] = nil
						-- make sure to use the currently selected projectile
						sprite:applyEffect({
							["effectID"] = 408, -- projectile mutator
							["durationType"] = 10, -- ticks
							["duration"] = 1,
							["res"] = "%ARCHER_CALLED_SHOT%P",
							["sourceID"] = sprite.m_id,
							["sourceTarget"] = sprite.m_id,
						})
						targetSprite:applyEffect({
							["effectID"] = 146, -- cast spl
							["dwFlags"] = 1, -- instant / ignore level
							["res"] = res,
							["sourceID"] = sprite.m_id,
							["sourceTarget"] = targetSprite.m_id,
						})
						--
						break
					end
				end
			end
		end
	end
end)

-- Make sure to use the currently selected projectile. Print a warning in case of AoE missiles --

%ARCHER_CALLED_SHOT%P = {

	["typeMutator"] = function(context)
		local actionSources = {
			[EEex_Projectile_DecodeSource.CGameAIBase_FireSpell] = true,
		}
		--
		local originatingSprite = context["originatingSprite"] -- CGameSprite
		--
		if not actionSources[context.decodeSource] then
			return
		end
		--
		local equipment = originatingSprite.m_equipment
		local selectedWeapon = equipment.m_items:get(equipment.m_selectedWeapon) -- CItem
		local selectedWeaponAbility = EEex_Resource_GetCItemAbility(selectedWeapon, equipment.m_selectedWeaponAbility) -- Item_ability_st
		-- morph projectile
		return selectedWeaponAbility.missileType
	end,

	["projectileMutator"] = function(context)
		local actionSources = {
			[EEex_Projectile_DecodeSource.CGameAIBase_FireSpell] = true,
		}
		--
		local originatingSprite = context["originatingSprite"] -- CGameSprite
		--
		if not actionSources[context.decodeSource] then
			return
		end
		--
		local projectile = context["projectile"] -- CProjectile
		--
		if EEex_Projectile_IsOfType(projectile, EEex_Projectile_Type["CProjectileArea"]) then
			originatingSprite.m_curAction.m_actionID = 0 -- nuke current action
			--
			originatingSprite:applyEffect({
				["effectID"] = 139, -- display string
				["effectAmount"] = %feedback_strref_AoE%,
				["sourceID"] = originatingSprite.m_id,
				["sourceTarget"] = originatingSprite.m_id,
			})
			--
			--projectile:ClearEffects()
		end
	end,

	["effectMutator"] = function(context)
		local actionSources = {
			[EEex_Projectile_AddEffectSource.CGameAIBase_FireSpell] = true,
		}
		--
		if not actionSources[context.addEffectSource] then
			return
		end
		--
		local effect = context["effect"] -- CGameEffect
		--
		local projectile = context["projectile"] -- CProjectile
		--
		if EEex_Projectile_IsOfType(projectile, EEex_Projectile_Type["CProjectileArea"]) then
			if effect.m_effectId == 402 then -- invoke lua
				if effect.m_res:get() == "%ARCHER_CALLED_SHOT%" then
					effect.m_effectAmount = 0
				end
			end
		end
	end,
}

-- Forget about ``spriteAux["gtCallShotXTargetID"]`` if the player manually interrupts the action --

EEex_Action_AddSpriteStartedActionListener(function(sprite, action)
	local spriteAux = EEex_GetUDAux(sprite)
	--
	local resToAux = {
		["%ARCHER_CALLED_SHOT%B"] = "gtCallShotArmTargetID",
		["%ARCHER_CALLED_SHOT%C"] = "gtCallShotLegTargetID",
	}
	--
	if sprite:getLocalInt("gtArcherCalledShot") == 1 then
		if not (action.m_actionID == 113 and resToAux[action.m_string1.m_pchData:get()]) then
			for _, aux in pairs(resToAux) do
				if spriteAux[aux] ~= nil then
					spriteAux[aux] = nil
				end
			end
		end
	end
end)

-- NWN-ish Called Shot ability. Gain ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) or Infinity_GetCurrentScreenName() == 'CHARGEN' then
		return
	end
	-- internal function that grants the ability
	local gain = function()
		-- Mark the creature as 'feat granted'
		sprite:setLocalInt("gtArcherCalledShot", 1)
		--
		local effectCodes = {
			{["op"] = 172, ["res"] = "%ARCHER_CALLED_SHOT%B"}, -- remove spell
			{["op"] = 171, ["res"] = "%ARCHER_CALLED_SHOT%B"}, -- give spell
			{["op"] = 172, ["res"] = "%ARCHER_CALLED_SHOT%C"}, -- remove spell
			{["op"] = 171, ["res"] = "%ARCHER_CALLED_SHOT%C"}, -- give spell
		}
		--
		for _, attributes in ipairs(effectCodes) do
			sprite:applyEffect({
				["effectID"] = attributes["op"] or -1,
				["res"] = attributes["res"] or "",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
	-- Check creature's class / kit
	local spriteClassStr = GT_Resource_IDSToSymbol["class"][sprite.m_typeAI.m_Class]
	--
	local spriteFlags = sprite.m_baseStats.m_flags
	-- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local spriteLevel1 = sprite.m_derivedStats.m_nLevel1
	local spriteLevel2 = sprite.m_derivedStats.m_nLevel2
	local spriteKitStr = GT_Resource_IDSToSymbol["kit"][sprite.m_derivedStats.m_nKit]
	--
	local gainAbility = spriteKitStr == "FERALAN"
		and (spriteClassStr == "RANGER"
			or (spriteClassStr == "CLERIC_RANGER" and (EEex_IsBitUnset(spriteFlags, 0x8) or spriteLevel1 > spriteLevel2)))
		and EEex_IsBitUnset(spriteFlags, 10) -- must not be fallen
	--
	if sprite:getLocalInt("gtArcherCalledShot") == 0 then
		if gainAbility then
			gain()
		end
	else
		if gainAbility then
			-- do nothing
		else
			-- Mark the creature as 'feat removed'
			sprite:setLocalInt("gtArcherCalledShot", 0)
			--
			sprite:applyEffect({
				["effectID"] = 172, -- remove spell
				["res"] = "%ARCHER_CALLED_SHOT%B",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
			sprite:applyEffect({
				["effectID"] = 172, -- remove spell
				["res"] = "%ARCHER_CALLED_SHOT%C",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)
