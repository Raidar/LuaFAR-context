-- Dialog module

----------------------------------------
--[[ description:
  -- FAR3 dialog compability script for temporary use.
  -- Скрипт совместимости с FAR3 dialog для временного использования.
--]]
--------------------------------------------------------------------------------
local Package = {}
local F = far.GetFlags()
local SendDlgMessage = far.SendDlgMessage

local LFVer = context.use.LFVer
local bit = LFVer == 3 and bit64 or bit
local band, bor  = bit.band, bit.bor
local bnot, bxor = bit.bnot, bit.bxor

--[[
  This module for temporary include to far3 for replace far2.dialog.
  No use (auto)reload user scripts otherwise it is not worked.

do
  local dialog = require "far2.dialog"
  local f3_dlg = require "context.utils.far3_dlg"

for k, v in pairs(f3_dlg) do
  dialog[k] = v
end

end -- do
--]]

--------------------------------------------------------------------------------
-- @param item : dialog item (a table)
-- @param ...  : sequence of item types, to check if `item' belongs to any of them
-- @return     : whether `item' belongs to one of the given types (a boolean)
--------------------------------------------------------------------------------
local function CheckItemType(item, ...)
  for i=1,select("#", ...) do
    local tp = select(i, ...)
    if tp==item[1] or F[tp]==item[1] then return true end
  end
  return false
end


-- 	int Type;                                1
-- 	int X1,Y1,X2,Y2;                         2,3,4,5
-- 	union {
-- 		DWORD_PTR Reserved;                    6
-- 		int Selected;                          6
-- 		struct FarList *ListItems;             6
-- 		CHAR_INFO *VBuf;                       6
-- 	};
-- 	const wchar_t *History;                  7
-- 	const wchar_t *Mask;                     8
-- 	unsigned __int64 Flags;                  9
-- 	LONG_PTR UserParam;                      10
-- 	const wchar_t *PtrData;                  11
-- 	size_t MaxLen;                           12  // terminate 0 not included (if == 0 string size is unlimited)

-- Bind dialog item names (see struct FarDialogItem) to their indexes.

local item_map
if LFVer == 3 then
item_map = {
  Type=1, X1=2, Y1=3, X2=4, Y2=5,
  --[[Focus=6,]] -- (build 1836)
  Selected=6,
  ListItems=6,
  --[[ListPos=6,]] -- (build 1845)
  VBuf=6,
  History=7, Mask=8, -- (build 1836)
  Flags=9,
  --[[DefaultButton=9,]] -- (build 1836)
  Data=10,
  MaxLen=11,
  UserData=12, -- (build 1836, 1837, 1944)
}
else
item_map = {
  Type=1, X1=2, Y1=3, X2=4, Y2=5,
  --Focus=6,
  Selected=7, ListItems=7,
  History=7, Mask=7,
  --ListPos=7,
  VBuf=7,
  Flags=8,
  --DefaultButton=9,
  Data=10,
}
end

local item_defs

if LFVer == 3 then
item_defs = {
  Type=1, X1=-1, Y1=-1, X2=-1, Y2=-1,
  --[[Focus=6,]] -- (build 1836)
  Selected=0,
  ListItems=nil,
  --[[ListPos=0,]] -- (build 1845)
  VBuf=nil,
  History=nil, Mask=nil, -- (build 1836)
  Flags=0,
  --[[DefaultButton=0,]] -- (build 1836)
  Data="",
  MaxLen=0,
  UserData=nil, -- (build 1836, 1837, 1944)
}
else
item_defs = {
  Type=1, X1=-1, Y1=-1, X2=-1, Y2=-1,
  --Focus=6,
  Selected=0, ListItems=nil,
  History=nil, Mask=nil,
  --ListPos=0,
  VBuf=nil,
  Flags=0,
  --DefaultButton=0,
  Data="",
}
end

-- Metatable for dialog items. All writes and reads at keys contained
-- in item_map (see above) are redirected to corresponding indexes.
local item_meta = {
  __index    = function (self, key)
                 local ind = item_map[key]
                 return rawget (self, ind) or ind
               end,
  __newindex = function (self, key, val)
                 rawset (self, item_map[key] or key, val)
               end,
}

function item_map:GetCheck (hDlg)
  return (F.BSTATE_CHECKED==SendDlgMessage(hDlg,"DM_GETCHECK",self.id,0))
end

function item_map:SaveCheck (hDlg, tData)
  tData[self.name] = self:GetCheck(hDlg)
end

function item_map:SetCheck (hDlg, check)
  SendDlgMessage(hDlg, "DM_SETCHECK", self.id,
    check and F.BSTATE_CHECKED or F.BSTATE_UNCHECKED)
end

function item_map:Enable (hDlg, enbl)
  SendDlgMessage(hDlg, "DM_ENABLE", self.id, enbl and 1 or 0)
end

function item_map:GetText (hDlg)
  return SendDlgMessage(hDlg, "DM_GETTEXT", self.id)
end

function item_map:SaveText (hDlg, tData)
  tData[self.name] = self:GetText(hDlg)
end

function item_map:SetText (hDlg, str)
  return SendDlgMessage(hDlg, "DM_SETTEXT", self.id, str)
end

function item_map:GetListCurPos (hDlg)
  local pos = SendDlgMessage(hDlg, "DM_LISTGETCURPOS", self.id, 0)
  return pos.SelectPos
end

-- A key for the "map" (an auxilliary table contained in a dialog table).
-- *  Both dialog and map tables contain all dialog items:
--    the dialog table is an array (for access by index by FAR API),
--    the map table is a dictionary (for access by name from Lua script).
-- *  A unique key is used, to prevent accidental collision with dialog
--    item names.
local mapkey = {}

local numFlag = context.utils.numFlag
-- Metatable for dialog.
-- *  When assigning an item to a (string) field of the dialog, the item is also
--    added to the array part.
-- *  Normally, give each item a unique name, though if 2 or more items do not
--    need be accessed by the program via their names, they can share the same
--    name, e.g. "sep" for separator, "lab" for label, or even "_".
local dialog_meta = {
  __newindex =
      function (self, item_name, item)
        item.name = item_name
        item.id = #self --> id is 0-based

        -- Change numbering of elements for support LuaFAR3 in LuaFAR2:
        if LFVer ~= 3 then
          -- Indexes 1, 2--5 are equivalent.

          -- Selected is 6 now (was 7).
          if CheckItemType(item, "DI_CHECKBOX", "DI_RADIOBUTTON") then
            item[7] = item[6]
          end
          -- History is 7.
          --item[7] = item[7]
          --if CheckItemType(item, "DI_EDIT") then end
          -- Mask is 8 now (was 7).
          if CheckItemType(item, "DI_FIXEDIT") then
            item[7] = item[8]
          end
          -- ListItems is 6 now (was 7).
          if CheckItemType(item, "DI_LISTBOX", "DI_COMBOBOX") then
            item[7] = item[6]
          end

          -- VBuf is 6 now (was 7) -- ignored.

          -- Flags is 9 now (was 8).
          item[8] = item[9]
          if type(item[8]) ~= 'number' then
            item[8] = numFlag(item[8])
          end

          -- Data is 10.
          --item[10] = item[10]

          -- Focus (6) is excluded.
          if band(item[8] or 0, F.DIF_FOCUS) ~= 0 then
            item[6] = 1
            item[8] = band(item[8] or 0, bnot(F.DIF_FOCUS))
          else
            item[6] = 0
          end

          -- DefaultButton (9) is excluded.
          if (item[1] == "DI_BUTTON" or
              item[1] == F.DI_BUTTON) and
             band(item[8], F.DIF_DEFAULTBUTTON) ~= 0 then
            item[9] = 1
            item[8] = band(item[8], bnot(F.DIF_DEFAULTBUTTON))
          else
            item[9] = 0
          end

          -- Ptr (10) is excluded.
          -- UserParam is 10.
          -- MaxLen is 12.
        end -- if

        -- NEW: Correct item parameters
        --far.Show(unpack(item))
        for k, v in pairs(item_map) do
          if item[k] ~= nil then
           item[v] = item[k]
          elseif item[v] == nil then
            item[v] = item_defs[k]
          end
        end

        setmetatable (item, item_meta)

        rawset (self, #self+1, item) -- table.insert (self, item)
        self[mapkey][item_name] = item
      end,

  __index = function (self, key) return rawget (self, mapkey)[key] end
}


-- Dialog constructor
function Package.NewDialog ()
  return setmetatable ({ [mapkey]={} }, dialog_meta)
end

local iSel, iLst, iDat = item_map.Selected, item_map.ListItems, item_map.Data

function Package.LoadData (aDialog, aData)
  for _,item in ipairs(aDialog) do
    if not (item._noautoload or item._noauto) then
      if CheckItemType(item, "DI_CHECKBOX", "DI_RADIOBUTTON") then
        if aData[item.name] == nil then --> nil==no data; false==valid data
          item[iSel] = item[iSel] or 0
        else
          item[iSel] = aData[item.name] and 1 or 0
        end
      elseif CheckItemType(item, "DI_EDIT", "DI_FIXEDIT") then
        item[iDat] = aData[item.name] or item[iDat] or ""
      elseif CheckItemType(item, "DI_LISTBOX", "DI_COMBOBOX") then
        local SelectIndex = aData[item.name] and aData[item.name].SelectIndex
        if SelectIndex then item[iLst].SelectIndex = SelectIndex end
      end
    end
  end
end

function Package.SaveData (aDialog, aData)
  for _,item in ipairs(aDialog) do
    if not (item._noautosave or item._noauto) then
      if CheckItemType(item, "DI_CHECKBOX", "DI_RADIOBUTTON") then
        aData[item.name] = (item[iSel] ~= 0)
      elseif CheckItemType(item, "DI_EDIT", "DI_FIXEDIT") then
        aData[item.name] = item[iDat]
      elseif CheckItemType(item, "DI_LISTBOX", "DI_COMBOBOX") then
        aData[item.name] = aData[item.name] or {}
        aData[item.name].SelectIndex = item[iLst].SelectIndex
      end
    end
  end
end

function Package.LoadDataDyn (hDlg, aDialog, aData)
  for _,item in ipairs(aDialog) do
    if not (item._noautoload or item._noauto) then
      local name = item.name
      if CheckItemType(item, "DI_CHECKBOX", "DI_RADIOBUTTON") then
        aDialog[name]:SetCheck(hDlg, aData[name])
      elseif CheckItemType(item, "DI_EDIT", "DI_FIXEDIT") then
        aDialog[name]:SetText(hDlg, aData[name])
      end
    end
  end
end

function Package.SaveDataDyn (hDlg, aDialog, aData)
  for _,item in ipairs(aDialog) do
    if not (item._noautosave or item._noauto) then
      if CheckItemType(item, "DI_CHECKBOX", "DI_RADIOBUTTON") then
        aDialog[item.name]:SaveCheck(hDlg, aData)
      elseif CheckItemType(item, "DI_EDIT", "DI_FIXEDIT") then
        aDialog[item.name]:SaveText(hDlg, aData)
      end
    end
  end
end

return Package

-- Adding item example:
-- dlg = dialog.NewDialog()
-- dlg.cbxCase = { "DI_CHECKBOX", 10, 4, 0, 0, 0, 0, 0, 0, "&Case sensitive" }
