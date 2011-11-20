--------------------------------------------------------------------------------
local UseAutoAdding = true
--local UseAutoAdding = false

----------------------------------------
-- Add LuaFAR context features first only!!!
require "context.initiate"               -- LFc initiate
MakeResident(require "context.resident") -- LFc resident

if UseAutoAdding then
  AutoInstall("scripts/", "%_.+menu%.lua", 1) -- Loading all _*menu.lua
else
  AddUserFile('scripts/lfe_config/_usermenu.lua') -- LFE config menu
  AddUserFile("scripts/Rh_Scripts/_usermenu.lua") -- Rh scripts items
  AddUserFile('scripts/fl_scripts/_usermenu.lua') -- farlua scripts items
end
--------------------------------------------------------------------------------
