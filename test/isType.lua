--[[ LFc testing ]]--

----------------------------------------
--[[ description:
  -- Test: Type checking.
  -- Тест: Проверка на тип.
--]]
--------------------------------------------------------------------------------
local meta = getmetatable('').__index or string
meta.isType = context.detect.use.isType

local tps = {

  'lua',
  'main',
  'config',
  'ini',
  'reg',
  'awk',
  --'script',

} ---
local t = {}

for _, t1 in pairs(tps) do
  for _, t2 in pairs(tps) do
    t[#t + 1] = ('%s %s %s'):format(t1, t1:isType(t2) and 'is' or 'is not', t2)

  end
end
t[#t + 1] = "--- end ---"

far.Message(table.concat(t, '\n'), "isType test")
--------------------------------------------------------------------------------
