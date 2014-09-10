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
local logShow = context.ShowInfo

local detect = context.detect
local cfgDat = ctxdata.config
--[[
local types = cfgDat.types
far.Show("types", unpack(types))
--]]

--------------------------------------------------------------------------------
local unit = {}

----------------------------------------
-- Messages
local Msgs = {
  CHandlerError = "Handler error",
  SHandlerError = "Error running handler %d.\n%s\nHandler is removed.",
} --- Msgs

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
end ---- add

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
end ---- del

  local pcall = pcall

  local farMsg = far.Message

-- Handle event calling all handlers for this event.
local function handleEvent (event, ...) --> (true|nil)
  if not event then return end
  local handlers = events[event]
  if not handlers then return end

  for k = 1, #handlers do
    --handlers[k](...)
    local st, res = pcall(handlers[k], ...) -- MAYBE: Use xpcall with traceback?!
    if not st then
      farMsg(Msgs.CHandlerError,
             Msgs.SHandlerError:format(k, res or ''), nil, 'lw')
      unit.del(event, k)
    end
  end

  return true
end -- handleEvent
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
end -- evt_index

  local evt_mt = { __index = evt_index }

-- Set a __index for subtables-configs.
local function ev_newindex (t, key, value)
  rawset(t, key, value)
  if type(value) == 'table' then
    setmetatable(value, evt_mt)
  end
end -- ev_newindex

  local detEditorType = detect.area.editor
  local detViewerType = detect.area.viewer

-- Detect and return config with type for 'current'.
local function e_index (t, key) --| for editor
  if key == 'current' then
    local tp = detEditorType()
    if tp then return { type = tp } end
  end
end -- e_index

local function v_index (t, key) --| for viewer
  if key == 'current' then
    local tp = detViewerType()
    if tp then return { type = tp } end
  end
end -- v_index

  setmetatable(editors, { __newindex = ev_newindex, __index = e_index })
  setmetatable(viewers, { __newindex = ev_newindex, __index = v_index })
end -- do

local function reloadEditorConfig (id, kind) --| editors
  --logShow({ "reset", editor.GetInfo() })

  local current = editors[id]
  if not current or current.kind ~= 'focus' then
    editors.current = nil     -- reset
    current = editors.current -- new config via mt
  end
  if current then current.kind = kind end
  editors.current = current

  -- Alternative code using indexes directly
  --local current = e_index(editors, 'current')
  --ev_newindex(editors, 'current', current)

  editors[id] = current
  handleEvent('reloadEditor', current)

  --far.Message(editors.current.type, "Editor")
end -- reloadEditorConfig

local function reloadViewerConfig (id, kind) --| viewers

  local current = viewers[id]
  if not current or current.kind ~= 'focus' then
    viewers.current = nil     -- reset
    current = viewers.current -- new config via mt
  end
  if current then current.kind = kind end
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
    local Info = editor.GetInfo()
    --logShow(Info)
    eid = Info.EditorID -- TEST and DELETE
    if not Info then return end

    reloadEditorConfig(eid, 'load')
    --far.Message(('%i %s'):format(eid, editors.current.type))

  elseif event == EE_GOTFOCUS then
    --if not editors[eid] then
      reloadEditorConfig(eid, 'focus')
    --else
    --  editors.current = editors[eid]
    --end

  elseif event == EE_SAVE then
    local Info = editor.GetInfo()
    if not Info then return end
  
    eid = Info.EditorID -- TEST and DELETE
    if not editors.current or
       editors.current.type == 'none' then
      reloadEditorConfig(eid, 'save')
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
    local Info = viewer.GetInfo()
    if not Info then return end
  
    vid = Info.ViewerID
    reloadViewerConfig(vid, 'load')
    --far.Message( ('%i %s'):format(vid, viewers.current.type) )

  elseif event == VE_GOTFOCUS then
    --if not viewers[vid] then
      reloadViewerConfig(vid, 'focus')
    --else
    --  viewers.current = viewers[vid]
    --end

  elseif event == VE_CLOSE then
    viewers.current, viewers[vid] = nil, nil

  end
end ---- viewerEvent

end -- do

--------------------------------------------------------------------------------
context.handle = unit -- 'process' table in context
--------------------------------------------------------------------------------
