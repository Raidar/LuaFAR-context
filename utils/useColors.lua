--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- Working with colors.
  -- Работа с цветами.
--]]
----------------------------------------
--[[ uses:
  LuaFAR,
  LF context.
  -- group: LFc utils.
--]]
--------------------------------------------------------------------------------

local type = type

----------------------------------------
local bit = bit64
local band, bor  = bit.band, bit.bor
--local bnot, bxor = bit.bnot, bit.bxor
local bshl, bshr = bit.lshift, bit.rshift

----------------------------------------
local far = far
local F = far.Flags

local Flag_FarColor = F.FCF_4BITMASK

----------------------------------------
--local logShow = context.Show

--------------------------------------------------------------------------------
-- Color handling class
local unit = {
  Mask      = 0xF,
  Shift     = 0x4,
  Default   = 0xF0,

  FGMask    = 0x0F,
  BGMask    = 0xF0,

  DefFG     = 0xF,
  DefBG     = 0x0,

  Flags     = 'Flags',
  FGName    = 'ForegroundColor',
  BGName    = 'BackgroundColor',
} ---
unit.FGMask =      unit.Mask
unit.BGMask = bshl(unit.Mask, unit.Shift)

--local MColors = { __index = unit }

---------------------------------------- Colors
do
  local setmetatable = setmetatable

  -- Base colors.
  -- Основные цвета.
  local BaseColors = {
  -- name = Console -- Default   Real  | Nearest         | Standard name
    black    = 0x0, -- 000000 | 000000 | 000000          | black
    navy     = 0x1, -- 000080 | 0000AA | 000080 / 0000FF | navy blue / blue
    green    = 0x2, -- 008000 | 00AA00 | 008000 / 00FF00 | ? / green
    cyan     = 0x3, -- 008080 | 00AAAA | 008080 / 00FFFF | teal / cyan+aqua
    maroon   = 0x4, -- 800000 | AA0000 | 800000 / 960018 | maroon / carmine
    purple   = 0x5, -- 800080 | AA00AA | 800080 / 660099 | ? / purple
    brown    = 0x6, -- 808000 | AA5500 | 808000 / 964B00 | olive / brown
    silver   = 0x7, -- C0C0C0 | AAAAAA | C0C0C0          | silver
    gray     = 0x8, -- 808080 | 555555 | 808080 / 708090 | gray / slate gray
    blue     = 0x9, -- 0000FF | 5555FF | 0000FF / 1E90FF | blue / dodger blue
    lime     = 0xA, -- 00FF00 | 55FF55 | 00FF00 / CCFF00 | green / lime
    aqua     = 0xB, -- 00FFFF | 55FFFF | 00FFFF / 7FFFD4 | aqua+cyan / aquamarine
    red      = 0xC, -- FF0000 | FF5555 | FF0000 / FF2400 | red / scarlet
    pink     = 0xD, -- FF00FF | FF55FF | FF00FF / FFC0CB | fuchsia+magenta / pink
    yellow   = 0xE, -- FFFF00 | FFFF55 | FFFF00 / FFFDD0 | yellow / cream
    white    = 0xF, -- FFFFFF | FFFFFF | FFFFFF          | white
  } ---

  --logShow(BaseColors, "BaseColors")

  -- All colors.
  -- Все цвета.
  local Colors = { __index = BaseColors }
  setmetatable(Colors, Colors)

  -- Одноимённые цвета:
  Colors.land    = BaseColors.green
  Colors.teal    = BaseColors.cyan
  Colors.magenta = BaseColors.purple
  Colors.olive   = BaseColors.brown
  Colors.fuchsia = BaseColors.pink

  -- Учёт яркости цветов:
  for k, v in pairs(BaseColors) do
    if v >= 0x1 and v <= 0x6 then
      --Colors["dark"..k]   = v
      --Colors["deep"..k]   = v
      Colors["light"..k]  = v + 0x8
      --Colors["bright"..k] = v + 0x8
    elseif v >= 0x9 and v <= 0xE then
      Colors["dark"..k]   = v - 0x8
      --Colors["deep"..k]   = v - 0x8
      --Colors["light"..k]  = v
      --Colors["bright"..k] = v
    end
  end

  -- Специальные цвета:
  Colors.darkgray = Colors.gray

  --logShow(Colors, "Additional Colors", 1)

  unit.Colors = Colors
  unit.BaseColors = BaseColors

  unit.__index = Colors
  setmetatable(unit, unit)
end -- do

---------------------------------------- functions

-- Number value of table-color.
-- Численное значение цвета-таблицы.
function unit.tonumber (color) --> (number)
  if type(color) ~= 'table' then return color end
  local self = unit

  return bor(     band(color[self.FGName], self.FGMask),
             bshl(band(color[self.BGName], self.BGMask), self.Shift))
end ---- tonumber

-- Table value of number-color.
-- Табличное значение цвета-числа.
function unit.totable (color) --> (table)
  if type(color) == 'table' then return color end

  local self = unit
  return {
    [self.Flags]  = Flag_FarColor,
    [self.FGName] = band(     color, self.FGMask             ),
    [self.BGName] = band(bshl(color, self.Shift), self.BGMask),
  }
end ---- totable

-- Required value of color.
-- Требуемое значение цвета.
function unit.tocolor (color, kind) --> (table|number)
  local self, tp = unit, type(color)
  if tp == 'number' then
    return kind ~= 'table' and color or self.totable(color)
  elseif tp == 'table' then
    return kind == 'table' and color or self.tonumber(color)
  end

  return color
end ---- tocolor

-- Get foreground color for color.
-- Получение цвета символа для цвета.
function unit.getFG (color) --> (number)
  if type(color) == 'table' then
    return color[unit.FGName]
  end

  return band(color, unit.FGMask)
end ---- getFG

-- Get background color for color.
-- Получение цвета фона для цвета.
function unit.getBG (color) --> (number)
  if type(color) == 'table' then
    return color[unit.BGName]
  end

  return bshr(color, unit.Shift)
end ---- getBG

-- Set foreground color for color.
-- Установка цвета символа для цвета.
function unit.setFG (color, fg) --> (number)
  local self = unit

  if type(color) == 'table' then
    color[self.FGName] = fg

    return color
  end

  return bor(band(color, self.BGMask), band(fg, self.Mask))
end ---- setFG

-- Set background color for color.
-- Установка цвета фона для цвета.
function unit.setBG (color, bg) --> (number)
  local self = unit

  if type(color) == 'table' then
    color[self.BGName] = bg

    return color
  end

  return bor(band(color, self.FGMask),
             bshl(band(bg, self.Mask), self.Shift))
end ---- setBG

-- Make color (by values).
-- Формирование цвета (по значениям).
function unit.make (fg, bg, kind) --> (color)
  local self = unit

  if (kind or 'table') == 'table' then
    return {
      [self.Flags]  = Flag_FarColor,
      [self.FGName] = fg,
      [self.BGName] = bg,
    }
  end

  return bor(fg, bshl(bg, self.Shift))
end ---- make

-- Make color (by colors).
-- Формирование цвета (по цветам).
function unit.cmake (fg, bg, kind) --> (color)
  local self = unit

  if (kind or 'table') == 'table' then
    return {
      [self.Flags]  = Flag_FarColor,
      [self.FGName] = type(fg) == 'table' and fg[self.FGName] or fg,
      [self.BGName] = type(bg) == 'table' and bg[self.FGName] or bg,
    }
  end

  return bor(band(fg, self.FGMask), band(bg, self.BGMask))
end ---- cmake

---------------------------------------- methods
-- Make new color (by values).
-- Формирование нового цвета (по значениям).
function unit:newColor (fg, bg, kind) --> (color)
  local self = self

  if (kind or 'table') == 'table' then
    return {
      [self.Flags]  = Flag_FarColor,
      [self.FGName] = fg,
      [self.BGName] = bg,
    }
  end

  return bor(fg, bshl(bg, self.Shift))
end ---- newColor

do
  local ColorFormat = "^(%a+)%s+.+%s+(%a+)$"

-- Get color (by name).
-- Получение цвета (по имени).
--[[
  -- @params:
  color  (string) - color name (may be color).
  kind   (string) - color format kind: 'table' | 'number'.
--]]
function unit:getColor (color, kind) --> (color)
  local self = self
  -- TODO: Копировать self.Default, если это таблица!
  local color = color or self.Default

  if type(color) ~= 'string' then
    return self.tocolor(color, kind)
  end

  local fg, bg = color:match(ColorFormat)
  fg = fg and self[fg] or self.DefFG
  bg = bg and self[bg] or self.DefBG

  return self:newColor(fg, bg, kind)
end ---- getColor

end -- do

-- Get color from data and store value.
-- Получение цвета из data и запоминание значения.
--[[
  -- @params:
  data    (table) - data table.
  name   (string) - field with color.
  prefix (string) - name prefix for value store.
  kind   (string) - color format kind: 'table' | 'number'.
--]]
function unit:dataColor (data, name, prefix, kind) --> (color)
  --local data, name = data, name
  local prefix = prefix or '_'
  local color = data[prefix..name]

  if color ~= nil and type(color) ~= 'string' then
    return self.tocolor(color, kind or 'table')
  end

  color = self:getColor(data[name], kind)
  data[prefix..name] = color

  return color
end ---- dataColor

--------------------------------------------------------------------------------
return unit
--------------------------------------------------------------------------------
