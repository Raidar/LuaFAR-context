--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- Data serializing.
  -- Сериализация данных.
--]]
----------------------------------------
--[[ uses:
  LuaFAR,
  LF context.
  -- group: Datas.
--]]
----------------------------------------
--[[ some code from:
1. Serial: serial.lua.
  © Shmuel Zeigerman.
2. Table Serialization.
  URL: http://lua-users.org/wiki/TableSerialization
--]]
--------------------------------------------------------------------------------
local _G = _G

local type, unpack = type, unpack
local pairs = pairs
local tostring = tostring
local setmetatable = setmetatable

local string = string

local modf, frexp = math.modf, math.frexp
local format = string.format

----------------------------------------
--local context = context

local lua = require "context.utils.useLua"
local numbers = require 'context.utils.useNumbers'
local strings = require 'context.utils.useStrings'
local utils = require 'context.utils.useUtils'
local tables = require 'context.utils.useTables'

local LuaKeywords = lua.keywords
local KeywordMask = lua.KeywordMask

local MaxNumberInt = numbers.MaxNumberInt

local spaces = strings.spaces -- for ...ToText

----------------------------------------
-- [[
local log = require "context.samples.logging"
local logShow = log.Show
--]]

--------------------------------------------------------------------------------
local unit = {}

---------------------------------------- types
local BasicSerialTypes = {
  ["boolean"]   = true,
  ["number"]    = true,
  ["string"]    = true,
} --- BasicSerialTypes
unit.BasicSerialTypes = BasicSerialTypes

local DefaultSerialTypes = {
  __index = BasicSerialTypes,
  ["table"]     = true,
} --- DefaultSerialTypes
setmetatable(DefaultSerialTypes, DefaultSerialTypes)
unit.DefaultSerialTypes = DefaultSerialTypes

---------------------------------------- ValToStr/KeyToStr
-- Convert field value to string.
-- Преобразование значения поля в строку.
local function ValToStr (value) --> (string | nil, type)
  local tp = type(value)

  if tp == 'boolean' then return tostring(value) end

  if tp == 'number' then
    -- integer:
    if value == modf(value) and value <= MaxNumberInt then
      return tostring(value)
    end
    -- real:
    return format("(%.17f * 2^%d)", frexp(value)) -- preserve accuracy
    --return format("math.ldexp(%.17f, %d)", frexp(value)) -- preserve accuracy
  end

  if tp == 'string' then
    return ("%q"):format(value) -- "string"
  end

  return nil, tp
end -- ValToStr
unit.ValToStr = ValToStr

-- Convert key name to string.
-- Преобразование имени ключа в строку.
local function KeyToStr (key) --> (string[, string] | nil)
  local tp = type(key)
  if tp ~= 'string' then
    local key = ValToStr(key)
    if key then
      return format("[%s]", key)
    end

    return
  end

  if key:find(KeywordMask) and not LuaKeywords[key] then
    return "."..key, key -- .string
  end

  return ("[%q]"):format(key) -- ["string"]
end -- KeyToStr
unit.KeyToStr = KeyToStr

---------------------------------------- TabToStr
-- Convert table to string.
-- Преобразование таблицы в строку.
--[[
  -- @notes:
     Serialize data of following types: boolean, number, string, table.
  -- @params (@see unit.serialize).
  -- @return:
  isOk   (bool) - operation success flag.
--]]
local function TabToStr (name, data, kind, write) --| (write)

  -- 1. Write self-references:
  do
    local value = kind.saved[data]
    if value then -- saved name as value
      write(kind.indent, name, " = ", value, "\n")
      return
    end
    kind.saved[data] = name
    --logShow({ name, kind, data or "nil" }, "kind", 3)
  end

  -- 2. Settings to write current table:

  -- Settings to write keys/values:
  local KeyToStr = kind.KeyToStr
  local ValToStr = kind.ValToStr
  local TypToStr = kind.TypToStr

  -- Settings to data nesting:
  kind.level = kind.level + 1
  local cur_indent = kind.indent
  local new_indent = cur_indent..kind.shift
  kind.indent = new_indent

  local tname = kind.tname
  tname = (kind.level % 2 == 1) and tname or (tname == "t" and "u" or "t")

  -- 3. Write current table fields:
  local isnull = true
  for k, v in kind.pairs(data, unpack(kind.pargs)) do
    local s = KeyToStr(k, kind)
    if s then
      local u, tp = ValToStr(v, kind)
      if isnull and (u or tp == 'table' or TypToStr) then
        isnull = false
        write(cur_indent, format("do local %s = {}; %s = %s\n",
                                 tname, name, tname)) -- do
      end
      if u then
        -- boolean, number or string:
        write(new_indent, format("%s%s = %s\n", tname, s, u))
      else
        -- subtable or special type:
        if tp == 'table' then
          TabToStr(name..s, v, kind, write)
        elseif TypToStr then
          TypToStr(name..s, v, kind, write)
        end
      end
    end
  end -- for

  if isnull then
    write(cur_indent, name, " = {}")
  else
    write(cur_indent, "end") -- end
  end
  write(cur_indent, "\n")

  -- 4. Restore settings
  kind.level = kind.level - 1
  kind.indent = cur_indent

  return true
end -- TabToStr
unit.TabToStr = TabToStr

---------------------------------------- ValToText/KeyToText
local hex = numbers.hex
local i2s, r2s = numbers.i2s, numbers.r2s

-- Convert field value to pretty text.
-- Преобразование значения поля в читабельный текст.
--[[
  -- @notes:
     Convert value of following types: boolean, number, string.
  -- @params (@see unit.serialize and unit.TabToText):
  value   (any) - value to convert.
  kind  (table) - conversion kind: @fields additions:
    maxint    (n|nil) - max integer number to convert as integer value
                        (@default = numbers.MaxNumberInt);
                        it is not used when keyint/valint is specified.
    numwidth  (n|nil) - min width of number value in string.
    keyhex    (n|nil) - write integer keys as hexadecimal numbers.
    valhex    (n|nil) - write integer values as hexadecimal numbers.
    keyint  (b|n|nil) - write integer keys using tostring (true) or
                        define precision to convert (number) (@default = 14).
    valint  (b|n|nil) - write integer values using tostring (true) or
                        define precision to convert (number) (@default = 14).
    keyreal (b|n|nil) - write real keys using tostring (true) or
                        define precision to convert (number) (@default = 17).
    valreal (b|n|nil) - write real values using tostring (true) or
                        define precision to convert (number) (@default = 17).
    strlong (b|n|nil) - use long brackets for string formatting
                        (strlong as number - string length minimum).
    iskey      (bool) - @see kind.iskey in unit.KeyToText.
  -- @return:
  (s | nil,tp)  - string representation of value.
--]]
local function ValToText (value, kind) --> (string | nil, type)
  local tp = type(value)

  -- boolean:
  if tp == 'boolean' then
    return tostring(value)
  end

  if tp == 'number' then
    local iskey, f = kind.iskey
    -- integer:
    if iskey then f = kind.keyint else f = kind.valint end
    --if value == modf(value) then
    if value == modf(value) and
       (f or value <= (kind.maxint or MaxNumberInt)) then
      local w
      if iskey then w = kind.keyhex else w = kind.valhex end
      if w then -- hex:
        return hex(value, type(w) == 'number' and w or nil)
      end

      local s = i2s(value, f)
      w = (kind.numwidth or 0) - s:len()
      if w > 0 then -- align:
        return format("%s%s", spaces[w], s)
      end

      return s
    end -- integer

    -- real:
    if iskey then f = kind.keyreal else f = kind.valreal end
    return r2s(value, f)
  end -- number

  -- string:
  if tp == 'string' then
    -- using long brackets for values:
    if kind.strlong and kind.iskey and
       value:len() > kind.strlong and
       value:find("\n", 1, true) and
       not value:find("%s\n") and
       --not value:find("%[%[.-%]%]") and
       not value:find("[[", 1, true) and
       not value:find("]]", 1, true) then
      return format("[[\n%s]]", value) -- [[string]]
    end

    -- quoted:
    return ("%q"):format(value) -- "string"
  end

  return nil, tp
end -- ValToText
unit.ValToText = ValToText

-- Convert field key to pretty text.
-- Преобразование ключа поля в читабельный текст.
--[[
  -- @notes: @see unit.ValToText.
  -- @params (@see unit.serialize and unit.TabToText):
  value   (any) - value to convert.
  kind  (table) - conversion kind: @fields additions: none.
    -- @locals in kind:
    iskey      (bool) - flag for key of field (not value).
  -- @return:
  (s | nil,tp)  - string representation of value.
--]]
local function KeyToText (key, kind) --> (string[, string] | nil)
  local tp = type(key)

  -- boolean & number:
  if tp ~= 'string' then
    kind.iskey = true
    local key = ValToText(key, kind)
    kind.iskey = false
    if key then
      return format("[%s]", key)
    end

    return
  end

  -- string:
  if key:find(KeywordMask) and not LuaKeywords[key] then
    return "."..key, key -- .string
  end

  return ("[%q]"):format(key) -- ["string"]
end -- KeyToText
unit.KeyToText = KeyToText

---------------------------------------- TabToText
local sortpairs = tables.sortpairs
local statpairs = tables.statpairs

-- TODO: Support null value and Null table --> also to gatherstat!

-- Convert table to pretty text.
-- Преобразование таблицы в читабельный текст.
--[[
  -- @notes:
     Serialize data of following types: boolean, number, string, table.
  -- @params (@see unit.serialize, unit.KeyToText, unit.ValToText):
  kind  (table) - conversion kind: @fields additions:
    pargs[1]  (table) - sortkind for statpairs: @see tables.statpairs.
    tnaming    (bool) - use temporary names to access fields.
    astable    (bool) - write data as whole table ({ fields }).
    nesting   (n|nil) - max nesting level of data to convert.
    -- Linearization parameters:
    lining   (string) - write for lines fill (@see fields below):
                        "all", "array", "hash".
                        ~to write array:
    alimit      (n|f) - length limit for line.
    acount      (n|f) - max field count in line.
    awidth      (n|f) - min field width in line.
                        ~ to write hash:
    hlimit      (n|f) - length limit for line.
    hcount      (n|f) - max field count in line.
    hwidth      (n|f) - min field width in line.
    -- @locals in kind:
    nestless  (table) - nestless flags for nesting levels.
    isarray   (table) - flag of array-part of prior/current level table.
  -- @return:
  isOk   (bool) - operation success flag.
--]]
local function TabToText (name, data, kind, write) --| (write)

  local level = kind.level -- Prior level
  local fname = kind.fname or name
  local cur_indent = kind.indent

  -- 0. Init serialize:
  if level == 0 then
    kind.nestless = {}
    local nesting = kind.nesting
    if nesting then
       if type(nesting) ~= 'number' or nesting < 0 then
         kind.nesting = 0
       end
    end
  end

  -- 1. Write self-references:
  do
    local astable = kind.astable or
                    (kind.tnaming and level > 0 and kind.nestless[level])

    local saved = kind.saved --or {}
    local value = saved[data]
    if value then -- saved name as value
      if astable then
        -- Save self-reference + Write as comment
        saved[fname] = data
        if kind.isarray then
          write(cur_indent, format("false, -- %s\n", value))
        else
          write(cur_indent, format("%s = false, -- %s\n", name, value))
        end
      else
        write(cur_indent, format("%s = %s\n", name, value))
      end

      return
    end

    saved[data] = fname -- name

    -- Check nesting level:
    local nesting = kind.nesting
    if nesting and level > nesting then
      local tp = type(name)
      if astable then
        if kind.isarray then
          --logShow(kind, name, 1)
          write(cur_indent, format("{}, -- skip\n"))
        else
          write(cur_indent, format("%s = {}, -- skip\n", name))
        end
      else
        write(cur_indent, format("%s = {} -- skip\n", name))
      end
      return
    end
  end -- do

  -- 2. Settings to write current table:

  -- Settings to write keys/values:
  local KeyToStr = kind.KeyToStr
  local ValToStr = kind.ValToStr
  local TypToStr = kind.TypToStr

  -- Settings to data nesting:
  kind.level = kind.level + 1 -- Current level
  level = kind.level
  local isarray = kind.isarray
  local new_indent = cur_indent..kind.shift
  kind.indent = new_indent

  local sortkind = kind.pargs[1] or {}
  local sortnext = statpairs(data, sortkind, unpack(kind.pargs, 2))
  --logShow(sortkind.stats, "statpairs stats")

  -- Settings to check table nesting:
  local nestless = sortkind.stats['table'] == 0
  kind.nestless[level] = nestless
  nestless = kind.astable or nestless

  -- 3. Write current table fields:
  local skip = {}
  local isnull = true

  -- 3.1. Write array fields:
  if nestless then
    kind.isarray = true -- in array-part only

    -- Settings to write fields of array in one line:
    local islining = kind.lining == "all" or kind.lining == "array"
    local alimit, acount, awidth
    if islining then
      alimit, acount, awidth = kind.alimit, kind.acount, kind.awidth
      if type(alimit) == 'function' then alimit = alimit(name, data) end
      if type(acount) == 'function' then acount = acount(name, data) end
      if type(awidth) == 'function' then awidth = awidth(name, data) end
    end

    local l = 0 -- New line count-flag
    local cnt, len, indlen = 1, 0, new_indent:len()

    local k, v = 1, data[1]
    while v ~= nil do
      skip[k] = v
      local u, tp = ValToStr(v, kind)

      -- Set '{' of array/table to line:
      if isnull and (u or tp == 'table' or
                     TypToStr and tp ~= nil) then
        isnull = false
        if isarray then
          write(cur_indent, "{\n") -- {
        else
          write(cur_indent, name, " = {\n") -- {
        end
      end

      if u then
        -- boolean, number or string:
        if islining then
          l = l + 1
          cnt = cnt + 1
          local ulen = u:len()
          len = len + ulen + 2 -- for ' ' + ','
          -- Settings to align fields:
          local w, sp = (awidth or 0) - ulen, ""
          if w > 0 then
            len = len + w
            sp = spaces[w]
          end
          -- Write field:
          if l == 1 or
             acount and cnt > acount or
             alimit and len >= alimit then
            cnt = 1 -- First field in new line:
            len = indlen + ulen + 1 -- for ','
            write(l > 1 and "\n" or "",
                  new_indent, format("%s,%s", u, sp))
          else      -- Other fields in same line:
            write(format(" %s,%s", u, sp))
          end
        else
          write(new_indent, u, ",\n")
        end

      else
        -- subtable or special type:

        -- New line before:
        if islining then
          write("\n")
          l = 0
        end

        local s = KeyToStr(k, kind)
        kind.fname = fname..s
        if tp == 'table' then
          TabToText(s, v, kind, write)
        elseif TypToStr and tp ~= nil then
          TypToStr(s, v, kind, write)
        end
      end -- if u -- value

      k = k + 1
      v = data[k]
    end -- while

    if not isnull then
      -- Set '}' of array/table to new line:
      if islining then write("\n") end
      -- Separate array and hash parts by empty line:
      if sortkind.stats.main >= k then write("\n") end
    end

    kind.isarray = isarray -- Restore value
  end -- if nestless
  -- 3.1. --

  -- 3.2. Write hash/table fields:
  do
    kind.isarray = false -- in hash-part only

    local tname = kind.tname -- Different temp names for sequential levels
    tname = (level % 2 == 1) and tname or (tname == "t" and "u" or "t")

    -- Settings to write fields of hash in one line:
    local islining = kind.lining == "all" or kind.lining == "hash"
    local hlimit, hcount, hwidth
    if islining then
      hlimit, hcount, hwidth = kind.hlimit, kind.hcount, kind.hwidth
      if type(hlimit) == 'function' then hlimit = hlimit(name, data) end
      if type(hcount) == 'function' then hcount = hcount(name, data) end
      if type(hwidth) == 'function' then hwidth = hwidth(name, data) end
    end

    local l = 0 -- New line count-flag
    local cnt, len, indlen = 1, 0, new_indent:len()

    for k, v in sortnext do
      if not skip[k] then
        local s, c = KeyToStr(k, kind)
        c = nestless and c or s -- Check using dot
        --logShow({ nestless, s, c, kind }, name, 2)

        if s then
          local u, tp = ValToStr(v, kind)

          -- Set '{' of hash/table to line:
          if isnull and (u or tp == 'table' or
                         TypToStr and tp ~= nil) then
            isnull = false
            --logShow({ nestless, kind }, name, 2)
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

          local isspec = not BasicSerialTypes[type(k)]
          if isspec then kind.indent = cur_indent..'--' end

          if u then
            local new_indent = kind.indent
            -- boolean, number or string:
            if nestless then
              if islining then
                l = l + 1
                cnt = cnt + 1
                local culen = c:len() + u:len()
                len = len + culen + 5 -- for ' ' + ' = ' + ','
                -- Settings to align fields:
                local w, sp = (hwidth or 0) - culen, ""
                if w > 0 then
                  len = len + w
                  sp = spaces[w]
                end
                -- Write field:
                if l == 1 or
                   hcount and cnt > hcount or
                   hlimit and len >= hlimit then
                  cnt = 1 -- First field in new line:
                  len = indlen + culen + 4 -- for ' = ' + ','
                  write(l > 1 and "\n" or "",
                        new_indent, format("%s = %s,%s", c, u, sp))
                else      -- Other fields in same line:
                  write(format(" %s = %s,%s", c, u, sp))
                end
              else
                write(new_indent, format("%s = %s,\n", c, u))
              end
            else
              write(new_indent, format("%s%s = %s\n", tname, c, u))
            end

          else
            -- subtable or special type:

            -- New line before:
            if islining then
              if l > 0 then write("\n") end
              l = 0
            end
            kind.fname = fname..s

            local n = nestless and c or (kind.tnaming and tname or name)..c
            --if c == "subsubtable" then logShow(kind, name, 1) end

            if tp == 'table' then
              TabToText(n, v, kind, write)
            elseif TypToStr and tp ~= nil then
              TypToStr(n, v, kind, write)
            end
          end -- if u -- value

          if isspec then kind.indent = new_indent end
        end -- if s -- key
      end
    end -- for

    if not isnull then
      -- Set '}' of hash/table to new line:
      if islining and l > 0 then write("\n") end
    end
  end -- do
  -- 3.2. --

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

  -- 3.3. Write self-references:
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

  -- 4. Restore settings
  kind.level = kind.level - 1
  kind.isarray = isarray
  kind.indent = cur_indent

  -- 5. Done serialize:

  return true
end -- TabToText
unit.TabToText = TabToText

---------------------------------------- serialize
-- Serialize data.
-- Сериализация данных.
--[[
  -- @params:
  name (string) - data name.
  data  (table) - saved data.
  kind  (table) - serializion kind (@see kind in pairs and *ToStr):
    saved     (table) - tables already saved with its names.
    indent   (string) - initial indent value to write.
    shift    (string) - indent shift to pretty write fields.
    pairs      (func) - pairs function to get fields.
    pargs     (table) - array of arguments to call pairs.
    localret   (bool) - use 'local name = {} ... return name' structure.

    ValToStr   (func) - function to convert simple value to string.
    KeyToStr   (func) - function to convert field key to string.
    TabToStr   (func) - function to convert table to string.
    TypToStr   (func) - function to convert other types to string.
    -- @locals in kind:
    level    (number) - current level of nesting: 0+.
    fname    (string) - full name of table field.
    tname    (string) - temporary name of table for local access:
                        "t" or "u" - to prevent collision with data name.
  write  (func) - function to write data strings.
  -- @return:
  isOk   (bool) - operation success flag.
--]]
function unit.serialize (name, data, kind, write) --> (bool)
  local kind = kind or {}

  kind.KeyToStr = kind.KeyToStr or KeyToStr
  kind.ValToStr = kind.ValToStr or ValToStr

  local s, tp = kind.ValToStr(data, kind)
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

  kind.level = 0
  kind.fname = name
  kind.tname = (name == "t") and "u" or "t"

  if kind.localret then
    write(kind.indent, "local ", name, "\n\n")
  end;

  (kind.TabToStr or TabToStr)(name, data, kind, write)

  if kind.localret then
    write(kind.indent, "\nreturn ", name, "\n")
  end

  return true
end -- serialize

-- Serialize data to pretty text.
-- Сериализация данных в читабельный текст.
function unit.prettyize (name, data, kind, write) --> (bool)
  local kind = kind or {}
  --logShow(kind, "kind")

  kind.KeyToStr = kind.KeyToStr or KeyToText
  kind.ValToStr = kind.ValToStr or ValToText
  kind.TabToStr = kind.TabToStr or TabToText

  if kind.localret == nil then kind.localret = true end
  if kind.tnaming == nil then kind.tnaming = true end

  --logShow(kind)

  return unit.serialize(name, data, kind, write)
end ---- prettyize

--------------------------------------------------------------------------------
return unit
--------------------------------------------------------------------------------
