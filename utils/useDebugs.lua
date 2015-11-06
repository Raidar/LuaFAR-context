--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- Debugging and logging of scripts.
  -- Отладка и протоколирование скриптов.
--]]
----------------------------------------
--[[ uses:
  LuaFAR.
  -- group: Datas, Debug.
--]]
--------------------------------------------------------------------------------

local type = type
local ipairs = ipairs
local tonumber, tostring = tonumber, tostring

local string = string
local format = string.format

local tconcat = table.concat

----------------------------------------
--local bit = bit64

----------------------------------------
local far = far
--local F = far.Flags

----------------------------------------
--local logShow = context.Show

local serial = require 'context.utils.useSerial'

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

-- Default width for: Ox12345678
function unit.hex8 (n, width) --> (string)
  return format(format("%%#0%dx", (width or 8) + 2), n or 0)
end ----

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
local function FuncToText (func, kind) --> (string)

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
    -- [[
    if kind.lining then
      t[5] = ":\n"
      t[6] = kind.indent
      t[7] = kind.shift
      t[8] = "-- "
    else
    --]]
      t[5] = ": "
    end
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
    return FuncToText(value, kind)
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
  kind    (t|nil) - conversion kind: @see serial.prettyize and:
    -- @fields additions: none.
    -- @locals in kind:
    filter (string) - @see filter param.
  filter (string) - filter some fields; filter characters:
                    -- common:
                    - w - write data as whole table.
                    - A - pairs all fields.
                    - d%d+ - max depth (nesting) level to convert.
                    -- fields:
                    - O|B|N|S|T|U|F|E - exclude some key types:
                                        @see unit.Types.
                    - o|b|n|s|t|u|f|e - exclude some value types:
                                        @see unit.Types.
                    - /|\|.|: - exclude fields containing this chars in keys.
                    - W - exclude some word names in keys: @see unit.Words.
                    - M - exclude meta-fields names in keys: @see unit.Metas.
                    -- format:
                    - x%d+ | xk%d* | xv%d* - @see kind.keyhex/kind.valhex.
                    - i%d+ | ik%d* | iv%d* - @see kind.keyint/kind.valint.
                    - r%d+ | rk%d* | rv%d* - @see kind.keyreal/kind.valreal.
                    - a%d+ | ak%d+ | av%d+ - @see kind.alimit/.acount/.awidth.
                    - h%d+ | hk%d+ | hv%d+ - @see kind.hlimit/.hcount/.hwidth.
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
                  --logShow({ tostring(kind.level or -1), ... })
                  for i = 1, select("#", ...) do
                    local s = select(i, ...)
                    -- Match for first '\n':
                    local sl, sr = s:match("^([^\n]-)\n(.*)$")
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
                      -- Match for next '\n':
                      if sr ~= "" then
                        s = sr
                        sl, sr = s:match("^([^\n]-)\n(.*)$")
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

  --logShow("Start")
  local res, s = serial.prettyize(name, data, kind, write)

  -- Move last collected to t:
  if m > 0 then
    n = n + 1
    t[n] = tconcat(u)
  end
  t.n = n
  --logShow("Stop")

  --logShow(t, "toarray")

  if res == nil then return nil, s end

  return t, s
end -- toarray

end -- do

---------------------------------------- Linearize
unit.linewidth = 60
unit.fieldwidth = 1

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
  if sfind(filter, 'A') then
    local tables = require 'context.utils.useTables'
    kind.pairs = tables.allpairs
  end
  local depth = filter:match("d(%d+)") -- Nesting:
  if depth then kind.nesting = tonumber(depth) end

  -- Linearization:
  local w, aw -- value, common value
    -- common:
  if kind.lining == nil then kind.lining = "all" end
    -- for array:
  w = filter:match("a(%d+)")
  kind.alimit = w and tonumber(w) or kind.alimit or unit.linewidth
  w = filter:match("ak(%d+)")
  kind.acount = w and tonumber(w) or kind.acount or unit.acount
  w = filter:match("av(%d+)")
  kind.awidth = w and tonumber(w) or kind.awidth or unit.fieldwidth
    -- for hash:
  w = filter:match("h(%d+)")
  kind.hlimit = w and tonumber(w) or kind.hlimit or unit.linewidth
  w = filter:match("hk(%d+)")
  kind.hcount = w and tonumber(w) or kind.hcount or unit.hcount
  w = filter:match("hv(%d+)")
  kind.hwidth = w and tonumber(w) or kind.hwidth or kind.fieldwidth

  -- Hexadecimal format:
  aw = filter:match("x(%d+)")
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

  -- Format for reals:
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
  { BreakKey = 'RETURN' },
  { BreakKey = 'SPACE' },
  -- Copy to clipboard:
  { BreakKey = 'C', Action = "Copy" },    -- original text
  { BreakKey = 'X', Action = "CopyEx" },  -- text with numbers
  { BreakKey = 'Z', Action = "CopyAs" },  -- text without numbers
  { BreakKey = 'V', Action = "Value" },   -- text of selected item
} --- BKeys

  local slen  = string.len
  local sfind = string.find

  local strings = require 'context.utils.useStrings'
  local spaces = strings.spaces

-- Show data as menu.
-- Показ данных как меню.
--[[
  -- @params: @see unit.Show.
  kind    (t|nil) - conversion kind: @fields additions:
    ShowMenu (func) - function to show menu with tabulized data.
    ShowLineNumber (bool) - show line numbers (@default = true).
    ChosenToClip   (bool) - copy chosen text to clipboard (@default = false).
  -- @return:
  Item    (t|nil) - an item of data menu.
--]]
function unit.ShowData (data, name, kind) --| (item)
  if type(data) ~= 'table' then
    return far.Message(tostring(data), name or unit.Nameless)
  end

  local kind = kind or {}
  local ShowMenu = kind.ShowMenu or far.Menu
  local ShowLineNumber = kind.ShowLineNumber == nil or kind.ShowLineNumber

  local Separ = unit.Separ
  local TextFmt = unit.TextFmt

  local items, n = {}, #data
  local nlen = slen(tostring(n))

  for k = 1, #data do
    local m, sp = tostring(k)
    local isnum = true

    for s in data[k]:gmatch("[^\n]+") do
      if ShowLineNumber then
        if isnum then
          isnum = false
          sp = spaces[nlen - slen(m)]
        else
          m = ""
          sp = spaces[nlen]
        end
        items[#items + 1] = {
          line = k,
          text = format(TextFmt, sp, m, Separ, s),
        }

      else
        items[#items + 1] = {
          line = k,
          text = s,
        }
      end
    end
  end

  local props = {
    Title = name or unit.Nameless,
    Flags = 'FMENU_SHOWAMPERSAND',
  } ---

  local Item, Pos = ShowMenu(props, items, unit.BKeys)

  if Item then
    if Item.Action then
      --logShow({ Pos, Item }, "Item")
      if Item.Action == "Value" and Pos then
        far.CopyToClipboard(items[Pos].text)

      elseif sfind(Item.Action, "Copy", 1, true) == 1 then
        local s
        if Item.Action == "Copy" then
          s = tconcat(data, "\n")

        elseif Item.Action == "CopyEx" then
          local t = {}
          for k, v in ipairs(items) do
            t[k] = v.text
          end
          s = tconcat(t, "\n")

        elseif Item.Action == "CopyAs" then
          local t = {}
          local f = format("^(.-%s)", unit.Separ)
          --logShow(f)
          for k, v in ipairs(items) do
            t[k] = v.text:gsub(f, "")
          end
          s = tconcat(t, "\n")
        end

        far.CopyToClipboard(s)
      end

    elseif kind.ChosenToClip and Pos then
      --logShow({ Pos, Item }, "Item")
      far.CopyToClipboard(items[Pos].text)
    end
  end

  return Item
end ---- ShowData

  local unpack = unpack

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

  --logShow(data)
  --logShow(type(data))
  local ShowData = kind.ShowData or unit.ShowData
  --logShow(unit.tabulize(name, data, kind, filter))
  --logShow(type(unit.tabulize(name, data, kind, filter)))
  return ShowData(unit.tabulize(name, data, kind, filter), name, kind)
end ---- Show

end -- do
---------------------------------------- Logging
do

local TLogging = {} -- Logging-to-file class
local MLogging = { __index = TLogging }

function TLogging:log (...)
  return self.file:write(...)
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
  local name = name or ""
  self:logln(name..":")
  for _, v in ipairs(t) do
    self:log(v)
    self:log('\n')
  end --
  self:logln("~"..name)
end ---- logtab

function TLogging:data (data, filter, name, kind)
  return self:logtab(unit.tabulize(name, data, kind, filter), name or "data")
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
local setmetatable = setmetatable

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
