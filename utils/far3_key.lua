-- FarKey module

----------------------------------------
--[[ description:
  -- FAR3 key handling compability script for temporary use.
  -- Скрипт совместимости обработки клавиш с FAR3 для временного использования.
--]]
--------------------------------------------------------------------------------
local _G = _G

local keys  = require "Rh_Scripts.Utils.keyTypes"
local keyUt = require "Rh_Scripts.Utils.keyUtils"

----------------------------------------
local far = far

local F = far.GetFlags()

--------------------------------------------------------------------------------
local unit = {}

-- INPUT_RECORD (build 1816, 1859):
function unit.FarKeyToInputRecord (FarKey) --> (InputRecord)
  local Fmod, Fkey = keyUt.ModFKey(FarKey)
  local VirKey = keyUt.FKeyToVKey(FarKey)
  local Vmod, Vkey = keyUt.ModVKey(VirKey)

  local Input = {
    EventType = F.KEY_EVENT,
    bKeyDown = true,
    wRepeatCount = 1,
    wVirtualKeyCode = Vkey,
    wVirtualScanCode = keys.VKEY_ScanCodes[Vkey] or 0x00,
    --AsciiChar = ,
    UnicodeChar = keyUt.isFKeyChar(Fkey) and
                  keyUt.FKeyToChar(Fkey) or "",
    dwControlKeyState = keyUt.VModToCState(Vmod),
  } ---
  return Input
end ----

--------------------------------------------------------------------------------
return unit
--------------------------------------------------------------------------------
