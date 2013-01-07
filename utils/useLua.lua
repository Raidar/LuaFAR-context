--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- Information about Lua language.
  -- Информация о языке Lua.
--]]
----------------------------------------
--[[ uses:
  LF context.
  -- group: Datas.
--]]
--------------------------------------------------------------------------------

----------------------------------------
--local context = context

----------------------------------------
--[[
local log = require "context.samples.logging"
local logShow = log.Show
--]]

--------------------------------------------------------------------------------
local unit = {}

----------------------------------------
local concat = table.concat
local format = string.format

---------------------------------------- const
local IdentFirstChars = "a-zA-Z_"
local IdentOtherChars = "a-zA-Z_0-9"

unit.IdentFirstChars = IdentFirstChars
unit.IdentOtherChars = IdentOtherChars
unit.IdentMask = format("^[%s][%s]-$", IdentFirstChars, IdentOtherChars)

---------------------------------------- base
unit.keywords = {
  ["do"] = true,
  ["end"] = true,
  ["local"] = true,
  ["goto"] = true,
  ["break"] = true,

  ["nil"] = true,
  ["true"] = true,
  ["false"] = true,
  ["number"] = true,
  ["function"] = true,
  ["return"] = true,

  ["if"] = true,
  ["then"] = true,
  ["elseif"] = true,
  ["for"] = true,
  ["in"] = true,
  ["while"] = true,
  ["repeat"] = true,
  ["until"] = true,

  ["not"] = true,
  ["and"] = true,
  ["or"] = true,
} -- keywords

unit.types = {
  ["nil"] = true,
  ["boolean"] = true,
  ["number"] = true,
  ["string"] = true,
  ["table"] = true,
  ["userdata"] = true,
  ["function"] = true,
  ["thread"] = true,
} -- types

unit.regex = {
  -- Lua character %-classes:
  ClassList = { '%c', '%a', '%d', '%s', '%p',
                '%l', '%u', '%w', '%x', '%z' },
  -- Lua wildcard characters:
  CardsList = { '?', '*', '+', '-' },
  Cards     = "", -- a string of them
  CardsSet  = "", -- a set of them

  DefCharEnum = "%w_",   -- Acceptable word characters
  -- Patterns:
  CharSetPat  = "[%s]",  -- for set of included characters
  NoneSetPat  = "[^%s]", -- for set of excluded characters
} -- regex
local regex = unit.regex

regex.Cards    = concat(regex.CardsList)
regex.CardsSet = format(regex.CharSetPat, regex.Cards:gsub("(.)", "%%%1"))

--logShow(regex.CardsSet, regex.Cards)

---------------------------------------- utils
local TextFirstCharMask = format("^[^%s]", IdentFirstChars)
local TextOtherCharMask = format("[^%s]", IdentOtherChars)

-- Convert a string to identifier
-- replacing unacceptable chars with '_'.
-- Преобразование строки в идентификатор
-- путём замены неприемлемых символов на '_'.
function unit.NameToIdent (name) --> (string)
  return name:gsub(TextOtherCharMask, "_")
             :gsub(TextFirstCharMask, "_%1")
             :gsub("_+", "_")
end ----

--------------------------------------------------------------------------------
return unit
--------------------------------------------------------------------------------
