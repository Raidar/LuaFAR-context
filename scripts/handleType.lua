--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- Type handling.
  -- Обработка типа.
--]]
----------------------------------------
--[[ uses:
  LuaFAR,
  LF context.
  -- group: LFc scripts.
  -- areas: editor, viewer.
--]]
--------------------------------------------------------------------------------

local type = type
local rawget, rawset = rawget, rawset

local table = table

----------------------------------------
local far = far
local F = far.Flags

----------------------------------------
require 'context.scripts.detectType'

local context, ctxdata = context, ctxdata

local utils = require 'context.utils.useUtils'

local detect = context.detect
local cfgDat = ctxdata.config
--[[
local types = cfgDat.types
far.Show("types", unpack(types))
--]]

----------------------------------------
--[[
local dbg = require "context.utils.useDebugs"
local logShow = dbg.Show
--]]

--------------------------------------------------------------------------------
local unit = {}

----------------------------------------
local farWarning = utils.warning

-- Messages
local Msgs = {
  CHandlerError = "Handler error",
  SHandlerError = "Error running handler %d.\n%s\nHandler is removed.",
} ---

---------------------------------------- Events
local events = ctxdata.events or {}
ctxdata.events = events

-- Add new handler for event.
function unit.add (event, handler) --> (true|nil)
  if not event then return end
  if not events[event] then events[event] = {} end

  local handlers = events[event]
  handlers[#handlers+1] = handler
  return true
end ----

-- Delete handler for event.
function unit.del (event, handler) --> (true|nil)
  if not event then return end
  local handlers = events[event]
  if not handlers then return end

  if type(handler) == 'number' then
    table.remove(handlers, handler)
    return true
  end

  -- handler is a function:
  for k = 1, #handlers do
    if handlers[k] == handler then
      table.remove(handlers, k)
      return true
    end
  end
end ----

local pcall = pcall

-- Handle event calling all handlers for this event.
local function handleEvent (event, ...) --> (true|nil)
  if not event then return end
  local handlers = events[event]
  if not handlers then return end

  for k = 1, #handlers do
    --handlers[k](...)
    local st, res = pcall(handlers[k], ...) -- MAYBE: Use xpcall with traceback?!
    if not st then
      farWarning(Msgs.CHandlerError,
                 Msgs.SHandlerError:format(k, res or ''), 'l')
      unit.del(event, k)
    end
  end
  return true
end --
unit.event = handleEvent

---------------------------------------- Metamethods
local editors = ctxdata.editors or {}
ctxdata.editors = editors
local viewers = ctxdata.viewers or {}
ctxdata.viewers = viewers

do
  local setmetatable = setmetatable

-- An __index for subtables-configs.
local function evt_index (t, key)
  if key == 'type' then return rawget(t, 'type') end
  local keycfg = cfgDat[key] -- may be nil or no table?
  if type(keycfg) ~= 'table' then return keycfg end
  return keycfg[rawget(t, 'type')]
end --

  local evt_mt = { __index = evt_index }

-- Set a __index for subtables-configs.
local function ev_newindex (t, key, value)
  rawset(t, key, value)
  if type(value) == 'table' then
    setmetatable(value, evt_mt)
  end
end --

  local detEditorType = detect.area.editor
  local detViewerType = detect.area.viewer

-- Detect and return config with type for 'current'.
local function e_index (t, key) --| for editor
  if key == 'current' then
    return { type = detEditorType() }
  end
end --

local function v_index (t, key) --| for viewer
  if key == 'current' then
    return { type = detViewerType() }
  end
end --

  setmetatable(editors, { __newindex = ev_newindex, __index = e_index })
  setmetatable(viewers, { __newindex = ev_newindex, __index = v_index })
end -- do

local function reloadEditorConfig (id) --| editors
  --logShow({ "reset", editor.GetInfo() })
  editors.current = nil           -- reset
  local current = editors.current -- new config via mt
  editors.current = current
  -- Alternative code using indexes directly
  --local current = e_index(editors, 'current')
  --ev_newindex(editors, 'current', current)
  editors[id] = current
  handleEvent('reloadEditor', current)

  --far.Message(editors.current.type, "Editor")
end -- reloadEditorConfig

local function reloadViewerConfig (id) --| viewers
  viewers.current = nil           -- reset
  local current = viewers.current -- new config via mt
  viewers.current = current
  -- Alternative code using indexes directly
  --local current = e_index(viewers, 'current')
  --ev_newindex(viewers, 'current', current)
  viewers[id] = current
  handleEvent('reloadViewer', current)

  --far.Message(viewers.current.type, "Viewer")
end -- reloadViewerConfig

-- Change type for areaid config.
function unit.changeType (areaid, newtype, force)
  if not newtype then return end

  local oldtype = rawget(areaid, 'type')
  if not force and newtype == oldtype then return end

  handleEvent('changeType', oldtype, false)
  areaid.type = newtype
  handleEvent('changeType', newtype, true)

  return true
end ---- changeType

---------------------------------------- Handlers
do
  local EE_READ     = F.EE_READ
  local EE_SAVE     = F.EE_SAVE
  local EE_CLOSE    = F.EE_CLOSE
  local EE_GOTFOCUS = F.EE_GOTFOCUS
  --local EE_CHANGE   = F.EE_CHANGE

-- Process type autodetection for editor.
function unit.editorEvent (id, event, param)
  local eid = id
  if event == EE_READ then
    --logShow(eid, "EE_READ")
    --logShow(editor.GetInfo())
    eid = editor.GetInfo().EditorID -- TEST and DELETE
    reloadEditorConfig(eid)
    --far.Message(('%i %s'):format(eid, editors.current.type))
  elseif event == EE_SAVE then
    eid = editor.GetInfo().EditorID -- TEST and DELETE
    if editors.current.type == 'none' then
      reloadEditorConfig(eid)
    end
  elseif event == EE_GOTFOCUS then
    if not editors[eid] then
      reloadEditorConfig(eid)
    else
      editors.current = editors[eid]
    end
  elseif event == EE_CLOSE then
    editors.current, editors[eid] = nil, nil
  end
end ---- editorEvent

end -- do

do
  local VE_READ     = F.VE_READ
  local VE_CLOSE    = F.VE_CLOSE
  local VE_GOTFOCUS = F.VE_GOTFOCUS

-- Process type autodetection for viewer.
function unit.viewerEvent (id, event, param)
  local vid = id
  if event == VE_READ then
    vid = viewer.GetInfo().ViewerID
    reloadViewerConfig(vid)
    --far.Message( ('%i %s'):format(vid, viewers.current.type) )
  elseif event == VE_GOTFOCUS then
    if not viewers[vid] then
      reloadViewerConfig(vid)
    else
      viewers.current = viewers[vid]
    end
  elseif event == VE_CLOSE then
    viewers.current, viewers[vid] = nil, nil
  end
end ---- viewerEvent

end -- do

--------------------------------------------------------------------------------
context.handle = unit -- 'process' table in context
--------------------------------------------------------------------------------
