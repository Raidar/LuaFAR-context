--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- Utility routines.
  -- Служебные подпрограммы.
--]]
----------------------------------------
--[[ uses:
  LuaFAR,
  LF context.
  -- group: LFc utils.
--]]
--------------------------------------------------------------------------------
local _G = _G

----------------------------------------
local bit = bit64
local band, bor  = bit.band, bit.bor
local bnot, bxor = bit.bnot, bit.bxor
local bshl, bshr = bit.lshift, bit.rshift

----------------------------------------
local win, far = win, far

----------------------------------------
--local logMsg = (require "Rh_Scripts.Utils.Logging").Message

--------------------------------------------------------------------------------
local unit = {}

---------------------------------------- null
do
  local error = error

-- null value implementation.
-- Реализация значения null.
local Tnull = {
  __index    = function (t, k)    --| (error)
    error("Attempt to get a field of null value", 2)
  end,
  __newindex = function (t, k, v) --| (error)
    error("Attempt to set a field of null value", 2)
  end,
  __metatable = "null value",
} --- Tnull
unit.null = setmetatable({}, Tnull)

end -- do

local null = unit.null -- null value instead of nil

---------------------------------------- Lua

---------------------------------------- String
-- Convert initial letter of string to upper.
-- Преобразование начальной буквы строки в верхний регистр.
function unit.initcap (s) --| (string)
  return s:sub(1, 1):upper()..s:sub(2, -1)
end --

-- Capitalize word (lowercase word with first uppercase letter).
-- Преобразование слова в строчное слово с первой заглавной буквой.
function unit.capit (s) --> (string)
  return s:sub(1, 1):upper()..s:sub(2, -1):lower()
end ----

---------------------------------------- Unicode
do
  local schar, sbyte = string.char, string.byte

-- Convert Char codepoint to UTF-16 LE two-byte char.
function unit.char16 (n) --< (number) --> (string)
  return schar(band(n, 0xFF), band(bshr(n, 8), 0xFF))
end ----

-- Convert UTF-16 LE two-byte char to Char codepoint.
function unit.byte16 (s) --< (string) --> (number)
  local n1, n2 = sbyte(s, 1, 2)
  return bor(n1 or 0x00, bshl(n2 or 0x00, 8))
end ----

end -- do

do
  local char16, byte16 = unit.char16, unit.byte16
  local U16toU8, U8toU16 = win.Utf16ToUtf8, win.Utf8ToUtf16

-- Convert Char codepoint to UTF-8 char.
function unit.u8char (n) --< (code) --> (char)
  return U16toU8(char16(n))
end ----
-- Convert UTF-8 char to Char codepoint.
function unit.u8byte (c) --< (char) --> (code)
  return byte16(U8toU16(c))
end ----

end -- do

---------------------------------------- Flags
local F = far.Flags

do
--[[
  -- @params (for flag handling):
  f     (number|bit64 string) - flag value.
  flags (number|bit64 string) - flag set.
  ...   (list)                - flag values list.
--]]

-- Create a new empty flag set.
-- Создание нового пустого набора флагов.
function unit.newFlag (flags) --> (flags)
  return flags or 0x00
end ----

-- Check flag in a set.
-- Проверка флага в наборе.
function unit.isFlag (flags, f) --> (flags)
  return band(flags, f) ~= 0
end ----

-- Add flag to a set.
-- Добавление флага к набору.
function unit.addFlag (flags, f) --> (flags)
  return bor(flags, f)
end ----

-- Delete flag from a set.
-- Удаление флага из набора.
function unit.delFlag (flags, f) --> (flags)
  return band(flags, bnot(f))
end ----

-- Invert flag from a set.
-- Обращение флага из набора.
function unit.invFlag (flags, f) --> (flags)
  return bxor(flags, f)
end ----

do
  local addFlag = unit.addFlag

-- Add flags to a set.
-- Добавление флагов к набору.
function unit.addFlags (flags, ...) --> (flags)
  for _, v in ipairs({...}) do
    flags = addFlag(flags, v)
  end
  return flags
end ----

  local delFlag = unit.delFlag

-- Delete flags from a set.
-- Удаление флагов из набора.
function unit.delFlags (flags, ...) --> (flags)
  for _, v in ipairs({...}) do
    flags = delFlag(flags, v)
  end
  return flags
end ----

end -- do

-- Create a new flag set.
-- Создание нового набора флагов.
function unit.newFlags (...) --> (flags)
  return unit.addFlags(unit.newFlag(), ...)
end ----

end -- do
do
  local type = type
  local tonumber = tonumber

  -- Number used flags
  local numFlags = {
    DIF_SETCOLOR = true, -- FAR23: Exclude!
    MIF_CHECKED  = true,
    WHEEL_DELTA  = true,
  } --- numFlags

-- Convert table-flag to number.
-- Преобразование флага-таблицы в число.
--[[
  -- @notes:
  Values of simple-value flags: 0|1, false|true, nil.
  Values of number-value flags: word-sized number.
  (Value of number-value flag takes a low word of flagh value.)
  -- @params:
  flags    (table) - source table with flags.
  numflags (table) - table with number-value flags.
--]]
function unit.numFlag (flags, numflags) --> (flags number)
  if type(flags) == 'string' then flags = { [flags] = 1 } end
  if type(flags) ~= 'table' then return flags end

  local n, numflags = 0, numflags or numFlags

  for k, v in pairs(flags) do
    --if type(v) == 'boolean' then v = b2n(v) end
    if v then n = bor(n, F[k] or 0) end
    if numFlags[k] then n = bor(n, tonumber(v)) end
  end

  return n
end ---- numFlag

end -- do

---------------------------------------- FAR
-- Plugin path.
function unit.pluginPath ()
  return far.PluginStartupInfo().ModuleName:match("(.*[/\\])")
end --

unit.PluginPath = unit.pluginPath() -- Current plugin path

-- Used interface and help language.
-- Используемый язык интерфейса и справки.
--[[
  -- @return:
  _ (table):
    Main (string) - interface language.
    Help (string) - help language.
--]]
function unit.language () --> (table)
  local key = "Software\\Far Manager\\Language"
  return {
    Main = win.GetEnv("FARLANG") or "Default",  -- Interface
    Help = win.GetRegKey("HKCU", key, "Help") or "Default", -- Help -- FAR23
  } ----
end ----

do
  local GetPanelInfo = panel.GetPanelInfo

-- Check panel as plugin panel.
-- Проверка панели на панель плагина.
function unit.isPluginPanel (Info) --> (bool)
  return unit.isFlag((Info or GetPanelInfo(nil, 1)).Flags, F.PFLAGS_PLUGIN)
end ----

end -- do

---------------------------------------- Message
do
  local farMsg = far.Message

-- Simple message box.
-- Простое окно с сообщением.
function unit.message (Title, Msg, Flags, Buttons) --| (window)
  return farMsg(Msg, Title, Buttons, Flags)
end --

-- Warning message box.
-- Окно-предупреждение с сообщением.
function unit.warning (Title, Msg, Flags) --| (window)
  return farMsg(Msg, Title, nil, (Flags or '').."w")
end --

end -- do
---------------------------------------- I/O
do
  local format = string.format

-- Full name.
function unit.fullname (path, name, ext) --> (string)
  return format('%s%s%s', path or '', name or '', ext or '')
end --

end -- do
do
  local io_open = io.open

-- Check file for exists and readability.
-- Проверка файла на существование и читаемость.
function unit.fexists (filename) --> (bool)
  local f = io_open(filename, 'rb')
  if f then f:close() end

  return f ~= nil
end ----

  local assert = assert

-- File size.
-- Размер файла.
function unit.filesize (filename) --> (number)
  local f = assert(io_open(filename, "rb"))
  local len = assert(f:seek("end"))
  f:close()

  return len
end ----

end -- do

--------------------------------------------------------------------------------
return unit
--------------------------------------------------------------------------------
