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
local LFVer = context.use.LFVer
if LFVer ~= 3 then
  far.Flags = far.GetFlags()
end
local F = far.Flags

--------------------------------------------------------------------------------
do
  local keyUt --= require "Rh_Scripts.Utils.keyUtils"
  local VKEY_Keys --= keyUt.VKEY_Keys

-- WARN: Call far.RepairInput(Input) before Input using in ProcessInput.
function far.RepairInput (Input) --|> (Input)

  if LFVer == 3 then
    local c = Input.UnicodeChar
    if type(c) == 'number' then
      Input.UnicodeChar = c ~= 0 and ("").char(c) or ""
    end
    return Input
  end

  if keyUt == nil then
    keyUt = require "Rh_Scripts.Utils.keyUtils"
    VKEY_Keys = keyUt.VKEY_Keys
  end

  if Input.bKeyDown then
    Input.KeyDown, Input.bKeyDown = Input.bKeyDown, nil
  end
  if Input.wRepeatCount then
    Input.RepeatCount, Input.wRepeatCount = Input.wRepeatCount, nil
  end
  if Input.wVirtualScanCode then
    Input.VirtualScanCode, Input.wVirtualScanCode  = Input.wVirtualScanCode, nil
  end
  if Input.dwControlKeyState then
    Input.ControlKeyState, Input.dwControlKeyState = Input.dwControlKeyState, nil
  end

  if Input.wVirtualKeyCode then
    Input.VirtualKeyCode, Input.wVirtualKeyCode = VKEY_Keys[Input.wVirtualKeyCode] or 0x00, nil
  end

  if Input.dwMousePositionX then
    Input.MousePositionX, Input.dwMousePositionX = Input.dwMousePositionX, nil
  end
  if Input.dwMousePositionY then
    Input.MousePositionY, Input.dwMousePositionY = Input.dwMousePositionY, nil
  end
  if Input.dwButtonState then
    Input.ButtonState, Input.dwButtonState = Input.dwButtonState, nil
  end
  if Input.dwEventFlags then
    Input.EventFlags,  Input.dwEventFlags = Input.dwEventFlags, nil
  end
  if Input.dwSizeX then
    Input.SizeX, Input.dwSizeX = Input.dwSizeX, nil
  end
  if Input.dwSizeY then
    Input.SizeY, Input.dwSizeY = Input.dwSizeY, nil
  end
  if Input.dwCommandId then
    Input.CommandId, Input.dwCommandId = Input.dwCommandId, nil
  end
  if Input.bSetFocus then
    Input.SetFocus, Input.bSetFocus = Input.bSetFocus, nil
  end

  local c = Input.UnicodeChar
  if type(c) == 'number' then
    Input.UnicodeChar = c ~= 0 and ("").char(c) or ""
  end

  --Input.Name = far.InputRecordToName(Input)
  return Input
end ---- RepairInput
do
  local f3_key --= require "context.utils.far3_key"

-- DN_INPUT/DN_CONTROLINPUT: Param2 --> INPUT_RECORD
-- WARN: Call far.ParseInput(param2) before param2 using in InputEvent.
function far.ParseInput (Input) --> (VirKey, FarKey)

  if LFVer == 3 then
    local c = Input.UnicodeChar
    if type(c) == 'number' then
      Input.UnicodeChar = c ~= 0 and ("").char(c) or ""
    end
    return Input
  end

  f3_key = f3_key or require "context.utils.far3_key" -- Lazy require

  if type(Input) == 'table' then
    far.RepairInput(Input)
    if Input.ButtonState then
      Input.EventType = F.MOUSE_EVENT
      return
    end

    local c = Input.UnicodeChar
    if type(c) == 'number' then
      Input.UnicodeChar = c ~= 0 and ("").char(c) or ""
    end

    return Input

  else -- if type(Input) == 'number' then
    return f3_key.FarKeyToInputRecord(Input)
  end
end ---- ParseInput

end -- do

end -- do
--------------------------------------------------------------------------------
-- Check applying
if context.use.AsFAR3spc then return end
context.use.AsFAR3spc = true

----------------------------------------
local far23 = {} -- FAR23
context.use.far23 = far23

----------------------------------------
if LFVer == 3 then return end

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
