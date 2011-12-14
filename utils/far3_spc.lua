--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- LuaFAR3 compability script for temporary use.
  -- Скрипт совместимости с LuaFAR3 для временного использования.
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
local F = far.GetFlags()

--------------------------------------------------------------------------------
do
  local f3_key --= require "context.utils.far3_key"

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

end -- do
do
  local keyUt --= require "Rh_Scripts.Utils.keyUtils"
  local VKEY_Keys --= keyUt.VKEY_Keys

-- WARN: Call far.RepairInput(Input) before Input using in ProcessInput.
function far.RepairInput (Input) --|> (Input)

  if keyUt == nil then
    keyUt = require "Rh_Scripts.Utils.keyUtils"
    VKEY_Keys = keyUt.VKEY_Keys
  end

  if Input.wVirtualKeyCode then
    if Input.EventType == F.KEY_EVENT or
       Input.EventType == F.FARMACRO_KEY_EVENT then
      Input.KeyDown,     Input.bKeyDown     = Input.bKeyDown, nil
      Input.RepeatCount, Input.wRepeatCount = Input.wRepeatCount, nil
      Input.VirtualScanCode, Input.wVirtualScanCode  = Input.wVirtualScanCode, nil
      Input.ControlKeyState, Input.dwControlKeyState = Input.dwControlKeyState, nil

      Input.VirtualKeyCode = VKEY_Keys[Input.wVirtualKeyCode] or 0x00
      Input.wVirtualKeyCode = nil

    elseif Input.EventType == F.MOUSE_EVENT then
      Input.MousePositionX, Input.dwMousePositionX = Input.dwMousePositionX, nil
      Input.MousePositionY, Input.dwMousePositionY = Input.dwMousePositionY, nil
      Input.ButtonState, Input.dwButtonState         = Input.dwButtonState, nil
      Input.EventFlags,  Input.dwEventFlags          = Input.dwEventFlags, nil
      Input.ControlKeyState, Input.dwControlKeyState = Input.dwControlKeyState, nil

    elseif Input.EventType == F.WINDOW_BUFFER_SIZE_EVENT then
      Input.SizeX, Input.dwSizeX = Input.dwSizeX, nil
      Input.SizeY, Input.dwSizeY = Input.dwSizeY, nil

    elseif Input.EventType == F.MENU_EVENT then
      Input.CommandId, Input.dwCommandId = Input.dwCommandId, nil

    elseif Input.EventType == F.FOCUS_EVENT then
      Input.SetFocus, Input.bSetFocus = Input.bSetFocus, nil
    end
  end

  --Input.Name = far.InputRecordToName(Input)
  return Input
end ---- RepairInput

end -- do
--------------------------------------------------------------------------------
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

---------------------------------------- export (build ????)
export = far -- TEMP: Только для упрощения!

---------------------------------------- panel (build ????)
panel = {}

do
  --local t = {}
  local sFarCtrl = "^Ctrl(.+)$"

for k, v in pairs(far) do
  local s = k:match(sFarCtrl)
  if s then
    panel[s] = v
    --t[#t+1] = s
    --far[k] = nil
  end
end
--table.sort(t)
--far.Show(unpack(t))

end -- do

---------------------------------------- editor (build ????)
editor = {}

do
  --local t = {}
  local sFarEditor = "^Editor(.+)$"

for k, v in pairs(far) do
  local s = k:match(sFarEditor)
  if s then
    editor[s] = v
    --t[#t+1] = s
  end
end
--table.sort(t)
--far.Show(unpack(t))

end -- do

---------------------------------------- viewer (build ????)
viewer = {}

do
  --local t = {}
  local sFarViewer = "^Viewer(.+)$"

for k, v in pairs(far) do
  local s = k:match(sFarViewer)
  if s then
    viewer[s] = v
    --t[#t+1] = s
  end
end
--table.sort(t)
--far.Show(unpack(t))

end -- do

---------------------------------------- viewer (build ????)
regex = {}

do
  regex.new     = far.regex
  regex.find    = far.find
  regex.gmatch  = far.gmatch
  regex.gsub    = far.gsub
  regex.match   = far.match
end -- do

--------------------------------------------------------------------------------
