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
1. Serial and History.
  serial.lua -- for serialize.
  history.lua -- for history.
  © Shmuel Zeigerman.
2. Table Serialization.
  URL: http://lua-users.org/wiki/TableSerialization
--]]
--------------------------------------------------------------------------------
local _G = _G

local type = type
local pairs = pairs
local getmetatable, setmetatable = getmetatable, setmetatable

----------------------------------------
local context = context
local utils = context.utils
local tables = context.tables

----------------------------------------
local logMsg = (require "Rh_Scripts.Utils.Logging").Message

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
  t     (table) - base table.
  list  (table) - list of tables.
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

---------------------------------------- load/require
do
  local loadfile, setfenv = loadfile, setfenv

-- Load data from file with loadfile.
-- Загрузка данных из файла с помощью loadfile.
--[[
  -- @params:
  fullname (string) - full file name.
  t         (t|nil) - already existing data table.
  kind     (string) - kind of addition (@see tables.add, @default = 'update').
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
    return nil, Msgs.FileDataNotFound:format(name)
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

---------------------------------------- save/serialize
do
  local pcall, require = pcall, require

-- Load data from file with require.
-- Загрузка данных из файла с помощью require.
--[[
  -- @params:
  name (string) - file name.
  t     (t|nil) - already existing data table.
  kind (string) - kind of data require (@see unit.add, @default 'update').
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
  kind (string) - kind of data load (@see unit.add).
  -- @return:
  data  (table) - data table.
--]]
function unit.make (path, name, ext, t, kind) --> (table | nil, error)
  if not name then
    return nil, Msgs.FileNameNotFound
  end

  local fullname = utils.fullname(path, name, ext)
  local u, loadError, reqError = unit.load(fullname, t, kind)
  --if u then logMsg(u, 'loadData', 1, '#q') end
  if u ~= nil then return u end

  u, reqError = unit.require(name, t, kind)
  --if u then logMsg(u, 'requireData', 1, '#q') end
  if u ~= nil then return u end

  return nil, ('%s\n%s'):format(loadError, reqError)
end -- make

do
  local tostring = tostring
  local format = string.format
  local frexp, modf = math.frexp, math.modf

-- Convert simple value to string.
-- Преобразование простого значения в строку.
local function ValToStr (value, strlong) --> (string | nil, type)
  local tp = type(value)
  if tp == 'boolean' then return tostring(value) end
  if tp == 'number' then
    if value == modf(value) then return tostring(value) end -- integer
    return format("(%.17f * 2^%d)", frexp(value)) -- preserve accuracy
  end

  if tp == 'string' then
    if strlong and
       value:len() > strlong and
       value:find("\n", 1, true) and
       not value:find("%s\n") and
       --not value:find("%[%[.-%]%]") and
       not value:find("[[", 1, true) and
       not value:find("]]", 1, true) then
      return ("[[\n%s]]"):format(value) -- [[string]]
    end
    return ("%q"):format(value) -- "string"
  end

  return nil, tp
end -- ValToStr
unit.ValToStr = ValToStr

  local reserveds = context.lua.keywords
  local KeywordMask = context.lua.KeywordMask

-- Convert key name to string.
-- Преобразование имени ключа в строку.
local function KeyToStr (key) --> (string)
  local tp = type(key)
  if tp ~= 'string' then
    local key = ValToStr(key)
    if key then
      return format("[%s]", key)
    end
    return --nil, tp
  end

  if key:find(KeywordMask) and not reserveds[key] then
    return "."..key, key
  end
  return format("[%q]", key)
end -- KeyToStr
unit.KeyToStr = KeyToStr

  local unpack = unpack

-- Convert table to string.
-- Преобразование таблицы в строку.
--[[
  -- @params (@see unit.serialize).
  -- @return:
  isOk   (bool) - operation success flag.
--]]
local function TabToStr (name, data, kind, write) --| (write)

  -- Write self-references:
  do
    local value = kind.saved[data]
    if value then -- saved name as value
      write(kind.indent, name, " = ", value, "\n")
      return
    end
    kind.saved[data] = name
    --logMsg({ name, kind, data or "nil" }, "kind", 3)
  end

  -- Settings to write current table:
  kind.level = kind.level + 1
  local cur_indent = kind.indent
  local new_indent = cur_indent..kind.shift
  kind.indent = new_indent

  local strlong = kind.strlong
  local tname = kind.tname
  tname = (kind.level % 2 == 1) and tname or (tname == "t" and "u" or "t")

  -- Write current table fields:
  local isnull = true
  for k, v in kind.pairs(data, unpack(kind.pargs)) do
    local s = KeyToStr(k)
    if s then
      local w, tp = ValToStr(v, strlong)
      if isnull and (w or tp == 'table') then
        isnull = false
        write(cur_indent, format("do local %s = {}; %s = %s\n",
                                 tname, name, tname)) -- do
      end
      if w then
        write(new_indent, format("%s%s = %s\n", tname, s, w))
      elseif tp == 'table' then
        TabToStr(name..s, v, kind, write)
      end
    end
  end

  if isnull then
    write(cur_indent, name, " = {}")
  else
    write(cur_indent, "end") -- end
  end
  write(cur_indent, "\n")

  -- Restore settings
  kind.level = kind.level - 1
  kind.indent = cur_indent

  return true
end -- TabToStr
unit.TabToStr = TabToStr

  local unpack = unpack
  local sortpairs = tables.sortpairs
  local statpairs = tables.statpairs

-- Convert table to pretty text.
-- Преобразование таблицы в читабельный текст.
--[[
  -- @params (@see unit.serialize):
  kind  (table) - conversion kind: @fields additions:
    pargs[1]  (table) - sortkind (@see tables.statpairs).
    astable    (bool) - write data as whole table ({ fields }).
    tnaming    (bool) - using temp names to access fields.
    lcount   (number) - field count in line to write array.
    lenmax   (number) - length maximum of line to write array.
  -- @return:
  isOk   (bool) - operation success flag.
--]]
local function TabToText (name, data, kind, write) --| (write)

  local level = kind.level -- Prior level
  local fname = kind.fname or name

  -- Write self-references:
  do
    local saved = kind.saved --or {}
    local value = saved[data]
    if value then -- saved name as value
      if kind.tnaming or kind.astable or
         (level > 1 and kind.nestless[level]) then
        saved[fname] = data -- Save self-reference
        write(kind.indent, name, " = ",   -- and
              "false, -- ", value, "\n")  -- Write as comment
      else
        write(kind.indent, name, " = ", value, "\n")
      end

      return
    end

    saved[data] = fname -- name
  end -- do

  -- Settings to write current table:
  kind.level = kind.level + 1 -- Current level
  level = kind.level

  local cur_indent = kind.indent
  local new_indent = cur_indent..kind.shift
  kind.indent = new_indent

  local sortkind = kind.pargs[1] or {}
  local sortnext = statpairs(data, sortkind, unpack(kind.pargs, 2))
  --logMsg(sortkind.stats, "statpairs stats")

  if level == 1 then kind.nestless = {} end
  local nestless = sortkind.stats['table'] == 0
  kind.nestless[level] = nestless
  nestless = kind.astable or nestless

  -- Write current table fields:
  local skip = {}
  local isnull = true

  local isarray = kind.isarray -- Save value

  -- Simplified write array fields:
  if nestless then
    kind.isarray = true

    -- Settings to write fields in one line
    local lcount, lenmax = kind.lcount, kind.lenmax
    if type(lcount) == 'function' then
      lcount = lcount(name, data)
    end
    if type(lenmax) == 'function' then
      lenmax = lenmax(name, data)
    end

    local l = 0 -- new line count-flag
    local cnt, len, indlen = 1, 0, new_indent:len()

    local k, v = 1, data[1]
    while v ~= nil do
      skip[k] = v
      local w, tp = ValToStr(v)
      if isnull and (w or tp == 'table') then
        isnull = false
        if isarray then
          write(cur_indent, "{\n") -- {
        else
          write(cur_indent, name, " = {\n") -- {
        end
      end

      if w then
        if lcount or lenmax then
          l = l + 1
          cnt = cnt + 1
          len = len + w:len() + 2 -- 2 for ' ' + ','
          if l == 1 or
             lcount and cnt > lcount or
             lenmax and len >= lenmax then
            cnt = 1
            len = indlen + w:len()
            write(l > 1 and "\n" or "", new_indent, w, ",")
          else
            write(" ", w, ",")
          end
        else
          write(new_indent, w, ",\n")
        end
      elseif tp == 'table' then
        if lcount or lenmax then
          l = 0
          write("\n")
        end
        local s = KeyToStr(k)
        kind.fname = fname..s
        TabToText(s, v, kind, write)
      end

      k = k + 1
      v = data[k]
    end -- while

    if not isnull then write("\n") end
    kind.isarray = isarray -- Restore value
  end -- if nestless

  local tname = kind.tname
  tname = (level % 2 == 1) and tname or (tname == "t" and "u" or "t")
  --if name == "t.aTEST" then logMsg(kind, tname) end

  -- Simplified write hash(+array) fields:
  for k, v in sortnext do
    if not skip[k] then
      local s, c = KeyToStr(k)
      c = nestless and c or s
      --logMsg({ nestless, s, c, kind }, name, 2)

      if s then
        local w, tp = ValToStr(v)
        if isnull and (w or tp == 'table') then
          isnull = false
          --logMsg({ nestless, kind }, name, 2)
          if nestless then
            if isarray then
              write(cur_indent, "{\n") -- {
            else
              write(cur_indent, name, " = {\n") -- {
            end
          else
            write(cur_indent, format("do local %s = {}; %s = %s\n",
                                     tname, name, tname)) -- do
          end
        end

        if w then
          if nestless then
            write(new_indent, format("%s = %s,\n", c, w))
          else
            write(new_indent, format("%s%s = %s\n", tname, c, w))
          end

        elseif tp == 'table' then
          kind.fname = fname..s
          if nestless then
            TabToText(c, v, kind, write)
          else
            TabToText((kind.tnaming and tname or name)..c, v, kind, write)
          end
        end
      end
    end
  end -- for

  if isnull then
    write(cur_indent, name, " = {}")
  else
    if nestless then
      write(cur_indent, "}") -- }
    else
      write(cur_indent, "end") -- end
    end
  end
  if level > 1 and (kind.astable or kind.nestless[level - 1]) then
    write(",")
  end
  write("\n")

  -- Write self-references:
  if level == 1 then
    local isnull = true
  
    local saved = kind.saved
    for k, v in sortpairs(saved) do
      if type(k) == 'string' and type(v) == 'table' then
        if isnull then
          isnull = false
          write("\n")
          --write("\n-- self-references:\n")
        end
        write(cur_indent, k, " = ", saved[v] or 'nil', "\n")
      end
    end
    --if not isnull then write("--\n") end
  end

  -- Restore settings
  kind.level = kind.level - 1 -- Prior level
  kind.indent = cur_indent

  return true
end -- TabToText
unit.TabToText = TabToText

-- Serialize data with write.
-- Сериализация данных с помощью write.
--[[
  -- @params:
  name (string) - data name.
  data  (table) - saved data.
  kind  (table) - serializion kind (@see kind in pairs and TabToStr):
    saved     (table) - names of tables already saved.
    indent   (string) - initial indent value to write.
    shift    (string) - indent shift to pretty write fields.
    pairs      (func) - pairs function to get fields.
    pargs     (table) - array of arguments to call pairs.
    localret   (bool) - using 'local name = {} ... return name' structure.
    strlong (b|n|nil) - using long brackets for string formatting
                        (strlong as number is for string length minimum).
    ValToStr   (func) - function to convert simple value to string.
    TabToStr   (func) - function to convert table to string.
  write  (func) - function to write data strings.
  -- @return:
  isOk   (bool) - operation success flag.
--]]
function unit.serialize (name, data, kind, write) --> (bool)
  local kind = kind or {}
  --logMsg(kind, "kind")

  local s, tp = (kind.ValToStr or ValToStr)(data, kind.strlong)
  if s then
    if kind.localret then
      return write(format("local %s = %s\nreturn %s\n", name, s, name))
    end
    return write(name, " = ", s, "\n")
  end
  if tp ~= 'table' then return end

  kind.saved = kind.saved or {}
  kind.indent = kind.indent or ""
  kind.shift = kind.shift or "  "
  kind.pairs = kind.pairs or pairs
  kind.pargs = kind.pargs or {}

  kind.level = 0 -- deep level for table nesting
  kind.fname = name -- using for table field name
  kind.tname = (name == "t") and "u" or "t" -- prevent collision of names

  if kind.localret then
    write(kind.indent, "local ", name, "\n\n")
  end;

  (kind.TabToStr or TabToStr)(name, data, kind, write)

  if kind.localret then
    write(kind.indent, "\nreturn ", name, "\n")
  end

  return true
end -- serialize

end -- do

local serialize = unit.serialize

do
  local io_open = io.open

-- Save data to file.
-- Сохранение данных в файл.
--[[
  -- @params:
  fullname (string) - full file name.
  name     (string) - data table name.
  data      (t|nil) - processed data table.
  kind      (table) - kind of data save (@see serialize.kind).
  -- @return:
  isOk       (bool) - operation success flag.
--]]
function unit.save (fullname, name, data, kind) --> (bool)
  kind = kind or {}
  local f, s, res = io_open(fullname, 'w')
  if f == nil then return nil, s end

  local write = function (...)
                  return f:write(...)
                end
  res, s = (kind.serialize or serialize)(name, data, kind, write)

  f:close()
  return res, s
end -- save

end -- do
do
  local select = select
  local tconcat = table.concat

-- Save data to string.
-- Сохранение данных в строку.
--[[
  -- @params:
  name     (string) - data table name.
  data      (t|nil) - processed data table.
  kind      (table) - kind of data save (@see serialize.kind).
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

                  return true -- t[n]
                end
  local res, s = (kind.serialize or serialize)(name, data, kind, write)

  if res == nil then return nil, s end

  return tconcat(t), s
end -- tostring

end -- do

---------------------------------------- history
local THistory = {} -- history class
local MHistory = { __index = THistory }

-- TODO: THistory methods.

function unit.history (name, kind) --> (object)

  local self = {
    name = name or "unknown",
    kind = kind or {},
  } --- self

  return setmetatable(self, MHistory)
end -- history

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
end -- customize

end -- do

--------------------------------------------------------------------------------
context.datas = unit -- 'datas' table in context
--------------------------------------------------------------------------------
