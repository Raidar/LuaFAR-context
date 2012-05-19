--[[ LFc testing ]]--

----------------------------------------
--[[ description:
  -- Test: Using serialization (and debug).
  -- Тест: Использование сериализации (и отладки).
--]]
--------------------------------------------------------------------------------
local _G = _G

----------------------------------------
local context = context

local tables = require 'context.utils.useTables'
local datas = require 'context.utils.useDatas'
local locale = require 'context.utils.useLocale'
local serial = require 'context.utils.useSerial'

local allpairs = tables.allpairs
local addNewData = tables.extend

----------------------------------------
local log = require "context.samples.logging"
local dbg = require "context.utils.useDebugs"
local logShow = log.Show
local dbgShow = dbg.Show
--local logShow = dbgShow

--------------------------------------------------------------------------------
local unit = {}

----------------------------------------
local scriptPath = "context\\test\\"

---------------------------------------- Test class
local TTest = { -- Информация по умолчанию:
} --- TLang
local MTest = { __index = TTest }

-- Создание объекта.
local function CreateTest (Data) --> (object)
  local self = {
    Data = Data,
    test = false,
  } --- self
  return setmetatable(self, MTest)
end -- CreateTest

---------------------------------------- methods
local tconcat = table.concat

-- Make data in subtable.
function TTest:makesub (kind) --| test
  local t, l = self.test[kind], self.test.Liter
  l[kind] = tconcat(t) -- string with letters

  -- Hash-list with positions of array items
  for k, v in ipairs(t) do t[v] = k end
end ---- makesub

-- Fill test using source data.
function TTest:Fill () --| Language

  local l = self.test

  do -- Fill .Konal
    local t = l.Konal
    for _, v in ipairs(l.Sonor) do t[#t + 1] = v end
    for _, v in ipairs(l.Sinel) do t[#t + 1] = v end
  end -- do

  do -- Make data
    self:makesub("Vocal")
    self:makesub("Konal")
    self:makesub("Sonor")
    self:makesub("Sinel")
    self:makesub("Hemil")
  end -- do

  do -- Fill .Yocal
    local t = l.Yocal
    local c = l.Hemal._Yocal_
    for _, v in ipairs(l.Vocal) do t[#t + 1] = c..v end
  end -- do

  do -- Fill .Yonal
    local t = l.Jonal
    local c = l.Hemal._Jonal_
    for _, v in ipairs(l.Konal) do t[#t + 1] = v..c end
  end -- do
end ---- Fill


---------------------------------------- Make
-- Загрузка.
function TTest:Load ()
  local Data = self.Data

  self.test = datas.load(Data.SourceFile, nil, 'change')
end ---- GenerateFormo

do
  local sortcompare = tables.sortcompare
  local sortpairs = tables.sortpairs

-- Сохранение.
function TTest:Save ()
  local Data = self.Data

  local sortkind = {
    --compare = sortcompare,
    --pairs = ipairs, -- TEST: array fields
    --pairs = tables.hpairs, -- TEST: hash fields
    pairs = pairs, -- TEST: array + hash fields
    --pairs = allpairs, -- TEST: all fields including from metas
  } ---

  local kind = {
    localret = true, -- TEST: local + return instead of global
    tnaming = true, -- TEST: temporary name of table to access fields
    astable = true, -- TEST: serialize as one table
    --nesting = 0, -- TEST: serialize data with max nesting level

    -- TEST: for simple values:
    --numwidth = 2, -- TEST: min number value width
    --keyhex = 2, -- TEST: hex width for integer key
    --valhex = 2, -- TEST: hex width for integer value
    --valhex = true, -- TEST: hex width for integer value
    keyfloat = true, -- TEST: using pretty float for key
    --valfloat = true, -- TEST: using pretty float for value
    --strlong = 80, -- TEST: long bracket strings

    --pairs = allpairs, -- TEST: all pairs
    --pairs = tables.sortpairs, -- TEST: sort pairs
    --pargs = {},
    --pargs = { sortkind },

    -- Параметры линеаризации
    lining = "all",
    --lining = "array",
    --lining = "hash",
    --alimit = 33,
    alimit = 60, -- TEST: length limit for line
    --acount = 5, -- TEST: max field count on line
    -- [[ TEST: max field count on line
    acount = function (n, t) --> (number)
               local l = #t
               return l > 17 and l / 3 or l > 9 and l / 2 or l
             end,--]]
    awidth = 4, -- TEST: min field width on line
--[[
  01..09 --> 1..9
  10..17 --> 5..8
  18..30 --> 6..10
--]]

    hlimit = 60, -- TEST: length limit for line
    -- [[ TEST: max field count on line
    hcount = function (n, t) --> (number)
               local l = #t
               return l > 14 and l / 3 or l > 5 and l / 2 or l
             end,--]]
    hwidth = 3, -- TEST: min field width on line
    --hwidth = 5, -- TEST: min field width on line -- for hex
--[[
  01..05 --> 1..5
  06..14 --> 3..7
  15..30 --> 5..10
--]]

    --[[ TEST: extended pretty write
    KeyToStr = serial.KeyToText,
    ValToStr = serial.ValToText,
    TabToStr = serial.TabToText,
    --]]
    serialize = serial.prettyize,
  } ---

  --logShow(self.test, "test")
  return datas.save(Data.ResultFile, "Data", self.test, kind)
end ---- GenerateFormo

end -- do

---------------------------------------- main
local FullNameFmt = "%s%s.%s"

function unit.Execute (Data) --> (bool | nil)
--[[ 1. Analyzing ]]
  local Data = Data or {}
  Data.SourceFile = Data.SourceFile or "uSerialSource.dat"
  Data.ResultFile = Data.ResultFile or "uSerialResult.dat"

--[[ 2. Configuring ]]
  local _Test = CreateTest(Data)

--[[ 3. Calling ]]
  _Test:Load() -- Load source
  --logShow(_Test.test, "Test")
  _Test:Fill() -- Fill fields
  --logShow(_Test.test, "Test")
  _Test:Save() -- Save result

  --logShow(_Test.test, "w") -- Test samples/logging
  --dbgShow(_Test.test, "w") -- Test utils/useDebugs
  --[[
  -- Test "logging-to-file" object:
  local l = dbg.open("uSerialFile.log")
  l:data(_Test.test, "w")
  l:close()
  --]]
end ---- Execute

--------------------------------------------------------------------------------
unit.Execute(nil)
--return unit
--------------------------------------------------------------------------------
