--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- Working with string.
  -- Работа со строкой.
--]]
----------------------------------------
--[[ uses:
  LuaFAR,
  LF context.
  -- group: LFc utils.
--]]
--------------------------------------------------------------------------------
local _G = _G

local string = string
local format = string.format

----------------------------------------
local bit = bit64
local band, bor  = bit.band, bit.bor
local bnot, bxor = bit.bnot, bit.bxor
local bshl, bshr = bit.lshift, bit.rshift

----------------------------------------
--[[
local log = require "context.samples.logging"
local logShow = log.Show
--]]

--------------------------------------------------------------------------------
local unit = {}

---------------------------------------- Spaces
do
  local error = error
  local srep = string.rep

-- Prepared spaced strings.
-- Подготовленные строки из пробелов.
local Tspaces = {
  __index = function (t, k)
    if type(k) == 'number' and k >= 0 then
      local v = ""
      if k > 0 then v = srep(" ", k) end

      rawset(t, k, v)
      return v
    end

    error("Attempt to get spaced string with not number count", 2)
  end,
} ---

unit.spaces = setmetatable({}, Tspaces)

end -- do

---------------------------------------- Char
-- Get a char from specified position of string.
-- Получение символа в заданной позиции строки.
function unit.at (s, pos) --> (string)
  return s:sub(pos, pos)
end ----

---------------------------------------- String
-- Set a replace string to specified position of string.
-- Установка строки-замены в заданную позиции строки.
function unit.sat (s, pos, str) --> (string)
  return pos <= 1       and format("%s%s", str, s:sub(2, -1)) or
         pos >= s:len() and format("%s%s", s:sub(1, -2), str) or
         format("%s%s%s", s:sub(1, pos - 1), str, s:sub(pos + 1, -1))
end ---- sat

-- Insert a new string to specified position of string.
-- Вставка новой строки в заданную позицию строки.
function unit.ins (s, pos, str) --> (string)
  return pos <= 1      and format("%s%s", str, s) or
         pos > s:len() and format("%s%s", s, v) or
         format("%s%s%s", s:sub(1, pos - 1), str, s:sub(pos, -1))
end ---- ins

-- Delete a char count from specified position of string.
-- Удаление числа символов из заданной позиции строки.
function unit.del (s, pos, count) --> (string)
  return (pos < 1 or pos > s:len()) and s or
         pos == 1       and s:sub(count + 1, -1) or
         pos == s:len() and s:sub(1, -count - 1) or
         format("%s%s", s:sub(1, pos - 1), s:sub(pos + count, -1))
end ---- del

---------------------------------------- Word
-- Convert initial letter of string to upper.
-- Преобразование начальной буквы строки в верхний регистр.
function unit.initcap (s) --> (string)
  return format("%s%s", s:sub(1, 1):upper(), s:sub(2, -1))
end --

-- Capitalize word (lowercase word with first uppercase letter).
-- Преобразование слова в строчное слово с первой заглавной буквой.
function unit.capit (s) --> (string)
  return format("%s%s", s:sub(1, 1):upper(), s:sub(2, -1):lower())
end ----

---------------------------------------- LuaExp
-- Convert pattern to plain kind.
-- Преобразование шаблона в plain-вид.
function unit.makeplain (pat) --> (string)
  --return pat:gsub("[%p%?%-+*^$&]", "%%%1")
  return pat:gsub("[%p%?%-%+%*%^%$%&]", "%%%1")
end ----

do
  local makeplain = unit.makeplain

-- Count of occurrences with gsub.
-- Подсчёт числа вхождений по gsub.
function unit.gsubcount (s, pat, plain) --> (number)
  if plain then pat = makeplain(pat) end
  local _, count = s:gsub(pat, "")

  return count
end ---- gsubcount

end -- do

---------------------------------------- Convert
-- Convert a string to boolean.
-- Преобразование строки к логическому типу.
function unit.s2b (s, default) --< (string) --> (bool)
  local v = s == 'true'  and true  or
            s == 'false' and false or nil
  if v ~= nil then return v else return default end -- Without and-or!
end ---- s2b

---------------------------------------- Unicode
do
  local schar, sbyte = string.char, string.byte

-- Convert codepoint to UTF-16 LE two-byte char.
-- Преобразование кодовой точки в двухбайтный UTF-16 LE символ.
function unit.char16 (n) --< (number) --> (string)
  return schar(band(n, 0xFF), band(bshr(n, 8), 0xFF))
end ----

-- Convert UTF-16 LE two-byte char to codepoint.
-- Преобразование двухбайтного UTF-16 LE символа в кодовую точку.
function unit.byte16 (s) --< (string) --> (number)
  local n1, n2 = sbyte(s, 1, 2)
  return bor(n1 or 0x00, bshl(n2 or 0x00, 8))
end ----

end -- do

do
  local win = win
  local char16, byte16 = unit.char16, unit.byte16
  local U16toU8, U8toU16 = win.Utf16ToUtf8, win.Utf8ToUtf16

-- Convert a codepoint to UTF-8 char.
-- Преобразование кодовой точки в UTF-8 символ.
function unit.u8char (n) --< (number) --> (char)
  return U16toU8(char16(n))
end ----

-- Convert a UTF-8 char to codepoint.
-- Преобразование UTF-8 символа в кодовую точку.
function unit.u8byte (c) --< (char) --> (number)
  return byte16(U8toU16(c))
end ----

end -- do
----------------------------------------

--------------------------------------------------------------------------------
return unit
--------------------------------------------------------------------------------
