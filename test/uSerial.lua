--[[ LFc testing ]]--

----------------------------------------
--[[ description:
  -- Test: Using serialization (and debugging).
  -- Тест: Использование сериализации (и отладки).
--]]
--------------------------------------------------------------------------------

----------------------------------------
--local context = context

local tables = require 'context.utils.useTables'
local datas = require 'context.utils.useDatas'
--local locale = require 'context.utils.useLocale'
local serial = require 'context.utils.useSerial'

--local allpairs = tables.allpairs
--local addNewData = tables.extend

----------------------------------------
-- [[
local log = require "context.samples.logging"
local logShow = log.Show
--]]
-- [[
local dbg = require "context.utils.useDebugs"
local dbgShow = dbg.Show
--local logShow = dbgShow
--]]

--------------------------------------------------------------------------------
local unit = {}

----------------------------------------
--local scriptPath = "context\\test\\"

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
    --pairs = ipairs, -- Test: array fields
    --pairs = tables.hpairs, -- Test: hash fields
    pairs = pairs, -- Test: array + hash fields
    --pairs = allpairs, -- Test: all fields including from metas
  } ---

  local kind = {
    localret = true, -- Test: local + return instead of global
    tnaming = true, -- Test: temporary name of table to access fields
    astable = true, -- Test: serialize as one table
    --nesting = 0, -- Test: serialize data with max nesting level

    -- Test: for simple values:
    numwidth = 2, -- Test: min number value width
    -- Test: hex width for integer key/value
    --keyhex = 2,
    --valhex = 2,
    --valhex = true,
    -- Test: using pretty int for key/value
    --keyint = 4,
    --keyint = 20,
    -- Test: using pretty real for key/value
    --keyreal = 5,
    --keyreal = true,
    --valreal = 5,
    --valreal = true,

    --strlong = 80, -- Test: long bracket strings

    --pairs = allpairs, -- Test: all pairs
    --pairs = tables.sortpairs, -- Test: sort pairs
    --pargs = {},
    --pargs = { sortkind },

    -- Параметры линеаризации
    lining = "all",
    --lining = "array",
    --lining = "hash",
    --alimit = 33,
    alimit = 60, -- Test: length limit for line
    --acount = 5, -- Test: max field count on line
    -- [[ Test: max field count on line
    acount = function (n, t) --> (number)
               local l = #t
               return l > 17 and l / 3 or l > 9 and l / 2 or l
             end,--]]
    awidth = 4, -- Test: min field width on line
--[[
  01..09 --> 1..9
  10..17 --> 5..8
  18..30 --> 6..10
--]]

    hlimit = 60, -- Test: length limit for line
    -- [[ Test: max field count on line
    hcount = function (n, t) --> (number)
               local l = #t
               return l > 14 and l / 3 or l > 5 and l / 2 or l
             end,--]]
    hwidth = 3, -- Test: min field width on line
    --hwidth = 5, -- Test: min field width on line -- for hex
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
--local FullNameFmt = "%s%s.%s"

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
  --_Test:Save() -- Save result

  -- Test filter:
  local filter
  --filter = "w" -- Whole table as table
  --filter = "wf" -- Exclude functions in values
  --filter = "wnTFf" -- Exclude tables in keys and functions
  --filter = "wfWM" -- Exclude Words and Metas
  --filter = "wd1" -- Nesting level
  --filter = "wxv2" -- Hexadecimal number
  filter = "wi20r5" -- Integer and real number

  --logShow(_Test.test, "test", "w") -- Test samples/logging
  dbgShow(_Test.test, "test", filter) -- Test utils/useDebugs
  --[[
  -- Test "logging-to-file" object:
  local l = dbg.open("uSerialFile.log")
  l:data(_Test.test, "test", "w")
  l:close()
  --]]
end ---- Execute

--------------------------------------------------------------------------------
unit.Execute(nil)
--return unit
--------------------------------------------------------------------------------
