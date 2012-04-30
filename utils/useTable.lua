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
--[[ Часто используемые параметры:
  t      (table) - основная таблица.
  u      (table) - используемая таблица.
  list   (table) - список (всех) таблиц.
  value    (any) - значение поля таблицы.
  field (string) - название поля (мета)таблицы.
  usemeta (bool) - признак использования метатаблицы.
  tpairs  (func) - функция для получения значений таблицы.
  deep    (bool) - признак "глубокого" просмотра таблицы.
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
end --

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
end --
unit._update = _update

function unit.update (t, u, tpairs, deep) --|> (t)
  if u == nil then return t end
  local t = t or {}

  if deep then
    return _update(t, u, tpairs or pairs)
  end

  for k, v in (tpairs or pairs)(u) do t[k] = v end
  return t
end --

-- Extend table t by values from u.
-- Расширение таблицы t значениями из u.
local function _extend (t, u, tpairs) --|> (t)
  for k, v in tpairs(u) do
    if t[k] == nil then
      t[k] = type(v) == 'table' and _copy(v, false, tpairs) or v
    end
  end
  return t
end --
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
end --

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
end --
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
end --

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
end --
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
end ----

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
end --
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
end ----

do
  local kinds = {
    update = true,
    extend = true,
    expand = true,
    asmeta = true,
    exmeta = true,
  } ---

-- Add data from u to t.
-- Добавление данных из u в t.
--[[ Параметры:
  kind (string) - вид добавления (по умолчанию update):
                  'update' | 'extend' | 'expand' | 'asmeta' | 'exmeta'.
  ...           - дополнительные параметры для вызываемых функций:
    [1]    (bool) - "глубокий" просмотр таблицы.
    [2]  (string) - поле метатаблицы при 'asmeta': по умолчанию '__index'.
--]]
function unit.add (t, u, kind, tpairs, ...) --> (table)
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
end --

end -- do

---------------------------------------- pairs
-- Make list of all tables.
-- Формирование списка из всех таблиц.
function unit.list (t, list, field) --> (table)
  local list, field = list or {}, field or '__index'
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
end --

--[[ Warning:
  This version of 'pairs' supports using metatables for merging & inheritance.
  Use this function instead of 'pairs' for right search of all config fields.
--]]

do
  local t_list = unit.list

-- 'pairs' function with metatables support.
-- (Shmuel's implementation of allpairs, adapted for multimetas.)
--[[
  t   (table) - table for pairing.
  make (func) - function for make all tables related to t.
--]]
function unit.allpairs (t, make) --> (func)
  if not t then return end
  local list = (make or t_list)(t) -- tables list

  local n, k, v = #list
  local function _next ()
    while n > 0 do
      k, v = next(list[n], k)

      if k ~= nil then
        --[[
        -- Find field in previous tables:
        local m, f = n - 1, false
        while m > 0 do
          if rawget(list[m], k) ~= nil then
            f = true -- found
            break
          end
          m = m - 1 -- not found
        end

        if not f then return k, v, n end
        --]]
        local m = n - 1 -- Find field in previous tables:
        while m > 0 and rawget(list[m], k) == nil do m = m - 1 end
        if m <= 0 then return k, v, n end
      else
        n, list[n] = n - 1, nil
      end
    end
    --return nil, nil, 0
  end --

  return _next
end ---- allpairs

end -- do

-- 'pairs' function for non-hole arrays.
function unit.ipairs (t) --> (func)
  if not t then return end

  local k = 0
  local function _next ()
    k = k + 1
    if t[k] ~= nil then return k, t[k] end
    --return nil, nil, k - 1
  end --

  return _next
end ---- ipairs

-- 'pairs' function for arrays with preset size.
function unit.npairs (t, n) --> (func)
  if not t then return end

  local k, n = 0, n or #t
  local function _next ()
    k = k + 1
    if k <= n then return k, t[k] end
    --return nil, nil, n
  end --

  return _next
end ---- npairs

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
end --

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
end --

-- Fill nil values in array with value.
-- Заполнение значений nil в массиве значением value.
function unit.fillnils (t, count, value) --|> t
  --local value = value
  for k = 1, count or #t do
    if t[k] == nil then t[k] = value end
  end
  return t
end --

-- Fill nil values in { ... } with value.
-- Заполнение значений nil в { ... } значением value.
function unit.fillargs (value, ...)
  return unit.fillnils({ ... }, select('#', ...), value)
end ----

-- Concat args-strings to string.
-- Соединение списка параметров-строк в строку.
function unit.concat (...) --> (string)
  return table.concat(unit.fillargs('', ...), '\n')
end ----

-- Find a key for a value.
-- Поиск ключа для значения.
function unit.find (t, v, tpairs) --> (key | nil)
  for k, w in (tpairs or pairs)(t) do
    if w == v then return k end
  end
end ----

--------------------------------------------------------------------------------
context.tables = unit -- 'tables' table in context
--------------------------------------------------------------------------------
