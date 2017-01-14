--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- Utility routines.
  -- Служебные подпрограммы.
--]]
----------------------------------------
--[[ uses:
  LuaFAR,
  LF context.
  -- group: LFc utils.
--]]
--------------------------------------------------------------------------------

----------------------------------------
local bit = bit64
local band, bor  = bit.band, bit.bor
local bnot, bxor = bit.bnot, bit.bxor
--local bshl, bshr = bit.lshift, bit.rshift

----------------------------------------
local win, far = win, far

local F = far.Flags

----------------------------------------
local logShow = context.Show

--------------------------------------------------------------------------------
local unit = {}

---------------------------------------- null
local error = error

do
-- Implementation of null value.
-- Реализация значения null.
local Tnull = {

  __index    = function (t, k)    --| (error)

    error("Attempt to get a field of null value", 2)

  end,

  __newindex = function (t, k, v) --| (error)

    error("Attempt to set a field of null value", 2)

  end,

  __metatable = "null value",

} --- Tnull
unit.null = setmetatable({}, Tnull)

end -- do

--local null = unit.null -- null value instead of nil

---------------------------------------- Flags
do
--[[
  -- @params (for flag handling):
  f     (number|bit64 string) - flag value.
  flags (number|bit64 string) - flag set.
  ...   (list)                - flag values list.
--]]

-- Create a new empty flag set.
-- Создание нового пустого набора флагов.
function unit.newFlag (flags) --> (flags)

  return flags or 0x00

end ----

-- Check flag in a set.
-- Проверка флага в наборе.
function unit.isFlag (flags, f) --> (flags)

  return band(flags, f) ~= 0

end ----

-- Add flag to a set.
-- Добавление флага к набору.
function unit.addFlag (flags, f) --> (flags)

  return bor(flags, f)

end ----

-- Delete flag from a set.
-- Удаление флага из набора.
function unit.delFlag (flags, f) --> (flags)

  return band(flags, bnot(f))

end ----

-- Invert flag from a set.
-- Обращение флага из набора.
function unit.invFlag (flags, f) --> (flags)

  return bxor(flags, f)

end ----

do
  local addFlag = unit.addFlag

-- Add flags to a set.
-- Добавление флагов к набору.
function unit.addFlags (flags, ...) --> (flags)

  for _, v in ipairs({...}) do
    flags = addFlag(flags, v)

  end

  return flags

end ----

  local delFlag = unit.delFlag

-- Delete flags from a set.
-- Удаление флагов из набора.
function unit.delFlags (flags, ...) --> (flags)

  for _, v in ipairs({...}) do
    flags = delFlag(flags, v)

  end

  return flags

end ----

end -- do

-- Create a new flag set.
-- Создание нового набора флагов.
function unit.newFlags (...) --> (flags)

  return unit.addFlags(unit.newFlag(), ...)

end ----

end -- do
do
  local type = type
  local tonumber = tonumber

  -- Number used flags
  local numFlags = {

    MIF_CHECKED  = true,
    WHEEL_DELTA  = true,

  } --- numFlags

-- Convert table-flag to number.
-- Преобразование флага-таблицы в число.
--[[
  -- @notes:
  Values of simple-value flags: 0|1, false|true, nil.
  Values of number-value flags: word-sized number.
  (Value of number-value flag takes a low word of flagh value.)
  -- @params:
  flags    (table) - source table with flags.
  numflags (table) - table with number-value flags.
--]]
function unit.numFlag (flags, numflags) --> (flags number)

  if type(flags) == 'string' then flags = { [flags] = 1 } end
  if type(flags) ~= 'table' then return flags end

  numflags = numflags or numFlags

  local n = 0

  for k, v in pairs(flags) do
    --if type(v) == 'boolean' then v = b2n(v) end
    if v then n = bor(n, F[k] or 0) end
    if numflags[k] then n = bor(n, tonumber(v)) end

  end

  return n

end ---- numFlag

end -- do

---------------------------------------- FAR
-- Plugin path.
-- Путь к плагину.
function unit.getPluginPath ()

  return far.PluginStartupInfo().ModuleDir

end --

unit.PluginPath = unit.getPluginPath() -- Current plugin path

-- Plugin directory name.
-- Название каталога плагина.
--unit.PluginDirName = unit.PluginPath:match("[/\\]([^/\\]*)[/\\]$")

--far.Message(unit.PluginPath, unit.PluginDirName)

do
  local GetSysEnv = win.GetEnv

-- Profile path.
-- Путь к профилю.
function unit.getProfilePath ()

  return (GetSysEnv("FARPROFILE") or
          GetSysEnv("FARHOME").."\\Profile").."\\"

end -- getProfilePath

-- Work directory.
-- Рабочий каталог.
function unit.getUserWorkDir ()

  return (GetSysEnv("FARUSERWORKDIR") or "work").."\\"

end -- getUserWorkDir

-- Data directory.
-- Каталог данных.
function unit.getUserDataDir ()

  return (GetSysEnv("FARUSERDATADIR") or "data").."\\"

end -- getUserDataDir

end --

unit.ProfilePath    = unit.getProfilePath() -- Current profile path
unit.PluginWorkDir  = unit.getUserWorkDir() -- Current user work directory
                                            -- (relative to profile path)
unit.PluginDataDir  = unit.getUserDataDir() -- Current user data directory
                                            -- (relative to profile path)
-- Work directory path.
-- Путь к рабочему каталогу.
function unit.getUserWorkPath ()

  local Info = far.PluginStartupInfo()
  local Guid = string.upper(win.Uuid(Info.PluginGuid) or "")
  --far.Show(Guid)

  if Guid == "4EBBEFC8-2084-4B7F-94C0-692CE136894D" then
    return unit.ProfilePath..unit.PluginWorkDir -- LuaMacro plugin

  end

  return Info.ModuleDir -- LuaFAR plugins

end -- getUserWorkPath

unit.PluginWorkPath = unit.getUserWorkPath()
unit.PluginDataPath = unit.ProfilePath..unit.PluginDataDir

-- Used interface and help language.
-- Используемый язык интерфейса и справки.
--[[
  -- @return:
  _ (table):
    Main (string) - interface language.
    Help (string) - help language.
--]]
function unit.language () --> (table)

  --[[
  far.FreeSettings()
  local lngMain, lngHelp

  local obj = far.CreateSettings("far", F.PSL_LOCAL)
  if obj then
    --far.Message(obj, "far")
    local key = obj:OpenSubkey(0, "Language")
    --far.Message(F.FST_STRING, key)
    --far.Message(obj:Get(0, "Main", F.FST_STRING), key)
    far.Message(obj:Get(key, "Main", F.FST_STRING), key)

    lngMain = obj:Get(key, "Main", F.FST_STRING)
    lngHelp = obj:Get(key, "Help", F.FST_STRING)
    obj:Free()

  end

  return {

    Main = lngMain or "Default", -- Interface
    Help = lngHelp or "Default", -- Help

  } ----
  --]]

  local Macro_Lang = [[
    return Far.GetConfig("Language.Main"), Far.GetConfig("Language.Help")
  ]] -- Macro_Lang

  local Lang = far.MacroExecute(Macro_Lang) or {}
  local MainLang = Lang[1]
  local HelpLang = Lang[2]
  --far.Show(Lang, MainLang, HelpLang)

  --[[
  -- Language settings are private! -- This code don't work.
  local FarCfg = far.CreateSettings("far", F.PSL_LOCAL)
  local Lang = FarCfg and FarCfg:OpenSubkey(0, "Language")
  local MainLang = Lang and FarCfg:Get(Lang, "Main", F.FST_STRING)
  local HelpLang = Lang and FarCfg:Get(Lang, "Help", F.FST_STRING)
  --far.Show(FarCfg, Lang, MainLang, HelpLang)
  far.FreeSettings()
  --]]

  MainLang = MainLang or win.GetEnv("FARLANG") or "Default"
  HelpLang = HelpLang or MainLang

  return {

    Main = MainLang,  -- UI
    Help = HelpLang,  -- Help

  } ----

end ---- language

do
  local GetPanelInfo = panel.GetPanelInfo

-- Check panel as plugin panel.
-- Проверка панели на панель плагина.
function unit.isPluginPanel (Info) --> (bool)

  return unit.isFlag((Info or GetPanelInfo(nil, 1)).Flags, F.PFLAGS_PLUGIN)

end ----

end -- do

---------------------------------------- Message
do
  local farMsg = far.Message

-- Simple message box.
-- Простое окно с сообщением.
function unit.message (Title, Msg, Flags, Buttons) --| (window)

  return farMsg(Msg, Title, Buttons, Flags)

end --

-- Warning message box.
-- Окно-предупреждение с сообщением.
function unit.warning (Title, Msg, Flags) --| (window)

  return farMsg(Msg, Title, nil, (Flags or '').."w")

end --

end -- do
---------------------------------------- System

-- Преобразование разделителей в разделители пути.
-- Convert separators (in path) to path separators.
function unit.to_path (path) --> (string)

  return path and path:gsub('/', '\\'):gsub('%.', '\\')

end ----

do
  local format = string.format

-- Полное имя
-- Full name.
function unit.fullname (path, name, ext) --> (string)

  return format('%s%s%s', path or '', name or '', ext or '')

end --

end -- do
do
  local io_open = io.open

-- Check file for exists and readability.
-- Проверка файла на существование и читаемость.
function unit.fexists (filename) --> (bool)

  local f = io_open(filename, 'rb')
  if f then f:close() end

  return f ~= nil

end ----

  local assert = assert

-- File size.
-- Размер файла.
function unit.filesize (filename) --> (number)

  local f = assert(io_open(filename, "rb"))
  local len = assert(f:seek("end"))
  f:close()

  return len

end ----

-- Создание каталога с подкаталогами.
-- Create directory with subdirectories.
function unit.makedir (path) --> (boolean)

  return assert(win.CreateDir(path, true))

end ----

end -- do

--------------------------------------------------------------------------------
return unit
--------------------------------------------------------------------------------
