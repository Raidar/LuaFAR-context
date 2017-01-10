--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- Using in LuaFAR plugin.
  -- Использование в LuaFAR-плагине.
--]]
----------------------------------------
--[[ uses:
  LuaFAR.
  -- group: LF context.
--]]
--------------------------------------------------------------------------------
--[[
  Insert code below to base script of LuaFAR plugin.
  Compile plugin with makefile like in directory of this file.
  Check user's settings section in this makefile.
--]]
--------------------------------------------------------------------------------
--[[ Recommended structure of files for makefile:
  FAR plugins\  - common directory of FAR plugins source
    luafar_unicode\ - LuaFARw source
    luafar_plugins\ - LuaFAR plugins source
        lfplugin\   - specific LuaFAR plugin source
            makefile    - makefile for this plugin
            lfp\        - maked version of this plugin
                lfplugin.dll    - luaplug.dll for plugin
                lfplugin.lua    - base lua-script of plugin
                others\         - other directories of plugin
--]]
--------------------------------------------------------------------------------
--[[ LuaFAR plugin ]]--

local _PluginVersion = "1.0.0"
--local _ReqLuafarVer = { 2, 0, 1 }

--------------------------------------------------------------------------------
--[[ Initial processing ]]--[[ Первоначальная обработка ]]--

local _FirstRun = not _LFP -- Первый запуск

--far.OnError = require "far2.errormessage"

if _FirstRun then -- Check version:
  -- TODO: Replace code to use version of FAR Manager!
  --local v1, v2 = far.LuafarVersion(true)
  --local r1, r2 = _ReqLuafarVer[1], _ReqLuafarVer[2]
  --local OK = (v1 > r1) or (v1 == r1 and v2 >= r2)
  --if not OK then error("LuaFAR version "..r1.."."..r2.." is required", 2) end

end --

if _FirstRun then -- Assign unicode:
  ----
  -- Add function unicode.utf8.cfind:
  -- same as find, but offsets are in characters rather than bytes
  ----
  local usub, ssub = unicode.utf8.sub, string.sub
  local ulen, slen = unicode.utf8.len, string.len
  local ufind = unicode.utf8.find

  unicode.utf8.cfind = function (s, patt, init, plain)
      init = init and slen(usub(s, 1, init-1)) + 1
      local t = { ufind(s, patt, init, plain) }
      if t[1] == nil then return nil end
      return ulen(ssub(s, 1, t[1]-1)) + 1, ulen(ssub(s, 1, t[2])), unpack(t, 3)

  end --

  getmetatable("").__index = unicode.utf8
  io = uio
  package.loadlib = far.LoadLib
  require, loadfile = far.Require, far.LoadFile

end --

if _FirstRun then -- LuaFAR context:
  require 'context.initiate'
  local context = context
  -- Configuration files registry
  local registerConfig = context.config.register
  registerConfig{ key = 'plugincfg', name = 'pluginname', inherit = true }

end --

--------------------------------------------------------------------------------
--[[ Special processing ]]--[[ Специальная обработка ]]--

if _FirstRun then
  _LFP = {}
  -- Include needful fields here --
end

local F = far.Flags
--local L = far.GetMsg
--local _PluginDir = far.PluginStartupInfo().ModuleDir

lfp = lfp or {}

function lfp.version ()

  return _PluginVersion

end

--------------------------------------------------------------------------------
--[[ Event handlers ]]--[[ Обработчики событий ]]--

local handle = context.handle

-- Action functions

function far.ProcessEditorEvent (id, event, param)

  handle.editorEvent(id, event, param)
  -- Do something here --

  return 0

end --

function far.ProcessViewerEvent (id, event, param)

  handle.viewerEvent(id, event, param)
  -- Do something here --

  return 0

end --

--------------------------------------------------------------------------------
--[[ Plugin functions ]]--[[ Функции плагина ]]--

function far.Config()

  far.Message("Configuration")

end

function far.OpenPlugin (From, Item) -- from lf_history.lua

  if From == F.OPEN_COMMANDLINE then return end

  -----------------------------------------------------------------------------
  local iAnyAction = { text="&Any action",    action=AnyAction }
  local iEdtAction = { text="&Editor action", action=EdtAction }
  local iConfig    = { text="&Configuration", action=far.Config }

  local properties = {Flags={"FMENU_WRAPMODE"}, Title="LuaFAR Plugin"}
  local items = { iAnyAction, iConfig }
  if From == F.OPEN_EDITOR then table.insert(items, 2, iEdtAction) end
  -----------------------------------------------------------------------------

  local item = far.Menu(properties, items)
  if item then item.action() end

end ----

--[[ Plugin functions ]]--[[ Функции плагина ]]--
--------------------------------------------------------------------------------
