--[[ LFc testing ]]--

----------------------------------------
--[[ description:
  -- Testing LF context localization.
  -- Тестирование локализации LF context.
--]]
--------------------------------------------------------------------------------
context.config.register{ key = 'paraminherit', name = '_inh', inherit = true }
--context.config.register{ key = 'paraminherit', name = 'inh', inherit = true,
--                         mode = { basis = 'common', merge = 'strange' } }

local data = ctxdata.config.paraminherit
if not data then return end

local s = '"lua" type param is '

local param = data.lua.param
far.Message(s..tostring(param), "Param with type inheritance")

param = data.lua_inh.param
far.Message(s..tostring(param), "Param with config inheritance")
--------------------------------------------------------------------------------
