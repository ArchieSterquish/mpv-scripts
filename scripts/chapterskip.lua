-- README.md
-- # chapterskip
-- Automatically skips chapters based on title.
-- 
-- ## Installation
-- Place chapterskip.lua in your mpv `scripts` folder.
-- 
-- ## Usage
-- Select which categories to skip.  
-- Globally: `script-opts/chapterskip.conf` > `skip=opening;ending;more;categories`  
-- Within an auto profile: `mpv.conf` > `script-opts=chapterskip-skip=opening;ending;more;categories`
-- 
-- The default categories are:
-- - prologue
-- - opening
-- - ending
-- - preview
-- 
-- Additional categories can be defined with `categories=my-new-category>Part [AB]/Ending 1; another-category>Part C` in `script-opts/chapterskip.conf`
-- 
-- ## Category syntax
-- List of `category name>slash-separated lua patterns`, separated by semicolons.  
-- A `+` can also be used instead of `>`.
-- 
-- Index-based skips are possible by starting your category name with `idx-`. All patterns will be treated as integers. Chapter indexes start at 1.

-- This script skips chapters based on their title
-- Categories are listed below but to skip them you need to add categories in script-opts/chapterskip.conf 

local categories = {
    specific_chapter = "^Chapter 1/^Chapter 2/", -- REMINDER: delete this one as it's only title specific 
    prologue         = "^[Pp]rologue/^[Ii]ntro",
    opening          = "^[Oo][Pp]/ [Oo][Pp]$/^[Oo]pening",
    ending           = "^[Ee][Dd]/ [Ee][Dd]$/^[Ee]nding",
    preview          = "[Pp]review$",    
}

local options = {
    enabled = true,
    skip_once = true,
    categories = "",
    skip = ""
}

mp.options = require "mp.options"

function matches(i, title)
    for category in string.gmatch(options.skip, " *([^;]*[^; ]) *") do
        if categories[category:lower()] then
            if string.find(category:lower(), "^idx%-") == nil then
                if title then
                    for pattern in string.gmatch(categories[category:lower()], "([^/]+)") do
                        if string.match(title, pattern) then
                            return true
                        end
                    end
                end
            else
                for pattern in string.gmatch(categories[category:lower()], "([^/]+)") do
                    if tonumber(pattern) == i then
                        return true
                    end
                end
            end
        end
    end
end

local skipped = {}
local parsed = {}

function chapterskip(_, current)
    mp.options.read_options(options, "chapterskip")
    if not options.enabled then return end
    for category in string.gmatch(options.categories, "([^;]+)") do
        name, patterns = string.match(category, " *([^+>]*[^+> ]) *[+>](.*)")
        if name then
            categories[name:lower()] = patterns
        elseif not parsed[category] then
            mp.msg.warn("Improper category definition: " .. category)
        end
        parsed[category] = true
    end
    local chapters = mp.get_property_native("chapter-list")
    local skip = false
    for i, chapter in ipairs(chapters) do
        if (not options.skip_once or not skipped[i]) and matches(i, chapter.title) then
            if i == current + 1 or skip == i - 1 then
                if skip then
                    skipped[skip] = true
                end
                skip = i
            end
        elseif skip then
            mp.set_property("time-pos", chapter.time)
            skipped[skip] = true
            return
        end
    end
    if skip then
        if mp.get_property_native("playlist-count") == mp.get_property_native("playlist-pos-1") then
            return mp.set_property("time-pos", mp.get_property_native("duration"))
        end
        mp.commandv("playlist-next")
    end
end

mp.observe_property("chapter", "number", chapterskip)
mp.register_event("file-loaded", function() skipped = {} end)
