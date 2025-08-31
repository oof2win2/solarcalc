--- @param params {surface: LuaSurface, solar_panel_name: string, accumulator_name: string}
--- @returns number
local function compute_ratio(params)
    local surface = params.surface
    if surface.always_day then return 1 end
    -- get solar power output in kW
    local solar_power = prototypes.entity[params.solar_panel_name].get_max_energy_production() * 60 / 1000
    -- accu buffer capacity in kJ
    local accu_charge = prototypes.entity[params.accumulator_name].electric_energy_source_prototype.buffer_capacity / 1000
    
    local ticks_per_day = surface.ticks_per_day
    -- we get the dusk, dawn etc as the tick when the parts of day start
    -- ie the surface.dusk is the time when dusk starts
    local day_start = surface.dawn
    local sunset_start = surface.dusk
    local night_start = surface.evening
    local sunrise_start = surface.morning

    local sunset_len = (surface.ticks_per_day * (night_start - sunset_start)) / ticks_per_day
    local night_len = surface.ticks_per_day * (sunrise_start - night_start) / ticks_per_day
    local sunrise_len = surface.ticks_per_day * (day_start - sunrise_start) / ticks_per_day
    local day_len = 1
        - sunset_len
        - night_len
        - sunrise_len

    local ratio = ((day_len + sunrise_len / 2 + sunset_len / 2) * (night_len + (sunrise_len + sunset_len) / 2 * ((day_len + sunrise_len / 2 + sunset_len / 2) / 1))) *
        (ticks_per_day / 60) * (solar_power * surface.solar_power_multiplier / accu_charge)

    return ratio
end

return compute_ratio