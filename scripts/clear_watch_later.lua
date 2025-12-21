local mp = require "mp"
local utils = require "mp.utils"
local options = require "mp.options" 

local opts = {
    days_count = 30     -- Maximum age in days before files are deleted    
}
options.read_options(opts, "clean_watch_later") -- Parse options from script-opts/clean_watch_later.conf

local function clear_watch_later()    
    local config_dir = mp.find_config_file(".") -- getting local config file directory
    if not config_dir then return end
    
    local watch_later_dir = utils.join_path(config_dir, "watch_later")  -- Getting watch_later directory
    if not utils.file_info(watch_later_dir) then return end

    local files = utils.readdir(watch_later_dir)    -- Reading watch_later directory 
    if not files then return end
    
    local time_passed_since = os.time() - opts.days_count * 24 * 60 * 60  

    for _, file in ipairs(files) do
        local file_path = utils.join_path(watch_later_dir, file)
        local file_info = utils.file_info(file_path)
        
        if file_info and file_info.mtime < time_passed_since then
            os.remove(file_path)
        end
    end
end

mp.register_event("shutdown", clear_watch_later)