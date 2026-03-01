---@meta _
-- globals we define are private to our plugin!
---@diagnostic disable: lowercase-global


-- General strategy is to hard override the loot choices count to whatever is configured
-- Then for rewards that should not have increased choices (either config or NPC rewards),
-- just return nil instead of creating the boon button (but leave reward count at configured value)
-- Then later we have to do some additional cleanup of the UpgradeButtons table to remove the excess nils so that vow/concave stone work

-- Dictates how many loot choices game should try to show
modutil.mod.Path.Override("GetTotalLootChoices", function()
	return GetTotalLootChoices_override()
end)

-- Dictates how many loot choices game will actually show
modutil.mod.Path.Override("CalcNumLootChoices", function(isGodLoot, treatAsGodLootByShops)
	return CalcNumLootChoices_override(isGodLoot, treatAsGodLootByShops)
end)

-- Builds an individual boon slot on the boon offering screen
modutil.mod.Path.Wrap("CreateUpgradeChoiceButton", function(base, screen, lootData, itemIndex, itemData )
	return CreateUpgradeChoiceButton_wrap(base, screen, lootData, itemIndex, itemData )
end)

-- Builds the full set of boon loot UI elements.  Mod is using this for cleanup when the reward is from an excluded subject
modutil.mod.Path.Wrap("CreateBoonLootButtons", function(base, screen, lootData, reroll )
	return CreateBoonLootButtons_wrap(base, screen, lootData, reroll )
end)

-- On reroll, make sure we clean up the extra boon slots that were added if any
modutil.mod.Path.Wrap("DestroyBoonLootButtons", function(base, screen, lootData )
	return DestroyBoonLootButtons_wrap(base, screen, lootData )
end)

-- Reroll rewards if config has changed since room load (when loot is initially rolled)
modutil.mod.Path.Wrap("HandleLootPickup", function(base, currentRun, loot, args )
	return HandleLootPickup_wrap(base, currentRun, loot, args )
end)

-- Ensure vow of forsaking and concave stone work as expected
modutil.mod.Path.Wrap("HandleUpgradeChoiceSelection", function(base, screen, button, args )
	HandleUpgradeChoiceSelection_wrap(base, screen, button, args)
end)

-- TryUpgradeBoon Context

-- Make this a no-op in this specific context unless we set a flag, so that we can call it later in the method instead
-- This is to fix an SGG bug where the rarify animation is attached to the previous version of the button (thats destroyed) instead of the rarified one - this breaks the scaling
function TryUpgradeBoon_context_UpgradeBoonRarityPresentation_wrap(base, button)
	if button.PlayRarityPresentation then
		base(button)
	end
end

-- Set flag and manually call UpgradeBoonRarityPresentation with new rarified button instead of old, destroyed button
function TryUpgradeBoon_context_CreateUpgradeChoiceButton_wrap(base, ...)
	local button = base(...)
	button.PlayRarityPresentation = true
	game.UpgradeBoonRarityPresentation(button)
	return button
end

-- Wrap the following functions but only within the TryUpgradeBoon context
function TryUpgradeBoon_context()
	modutil.mod.Path.Wrap("UpgradeBoonRarityPresentation", TryUpgradeBoon_context_UpgradeBoonRarityPresentation_wrap)
	modutil.mod.Path.Wrap("CreateUpgradeChoiceButton", TryUpgradeBoon_context_CreateUpgradeChoiceButton_wrap)
end
modutil.mod.Path.Context.Wrap("TryUpgradeBoon", TryUpgradeBoon_context)

-- Update the number of loot choices to use on each room load.  If changed mid-room, we need to reroll the rewards on the loot on pickup
-- (since it was already rolled with the previous config on room load)
OnAnyLoad{ function()
	loot_choices_at_room_load = getLootChoiceCount()
end}