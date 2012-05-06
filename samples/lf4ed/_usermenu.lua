--------------------------------------------------------------------------------
local UseAutoAdding = true
--local UseAutoAdding = false

----------------------------------------
-- Add LuaFAR context features first only!!!
require "context.initiate"       -- LFc initiate
if context.use.LFVer >= 3 then
MakeResident("context.resident") -- LFc resident
else
MakeResident(require "context.resident") -- LFc resident
end

if UseAutoAdding then
  AutoInstall("scripts/", "%_.+menu%.lua", 1) -- Loading all _*menu.lua
else
  AddUserFile('scripts/lfa_config/_usermenu.lua') -- LFA config menu
  AddUserFile("scripts/Rh_Scripts/_usermenu.lua") -- Rh scripts items
  AddUserFile('scripts/fl_scripts/_usermenu.lua') -- farlua scripts items
end
--------------------------------------------------------------------------------
