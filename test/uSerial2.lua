--[[ LFc testing ]]--

----------------------------------------
--[[ description:
  -- Test: Using serialization 2 (and debugging).
  -- Тест: Использование сериализации 2 (и отладки).
--]]
--------------------------------------------------------------------------------

----------------------------------------
--local context = context
local logShow = context.ShowInfo

local tables = require 'context.utils.useTables'
local datas = require 'context.utils.useDatas'
--local locale = require 'context.utils.useLocale'
local serial = require 'context.utils.useSerial'

--------------------------------------------------------------------------------

---------------------------------------- main
--local sortcompare = tables.sortcompare
--local sortpairs = tables.sortpairs

local function Execute ()

  local SourceFile = "uSerialSource.dat2"
  local ResultFile = "uSerialResult.dat2"

  local data = datas.load(SourceFile, nil, 'change')

  --[[
  local sortkind = {
    --compare = sortcompare,
    --pairs = ipairs, -- Test: array fields
    --pairs = tables.hpairs, -- Test: hash fields
    pairs = pairs, -- Test: array + hash fields
    --pairs = allpairs, -- Test: all fields including from metas
  } ---
  --]]

  local kind = {
    localret = true, -- Test: local + return instead of global
    tnaming = true, -- Test: temporary name of table to access fields
    astable = true, -- Test: serialize as one table
    --nesting = 0, -- Test: serialize data with max nesting level

    -- Test: for simple values:
    --numwidth = 2, -- Test: min number value width
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
    --lining = "all",
    --lining = "array",
    --lining = "hash",
    --alimit = 33,
    --alimit = 60, -- Test: length limit for line
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

  --logShow(data, "test")
  return datas.save(ResultFile, "Data", data, kind)

end ---- Execute

--------------------------------------------------------------------------------
Execute()
--------------------------------------------------------------------------------
