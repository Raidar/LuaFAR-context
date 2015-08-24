--[[ LuaMacro init ]]--

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

require "context.initiate"
resident = require "context.resident"
local MakeResident = require "context.luamacro"
MakeResident(resident, Event)

--------------------------------------------------------------------------------
