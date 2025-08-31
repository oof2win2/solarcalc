local flib_gui = require("__flib__.gui")
local mod_gui = require("__core__.lualib.mod-gui")

local main_gui = require("scripts.gui.main")

--- @param player LuaPlayer
local function refresh_button(player)
    local button_flow = mod_gui.get_button_flow(player)
    if button_flow.solarcalc_toggle then
        button_flow.solarcalc_toggle.destroy()
    end
    button_flow.add({
        type = "sprite-button",
        name = "solarcalc_toggle",
        style = mod_gui.button_style,
        tooltip = { "", { "gui.solarcalc" }, " (", { "gui.control_toggle" }, ")" },
        sprite = "item/solar-panel",
        tags = flib_gui.format_handlers({ [defines.events.on_gui_click] = main_gui.toggle }),
    }).style.padding =
        7
end

--- @param e EventData.on_player_created
local function on_player_created(e)
    local player = game.get_player(e.player_index)
    if not player then
        return
    end
    refresh_button(player)
end

--- @param e EventData.on_runtime_mod_setting_changed
local function on_runtime_mod_setting_changed(e)
    if e.setting ~= "solarcalc-show-overhead-button" then
        return
    end
    local player = game.get_player(e.player_index)
    if not player then
        return
    end
    refresh_button(player)
end

local overhead_button = {}

function overhead_button.on_init()
    for _, player in pairs(game.players) do
        refresh_button(player)
    end
end

function overhead_button.on_configuration_changed()
    for _, player in pairs(game.players) do
        refresh_button(player)
    end
end

overhead_button.events = {
    [defines.events.on_player_created] = on_player_created,
    [defines.events.on_runtime_mod_setting_changed] = on_runtime_mod_setting_changed,
}

return overhead_button
