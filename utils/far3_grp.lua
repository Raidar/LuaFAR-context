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

if context.use.LFVer == 3 then return end

-- Check applying
if context.use.AsFAR3g then return end

context.use.AsFAR3g = true
----------------------------------------

local f3_key --= require "context.utils.far3_key"

----------------------------------------
local far23 = {} -- FAR23
context.use.far23 = far23

----------------------------------------
local far = far

far23.FarInputRecordToKey = far.FarInputRecordToKey

----------------------------------------
--local logMsg = (require "Rh_Scripts.Utils.Logging").Message

--------------------------------------------------------------------------------
-- Таблица системных функций (build ????).
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

-- Таблица экспортируемых функций (build ????).
if not rawget(_G, 'export') then
  export = far -- TEMP: Только для упрощения!
end
--------------------------------------------------------------------------------
do
  --local f3_key = require "context.utils.far3_keys"

-- DN_INPUT/DN_CONTROLINPUT: Param2 --> INPUT_RECORD
-- WARN: Call far.ParseInput(param2) before param2 using.
function far.ParseInput (Input) --> (VirKey, FarKey)
  f3_key = f3_key or require "context.utils.far3_key" -- Lazy require

  if type(Input) == 'table' then
    if Input.dwButtonState then
      Input.EventType = F.MOUSE_EVENT
      return
    end

    return Input, far23.FarInputRecordToKey(Input) -- TODO: Exclude FarKey

  else -- if type(Input) == 'number' then
    return f3_key.FarKeyToInputRecord(Input), Input
  end
end ---- ParseInput

end -- do
--------------------------------------------------------------------------------
