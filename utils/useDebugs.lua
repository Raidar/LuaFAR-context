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

local type = type
local pairs, ipairs = pairs, ipairs
local tonumber, tostring = tonumber, tostring
local setmetatable = setmetatable

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
local serial = require 'context.utils.useSerial'

----------------------------------------
--local logMsg = (require "Rh_Scripts.Utils.Logging").Message

--------------------------------------------------------------------------------
local unit = {}

---------------------------------------- Config
unit.ExcludeChar = nil
--unit.ExcludeChar = '-'

local Types = {
  ["nil"]       = 'i',
  ["boolean"]   = 'b',
  ["number"]    = 'n',
  ["string"]    = 's',
  ["table"]     = 't',
  ["userdata"]  = 'u',
  ["function"]  = 'f',
  ["thread"]    = 'h',
} --- Types
unit.Types = Types

local Names = {
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
} --- Names
unit.Names = Names

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

local format = string.format

-- Convert to hexadecimal presentation.
local hex8 = numbers.hex8
unit.hex8 = hex8
local hex = numbers.hex
unit.hex = hex

-- Convert to string checking quotes.
local function str (s, filter) --> (string)
  return sfind(filter, "'") and format("'%s'", s or "") or
         sfind(filter, 'q') and s or ("%q"):format(s)
end --
unit.str = str

local floor = math.floor

-- Check table key to array-part index.
local function isArrayKey (k, t) --> (bool)
  return k > 0 and k <= #t and k == floor(k)
end --
unit.isArrayKey = isArrayKey

-- Check type of value to include.
local function isFitType (v, filter) --> (bool)
  return not sfind(filter, Types[type(v)] or '?')
end -- isFitType
unit.isFitType = isFitType

-- Check name of value to include.
local function isFitName (n, filter) --> (bool)
  return not (sfind(filter, '_') and Names[n] or
              sfind(filter, '/') and sfind(n, '/') or
              sfind(filter, '\\') and sfind(n, '\\') or
              sfind(filter, '.') and sfind(n, '.') or
              sfind(filter, ':') and sfind(n, ':') or
              sfind(filter, 'm') and (Metas[n] or n:find("^__"))
             )
end -- isFitName
unit.isFitName = isFitName

---------------------------------------- Make
do
  local select = select
  local tconcat = table.concat

-- Save data to array.
-- Сохранение данных в массив.
--[[
  -- @params:
  name   (string) - data table name.
  data    (t|nil) - processed data table.
  kind    (t|nil) - conversion kind (@see serial.prettyize):
    -- @fields additions: none.
  filter (string) - filter to exclude some fields; filter characters:
                    -- common:
                    - w - write data as whole table.
                    - d%d+ - max depth (nesting) level to convert.
                    -- fields:
                    - i|b|n|s|t|u|f|h - exclude some types (@see unit.Types).
                    - /|\|.|: - exclude fields containing this characters.
                    - _ - exclude names (@see unit.Names).
                    - m - exclude meta-fields (@see unit.Metas).
                    -- format:
                    - q - exclude quotes from string values.
                    - ' - use apostrophes to quote string values.
                    - a - preserve accuracy for float keys and values.
                    - x%d+ | xk%d* | xv%d* - use hexadecimal format for integer
                      <key+values | keys | values> with specified number width.
  -- @return:
  array   (table) - array of strings.
--]]
function unit.toarray (name, data, kind, filter) --> (table)
  kind = kind or {}

  -- Copy settings from filter to kind:

  local t, n = {}, 0
  local u, m = {}, 0 -- temporary table to concat one line only

  local write = function (...)
                  --logMsg({ ... }, tostring(kind.level or -1))
                  for i = 1, select("#", ...) do
                    -- TODO: Алгоритм:
                    -- 1. Собирать в подтаблицу u до встречи '\n'.
                    -- 2. Перенести всё до '\n' без концевых пробелов в новую позицию t
                    -- 3. Создать новую подтаблицу, куда перенести остаток после '\n'.
                    -- Повторить несколько раз, т.к. в строке м/б несколько '\n'.
                    local s = select(i, ...)
                    -- Match for first "\n":
                    local sl, sr = s:match("^([^\n]*)\n([^\n]*)$")
                    while sl do
                      -- Collect strings before "\n":
                      if sl ~= "" then
                        m = m + 1
                        u[m] = sl
                      end
                      if m > 0 then
                        n = n + 1
                        t[n] = tconcat(u)
                        u, m = {}, 0 -- reset
                      end
                      -- Next match for "\n":
                      if sr ~= "" then
                        s = sr
                        sl, sr = s:match("^([^\n]*)\n([^\n]*)$")
                        --m = m + 1
                        --u[m] = sr
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
                end
  local res, s = serial.prettyize(name, data, kind, write)

  --logMsg(t, "toarray")

  if res == nil then return nil, s end

  return t, s
end -- toarray

end -- do

---------------------------------------- Linearize
unit.linewidth = 60

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
-- "Таблизация" данных для протоколирования.
--[[
  -- @params: @see unit.toarray.
  -- @return: @see unit.toarray.
--]]
function unit.tabulize (name, data, kind, filter) --> (table)
  name = name or "data"
  local kind = kind or {}
  local filter = filter or ""

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
  local xw = filter:match("x(%d+)")
  local w = xw or filter:match("xk(%d*)")
  if w then kind.keyhex = w == "" or tonumber(w) end
  local w = xw or filter:match("xv(%d*)")
  if w then kind.valhex = w == "" or tonumber(w) end

  -- Float with accuracy:
  if not sfind(filter, 'a') then
    kind.keyfloat = true
    kind.valfloat = true
  end

  return unit.toarray(name, data, kind, filter)
end ---- tabulize

---------------------------------------- Show
function unit.Show (data, filter, name, kind)
  return far.Show(unpack(unit.tabulize(name, data, kind, filter)))
end ----

--local tconcat = table.concat

--------------------------------------------------------------------------------
return unit
--------------------------------------------------------------------------------
