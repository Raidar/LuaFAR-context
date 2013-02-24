--[[ LFc testing ]]--

----------------------------------------
--[[ description:
  -- Test: Type detecting.
  -- Тест: Определение типа.
--]]
--------------------------------------------------------------------------------

----------------------------------------
local farMsg = far.Message

----------------------------------------
local context = context
if not context then
  farMsg("No 'LuaFAR context' pack installed\n", "test_detType")
  return
end

local logShow = context.ShowInfo
--local cfgReg = ctxdata.reg
local readCfg = context.config.read

if not readCfg then
  farMsg("No types for detect\n\n"..
         "'LuaFAR context' pack is required\n", "test_detType")
  return
end

local utils = require 'context.utils.useUtils'

----------------------------------------

--readCfg(cfgReg.types) -- Reading types_config -- don't work!

local PluginPath = utils.PluginPath

--[[
-- Protected require.
local function prequire (modname)
  local st, res = pcall(require, modname)
  return st and res or nil
end -- prequire
--]]

local detect = context.detect

----------------------------------------
local DetKindsInfo = { -- Описание видов detect:
  bymask = "By mask only without first line", -- Только по маске (без 1-й линии)
  byline = "By mask with first line checked", -- По маске с проверкой 1-й линии
} --- DetKindsInfo

local TestFilesInfo = { -- Ожидаемые результаты detect:
  -- Разница между bymask и byline --
  [".t_t"]          = { bymask = "none",  byline = "tst_fl2", },
  ["With_fl2"]      = { bymask = "none",  byline = "tst_fl2", },
  [".With_fl2.t_t"] = { bymask = "none",  byline = "tst_fl2", },
  ["With_fl2.t_t"]  = { bymask = "none",  byline = "tst_fl2", },

  --["With_py"]       = { bymask = "none",  byline = "python", },
  ["With_tcl"]      = { bymask = "none",  byline = "tcl_tk", },

  -- Разница между bymask и byline + strong --
  ["With_cfg.lua"]  = { bymask = "lua",   byline = "lua", },
  ["With_cfg.cfg"]  = { bymask = "ini",   byline = "ini", },
  ["With_fl2.cfg"]  = { bymask = "ini",   byline = "ini", },

  ["With_lua.lum"]  = { bymask = "none",  byline = "none", },

  ["Def_file.tst"]  = { bymask = "tst_def", byline = "tst_def", },
  ["With_fl1.tst"]  = { bymask = "tst_def", byline = "tst_fl1", },
  ["With_fl2.tst"]  = { bymask = "tst_def", byline = "tst_fl2", },
  [".With_fl2.tst"] = { bymask = "tst_def", byline = "tst_fl2", },
} --- TestFilesInfo

local DetFuncsInfo = {
  default = { Value = detect.FileType },
  --altered = { Value = <function> },
} --- DetFuncsInfo

----------------------------------------
local readFline = detect.readFileFirstLine

local function getFilesType (FileList, detTypeFunc, f) --> (table) or nil
  if not detTypeFunc then return nil, 'no detect function' end
  local t, tf = {}, f or {}
  local checkFline = f.firstline
  for _, v in ipairs(FileList) do
    tf.name = v.name
    tf.filename = v.name
    tf.path = v.path
    if checkFline then
      tf.firstline = readFline and readFline(v.path..v.name) or nil
    end
    t[v.name] = detTypeFunc(tf)
    --t[v.name] = { detTypeFunc(tf) }
  end -- for
  f.firstline = checkFline

  return t
end -- getFilesType

local function cmpFilesType (t, FilesType, kind) --> (table | nil, error)
  if not FilesType then return nil, 'no file types' end
  local t, tp, exp, cmp = t or {}
  t[#t+1] = "--- "..DetKindsInfo[kind].." ---"
  for k, v in pairs(FilesType) do
    tp = type(v) == "string" and v or type(v) == "table" and v[1] or ""
    exp = TestFilesInfo[k]
    --if not exp then rhlog.Msg(k, "Unknown name") end
    if exp then
      exp = exp and TestFilesInfo[k][kind] or ""
      cmp = tp == exp and "ok" or ("error: %s ~= %s"):format(tp, exp)
      t[#t+1] = ("%14s : %s"):format(k, cmp)
    end
  end -- for
  t[#t+1] = "--- end ---"

  return t
end -- cmpFilesType

local PathNamePattern = '^(.-)([^\\/]+)$'

local CNoTestFiles = "No test files"
local SNoTestFiles = [[
Test files not found.
Copy content of 'context\test\detType'
to 'context\test\detType' on plugin path!
]] -- SNoTestFiles

local function testTypesCfg (...)
  local TestFilesDir = PluginPath.."context\\test\\detType\\"
  local DirList = far.GetDirList(TestFilesDir)
  if #DirList == 0 then
    farMsg(SNoTestFiles, CNoTestFiles, nil, 'l')
    return
  end
  --logShow(DirList, 'test_detType Dir List', 2)

  --logShow({ ... }, 'test_detType ...', 2)
  local DetFuncKinds = select(1, ...)
  --logShow(DetFuncKinds, 'test_detType DetFuncKinds', 2)
  if DetFuncKinds == nil then DetFuncKinds = { "default" } end

  local FileList = {}
  local Path, Name
  for k, v in ipairs(DirList) do
    if not v.FileAttributes:find('d', 1, true) then
      Path, Name = v.FileName:match(PathNamePattern)
      FileList[k] = { name = Name, path = Path }
    end
  end
  --logShow(FileList, 'test_detType Files List', 2)

  local Caption = "type detect (det ~= exp): "

  for k, v in ipairs(DetFuncKinds) do
    local detFunc = DetFuncsInfo[v] and DetFuncsInfo[v].Value
    local Title = Caption..(v or "#"..tostring(k))
    --logShow(DetFuncsInfo, Title)
    if detFunc then
      local f = {}  -- Detect file information
      local t       -- Type of files information
      local res     -- Test result information
      t = getFilesType(FileList, detFunc, f)
      res = cmpFilesType(nil, t, 'bymask')
      farMsg(table.concat(res, '\n'), Title)
      f.firstline = true
      t = getFilesType(FileList, detFunc, f)
      res = cmpFilesType(nil, t, 'byline')
      farMsg(table.concat(res, '\n'), Title)
    end
  end
end ---- testTypesCfg

---------------------------------------- main
local arg = select(1, ...)
--logShow({ ... }, 'args', 2)
if arg == nil then
  return testTypesCfg()
else
  return testTypesCfg
end
--------------------------------------------------------------------------------
