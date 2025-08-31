local compute_ratio = require("__solarcalc__.scripts.ratio")

local main_gui = {}

function main_gui.destroy(player_index)
    local self = storage.guis[player_index]
    if not self then return end
    if self.window.valid then self.window.destroy() end
    storage.guis[player_index] = nil
end

function main_gui.build(player_index)
    -- toggle the center gui that floats, allowing the user to input the solar panels used, accumulators used, and surface
    local player = game.players[player_index]
    if not player then return end
    local screen_element = player.gui.screen
    local window = screen_element.add {
        type = "frame",
        name = "solarcalc_main_gui",
        direction = "vertical"
    }

    window.style.size = { 535, 195 }
    window.auto_center = true

    local header = window.add {
        type = "flow",
        name = "header_flow",
        direction = "horizontal",
        style = "flib_titlebar_flow"
    }
    header.drag_target = window
    header.add {
        type = "label",
        name = "header_label",
        caption = "Solar Calculator",
        style = "flib_frame_title"
    }
    header.add { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true }
    header.add {
        type = "sprite-button",
        name = "solarcalc_header_button",
        sprite = "utility/close",
        style = "frame_action_button"
    }

    local content_frame = window.add { type = "frame", name = "content_frame", direction = "vertical", style = "solarcalc_content_frame" }
    local controls_flow = content_frame.add { type = "flow", name = "controls_flow", direction = "horizontal", style = "solarcalc_controls_flow" }

    local selected_index = -1
    local player_surface = storage.preferences[player_index].surface_index
    local surfaces = {}
    local i = 1
    for _, surface in pairs(game.surfaces) do
        if surface.index == player_surface then selected_index = i
        else i = i + 1 end
        table.insert(surfaces, surface.name)
    end
    
    controls_flow.add {
        type = "drop-down",
        name = "solarcalc_surface_selector",
        items = surfaces,
        selected_index = selected_index
    }

    controls_flow.add {
        type = "choose-elem-button",
        name = "solarcalc_solarpanel_selector",
        elem_type = "item",
        item = storage.preferences[player_index].solar_panel_name,
        elem_filters = {{ filter = "place-result", elem_filters = {{ filter = "type", type = "solar-panel" }} }}
    }
    controls_flow.add {
        type = "choose-elem-button",
        name = "solarcalc_accumulator_selector",
        elem_type = "item",
        item = storage.preferences[player_index].accumulator_name,
        elem_filters = {{ filter = "place-result", elem_filters = {{ filter = "type", type = "accumulator" }} }}
    }

    local textinput = controls_flow.add { type = "textfield", name = "solarcalc_power_requirement_input", numeric = true, text = "1" }
    textinput.style.width = 64
    textinput.style.horizontal_align = "right"
    local selected_unit_index = 1
    if storage.preferences[player.index].power_requirement_unit == "GW" then selected_unit_index = 2 end
    controls_flow.add { type = "drop-down", items = {"MW", "GW"}, selected_index = selected_unit_index, name = "solarcalc_power_requirement_input_unit" }

    -- content_frame.add { type = "line"}
    local output_flow = content_frame.add { type = "flow", name = "output_flow", direction = "horizontal", style = "solarcalc_controls_flow" }
    local output_table = output_flow.add {
        type = "table",
        column_count = 2,
        draw_horizontal_lines = true,
        vertical_centering = false
    }
    output_table.add { type = "label", caption = "Solar Ratio" }
    output_table.add { type = "label", caption = string.format("%.3f", storage.computations[player_index].solar_ratio), name = "solarcalc-ratio-output" }
    output_table.add { type = "label", caption = "Solar panel count" }
    output_table.add { type = "label", caption = tostring(string.format("%.3f", storage.computations[player_index].panels_required)), name = "solarcalc-panels-required" }
    output_table.add { type = "label", caption = "Accumulator count" }
    output_table.add { type = "label", caption = tostring(string.format("%.3f", storage.computations[player_index].accumulators_required)), name = "solarcalc-accumulators-required" }


    local self = {
        window = window,
        output_flow = output_table
    }
    storage.guis[player.index] = self

    return self
end

function main_gui.toggle(player_index)
    local self = storage.guis[player_index]
    if not self then
        main_gui.build(player_index)
        -- main_gui.recompute_all_data(player_index)
    else
        main_gui.destroy(player_index) 
    end
end

function main_gui.recompute_ratio(player_index)
    local solar_panel_name = storage.preferences[player_index].solar_panel_name
    local accumulator_name = storage.preferences[player_index].accumulator_name
    local surface_index = storage.preferences[player_index].surface_index

    local ratio = 0

    if solar_panel_name ~= nil and accumulator_name ~= nil and surface_index ~= nil then
        ratio = compute_ratio{
            solar_panel_name = solar_panel_name,
            surface = game.surfaces[surface_index],
            accumulator_name = accumulator_name
        }
    end

    if storage.guis[player_index] then
        storage.guis[player_index].output_flow["solarcalc-ratio-output"].caption = string.format("%.3f", ratio)
    end

    storage.computations[player_index].solar_ratio = ratio
end

function main_gui.recompute_outputs(player_index)
    local surface = game.surfaces[storage.preferences[player_index].surface_index]

    local requested_power = storage.preferences[player_index].power_requirement
    local unit = storage.preferences[player_index].power_requirement_unit

    local requested_power_kw = requested_power * 1000
    if unit == "GW" then requested_power_kw = requested_power_kw * 1000 end

    local solar_panel_name = storage.preferences[player_index].solar_panel_name
    if solar_panel_name == nil then return end
    local solar_power_kw = prototypes.entity[solar_panel_name].get_max_energy_production() * 60 / 1000
    local accumulator_name = storage.preferences[player_index].accumulator_name
    if accumulator_name == nil then return end
    local accumulator_charge = prototypes.entity[accumulator_name].electric_energy_source_prototype.buffer_capacity / 1000

    local day_start = surface.dawn
    local sunset_start = surface.dusk
    local night_start = surface.evening
    local sunrise_start = surface.morning

    local sunset_len = (surface.ticks_per_day * (night_start - sunset_start))
    local night_len = surface.ticks_per_day * (sunrise_start - night_start)
    local sunrise_len = surface.ticks_per_day * (day_start - sunrise_start)
    local day_len = surface.ticks_per_day
        - sunset_len
        - night_len
        - sunrise_len

    local day_max_power = requested_power_kw * surface.ticks_per_day / (day_len + sunrise_len / 2 + sunset_len / 2)
    local solar_panel_count = day_max_power / solar_power_kw


    local required_accumulator_charge = requested_power_kw * (night_len + (sunrise_len / 2 + sunset_len / 2) * requested_power_kw / day_max_power) / 60
    local accumulator_count = required_accumulator_charge / accumulator_charge

    
    storage.computations[player_index].panels_required = solar_panel_count
    storage.computations[player_index].accumulators_required = accumulator_count


    if storage.guis[player_index] then
        local output_flow = storage.guis[player_index].output_flow
        output_flow["solarcalc-panels-required"].caption = tostring(string.format("%.3f",solar_panel_count))
        output_flow["solarcalc-accumulators-required"].caption = tostring(string.format("%.3f",accumulator_count))
    end
end

function main_gui.recompute_all_data(player_index)
    main_gui.recompute_ratio(player_index)
    main_gui.recompute_outputs(player_index)
end

---@param event EventData.on_gui_text_changed
local function on_gui_text_changed(event)
    if event.element.name == "solarcalc_power_requirement_input" then
        local value = tonumber(event.element.text)
        storage.preferences[event.player_index].power_requirement = value
        main_gui.recompute_outputs(event.player_index)
    end
end

--- @param event EventData.on_gui_click
local function on_gui_click(event)
    if event.element.name == "solarcalc_toggle" then
        main_gui.toggle(event.player_index)
    end
    if event.element.name == "solarcalc_header_button" then
        main_gui.destroy(event.player_index)
    end
end

--- @param event EventData.on_gui_elem_changed
local function on_gui_elem_changed(event)
    if event.element.name == "solarcalc_solarpanel_selector" then
        local selected = event.element.elem_value
        storage.preferences[event.player_index].solar_panel_name = selected
        main_gui.recompute_all_data(event.player_index)
    end
    if event.element.name == "solarcalc_accumulator_selector" then
        local selected = event.element.elem_value
        storage.preferences[event.player_index].accumulator_name = selected
        main_gui.recompute_all_data(event.player_index)
    end
end

--- @param event EventData.on_gui_selection_state_changed
local function on_gui_selection_state_changed(event)
    if event.element.name == "solarcalc_surface_selector" then
        local selected = event.element.items[event.element.selected_index]
        local surface = game.get_surface(selected)
        if not surface then return end
        storage.preferences[event.player_index].surface_index = surface.index
        main_gui.recompute_all_data(event.player_index)
    end

    if event.element.name == "solarcalc_power_requirement_input_unit" then
        local selected = event.element.items[event.element.selected_index]
        storage.preferences[event.player_index].power_requirement_unit = selected
        main_gui.recompute_all_data(event.player_index)
    end
end

local function on_player_created(event)
    local surface_index = game.get_player(event.player_index).surface_index
    storage.preferences[event.player_index] = {
        solar_panel_name = "solar-panel",
        accumulator_name = "accumulator",
        surface_index = surface_index,
        power_requirement = 1,
        power_requirement_unit = "MW"
    }
    storage.computations[event.player_index] = {
        solar_ratio = 0,
        panels_required = 0,
        accumulators_required = 0
    }

    main_gui.recompute_all_data(event.player_index)
end

function main_gui.on_init(event)
    storage.guis = {}
    storage.preferences = {}
    storage.computations = {}
end

main_gui.events = {
    [defines.events.on_gui_text_changed] = on_gui_text_changed,
    [defines.events.on_gui_click] = on_gui_click,
    [defines.events.on_gui_elem_changed] = on_gui_elem_changed,
    [defines.events.on_player_created] = on_player_created,
    [defines.events.on_gui_selection_state_changed] = on_gui_selection_state_changed
}

return main_gui
