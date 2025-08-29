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

    local sunset_len = surface.ticks_per_day * (night_start - sunset_start)
    local night_len = surface.ticks_per_day * (sunrise_start - night_start)
    local sunrise_len = surface.ticks_per_day * (day_start - sunrise_start)
    local day_len = surface.ticks_per_day
        - sunset_len
        - night_len
        - sunrise_len

    -- Log the results
    game.print("=== Solar Cycle Durations ===")
    game.print(string.format("Total ticks per day: %d", ticks_per_day))
    game.print("")

    -- Display durations with both ticks and percentage
    game.print(string.format("Dawn duration (sunrise): %d ticks (%.2f%% of day)",
        sunrise_len, (sunrise_len / ticks_per_day) * 100))
    game.print(string.format("Day duration (full light): %d ticks (%.2f%% of day)",
        day_len, (day_len / ticks_per_day) * 100))
    game.print(string.format("Dusk duration (sunset): %d ticks (%.2f%% of day)",
        sunset_len, (sunset_len / ticks_per_day) * 100))
    game.print(string.format("Night duration (darkness): %d ticks (%.2f%% of day)",
        night_len, (night_len / ticks_per_day) * 100))
    game.print("")

    -- Verify our calculations add up to a full day
    local total_duration = sunrise_len + day_len + sunset_len + night_len
    local difference = math.abs(total_duration - ticks_per_day)
    if difference < 1 then
        game.print(string.format("✓ Verification passed: Total = %d ticks (difference: %.2f)",
            total_duration, difference))
    else
        game.print(string.format("⚠ Warning: Total = %d ticks, expected %d (difference: %.2f)",
            total_duration, ticks_per_day, difference))
    end
    game.print("")
end)
