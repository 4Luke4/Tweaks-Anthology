-- cdtweaks: NWN-ish metamagic feat for spellcasters (cancel metamagic mode if the caster is not casting a wizard / priest spell... Make the spell uninterruptible if quickened) --

EEex_Action_AddSpriteStartedActionListener(function(sprite, action)
	local metamagicType = EEex_Sprite_GetStat(sprite, GT_Resource_SymbolToIDS["stats"]["CDTWEAKS_METAMAGIC"])
	local metamagicRes = {"CDMTMQCK", "CDMTMEMP", "CDMTMEXT", "CDMTMMAX", "CDMTMSIL", "CDMTMSTL"}
	--
	if sprite:getLocalInt("cdtweaksMetamagic") == 1 then
		if metamagicType > 0 then
			-- whatever the action, remove the metamagic feat
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["durationType"] = 1,
				["res"] = metamagicRes[metamagicType],
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
			-- whatever the action, make sure to exit the op214 sub-state
			EEex_Actionbar_RestoreLastState()
			--
			if (action.m_actionID == 191 or action.m_actionID == 192 or action.m_actionID == 477) then -- SpellNoDec() / SpellPointNoDec() / EEex_SpellObjectOffsetNoDec()
				--
				local spellResRef = action.m_string1.m_pchData:get()
				if spellResRef == "" then
					spellResRef = GT_Utility_DecodeSpell(action.m_specificID)
				end
				--
				local spellHeader = EEex_Resource_Demand(spellResRef, "SPL")
				local spellType = spellHeader.itemType
				--
				local casterLevel = EEex_Sprite_GetCasterLevelForSpell(sprite, spellResRef, true)
				local spellAbility = EEex_Resource_GetSpellAbilityForLevel(spellHeader, casterLevel)
				--
				if (spellType == 1 or spellType == 2) then -- sanity check
					-- check if spellcasting is disabled...
					if not GT_Metamagic_SpellcastingDisabled(sprite, spellHeader, metamagicType) then
						-- ``(Really)ForceSpell()`` bypasses range and LOS, so we need to check them...
						if GT_Metamagic_LOS(sprite, action, spellAbility, metamagicType) then
							-- ``(Really)ForceSpell()`` bypasses Invisibility and Sanctuary, so we need to check them...
							if GT_Metamagic_InvisibilitySanctuary(sprite, action, spellHeader, metamagicType) then
								-- ``(Really)ForceSpell()`` bypasses Silence, so we need to check it...
								if GT_Metamagic_Silence(sprite, spellHeader, metamagicType) then
									-- ``(Really)ForceSpell()`` ignores the caster's aura, so we need to check it...
									if not (metamagicType == 1 or metamagicType == 5) or (EEex_Sprite_GetCastTimer(sprite) == -1 or EEex_Sprite_GetStat(sprite, GT_Resource_SymbolToIDS["stats"]["AURACLEANSING"]) > 0) then
										-- check if the caster has at least one spell memorized of level ``spellLevel`` + X, X depending on the selected metamagic feat...
										if GT_Metamagic_ConsumeSlots(sprite, spellHeader, metamagicType, spellResRef) then
											--
											sprite:applyEffect({
												["effectID"] = 408, -- Projectile mutator
												["durationType"] = 1,
												["effectAmount"] = metamagicType,
												["res"] = "GTMMAGIC",
												["m_sourceRes"] = "CDMMAGIC",
												["sourceID"] = sprite.m_id,
												["sourceTarget"] = sprite.m_id,
											})
											--
											if metamagicType == 1 then
												GT_Metamagic_QuickenSpell(sprite, action, casterLevel)
											elseif metamagicType == 5 then
												-- store CURHITPOINTS as soon as the action starts...
												sprite:setLocalInt("gtSilentSpellStartingHP", sprite.m_baseStats.m_hitPoints)
												-- ``ForceSpell()`` cannot be interrupted, so we have to manually do that...
												sprite:applyEffect({
													["effectID"] = 232, -- Cast spell on condition
													["durationType"] = 1,
													["dwFlags"] = 11, -- TookDamage()
													["res"] = "CD#MMSIL",
													["m_sourceRes"] = "CDMMAGIC",
													["sourceID"] = sprite.m_id,
													["sourceTarget"] = sprite.m_id,
												})
												--
												GT_Metamagic_SilentSpell(sprite, action, casterLevel)
											end
										else
											action.m_actionID = 0 -- nuke current action
											sprite:applyEffect({
												["effectID"] = 139, -- Display string
												["durationType"] = 1,
												["effectAmount"] = %strref_CasterDoesNotMeetRequirements%,
												["sourceID"] = sprite.m_id,
												["sourceTarget"] = sprite.m_id,
											})
										end
									else
										action.m_actionID = 0 -- nuke current action
										sprite:applyEffect({
											["effectID"] = 139, -- Display string
											["durationType"] = 1,
											["effectAmount"] = %strref_AuraFree%,
											["sourceID"] = sprite.m_id,
											["sourceTarget"] = sprite.m_id,
										})
									end
								else
									action.m_actionID = 0 -- nuke current action
									sprite:applyEffect({
										["effectID"] = 139, -- Display string
										["durationType"] = 1,
										["effectAmount"] = %strref_CasterSilenced%,
										["sourceID"] = sprite.m_id,
										["sourceTarget"] = sprite.m_id,
									})
								end
							else
								action.m_actionID = 0 -- nuke current action
								sprite:applyEffect({
									["effectID"] = 139, -- Display string
									["durationType"] = 1,
									["effectAmount"] = %strref_InvisibleOrSanctuaried%,
									["sourceID"] = sprite.m_id,
									["sourceTarget"] = sprite.m_id,
								})
							end
						else
							action.m_actionID = 0 -- nuke current action
							sprite:applyEffect({
								["effectID"] = 139, -- Display string
								["durationType"] = 1,
								["effectAmount"] = %strref_OutOfRange%,
								["sourceID"] = sprite.m_id,
								["sourceTarget"] = sprite.m_id,
							})
						end
					else
						action.m_actionID = 0 -- nuke current action
						sprite:applyEffect({
							["effectID"] = 139, -- Display string
							["durationType"] = 1,
							["effectAmount"] = %strref_SpellcastingDisabled%,
							["sourceID"] = sprite.m_id,
							["sourceTarget"] = sprite.m_id,
						})
					end
				else
					-- remove op408 (in case of an innate spell)
					sprite:applyEffect({
						["effectID"] = 321, -- Remove effects by resource
						["durationType"] = 1,
						["res"] = "CDMMAGIC",
						["sourceID"] = sprite.m_id,
						["sourceTarget"] = sprite.m_id,
					})
				end
			else
				-- remove op408
				sprite:applyEffect({
					["effectID"] = 321, -- Remove effects by resource
					["durationType"] = 1,
					["res"] = "CDMMAGIC",
					["sourceID"] = sprite.m_id,
					["sourceTarget"] = sprite.m_id,
				})
			end
		else
			-- remove op408 (in case the spell gets disrupted)
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["durationType"] = 1,
				["res"] = "CDMMAGIC",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)
