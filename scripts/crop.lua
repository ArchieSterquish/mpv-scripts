-- VLC style crop for mpv
-- uses hotkey 'c', same as VLC
-- https://github.com/kism/mpvscripts

require "mp.msg"
require "mp.options"

local crop_option = 0
local cropstring = string.format("%s-crop", mp.get_script_name())
local command_prefix = 'no-osd' --set this to null to debug

function get_target_ar(file_ar)
    local aspect_ratios = {
        [1]  = {"16:10",    16 / 10},
        [2]  = {"16:9",     16 / 9},
        [3]  = {"4:3",       4 / 3},
        [4]  = {"1.85:1", 1.85 / 1},
        [5]  = {"2.21:1", 2.21 / 1},
        [6]  = {"2.35:1", 2.35 / 1},
        [7]  = {"2.39:1", 2.39 / 1},
        [8]  = {"5:3",       5 / 3},
        [9]  = {"5:4",       5 / 4},
        [10] = {"1:1",       1 / 1},
        [11] = {"9:16",      9 / 16},
    }
    crop_option = crop_option + 1

    local setting = aspect_ratios[crop_option]
    local result

    if setting then
        mp.osd_message("Crop: " .. setting[1])
        result = setting[2]
    else
        mp.osd_message("Crop: Default")
        crop_option = 0 
        result = file_ar
    end

    return result
end

function has_video()
    for _, track in pairs(mp.get_property_native('track-list')) do
        if track.type == 'video' and track.selected then
            return not track.albumart
        end
    end

    return false
end

function on_press()
    -- If it's not cropable, exit.
    if not has_video() then
        mp.msg.warn("autocrop only works for videos.")
        return
    end

    -- Get current video fields, this doesnt take into consideration pixel aspect ratio
    local width = mp.get_property_native("width")
    local height = mp.get_property_native("height")
    local aspect = mp.get_property_native("video-params/aspect")
    local par = mp.get_property_native("video-params/par")

    local new_w
    local new_h
    local new_x
    local new_y

    -- Get target aspect ratio
    target_ar = get_target_ar(aspect)
    mp.msg.info("Cropping Video, Target Aspect Ratio: " .. tostring(target_ar))

    -- Compare target AR to current AR, crop height or width depending on what is needed
    -- The if statements
    if target_ar < aspect * 0.99 then
        -- Reduce width
        new_w = (height * target_ar) / par -- New width is the width multiple by the aspect ratio, adjusted for the PAR (pixel aspect ratio) incase it's not 1:1
        new_h = height                    -- Height stays the same since we only ever crop one axis in this script
        new_x = (width - new_w) / 2       -- Width - new width will equal the total space cropped, since its evenly cropped from both sides the offset needs to be halved
        new_y = 0                         -- This along with the height being the video height means that it will crop zero pixels
    elseif target_ar > aspect * 1.01 then
        -- Reduce height
        new_w = width                            -- See new_h above
        new_h = (width * (1 / target_ar)) * par   -- See new_w above, need to adjust for PAR but it's in the reverse direction
        new_x = 0                                -- See new_y above
        new_y = (height - new_h) / 2             -- See new_h above
    else
        -- So if the target aspect ratio is the same as the source (or within 1%), )
        mp.msg.verbose("Target aspect ratio = source aspect ratio, removing filter")
        cleanup() -- remove the crop filter
        return    -- exit the function before we apply that crop
    end

    -- Apply crop
    mp.command(string.format("%s vf pre @%s:lavfi-crop=w=%s:h=%s:x=%s:y=%s",
                            command_prefix, cropstring, new_w, new_h, new_x, new_y))
end

function cleanup() 
    mp.msg.verbose("Cleanup")

    -- This looks for applied filters that match the filter that we are using, then removes them
    local filters = mp.get_property_native("vf")
    for index, filter in pairs(filters) do
        mp.msg.verbose("Applied Crop : " .. tostring(filter["label"]))
        mp.msg.verbose("Comparing to : " .. tostring(cropstring))
        if filter["label"] == cropstring then
            mp.msg.info("Removing Crop")
            mp.command(string.format('%s vf remove @%s', command_prefix, cropstring))
            return true
        end
    end

    return false
end

function on_start()
    cleanup()
    crop_option = 0 -- Reset crop option
end

-- Custom functions for menu-plugin script
function reset_crop()   crop_option = -1; on_press() end
function apply_16_10()  crop_option = 0;  on_press() end
function apply_16_9()   crop_option = 1;  on_press() end
function apply_4_3()    crop_option = 2;  on_press() end
function apply_1_85_1() crop_option = 3;  on_press() end
function apply_2_21_1() crop_option = 4;  on_press() end
function apply_2_35_1() crop_option = 5;  on_press() end
function apply_2_39_1() crop_option = 6;  on_press() end
function apply_5_3()    crop_option = 7;  on_press() end
function apply_5_4()    crop_option = 8;  on_press() end
function apply_1_1()    crop_option = 9;  on_press() end
function apply_9_16()   crop_option = 10; on_press() end

-- Make functions visible to input.conf (strange solution but okay)
mp.add_key_binding("", "crop-reset", reset_crop, { repeatable = false })
mp.add_key_binding("", "crop-16-10", apply_16_10, { repeatable = false })
mp.add_key_binding("", "crop-16-9", apply_16_9, { repeatable = false })
mp.add_key_binding("", "crop-4-3", apply_4_3, { repeatable = false })
mp.add_key_binding("", "crop-1-85-1", apply_1_85_1, { repeatable = false })
mp.add_key_binding("", "crop-2-21-1", apply_2_21_1, { repeatable = false })
mp.add_key_binding("", "crop-2-35-1", apply_2_35_1, { repeatable = false })
mp.add_key_binding("", "crop-2-39-1", apply_2_39_1, { repeatable = false })
mp.add_key_binding("", "crop-5-3", apply_5_3, { repeatable = false })
mp.add_key_binding("", "crop-5-4", apply_5_4, { repeatable = false })
mp.add_key_binding("", "crop-1-1", apply_1_1, { repeatable = false })
mp.add_key_binding("", "crop-9-16", apply_9_16, { repeatable = false })

mp.add_key_binding("c", "toggle_crop", on_press)   -- another way to set keybindings
mp.register_event("file-loaded", on_start)