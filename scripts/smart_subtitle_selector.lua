-- # 🎯 Smart Subtitle Selector
-- 
-- Ends the nightmare of manually cycling through subtitle tracks. This script intelligently scans and selects the best subtitle track based on your preferences, automatically rejecting "Forced" or "Commentary" tracks.  
-- 
-- 
-- Find out how it works!
-- 
--   > *An intelligent script to automatically select the correct subtitle track.*
-- 
-- ###  The Problem This Solves
-- 
-- When playing media with multiple subtitle tracks, MPV's default behavior often selects an undesirable track, such as "Signs & Songs" or "Forced," leading to a frustrating user experience. The user must then manually cycle through all available tracks on every single file to find the main dialogue track.
-- 
-- ### ✨ The Solution
-- 
-- This script replaces MPV's default logic with an intelligent, priority-based system. It analyzes the titles of all available subtitle tracks and automatically selects the one that best matches the user's configured preferences, ignoring commentary or utility tracks.
-- 
-- This provides a "set it and forget it" solution that ensures the correct dialogue track is selected automatically, every time.
-- 
-- ### 🤔 How It Works:
-- 
-- The script ranks subtitle tracks based on a tiered priority system:
-- 
-- 1.  **Priority Tier:** First, it searches for tracks containing keywords that indicate a primary dialogue track (e.g., "dialogue," "full").
-- 2.  **Normal Tier:** If no priority tracks are found, it falls back to any standard subtitle track that isn't explicitly rejected.
-- 3.  **Rejected Tier:** It actively ignores any track containing keywords that mark it as a utility track (e.g., "signs," "songs," "commentary").
-- 
-- ### 😯 Real Example:
-- ```
-- Available tracks:
-- ❌ English [Forced] 
-- ❌ English [Signs/Songs]
-- ✅ English [Full Dialogue] ← This one gets picked!
-- ❌ Commentary Track
-- ```
-- 
-- ## 🚀 Quick Setup
-- 
-- ### 1\. File Placement
-- 
-- ```
-- 📁 portable_config/
-- ├── 📁 scripts/
-- │   └── 📄 smart_subs.lua
-- └── 📁 script-opts/
--     └── 📄 smart_subs.conf
-- ```
-- 
-- ### 2\. MPV Configuration
-- 
-- For the script to take control, you must disable MPV's default subtitle selection logic. In your `mpv.conf` file, comment out or delete the following line:
-- 
-- ```ini
-- # sid=auto
-- ```
-- 
-- ### ⚙️ Configuration
-- 
-- The script's behavior is controlled via `smart_subs.conf`.
-- 
-- ```ini
-- # Languages to select, in order of preference.
-- preferred_langs = en,eng
-- 
-- # Keywords that identify a high-priority dialogue track.
-- priority_keywords = dialogue,full,complete
-- 
-- # Keywords that identify tracks to be ignored.
-- reject_keywords = signs,songs,commentary
-- ```
-- 
-- ### Example Configurations:
-- 
--   * **For Multi-Language Users:** `preferred_langs = en,eng,jp,jpn`
--   * **For Anime Fans:** `reject_keywords = signs,songs,commentary,forced,karaoke`
--   * **For Movie Fans (with accessibility):** `priority_keywords = dialogue,full,complete,sdh`
-- 
-- ## 🔧 Troubleshooting
-- 
--   * **If the script isn't working:**
--     1.  Ensure the `.lua` and `.conf` files are in the correct folders.
--     2.  Confirm that `sid=auto` has been removed from `mpv.conf`.
--   * **If the wrong track is selected:**
--     1.  Check the track titles in your media file.
--     2.  Add any unwanted keywords (e.g., "Forced") to `reject_keywords`.
--     3.  Add any desired keywords to `priority_keywords`.
--   * **To see the script's decision-making process:**
--     1.  Enable the MPV console (press `~`). The script will log its actions, such as `Subtitle Selector: Found a PRIORITY track. Activating subtitle track #2`.
-- 
-- ## 🎉 The Bottom Line
-- Install once, configure to your taste, then never think about subtitles again. The script just quietly does the right thing while you focus on actually watching your content.

-- Intelligent Subtitle Selector for MPV
-- This script automatically selects the best subtitle track using a priority system.
-- Configuration is handled by an external 'smart_subs.conf' file.

local mp = require 'mp'
local options = require 'mp.options'

-- Define the default settings. These will be used if the .conf file is missing
-- or if an option is not specified.
local config = {
    preferred_langs = "en,eng",
    priority_keywords = "dialogue,full,complete",
    reject_keywords = "signs,songs,commentary"
}
options.read_options(config, "smart_subs")

-- Helper function to parse comma-separated strings into a simple array.
local function parse_list(str)
    local list = {}
    for item in string.gmatch(str, "([^,]+)") do
        table.insert(list, item:match("^%s*(.-)%s*$"):lower()) -- Trim whitespace and make lowercase
    end
    return list
end

-- Main function to select the best subtitle track.
function select_best_subtitle()
    -- Parse the settings from the config into usable tables
    local preferred_langs = parse_list(config.preferred_langs)
    local priority_keywords = parse_list(config.priority_keywords)
    local reject_keywords = parse_list(config.reject_keywords)

    local track_list = mp.get_property_native("track-list")
    if not track_list then return end

    local potential_tracks = {
        priority = {},
        normal = {}
    }

    mp.msg.info("Subtitle Selector: Analyzing tracks with priority logic...")

    -- Step 1: Categorize all available tracks
    for _, track in ipairs(track_list) do
        if track.type == "sub" then
            local lang_match = false
            for _, lang in ipairs(preferred_langs) do
                if track.lang and track.lang:match(lang) then
                    lang_match = true
                    break
                end
            end

            if lang_match then
                local title = track.title and track.title:lower() or ""
                local is_rejected = false
                local is_priority = false

                -- SKIP FORCED TRACKS ENTIRELY - this is the key fix
                if track.forced then
                    mp.msg.info("  - Skipping forced track #" .. track.id .. " ('" .. (track.title or "No Title") .. "')")
                else
                    -- Check if the track title contains any reject keywords
                    for _, keyword in ipairs(reject_keywords) do
                        if title:match(keyword) then
                            is_rejected = true
                            mp.msg.info("  - Rejecting track #" .. track.id .. " ('" .. (track.title or "No Title") .. "') due to keyword: " .. keyword)
                            break
                        end
                    end

                    if not is_rejected then
                        -- Check if the track title contains any priority keywords
                        for _, keyword in ipairs(priority_keywords) do
                            if title:match(keyword) then
                                is_priority = true
                                break
                            end
                        end

                        if is_priority then
                            table.insert(potential_tracks.priority, track)
                        else
                            table.insert(potential_tracks.normal, track)
                        end
                    end
                end
            end
        end
    end

    -- Step 2: Select the best track based on a clear hierarchy
    local best_track_id = nil
    if #potential_tracks.priority > 0 then
        best_track_id = potential_tracks.priority[1].id
        mp.msg.info("Subtitle Selector: Found a PRIORITY track.")
    elseif #potential_tracks.normal > 0 then
        best_track_id = potential_tracks.normal[1].id
        mp.msg.info("Subtitle Selector: No priority track found. Selecting a NORMAL track.")
    end

    -- Step 3: Apply the change
    if best_track_id then
        mp.set_property("sid", best_track_id)
        mp.msg.info("Subtitle Selector: Best track found. Activating subtitle track #" .. best_track_id)
    else
        mp.msg.info("Subtitle Selector: No suitable subtitle track found.")
    end

    -- Defend our subtitle choice from profile interference
    local function defend_subtitle_choice()
        if best_track_id then
            local current_sid = mp.get_property_number("sid")
            if current_sid ~= best_track_id then
                mp.set_property("sid", best_track_id)
                mp.msg.info("Subtitle Selector: Restored track #" .. best_track_id .. " (was overridden)")
            end
        end
    end

    -- Check periodically for the first few seconds
    for i = 1, 5 do
        mp.add_timeout(i * 0.5, defend_subtitle_choice)
    end
end

mp.register_event("file-loaded", select_best_subtitle)
