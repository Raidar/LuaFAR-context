-- FarKey module

----------------------------------------
--[[ description:
  -- FAR3 key handling compability script for temporary use.
  -- Скрипт совместимости обработки клавиш с FAR3 для временного использования.
--]]
--------------------------------------------------------------------------------
local _G = _G

local pairs = pairs

-- INPUT_RECORD (build 2103—2104):

local keyUt = require "Rh_Scripts.Utils.keyUtils"

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

---------------------------------------- VK_
local VK_   = keyUt.VKEY_Keys
local VKCS_ = keyUt.VKEY_State

---------------------------------------- FK_ key bases
-- Основные константы KEY_ клавиш.
local FKEY_ = {
  BASE = 0x00000,       -- BASE
  CHR       = 0x0020,
  CHR_EXT   = 0x0080,
  CHR_END   = 0xFFFF,
  EXT     = 0x10000,
  INT     = 0x20000,
  INT_2   = 0x30000,
  FK_END  = 0x1FFFF,
  VK_0xFF     = 0x0100,
  VK_0xFF_LEN = 0x00FF,
  OP     = 0x100,
  OP_LEN = 0x0FF,
  SK_END = 0x3FFFF,
  END  = 0x3FFFF,       -- BASE END

  MACRO     = 0x80000,  -- MACRO
  MACRO_O   = 0x00000, -- - 0x003FF
  MACRO_C   = 0x00400, -- - 0x007FF
  MACRO_V   = 0x00800, -- - 0x00BFF
  MACRO_F   = 0x00C00, -- - 0x...
  MACRO_U   = 0x08000, -- - 0x...
  MACRO_END = 0xFFFFF,  -- MACRO END

  -- Маски клавиш и модификаторов.
  KeyMask   = 0x0003FFFF,
  ModMask   = 0xFFF00000,
} --- FKEY_

-- Базисы значений KEY_ клавиш.
local FKB_ = {
  -- BASE
  KEY_CHAR_BEGIN  = FKEY_.CHR,
  KEY_CHAR_EXT    = FKEY_.CHR_EXT,
  KEY_CHAR_END    = FKEY_.CHR_END,
  EXTENDED_KEY_BASE = FKEY_.EXT,
  KEY_FKEY_BEGIN  = FKEY_.EXT,
  KEY_END_FKEY    = FKEY_.FK_END,
  KEY_VK_0xFF_BEGIN = FKEY_.EXT + FKEY_.VK_0xFF,
  KEY_VK_0xFF_END   = FKEY_.EXT + FKEY_.VK_0xFF + FKEY_.VK_0xFF_LEN,
  INTERNAL_KEY_BASE   = FKEY_.INT,
  INTERNAL_KEY_BASE_2 = FKEY_.INT_2,
  KEY_OP_BASE       = FKEY_.INT_2 + FKEY_.OP,
  KEY_OP_ENDBASE    = FKEY_.INT_2 + FKEY_.OP + FKEY_.OP_LEN,
  KEY_END_SKEY    = FKEY_.SK_END,
  KEY_LAST_BASE   = FKEY_.END,
  -- MACRO
  KEY_MACRO_BASE    = FKEY_.MACRO,
  KEY_MACRO_OP_BASE = FKEY_.MACRO + FKEY_.MACRO_O,
  KEY_MACRO_C_BASE  = FKEY_.MACRO + FKEY_.MACRO_C,
  KEY_MACRO_V_BASE  = FKEY_.MACRO + FKEY_.MACRO_V,
  KEY_MACRO_F_BASE  = FKEY_.MACRO + FKEY_.MACRO_F,
  KEY_MACRO_U_BASE  = FKEY_.MACRO + FKEY_.MACRO_U,
  KEY_MACRO_ENDBASE = FKEY_.MACRO_END,
} -- FKB_ / FKEY_Base

-- Модификаторы KEY_ клавиш.
local FKM_ = {
  CTRL      = 0x01000000,
  ALT       = 0x02000000,
  SHIFT     = 0x04000000,

  RCTRL     = 0x10000000,
  RALT      = 0x20000000,
  RSHIFT    = 0x80000000,

  ALTDIGIT  = 0x40000000,
  --M_OEM     = 0x00100000,
  --M_SPEC    = 0x00200000,
} -- FKM_ / FKEY_Mods

---------------------------------------- FK_ codes/names
local EXTENDED_KEY_BASE   = FKB_.EXTENDED_KEY_BASE
local INTERNAL_KEY_BASE   = FKB_.INTERNAL_KEY_BASE
local INTERNAL_KEY_BASE_2 = FKB_.INTERNAL_KEY_BASE_2
local KEY_OP_BASE         = FKB_.KEY_OP_BASE

-- Код KEY_ клавиш по их названию.
local FK_ = {
  -- KEY_CTRLMASK --
  BRACKET     = 0x5B, -- '['
  BACKBRACKET = 0x5D, -- ']'
  COMMA = 0x2C, -- ','
  QUOTE = 0x22, -- '"'
  DOT   = 0x2E, -- '.'
  SLASH     = 0x2F, -- '/'
  COLON     = 0x3A, -- ':'
  SEMICOLON = 0x3B, -- ';',
  BACKSLASH = 0x5C, -- '\\'
  BS    = 0x08,
  TAB   = 0x09,
  ENTER = 0x0D,
  ESC   = 0x1B,
  SPACE = 0x20,
  -- KEY_MASKF --

  -- KEY_FKEY_BEGIN --
  BREAK = EXTENDED_KEY_BASE + VK_.CANCEL,
  -- Other keys
  PAUSE = EXTENDED_KEY_BASE + VK_.PAUSE,
  CAPSLOCK = EXTENDED_KEY_BASE + VK_.CAPITAL,
  -- Arrow keys
  PGUP  = EXTENDED_KEY_BASE + VK_.PRIOR,
  PGDN  = EXTENDED_KEY_BASE + VK_.NEXT,
  END   = EXTENDED_KEY_BASE + VK_.END,
  HOME  = EXTENDED_KEY_BASE + VK_.HOME,
  LEFT  = EXTENDED_KEY_BASE + VK_.LEFT,
  UP    = EXTENDED_KEY_BASE + VK_.UP,
  RIGHT = EXTENDED_KEY_BASE + VK_.RIGHT,
  DOWN  = EXTENDED_KEY_BASE + VK_.DOWN,
  -- Other keys
  PRNTSCRN = EXTENDED_KEY_BASE + VK_.SNAPSHOT,
  INS   = EXTENDED_KEY_BASE + VK_.INSERT,
  DEL   = EXTENDED_KEY_BASE + VK_.DELETE,
  -- Modifiers
  LWIN  = EXTENDED_KEY_BASE + VK_.LWIN,
  RWIN  = EXTENDED_KEY_BASE + VK_.RWIN,
  APPS  = EXTENDED_KEY_BASE + VK_.APPS,
  -- Other keys
  STANDBY  = EXTENDED_KEY_BASE + VK_.SLEEP,
  -- Numpad keys
  NUMPAD0  = EXTENDED_KEY_BASE + VK_.NUMPAD0,
  NUMPAD1  = EXTENDED_KEY_BASE + VK_.NUMPAD1,
  NUMPAD2  = EXTENDED_KEY_BASE + VK_.NUMPAD2,
  NUMPAD3  = EXTENDED_KEY_BASE + VK_.NUMPAD3,
  NUMPAD4  = EXTENDED_KEY_BASE + VK_.NUMPAD4,
  NUMPAD5  = EXTENDED_KEY_BASE + VK_.NUMPAD5,
  CLEAR    = EXTENDED_KEY_BASE + VK_.NUMPAD5, -- NUMPAD5
  NUMPAD6  = EXTENDED_KEY_BASE + VK_.NUMPAD6,
  NUMPAD7  = EXTENDED_KEY_BASE + VK_.NUMPAD7,
  NUMPAD8  = EXTENDED_KEY_BASE + VK_.NUMPAD8,
  NUMPAD9  = EXTENDED_KEY_BASE + VK_.NUMPAD9,
  MULTIPLY = EXTENDED_KEY_BASE + VK_.MULTIPLY,
  ADD      = EXTENDED_KEY_BASE + VK_.ADD,
  SUBTRACT = EXTENDED_KEY_BASE + VK_.SUBTRACT,
  DECIMAL  = EXTENDED_KEY_BASE + VK_.DECIMAL,
  DIVIDE   = EXTENDED_KEY_BASE + VK_.DIVIDE,
  -- Function keys
  F1  = EXTENDED_KEY_BASE + VK_.F1,
  F2  = EXTENDED_KEY_BASE + VK_.F2,
  F3  = EXTENDED_KEY_BASE + VK_.F3,
  F4  = EXTENDED_KEY_BASE + VK_.F4,
  F5  = EXTENDED_KEY_BASE + VK_.F5,
  F6  = EXTENDED_KEY_BASE + VK_.F6,
  F7  = EXTENDED_KEY_BASE + VK_.F7,
  F8  = EXTENDED_KEY_BASE + VK_.F8,
  F9  = EXTENDED_KEY_BASE + VK_.F9,
  F10 = EXTENDED_KEY_BASE + VK_.F10,
  F11 = EXTENDED_KEY_BASE + VK_.F11,
  F12 = EXTENDED_KEY_BASE + VK_.F12,
  F13 = EXTENDED_KEY_BASE + VK_.F13,
  F14 = EXTENDED_KEY_BASE + VK_.F14,
  F15 = EXTENDED_KEY_BASE + VK_.F15,
  F16 = EXTENDED_KEY_BASE + VK_.F16,
  F17 = EXTENDED_KEY_BASE + VK_.F17,
  F18 = EXTENDED_KEY_BASE + VK_.F18,
  F19 = EXTENDED_KEY_BASE + VK_.F19,
  F20 = EXTENDED_KEY_BASE + VK_.F20,
  F21 = EXTENDED_KEY_BASE + VK_.F21,
  F22 = EXTENDED_KEY_BASE + VK_.F22,
  F23 = EXTENDED_KEY_BASE + VK_.F23,
  F24 = EXTENDED_KEY_BASE + VK_.F24,
  -- Other keys
  NUMLOCK    = EXTENDED_KEY_BASE + VK_.NUMLOCK,
  SCROLLLOCK = EXTENDED_KEY_BASE + VK_.SCROLL,
  -- Multimedia
  BROWSER_BACK      = EXTENDED_KEY_BASE + VK_.BROWSER_BACK,
  BROWSER_FORWARD   = EXTENDED_KEY_BASE + VK_.BROWSER_FORWARD,
  BROWSER_REFRESH   = EXTENDED_KEY_BASE + VK_.BROWSER_REFRESH,
  BROWSER_STOP      = EXTENDED_KEY_BASE + VK_.BROWSER_STOP,
  BROWSER_SEARCH    = EXTENDED_KEY_BASE + VK_.BROWSER_SEARCH,
  BROWSER_FAVORITES = EXTENDED_KEY_BASE + VK_.BROWSER_FAVORITES,
  BROWSER_HOME      = EXTENDED_KEY_BASE + VK_.BROWSER_HOME,
  VOLUME_MUTE       = EXTENDED_KEY_BASE + VK_.VOLUME_MUTE,
  VOLUME_DOWN       = EXTENDED_KEY_BASE + VK_.VOLUME_DOWN,
  VOLUME_UP         = EXTENDED_KEY_BASE + VK_.VOLUME_UP,
  MEDIA_NEXT_TRACK  = EXTENDED_KEY_BASE + VK_.MEDIA_NEXT_TRACK,
  MEDIA_PREV_TRACK  = EXTENDED_KEY_BASE + VK_.MEDIA_PREV_TRACK,
  MEDIA_STOP        = EXTENDED_KEY_BASE + VK_.MEDIA_STOP,
  MEDIA_PLAY_PAUSE  = EXTENDED_KEY_BASE + VK_.MEDIA_PLAY_PAUSE,
  LAUNCH_MAIL       = EXTENDED_KEY_BASE + VK_.LAUNCH_MAIL,
  LAUNCH_MEDIA_SELECT
                    = EXTENDED_KEY_BASE + VK_.LAUNCH_MEDIA_SELECT,
  LAUNCH_APP1       = EXTENDED_KEY_BASE + VK_.LAUNCH_APP1,
  LAUNCH_APP2       = EXTENDED_KEY_BASE + VK_.LAUNCH_APP2,

  -- KEY_VK_0xFF_BEGIN --
  -- KEY_VK_0xFF_END --

  -- KEY_END_FKEY --

  CTRLALTSHIFTPRESS    = INTERNAL_KEY_BASE + 1,
  CTRLALTSHIFTRELEASE  = INTERNAL_KEY_BASE + 2,

  MSWHEEL_UP    = INTERNAL_KEY_BASE + 3,
  MSWHEEL_DOWN  = INTERNAL_KEY_BASE + 4,
  
  --RCTRLALTSHIFTPRESS   = INTERNAL_KEY_BASE + 7,
  --RCTRLALTSHIFTRELEASE = INTERNAL_KEY_BASE + 8,
  NUMDEL    = INTERNAL_KEY_BASE + 0x9,
  NUMENTER  = INTERNAL_KEY_BASE + 0xB,

  MSWHEEL_LEFT  = INTERNAL_KEY_BASE + 0xC,
  MSWHEEL_RIGHT = INTERNAL_KEY_BASE + 0xD,

  MSLCLICK  = INTERNAL_KEY_BASE + 0x0F,
  MSRCLICK  = INTERNAL_KEY_BASE + 0x10,
  MSM1CLICK = INTERNAL_KEY_BASE + 0x11,
  MSM2CLICK = INTERNAL_KEY_BASE + 0x12,
  MSM3CLICK = INTERNAL_KEY_BASE + 0x13,

  NONE = INTERNAL_KEY_BASE_2 + 1,
  IDLE = INTERNAL_KEY_BASE_2 + 2,

  --DRAGCOPY             = INTERNAL_KEY_BASE_2 + 3,
  --DRAGMOVE             = INTERNAL_KEY_BASE_2 + 4,

  KILLFOCUS            = INTERNAL_KEY_BASE_2 + 6,
  GOTFOCUS             = INTERNAL_KEY_BASE_2 + 7,
  CONSOLE_BUFFER_RESIZE= INTERNAL_KEY_BASE_2 + 8,

  -- KEY_OP_BASE --
  --OP_XLAT              = KEY_OP_BASE + 0,
  --OP_DATE              = KEY_OP_BASE + 1,
  --OP_PLAINTEXT         = KEY_OP_BASE + 2,
  --OP_SELWORD           = KEY_OP_BASE + 3,
  -- KEY_OP_ENDBASE --

  -- KEY_END_SKEY --
  -- KEY_LAST_BASE --
} --- FK_ / FKEY_Keys

-- Различие кодов: KEY_ --> VK_
local FKEY_to_VKEY = {
  --[0x000]       = 0x00,         -- NULL
  [FK_.BS]      = VK_.BACK,     -- BS / Back
  [FK_.TAB]     = VK_.TAB,      -- Tab
  [FK_.ENTER]   = VK_.RETURN,   -- Enter / Return
  [FK_.ESC]     = VK_.ESCAPE,   -- Escape / Esc
  [FK_.SPACE]   = VK_.SPACE,    -- Space
  [0x2D]    = VK_.OEM_MINUS,    -- "-_"
  [0x3D]    = VK_.OEM_PLUS,     -- "=+"
  [0x2C]    = VK_.OEM_COMMA,    -- ",<"
  [0x2E]    = VK_.OEM_PERIOD,   -- ".>"
  [0x3B]    = VK_.OEM_1,    -- ";:"
  [0x2F]    = VK_.OEM_2,    -- "/?"
  [0x60]    = VK_.OEM_3,    -- "`~"
  [0x5B]    = VK_.OEM_4,    -- "[{"
  [0x5C]    = VK_.OEM_5,    -- "\\|"
  [0x5D]    = VK_.OEM_6,    -- "]}"
  --[0x22]    = VK_.OEM_7,    -- "'"'"'
  [0x27]    = VK_.OEM_7,    -- "'"'"'
  --[0x??]    = VK_.OEM_102,  -- "<>" / "\\|"
  [FK_.NUMENTER]= VK_.RETURN,   -- NumEnter
  --[FK_.CLEAR]    = VK_.CLEAR,   -- Numpad5 / Clear
  [FK_.NUMDEL]  = VK_.DELETE,   -- NumDel / Decimal
} -- FKEY_to_VKEY

---------------------------------------- VK Chars & Names
-- Различие символов для клавиш с Shift.
local SKEY_Shifts = {
  ['!'] = '1', ['@'] = '2', ['#'] = '3', ['$'] = '4', ['%%'] = '5',
  ['^'] = '6', ['&'] = '7', ['*'] = '8', ['('] = '9', [')']  = '0',
  ['_'] = '-', ['+'] = '=', ['~'] = '`',
  ['{'] = '[', ['}'] = ']', ['|'] = '\\',
  [':'] = ';', ['"'] = "'",
  ['<'] = ',', ['>'] = '.', ['?'] = '/',
} -- SKEY_Shifts

  local charkey = string.byte

-- Различие кодов символов для клавиш с Shift.
local AKEY_Shifts = {}
for k, v in pairs(SKEY_Shifts) do
  AKEY_Shifts[charkey(k)] = charkey(v)
end
--logMsg(AKEY_Shifts, "AKEY_Shifts", "h2")

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
} --- VKey_Chars

local VKey_Names = {
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
} --- VKey_Names

----------------------------------------
local function ismod (mod, flag) --> (bool)
  return band(mod, flag) ~= 0
end

-- Проверка значения v в [a; b].
local function inseg (v, a, b) --> (bool)
  return v >= a and v <= b
end

----------------------------------------
do
  local FarNameToKey = far23.FarNameToKey
  local FarKeyToName = far23.FarKeyToName

local function LocNameToLatKey (KeyStr) --> (number)
  local Key, _ = FarNameToKey("Ctrl"..KeyStr)
  if Key ~= nil then
    Key = band(Key, FKEY_.KeyMask)
  end

  return Key
end --function LocNameToLatKey

local function FarModToKeyState (FarMod) --> (table)
  local KeyState = 0

  if ismod(FarMod, FKM_.CTRL) then
    KeyState = bor(KeyState, VKCS_.LEFT_CTRL_PRESSED)
  end
  if ismod(FarMod, FKM_.ALT) then
    KeyState = bor(KeyState, VKCS_.LEFT_ALT_PRESSED)
  end
  if ismod(FarMod, FKM_.SHIFT) then
    KeyState = bor(KeyState, VKCS_.SHIFT_PRESSED)
  end
  if ismod(FarMod, FKM_.RCTRL) then
    KeyState = bor(KeyState, VKCS_.RIGHT_CTRL_PRESSED)
  end
  if ismod(FarMod, FKM_.RALT) then
    KeyState = bor(KeyState, VKCS_.RIGHT_ALT_PRESSED)
  end
  if ismod(FarMod, FKM_.RSHIFT) then
    KeyState = bor(KeyState, VKCS_.SHIFT_PRESSED) -- ?
  end

  return KeyState
end -- FarModToKeyState

local function isShift (FarMod) --> (bool)
  return ismod(FarMod, FKM_.SHIFT) or ismod(FarMod, FKM_.RSHIFT)
end --

local function FarKeyToVir (key, state, name, loc) --> (Key, State, Name, Scan)
  --far.Message(hex(key), hex(state))
  local scan
  if     state == 0x00 and inseg(key, 0x41, 0x5A) and name:find("%u") then
    state = bor(state, VKCS_.SHIFT_PRESSED)
  elseif state == 0x00 and inseg(key, 0x61, 0x7A) and name:find("%l") then
    key = key - 0x20
  else
    if inseg(key, FKB_.KEY_FKEY_BEGIN, FKB_.KEY_END_FKEY) then
      --far.Message(hex(key), hex(FKB_.KEY_FKEY_BEGIN))
      key = key - FKB_.EXTENDED_KEY_BASE
    elseif inseg(key, FKB_.KEY_VK_0xFF_BEGIN, FKB_.KEY_VK_0xFF_END) then
      --far.Message(hex(key), hex(FKB_.KEY_VK_0xFF_BEGIN))
      key, scan = 0xFF, key - FKB_.KEY_VK_0xFF_BEGIN
    else
      -- Символ с Shift.
      local aKey = AKEY_Shifts[key]
      if aKey then
        --far.Message(hex(key), hex(aKey))
        key, state = aKey, bor(state, VKCS_.SHIFT_PRESSED)
      end
      key = FKEY_to_VKEY[key] or key
    end
  end
  --far.Message(hex(key).."\n"..hex(state), name)
  if loc and loc:len() > 1 then loc = nil end
  if name:len() > 1 then name = VKey_Chars[name] or "" end

  --far.Message(hex(key), hex(state))
  return key, state, loc or name, scan or keyUt.VKEY_ScanCodes[key] or 0x00
end -- FarKeyToVir

-- Разделение FarKey на компоненты для InputRecord.
function unit.FarKeyToRecFields (FarKey) --> (key, state, char)
  local FKey = band(FarKey, FKEY_.KeyMask)
  local FMod = band(FarKey, FKEY_.ModMask)

  local KeyState = FarModToKeyState(FMod) -- Управляющее состояние
  local KeyName = FarKeyToName(FKey) -- Локализованное имя

  if KeyName == nil then return nil, KeyState, nil end
  if not inseg(FKey, FKB_.KEY_CHAR_EXT, FKB_.KEY_CHAR_END) then
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
        LatKey = AKEY_Shifts[LatKey] or LatKey
      end
    end
    if LatKey == -1 then return nil, KeyState, nil end -- ??
    LatChar = LatKey and FarKeyToName(LatKey)
  end

  return FarKeyToVir(LatKey or FKey, KeyState, LatChar or KeyName, KeyName)
end -- FarKeyToRecFields

end -- do
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

local function KeyStateToName (KeyState)
  local t = {}

  if ismod(KeyState, VKCS_.RIGHT_ALT_PRESSED)  then t[#t+1] = "RAlt"  end
  if ismod(KeyState, VKCS_.LEFT_ALT_PRESSED)   then t[#t+1] = "Alt"   end
  if ismod(KeyState, VKCS_.RIGHT_CTRL_PRESSED) then t[#t+1] = "RCtrl" end
  if ismod(KeyState, VKCS_.LEFT_CTRL_PRESSED)  then t[#t+1] = "Ctrl"  end
  if ismod(KeyState, VKCS_.SHIFT_PRESSED)      then t[#t+1] = "Shift" end

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
      KeyState = bor(KeyState, VKCS_.RIGHT_CTRL_PRESSED)
    else
      KeyState = bor(KeyState, VKCS_.LEFT_CTRL_PRESSED)
    end
  end
  if a and a ~= "" then
    if c == 'RAlt' then
      KeyState = bor(KeyState, VKCS_.RIGHT_ALT_PRESSED)
    else
      KeyState = bor(KeyState, VKCS_.LEFT_ALT_PRESSED)
    end
  end
  if s and s ~= "" then -- 'Shift'
    KeyState = bor(KeyState, VKCS_.SHIFT_PRESSED)
  end

  return KeyState, key or ""
end -- NameToKeyState

function unit.InputRecordToName (Rec) --> (string)
  local VKey, SKey = Rec.VirtualKeyCode
  if inseg(VKey, 0x30, 0x39) or inseg(VKey, 0x41, 0x5A) then
    SKey = string.char(VKey)
  end
  if not SKey then
    SKey = tfind(VK_, VKey) or ""
    SKey = VKey_Names[SKey] or SKey
  end

  local VMod, SMod = Rec.ControlKeyState, ""
  if VMod ~= 0 then
    SMod = KeyStateToName(VMod) or ""
  end

  return SMod..SKey
end ---- InputRecordToName

function unit.NameToInputRecord (Name) --> (table)
  local VState, VName = NameToKeyState(Name)
  VName = tfind(VKey_Names, VName) or VName
  local VKey = VK_[VName] or 0x00

  return {
    EventType       = F.KEY_EVENT,
    KeyDown         = true,
    RepeatCount     = 1,
    VirtualKeyCode  = VKey,
    VirtualScanCode = keyUt.VKEY_ScanCodes[VKey] or 0x00,
    UnicodeChar     = "", -- TODO
    ControlKeyState = VState,
  }
end ---- NameToInputRecord

local farMatch = far.match

-- Преобразование BreakKeys для работы с меню в FAR2.
function unit.MenuBreakKeysToOld (BreakKeys) --|> (BreakKeys)
  if type(BreakKeys) ~= 'table' then return BreakKeys end

  for k, b in ipairs(BreakKeys) do
    local m, s = farMatch(b.BreakKey,
                          "((?:R?Ctrl)?(?:R?Alt)?(?:Shift)?)(.*)", 1)
    local k = tfind(VKey_Names, s)
    if k then b.BreakKey = m..k end
  end

  return BreakKeys
end ---- MenuBreakKeysToOld

end -- do

--------------------------------------------------------------------------------
return unit
--------------------------------------------------------------------------------
