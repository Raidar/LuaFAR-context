--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- History control.
  -- Ведение истории.
--]]
----------------------------------------
--[[ uses:
  LuaFAR,
  far2,
  LF context.
  -- group: Config, Datas.
--]]
--------------------------------------------------------------------------------
local _G = _G

--------------------------------------------------------------------------------
--local unit = {}

---------------------------------------- History
local history = require "far2.history"

context.use.newHistory = history.newfile -- history creating function

--------------------------------------------------------------------------------
context.use.history = history -- 'history' table in context.use
--------------------------------------------------------------------------------
