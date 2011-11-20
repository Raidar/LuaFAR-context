--[[ LFc testing ]]--

----------------------------------------
--[[ description:
  -- Testing type checking.
  -- Тестирование проверки на тип.
--]]
--------------------------------------------------------------------------------
local meta = getmetatable('').__index or string
meta.isType = context.detect.use.isType

local tps = { 'lua', 'main', 'config', 'ini', 'reg', 'awk' }
local t = {}

for _, t1 in pairs(tps) do
  for __, t2 in pairs(tps) do
     t[#t+1] = ('%s %s %s'):format(t1, t1:isType(t2) and 'is' or 'is not', t2)
  end
end

far.Message(table.concat(t, '\n'), "isType test")
--------------------------------------------------------------------------------
