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
local _G = _G

----------------------------------------
local context = context

----------------------------------------
--[[
local log = require "context.samples.logging"
local logShow = log.Show
--]]

--------------------------------------------------------------------------------
local unit = {}

---------------------------------------- const
local format = string.format

local IdentFirstChars = "a-zA-Z_"
local IdentOtherChars = "a-zA-Z_0-9"

unit.IdentFirstChars = FirstChars
unit.IdentOtherChars = OtherChars
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

---------------------------------------- utils
local TextFirstCharMask = format("^[^%s]", IdentFirstChars)
local TextOtherCharMask = format("[^%s]", IdentOtherChars)

function unit.NameToIdent (name) --> (string)
  return name:gsub(TextOtherCharMask, "_")
             :gsub(TextFirstCharMask, "_%1")
end ----

--------------------------------------------------------------------------------
return unit
--------------------------------------------------------------------------------
