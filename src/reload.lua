---@meta _
---@diagnostic disable: lowercase-global

local boonSlotObtacleNames = {
	[3] = "BoonSlotBase",
	[4] = "BoonSlotBaseFourOptions",
	[5] = "BoonSlotBaseFiveOptions",
	[6] = "BoonSlotBaseSixOptions"
}

local indicesToRemove = {}

local is_god_boon = {
	ZeusUpgrade = true,
	HeraUpgrade = true,
	PoseidonUpgrade = true,
	ApolloUpgrade = true,
	DemeterUpgrade = true,
	HestiaUpgrade = true,
	AphroditeUpgrade = true,
	HephaestusUpgrade = true,
	HermesUpgrade = true,
	ArtemisUpgrade = true,
	AresUpgrade = true,
}

function isBoonSubjectExcluded(subjectName)
	print("SubjectName: " .. tostring(subjectName))

	if subjectName == nil or subjectName:sub(1,3) == "NPC" then return true end
	if is_god_boon[subjectName] then
		return not config.GodUpgrade_enabled
	else
    	return not config[subjectName .. "_enabled"]
	end
end

-- TODO: Change these to selectively give the configured choices or vanilla depending on excludedSubjects?
function GetTotalLootChoices_override()
	return getCurrentLootChoices()
end

function CalcNumLootChoices_override(isGodLoot, treatAsGodLootByShops)
	local numChoices = getCurrentLootChoices() -- GetNumMetaUpgrades function doesn't exist anymore
	if (isGodLoot or treatAsGodLootByShops) and HasHeroTraitValue("RestrictBoonChoices") then
			numChoices = numChoices - 1
	end
	return numChoices
end

-- Main meat of the mod
function CreateUpgradeChoiceButton_wrap(base, screen, lootData, itemIndex, itemData )
	if config.enabled ~= true or isBoonSubjectExcluded(screen.SubjectName) then
		-- I'm worried this will break something down the line and also probably doesn't play nice with never see boon again heat
		if itemIndex > 3 then
			-- Attempt to fix "never see boon again" heat by cleaning up the extra nils after all buttons are created - but I think the list is used prior to this cleanup
			table.insert(indicesToRemove, itemIndex)
			return {Id = nil}
		end

		print("Using default boon screen behavior because " .. tostring(screen.SubjectName) .. " is excluded")
		return base(screen, lootData, itemIndex, itemData)
	end

	local numChoices = getCurrentLootChoices()
	screen.MaxChoices = numChoices
	local scaleFactor = 3.0 / numChoices
	screen.PurchaseButton.Name = boonSlotObtacleNames[numChoices]

	-- Set up static data that determines how the layout is built
	resizeBoonScreenData(screen, scaleFactor, numChoices)
	
	local button = base(screen, lootData, itemIndex, itemData)

	-- Resize and move components after they've been drawn to screen
	resizeBoonScreenComponents(screen, itemIndex, scaleFactor, numChoices)

	return button
end

function logScreenProperties(screen)
	print("=== SCREEN PROPERTIES ===")
	for key, value in pairs(screen) do
		if type(value) ~= "table" then
			print(key .. ": " .. tostring(value))
		else
			print(key .. " (table):")
			for subKey, subValue in pairs(value) do
				if type(subValue) ~= "table" and type(subValue) ~= "function" then
					print("  " .. subKey .. ": " .. tostring(subValue))
				elseif type(subValue) == "table" then
					print("  " .. subKey .. " (table)")
				end
			end
		end
	end
	print("========================")
end

function resizeBoonScreenData(screen, scaleFactor, numChoices)

	local sizeFont = numChoices > 3 and  18 or 20

	screen.ButtonSpacingY = rom.game.ScreenData.UpgradeChoice.ButtonSpacingY * scaleFactor
	--screen.LineHeight = rom.game.ScreenData.UpgradeChoice.LineHeight * scaleFactor

	screen.StatLineLeft.LineSpacingBottom = rom.game.ScreenData.UpgradeChoice.StatLineLeft.LineSpacingBottom * scaleFactor
	screen.StatLineRight.LineSpacingBottom = rom.game.ScreenData.UpgradeChoice.StatLineLeft.LineSpacingBottom * scaleFactor

	screen.StatLineLeft.FontSize = sizeFont * scaleFactor ^ (1/3)
	screen.StatLineRight.FontSize = sizeFont * scaleFactor ^ (1/3)

	-- Scaling FontSize by cube root looks better, tested and suggested by dwbl.
	screen.RarityText.OffsetY = rom.game.ScreenData.UpgradeChoice.RarityText.OffsetY * scaleFactor
	screen.RarityText.FontSize = sizeFont * scaleFactor ^ (1/3)
	screen.TitleText.OffsetY = rom.game.ScreenData.UpgradeChoice.TitleText.OffsetY * scaleFactor
	screen.TitleText.FontSize = sizeFont * scaleFactor ^ (1/3)
	screen.DescriptionText.OffsetY = rom.game.ScreenData.UpgradeChoice.DescriptionText.OffsetY * scaleFactor * scaleFactor
	screen.DescriptionText.FontSize = sizeFont * scaleFactor ^ (1/3)
	-- screen.DescriptionText.TextSymbolScale = rom.game.ScreenData.UpgradeChoice.DescriptionText.TextSymbolScale * scaleFactor

	screen.IconOffsetY = rom.game.ScreenData.UpgradeChoice.IconOffsetY * scaleFactor
	screen.ExchangeIconOffsetY = rom.game.ScreenData.UpgradeChoice.ExchangeIconOffsetY * scaleFactor
	screen.ExchangeIconOffsetX = rom.game.ScreenData.UpgradeChoice.ExchangeIconOffsetX + 5  * (numChoices - 3)
	screen.ExchangeSymbol.OffsetX = rom.game.ScreenData.UpgradeChoice.ExchangeSymbol.OffsetX + 5  * (numChoices - 3)
	screen.BonusIconOffsetY = rom.game.ScreenData.UpgradeChoice.BonusIconOffsetY * scaleFactor
	screen.QuestIconOffsetY = rom.game.ScreenData.UpgradeChoice.QuestIconOffsetY * scaleFactor
	screen.PoseidonDuoIconOffsetY = rom.game.ScreenData.UpgradeChoice.PoseidonDuoIconOffsetY * scaleFactor

	screen.ElementIcon.YShift = rom.game.ScreenData.UpgradeChoice.ElementIcon.YShift * scaleFactor

	screen.ExchangeSymbol.OffsetY = rom.game.ScreenData.UpgradeChoice.ExchangeSymbol.OffsetY * scaleFactor
	
	-- Log all screen properties for debugging
	--logScreenProperties(screen)
end

-- Some components are not created via ScreenData config, so we rescale and tweak them after their creation
function resizeBoonScreenComponents(screen, itemIndex, scaleFactor, numChoices)
	local components = screen.Components
	local purchaseButtonKey = "PurchaseButton"..itemIndex

	SetScaleY({ Id = components[purchaseButtonKey].Id, Fraction = scaleFactor, Duration = 0 })
	-- SetScaleX({ Id = components[purchaseButtonKey].Id, Fraction = 1 / scaleFactor, Duration = 0 })
	components[purchaseButtonKey].ScaleFactor = scaleFactor
	
	SetScaleY({ Id = components[purchaseButtonKey.."Highlight"].Id, Fraction = scaleFactor, Duration = 0 })
	-- Move highlight up by 10% to match button

	-- The icons stop overlapping the boon properly when scaled down, so shift them a bit right to look normal again
	SetScaleX({ Id = components[purchaseButtonKey.."Icon"].Id, Fraction = scaleFactor, Duration = 0 })
	SetScaleY({ Id = components[purchaseButtonKey.."Icon"].Id, Fraction = scaleFactor, Duration = 0 })
	if (numChoices ~= 3) then -- Move of Distance = 0 puts component to top left corner of screen
		Move({ Id = components[purchaseButtonKey.."Icon"].Id, Angle = 360, Distance = 5  * (numChoices - 3) })
	end

	SetScaleX({ Id = components[purchaseButtonKey.."Frame"].Id, Fraction = scaleFactor, Duration = 0 })
	SetScaleY({ Id = components[purchaseButtonKey.."Frame"].Id, Fraction = scaleFactor, Duration = 0 })
	if (numChoices ~= 3) then -- Move of Distance = 0 puts component to top left corner of screen
		Move({ Id = components[purchaseButtonKey.."Frame"].Id, Angle = 360, Distance = 5  * (numChoices - 3) })
	end

	-- TODO: shift this down left ~5 pixels once vanilla UI is referenced
	if (components[purchaseButtonKey.."ElementIcon"] ~= nil) then
		SetScaleX({ Id = components[purchaseButtonKey.."ElementIcon"].Id, Fraction = scaleFactor, Duration = 0 })
		SetScaleY({ Id = components[purchaseButtonKey.."ElementIcon"].Id, Fraction = scaleFactor, Duration = 0 })
	end

	if (components[purchaseButtonKey.."ExchangeSymbol"] ~= nil
			and components[purchaseButtonKey.."ExchangeIcon"] ~= nil
			and components[purchaseButtonKey.."ExchangeIconFrame"] ~= nil) then
		SetScaleX({ Id = components[purchaseButtonKey.."ExchangeSymbol"].Id, Fraction = scaleFactor, Duration = 0 })
		SetScaleY({ Id = components[purchaseButtonKey.."ExchangeSymbol"].Id, Fraction = scaleFactor, Duration = 0 })

		SetScaleX({ Id = components[purchaseButtonKey.."ExchangeIcon"].Id, Fraction = scaleFactor, Duration = 0 })
		SetScaleY({ Id = components[purchaseButtonKey.."ExchangeIcon"].Id, Fraction = scaleFactor, Duration = 0 })


		SetScaleX({ Id = components[purchaseButtonKey.."ExchangeIconFrame"].Id, Fraction = scaleFactor, Duration = 0 })
		SetScaleY({ Id = components[purchaseButtonKey.."ExchangeIconFrame"].Id, Fraction = scaleFactor, Duration = 0 })


		if (numChoices ~= 3) then -- Move of Distance = 0 puts component to top left corner of screen
			Move({ Id = components[purchaseButtonKey.."ExchangeSymbol"].Id, Angle = 360, Distance = 5  * (numChoices - 3) })
			Move({ Id = components[purchaseButtonKey.."ExchangeIcon"].Id, Angle = 360, Distance = 5  * (numChoices - 3) })
			Move({ Id = components[purchaseButtonKey.."ExchangeIconFrame"].Id, Angle = 360, Distance = 5  * (numChoices - 3) })
		end
	end

	if (components[purchaseButtonKey.."QuestIcon"] ~= nil) then
		SetScaleX({ Id = components[purchaseButtonKey.."QuestIcon"].Id, Fraction = scaleFactor , Duration = 0 })
		SetScaleY({ Id = components[purchaseButtonKey.."QuestIcon"].Id, Fraction = scaleFactor, Duration = 0 })
	end
end

function CreateBoonLootButtons_wrap( base, screen, lootData, reroll )
	local returnVal = base(screen, lootData, reroll)
	-- Delete off the end of the list past 3 rewards as needed if this is an excluded subject
	-- Grab reward from active screens because lootData here is different and doesn't have subject name
	if isBoonSubjectExcluded(rom.mods['SGG_Modding-ModUtil'].mod.Path.Get("ActiveScreens.UpgradeChoice.SubjectName")) then
		for _, index in ipairs(indicesToRemove) do
			print("Deleting extra table values from upgradeOptions")
			table.remove(screen.UpgradeButtons)
		end
	end
	indicesToRemove = {}
	return returnVal
end

function DestroyBoonLootButtons_wrap( base, screen, lootData )
	base(screen, lootData)

	-- For each extra boon we displayed, also delete those
    local components = screen.Components
    local toDestroy = {}
    for index = 3, CHOICE_LIMIT.MAX do -- do all the way to 6 blindly in case config has changed since menu was opened
        local destroyIndexes = {
			"PurchaseButton"..index,
			"PurchaseButton"..index.. "Lock",
			"PurchaseButton"..index.. "Highlight",
			"PurchaseButton"..index.. "Icon",
			-- "PurchaseButton"..index.. "ExchangeSymbol", -- Is the exclusion of this an SGG bug or because its not an anim?
			"PurchaseButton"..index.. "ExchangeIcon",
			"PurchaseButton"..index.. "ExchangeIconFrame",
			"PurchaseButton"..index.. "QuestIcon",
			"PurchaseButton"..index.. "ElementIcon",
			"Backing"..index,
			"PurchaseButton"..index.. "Frame",
			"PurchaseButton"..index.. "Patch",
        }
        for i, indexName in pairs( destroyIndexes ) do
            if components[indexName] then
                table.insert(toDestroy, components[indexName].Id)
                components[indexName] = nil
            end
        end
    end
    Destroy({ Ids = toDestroy })
end

function HandleLootPickup_wrap(base, currentRun, loot, args )
	local currentChoices = getCurrentLootChoices()
	if (loot_choices_at_room_load ~= currentChoices) then
		print("Loot choice at room load: " .. tostring(loot_choices_at_room_load) .. ", loot choices configured: " .. currentChoices .. " - Rerolling rewards")
		SetTraitsOnLoot(loot, args)
	end
	base(currentRun, loot, args)
end

function HandleUpgradeChoiceSelection_wrap(base, screen, button, args )
	screen.UpgradeButtons = game.CollapseTable(screen.UpgradeButtons) -- CollapseTableOrderedByKeys seems to have been replaced with CollapseTable, but it doesn't use OrderedPairs

	if config.vow_of_forsaking == VowOptions.RANDOM then
		-- UpgradeButtons are only used for concave stone + vow of forsaking at this point, so shuffle them so vow choses random X instead of first X
		FYShuffle(screen.UpgradeButtons)
		base(screen, button, args)
	elseif config.vow_of_forsaking == VowOptions.ALL then
		local pre = game.DeepCopyTable(game.MetaUpgradeData.BanUnpickedBoonsShrineUpgrade.ChangeValue)
		game.MetaUpgradeData.BanUnpickedBoonsShrineUpgrade.ChangeValue = getCurrentLootChoices() - 1

		base(screen, button, args)

		game.MetaUpgradeData.BanUnpickedBoonsShrineUpgrade.ChangeValue = pre
	else
		base(screen, button, args)
	end
end
