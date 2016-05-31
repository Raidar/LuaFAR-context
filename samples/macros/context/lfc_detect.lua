--[[ LuaFAR context check macros ]]--

----------------------------------------
--[[ description:
  -- Macros for 'LuaFAR context' check.
  -- Макросы для проверки 'LuaFAR context'.
--]]
----------------------------------------
--[[ uses:
  nil.
  -- group: LF context.
--]]
--------------------------------------------------------------------------------

----------------------------------------
local context, ctxdata = context, ctxdata

----------------------------------------
--[[
local debugs = require "context.utils.useDebugs"
local logShow = debugs.Show
--]]

--------------------------------------------------------------------------------
--local unit = {}

local debugs

local function doShow (...)
  debugs = debugs or require "context.utils.useDebugs"
  return debugs.Show(...)
end -- doShow

----------------------------------------
local Macro = Macro or function () end

---------------------------------------- check
local detArea = context.detect.area
local curFileType = detArea.current

Macro {
  area = "Shell",
  key = "RCtrlD",
  flags = "EmptyCommandLine",
  description = "LFc: detect type",
  action = function ()
    local f = { matchcase = false, forceline = true, }
    --local f = { matchcase = true, }
    local info = { curFileType(f), }

    if #info > 0 then
      doShow(info, "detType", "d2 _")
    else
      doShow("No types to detect\n\n'LuaFAR context' pack is required\n", "detType")
    end
  end, ---
} ---
--------------------------------------------------------------------------------
