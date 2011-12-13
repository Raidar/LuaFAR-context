--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- FAR3 compability script for temporary use.
  -- Скрипт совместимости с FAR3 для временного использования.
--]]
----------------------------------------
--[[ uses:
  LuaFAR,
  LF context.
  -- group: temp.
  -- areas: any.
--]]
--------------------------------------------------------------------------------
local _G = _G

----------------------------------------
local context = context

----------------------------------------
local f3_key --= require "context.utils.far3_key"

--------------------------------------------------------------------------------
do
  --local f3_key = require "context.utils.far3_keys"

-- DN_INPUT/DN_CONTROLINPUT: Param2 --> INPUT_RECORD
-- WARN: Call far.ParseInput(param2) before param2 using in InputEvent.
function far.ParseInput (Input) --> (VirKey, FarKey)
  f3_key = f3_key or require "context.utils.far3_key" -- Lazy require

  if type(Input) == 'table' then
    if Input.dwButtonState then
      Input.EventType = F.MOUSE_EVENT
      return
    end

    return
    --return Input, far23.FarInputRecordToKey(Input) -- Exclude FarKey

  else -- if type(Input) == 'number' then
    return f3_key.FarKeyToInputRecord(Input) --, Input -- Exclude FarKey
  end
end ---- ParseInput

  local keyUt --= require "Rh_Scripts.Utils.keyUtils"
  local VKEY_Keys --= keyUt.VKEY_Keys

-- WARN: Call far.RepairInput(Input) before Input using in ProcessInput.
function far.RepairInput (Input) --> (Input)

  if keyUt == nil then
    keyUt = require "Rh_Scripts.Utils.keyUtils"
    VKEY_Keys = keyUt.VKEY_Keys
  end

  if Input.wVirtualKeyCode then
    if EventType == F.KEY_EVENT then
      Input.KeyDown,     Input.bKeyDown     = Input.bKeyDown, nil
      Input.RepeatCount, Input.wRepeatCount = Input.wRepeatCount, nil
      Input.VirtualScanCode, Input.wVirtualScanCode  = Input.wVirtualScanCode, nil
      Input.ControlKeyState, Input.dwControlKeyState = Input.dwControlKeyState, nil

      Input.VirtualKeyCode = VKEY_Keys[Input.wVirtualKeyCode] or 0x00
      Input.wVirtualKeyCode = nil

    elseif EventType == F.MOUSE_EVENT then
      Input.MousePositionX, Input.dwMousePositionX = Input.dwMousePositionX, nil
      Input.MousePositionY, Input.dwMousePositionY = Input.dwMousePositionY, nil
      Input.ButtonState, Input.dwButtonState         = Input.dwButtonState, nil
      Input.EventFlags, Input.dwEventFlags           = Input.dwEventFlags, nil
      Input.ControlKeyState, Input.dwControlKeyState = Input.dwControlKeyState, nil

    elseif EventType == F.WINDOW_BUFFER_SIZE_EVENT then
      Input.SizeX, Input.dwSizeX = Input.dwSizeX, nil
      Input.SizeY, Input.dwSizeY = Input.dwSizeY, nil

    elseif EventType == F.MENU_EVENT then
      Input.CommandId, Input.dwCommandId = Input.dwCommandId, nil

    elseif EventType == F.FOCUS_EVENT then
      Input.SetFocus, Input.bSetFocus = Input.bSetFocus, nil
    end
  end

  Input.Name = far.InputRecordToName(Input)
  return Input
end ---- RepairInput

end -- do
--------------------------------------------------------------------------------

----------------------------------------
if context.use.LFVer == 3 then return end

-- Check applying
if context.use.AsFAR3spc then return end

context.use.AsFAR3spc = true

----------------------------------------
local far23 = {} -- FAR23
context.use.far23 = far23

----------------------------------------
local far = far

far23.FarKeyToName = far.FarKeyToName
far23.FarNameToKey = far.FarNameToKey
far23.FarInputRecordToKey = far.FarInputRecordToKey

----------------------------------------
--local logMsg = (require "Rh_Scripts.Utils.Logging").Message

--------------------------------------------------------------------------------
-- Пространства, выделенные из far.

---------------------------------------- win (build ????)
if not rawget(_G, 'win') then
  win = {}

  local far_to_win = {
    wcscmp = true,
    CompareString = true,
    OemToUtf8 = true,
    Utf8ToOem = true,
    Utf16ToUtf8 = true,
    Utf8ToUtf16 = true,
    MultiByteToWideChar = true,

    GetEnv = true,
    SetEnv = true,

    Uuid = true, -- FAR3
    ShellExecute = true,

    CopyFile = true,
    MoveFile = true,
    RenameFile = true,
    DeleteFile = true,
    CreateDir = true,
    RemoveDir = true,
    SearchPath = true,

    GetDriveType = true,
    GetFileInfo = true,
    GetLogicalDriveStrings = true,
    
    GetACP = true,
    GetOEMCP = true,
    GetCPInfo = true,
    EnumSystemCodePages = true,

    ExtractKey = true,
    GetVirtualKeys = true,
    GetConsoleScreenBufferInfo = true,
    
    GetSystemTime = true,
    FileTimeToSystemTime = true,
    SystemTimeToFileTime = true,
    GetTimeZoneInformation = true,
  } --- far_to_win

  -- Перенос ряда функций из far в win.
  for k, _ in pairs(far_to_win) do
    if not win[k] and far[k] then
      win[k], far[k] = far[k], nil
    end
  end
  far.Uuid = win.Uuid -- TEMP: Совместимость со встроенными скриптами

end -- if

---------------------------------------- export (build ????)
if not rawget(_G, 'export') then
  export = far -- TEMP: Только для упрощения!
end
--------------------------------------------------------------------------------
