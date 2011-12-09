-- FarKey module

----------------------------------------
--[[ description:
  -- FAR3 key handling compability script for temporary use.
  -- Скрипт совместимости обработки клавиш с FAR3 для временного использования.
--]]
--------------------------------------------------------------------------------
local _G = _G

local keys  = require "Rh_Scripts.Utils.keyTypes"
--local keyUt = require "Rh_Scripts.Utils.keyUtils"

----------------------------------------
local bit = bit64
local band, bor = bit.band, bit.bor
local bnot, bxor = bit.bnot, bit.bxor
local bshl, bshr = bit.lshift, bit.rshift

----------------------------------------
local far = far

local F = far.GetFlags()

----------------------------------------
local context = context
local utils = context.utils

local hex = context.number.hex -- for far.Message
local tfind = context.tables.find

--------------------------------------------------------------------------------
local unit = {}

local function ismod (mod, flag) --> (bool)
  return band(mod, flag) ~= 0
end

-- Проверка значения v в [a; b].
local function inseg (v, a, b) --> (bool)
  return v >= a and v <= b
end

local fmods = keys.FKEY_Mods
local vksts = keys.VKEY_CtrlState

local FarNameToKey = far.FarNameToKey
local FarKeyToName = far.FarKeyToName

local function LocNameToLatKey (KeyStr) --> (number)
  local Key, _ = FarNameToKey("Ctrl"..KeyStr)
  if Key ~= nil then
    Key = band(Key, keys.FKEY_KeyMask)
  end
  return Key
end --

local function FarModToKeyState (FarMod) --> (table)
  local KeyState = 0
  if ismod(FarMod, fmods.CTRL) then
    KeyState = bor(KeyState, vksts.LEFT_CTRL_PRESSED)
  end
  if ismod(FarMod, fmods.ALT) then
    KeyState = bor(KeyState, vksts.LEFT_ALT_PRESSED)
  end
  if ismod(FarMod, fmods.SHIFT) then
    KeyState = bor(KeyState, vksts.SHIFT_PRESSED)
  end
  if ismod(FarMod, fmods.RCTRL) then
    KeyState = bor(KeyState, vksts.RIGHT_CTRL_PRESSED)
  end
  if ismod(FarMod, fmods.RALT) then
    KeyState = bor(KeyState, vksts.RIGHT_ALT_PRESSED)
  end
  if ismod(FarMod, fmods.RSHIFT) then
    KeyState = bor(KeyState, vksts.SHIFT_PRESSED) -- ?
  end
  if ismod(FarMod, fmods.ALTDIGIT) then
    KeyState = bor(KeyState, vksts.LEFT_CTRL_PRESSED)
  end

  return KeyState
end -- FarModToKeyState

local function isShift (FarMod) --> (bool)
  return ismod(FarMod, fmods.SHIFT) or ismod(FarMod, fmods.RSHIFT)
end --

local FKEY_Base = keys.FKEY_Base
local FKEY_to_VKEY = keys.FKEY_to_VKEY

local function FarKeyToVir (key, state, name) --> (Key, State, Name, Scan)
  --far.Message(hex(key), hex(state))
  local scan
  if     inseg(key, 0x41, 0x5A) and name:find("%u") then
    state = bor(state, vksts.SHIFT_PRESSED)
  elseif inseg(key, 0x61, 0x7A) and name:find("%l") then
    key, name = key - 0x20, name:upper()
  else
    if inseg(key, FKEY_Base.KEY_FKEY_BEGIN, FKEY_Base.KEY_END_FKEY) then
      --far.Message(hex(key), hex(FKEY_Base.KEY_FKEY_BEGIN))
      key = key - FKEY_Base.EXTENDED_KEY_BASE
      --if inseg(key, keys.VKEY_Keys.PRIOR, keys.VKEY_Keys.HELP) then
      --  state = bor(state, vksts.ENHANCED_KEY)
      --end
    elseif inseg(key, FKEY_Base.KEY_VK_0xFF_BEGIN, FKEY_Base.KEY_VK_0xFF_END) then
      --far.Message(hex(key), hex(FKEY_Base.KEY_VK_0xFF_BEGIN))
      key, scan = 0xFF, key - FKEY_Base.KEY_VK_0xFF_BEGIN
    else
      -- Символ с Shift.
      local aKey = keys.AKEY_Shifts[key]
      if aKey then
        --far.Message(hex(key), hex(aKey))
        key, state = aKey, bor(state, vksts.SHIFT_PRESSED)
      end
      key = FKEY_to_VKEY[key] or key
    end
    -- Корректировка названия
    --[[ Не нужно, т.к. требуется символ, а не название клавиши!
    name = name:upper()
    name = keys.KSYM_VKeys[name] or tfind(keys.SKEY_Diffs, name) or name
    --]]
  end
  if name:len() > 1 then name = "" end

  --far.Message(hex(key), hex(state))
  return key, state, name, scan or keys.VKEY_ScanCodes[key] or 0x00
end -- FarKeyToVir

-- Разделение FarKey на компоненты для InputRecord.
function unit.FarKeyToRecFields (FarKey) --> (key, state, char)
  local Fkey = band(FarKey, keys.FKEY_KeyMask)
  local Fmod = band(FarKey, keys.FKEY_ModMask)

  local KeyState = FarModToKeyState(Fmod) -- Управляющее состояние
  local KeyName = FarKeyToName(Fkey) -- Локализованное имя

  if KeyName == nil then return nil, KeyState, nil end
  if not inseg(Fkey, FKEY_Base.KEY_CHAR_EXT, FKEY_Base.KEY_CHAR_END) then
    --far.Message(hex(Fkey), KeyName)
    return FarKeyToVir(Fkey, KeyState, KeyName)
  end

  -- Учёт локализации
  local LatKey, KeyChar
  -- Без модификаторов или только (L|R)Shift:
  if Fmod == 0 or isShift(Fmod) then
    --far.Message(KeyName, "KeyName")
    LatKey = LocNameToLatKey(KeyName)
    if LatKey == -1 then -- ??
      far.Message(KeyName, "-1")
      return nil, KeyState, nil
    end

    KeyChar = LatKey and FarKeyToName(LatKey)
    if KeyChar and KeyChar ~= KeyName and KeyName:find("%l") then
      KeyChar = KeyChar:lower()
      LatKey  = FarNameToKey(KeyChar)
    end
    --far.Message(KeyChar, KeyName)

    -- Особый случай для неудачных преобразований:
    -- Пример: Юникодные символы.
    if KeyChar and KeyChar:lower() == KeyName then
      --far.Message(KeyChar.." <-> "..KeyName, "Special")
      LatKey = LocNameToLatKey(KeyName:upper())
      if LatKey ~= -1 then
        LatKey = keys.AKEY_Shifts[LatKey] or LatKey
      end
    end
    if LatKey == -1 then return nil, KeyState, nil end -- ??
    KeyChar = LatKey and FarKeyToName(LatKey)
  end

  return FarKeyToVir(LatKey or Fkey, KeyState, KeyChar or KeyName)
end -- FarKeyToRecFields

----------------------------------------
local FarKeyToRecFields = unit.FarKeyToRecFields

-- INPUT_RECORD (build 1816, 1859):
function unit.FarKeyToInputRecord (FarKey) --> (InputRecord)
  -- Уже InputRecord -- для FAR3
  if type(FarKey) == 'table' then return FarKey end

  local Vkey, Vstate, Vchar, Vscan = FarKeyToRecFields(FarKey)
  return { -- InputRecord
    EventType         = F.KEY_EVENT,
    bKeyDown          = true,
    wRepeatCount      = 1,
    wVirtualKeyCode   = Vkey or 0x00,
    wVirtualScanCode  = Vscan or 0x00,
    --AsciiChar         = "",
    UnicodeChar       = Vchar or "",
    dwControlKeyState = Vstate or 0x00,
  } ---
end ---- FarKeyToInputRecord

-- TODO: INPUT_RECORD (build 2103):

--[[ Внимание: неправильно обрабатываемые комбинации:
  All:
  - NumPad = Enhanced.
  - NumPad w/ NumLock = digits.
  - Не ловится: @+Print Screen, CapsLock ScrollLock, NumLock.
  - Не различаются: LCtrl и RCtrl, LAlt и RAlt в комбинациях с клавишами.
  Rus:
  - / = OEM_PERIOD, Sh+/ = OEM_COMMA.
  - Sh+2 = Sh+OEM_7, Sh+4 = OEM_1, Sh+6 = Sh+OEM_1, Sh+7 = Sh+OEM_2.
--]]

--------------------------------------------------------------------------------
return unit
--------------------------------------------------------------------------------
