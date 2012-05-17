--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- Data configuring.
  -- Конфигурирование данных.
--]]
----------------------------------------
--[[ uses:
  LuaFAR,
  LF context.
  -- group: LFc scripts, Datas.
--]]
--------------------------------------------------------------------------------
local _G = _G

local type = type
local pairs = pairs
local rawget, rawset = rawget, rawset
local getmetatable, setmetatable = getmetatable, setmetatable

----------------------------------------
local context, ctxdata = context, ctxdata
local cfgDat, cfgReg = ctxdata.config, ctxdata.reg
local descriptors = ctxdata.descriptors

local tables = context.tables

local datas = require 'context.utils.useDatas'
local locale = require 'context.utils.useLocale'

local cfgpairs = datas.cfgpairs

----------------------------------------
--local logMsg = (require "Rh_Scripts.Utils.Logging").Message

--------------------------------------------------------------------------------
local unit = {}

----------------------------------------
local Custom = {
  label = "mCfg",
  name = "scripts",
  path = "context.scripts.",
  locale = { kind = 'require' },
} ---
local L, e1, e2 = locale.create(Custom)
if L == nil then
  return locale.showError(e1, e2)
end

---------------------------------------- Forming

local defBasis = 'base' -- Default basis table
local defMerge = 'update' -- Default merge kind
local defMeta = { -- Default meta
  basis = defBasis,
  merge = defMerge,
  pairs = cfgpairs,
} ---

-- Detect config mode.
local function detectMode (meta) --> (mode table)
  if meta == nil then
    meta = tables.copy(defMeta, false, pairs)
    meta.default = true -- By default!
    return meta
  end

  if type(meta) ~= 'table' then
    meta = { data = meta }
  end

  --return extendData(meta, defMeta)
  local isDef = true
  for k, v in pairs(defMeta) do
    if meta[k] then isDef = nil else meta[k] = v end
  end
  meta.default = isDef

  return meta
end -- detectMode
unit.detectMode = detectMode

do
  local merges = {
    update = 0,
    extend = 0,
    expand = 0,
    asmeta = 1,
  } ---

-- Merge two config data tables.
--[[
  -- @params:
  base (table) - base config data table.
  user (table) - user config data table.
  mode (table) - mode table for merging config data tables.
    basis (string) - returned table ('base' by default):
                     values: base | user.
    merge (string) - merge mode ('update' by default):
                     values: none | update | extend | asmeta.
--]]
function unit.merge (base, user, mode) --> (config table)
  local mode = tables.extend(mode, defMeta)
  if mode.basis == 'user' then base, user = user, base end

  local merge = mode.merge
  --logMsg(mode, "Config merge mode")
  if merge == 'none' then return base end

  local tpairs = mode.pairs --or defMeta.pairs
  local deep = mode.deep ~= false

  if merges[merge] == 0 then
    return tables[merge](base, user, tpairs, deep)
  end
  if merge == 'asmeta' then
    return tables.asmeta(base, user, tpairs, deep, '__cfgMT')
  end

  L:w1('CWrongMerge', 'SWrongMerge', mode.basis, mode.merge)
  return base or user -- user or base
end ---- merge

end -- do
do
  local require, pcall = require, pcall

-- Require config by filename base and former mask.
function unit.require (path, name, mask, loaded) --> (config, mode)
  local fullname = path..mask:format(name)
  local st, cfg = pcall(require, fullname)
  if st then
    if loaded then loaded[#loaded+1] = fullname end
    cfg._meta_ = detectMode(cfg._meta_)
    return cfg, cfg._meta_
  end

  if not cfg:match("module '.-' not found:") then -- Invalid syntax only!
    L:w(L:t'CInvalidCfg', L:t1('SInvalidCfg', fullname, cfg), 'l')
  end
end ---- require

end -- do

local desc_mask = '.cfgdsc.%s'          -- config descriptors' folder
local base_mask = '.cfg.%s_config'      -- configs' main folder
local user_mask = '.usrcfg.%s_config'   -- configs' user folder
local auto_mask = '.gencfg.%s_config'   -- auto-generated configs' folder

-- Read config data from base and user config files.
--[[
  -- @params:
  regdata (table) - config registry data from ctxdata.reg.
--]]
function unit.read (regdata) --> (config table)
  local path, name, mode = regdata.path, regdata.name, regdata.mode
  local regmode = not mode.default and mode --or mode
  regdata.loaded = {}
  local loaded = regdata.loaded
  --far.Message(name, mode)
  local usercfg, usermode
  local requireConfig = unit.require

  -- Unique config data:
  if name:sub(1, path:len()) == path then
  --if name:find('[\\/%.]') then -- DO NOT USE because name is relative!
    usercfg, usermode = requireConfig(path, '', name, loaded)
    if usercfg then return usercfg end
    L:w1('CNoUniqueCfg', 'SNoUniqueCfg', name)
    return
  end
  --far.Message(type(usercfg), usermode)

  -- Auto config data:
  local autocfg, automode = requireConfig(path, name, auto_mask, loaded)
  if mode.basis == 'auto' and mode.merge == 'none' then return autocfg end

  -- User config data:
  if not (mode.basis == 'base' and mode.merge == 'none') then
    usercfg, usermode = requireConfig(path, name, user_mask, loaded)
    if usercfg then
      local _mode = regmode or (not usermode.default and usermode) or mode
      if _mode.basis == 'user' and _mode.merge == 'none' then
        return usercfg
      end
    end
  end
  --far.Message(package.path, "package.path")
  --far.Message(type(usercfg), "User: "..tostring(usermode))

  -- Base config data:
  local basecfg, basemode = requireConfig(path, name, base_mask, loaded)
  --far.Message(type(basecfg), "Base: "..tostring(basemode))

  -- Check config datas present:
  if not (basecfg or autocfg) and usercfg then
    --L:w1('CNoBaseCfg', 'SNoBaseCfg', name)
    return usercfg
  end
  if not (autocfg or usercfg) then
    if basecfg then return basecfg end
    -- Check once more for Unique config data:
    usercfg, usermode = requireConfig(path, '', name, loaded)
    if usercfg then return usercfg end
    L:w1('CNoConfigs', 'SNoConfigs', name)
    return
  end

  -- Merge config datas:
  if basecfg then
    if usercfg then
      mode = regmode or (not usermode.default and usermode) or
                        (not basemode.default and basemode) or mode
      --far.Message(type(basecfg)..'\n'..type(usercfg), name)
      --L:w1(name, 'SWrongMerge', mode.basis, mode.merge)
      usercfg = unit.merge(basecfg, usercfg, mode)
    else
      usercfg = basecfg
    end
  end
  if autocfg then
    usercfg = unit.merge(usercfg, autocfg,
                         regmode or (not automode.default and automode) or mode)
  end

  return usercfg
end ---- read

do
  local pkg_loaded = package.loaded

-- Reset data for config registered by key.
-- Warning: It is no checking for right config.
function unit.reset (key)
  if rawget(cfgDat, key) ~= nil then cfgDat[key] = nil end
  local regdata = cfgReg[key] -- regdata
  if not (regdata and regdata.loaded) then return end

  local loaded = regdata.loaded
  for k = 1, #loaded do
    pkg_loaded[loaded[k]] = nil
  end
  regdata.loaded = nil
end ---- reset

end -- do

---------------------------------------- Access

local parentType -- function for detect parent type

-- Get _meta_ for config data table or its item-subtable.
local function get_meta (t) --> (table)
  return rawget(t, '_meta_')
end --

-- Detect parent for item-subtable in config data table.
local function itemParent (item) --> (type|string | nil)
  local v = rawget(item, 'inherit')
  if v ~= nil then return v end

  local meta = get_meta(item) -- meta for item
  if rawget(meta, 'cfgonly') then return end

  v = rawget(meta, 'type') -- current type
  meta = get_meta(rawget(meta, 'config')) -- meta for config
  if rawget(meta, 'cfgonly') then return end

  parentType = parentType or context.detect.use.parentType
  return parentType(v) or nil -- nil for false
end -- itemParent

-- Inheritance mechanism for config data items-subtables.
-- (Subtable don't know about config data table, so metatable is for get it.)
local function item_index (item, key)
  local v = itemParent(item) -- parent for item
  if not v then return end

  local cfg = rawget(get_meta(item), 'config')
  v = cfg[v] -- Recursive call of type_index! -- parent' subtable
  if v == nil then return end

  v = v[key] -- Recursive call of item_index! -- subtable key's value
  rawset(item, key, v)
  get_meta(cfg).gencfg[key] = true

  return v
end -- item_index

local item_MT = { __index = item_index }

-- Set _meta_ & metatable for item value.
local function set_meta (cfg, ctype, value) --| (value)
  if type(value) == 'table' then
    -- Warning: fields specified below are always present.
    value._meta_ = { type = ctype, config = cfg, gencfg = {} }
    setmetatable(value, item_MT) -- Access to _meta_ with get_meta only!
  end
end -- set_meta

local t_index = tables.t_index

-- Default mechanism for whole config data table.
local function type_oldindex (cfg, ctype)
  local v = t_index(cfg, ctype, '__cfgMT')
  if v ~= nil then return v end

  return t_index(cfg, ctype, '__oldindex')
end -- type_oldindex

-- Inheritance mechanism for whole config data table.
local function type_index (cfg, ctype)
  local v = type_oldindex(cfg, ctype)
  if v ~= nil then return v end

  parentType = parentType or context.detect.use.parentType
  v = parentType(ctype) -- parent for ctype
  if not v then return end

  v = cfg[v] -- Recursive call of type_index! -- parent' subtable
  rawset(cfg, ctype, v)
  get_meta(cfg).gencfg[ctype] = true

  return v
end -- type_index

local function type_newindex (cfg, ctype, value)
  if getmetatable(value) ~= item_MT then
    set_meta(cfg, ctype, value)
  end
  return rawset(cfg, ctype, value)
end -- type_newindex

---------------------------------------- Load

-- Load config data with use of inheritance mechanism.
function unit.load (regdata) --> (config table)
  local cfg = unit.read(regdata)
  if not cfg then return end -- No config files

  if type(cfg) ~= 'table' then
    --far.Message(cfg, key)
    L:w1('CNoCfgTable', 'SNoCfgTable', key)
    return
  end --

  -- Copy some metadata from regdata:
  local meta = cfg._meta_
  meta.gencfg = {}
  meta.inherit = regdata.inherit or meta.inherit
  meta.cfgonly = regdata.cfgonly or meta.cfgonly

  -- Set updated MT for config data table.
  local MT = getmetatable(cfg) or {} -- Reuse
  MT.__oldindex = MT.__index

  -- Connect inheritance mechanism:
  if meta.inherit then
    -- Set MT for item-subtables
    for k, v in cfgpairs(cfg) do
      set_meta(cfg, k, v)
    end

    MT.__index    = type_index
    MT.__newindex = type_newindex
  else
    MT.__index = type_oldindex
  end
  setmetatable(cfg, MT) -- Set MT

  return cfg
end ---- load

-- Load config descriptor.
function unit.loadDescriptor (key, regdata, cfg)
  local desc = unit.require(regdata.path, regdata.name,
                            desc_mask, regdata.loaded)
  if not desc then return end
  descriptors[key] = { configs = datas.cfglist(cfg), dsc = desc }
end ---- loadDescriptor

-- Autoload and access to registered config data
-- via ctxdata.config.<key name of config data> table.
local function cfg_index (t, key) --> (config table)
  local regdata = cfgReg[key]
  --logMsg(regdata, key)
  --if key == "lfa_editor" then logMsg(regdata, key) end
  if not regdata then
    L:w1('CNoRegConfig', 'SNoRegConfig', key)
    return
  end

  local cfg = unit.load(regdata)
  t[key] = cfg
  unit.loadDescriptor(key, regdata, cfg)

  return cfg
end -- cfg_index

--logMsg(cfgDat, "cfgDat")
setmetatable(cfgDat, { __index = cfg_index })

---------------------------------------- Using

local useConfig = { -- Use config
  -- Usefull functions:
  value = type_oldindex,
  itemParent = itemParent,
  -- _meta_ handling functions:
  get_meta = get_meta,
  set_meta = set_meta,
} ---
unit.use = useConfig

-- Rawget for config data table.
function useConfig.rawget (cfg, ctype)
  local meta = get_meta(cfg)
  if meta and meta.gencfg and meta.gencfg[ctype] then return nil end

  return rawget(cfg, ctype)
end ---- rawget

-- Rawset for config data table.
function useConfig.rawset (cfg, ctype, value)
  local meta = get_meta(cfg)
  if meta and meta.gencfg and meta.gencfg[ctype] then
    meta.gencfg[ctype] = nil
  end

  if getmetatable(value) ~= item_MT then
    set_meta(cfg, ctype, value)
  end

  return rawset(cfg, ctype, value)
end ---- rawset

-- Detect value and used type for type in config data table.
function useConfig.typeValue (cfg, ctype) --> (value, type|string | nil)
  parentType = parentType or context.detect.use.parentType
  local t, k = cfg, ctype
  local cfgonly = rawget(get_meta(cfg), 'cfgonly')

  while k do
    local v = rawget(t, k) -- any value!
    if v ~= nil then return v, k end
    v = type_oldindex(t, k)
    if v ~= nil then return v, k end
    if not cfgonly then k = parentType(k) end -- parent
  end
end ---- typeValue
local typeValue = useConfig.typeValue

-- Detect key value for item-subtable in config data table.
function useConfig.itemValue (item, key) --> (value | nil)
  local t, k = item, key
  local cfg = rawget(get_meta(item), 'config')

  while type(t) == 'table' do -- like assert!
    local v = rawget(t, k) -- any value!
    if v ~= nil then return v, k end
    k = itemParent(t) -- parent
    if not k then return end
    t, k = typeValue(cfg, k)
  end
end ---- itemValue

---------------------------------------- Register

-- Check equality of base parameters for two configs.
local function isRegDataEqual (t1, t2) --> (bool)
  return t1.key  == t2.key  and
         t1.path == t2.path and
         t1.name == t2.name
end --
unit.isRegDataEqual = isRegDataEqual

-- Fill information for config.
--[[
  -- @params:
  regdata (table) - @see unit.register.
--]]
local function fillRegData (regdata) --> (table)
  local key = regdata.key
  if not key then
    L:w0('CRegError', 'SRegNoKey')
    return
  end

  -- Use default values (if they are nil).
  regdata.path = regdata.path or 'context'
  regdata.name = regdata.name or key
  regdata.inherit = regdata.inherit
  regdata.cfgonly = regdata.cfgonly
  regdata.mode = detectMode(regdata.mode)

  return regdata
end ---- fillRegData
unit.fillRegData = fillRegData

-- Register config data.
--[[
  -- @params:
  regdata (table) - information about config data:
    key     - config key name.
    path    - config filepath.
    name    - config filename.
    inherit - inheritance flag.
    mode    - config merge mode.
--]]
function unit.register (regdata) --> (bool)
  local t = fillRegData(regdata)
  local key = t.key

  --if key == "lfa_editor" then logMsg(regdata, "lfa_editor") end

  if cfgReg[key] then
    if not isRegDataEqual(cfgReg[key], t) then
      L:w1('CRegError', 'SRegRepeat', key)
      return false
    end

    unit.reset(key)
  end

  cfgReg[key] = t

  return true
end ---- register

-- Unregister config data.
--[[
  -- @params:
  regdata (table) - @see unit.register.
--]]
function unit.unregister (regdata) --> (bool)
  local t = fillRegData(regdata)
  local key = t.key

  if not cfgReg[key] then
    L:w1('CUnRegError', 'SUnRegNoReg', key)
    return false
  end
  if not isRegDataEqual(cfgReg[key], t) then
    L:w1('CUnRegError', 'SUnRegDiffer', key)
    return false
  end

  unit.reset(key)
  cfgReg[key] = nil

  return true
end ---- unregister

-- Check config is registered.
function unit.isRegistered (key) --> (bool)
  return cfgReg[key] ~= nil
end --

--------------------------------------------------------------------------------
context.config = unit -- 'make' table in context
--------------------------------------------------------------------------------
