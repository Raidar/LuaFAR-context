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
if context.use.LFVer >= 3 then
local history = require "far2.history"

context.use.newHistory = history.newfile -- history creating function

else -- FAR23
local history = require "history"

context.use.newHistory = history.new -- history creating function
end
--------------------------------------------------------------------------------
context.use.history = history -- 'history' table in context.use
--------------------------------------------------------------------------------
