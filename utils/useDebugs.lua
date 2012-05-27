--[[ Debug ]]--
--[[ Отладка ]]--

----------------------------------------
--[[ description:
  -- Debugging and logging of scripts.
  -- Отладка и протоколирование скриптов.
--]]
----------------------------------------
--[[ uses:
  LuaFAR.
  -- group: Debug.
--]]
--------------------------------------------------------------------------------
local _G = _G

local type, unpack = type, unpack
local pairs, ipairs = pairs, ipairs
local tonumber, tostring = tonumber, tostring
local setmetatable = setmetatable

local string = string
local format = string.format

local tconcat = table.concat

local io_open = io.open

----------------------------------------
local bit = bit64

----------------------------------------
local far = far
local F = far.Flags
local far_Message, far_Show = far.Message, far.Show

----------------------------------------
local context = context

local numbers = require 'context.utils.useNumbers'
local strings = require 'context.utils.useStrings'
local serial = require 'context.utils.useSerial'

local spaces = strings.spaces -- for ShowData

----------------------------------------
-- [[
local log = require "context.samples.logging"
local logShow = log.Show
--]]

--------------------------------------------------------------------------------
local unit = {}

---------------------------------------- Config
unit.Nameless = "data"

unit.ExcludeChar = nil
--unit.ExcludeChar = '-'

local Types = {
  ["nil"]       = 'o',
  ["boolean"]   = 'b',
  ["number"]    = 'n',
  ["string"]    = 's',
  ["table"]     = 't',
  ["userdata"]  = 'u',
  ["function"]  = 'f',
  ["thread"]    = 'e',
} --- Types
unit.Types = Types

local Words = {
  -- standard modules
  ["string"] = true,
  ["package"] = true,
  ["os"] = true,
  ["io"] = true,
  ["math"] = true,
  ["debug"] = true,
  ["table"] = true,
  ["coroutine"] = true,
  -- additional modules
  ["_io"] = true,
  ["uio"] = true,
  ["bit"] = true,
  ["bit64"] = true,
  ["export"] = true,
  ["far"] = true,
  ["far2"] = true,
  ["win"] = true,
  -- special variables
  ["_G"] = true,
  ["_M"] = true,
  -- special keys
  ["__index"] = true,
  -- special functions
  ["assert"] = true,
  ["error"] = true,
  ["print"] = true,
  ["collectgarbage"] = true,
  -- typing functions
  ["type"] = true,
  ["tostring"] = true,
  ["tonumber"] = true,
  -- module functions
  ["module"] = true,
  ["require"] = true,
  ["import"] = true,
  -- fenv functions
  ["getfenv"] = true,
  ["setfenv"] = true,
  -- iteration functions
  ["pairs"] = true,
  ["ipairs"] = true,
  ["next"] = true,
  -- global functions
  ["select"] = true,
  ["unpack"] = true,
  ["rawget"] = true,
  ["rawset"] = true,
  ["rawequal"] = true,
  ["getmetatable"] = true,
  ["setmetatable"] = true,
  -- load/call functions
  ["dofile"] = true,
  ["load"] = true,
  ["loadfile"] = true,
  ["loadstring"] = true,
  ["pcall"] = true,
  ["xpcall"] = true,

  -- other variables
  _VERSION = true,
  Flags = true,
  flags = true,
  -- RectMenu
  LMap = true,
} --- Words
unit.Words = Words

local Metas = {
  -- LuaFAR context
  _meta_ = true,
} --- Metas
unit.Metas = Metas

---------------------------------------- Work
-- Plain find of string.
local function sfind (s, pat) --> (bool)
  return s:find(pat, 1, true)
end --
unit.sfind = sfind

--[[
-- Convert to string checking quotes.
local function str (s, filter) --> (string)
  return sfind(filter, "'") and format("'%s'", s or "") or
         sfind(filter, 'q') and s or ("%q"):format(s)
end --
--unit.str = str
--]]

--[[
local floor = math.floor

-- Check table key to array-part index.
local function isArrayKey (k, t) --> (bool)
  return k > 0 and k <= #t and k == floor(k)
end --
unit.isArrayKey = isArrayKey
--]]

-- Check field type to exclude.
local function isUnfitValType (tp, filter) --> (bool)
  return sfind(filter, Types[tp] or '?')
end -- isUnfitValType
unit.isUnfitValType = isUnfitValType

local supper = string.upper

local function isUnfitKeyType (tp, filter) --> (bool)
  return sfind(filter, supper(Types[tp] or '?'))
end -- isUnfitKeyType
unit.isUnfitKeyType = isUnfitKeyType

-- Check field string key to exclude.
local function isUnfitKeyName (n, filter) --> (bool)
  return sfind(filter, 'W') and Words[n] or
         sfind(filter, '/') and sfind(n, '/') or
         sfind(filter, '\\') and sfind(n, '\\') or
         sfind(filter, '.') and sfind(n, '.') or
         sfind(filter, ':') and sfind(n, ':') or
         sfind(filter, 'M') and (Metas[n] or n:find("^__"))
end -- isUnfitKey
unit.isUnfitKeyName = isUnfitKeyName

---------------------------------------- Make
do
  local getinfo = debug.getinfo

-- Convert function info to pretty text.
-- Преобразование информации о функции в читабельный текст.
local function FuncToText (func) --> (string)

  local i = getinfo(func, "uS")
  local isLua = i.what == "Lua"
  --logShow(i, "getinfo")

  local t = { "", "", "", "", "" }

  t[1] = isLua and "lua" or "non-lua"
  t[2] = "-function"
  if i.nups > 0 then
    t[3] = " w/ upvalue"
    if i.nups > 1 then
      t[4] = "s"
    end
  end

  if isLua then
    t[5] = ": "
    t[#t+1] = "in ("
    t[#t+1] = i.linedefined
    t[#t+1] = "-"
    t[#t+1] = i.lastlinedefined
    t[#t+1] = ") "
    t[#t+1] = i.source
  end

  return tconcat(t)
end ---- FuncToText
unit.FuncToText = FuncToText

  local DefaultSerialTypes = serial.DefaultSerialTypes

-- Convert special type info to pretty text.
-- Преобразование информации о спец-типе в читабельный текст.
local function SpecToText (value, kind) --> (string)
  local tp = type(value)
  if DefaultSerialTypes[tp] then return end

  if tp == 'function' then
    return FuncToText(value)
  else
    return tostring(value)
  end
end -- SpecToText
unit.SpecToText = SpecToText

  local BasicValToText = serial.ValToText

-- Convert field value to pretty text with special types.
-- Преобразование значения поля в читабельный текст со спец-типами.
function unit.ValToText (value, kind)
  local tp = type(value)

  local filter = kind.filter
  if not kind.iskey and isUnfitValType(tp, filter) then return end

  return BasicValToText(value, kind)
end ----

  local BasicKeyToText = serial.KeyToText
  local BasicSerialTypes = serial.BasicSerialTypes

-- Convert field key to pretty text with special types.
-- Преобразование ключа поля в читабельный текст со спец-типами.
function unit.KeyToText (key, kind) --> (string[, string] | nil)
  local tp = type(key)

  local filter = kind.filter
  if isUnfitKeyType(tp, filter) then return end
  if tp == 'string' and isUnfitKeyName(key, filter) then return end

  if BasicSerialTypes[tp] then
    return BasicKeyToText(key, kind)
  end

  if tp == 'table' then
    return format("[{%q}]", tostring(key))
  end

  return format("[{%q}]", SpecToText(key, kind))
end ---- KeyToText

-- Convert special types' information to pretty text.
-- Преобразование информации о специальных типах в читабельный текст.
function unit.TypToText (name, data, kind, write) --| (write)

  local u = SpecToText(data, kind)
  if not u then return end

  local cur_indent = kind.indent
  if kind.isarray then
    write(cur_indent, format("nil, -- %s\n", u))
  else
    write(cur_indent, format("%s = nil, -- %s\n", name, u))
  end

  return true
end ---- TypToText
  
  local select = select

-- Save data to array.
-- Сохранение данных в массив.
--[[
  -- @params:
  name   (string) - data table name.
  data    (t|nil) - processed data table.
  kind    (t|nil) - conversion kind (@see serial.prettyize):
    -- @fields additions: none.
    -- @locals in kind:
    filter (string) - @see filter param.
  filter (string) - filter some fields; filter characters:
                    -- common:
                    - w - write data as whole table.
                    - d%d+ - max depth (nesting) level to convert.
                    -- fields:
                    - O|B|N|S|T|U|F|E - exclude some key types
                                        (@see unit.Types).
                    - o|b|n|s|t|u|f|e - exclude some value types.
                                        (@see unit.Types).
                    - /|\|.|: - exclude fields containing this chars in keys.
                    - W - exclude some word names in keys (@see unit.Words).
                    - M - exclude meta-fields names in keys (@see unit.Metas).
                    -- format:
                    - x%d+ | xk%d* | xv%d* - @see kind.keyhex/kind.valhex.
                    - i%d+ | ik%d* | iv%d* - @see kind.keyint/kind.valint.
                    - r%d+ | rk%d* | rv%d* - @see kind.keyreal/kind.valreal.
  -- @return:
  array   (table) - array of strings.
--]]
function unit.toarray (name, data, kind, filter) --> (table)
  kind = kind or {}
  kind.filter = filter or ""

  -- Copy settings from filter to kind:

  local t, n = {}, 0
  local u, m = {}, 0 -- temporary table to concat one line only

  -- Write strings to array.
  --[[ Algorithm:
    for all arguments do
      1. Repeat by '\n':
        1.1. Collect all before '\n' to subarray u.
        1.2. Concat subarray u to array t.
      2. Save all after last '\n' to subarray u.
  --]]
  local write = function (...)
                  --log({ ... }, tostring(kind.level or -1))
                  for i = 1, select("#", ...) do
                    local s = select(i, ...)
                    -- Match for first "\n":
                    local sl, sr = s:match("^([^\n]*)\n([^\n]*)$")
                    while sl do
                      -- Collect strings before "\n":
                      if sl ~= "" then
                        m = m + 1
                        u[m] = sl
                      end
                      -- Move collected to t:
                      if m > 0 then
                        n = n + 1
                        t[n] = tconcat(u)
                        u, m = {}, 0 -- reset
                      end
                      -- Next match for "\n":
                      if sr ~= "" then
                        s = sr
                        sl, sr = s:match("^([^\n]*)\n([^\n]*)$")
                      else
                        s, sl = "", false
                      end
                    end
                    -- Save string after last "\n":
                    if s ~= "" then
                      m = m + 1
                      u[m] = s
                    end
                  end -- for

                  return true
                end -- write

  local res, s = serial.prettyize(name, data, kind, write)

  -- Move last collected to t:
  if m > 0 then
    n = n + 1
    t[n] = tconcat(u)
  end
  t.n = n

  --logShow(t, "toarray")

  if res == nil then return nil, s end

  return t, s
end -- toarray

end -- do

---------------------------------------- Linearize
unit.linewidth = 60

-- Get array items count on one line.
--[[
  @return:
  1..9  - for count in 01..09.
  5..8  - for count in 10..17.
  6..10 - count in 18..30.
--]]
function unit.acount (n, t) --> (number)
  local l = #t
  return l > 17 and l / 3 or l > 9 and l / 2 or l
end

-- Get hash items count on one line.
--[[
  @return:
  1..5  - for count in 01..05.
  3..7  - for count in 06..14.
  5..10 - count in 15..30.
--]]
function unit.hcount (n, t) --> (number)
  local l = #t
  return l > 14 and l / 3 or l > 5 and l / 2 or l
end

---------------------------------------- Tabulize
-- Tabulize data for logging.
-- Табулирование данных для протоколирования.
--[[
  -- @params: @see unit.toarray.
  -- @return: @see unit.toarray.
--]]
function unit.tabulize (name, data, kind, filter) --> (table)
  name = name or unit.Nameless
  local kind = kind or {}

  -- Prettyize special types and filter all types:
  kind.KeyToStr = unit.KeyToText -- in keys
  kind.ValToStr = unit.ValToText -- in values
  kind.TypToStr = unit.TypToText -- in special values

  -- Nesting level or empty string:
  if type(filter) == 'number' then
    filter = format("d%d", filter)
  else
    filter = filter or ""
  end
  --logShow({ filter, kind })

  -- Common:
  kind.localret = false
  if sfind(filter, 'w') then kind.astable = true end
  local depth = filter:match("d(%d+)") -- Nesting:
  if depth then kind.nesting = tonumber(depth) end

  -- Linearization:
  if kind.lining == nil then kind.lining = "all" end
  kind.alimit = kind.alimit or unit.linewidth
  kind.hlimit = kind.hlimit or unit.linewidth
  kind.acount = kind.acount or unit.acount
  kind.hcount = kind.hcount or unit.hcount

  -- Hexadecimal format:
  local aw, w = filter:match("x(%d+)")
  w = aw or filter:match("xk(%d*)")
  if w then kind.keyhex = w == "" or tonumber(w) end
  w = aw or filter:match("xv(%d*)")
  if w then kind.valhex = w == "" or tonumber(w) end

  -- Format for integers:
  aw = filter:match("i(%d+)")
  w = aw or filter:match("ik(%d*)")
  if w then kind.keyint = w == "" or tonumber(w) end
  w = aw or filter:match("iv(%d*)")
  if w then kind.valint = w == "" or tonumber(w) end

  -- Format for integers:
  aw = filter:match("r(%d+)")
  w = aw or filter:match("rk(%d*)")
  if w then kind.keyreal = w == "" or tonumber(w) end
  w = aw or filter:match("rv(%d*)")
  if w then kind.valreal = w == "" or tonumber(w) end

  --logShow({ filter, kind })

  return unit.toarray(name, data, kind, filter)
end ---- tabulize

---------------------------------------- Show
do
unit.Separ = "│"
unit.TextFmt = "%s%s%s%s"
--unit.TextFmt = "%s%s %s %s"
unit.BKeys = {
  {BreakKey = 'RETURN'},
  {BreakKey = 'SPACE'}
} ---

  local slen = string.len

-- Show data as menu.
-- Показ данных как меню.
--[[
  -- @params: @see unit.Show.
  kind    (t|nil) - conversion kind: @fields additions:
    ShowMenu (func) - function to show menu with tabulized data.
  -- @return: @see kind.Show.
--]]
function unit.ShowData (data, name, kind) --| (menu)
  local kind = kind or {}
  local ShowMenu = kind.ShowMenu or far.Menu

  local Separ = unit.Separ
  local TextFmt = unit.TextFmt

  local items, n = {}, #data
  local nlen = slen(tostring(n))

  for k, v in ipairs(data) do
    local m, sp = tostring(k)
    local isnum = true
    for s in v:gmatch("[^\n]+") do
      if isnum then
        isnum = false
        sp = spaces[nlen - slen(m)]
      else
        m = ""
        sp = spaces[nlen]
      end
      items[#items + 1] = {
        text = format(TextFmt, sp, m, Separ, s),
      }
    end
  end

  local props = {
    Title = name or unit.Nameless,
    Flags = 'FMENU_SHOWAMPERSAND',
  } ---

  return ShowMenu(props, items, unit.BKeys)
end ---- ShowData

-- Show data based on far.Show.
-- Показ данных, основанный на far.Show.
function unit.farShow (data) --| (menu)
  return far.Show(unpack(data))
end ----

-- Show data.
-- Показ данных.
--[[
  -- @params: @see unit.toarray.
  kind    (t|nil) - conversion kind: @fields additions:
    ShowData (func) - function to show tabulized data.
  -- @return: @see kind.ShowData.
--]]
function unit.Show (data, name, filter, kind) --| (menu)
  local name = name or unit.Nameless
  local kind = kind or {}

  local ShowData = kind.ShowData or unit.ShowData
  return ShowData(unit.tabulize(name, data, kind, filter), name, kind)
end ---- Show

end -- do
---------------------------------------- Logging
do

local TLogging = {} -- Logging-to-file class
local MLogging = { __index = TLogging }

function TLogging:log (...)
  self.file:write(...)
end ----

local nowDT = os.date
local fmtDT = "%Y-%m-%d %H:%M:%S "

function TLogging:logln (...)
  if self.isDT then
    self:log(nowDT(self.fmtDT))
  end
  self:log(...)
  self:log('\n')
end ----

function TLogging:logtab (t, name) --< array
  self:logln(name or "")
  for k, v in ipairs(t) do
    self:log(v)
    self:log('\n')
  end --
  self:logln(name or "")
end ---- logtab

function TLogging:data (data, filter, name, kind)
  self:logtab(unit.tabulize(name, data, kind, filter), name or "data")
end ----

function TLogging:close (s) --< (file table)
  self:log('\n')
  self:logln(s or "Stop logging")

  local f = self.file
  f:flush()
  f:close()
  --return true
end ---- close

local io_open = io.open

function unit.open (filename, mode, s) --> (file table)
   local self = {
     isDT = true,   -- Show datetime before log-text
     fmtDT = fmtDT, -- Format of datetime

     name = filename,
     file = io_open(filename, mode or "w+"),
   } ---
   if self.file == nil then return end

   setmetatable(self, MLogging)
   self:logln(s or "Start logging")

   return self
end ---- open

end -- do
--------------------------------------------------------------------------------
return unit
--------------------------------------------------------------------------------
