--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- Working with number.
  -- Работа с числом.
--]]
----------------------------------------
--[[ uses:
  LuaFAR,
  LF context.
  -- group: LFc utils.
--]]
--------------------------------------------------------------------------------
local _G = _G

local floor = math.floor

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

---------------------------------------- Convert
-- Hexadecimal string presentation of number.
-- 16-ричное строковое представление числа.
do
  local tostring = tostring
  local sformat = string.format

-- Default width for: Ox12345678
function unit.hex8 (n, width) --> (string)
  return sformat(sformat("%%#0%dx", width or 10), n or 0)
end ----
local hex8 = unit.hex8

function unit.hex (n, width) --> (string)
  if width then
    return hex8(n, width)
  end
  return sformat("%#x", n or 0)
end ---- hex

end -- do

-- Conversion of a boolean to number.
-- Преобразование логического значения в число.
function unit.b2n (b) --< (bool) --> (number)
  return b and 1 or 0 -- tonumber(b) don't work!
end ----

---------------------------------------- Math
-- Sign of number.
-- Знак числа.
function unit.sign (n) --> (-1 | 0 | 1 | nil)
  return n and (n > 0 and 1 or n < 0 and -1 or 0)
end ----

-- Minimum of 2 numbers.
-- Минимум двух чисел.
function unit.min2 (x, y) --> (number)
  return x <= y and x or y
end ----

-- Maximum of 2 numbers.
-- Максимум двух чисел.
function unit.max2 (x, y) --> (number)
  return y <= x and x or y
end ----

---------------------------------------- Numbers
-- Increment of 2 numbers.
-- Инкремент двух переменных.
function unit.inc2 (a, b) --> (number)
  return a + 1, b + 1
end ----

-- Decrement of 2 numbers.
-- Декремент двух переменных.
function unit.dec2 (a, b) --> (number)
  return a - 1, b - 1
end ----

-- Swap of 2 variables' values.
-- Обмен значений двух переменных.
function unit.swap (a, b) --> (number, number)
  return b, a
end ----

-- Check for an integer number.
-- Проверка на целочисленность.
function unit.isint (x) --> (bool)
  return floor(x) == x
end ----

-- Check for NaN (not a number).
-- Проверка на NaN (не число).
function unit.isnan (x) --> (bool)
  return x ~= x
end ----

---------------------------------------- Division
-- Integer division (like floor).
-- Целочисленное деление (обычное).
function unit.divf (x, y) --> (number)
  return (x - x%y) / y
end ----

-- Integer division (like ceil).
-- Целочисленное деление (с запасом).
function unit.divc (x, y) --> (number)
  local m = x%y; local z = (x - m) / y
  if m == 0 then return z else return z + 1 end
end ----

-- Integer division (rounded).
-- Целочисленное деление (с округлением).
function unit.divr (x, y) --> (number)
  local m = x%y; local z = (x - m) / y
  if m < y / 2 then return z else return z + 1 end
end ----

-- Integer division (with remainder).
-- Целочисленное деление (с остатком).
function unit.divm (x, y) --> (number)
  local m = x%y; return (x - m) / y, m
end ----

---------------------------------------- Operation
-- Extract an integer square root.
-- Извлечение целочисленного квадратного корня.
function unit.sqrti (x) --> (number)
  return floor(x^(1/2)) -- MAYBE: Лучше методом дихотомии?!
end ----

---------------------------------------- Range
-- Check value in range.
-- Проверка на принадлежность значения диапазону.
function unit.inrange (n, min, max) --> (bool)
  return n >= min and n <= max
end ----

-- Check value not in range.
-- Проверка на НЕпринадлежность значения диапазону.
function unit.outrange (n, min, max) --> (bool)
  return n < min or n > max
end ----

-- Get value within range.
-- Получение значения в диапазоне.
function unit.torange (n, min, max) --> (number)
  return n < min and min or n > max and max or n
end ----

--------------------------------------------------------------------------------
context.numbers = unit -- 'numbers' table in context
--------------------------------------------------------------------------------
