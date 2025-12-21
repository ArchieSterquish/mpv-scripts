-- Small script to make player stay on top only while playing the media

local function on_pause_change(name, value)
    if value == true then
        mp.set_property("ontop", "no")
    else
        mp.set_property("ontop", "yes")
    end
end

mp.observe_property("pause", "bool", on_pause_change)