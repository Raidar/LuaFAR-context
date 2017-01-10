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
local unit = {}

----------------------------------------
context = rawget(_G, 'context') or {}

local context = context
context.guid = "c0afe3a3-ff78-4904-b100-1c366d04ea96"

context.use = context.use or {} -- for non-context utils

---------------------------------------- Data
ctxdata = rawget(_G, 'ctxdata') or {}

local ctxdata = ctxdata
ctxdata.guid = "c05e4187-192b-4c37-8821-06cf75e7b4d1"

ctxdata.config      = ctxdata.config      or {} -- access to configs
ctxdata.reg         = ctxdata.reg         or {} -- register of configs
ctxdata.checked     = ctxdata.checked     or {} -- type checked configs
ctxdata.descriptors = ctxdata.descriptors or {} -- config descriptors

---------------------------------------- Debug
-- Show simple information.
function context.Show (...)

  context.log = context.log or require "context.samples.logging"

  return context.log.Show(...)

end ---- Show

-- Show required information.
function context.ShowInfo (...)

  context.dbg = context.dbg or require "context.utils.useDebugs"

  return context.dbg.Show(...)

end ---- ShowInfo

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
