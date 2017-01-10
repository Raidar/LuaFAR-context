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
require "context.initiate"          -- LFc initiate
MakeResident("context.resident")    -- LFc resident
--
--]]
----------------------------------------
--local logShow = context.Show

--------------------------------------------------------------------------------
-- Type autodetect functions
local handle = context.handle
ctxdata.isResident = true

----------------------------------------
function ProcessEditorEvent (id, event, param)
  --logShow({ id, event, param })
  --logShow(editor.GetInfo())
  handle.editorEvent(id, event, param)

  return 0

end --

function ProcessViewerEvent (id, event, param)

  handle.viewerEvent(id, event, param)

  return 0

end --

function ExitScript ()
  if rawget(_G, 'ctxdata') then
    ctxdata.events = nil -- ?!
    ctxdata = nil

  end
end --

----------------------------------------
local resident = {

  ProcessEditorEvent = ProcessEditorEvent,
  ProcessViewerEvent = ProcessViewerEvent,

  ExitScript = ExitScript,

} --- resident

--------------------------------------------------------------------------------
return resident
--------------------------------------------------------------------------------
