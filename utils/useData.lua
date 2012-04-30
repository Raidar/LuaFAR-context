--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- Working with data tables.
  -- Работа с таблицами данных.
--]]
----------------------------------------
--[[ uses:
  LuaFAR,
  LF context.
  -- group: Datas.
--]]
----------------------------------------
--[[ some code from:
  serial.lua -- for serialize
  (c) Shmuel Zeigerman.
--]]
--------------------------------------------------------------------------------
local _G = _G

local type = type
local pairs = pairs
local getmetatable, setmetatable = getmetatable, setmetatable

local io_open = io.open

----------------------------------------
local context = context
local utils = context.utils
local tables = context.tables

----------------------------------------
--local logMsg = (require "Rh_Scripts.Utils.Logging").Message

--------------------------------------------------------------------------------
local unit = {}

----------------------------------------
-- Messages
local Msgs = {
  -- load/save:
  FileNameNotFound = "File name not found",
  FileDataNotFound = "File data not found for:\n%s",
  FileRequireError = "Error require file:\n%s\n%s",
} --- Msgs

---------------------------------------- base
-- Special values:
unit.Nameless = '@'                -- A field name for unnamed field
unit.Dataless = context.utils.null -- A field data for undatum field

-- Add data from user-table to base-table.
-- Добавление данных из пользовательской таблицы в базовую.
--[[ Параметры (см. tables.add):
  base  (table) - базовая таблица.
  user  (table) - пользовательская таблица.
  kind (string) - вид добавления.
  tpairs (func) - функция для получения значений таблицы.
  value  (bool) - дополнительный параметр.
--]]
function unit.add (base, user, kind, tpairs, deep, ...) --> (table)
  if not base then return user end
  if not user then return base end
  return tables.add(base, user, kind, tpairs, deep, ...)
end --
local addData = unit.add

---------------------------------------- pairs
-- TODO: cfglist with metafields list in args!

-- Make list of all config tables.
-- Формирование списка из всех таблиц конфигурации.
--[[
  t    (table) - base table.
  list (table) - list of tables.
--]]
local function _cfglist (t, list) --> (table)
  if not list[t] then
    list[t], list[#list+1] = true, t
  end

  local t = getmetatable(t)
  if type(t) ~= 'table' then return list end

  local u = t.__cfgMT     -- Merged __index
  if type(u) == 'table' then _cfglist(u, list) end

  u = t.__oldindex        -- Saved __index
  if type(u) == 'table' then _cfglist(u, list) end

  u = t.__index           -- Default __index
  if type(u) == 'table' then _cfglist(u, list) end

  return list
end --
unit._cfglist = _cfglist

function unit.cfglist (t) --> (table)
  local list = {}
  if type(t) ~= 'table' then return list end

  return _cfglist(t, list)
end --

-- 'pairs' function with configs support.
function unit.cfgpairs (t) --> (func)
  return tables.allpairs(t, unit.cfglist)
end --

---------------------------------------- load/save
do
  local loadfile, setfenv = loadfile, setfenv

-- Load data from file with loadfile.
-- Загрузка данных из файла с помощью loadfile.
--[[ Параметры:
  fullname (string) - полное имя файла.
  t     (table|nil) - уже существующая таблица данных.
  kind     (string) - вид добавления (см. unit.add, по умолчанию 'update').
  -- Результаты:
  data (table|nil) - таблица с данными.
--]]
function unit.load (fullname, t, kind) --> (table | nil, error)
  if not fullname then return nil, Msgs.FileNameNotFound end

  -- Load lua-file with data:
  local chunk, serror = loadfile(fullname)
  if not chunk then return nil, serror end

  -- Retrieve data from file:
  local env = { __index = _G }
  setmetatable(env, env)
  local u = setfenv(chunk, env)()
  if u == nil then u = env.Data end
  if u == nil and t == nil then
      return nil, Msgs.FileDataNotFound:format(name)
  end

  return addData(t, u, kind or 'update', pairs, false)
end --

end -- do

-- Find data file on package.path.
-- Поиск файла данных на package.path.
--[[ Параметры:
  name (string) - имя файла.
  -- Результаты:
  fullname (string) - полное имя файла.
--]]
function unit.find (name) --> (string)
  -- TODO: !!!
end ----

do
  local pcall, require = pcall, require

-- Load data from file with require.
-- Загрузка данных из файла с помощью require.
--[[ Параметры:
  name  (string) - имя файла.
  t  (table|nil) - уже существующая таблица данных.
  kind  (string) - вид добавления (см. unit.add, по умолчанию 'update').
  reload  (bool) - признак перезагрузки при повторной загрузке данных.
  -- Результаты:
  data (table|nil) - таблица с данными.
--]]
function unit.require (name, t, kind, reload) --> (table | nil, error)
  if not name then return nil, Msgs.FileNameNotFound end

  -- Protected require module with Data.
  local st, u = pcall(require, name)
  if not st then
    return nil, Msgs.FileRequireError:format(name, u)
  end

  -- Exclude module from loaded list.
  if reload then package.loaded[name] = nil end

  return addData(t, u, kind or 'update', pairs, false)
end --

end -- do

-- Make data with loadfile or require.
-- Формирование данных с помощью loadfile или require.
--[[ Параметры:
  path  (string) - путь к файлу.
  name  (string) - имя файла.
  ext   (string) - расширение файла.
  t  (table|nil) - уже существующая таблица данных.
  kind  (string) - вид добавления (см. unit.add).
  -- Результаты:
  data (table|nil) - таблица с данными.
--]]
function unit.make (path, name, ext, t, kind) --> (table | nil, error)
  if not name then return nil, Msgs.FileNameNotFound end
  local fullname = utils.fullname(path, name, ext)
  local u, loadError, reqError = unit.load(fullname, t, kind)
  --if u then logMsg(u, 'loadData', 1, '#q') end
  if u ~= nil then return u end

  u, reqError = unit.require(name, t, kind)
  --if u then logMsg(u, 'requireData', 1, '#q') end
  if u ~= nil then return u end
  return nil, ('%s\n%s'):format(loadError, reqError)
end --

-- Serialize data with write.
-- Сериализация данных с помощью write.
--[[ Параметры:
  name (string) - название для данных.
  data  (table) - сохраняемые данные.
  kind  (table) - вид хранения: format, saved etc.
  write  (func) - функция записи строки данных.
  -- Результаты:
  isOk (bool) - успешность операции.
--]]
local function serialize (name, data, kind, write) --> (bool)
  -- TODO
  return false, 'TODO'
end --
unit.serialize = serialize

-- Save data to file.
-- Сохранение данных в файл.
--[[ Параметры:
  fullname (string) - полное имя файла.
  name     (string) - название таблицы данных.
  data  (table|nil) - обрабатываемая таблица данных.
  kind      (table) - вид хранения.
  -- Результаты:
  isOk (bool) - успешность операции.
--]]
function unit.save (fullname, name, data, kind) --> (bool)
  local f, s, res = io_open(fullname, 'w')
  if f == nil then return nil, s end
  local res, s =
      serialize(name, data, kind,
                function (...)
                  fh:write (...)
                end)
  f:close()
  return res, s
end --

do
  local tconcat = table.concat

-- Save data to string.
-- Сохранение данных в строку.
--[[ Параметры:
  name     (string) - название таблицы данных.
  data  (table|nil) - обрабатываемая таблица данных.
  kind      (table) - вид хранения.
  -- Результаты:
  isOk (bool) - успешность операции.
--]]
function unit.tostring (name, data, kind) --> (bool)
  local t, n = {}, 0
  local res, s =
      serialize(name, data, kind,
                function (...)
                  for i = 1, select("#", ...) do
                    n = n + 1
                    t[n] = select(i, ...)
                  end
                end)
  if res == nil then return nil, s end

  return tconcat(t), s
end -- tostring

end -- do

---------------------------------------- custom
do
  local PluginPath = utils.PluginPath

  local f_fpath = '%s%s%s'      -- Relative path
  local f_tlink = '<%s%s>%s'    -- Help topic link

-- defCustom sample.
-- Warning: Fields with '*' are required, others are optional.
--[[
local defCustom = {
 *name = ScriptName,  -- имя скрипта (для формирования имён файлов).
 *path = ScriptPath,  -- относительный путь к файлам скрипта.
  base = PluginPath,  -- базовая часть пути для файлов скрипта.

  -- Options: -- Опции скрипта.
  options = {},       -- таблица параметров, настраиваемых скриптом.

  -- Common:  -- Общие параметры:
  label = '',         -- обозначение скрипта (обычно сокращённое).
  file  = '',         -- общая часть имени (без расширения) для файлов.

  -- History:
  history = { -- История (обработка настроек скрипта):
    field = name,     -- поле настроек скрипта в таблице файла.
    dir  = '',        -- каталог файла.
    name = '',        -- имя файла (без расширения).
    ext  = '.cfg',    -- расширение файла.
    file = '',        -- относительный путь и имя файла.
  },

  -- Help:
  help = {    -- Справка по скрипту:
    ext  = '.hlf',    -- расширение файла.
    topic = '',       -- название темы.
    tlink = '',       -- ссылка на тему.
  },

  -- Locale:
  locale = {  -- Файлы локализации скрипта:
    kind = 'both',    -- способ обработки файлов.
    ext  = '.lua',    -- расширение файлов.
    dir  = "locales\\", -- каталог файлов.
    path = '',        -- относительный путь к файлам.
  }
} --- defCustom
--]]

-- Customize script settings.
-- Настройка установок скрипта.
--[[ Параметры:
  Custom    (table) - таблица пользовательских установок.
  defCustom (table) - таблица установок по умолчанию.
  -- Результаты:
  Custom    (table) - настроенная таблица установок.
--]]
function unit.customize (Custom, defCustom) --> (table)
  local t, u = addData(Custom or {}, defCustom, 'extend', pairs, true)
  local name, path = t.name, t.path:gsub('/', '\\'):gsub('%.', '\\')
  t.path = path
  --logMsg(t, "data")

  -- Options:
  t.options = t.options or {}

  -- Common:
  t.label = t.label or name
  t.file  = t.file  or name
  t.base  = t.base  or PluginPath

  -- History:
  u = t.history or {}; t.history = u
  u.field = u.field or name
  u.ext   = u.ext  or '.cfg'
  u.dir   = u.dir  or ''
  u.name  = u.name or name..u.ext
  u.file  = u.file or f_fpath:format(path, u.dir, u.name)
  u.full  = t.base..u.file

  -- Help:
  u = t.help or {}; t.help = u
  u.ext   = u.ext  or '.hlf'
  u.file  = u.file or t.file or name
  u.topic = u.topic or u.file
  u.tlink = u.tlink or f_tlink:format(t.base, path, u.topic)

  -- Locale:
  u = t.locale or {}; t.locale = u
  u.kind = u.kind or 'both'
  u.file = u.file or t.file or name
  u.ext  = u.ext  or '.lua'
  u.dir  = u.dir or 'locales\\'
  u.path = u.path or path..u.dir
  u.fullpath = t.base..u.path
  --logMsg(t, "data")

  return t
end --

end -- do

--------------------------------------------------------------------------------
context.datas = unit -- 'datas' table in context
--------------------------------------------------------------------------------
