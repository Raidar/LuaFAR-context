--[[ LuaMacro init ]]--

--local PackPath = package.path:gsub(";", "\n")
--far.Show(PackPath)

----------------------------------------
--[[ Extend package.path ]]--

local function ExpandEnv (s)
  return (s or ""):gsub("%%(.-)%%", win.GetEnv)
end

local PackPath = package.path
local LuaFAR_Path = ExpandEnv(win.GetEnv("LUAFAR_PATH") or "")
if string.len(LuaFAR_Path) > 0 then
  if LuaFAR_Path:sub(-1, 1) ~= ";" then
    LuaFAR_Path = LuaFAR_Path..";"
  end
  --far.Show(LuaFAR_Path:gsub(";", "\n"))
  if not PackPath:find(LuaFAR_Path, 1, true) then
    PackPath = LuaFAR_Path..PackPath
  end
end
package.path = PackPath
--far.Show(package.path:gsub(";", "\n"))

--package.path = far.PluginStartupInfo().ModuleDir.."?.lua;"..package.path

----------------------------------------

--far.Show"initiating .."
require "context.initiate"
--far.Show"initiating OK"
resident = require "context.resident"
--if resident then far.Show"resident OK" end
local MakeLFcResident = require "context.luamacro"
--if MakeLFcResident then far.Show"MakeResident OK" end
MakeLFcResident(resident, Event)

--------------------------------------------------------------------------------
