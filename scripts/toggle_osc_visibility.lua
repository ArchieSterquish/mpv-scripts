local is_visible = false                                                -- Tracking variable to know in which we're currently in (FALSE - never, TRUE - always)
local INITIAL_STATE = "never"                                           -- State that always starts in mpv (see conf files which state is currently initialized)
local FINISH_STATE = "always"                                           -- State to change to/from

local function toggle_osc_visibility()                                 
    is_visible = not is_visible                                         -- Toggling variable
    local new_state = is_visible and FINISH_STATE or INITIAL_STATE      -- Changing state   
    mp.commandv("script-message", "osc-visibility", new_state,"no-osd") -- Setting new state
    mp.osd_message("OSC visibilty: " .. new_state)                      -- Showing message about changing state
end
mp.add_key_binding("", "osc-visibility-toggle", toggle_osc_visibility)  -- Making function invokable from mpv