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

local type = type
local pairs = pairs
local unpack = unpack
local tostring = tostring

local string = string

----------------------------------------
local context = context
local lua = context.lua
--local utils = context.utils
local tables = context.tables

----------------------------------------
--local logMsg = (require "Rh_Scripts.Utils.Logging").Message

--------------------------------------------------------------------------------
local unit = {}

----------------------------------------
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
      return format("[[\n%s]]", value) -- [[string]]
    end
    return ("%q"):format(value) -- "string"
  end

  return nil, tp
end -- ValToStr
unit.ValToStr = ValToStr

local reserveds = lua.keywords
local KeywordMask = lua.KeywordMask

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
      local u, tp = ValToStr(v, strlong)
      if isnull and (u or tp == 'table') then
        isnull = false
        write(cur_indent, format("do local %s = {}; %s = %s\n",
                                 tname, name, tname)) -- do
      end
      if u then
        write(new_indent, format("%s%s = %s\n", tname, s, u))
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

---------------------------------------- TabToText
local srep = string.rep
local sortpairs = tables.sortpairs
local statpairs = tables.statpairs

local spaces = {
} ---

-- Convert table to pretty text.
-- Преобразование таблицы в читабельный текст.
--[[
  -- @notes:
     Serialize data of following types: boolean, number, string, table.
  -- @params (@see unit.serialize):
  kind  (table) - conversion kind: @fields additions:
    pargs[1]  (table) - sortkind for statpairs (@see tables.statpairs).
    tnaming    (bool) - using temp names to access fields.
    astable    (bool) - write data as whole table ({ fields }).
    -- Linearization parameters:
    lining   (string) - write to fill lines (@see 3+3 fields below).
                        ~to write array:
    alimit   (number) - length limit for line.
    acount   (number) - max field count in line.
    awidth   (number) - min field width in line.
                        ~ to write hash:
    hlimit   (number) - length limit for line.
    hcount   (number) - max field count in line.
    hwidth   (number) - min field width in line.
  -- @return:
  isOk   (bool) - operation success flag.
--]]
local function TabToText (name, data, kind, write) --| (write)

  local level = kind.level -- Prior level
  local fname = kind.fname or name

  -- 1. Write self-references:
  do
    local saved = kind.saved --or {}
    local value = saved[data]
    if value then -- saved name as value
      if kind.astable or (kind.tnaming and
         (level > 1 and kind.nestless[level])) then
        -- Save self-reference + Write as comment
        saved[fname] = data
        if kind.isarray then
          write(kind.indent, "false, -- ", value, "\n")
        else
          write(kind.indent, format("%s = false, -- %s\n", name, value))
        end
      else
        write(kind.indent, format("%s = %s\n", name, value))
      end

      return
    end

    saved[data] = fname -- name
  end -- do

  -- 2. Settings to write current table:
  kind.level = kind.level + 1 -- Current level
  level = kind.level

  local cur_indent = kind.indent
  local new_indent = cur_indent..kind.shift
  kind.indent = new_indent

  local sortkind = kind.pargs[1] or {}
  local sortnext = statpairs(data, sortkind, unpack(kind.pargs, 2))
  --logMsg(sortkind.stats, "statpairs stats")

  -- Settings to check table nesting
  if level == 1 then kind.nestless = {} end
  local nestless = sortkind.stats['table'] == 0
  kind.nestless[level] = nestless
  nestless = kind.astable or nestless

  -- 3. Write current table fields:
  local skip = {}
  local isnull = true

  local isarray = kind.isarray -- Save value

  -- 3.1. Write array only fields:
  if nestless then
    kind.isarray = true -- in array-part only

    -- Settings to write fields of array in one line
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
      local u, tp = ValToStr(v)

      -- Set '{' of array/table to line:
      if isnull and (u or tp == 'table') then
        isnull = false
        if isarray then
          write(cur_indent, "{\n") -- {
        else
          write(cur_indent, name, " = {\n") -- {
        end
      end

      if u then
        if islining then
          l = l + 1
          cnt = cnt + 1
          local ulen = u:len()
          len = len + ulen + 2 -- for ' ' + ','
          -- Settings to align fields:
          local w, sp = awidth or 0, ""
          w = w - ulen
          if w > 0 then
            len = len + w
            sp = spaces[w]
            if not sp then
              sp = srep(" ", w)
              spaces[w] = sp
            end
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
      elseif tp == 'table' then
        -- New line before subtable:
        if islining then
          write("\n")
          l = 0
        end
        local s = KeyToStr(k)
        kind.fname = fname..s
        TabToText(s, v, kind, write)
      end

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
    local tname = kind.tname -- Different temp names for sequential levels
    tname = (level % 2 == 1) and tname or (tname == "t" and "u" or "t")

    -- Settings to write fields of hash in one line
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
        local s, c = KeyToStr(k)
        c = nestless and c or s -- Check using dot
        --logMsg({ nestless, s, c, kind }, name, 2)

        if s then
          local u, tp = ValToStr(v)
          -- Set '{' of hash/table to line:
          if isnull and (u or tp == 'table') then
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

          if u then
            if nestless then
              if islining then
                l = l + 1
                cnt = cnt + 1
                local culen = c:len() + u:len()
                len = len + culen + 5 -- for ' ' + ' = ' + ','
                -- Settings to align fields:
                local w, sp = hwidth or 0, ""
                w = w - culen
                if w > 0 then
                  len = len + w
                  sp = spaces[w]
                  if not sp then
                    sp = srep(" ", w)
                    spaces[w] = sp
                  end
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
          elseif tp == 'table' then
            -- New line before subtable:
            if islining then
              if l > 0 then write("\n") end
              l = 0
            end
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

  -- 4. Write self-references:
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

  -- 5. Restore settings
  kind.level = kind.level - 1 -- Prior level
  kind.indent = cur_indent

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

--------------------------------------------------------------------------------
context.serial = unit -- 'serial' table in context
--------------------------------------------------------------------------------
