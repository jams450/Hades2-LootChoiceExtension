---@meta _
-- grabbing our dependencies,
-- these funky (---@) comments are just there
--	 to help VS Code find the definitions of things

---@diagnostic disable-next-line: undefined-global
local mods = rom.mods

---@module 'SGG_Modding-ENVY-auto'
mods['SGG_Modding-ENVY'].auto()
-- ^ this gives us `public` and `import`, among others
--	and makes all globals we define private to this plugin.
---@diagnostic disable: lowercase-global

---@diagnostic disable-next-line: undefined-global
rom = rom
---@diagnostic disable-next-line: undefined-global
_PLUGIN = PLUGIN

---@module 'SGG_Modding-Hades2GameDef-Globals'
game = rom.game
import_as_fallback(game)

---@module 'SGG_Modding-SJSON'
sjson = mods['SGG_Modding-SJSON']
---@module 'SGG_Modding-ModUtil'
modutil = mods['SGG_Modding-ModUtil']

---@module 'SGG_Modding-Chalk'
chalk = mods["SGG_Modding-Chalk"]
---@module 'SGG_Modding-ReLoad'
reload = mods['SGG_Modding-ReLoad']

---@module 'config'
config = chalk.auto 'config.lua'
-- ^ this updates our `.cfg` file in the config folder!
public.config = config -- so other mods can access our config
loot_choices_at_room_load = config.choices

-- Mod is only set up to look good and function properly within these values
CHOICE_LIMIT = {
	MIN = 3,
	MAX = 6,
}

-- Generates a new loot choice count for the current room
-- If random_choices is enabled, returns a random value between MIN and MAX
-- Otherwise, returns the configured choices value
function getLootChoiceCount()
	if config.random_choices then
		return math.random(CHOICE_LIMIT.MIN, CHOICE_LIMIT.MAX)
	else
		return config.choices
	end
end

-- Returns the current loot choice count for this room
-- This value is set once when entering a room and remains constant throughout
function getCurrentLootChoices()
	return loot_choices_at_room_load
end

---@enum VowOptions
VowOptions = {
	RANDOM = "Random",
	ALL = "All"
}

local function on_ready()
	-- what to do when we are ready, but not re-do on reload.
	if config.enabled == false then return end

	rom.gui.add_imgui(function()
		if rom.ImGui.Begin("Configure") then
		rom.ImGui.Text("Number of reward choices:")

		local value, clicked = rom.ImGui.SliderInt("", config.choices, CHOICE_LIMIT.MIN, CHOICE_LIMIT.MAX)
		if clicked then
			config.choices = value
		end

		local random_value, random_clicked = rom.ImGui.Checkbox("Random choices (3-6)", config.random_choices)
		if random_clicked then config.random_choices = random_value end

		rom.ImGui.Text("Reward types enabled:")

			local value, clicked = rom.ImGui.Checkbox("Hammers", config.WeaponUpgrade_enabled)
			if clicked then config.WeaponUpgrade_enabled = value end
			local value, clicked = rom.ImGui.Checkbox("Poms", config.StackUpgrade_enabled)
			if clicked then config.StackUpgrade_enabled = value end
			local value, clicked = rom.ImGui.Checkbox("Chaos", config.TrialUpgrade_enabled)
			if clicked then config.TrialUpgrade_enabled = value end
			local value, clicked = rom.ImGui.Checkbox("Boons", config.GodUpgrade_enabled)
			if clicked then config.GodUpgrade_enabled = value end

			rom.ImGui.End()
		end
	end)

	import 'sjson.lua'
	import 'ready.lua'
end

local function on_reload()
	-- what to do when we are ready, but also again on every reload.
	-- only do things that are safe to run over and over.


	-- Other mods should override this value
	config.choices = math.min(CHOICE_LIMIT.MAX, math.max(CHOICE_LIMIT.MIN, config.choices))

	import 'reload.lua'
end

-- this allows us to limit certain functions to not be reloaded.
local loader = reload.auto_single()

-- this runs only when modutil and the game's lua is ready
modutil.once_loaded.game(function()
	loader.load(on_ready, on_reload)
end)
