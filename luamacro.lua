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
local MakeResident = require "context.luamacro"
MakeResident(resident, Event)
--
--]]
----------------------------------------
--local logShow = context.Show

--------------------------------------------------------------------------------

----------------------------------------
function MakeResident (resident, Event)

  Event {
    group       = "EditorEvent",
    description = "LFc ProcessEditorEvent",
    priority    = 100,
    action      = function (id, event, param)
      return resident.ProcessEditorEvent(id, event, param)
    end,
  } ---

  Event {
    group       = "ViewerEvent",
    description = "LFc ProcessViewerEvent",
    priority    = 100,
    action      = function (id, event, param)
      return resident.ProcessViewerEvent(id, event, param)
    end,
  } ---

  Event {
    group       = "ExitFAR",
    description = "LFc ExitScript",
    priority    = 100,
    action      = function ()
      return resident.ExitScript()
    end,
  } ---

end ---- MakeResident

--------------------------------------------------------------------------------
return MakeResident
--------------------------------------------------------------------------------
