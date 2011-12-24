--[[ LFc testing ]]--

----------------------------------------
--[[ description:
  -- Testing localization.
  -- Тестирование локализации.
--]]
--------------------------------------------------------------------------------
local _G = _G

----------------------------------------
local context = context
local locale = context.locale

local logMsg = (require "Rh_Scripts.Utils.Logging").Message

--------------------------------------------------------------------------------
local scriptPath = "context\\test\\"

local Custom = {
} ---

local DefCustom = {
  name = "useLoc",
  path = scriptPath,

  label = "mL",

  locale = { kind = 'require' },
} ---

---------------------------------------- main
local loc, error1, error2 = locale.create(DefCustom)
--local cLoc, error1, error2 = locale.create(Custom, DefCustom)
loc.b = loc.button

if loc == nil then
  logMsg({ error1, error2 }, 'Error')
  return
end

--logMsg(Custom, 'Custom', 1, "#q")
--logMsg(loc, 'loc', 1, "#q")

far.Message(loc:t'TestMessage', loc:t'Test', loc:b'Apply')
loc:w1('Warning', 'WarnMsg')
--------------------------------------------------------------------------------
