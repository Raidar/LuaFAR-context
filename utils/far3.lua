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
--local _G = _G

----------------------------------------
local context = context

if context.use.LFVer >= 3 then return end

-- Check applying
if context.use.AsFAR3 then return end

context.use.AsFAR3 = true

----------------------------------------
--[[
local log = require "context.samples.logging"
local logShow = log.Show
--]]

----------------------------------------
--bit64 = bit
local band, bor  = bit.band, bit.bor
--local bnot, bxor = bit.bnot, bit.bxor
--local bshl, bshr = bit.lshift, bit.rshift

--------------------------------------------------------------------------------

---------------------------------------- Tables
far.Keys   = require "farkeys" -- TODO: exclude!!!
far.Colors = require "farcolor"

---------------------------------------- Flags
-- Удаление / переименование флагов.

local F = far.Flags
local O = {} -- old flags
F.OldFlags = O

-- KMFLAGS_ (build 1844, 2551):
do
  -- KSFLAGS_ --> KMFLAGS_:
  for k, v in pairs(F) do
    if k:find("^KSFLAGS_") then
      local flag = k:match("^KSFLAGS_(.*)")
      F["KMFLAGS_"..flag] = v
      F[k] = nil
    end
  end

  F.KMFLAGS_SAVEMACRO = nil
end -- do

-- PFLAGS_ (Panel info flag) (build 1812):
do
  F.PFLAGS_PLUGIN           = 0x00000800
  F.PFLAGS_VISIBLE          = 0x00001000
  F.PFLAGS_FOCUS            = 0x00002000
  F.PFLAGS_ALTERNATIVENAMES = 0x00004000
end -- do

-- PKF_ (? flag) (build 1815):
do
  --FAR_PKF_FLAGS = nil
  F.PKF_CONTROL    = nil
  F.PKF_ALT        = nil
  F.PKF_SHIFT      = nil
  F.PKF_PREPROCESS = nil
end -- do

-- WIF_ (Window info flag) (build 1823, 2539):
do
  F.WIF_MODIFIED = 0x00000001
  F.WIF_CURRENT  = 0x00000002
  F.WIF_MODAL    = nil
end -- do

-- FCTL_ (File control) (build 1825, 2202):
F.FCTL_GETCMDLINESELECTEDTEXT = nil
F.FCTL_GETPANELPREFIX = 34

-- ECTL_ (Editor control) (build 2041):
--F.ECTL_DELCOLOR = F.ECTL_ADDCOLOR

-- OPIF_ (Open plugin info) (build 1825, 1826, 1835, 2556):
do
  --F.OPIF_USEFILTER       --> not F.OPIF_DISABLEFILTER
  --F.OPIF_USESORTGROUPS   --> not F.OPIF_DISABLESORTGROUPS
  --F.OPIF_USEHIGHLIGHTING --> not F.OPIF_DISABLEHIGHLIGHTING
  F.OPIF_USEFREESIZE    = 0x00020000
  F.OPIF_SHORTCUT       = 0x00040000
end -- do

-- DialogInfo (build 1830, 2199, 2220, 2246):
F.DN_GETDIALOGINFO = nil
F.DN_GETVALUE = 4118

-- DIF_ (FarDialogItem) (build 1836):
do
  F.DIF_FOCUS         = 0x04000000 -- ??
  --            0x0000000200000000
  F.DIF_DEFAULTBUTTON = 0x00100000 -- DIF_DROPDOWNLIST
  --            0x0000000100000000
end -- do

-- DM_ (build 1834, 2116):
F.DM_SETREDRAW = F.DM_REDRAW
F.DM_SETTEXTLENGTH = F.DM_SETMAXTEXTLENGTH
--F.DM_LISTSETMOUSEREACTION = nil --> DIF_LISTTRACKMOUSE / DIF_LISTTRACKMOUSEINFOCUS

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

-- ACTL_ (Advanced control) (build 1860, 1864, 1906):
F.ACTL_GETSHORTWINDOWINFO = nil
F.ACTL_GETPOLICIES = nil -- ??
F.ACTL_GETFARMANAGERVERSION = F.ACTL_GETFARVERSION
--F.ACTL_GETFARVERSION = nil

-- ECF_ (Editor control flag) (build 1898, 2191):
do
  O.ECF_TAB1 = F.ECF_TAB1
  F.ECF_TAB1 = nil -- 0x1
  F.ECF_TABMARKFIRST   = 0x1
  F.ECF_TABMARKCURRENT = 0x2
end -- do

-- EF_ (Editor flag) (build 2046):
F.EF_LOCKED         = 0x00000400
F.EF_DISABLESAVEPOS = 0x00000800

-- FCF_ (FarColor flag) (build 2130):
do
  F.FCF_NONE     = 0x0
  F.FCF_FG_4BIT  = 0x1
  F.FCF_BG_4BIT  = 0x2
  F.FCF_4BITMASK = F.FCF_FG_4BIT + F.FCF_BG_4BIT
end -- do

-- PS_ --> TBPS_ (ProgressState) (build 2515):
do
  local PS_Flags = {
    PS_NOPROGRESS = true,
    PS_INDETERMINATE = true,
    PS_NORMAL = true,
    PS_ERROR = true,
    PS_PAUSED = true,
  } ---
  for k, _ in pairs(PS_Flags) do
    F["TB"..k] = F[k]
    F[k] = nil
  end
end -- do

---------------------------------------- API functions
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
  local GetPanelInfo = panel.GetPanelInfo

function panel.GetPanelInfo (handle, whatpanel)
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
end ---- GetPanelInfo

end -- do

-- PluginPanelItem (build 1821):
do
  local GetCurPanelItem = panel.GetCurrentPanelItem

function panel.GetCurrentPanelItem (handle, whatpanel)
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
end ---- AdvControl

end -- do

-- DialogInit / Dialog
-- (build 1830, 1842)
do
  local _Dialog = far.Dialog

function far.Dialog (Guid, ...)
  --far.Message(type(Guid))
  if type(Guid) == 'string' then
    return _Dialog(...)
  end

  return _Dialog(Guid, ...)
end ----

  local DlgInit = far.DialogInit

function far.DialogInit (Guid, ...)
  --log.Show({Guid, ...}, "DialogInit")
  if type(Guid) == 'string' then
    return DlgInit(...)
  end

  return DlgInit(Guid, ...)
end ----

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

-- MacroControl (build 1849, 2106, 2108, 2208):
do
  local farAdvControl = far.AdvControl
  local ActlKeyMacro = O.ACTL_KEYMACRO
  local AcmdLoadAll  = { Command = O.MCMD_LOADALL }
  local AcmdSaveAll  = { Command = O.MCMD_SAVEALL }
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

function far.MacroPost (SequenceText, Flags, AKey) --> (bool)
  -- AKey is not used in FAR2.
  return farAdvControl(ActlKeyMacro, {
                       Command = AcmdPostMacro,
                       SequenceText = SequenceText,
                       Flags = Flags }) == 1
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

-- EditorControl/ViewerControl (build 1851, 1852, ..., 2184, 2559):
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
    EditorUndoRedo      = true,

    EditorAddColor      = true,
    EditorGetColor      = true,

    EditorProcessInput  = true,
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
  local sFarEditor = "^Editor(.+)$"
  local sFarViewer = "^Viewer(.+)$"

  for k, _ in pairs(Functions) do
    Functions[k] = far[k]
    far[k] = function (Id, ...)
               if Id ~= nil and type(Id) ~= 'number' then
                 return Functions[k](Id, ...)
               end
               return Functions[k](...)
             end ----
    local s
    s = k:match(sFarEditor)
    if s then
      editor[s] = far[k]
    end
    s = k:match(sFarViewer)
    if s then
      editor[s] = far[k]
    end
  end -- for

far.EditorProcessKey = nil -- ~= far.EditorProcessInput -- ECTL_PROCESSKEY
far.TurnOffMarkingBlock = nil -- ECTL_TURNOFFMARKINGBLOCK

end -- do

-- FarColor (build 1898, 2041, 2070—2075, 2130):
do

local function FarColorToNumber (Value) --> (number)
  if type(Value) ~= 'table' then return Value end

  --local Result = band(Value.Flags or 0,
  --                    F.ECF_TABMARKFIRST) ~= 0 and O.ECF_TAB1 or 0
  local Result = 0
  return Result + band(Value.ForegroundColor, 0xF) +
                  band(Value.BackgroundColor, 0xF) * 0x10
end --

local function FarNumberToColor (Value) --> (table)
  if type(Value) == 'table' then return Value end

  local Result = {
    --Flags = band(Value or 0, O.ECF_TAB1) ~= 0 and F.ECF_TABMARKFIRST or 0,
    Flags = F.FCF_4BITMASK,
    ForegroundColor = band(Value, 0xF),
    BackgroundColor = band(bshl(Value, 4), 0xF),
  } ---

  return Result
end --

  local farText = far.Text
  local _EditorAddColor = editor.AddColor
  local _EditorGetColor = editor.GetColor

function far.Text (X, Y, Color, Str)
  return farText(X, Y, FarColorToNumber(Color), Str)
end ----

function editor.AddColor (EditorId, StringNumber,
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

function editor.DelColor (EditorId, StringNumber, StartPos)
  --far.Show(EditorId, StringNumber, StartPos)
  return editor.AddColor(EditorId, StringNumber, StartPos, StartPos, 0)
end ----

function editor.GetColor (EditorId, StringNumber,
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

-- INPUT_RECORD (build 1816, 1859, 2103—2104):
-- ProcessKeyW: Key --> INPUT_RECORD (build 1814).
-- ProcessKeyW --> ProcessPanelInputW (build 2027).
-- ??? --> dll
do
  local f3_key = require "context.utils.far3_key"

far.FarInputRecordToKey = nil
far.FarKeyToName = nil
far.FarNameToKey = nil
far.InputRecordToName = f3_key.InputRecordToName
far.NameToInputRecord = f3_key.NameToInputRecord

  do
    local farMenu = far.Menu
    local MenuBreakKeysToOld = f3_key.MenuBreakKeysToOld

    function far.Menu (Properties, Items, BreakKeys)
      --return farMenu(Properties, Items, BreakKeys)
      --far.Message('far.Menu')
      return farMenu(Properties, Items, MenuBreakKeysToOld(BreakKeys))
    end ----

  end -- do

end -- do

-- Panel Dir (build 2343):
do
  local GetPanelDir = panel.GetPanelDir
  panel.GetPanelDir = nil

  function panel.GetPanelDirectory (handle, whatpanel)
    return { Name = GetPanelDir(handle, whatpanel) }
  end

  local SetPanelDir = panel.SetPanelDir
  panel.SetPanelDir = nil

  function panel.SetPanelDirectory (handle, whatpanel, dir)
    if type(dir) == 'string' then
      return SetPanelDir(handle, whatpanel, dir)
    else
      return SetPanelDir(handle, whatpanel, dir.Name)
    end
  end
end -- do

--[[ TODO: build > 2896, excluding:
           -- Макросы:
           2851 (Lua-макросы !!!),
           2856 (Plugin.Exist),
           2859 (Panel.Item, panel.setpath, fexist, beep, Window.Scroll),
           2869 (Plugin.Menu, Plugin.Config, Plugin.Command),
---- TODO: -- Скрипты:
           2435 (EEREDRAW_), 2438 (EE_CHANGE),
           2478—2479, 2541 (переход на FSSF_…),
           2542, 2544, 2546 (FSSF_…),
           2804 (DM_GETTEXTLENGTH & DM_GETTEXTPTR удалены),
           --2810 (добавлена ACTL_ENABLEREDRAW), -- 2818 (удалена),
           2811 (изменения в ProcessPanelEventInfo),
           2813 (FSF.CopyToClipboard / FSF.PasteFromClipboard),
           2815 (EditorBookMarks -> EditorBookmarks),
           2820 (ViewerInfo.FileName -> VCTL_GETFILENAME),
           2825 (InfoPanelLine Separator -> Flags + флаг IPLFLAGS_SEPARATOR),
           2828 (ViewerMode: Wrap&WordWrap -> Flags, Hex -> Type),
           2834 (PluginPanelItem),
           2835 (удалена ACTL_EJECTMEDIA),
           2837 (ProcessConsoleInput), 2843 (ProcessConsoleInputInfo),
---- TODO: -- Остальное:
           2580 (PFLAGS_SHORTCUT + FCTL_GETPANELDIRECTORY).
           2802 (OPEN_COMMANDLINE),
           2870 (sqlite 3.7.14.1).
… ]]--
--[[ TODO: Checking FAR builds: 2246; 2516; 2574(?), 2686(?) ]]--

--------------------------------------------------------------------------------
