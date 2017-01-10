--[[ LFc testing ]]--

----------------------------------------
--[[ description:
  -- Test: Using localization.
  -- Тест: Использование локализации.
--]]
--------------------------------------------------------------------------------

----------------------------------------
--local context = context
local ShowInfo = context.ShowInfo

local locale = require 'context.utils.useLocale'

--------------------------------------------------------------------------------
local scriptPath = "context\\test\\"

--local Custom = {
--} ---

local DefCustom = {

  name = "uLocale",
  path = scriptPath,

  label = "mL",

  locale = { kind = 'require' },

} ---

---------------------------------------- main
local loc, error1, error2 = locale.create(DefCustom)
--local cLoc, error1, error2 = locale.create(Custom, DefCustom)
loc.b = loc.button

if loc == nil then
  ShowInfo({ error1, error2 }, 'Error')

  return
end

--logShow(Custom, 'Custom', "#qd1")
--logShow(loc, 'loc', "#qd1")

far.Message(loc:t'TestMessage', loc:t'Test', loc:b'Apply')
loc:w1('Warning', 'WarnMsg')
--------------------------------------------------------------------------------
