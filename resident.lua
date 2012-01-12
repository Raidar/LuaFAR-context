--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- Using in plugins.
  -- Использование в плагинах.
--]]
----------------------------------------
--[[ uses:
  LuaFAR.
  -- group: LF context.
--]]
--------------------------------------------------------------------------------
--[[
  Insert following code to start of LuaFAR plugin _usermenu.lua file:
--
require "context.initiate"               -- LFc initiate
MakeResident(require "context.resident") -- LFc resident
--
--]]
--------------------------------------------------------------------------------
-- Type autodetect functions
local handle = context.handle
ctxdata.isResident = true

----------------------------------------
function ProcessEditorEvent (event, param)
  handle.editorEvent(event, param)
  return 0
end --

function ProcessViewerEvent (event, param)
  handle.viewerEvent(event, param)
  return 0
end --

function ExitScript ()
  ctxdata.events = nil -- ?!
  ctxdata = nil
end --

local resident = {
  ProcessEditorEvent = ProcessEditorEvent,
  ProcessViewerEvent = ProcessViewerEvent,
  ExitScript = ExitScript,
} --- resident

--------------------------------------------------------------------------------
return resident
--------------------------------------------------------------------------------
