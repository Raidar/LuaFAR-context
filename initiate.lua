--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- Work initiation.
  -- Инициирование работы.
--]]
----------------------------------------
--[[ uses:
  LuaFAR.
  -- group: LF context.
--]]
--------------------------------------------------------------------------------
local _G = _G

--------------------------------------------------------------------------------
context = rawget(_G, 'context') or {}
context.use = context.use or {} -- for non-context utils

---------------------------------------- Data
ctxdata = rawget(_G, 'ctxdata') or {}
ctxdata.config  = ctxdata.config or {}  -- access to configs
ctxdata.reg     = ctxdata.reg or {}     -- register of configs
ctxdata.checked = ctxdata.checked or {} -- type checked configs
ctxdata.descriptors = ctxdata.descriptors or {} -- config descriptors

ctxdata.languages = ctxdata.languages or
                    require "context.data.languages" -- languages and codes

---------------------------------------- Modules
-- Modules used in context
local modules = {
  -- Preload modules:
  'context.utils.useUtils',
  'context.utils.useNumbers',
  'context.utils.useTables',
  'context.utils.useDatas',
  'context.utils.useLocale',
  -- Other modules:
  'context.utils.handleType',
  'context.utils.manageData',
  'context.utils.useColors',
  'context.utils.useHistory',
} ---
local packnum = 5 -- Number of preload modules

-- Unregister all loaded modules.
for k = 1, #modules do
  package.loaded[modules[k]] = nil
end

---------------------------------------- -- FAR23 begin
--[[
  Блок кода работы скриптов для LuaFAR3 под LuaFAR2.
  Внимание: не гарантируется работа всех скриптов,
  только для LF context, Rh_Scripts, fl_scripts и LF area config.
--]]
-- [==[
context.use.LFVer = far.LuafarVersion(true)
if context.use.LFVer < 3 then bit64 = bit end

require "context.utils.far3_spc"

--]==]
---------------------------------------- -- FAR23 end

-- Load preload packages.
for k = 1, packnum do require(modules[k]) end

-- [[
  require "context.utils.far3" -- FAR23
--]]

local registerConfig

do -- Load special modules & Register types.
  --far.Message("require configData")
  require 'context.utils.configData'
  registerConfig = context.config.register
  --far.Message("register 'types' config")
  registerConfig{ key = 'types' }
  --far.Message("require detectType")
  require 'context.utils.detectType'
end

---------------------------------------- Configs
do -- Register other configuration files.
  --registerConfig{ key = 'key name', name = 'file base name' } -- Sample
end

---------------------------------------- Others
-- Load other modules.
for k = packnum + 1, #modules do require(modules[k]) end
--------------------------------------------------------------------------------
