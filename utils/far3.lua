--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- FAR3 compability script for temporary use.
  -- Скрипт совместимости с FAR3 для временного использования.
--]]
----------------------------------------
--[[ uses:
  LuaFAR,
  LF context.
  -- group: temp.
  -- areas: any.
--]]
--------------------------------------------------------------------------------
local _G = _G

----------------------------------------
local context = context

----------------------------------------
--local logMsg = (require "Rh_Scripts.Utils.Logging").Message

--------------------------------------------------------------------------------
-- DN_INPUT/DN_CONTROLINPUT: Param2 --> INPUT_RECORD
-- WARN: Вызывать far.ParseInput(param2) перед использованием param2.
function far.ParseInput (Input) --> (FarKey, VirKey)
  if type(Input) == 'table' then
    if Input.dwButtonState then
      Input.EventType = F.MOUSE_EVENT
      return
    end
    return far.FarInputRecordToKey(Input), Input
  else -- if type(Input) == 'number' then
    return Input, far.FarKeyToInputRecord(Input)
  end
end ----

----------------------------------------
if context.use.LFVer == 3 then return end

-- Check applying
if context.use.AsFAR3 then return end

context.use.AsFAR3 = true

--------------------------------------------------------------------------------

--bit64 = bit
local band, bor  = bit.band, bit.bor
local bnot, bxor = bit.bnot, bit.bxor
--local bshl, bshr = bit.lshift, bit.rshift

---------------------------------------- Tables
far.Keys   = require "farkeys" -- TODO: exclude!!!
far.Colors = require "farcolor"

---------------------------------------- Flags
-- Удаление / переименование флагов.

local F = far.GetFlags()
far.Flags = F

local O = {} -- old flags
F.OldFlags = O

do
  -- KSFLAGS_ --> KMFLAGS_ (build 1844):
  for k, v in pairs(F) do
    if k:find("^KSFLAGS_") then
      local flag = k:match("^KSFLAGS_(.*)")
      F["KMFLAGS_"..flag] = v
      F[k] = nil
    end
  end
end -- do

-- PanelInfo (build 1812):
do
F.PFLAGS_PLUGIN           = 0x00000800
F.PFLAGS_VISIBLE          = 0x00001000
F.PFLAGS_FOCUS            = 0x00002000
F.PFLAGS_ALTERNATIVENAMES = 0x00004000
end -- do

-- PKF_ (build 1815):
--FAR_PKF_FLAGS = nil
F.PKF_CONTROL    = nil
F.PKF_ALT        = nil
F.PKF_SHIFT      = nil
F.PKF_PREPROCESS = nil

-- WindowInfo (build 1823):
F.WIF_MODIFIED = 0x00000001
F.WIF_CURRENT  = 0x00000002

-- FCTL_ (build 1825):
F.FCTL_GETCMDLINESELECTEDTEXT = nil

-- ECTL_ (build 2041):
--F.ECTL_DELCOLOR = F.ECTL_ADDCOLOR

-- OPIF_ (build 1825, 1826):
--F.OPIF_USEFILTER       --> not F.OPIF_DISABLEFILTER
--F.OPIF_USESORTGROUPS   --> not F.OPIF_DISABLESORTGROUPS
--F.OPIF_USEHIGHLIGHTING --> not F.OPIF_DISABLEHIGHLIGHTING

-- DialogInfo (build 1830):
F.DN_GETDIALOGINFO = nil

-- FarDialogItem (build 1836):
do
F.DIF_FOCUS         = 0x04000000 -- ??
--            0x0000000200000000
F.DIF_DEFAULTBUTTON = 0x00100000 -- DIF_DROPDOWNLIST
--            0x0000000100000000
end -- do

-- DM_ (build 1834):
F.DM_SETREDRAW = F.DM_REDRAW
F.DM_SETTEXTLENGTH = F.DM_SETMAXTEXTLENGTH

-- MacroControl (build 1849):
do
  local MacroFlags = {
    ACTL_KEYMACRO = true,
    MCMD_LOADALL = true,
    MCMD_SAVEALL = true,
    MCMD_GETAREA = true,
    MCMD_GETSTATE = true,
    MCMD_POSTMACROSTRING = true,
    MCMD_CHECKMACRO = true,
  } ---
  for k, _ in pairs(MacroFlags) do
    O[k] = F[k]
    F[k] = nil
  end
end -- do

-- OPEN_ (build 1850):
do
  O.OPEN_DISKMENU = F.OPEN_DISKMENU
  F.OPEN_DISKMENU = nil

  F.OPEN_LEFTDISKMENU  = O.OPEN_DISKMENU
  F.OPEN_RIGHTDISKMENU = 10
end -- do

-- DN_ (build 1859):
do
  O.DN_MOUSEEVENT = F.DN_MOUSEEVENT
  F.DN_MOUSEEVENT = nil
  F.DN_INPUT = O.DN_MOUSEEVENT

  O.DN_KEY = F.DN_KEY
  F.DN_KEY = nil
  F.DN_CONTROLINPUT = O.DN_KEY

  O.DN_MOUSECLICK = F.DN_MOUSECLICK
  F.DN_MOUSECLICK = nil -- == F.DN_CONTROLINPUT
end -- do

-- ACTL_ (build 1860, 1864, 1906):
F.ACTL_GETSHORTWINDOWINFO = nil
F.ACTL_GETPOLICIES = nil -- ??
F.ACTL_GETFARMANAGERVERSION = F.ACTL_GETFARVERSION
--F.ACTL_GETFARVERSION = nil

-- ECF_ (build 1898):
O.ECF_TAB1 = F.ECF_TAB1
F.ECF_TAB1 = 0x1

-- EF_ (build 2046):
F.EF_LOCKED         = 0x00000400
F.EF_DISABLESAVEPOS = 0x00000800

---------------------------------------- API
-- Удаление / изменение функций.

-- FAR Version (build 1808):
far.GetMinFarVersionW = nil

-- GUID (build 1808, 1830, 1833)
function win.Uuid (Uuid)
  assert(Uuid == nil or type(Uuid) == 'string')
  if not Uuid then
    return ""
  end
  if string.sub(Uuid, 1, 1) == "{" then
    return ""
  end
  return ""
end ----

-- PluginInfo (build 1808),
-- API (build 1826, 1831, 1833, 1835, 1863, 1871, 1891):
-- ??? --> dll

-- GUID плагина (build 1834, 1841—1843, 1891):
-- ??? --> dll

-- PanelInfo (build 1812):
do
  local GetPanelInfo = far.CtrlGetPanelInfo

function far.CtrlGetPanelInfo (handle, whatpanel)
  local Info = GetPanelInfo(handle, whatpanel)
  local flags = Info.Flags
  if Info.Plugin then
    Info.Plugin = nil
    flags = bor(flags, F.PFLAGS_PLUGIN)
  end
  if Info.Visible then
    Info.Visible = nil
    flags = bor(flags, F.PFLAGS_VISIBLE)
  end
  if Info.Focus then
    Info.Focus = nil
    flags = bor(flags, F.PFLAGS_FOCUS)
  end
  if Info.ShortNames then
    Info.ShortNames = nil
    flags = bor(flags, F.PFLAGS_ALTERNATIVENAMES)
  end
  Info.Flags = flags
  Info.OwnerGuid = ""
  --Info.PluginHandle = nil
  return Info
end ----

end -- do

-- INPUT_RECORD (build 1816, 1859):
do
  local f3_key = require "context.utils.far3_key"

far.FarKeyToInputRecord = f3_key.FarKeyToInputRecord

-- ProcessKeyW: Key --> INPUT_RECORD -- build 1814.
-- ProcessKeyW --> ProcessPanelInputW -- build 2027.
-- ??? --> dll

end -- do

-- PluginPanelItem (build 1821):
do
  local GetCurPanelItem = far.CtrlGetCurrentPanelItem

function far.CtrlGetCurrentPanelItem (handle, whatpanel)
  local Item = GetCurPanelItem(handle, whatpanel)
  for k, v in pairs(Item.FindData) do
    Item[k] = v
  end
  Item.FindData = nil
  --Item.ChangeTime = Item.LastWriteTime -- Нет в LuaFAR3!
  return Item
end ----

end -- do

-- WindowInfo (build 1823):
-- ?? WindowInfo.Id = hDlg | E/V Id.
do
  local AdvCtrl = far.AdvControl

function far.AdvControl (Command, Param)
  local Result = AdvCtrl(Command, Param)

  if type(Result) == 'table' then
     if Command ==  "ACTL_GETWINDOWINFO" or
        Command == F.ACTL_GETWINDOWINFO then
       Result.Id = -1
       Result.Flags = Result.Flags or 0
       if Result.Modified then
          Result.Modified = nil
          Result.Flags = bor(Result.Flags, F.WIF_MODIFIED)
       end
       if Result.Current then
          Result.Current = nil
          Result.Flags = bor(Result.Flags, F.WIF_CURRENT)
       end
    end
  end

  return Result
end ----

end -- do

-- DialogInit / Dialog
-- (build 1830, 1842)
do
  local _Dialog = far.Dialog

function far.Dialog (Guid, ...)
  if type(Guid) == 'string' then
    return _Dialog(...)
  end
  return _Dialog(Guid, ...)
end

  local DlgInit = far.DialogInit

function far.DialogInit (Guid, ...)
  --logMsg({...}, "DialogInit", 3)
  if type(Guid) == 'string' then
    return DlgInit(...)
  end
  return DlgInit(Guid, ...)
end

end -- do

-- Dialog / DialogItem tables
-- (build 1836, 1837, 1845)
do
  local dialog = require "far2.dialog"
  local f3_dlg = require "context.utils.far3_dlg"

  -- [[
  for k, v in pairs(f3_dlg) do
    dialog[k] = v
  end
  --]]

end -- do

-- DialogBuilder (build 1856, 1858, 1869):
-- ??? --> nil

-- KeyBarTitles (build 1844):
-- ???

-- MakeFarVersion (build 1846):
-- far.MakeFarVersion
-- ??? -->

-- MacroControl (build 1849):
do
  local farAdvControl = far.AdvControl
  local ActlKeyMacro = O.ACTL_KEYMACRO
  local AcmdLoadAll = { Command = O.MCMD_LOADALL }
  local AcmdSaveAll = { Command = O.MCMD_SAVEALL }
  local AcmdGetArea  = { Command = O.MCMD_GETAREA }
  local AcmdGetState = { Command = O.MCMD_GETSTATE }
  local AcmdPostMacro  = O.MCMD_POSTMACROSTRING
  local AcmdCheckMacro = O.MCMD_CHECKMACRO
  
function far.MacroLoadAll () --> (bool)
  return farAdvControl(ActlKeyMacro, AcmdLoadAll) == 1
end

function far.MacroSaveAll () --> (bool)
  return farAdvControl(ActlKeyMacro, AcmdSaveAll) == 1
end

function far.MacroGetArea () --> (number)
  return farAdvControl(ActlKeyMacro, AcmdGetArea)
end

function far.MacroGetState () --> (number)
  return farAdvControl(ActlKeyMacro, AcmdGetState)
end ----

function far.MacroPost (macro) --> (bool)
  return farAdvControl(ActlKeyMacro, {
                       Command = AcmdPostMacro,
                       SequenceText = macro.SequenceText,
                       Flags = macro.Flags }) == 1
end

function far.MacroCheck (macro) --> (table)
  local _, res =
        farAdvControl(ActlKeyMacro, {
                      Command = AcmdCheckMacro,
                      SequenceText = macro.SequenceText,
                      Flags = macro.Flags })
  return res
end

end -- do

-- EditorControl/ViewerControl (build 1851, 1852):
do
  local Functions = {
    -- Editor Control
    --EditorGetInfo       = true,
    --EditorGetFileName   = true,
    --EditorQuit          = true,
    --EditorRedraw        = true,
    EditorSaveFile      = true,
    EditorSetKeyBar     = true,
    EditorSetParam      = true,
    EditorSetPosition   = true,
    EditorSetTitle      = true,
    --EditorTurnOffMarkingBlock   = true,
    EditorUndoRedo      = true,

    EditorAddColor      = true,
    EditorGetColor      = true,

    EditorProcessInput  = true,
    EditorProcessKey    = true,
    --EditorReadInput     = true,

    EditorExpandTabs    = true,
    EditorRealToTab     = true,
    EditorTabToReal     = true,

    --EditorDeleteBlock   = true,
    --EditorDeleteChar    = true,

    EditorGetString     = true,
    EditorSetString     = true,
    EditorDeleteString  = true,
    EditorInsertString  = true,
    EditorInsertText    = true,

    EditorSelect        = true,
    EditorGetSelection  = true,

    --EditorGetBookmarks          = true,
    --EditorGetStackBookmarks     = true,
    --EditorAddStackBookmark      = true,
    EditorDeleteStackBookmark   = true,
    --EditorClearStackBookmarks   = true,
    --EditorNextStackBookmark     = true,
    --EditorPrevStackBookmark     = true,

    -- Viewer Control
    --ViewerGetInfo       = true,
    --ViewerQuit          = true,
    --ViewerRedraw        = true,
    ViewerSetKeyBar     = true,
    ViewerSetMode       = true,
    ViewerSetPosition   = true,

    ViewerSelect        = true,

  } ---

  for k, _ in pairs(Functions) do
    Functions[k] = far[k]
    far[k] = function (Id, ...)
               if Id ~= nil and type(Id) ~= 'number' then
                 return Functions[k](Id, ...)
               end
               return Functions[k](...)
             end ----
  end -- for

end -- do

-- FarColor (build 1898, 2041, 2070—2075):
do

local function FarColorToNumber (Value) --> (number)
  if type(Value) ~= 'table' then return Value end

  local Result = band(Value.Flags or 0, F.ECF_TAB1) ~= 0 and O.ECF_TAB1 or 0
  return Result + band(Value.ForegroundColor, 0xF) +
                  band(Value.BackgroundColor, 0xF) * 0x10
end --

local function FarNumberToColor (Value) --> (table)
  if type(Value) == 'table' then return Value end

  local Result = {
    Flags = band(Value or 0, O.ECF_TAB1) ~= 0 and F.ECF_TAB1 or 0,
    ForegroundColor = band(Value, 0xF),
    BackgroundColor = band(bshl(Value, 4), 0xF),
  } ---
  return Result
end --

  local farText = far.Text
  local _EditorAddColor = far.EditorAddColor
  local _EditorGetColor = far.EditorGetColor

function far.Text (X, Y, Color, Str)
  return farText(X, Y, FarColorToNumber(Color), Str)
end ----

function far.EditorAddColor (EditorId, StringNumber,
                             StartPos, EndPos, Flags, Color, Priority)
  --far.Show(EditorId, StringNumber, StartPos, EndPos, Flags, Color, Priority)
  if type(Color) == 'table' then
    return _EditorAddColor(EditorId, StringNumber,
                           StartPos, EndPos, FarColorToNumber(Color))
  else
    return _EditorAddColor(EditorId, StringNumber,
                           StartPos, EndPos, Color or 0)
  end
end ----

function far.EditorDelColor (EditorId, StringNumber, StartPos)
  --far.Show(EditorId, StringNumber, StartPos)
  return far.EditorAddColor(EditorId, StringNumber, StartPos, StartPos, 0)
end ----

function far.EditorGetColor (EditorId, StringNumber,
                             StartPos, EndPos, ColorItem, Flags)
  local Result = _EditorGetColor(EditorId, StringNumber,
                                 StartPos, EndPos, ColorItem)
  if type(Result) ~= 'table' then
    return FarNumberToColor(Result)
  else
    return Result
  end
end ----

end -- do

-- CompareW, DeleteFilesW, FreeFindDataW, FreeVirtualFindDataW,
-- GetFilesW, GetFindDataW, GetOpenPanelInfoW, GetVirtualFindDataW,
-- MakeDirectoryW, OpenW, ProcessHostFileW, ProcessMacroFuncW (?),
-- PutFilesW, SetDirectoryW, SetFindListW (build 1899):
do

function export.GetOpenPanelInfo (object, handle)
  return far.GetOpenPluginInfo (object, handle)
end ----

function export.Open (OpenFrom, Guid, Item)
  return far.OpenPlugin(OpenFrom, Item)
end ----

function export.PutFiles (object, handle, Items, Move, SrcPath, OpMode)
  return far.PutFiles(object, handle, Items, Move, OpMode)
end ----

end -- do

-- SettingsControl (...):
-- ??

-- sqlite (...):
-- ??

-- ACTL_GETCOLOR, ACTL_SETCURRENTWINDOW,
-- ACTL_SETPROGRESSSTATE, ACTL_WAITKEY (build 1988):
-- ???
-- FCTL_GETPANELITEM, FCTL_GETSELECTEDPANELITEM,
-- FCTL_GETCURRENTPANELITEM; DM_GETDLGITEM (build 2019—2020):
-- ???

-- ClosePanelW, ConfigureW, ProcessDialogEventW,
-- ProcessEditorEventW, ProcessPanelEventW, ProcessPanelInputW,
-- ProcessSynchroEventW, ProcessViewerEventW (build 2082):
-- ???

--[[ TODO: build 2103—2104, 2105, 2106+2108, > 2108 ]]--

--------------------------------------------------------------------------------
