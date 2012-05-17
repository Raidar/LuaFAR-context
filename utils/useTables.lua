--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- Working with table.
  -- Работа с таблицей.
--]]
----------------------------------------
--[[ uses:
  LuaFAR,
  LF context.
  -- group: LFc utils, Datas.
--]]
--------------------------------------------------------------------------------
local _G = _G

local type = type
local next, pairs = next, pairs
local getmetatable, setmetatable = getmetatable, setmetatable
local rawget = rawget

local table = table

----------------------------------------
local context = context

----------------------------------------
--local logMsg = (require "Rh_Scripts.Utils.Logging").Message

--------------------------------------------------------------------------------
local unit = {}

---------------------------------------- Null
do
  local error = error

-- Null table implementation.
-- Реализация таблицы Null.
local TNull = {
  __newindex = function (t, k, v) --| (error)
    error("Attempt to update a Null table", 2)
  end,
  __metatable = "Null table",
} --- TNull
unit.Null = setmetatable({}, TNull)

end -- do

local Null = unit.Null -- Empty read-only table

---------------------------------------- ----
--[[
  -- @params (frequently used):
  t      (table) - main table.
  u      (table) - used table.
  list   (table) - (all) tables list.
  value    (any) - table field value.
  field (string) - (meta)table field name.
  usemeta (bool) - metatable using flag.
  tpairs  (func) - pairs-function to get fields values.
  deep    (bool) - table deep viewing falg.
--]]
---------------------------------------- base
do
  --local lenher = require "lenher"

-- Create table with narr array elements and nrec non-array elements.
-- Создание таблицы с narr элементами массива и nrec элементами не-массива.
function unit.create (narr, nrec) --> (table)
  --return lenher.createtable(narr, nrec)
  return { nil, nil, nil, nil, nil, nil, nil, nil } -- 8
--[[
  return not narr and {} or
         narr <= 1 and { nil } or
         narr <= 2 and { nil, nil } or
         narr <= 4 and { nil, nil, nil, nil } or
         narr <= 8 and { nil, nil, nil, nil, nil, nil, nil, nil } or
         --narr <= 16 and
         { nil, nil, nil, nil, nil, nil, nil, nil,
           nil, nil, nil, nil, nil, nil, nil, nil } -- 16
--]]
--[[
  -- Common (but slow) table creating:
  return loadstring("return {"..
                    ("nil,"):rep(narr)..
                    ("[0] = nil,"):rep(nrec).."}")()
--]]
end ---- create

end -- do

-- Is a table empty?
function unit.isempty (t) --> (bool)
  return t == nil or next(t) == nil
end ----

---------------------------------------- find
-- Find a key for a value.
-- Поиск ключа для значения.
function unit.find (t, v, tpairs) --> (key | nil)
  for k, w in (tpairs or pairs)(t) do
    if w == v then return k end
  end
end ----

do
  local modf = math.modf

-- Binary find of fitting position in sorted array.
-- Двоичный поиск подходящей позиции в отсортированном массиве.
--[[
  -- @params:
  t     (table) - table to find in.
  v      (~nil) - value to find for.
  comp   (func) - function to compare.
  -- @return:
  index (number) - fitting position for value.
--]]
function unit.fitfind (t, v, comp) --> (index: 1..#t+1)
  local min, max = 1, #t + 1
  while max - min > 0 do
    local m = modf((max + min) / 2) -- TODO: optimize
    if comp(t[m], v) then
      min = m + 1
    else
      max = m
    end
  end

  return max
end ---- fitfind

-- Binary find in sorted array.
-- Двоичный поиск в отсортированном массиве.
function unit.bfind (t, v, comp) --> (index | nil)
  local i = fitfind(t, v, comp)
  return v == t[i] and i or nil
end ---- bfind

end -- do

---------------------------------------- copy

-- Simple copy of table without links to one and the same table.
-- Простая копия таблицы без учёта ссылок на одну и ту же таблицу.
-- WARNING: There is no support of key-subtables and cycles!
local function _copy (t, usemeta, tpairs) --> (table)
  local u = {}
  for k, v in tpairs(t) do
    u[k] = type(v) == 'table' and _copy(v, usemeta, tpairs) or v
  end
  return usemeta and setmetatable(u, getmetatable(t)) or u
end --
unit._copy = _copy

function unit.copy (t, usemeta, tpairs, deep) --> (table)
  if t == nil then return end

  if deep then
    return _copy(t or {}, usemeta, tpairs or pairs)
  end

  local u = {}
  for k, v in (tpairs or pairs)(t) do u[k] = v end

  return usemeta and setmetatable(u, getmetatable(t)) or u
end ---- copy

-- Copy of table with possible saving all metatables.
-- Копия таблицы с возможным сохранением всех метатаблиц.
function unit.clone (t, usemeta, tpairs) --> (table)
  local tpairs = tpairs or pairs
  local Lookup = {} -- Список уже скопированных таблиц

  local function _clone (t, usemeta)
    if type(t) ~= 'table' then return t
    elseif Lookup[t] then return Lookup[t] end

    local u = {}
    Lookup[t] = u -- Внесение в список / Копирование ключей и значений:
    for k, v in tpairs(t) do u[_clone(k)] = _clone(v, usemeta) end

    return usemeta and setmetatable(u, getmetatable(t)) or u
  end --function _clone

  return _clone(t, usemeta)
end ---- clone

---------------------------------------- change
-- Update table t by values from u.
-- Обновление таблицы t значениями из u.
local function _update (t, u, tpairs) --|> (t)
  for k, v in tpairs(u) do
    if type(v) == 'table' then
      if type(t[k]) == 'table' then
        _update(t[k], v, tpairs)
      else
        t[k] = _copy(v, false, tpairs)
      end
    else
      t[k] = v
    end
  end

  return t
end -- _update
unit._update = _update

function unit.update (t, u, tpairs, deep) --|> (t)
  if u == nil then return t end
  local t = t or {}

  if deep then
    return _update(t, u, tpairs or pairs)
  end

  for k, v in (tpairs or pairs)(u) do t[k] = v end

  return t
end ---- update

-- Extend table t by values from u.
-- Расширение таблицы t значениями из u.
local function _extend (t, u, tpairs) --|> (t)
  for k, v in tpairs(u) do
    if t[k] == nil then
      t[k] = type(v) == 'table' and _copy(v, false, tpairs) or v
    end
  end

  return t
end -- _extend
unit._extend = _extend

function unit.extend (t, u, tpairs, deep) --|> (t)
  if u == nil then return t end
  local t = t or {}

  if deep then
    return _extend(t, u, tpairs or pairs)
  end

  for k, v in (tpairs or pairs)(u) do
    if t[k] == nil then t[k] = v end
  end

  return t
end ---- extend

-- Expand table t by values from u (using subvalues).
-- Наращение таблицы t значениями из u (с учётом подзначений).
local function _expand (t, u, tpairs) --|> (t)
  for k, v in tpairs(u) do
    local w, tp = t[k], type(v)
    if w == nil then
      t[k] = tp == 'table' and _copy(v, false, tpairs) or v
    elseif tp == 'table' and type(w) == 'table' then
      _expand(w, v, tpairs)
    end
  end

  return t
end -- _expand
unit._expand = _expand

function unit.expand (t, u, tpairs, deep) --|> (t)
  if u == nil then return t end
  local t = t or {}

  if deep then
    return _expand(t, u, tpairs or pairs)
  end

  for k, v in (tpairs or pairs)(u) do
    if t[k] == nil then t[k] = v end
  end

  return t
end -- expand

-- Set table u as field f of metatable for t.
-- Установка таблицы u как поля f метатаблицы для t.
local function _asmeta (t, u, tpairs, field, force) --|> (t)
  for k, v in tpairs(u) do
    if type(v) == 'table' and type(t[k]) == 'table' then
      _asmeta(t[k], v, tpairs, field)
    end
  end
  --if (t or {}).TabSize then logMsg({ tdef = t, udef = u }, "asmeta", 3) end
  --if (t.default or {}).TabSize then logMsg({ tdef = t.default, udef = u.default }, "asmeta", 3) end

  local m = getmetatable(t) or {}
  if m[field] and not force then return t end

  m[field] = u
  return setmetatable(t, m)
end -- _asmeta
unit._asmeta = _asmeta

function unit.asmeta (t, u, tpairs, deep, field, force) --|> (t)
  local t = t or {}
  if u == nil then return t end

  --if (t.default or {}).TabSize then logMsg({ t = t, u = u, deep = deep, field = field }, "asmeta", 3) end
  if deep then
    return _asmeta(t, u, tpairs or pairs, field or '__index')
  end

  local m = getmetatable(t) or {}
  if m[field] and not force then return t end

  m[field or '__index'] = u
  return setmetatable(t, m)
end ---- asmeta

-- Set table u as field f of metatable for t (expanding subvalues).
-- Установка таблицы u как поля f метатаблицы для t (с наращением подзначений).
local function _exmeta (t, u, tpairs, field, force) --|> (t)
  for k, v in tpairs(u) do
    if type(v) == 'table' then
      if t[k] == nil then t[k] = {} end
      if type(t[k]) == 'table' then
        _exmeta(t[k], v, tpairs, field)
      end
    end
  end

  local m = getmetatable(t) or {}
  if m[field] and not force then return t end

  m[field] = u
  return setmetatable(t, m)
end -- _exmeta
unit._exmeta = _exmeta

function unit.exmeta (t, u, tpairs, deep, field, force) --|> (t)
  local t = t or {}
  if u == nil then return t end

  if deep then
    return _exmeta(t, u, tpairs or pairs, field or '__index')
  end

  local m = getmetatable(t) or {}
  if m[field] and not force then return t end

  m[field or '__index'] = u
  return setmetatable(t, m)
end ---- exmeta

do
  local kinds = {
    change = true,
    update = true,
    extend = true,
    expand = true,
    asmeta = true,
    exmeta = true,
  } ---

-- Add data from u to t.
-- Добавление данных из u в t.
--[[
  -- @params:
  kind (string) - kind of addition (@default = 'update'): @see kinds.
  ...           - additional parameters for called functions:
    [1]    (bool) - "deep" view of table.
    [2]  (string) - metatable field for 'asmeta' (@default = '__index').
--]]
function unit.add (t, u, kind, tpairs, ...) --> (table)
  if kind == 'change' then
    return u
  end

  local t = t or {}
  if u == nil then return t end

  kind, tpairs = kind or 'update', tpairs or pairs
  if not kinds[kind] then return t end

  if kind == 'asmeta' then
    return unit.asmeta(t, u, tpairs, ...)
  else
    return unit[kind](t, u, tpairs, ...)
  end --

  return t
end ---- add

end -- do

---------------------------------------- pairs
-- 'pairs' function for non-hole arrays.
-- Функция 'pairs' для массивов без "дыр".
function unit.ipairs (t) --> (func)
  if not t then return end

  local k = 0
  local function _next ()
    k = k + 1
    if t[k] ~= nil then
      return k, t[k]
    end
    --return nil, nil, k - 1
  end --

  return _next
end ---- ipairs

-- 'pairs' function for arrays with preset size.
-- Функция 'pairs' для массивов с заданным размером.
function unit.npairs (t, n) --> (func)
  if not t then return end

  local k, n = 0, n or #t
  local function _next ()
    k = k + 1
    if k <= n then
      return k, t[k]
    end
    --return nil, nil, n
  end --

  return _next
end ---- npairs

do
  local ipairs = ipairs

-- 'pairs' function for hashes only.
-- Функция 'pairs' только для хешей.
function unit.hpairs (t) --> (func)
  if not t then return end

  local skip = {}
  for i in ipairs(t) do skip[i] = true end

  local k
  local function _next ()
    local v
    repeat
      k, v = next(t, k)
    until k == nil or not skip[k]

    return k, v
  end

  return _next
end ---- hpairs

end -- do

---------------------------------------- allpairs
-- Make list of all tables.
-- Формирование списка из всех таблиц.
function unit.list (t, list, field) --> (table)
  local t, list = t, list or {}
  local field = field or '__index'
  --local field = field ~= false and (field or '__index')
  if type(t) ~= 'table' then return list end

  if not list[t] then
    list[t], list[#list+1] = true, t
  end
  t = getmetatable(t)
  t = type(t) == 'table' and t[field]

  while type(t) == 'table' and not list[t] do
    list[t], list[#list+1] = true, t
    t = getmetatable(t)
    t = type(t) == 'table' and t[field]
  end

  return list
end ---- list

--[[ Warning:
  This version of 'pairs' supports using metatables for merging & inheritance.
  Use this function instead of 'pairs' for right search of all config fields.
--]]
do
  local t_list = unit.list

-- 'pairs' function with metatables support.
-- (Shmuel's implementation of allpairs, adapted for multimetas.)
--[[
  -- @params:
  t     (table) - table for pairing.
  make   (func) - function for make all tables related to t.
  ...           - parameters to call make(t, ...).
--]]
function unit.allpairs (t, make, ...) --> (func)
  if not t then return end
  local list = (make or t_list)(t, ...) -- tables list

  local n, k, v = #list
  local function _next ()
    while n > 0 do
      k, v = next(list[n], k)

      if k ~= nil then
        local m = n - 1 -- Find in previous tables:
        while m > 0 and rawget(list[m], k) == nil do
          m = m - 1
        end
        if m <= 0 then
          --logMsg({ n, k, v }, "next")
          return k, v, n -- Not found --> pairing
        end
      else
        n, list[n] = n - 1, nil
      end
    end
    --return nil, nil, 0
  end --

  return _next
end ---- allpairs

end -- do

---------------------------------------- sortpairs
-- Compare values for table sort.
-- Сравнение значений для сортировки таблицы.
function unit.sortcompare (v1, v2) --> (bool)
  local t1, t2 = type(v1), type(v2)

  -- 1 -- true/false
  if t1 == 'boolean' then
    if t2 ~= 'boolean' then return true end
    return v1
  end

  -- 2 -- number
  if t1 == 'number' then
    if t2 ~= 'number' then return t2 ~= 'boolean' end
    return v1 < v2
  end

  -- 3 -- string
  if t1 == 'string' then
    if t2 ~= 'string' then return t2 ~= 'boolean' and t2 ~= 'number' end
    -- 3.1 -- one letter string
    local l1, l2 = v1:len(), v2:len()
    if l1 == 1 then return l2 > 1 or v1 < v2 end
    if l2 == 1 then return l1 == 1 and v1 < v2 end
    -- 3.2 -- other string
    return v1 < v2
  end

  -- 4 -- other
  return false
end ---- sortcompare

do
  local t_find = unit.fitfind
  local t_insert = table.insert

-- 'pairs' function with field sort.
-- Функция 'pairs' с сортировкой полей.
--[[
  -- @params:
  t     (table) - table for pairing.
  make (func) - function for make all tables related to t.
  kind  (table) - additional parameters for sort:
    pairs    (func) - pairs-function to get fields.
    compare  (func) - function to compare field names.
  ...           - parameters to call kind.pairs(t, ...).
--]]
function unit.sortpairs (t, kind, ...) --> (func)
  if not t then return end

  local kind = kind or {}
  local compare = kind.compare or unit.sortcompare

  local names = {}
  local values = {}

  for k, v in (kind.pairs or pairs)(t, ...) do
    values[k] = v
    local i = t_find(names, k, compare)
    t_insert(names, i, k)
  end

  local k = 0
  local function _next ()
    k = k + 1
    local m = names[k]
    if m ~= nil then
      return m, values[m]
    end
  end --

  return _next
end ---- sortpairs

  local lua -- useLua unit

-- Gather simple statistics.
-- Сбор элементарной статистики.
--[[
  -- @params:
  k         (any) - table key (k == nil --> call for init).
  v         (any) - table value (v == t --> call for init).
  kind    (table) - additional parameters (@see unit.statpairs.kind).
  -- @return:
    -- @return in kind:
    stats (table) - required statistics.
--]]
function unit.gatherstat (k, v, kind) --| kind.stats
  if k == nil then
    local stats = kind.stats or {}
    kind.stats = stats
    if v ~= nil then
      -- Init --
      local gathered = kind.gathered
      if not lua then lua = require 'context.utils.useLua' end

      for k, _ in pairs(lua.types) do
        if gathered then
          stats[k] = stats[k] or 0
        else
          stats[k] = 0
        end
      end

    else
      -- Done --
      stats.main = stats["boolean"] + stats["number"] +
                   stats["string"] + stats["table"]
    end -- Init/Done

    return
  end

  local tp = type(v)
  kind.stats[tp] = kind.stats[tp] + 1
  --return tp
end ---- gatherstat

-- 'sortpairs' function with gathering some statistics.
-- Функция 'sortpairs' со сбором некоторой статистики.
--[[
  -- @params:
  t     (table) - table for pairing.
  make (func) - function for make all tables related to t.
  kind  (table) - additional parameters for sort:
    pairs    (func) - pairs-function to get fields.
    compare  (func) - function to compare field names.
    gather   (func) - function to gather statistics.
    gathered (bool) - gathered statistics (@default = false).
  ...           - parameters to call kind.pairs(t, ...).
  -- @return:
    -- @return in kind (@see unit.gatherstat.kind).
--]]
function unit.statpairs (t, kind, ...) --| kind --> (func)
  if not t then return end

  assert(type(kind) == 'table')
  local compare = kind.compare or unit.sortcompare
  local gather = kind.gather or unit.gatherstat

  gather(nil, t, kind) -- Init

  local names = {}
  local values = {}

  for k, v in (kind.pairs or pairs)(t, ...) do
    values[k] = v

    gather(k, v, kind) -- Gather stats

    local i = t_find(names, k, compare)
    t_insert(names, i, k)
  end

  gather(nil, nil, kind) -- Done

  local k = 0
  local function _next ()
    k = k + 1
    local m = names[k]
    if m ~= nil then
      return m, values[m]
    end
  end --

  return _next
end ---- statpairs

end -- do

---------------------------------------- fill

-- Fill values in array with value.
-- Заполнение значений в массиве значением value.
function unit.fillwith (t, count, value) --|> t
  local value = value

  if type(value) ~= 'function' then
    for k = 1, count or #t do t[k] = value end
  else
    for k = 1, count or #t do t[k] = value(t, k) end
  end

  return t
end -- fillwith

-- Fill nil values in array with value.
-- Заполнение значений nil в массиве значением value.
function unit.fillnils (t, count, value) --|> t
  --local value = value
  for k = 1, count or #t do
    if t[k] == nil then t[k] = value end
  end

  return t
end -- fillnils

-- Fill nil values in { ... } with value.
-- Заполнение значений nil в { ... } значением value.
function unit.fillargs (value, ...)
  return unit.fillnils({ ... }, select('#', ...), value)
end ----

---------------------------------------- others

-- Get value t[k] checking field of metatable.
-- Получение значения t[k] проверкой поля метатаблицы.
function unit.t_index (t, k, field) --> (value)
  if t == nil then return end
  local u = (getmetatable(t) or Null)[field or '__index']
  if u == nil then return end

  local tp = type(u)
  if tp == 'table'    then return u[k] end
  if tp == 'function' then return u(t, k) end

  return u
end ---- t_index

-- Concat args-strings to string.
-- Соединение списка параметров-строк в строку.
function unit.concat (...) --> (string)
  return table.concat(unit.fillargs('', ...), '\n')
end ----

--------------------------------------------------------------------------------
context.tables = unit -- 'tables' table in context
return unit
--------------------------------------------------------------------------------
