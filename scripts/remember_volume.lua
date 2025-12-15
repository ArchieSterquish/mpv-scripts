-- Script to remember volume 
-- (I don't know why it's not built-in feature)

local filepath = mp.command_native({"expand-path", "~/.mpv_volume"})    -- Self-explanatory
local loadfile = io.open(filepath, "r")                                 -- Opening file

if loadfile then                                    
    set_volume = string.sub(loadfile:read(), 8)                         -- Getting last saved volume value
    loadfile:close()                                                    -- Closing file
    mp.set_property_number("volume", set_volume)                        -- Applying read volume value to mpv current volume value
end

-- Saving volume value on shutdown
mp.register_event("shutdown", 
    function()
        local savefile  = io.open(filepath, "w+")                       -- Opening file with writing modifier
        savefile:write("volume=" .. mp.get_property("volume"), "\n")    -- Writing contents of property 'volume'
        savefile:close()                                                -- Closing file
    end
)