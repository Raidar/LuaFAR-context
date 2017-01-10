--------------------------------------------------------------------------------
local UseAutoAdding = true
--local UseAutoAdding = false

-- Add LuaFAR context features first only!!!
----------------------------------------
--[[ Extend package.path ]]--

local function ExpandEnv (s)

  return s:gsub("%%(.-)%%", win.GetEnv)

end

local PackPath = package.path
local LuaFAR_Path = ExpandEnv(win.GetEnv("LUAFAR_PATH") or "")
if string.len(LuaFAR_Path) > 0 then

  if LuaFAR_Path:sub(-1, 1) ~= ";" then
    LuaFAR_Path = LuaFAR_Path..";"

  end

  --far.Show(LuaFAR_Path)

  if not PackPath:find(LuaFAR_Path, 1, true) then
    PackPath = LuaFAR_Path..PackPath

  end
end
package.path = PackPath

----------------------------------------

require "context.initiate"       -- LFc initiate
MakeResident("context.resident") -- LFc resident

if UseAutoAdding then
  AutoInstall("scripts/", "%_.+menu%.lua$", 1) -- Loading all _*menu.lua

else
  AddUserFile('scripts/lfa_config/_usermenu.lua') -- LFA config menu
  AddUserFile("scripts/Rh_Scripts/_usermenu.lua") -- Rh scripts items
  AddUserFile('scripts/fl_scripts/_usermenu.lua') -- farlua scripts items

end

--------------------------------------------------------------------------------
