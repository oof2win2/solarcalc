commands.add_command("calculate", nil, function(command)
    if command.player_index == nil then return end
    local surface = game.get_player(command.player_index).surface
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

    local accu_charge = 5000
    local solar_power = 60

    local ratio = ((day_len + sunrise_len / 2 + sunset_len / 2) * (night_len + (sunrise_len + sunset_len) / 2 * ((day_len + sunrise_len / 2 + sunset_len / 2) / 1))) *
        (ticks_per_day / 60) * (solar_power * surface.solar_power_multiplier / accu_charge)
    game.print(ratio)
end)
