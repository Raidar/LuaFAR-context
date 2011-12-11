-- FarKey module

----------------------------------------
--[[ description:
  -- FAR3 key handling compability script for temporary use.
  -- Скрипт совместимости обработки клавиш с FAR3 для временного использования.
--]]
--------------------------------------------------------------------------------
local _G = _G

-- INPUT_RECORD (build 2103): -- TODO: 2104

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
local tconcat, tfind = table.concat, context.tables.find

local far23 = context.use.far23

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

local FarNameToKey = far23.FarNameToKey
local FarKeyToName = far23.FarKeyToName

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

  return KeyState
end -- FarModToKeyState

local function isShift (FarMod) --> (bool)
  return ismod(FarMod, fmods.SHIFT) or ismod(FarMod, fmods.RSHIFT)
end --

local FKEY_Base = keys.FKEY_Base
local FKEY_to_VKEY = keys.FKEY_to_VKEY

local VKey_Chars = {
  --Back      = "BS",
  --Tab       = "Tab",

  --Return    = "Enter",

  Space     = " ",

  Multiply  = "*",
  Add       = "+",
  Subtract  = "-",
  Decimal   = ".",
  Divide    = "/",
} ---

local function FarKeyToVir (key, state, name, loc) --> (Key, State, Name, Scan)
  --far.Message(hex(key), hex(state))
  local scan
  if     state == 0x00 and inseg(key, 0x41, 0x5A) and name:find("%u") then
    state = bor(state, vksts.SHIFT_PRESSED)
  elseif state == 0x00 and inseg(key, 0x61, 0x7A) and name:find("%l") then
    key = key - 0x20
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
  --far.Message(hex(key).."\n"..hex(state), name)
  if loc and loc:len() > 1 then loc = nil end
  if name:len() > 1 then name = VKey_Chars[name] or "" end

  --far.Message(hex(key), hex(state))
  return key, state, loc or name, scan or keys.VKEY_ScanCodes[key] or 0x00
end -- FarKeyToVir

-- Разделение FarKey на компоненты для InputRecord.
function unit.FarKeyToRecFields (FarKey) --> (key, state, char)
  local FKey = band(FarKey, keys.FKEY_KeyMask)
  local FMod = band(FarKey, keys.FKEY_ModMask)

  local KeyState = FarModToKeyState(FMod) -- Управляющее состояние
  local KeyName = FarKeyToName(FKey) -- Локализованное имя

  if KeyName == nil then return nil, KeyState, nil end
  if not inseg(FKey, FKEY_Base.KEY_CHAR_EXT, FKEY_Base.KEY_CHAR_END) then
    --far.Message(hex(FKey).."\n"..hex(KeyState), KeyName)
    return FarKeyToVir(FKey, KeyState, KeyName)
  end
  --far.Message(hex(FKey).."\n"..hex(KeyState), KeyName)

  -- Учёт локализации
  local LatKey, LatChar
  -- Без модификаторов или только Shift:
  if FMod == 0 or isShift(FMod) then
    --far.Message(KeyName, "KeyName")
    LatKey = LocNameToLatKey(KeyName)
    if LatKey == -1 then -- ??
      far.Message(KeyName, "-1")
      return nil, KeyState, nil
    end

    LatChar = LatKey and FarKeyToName(LatKey)
    if LatChar and LatChar ~= KeyName and KeyName:find("%l") then
      LatChar = LatChar:lower()
      LatKey  = FarNameToKey(LatChar)
    end
    --far.Message(LatChar, KeyName)

    -- Особый случай для неудачных преобразований:
    -- Пример: Юникодные символы.
    if LatChar and LatChar:lower() == KeyName then
      --far.Message(LatChar.." <-> "..KeyName, "Special")
      LatKey = LocNameToLatKey(KeyName:upper())
      if LatKey ~= -1 then
        LatKey = keys.AKEY_Shifts[LatKey] or LatKey
      end
    end
    if LatKey == -1 then return nil, KeyState, nil end -- ??
    LatChar = LatKey and FarKeyToName(LatKey)
  end

  return FarKeyToVir(LatKey or FKey, KeyState, LatChar or KeyName, KeyName)
end -- FarKeyToRecFields

---------------------------------------- InputRecord
do
  local FarKeyToRecFields = unit.FarKeyToRecFields

-- INPUT_RECORD (build 1816, 1859):
function unit.FarKeyToInputRecord (FarKey) --> (InputRecord)
  -- Уже InputRecord -- для FAR3
  if type(FarKey) == 'table' then return FarKey end

  local VKey, VState, VChar, VScan = FarKeyToRecFields(FarKey)
  return { -- InputRecord
    EventType       = F.KEY_EVENT,
    KeyDown         = true,
    RepeatCount     = 1,
    VirtualKeyCode  = VKey or 0x00,
    VirtualScanCode = VScan or 0x00,
    UnicodeChar     = VChar or "",
    ControlKeyState = VState or 0x00,
  } ---
end ---- FarKeyToInputRecord

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
end -- do

do
  local VKeyToChar, CharToVKey = string.char, string.byte

local function KeyStateToName (KeyState)
  local t = {}

  if ismod(KeyState, vksts.RIGHT_ALT_PRESSED)   then t[#t+1] = "RAlt"   end
  if ismod(KeyState, vksts.LEFT_ALT_PRESSED)    then t[#t+1] = "Alt"    end
  if ismod(KeyState, vksts.RIGHT_CTRL_PRESSED)  then t[#t+1] = "RCtrl"  end
  if ismod(KeyState, vksts.LEFT_CTRL_PRESSED)   then t[#t+1] = "Ctrl"   end
  if ismod(KeyState, vksts.SHIFT_PRESSED)       then t[#t+1] = "Shift"  end

  return tconcat(t)
end --function KeyStateToName

local farMatch = far.match

local function NameToKeyState (KeyName) --> (number)
  local KeyState = 0

  local mod, c, a, s, key =
        farMatch(KeyName, "((R?Ctrl)?(R?Alt)?(Shift)?)(.*)", 1)
  if not mod or mod == "" then return KeyState, key or "" end

  if c and c ~= "" then
    if c == 'RCtrl' then
      KeyState = bor(KeyState, vksts.RIGHT_CTRL_PRESSED)
    else
      KeyState = bor(KeyState, vksts.LEFT_CTRL_PRESSED)
    end
  end
  if a and a ~= "" then
    if c == 'RAlt' then
      KeyState = bor(KeyState, vksts.RIGHT_ALT_PRESSED)
    else
      KeyState = bor(KeyState, vksts.LEFT_ALT_PRESSED)
    end
  end
  if s and s ~= "" then -- 'Shift'
    KeyState = bor(KeyState, vksts.SHIFT_PRESSED)
  end

  return KeyState, key or ""
end -- NameToKeyState

  local VKeys = keys.VKEY_Keys

local Key_Names = {
  CANCEL    = "Break",
  BACK      = "BS",
  TAB       = "Tab",

  CLEAR     = "Clear",
  RETURN    = "Enter",

  PAUSE     = "Pause",
  CAPITAL   = "CapsLock",

  ESCAPE    = "Esc",
  SPACE     = "Space",

  PRIOR     = "PgUp",
  NEXT      = "PgDn",
  END       = "End",
  HOME      = "Home",
  LEFT      = "Left",
  UP        = "Up",
  RIGHT     = "Right",
  DOWN      = "Down",

  SNAPSHOT  = "PrntScrn",
  INSERT    = "Ins",
  DELETE    = "Del",

  LWIN      = "LWin",
  RWIN      = "RWin",
  APPS      = "Apps",
  SLEEP     = "StandBy",

  NUMPAD0   = "Num0",
  NUMPAD1   = "Num1",
  NUMPAD2   = "Num2",
  NUMPAD3   = "Num3",
  NUMPAD4   = "Num4",
  NUMPAD5   = "Num5",
  NUMPAD6   = "Num6",
  NUMPAD7   = "Num7",
  NUMPAD8   = "Num8",
  NUMPAD9   = "Num9",

  MULTIPLY  = "Multiply",
  ADD       = "Add",
  SEPARATOR = "Separator", -- ??
  SUBTRACT  = "Subtract",
  DECIMAL   = "Decimal",
  DIVIDE    = "Divide",
  NUMENTER  = "NumEnter", -- ??

  -- F1 -- F24 -- no change

  NUMLOCK   = "NumLock",
  SCROLL    = "ScrollLock",

  BROWSER_BACK      = "BrowserBack",
  BROWSER_FORWARD   = "BrowserForward",
  BROWSER_REFRESH   = "BrowserRefresh",
  BROWSER_STOP      = "BrowserStop",
  BROWSER_SEARCH    = "BrowserSearch",
  BROWSER_FAVORITES = "BrowserFavorites",
  BROWSER_HOME      = "BrowserHome",
  VOLUME_MUTE       = "VolumeMute",
  VOLUME_DOWN       = "VolumeDown",
  VOLUME_UP         = "VolumeUp",
  MEDIA_NEXT_TRACK  = "MediaNextTrack",
  MEDIA_PREV_TRACK  = "MediaPrevTrack",
  MEDIA_STOP        = "MediaStop",
  MEDIA_PLAY_PAUSE  = "MediaPlayPause",
  LAUNCH_MAIL       = "LaunchMail",
  LAUNCH_MEDIA_SELECT = "LaunchMediaSelect",
  LAUNCH_APP1       = "LaunchApp1",
  LAUNCH_APP2       = "LaunchApp2",

  OEM_1         = ":",      -- ";:"
  OEM_PLUS      = "=",      -- "+="
  OEM_COMMA     = ",",      -- ",<"
  OEM_MINUS     = "-",      -- "-_"
  OEM_PERIOD    = ".",      -- ".>"
  OEM_2         = "/",      -- "/?"
  OEM_3         = "`",      -- "`~"
  OEM_4         = "[",      -- "[{"
  OEM_5         = "\\",     -- "\\|"
  OEM_6         = "]",      -- "]}"
  OEM_7         = "\"",     -- "'"..'"'
  --OEM_8         = "",       -- ""
} ---
--unit.Key_Names = Key_Names

function unit.FarInputRecordToName (Rec) --> (string)
  local VKey, SKey = Rec.VirtualKeyCode
  if inseg(VKey, 0x30, 0x39) or inseg(VKey, 0x41, 0x5A) then
    SKey = string.char(VKey)
  end
  if not SKey then
    SKey = tfind(VKeys, VKey) or ""
    SKey = Key_Names[SKey] or SKey
  end

  local VMod, SMod = Rec.ControlKeyState, ""
  if VMod ~= 0 then
    SMod = KeyStateToName(VMod) or ""
  end

  return SMod..SKey
end ---- FarInputRecordToName

function unit.FarNameToInputRecord (Name) --> (table)
  local VState, VName = NameToKeyState(Name)
  VName = tfind(Key_Names, VName) or VName
  local VKey = VKeys[VName] or 0x00

  return {
    EventType       = F.KEY_EVENT,
    KeyDown         = true,
    RepeatCount     = 1,
    VirtualKeyCode  = VKey,
    VirtualScanCode = keys.VKEY_ScanCodes[VKey] or 0x00,
    UnicodeChar     = "", -- TODO
    ControlKeyState = VState,
  }
end ---- FarNameToInputRecord

local farMatch = far.match

-- Преобразование BreakKeys для работы с меню в FAR2.
function unit.MenuBreakKeysToOld (BreakKeys) --|> (BreakKeys)
  if type(BreakKeys) ~= 'table' then return BreakKeys end

  for k, b in ipairs(BreakKeys) do
    local m, s = farMatch(b.BreakKey,
                          "((?:R?Ctrl)?(?:R?Alt)?(?:Shift)?)(.*)", 1)
    local k = tfind(Key_Names, s)
    if k then b.BreakKey = m..k end
  end

  return BreakKeys
end ---- MenuBreakKeysToOld

end -- do

--------------------------------------------------------------------------------
return unit
--------------------------------------------------------------------------------
