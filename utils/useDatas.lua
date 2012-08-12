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
1. History: history.lua.
  © Shmuel Zeigerman.
--]]
--------------------------------------------------------------------------------

local type = type
local pairs = pairs
local getmetatable, setmetatable = getmetatable, setmetatable

----------------------------------------
local context = context

local utils = require 'context.utils.useUtils'
local tables = require 'context.utils.useTables'

local PluginPath = utils.PluginPath

----------------------------------------
--[[
local log = require "context.samples.logging"
local logShow = log.Show
--]]

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
unit.Nameless = '@'         -- A field name for unnamed field
unit.Dataless = utils.null  -- A field data for undatum field

-- Add data from user-table to base-table.
-- Добавление данных из пользовательской таблицы в базовую.
--[[
  -- @params (@see tables.add):
  base  (table) - base table.
  user  (table) - user table.
  kind (string) - kind of addition.
  tpairs (func) - pairs-function to get fields values.
  value  (bool) - additional parameter.
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
  -- @params:
  t       (table) - base table.
  list    (table) - list of tables.
  -- @locals:
  index  (string) - used __index name.
--]]
local function _cfglist (t, list, index) --> (table)
  --[[ -- old code
  if not list[t] then
    list[t], list[#list+1] = true, t
  end
  --]]
  local l = list[t]

  -- Check repeating call for t:
  if l and l[index] then return list end

  -- Save new found table:
  if not l then
    list[t], list[#list+1] = {}, t
  end
  list[t][index or ""] = true -- Save used index

  -- Analyze all metaindexes:
  local t = getmetatable(t)
  if type(t) ~= 'table' then return list end

  local u = t.__cfgMT     -- Merged __index
  if type(u) == 'table' then _cfglist(u, list, "__cfgMT") end

  u = t.__oldindex        -- Saved __index
  if type(u) == 'table' then _cfglist(u, list, "__oldindex") end

  u = t.__index           -- Default __index
  if type(u) == 'table' then _cfglist(u, list, "__index") end

  return list
end -- _cfglist
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

---------------------------------------- load/require
do
  local loadfile, setfenv = loadfile, setfenv

-- Load data from file with loadfile.
-- Загрузка данных из файла с помощью loadfile.
--[[
  -- @params:
  fullname (string) - full file name.
  t         (t|nil) - already existing data table.
  kind     (string) - kind of addition (@default = 'update'): @see tables.add.
  -- @return:
  data      (t|nil) - data table.
--]]
function unit.load (fullname, t, kind) --> (table | nil, error)
  if not fullname then
    return nil, Msgs.FileNameNotFound
  end

  -- Load lua-file with data:
  local chunk, serror = loadfile(fullname)
  if not chunk then return nil, serror end

  -- Retrieve data from file:
  local env = { __index = _G }
  setmetatable(env, env)
  local u = setfenv(chunk, env)()
  if u == nil then u = env.Data end
  if u == nil and t == nil then
    return nil, Msgs.FileDataNotFound:format(fullname)
  end

  return addData(t, u, kind or 'update', pairs, false)
end -- load

end -- do

-- Find data file on path.
-- Поиск файла данных на path.
--[[
  -- @params:
  name     (string) - file name.
  path     (string) - string with path-mask list.
  -- @return:
  fullname (string) - full file name.
--]]
function unit.find (name, path) --> (string)
  path = path or package.path
  -- TODO: !!!
  return nil
end ---- find

do
  local pcall, require = pcall, require

-- Load data from file with require.
-- Загрузка данных из файла с помощью require.
--[[
  -- @params:
  name (string) - file name.
  t     (t|nil) - already existing data table.
  kind (string) - kind of data require (@default 'update'): @see unit.add.
  reload (bool) - flag for reload on repeated data load.
  -- @return:
  data  (table) - data table.
--]]
function unit.require (name, t, kind, reload) --> (table | nil, error)
  if not name then
    return nil, Msgs.FileNameNotFound
  end

  -- Protected require module with Data.
  local st, u = pcall(require, name)
  if not st then
    return nil, Msgs.FileRequireError:format(name, u)
  end

  -- Exclude module from loaded list.
  if reload then package.loaded[name] = nil end

  return addData(t, u, kind or 'update', pairs, false)
end -- require

end -- do

-- Make data with loadfile or require.
-- Формирование данных с помощью loadfile или require.
--[[
  -- @params:
  path (string) - file path.
  name (string) - file name.
  ext  (string) - file extension.
  t     (t|nil) - already existing data table.
  kind (string) - kind of data load: @see unit.add.
  -- @return:
  data  (table) - data table.
--]]
function unit.make (path, name, ext, t, kind) --> (table | nil, error)
  if not name then
    return nil, Msgs.FileNameNotFound
  end

  local fullname = utils.fullname(path, name, ext)
  local u, loadError, reqError = unit.load(fullname, t, kind)
  --if u then logShow(u, 'loadData', '#qd1') end
  if u ~= nil then return u end

  u, reqError = unit.require(name, t, kind)
  --if u then logShow(u, 'requireData', '#qd1') end
  if u ~= nil then return u end

  return nil, ('%s\n%s'):format(loadError, reqError)
end -- make

---------------------------------------- save/tostring
do
  local io_open = io.open

  local serial -- useSerial unit

-- Get serialize function.
local function getSerialize (serialize) --> (serialize)
  if serialize then return serialize end

  serial = serial or require 'context.utils.useSerial'

  return serial and serial.serialize
end -- getSerialize

-- Save data to file.
-- Сохранение данных в файл.
--[[
  -- @params:
  fullname (string) - full file name.
  name     (string) - data table name.
  data      (t|nil) - processed data table.
  kind      (table) - kind of data save: @see serialize.kind in useSerial.
  -- @return:
  isOk       (bool) - operation success flag.
--]]
function unit.save (fullname, name, data, kind) --> (bool)
  kind = kind or {}

  local f, s, res = io_open(fullname, 'w')
  if f == nil then return nil, s end

  local write = function (...)
                  return f:write(...)
                end -- write

  res, s = getSerialize(kind.serialize)(name, data, kind, write)

  f:close()
  return res, s
end -- save

  local select = select
  local tconcat = table.concat

-- Save data to string.
-- Сохранение данных в строку.
--[[
  -- @params:
  name     (string) - data table name.
  data      (t|nil) - processed data table.
  kind      (table) - kind of data conversion: @see serialize.kind in useSerial.
  -- @return:
  isOk (bool) - operation success flag.
--]]
function unit.tostring (name, data, kind) --> (bool)
  kind = kind or {}

  local t, n = {}, 0
  local write = function (...)
                  for i = 1, select("#", ...) do
                    n = n + 1
                    t[n] = select(i, ...)
                  end
                  return true
                end -- write

  local res, s = getSerialize(kind.serialize)(name, data, kind, write)

  if res == nil then return nil, s end

  return tconcat(t), s
end -- tostring

end -- do

---------------------------------------- history
local THistory = {} -- history class
local MHistory = { __index = THistory }

-- TODO: THistory methods.

function unit.history (path, name, kind) --> (object)

  local self = {
    path = path or PluginPath,
    name = name or "unknown",
    kind = kind or {},
  } --- self

  return setmetatable(self, MHistory)
end -- history

-- Create history object.
function unit.newHistory (name) --> (object)
if context.use.LFVer >= 3 then
  local history = require "far2.history"

  return history.newfile(name)

else -- FAR23
  local history = require "history"

  return history.new(name)
end
end -- history

---------------------------------------- custom
do
  local f_fpath = '%s%s%s'      -- Relative path
  local f_tlink = '<%s%s>%s'    -- Help topic link

-- defCustom sample.
-- Warning: Fields with '*' are required, others are optional.
--[[
local defCustom = {
 *name = ScriptName,    -- имя скрипта (для формирования имён файлов).
 *path = ScriptPath,    -- относительный путь к файлам скрипта.
  base = PluginPath,    -- базовая часть пути для файлов скрипта.

  -- Options: -- Опции скрипта.
  options = {},         -- таблица параметров, настраиваемых скриптом.

  -- Common:  -- Общие параметры:
  label = '',           -- обозначение скрипта (обычно сокращённое).
  file  = '',           -- общая часть имени (без расширения)
                           для файлов справки и локализации.

  -- History:
  history = { -- История (обработка настроек скрипта):
    field = name,       -- поле настроек скрипта в таблице файла.
    dir  = '',          -- каталог файла.
    ext  = '.cfg',      -- расширение файла.
    name = '',          -- имя файла с расширением.
    path = '',          -- относительный путь к файлу.
    file = '',          -- относительный путь с именем файла.
    full = '',          -- полный путь с именем файла.
  },

  -- Help:
  help = {    -- Справка по скрипту:
    ext  = '.hlf',      -- расширение файла.
    file = '',          -- имя файла.
    path = '',          -- относительный путь к файлу.
    topic = '',         -- название темы.
    tlink = '',         -- ссылка на тему.
  },

  -- Locale:
  locale = {  -- Файлы локализации скрипта:
    kind = 'both',      -- способ обработки файлов.
    dir  = "locales\\", -- каталог файлов.
    ext  = '.lua',      -- расширение файлов.
    file = '',          -- общее имя файлов.
    pdir = nil,         -- относительный путь к каталогу файлов.
    path = '',          -- относительный путь к файлам.
  }
} --- defCustom
--]]

-- Customize script settings.
-- Настройка установок скрипта.
--[[
  -- @params:
  Custom    (table) - user settings table.
  defCustom (table) - default settings table.
  -- @return:
  Custom    (table) - customized settings table.
--]]
function unit.customize (Custom, defCustom) --> (table)
  local t, u = addData(Custom or {}, defCustom, 'extend', pairs, true)
  local name, path = t.name, t.path:gsub('/', '\\'):gsub('%.', '\\')
  t.path = path
  --logShow(t, "data")

  -- Options:
  t.options = t.options or {}

  -- Common:
  t.label = t.label or name
  t.file  = t.file  or name
  t.base  = t.base  or PluginPath

  -- History:
  u = t.history or {}; t.history = u
  u.field = u.field or name
  u.dir   = u.dir  or ''
  u.ext   = u.ext  or '.cfg'
  u.name  = u.name or name..u.ext
  u.path  = u.path or path
  u.file  = u.file or f_fpath:format(u.path, u.dir, u.name)
  u.full  = t.base..u.file

  -- Help:
  u = t.help or {}; t.help = u
  u.ext   = u.ext  or '.hlf'
  u.file  = u.file or t.file or name
  u.path  = u.path or path
  u.topic = u.topic or u.file
  u.tlink = u.tlink or f_tlink:format(t.base, u.path, u.topic)

  -- Locale:
  u = t.locale or {}; t.locale = u
  u.kind = u.kind or 'both'
  u.dir  = u.dir or 'locales\\'
  u.ext  = u.ext  or '.lua'
  u.file = u.file or t.file or name
  u.pdir = u.pdir or path
  u.path = u.pdir..u.dir
  --u.path = u.path or u.pdir..u.dir
  --u.fullpath = t.base..u.path
  --logShow(t, "data")

  return t
end -- customize

end -- do

--------------------------------------------------------------------------------
return unit
--------------------------------------------------------------------------------
