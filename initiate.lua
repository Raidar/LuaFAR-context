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
-- [[
  require "context.utils.far3" -- FAR23
--]]
---------------------------------------- -- FAR23 end

---------------------------------------- Config
local registerConfig

do -- Load special modules & Register types.
  --far.Message("require configData")
  require 'context.scripts.configData'
  registerConfig = context.config.register
  --far.Message("register 'types' config")
  registerConfig{ key = 'types' }
  --far.Message("require detectType")
  require 'context.scripts.detectType'
end -- do

---------------------------------------- Configs
do -- Register other configuration files.
  --registerConfig{ key = 'key name', name = 'file base name' } -- Sample
end

---------------------------------------- Modules
do
  -- Modules loaded to context:
  local modules = {
    'context.scripts.handleType', --> detectType
    'context.scripts.manageData',
  } ---

  -- Load modules to context.
  for k = 1, #modules do require(modules[k]) end
end -- do
--------------------------------------------------------------------------------
