--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- Type detecting.
  -- Определение типа.
--]]
----------------------------------------
--[[ uses:
  LuaFAR,
  LF context.
  -- group: LFc utils.
  -- areas: basic.
--]]
--------------------------------------------------------------------------------
local _G = _G

local assert = assert
local pairs = pairs

----------------------------------------
local context, ctxdata = context, ctxdata
local types = ctxdata.config.types

local utils = context.utils
local tables = context.tables
local datas  = context.datas
local cfgpairs = datas.cfgpairs

local Null = tables.Null

--------------------------------------------------------------------------------
local unit = {}

----------------------------------------
local Custom = {
  label = "mDet",
  name = "utils",
  path = "context.utils.",
  locale = { kind = 'require' },
} ---
local L, e1, e2 = context.locale.create(Custom)
if L == nil then
  return context.locale.showError(e1, e2)
end

-- Messages
local Msgs = {
  UnknownType = 'none',
  UnknownArea = 'unknown',
} ---

---------------------------------------- Base
local pcall = pcall
-- Mask & first line find function.
local sfind = ('').cfind -- Slow but char positions return
--local sfind = ('').find -- Fast but byte positions return

-- Protected find of pattern in string for file type.
-- Защищённый поиск паттерна в строке для типа файла.
local function pfind (s, pattern) --> (number, number | nil)
  if not s then return end
  local isOk, findpos, findend = pcall(sfind, s, pattern)
  if isOk then return findpos, findend end -- Успешный поиск
end --

-- Check skipped lines of file.
-- Проверка на пропускаемые линии файла.
local function checkSkipLines (line) --> (string | nil)
  local skiplines = (types.ignore or Null).skiplines
  if not skiplines then return end

  for k, v in pairs(skiplines) do
    if pfind(line, k) then return v end
  end
end --
unit.checkSkipLines = checkSkipLines

-- Read a first line from file.
-- Чтение первой линии из файла.
function unit.readFileFirstLine (filename) --> (string, string|nil | nil)
  --far.Message(filename)
  local f = io.open(filename)
  if not f then return end

  local line, assumed
  repeat
    line = f:read("*l")
    if not line then break end
    local check = checkSkipLines(line)
    if check and not assumed then assumed = check end
  until check == nil

  f:close()
  --far.Message(line, assumed)

  return line, assumed
end --

do
  local EditorGetStr = far.EditorGetString

-- Read a first line from file in editor.
-- Чтение первой линии из файла в редакторе.
function unit.readEditorFirstLine () --> (string, string|nil | nil)
  local k, line, assumed = 0
  local Info = far.EditorGetInfo()

  repeat
    line = EditorGetStr(nil, k, 2)
    local check = checkSkipLines(line)
    if check and not assumed then assumed = check end
    k = k + 1
  until check == nil

  far.EditorSetPosition(nil, Info) -- Restore cursor pos!
  --far.Message(tostring(Info.CurLine)..'\n'..tostring(Info.CurPos), 'Info')

  return line, assumed
end --

end -- do

---------------------------------------- Pass
-- Check a value by values table.
-- Проверка значения по таблице значений.
local function checkValueOver (value, values) --> (number | nil)
  if not values then return nil end
  if type(values) == 'string' then values = { values } end

  for k = 1, #values do
    local v = values[k]
    local findpos, findend = pfind(value, v)
    if findpos then
      return findend - findpos + 1, v -- + 1 for real length
    end
  end
end --function checkValueOver
unit.checkValueOver = checkValueOver

-- Detect a type by filename and first line (on single pass).
-- Определяет тип по имени файла и первой линии (при одном проходе).
local function detTypePass (f) --> (typeName, detKind, detValues) or
                               --  ('none',   detKind, detInfo)   or (nil)
  local fname, f_ext, fline = f.name or f.filename, f.ext, f.firstline

  -- 1. Расчёт подходящих типов.

  -- Хранение лучших типов:
  local bmaskwei, bmasklen, bmask, bmaskidx = 1, 0 -- по маске без наличия 1-й линии
  local blinewei, blinelen, bline, blineidx = 1, 0 -- по 1-й линии без учёта маски
  local dtypewei, dmasklen, dmask,                 -- сразу по маске и 1-й линии
                  dlinelen, dline, dtypeidx = 1, 0, "", 0, ""

  --local checkname -- DEBUG
  --checkname = "with_fl2"
  --checkname = "with_cfg.lua"
  --checkname = "with_cfg.cfg"
  --checkname = "with_fl2.cfg"
  --checkname = "with_lua.lum"
  --checkname = "def_file.tst"
  --checkname = "with_fl2.t_t"
  --checkname = "with_fl2.tst"

  -- Отбор по всем параметрам типов.
  for k, v in cfgpairs(types) do
    local w = v.weight or 1                         -- Учёт веса
    local lines, sines = v.firstline, v.strongline  -- Учёт линий

    -- Текущая длина совпадения и подошедший шаблон:
    local mlen, mask
    if w >= bmaskwei or w >= dtypewei then
      mlen, mask = checkValueOver(fname, v.masks)   -- Маска
    end
    local llen, line
    if fline and lines and w >= blinewei then
      llen, line = checkValueOver(fline, lines)     -- Обычная линия
    end
    local slen, sine
    if fline and sines and w >= blinewei then
      slen, sine = checkValueOver(fline, sines)     -- Строгая линия
    end

    --local t = { k, mlen, mask, llen, line } -- DEBUG
    --[[
    if checkname and fname == checkname and (mlen or llen) then
      logMsg(t, "Types: pass ["..fname.."]", 1)
    end
    --]]

    if mlen then
      -- Учёт только маски:
      if not (sines or lines) and mlen > bmasklen then
        bmasklen, bmask, bmaskwei, bmaskidx = mlen, mask, w, k
      end
      -- Учёт сразу маски и 1-й линии:
      if not lines or mlen >= dmasklen then         -- Учёт длины маски
        --[[
        if checkname and fname == checkname and (mlen or llen) then
          logMsg(t, "Types: pass ["..fname.."]", 1)
        end
        --]]

        -- Если нет подходящих типов:
        if not (slen or llen) and dlinelen <= 0 then
          dmasklen, dmask, dtypewei = mlen, mask, w-1 -- (вес ниже! - maxdrfl)
          dlinelen, dline, dtypeidx = 0, "", k
        elseif slen and slen > dlinelen then        -- Учёт длины строгой линии
          dmasklen, dmask, dtypewei = mlen, mask, w
          dlinelen, dline, dtypeidx = slen, sine, k
        elseif llen and llen > dlinelen then        -- Учёт длины обычной линии
          dmasklen, dmask, dtypewei = mlen, mask, w
          dlinelen, dline, dtypeidx = llen, line, k
        end
      end
    end -- if mlen

    if sines and slen and slen > blinelen then      -- Учёт только строгой линии:
      --if checkname and fname == checkname then logMsg(t, "Types: pass ["..fname.."]", 1) end
      blinelen, bline, blinewei, blineidx = slen, sine, w, k
    end -- if llen
  end --

  --[[
  if checkname and fname == checkname then
    local t = {}
    t.param = { fline, forceline or nil }
    --t.param = { fname, f_ext, fline, forceline }
    t.bmask = { bmasklen, bmask, bmaskwei, bmaskidx }
    t.bline = { blinelen, bline, blinewei, blineidx }
    t.dtype = { dmasklen, dmask, dtypewei, dlinelen, dline, dtypeidx }
    logMsg(t, "Types: pass ["..fname.."]", 1)
  end -- if
  --]]

  -- 2. Отбор из трёх вариантов:
  if dmasklen <= 0 --[[and dlinelen <= 0]] and blinelen > 0 then
    return blineidx, 'pass+byline', bline, blinelen
  end
  if (bmasklen <= 0 or fline and dtypewei >= bmaskwei) and dmasklen > 0 then
    return dtypeidx, 'pass+best', dmask, dline
  end
  if bmasklen > 0 then
    return bmaskidx, 'pass+bymask', bmask, bmasklen
  end
  if f.assumed then
    return f.assumed, 'read+line', f_ext, 0
  end
  return 'none', 'pass+worse', f_ext, 1 -- It is possible!
end --function detTypePass
unit.TypePass = detTypePass

-- Detect a type by filename and first line.
-- Определяет тип по имени файла и первой линии.
local function detectType (f) --> (see detTypePass)
  --logMsg(f, "detType", 1)
  if not types then return end

  local ff = { __index = f }; setmetatable(ff, ff)

  local fname = f.name or f.filename
  if not fname or fname == "" then return 'none', 'none', fname end

  if not f.matchcase then fname = fname:lower() end

  ff.name, ff.ext = fname, fname:match('(%.[^%.]+)$') or fname
  ff.forceline = f.firstline and f.forceline
  --ff.forceline = f.firstline and (f.forceline or
  --               not fname:find('.', 1, true) or fname:sub(1, 1) == '.')

  return detTypePass(ff)
end --
unit.FileType = detectType

---------------------------------------- Detect
local areaFileType = {} -- Detect filetype in area
unit.area = areaFileType

local PathNamePattern = '^(.-)([^\\/]+)$'

-- Detect a type of file in active panel.
function areaFileType.panels (f)
  local f = f or {}

  if not f.filename then
    local Info = far.CtrlGetPanelInfo(nil, 1)
    if Info.ItemNumbers == 0 then return 'empty' end
    local Item = far.CtrlGetCurrentPanelItem(nil, 1)
    f.path, f.name = far.CtrlGetPanelDir(nil, 1), Item.FileName
    --far.Message(f.name, "Current item name")
    if Item.FileAttributes:find('d', 1, true) then
      return f.name == '..' and 'back' or 'dir'
    end
  else
    f.name = f.filename
  end

  if f.firstline == true and
     not utils.isPluginPanel(Info) then
    f.firstline, f.assumed =
        unit.readFileFirstLine((f.path or '.')..'/'..f.name)
  end

  return detectType(f)
end --

-- Detect a type of edited file.
function areaFileType.editor (f)
  local f = f or {}

  if not f.filename then
    local fullname = far.EditorGetInfo().FileName
    f.path, f.name = fullname:match(PathNamePattern)
  end

  if not f.firstline then
    f.firstline, f.assumed = unit.readEditorFirstLine()
  end

  return detectType(f)
end --

-- Detect a type of viewed file.
function areaFileType.viewer (f)
  local f = f or {}

  if not f.filename then
    local fullname = far.ViewerGetInfo().FileName
    f.path, f.name = fullname:match(PathNamePattern)
  end

  if f.firstline == true then
    f.firstline, f.assumed = detect.readFileFirstLine(fullname)
  end

  return detectType(f)
end --

do
  local F = far.Flags

local areas = { -- FAR areas:
  [F.WTYPE_PANELS] = 'panels',
  [F.WTYPE_VIEWER] = 'viewer',
  [F.WTYPE_EDITOR] = 'editor',
  --[F.WTYPE_DIALOG] = 'dialog',
  --[F.WTYPE_VMENU]  = 'vmenu',
  --[F.WTYPE_HELP]   = 'help',
} --- areas

for k, v in pairs(areas) do
  areaFileType[k] = areaFileType[v]
end

function areaFileType.current (f)
  local area = far.AdvControl(F.ACTL_GETWINDOWINFO, -1).Type
  if areaFileType[area] then
    return areaFileType[area](f)
  else
    return nil, L:t1("SNoAreaFunction",
                     L:t((areas[area] or Msgs.UnknownArea)..'Area'))
  end
end --

end -- do

---------------------------------------- Using
local useType = {} -- Use type
unit.use = useType

-- Next field type of ctype.
local function nextType (ctype, field) --> (string|nil)
  return ctype and types[ctype] and types[ctype][field or 'inherit']
end --
useType.nextType = nextType

-- Parent type of ctype.
local function parentType (ctype) --> (string|nil)
  return nextType(ctype, 'inherit')
end --
useType.parentType = parentType

-- Group type of ctype.
function useType.groupType (ctype) --> (string|nil)
  return nextType(ctype, 'group')
end --

-- Check ctype as Type or as inheritor from Type.
function useType.isType (ctype, Type, field) --> (bool)
  local tp = ctype
  while tp do
    if tp == Type then return true end
    tp = nextType(tp, field)
  end
  return false
end --

-- Find abstract config table for cfg.
function useType.abstractConfig (cfg) --> (table)
  if type(cfg) ~= 'table' then return end
  local t = datas.cfglist(cfg) -- all config tables!
  for k = 1, #t do
    local u = t[k]
    if u and u._meta_ and u._meta_.abstract then return u end
  end
end --

local abstypes = useType.abstractConfig(types) -- Abstract types
ctxdata.abstypes = abstypes

-- Find nomask supertype of ctype for cfg.
function useType.nomaskType (ctype, cfg, field) --> (string | nil)
  local tp, cfg, field = ctype, cfg or types, field or 'inherit'
  while tp and types[tp] and types[tp].masks do
    tp = (cfg[tp] or Null)[field] or types[tp][field]
  end
  return tp -- any nomask type
end --

-- Find abstract supertype of ctype for cfg.
function useType.abstractType (ctype, cfg, field) --> (string | nil)
  local tp, cfg, field = ctype, cfg or types, field or 'inherit'
  while tp and types[tp] and not abstypes[tp] do
    tp = (cfg[tp] or Null)[field] or types[tp][field]
  end
  return tp and abstypes[tp] and tp -- abstract type only
end --

--[[ Warning:
  These functions is only for unregistered config data tables.
  They provide a simple mechanism for using types with such tables.
  They don't use inheritance in config tables, but in types only.
--]]

-- Find ctype as cfg type with inheritance and equivalence.
local function nextConfigType (ctype, cfg, equiv, field)
  local tp, eqtp = ctype
  local eq = equiv and cfg[equiv] -- equivalence section
  while tp do
    if eq then
      eqtp = eq[tp] -- equivalent type
      if eqtp and cfg[eqtp] then tp = eqtp end
    end
    if cfg[tp] then return tp end -- is in Config
    tp = nextType(tp, field)
  end
end --
useType.nextConfigType = nextConfigType

-- Retrieve first ctype as cfg type.
function useType.configType (ctype, cfg, equiv, field) --> (string)
  --assert(not cfg, "No config for configType")
  if cfg[ctype] then return ctype end -- by cfg
  return nextConfigType(ctype, cfg, equiv, field or 'inherit')
end --

-- Retrieve next type (for ctype) as cfg type.
function useType.configNextType (ctype, cfg, equiv, field) --> (string)
  --assert(not cfg, "No config for configNextType")
  local field = field or 'inherit'
  local tp = ctype and cfg[ctype] and cfg[ctype][field] or -- by cfg
             nextType(ctype, field) -- by types (find next by default)
  return nextConfigType(tp, cfg, equiv, field)
end --

---------------------------------------- Check
local checkType = {} -- Check inheritance
unit.check = checkType

local isError = false -- One warning per action!

-- Check inheritance of type from itself.
--[[ Parameters:
  ctype (string) - checked type.
  v      (table) - ctype values table.
  field (string) - used field.
  -- Returns:
  v[field] (string) - supertype for ctype.
--]]
local function checkItself (ctype, v, field) --> (string | nil)
  field = field or 'inherit'
  if ctype ~= v[field] then return v[field] end

  if not isError then
    isError = true
    L:w(L:t'CInheritError',
        L:t1('SInheritDirect', ctype, field)..
        L:t1('SInheritReset', ctype, ctype))
  end
  v[field] = nil
end --
checkType.itself = checkItself

-- Check inheritance from supertype.
--[[ Parameters:
  ctype - checked type.
  v - ctype values table.
  cfg - config table.
  field - used field.
  -- Returns:
  v[field] - supertype for ctype.
--]]
local function superType (ctype, v, cfg, field) --> (string | nil)
  field = field or 'inherit'
  local super = v[field]
  if super == nil then return end

  -- Check type and supertype:
  if ctype == super then -- Itself
    if not isError then
      isError = true
      L:w(L:t'CInheritError',
          L:t1('SInheritDirect', ctype, field)..
          L:t1('SInheritReset', ctype, ctype))
    end
    v[field] = nil
    return
  elseif cfg[super] == nil then -- Unknown
    if not isError then
      isError = true
      L:w(L:t'CInheritError',
          L:t1('SInheritUnknown', ctype, super, field)..
          L:t1('SInheritReset', ctype, super))
    end;
    v[field] = nil
    return
  end

  return super
end --
checkType.superType = superType

-- Check inheritance for config type.
local function checkInherit (ctype, v, cfg, field)
  if v._checked_ then return end
  field = field or 'inherit'

  local super = superType(ctype, v, cfg, field)
  if not super then
    v._checked_ = true
    return
  end

  -- Check inheritance chain:
  local chain = { [ctype] = true; ctype }
  while super and not cfg[super]._checked_ do
    if chain[super] then
      local last = chain[#chain]
      if not isError then
        isError = true
        local message = {
          L:t1('SInheritIndirect', ctype, field),
          L:t'SInheritChainBegin',
          table_concat(chain, L:t'SInheritChainSep'),
          L:t'SInheritChainEnd',
          L:t1('SInheritReset', last, super),
        }
        L:w(L:t'CInheritError', table.concat(message, '\n'))
      end
      cfg[last][field] = nil
      break
    end -- if

    chain[#chain+1] = super
    chain[super] = true
    super = superType(super, cfg[super], cfg, field)
  end

  -- Remember checked types:
  for k = 1, #chain do
    if cfg[chain[k]] then
      cfg[chain[k]]._checked_ = true
    else -- Check for 'asmeta'
      if not isError then
        isError = true
        L:w1('CInheritError', 'SInheritLostType', chain[k])
      end
    end
  end
  --v._checked_ = true -- it is set by upper loop!
end --
checkType.type = checkInherit

do
  local checked = ctxdata.checked

-- Check inheritance for all config types.
function checkType.types (cfg) --| cfg --> (true | nil)
  local cfg = cfg or types
  if not cfg or checked[cfg] then return end

  isError = false
  for k, v in cfgpairs(cfg) do
    checkInherit(k, v, cfg, 'inherit')
  end
  isError = false

  checked[cfg] = true
  return true
end --

-- Check inheritance reset.
function checkType.reset (cfg) --| cfg
  local cfg = cfg or types
  if not cfg then return end

  for k, v in cfgpairs(cfg) do
    v._checked_ = false -- nil
  end
  checked[cfg] = false
end --

if not checked[types] then
  checkType.types(types)
end

end -- do

--------------------------------------------------------------------------------
context.detect = unit -- 'detect' table in context
--------------------------------------------------------------------------------
