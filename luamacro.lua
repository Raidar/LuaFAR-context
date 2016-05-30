--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- Using in LuaMacro.
  -- Использование в LuaMacro.
--]]
----------------------------------------
--[[ uses:
  LuaFAR.
  -- group: LF context.
--]]
--------------------------------------------------------------------------------
--[[
  Insert following code to start of LuaMacro _macroinit.lua file:
--
require "context.initiate"
resident = require "context.resident"

local MakeLFcResident = require "context.luamacro"
MakeLFcResident(resident, Event)
--
--]]
----------------------------------------
--local logShow = context.Show

--------------------------------------------------------------------------------

----------------------------------------
function MakeResident (resident, Event, Priority)

  local Priority = Priority or 100

  Event {
    group       = "EditorEvent",
    description = "LuaFAR context ProcessEditorEvent",
    priority    = Priority,
    action      = function (id, event, param)
      return resident.ProcessEditorEvent(id, event, param)
    end,
  } ---

  Event {
    group       = "ViewerEvent",
    description = "LuaFAR context ProcessViewerEvent",
    priority    = Priority,
    action      = function (id, event, param)
      return resident.ProcessViewerEvent(id, event, param)
    end,
  } ---

  Event {
    group       = "ExitFAR",
    description = "LuaFAR context ExitScript",
    priority    = Priority,
    action      = function ()
      return resident.ExitScript()
    end,
  } ---

end ---- MakeResident

--------------------------------------------------------------------------------
return MakeResident
--------------------------------------------------------------------------------
