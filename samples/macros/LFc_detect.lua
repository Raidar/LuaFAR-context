--[[ LF context check macros ]]--

----------------------------------------
--[[ description:
  -- Macros for LF context check.
  -- Макросы для проверки LF context.
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
local dbg = require "context.utils.useDebugs"
local logShow = dbg.Show
--]]

--------------------------------------------------------------------------------
--local unit = {}

local dbgs

local function doShow (...)
  dbgs = dbgs or require "context.utils.useDebugs"
  return dbgs.Show(...)
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
