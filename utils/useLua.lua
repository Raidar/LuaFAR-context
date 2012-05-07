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
--local logMsg = (require "Rh_Scripts.Utils.Logging").Message

--------------------------------------------------------------------------------
local unit = {}

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

--------------------------------------------------------------------------------
context.lua = unit -- 'lua' table in context
--------------------------------------------------------------------------------
