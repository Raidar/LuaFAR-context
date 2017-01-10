--[[ FAQ ]]--

----------------------------------------
--[[ description:
  -- FAQ examples testing.
  -- Тестирование примеров из FAQ.
--]]
----------------------------------------
--[[ uses:
  LuaFAR.
  -- group: Test.
--]]
--------------------------------------------------------------------------------
--[[ string ]]--

-- Строки не соединяются, получается только первая строка.
-- [[
local s1 = 'abc\000'
local s2 = 'def'
--> s1..s2 = 'abc\\000def'
far.Message(s1..s2) --> 'abc'
--]]

--[[ string ]]--
--------------------------------------------------------------------------------
--[[ table ]]--

-- Как проверить: пустая таблица или нет?
-- [[
local t = {}
far.Message(t == {}, 't == {}') --> false
far.Message(#t == 0, '#t == 0') --> true
far.Message(next(t, nil) == nil, 'next(t, nil) == nil') --> true
--]]

-- Зачем необходимо использовать __index?
-- [[
-- 1. Значения по умолчанию:
local Default = { x = 10, y = 10 }
local Result  = { z = 25 }
setmetatable(Result, { __index = Default })
far.Message(Result.x,  "Result.x") --> 10

-- 2. Сохранение значений по умолчанию:
Result.x = 20 --> Default.x = 10
far.Message(Result.x,  "Result.x") --> 20
far.Message(Default.x, "Default.x") --> 10
--> Result = { x = 20, z = 25 }
far.Message(Default.z == nil, "Default.z") --> true
--]]

--[[ table ]]--
--------------------------------------------------------------------------------
