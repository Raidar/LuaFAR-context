--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- Working with numbers.
  -- Работа с числами.
--]]
----------------------------------------
--[[ uses:
  LuaFAR,
  LF context.
  -- group: LFc utils.
--]]
--------------------------------------------------------------------------------

local floor, ceil = math.floor, math.ceil

----------------------------------------
--local bit = bit64
--local band, bor  = bit.band, bit.bor
--local bnot, bxor = bit.bnot, bit.bxor
--local bshl, bshr = bit.lshift, bit.rshift

----------------------------------------
--local win, far = win, far

----------------------------------------
--local logShow = context.Show

--------------------------------------------------------------------------------
local unit = {}

---------------------------------------- Convert
-- WARN: This is platform-specific values.

-- Max integer number to convert as integer with tostring.
-- Максимальное целое число, преобразуемое в целое с помощью tostring.
unit.MaxNumberInt = 99999999999999
-- Default precisions to convert numbers to string.
-- Точности по умолчанию при конвертировании чисел в строку.
unit.DefaultIntPrec  = 14
unit.DefaultRealPrec = 17

-- Hexadecimal string presentation of number.
-- 16-ричное строковое представление числа.
do
  local format = string.format

-- Default width for: Ox12345678
function unit.hex8 (n, width) --> (string)

  return format(format("%%#0%dx", (width or 8) + 2), n or 0)

end ----
local hex8 = unit.hex8

function unit.hex (n, width) --> (string)

  if width then
    return hex8(n, width)

  end

  return format("%#x", n or 0)

end ---- hex

  local tostring = tostring
  local DefaultIntPrec = unit.DefaultIntPrec

-- Convert an integer number to string.
-- Преобразование целого числа в строку.
function unit.i2s (n, prec) --> (string)

  n = n or 0
  if prec == true then
    return tostring(n)

  end

  return format(format("%%.%dg", prec or DefaultIntPrec), n)

end ---- i2s

  local frexp = math.frexp
  local DefaultRealPrec = unit.DefaultRealPrec

-- Convert a real number to string.
-- Преобразование вещественного числа в строку.
function unit.r2s (n, prec) --> (string)

  n = n or 0
  if prec == true then
    return tostring(n)

  end

  local fr, exp = frexp(n) -- format:
  local f = exp < 0 and "(%%.%df * 2^(%%d))" or
            exp > 0 and "(%%.%df * 2^%%d)" or "(%%.%df)"

  return format(format(f, prec or DefaultRealPrec), fr, exp)

end ---- r2s

-- Convert an integer number to string with thousand separator.
-- Преобразование целого числа в строку с разделителем тысяч.
function unit.n2s (n, fmt, separator, force) --> (string)

  n = n or 0

  local s = format(fmt or "%.f", n)
  if n < 1000 or (not force and n < 10000) then return s end

  separator = separator or " "
  s = s:reverse():gsub("...", "%0"..separator)

  return s:reverse():gsub(format("^[%s]+", separator), "")

end ---- n2s

end -- do

-- Convert a boolean to number.
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

-- Round of number.
-- Округление числа.
function unit.round (x) --> (number)

  if x >= 0 then
    return floor(x + 0.5)

  else
    return ceil(x - 0.5)

  end
end -- round

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

  local m = x%y
  local z = (x - m) / y

  return m == 0 and z or z + 1

end ----

-- Integer division (rounded).
-- Целочисленное деление (с округлением).
function unit.divr (x, y) --> (number)

  local m = x%y
  local z = (x - m) / y

  return m < y / 2 and z or z + 1

end ----

-- Integer division (with remainder).
-- Целочисленное деление (с остатком).
function unit.divm (x, y) --> (number)

  local m = x%y

  return (x - m) / y, m

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
return unit
--------------------------------------------------------------------------------
