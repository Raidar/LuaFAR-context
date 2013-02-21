--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- Configuration data management.
  -- Управление данными конфигураций.
--]]
----------------------------------------
--[[ uses:
  LuaFAR,
  LF context.
  -- group: LFc scripts, Datas.
--]]
--------------------------------------------------------------------------------

local pairs = pairs

----------------------------------------
local far = far
local F = far.Flags

----------------------------------------
local context, ctxdata = context, ctxdata

local types = ctxdata.config.types
local abstypes = ctxdata.abstypes or {}

--------------------------------------------------------------------------------
local unit = {}

---------------------------------------- Types
do
   -- Sort abstract types.
   local absorted = {}
   for k in pairs(abstypes) do
     absorted[#absorted] = k
   end
   table.sort(absorted)

   -- Types compare function for sort.
   local function sortTypes (a, b) --> (bool)
     --return a.type < b.type
     return a.desc < b.desc
   end

   local getAbstractType = context.detect.use.nomaskType

   local itemFormat = '%3i %s %20.20s'
   local menuFlags = { FMENU_AUTOHIGHLIGHT = 1, FMENU_WRAPMODE = 1, }
   local menuProps = { Flags = menuFlags, Title = "Categories", }
   local catMenuProps = { Flags = menuFlags, Title = "Types", Bottom = "BackSpace", }

-- Types menu-manager.
function unit.showTypes (selected)
    local categories = {}

    local datas = require 'context.utils.useDatas'
    local cfgpairs = datas.cfgpairs

    -- Find categories and owned types.
    for k, v in cfgpairs(types) do
      if not abstypes[k] then
      --if v.masks then
        local cat = v.inherit and getAbstractType(v.inherit) or 'none'
        if not categories[cat] then -- new category:
            categories[cat] = { type = cat, desc = types[cat].desc or cat, }
            table.insert(categories, categories[cat])
        end
        -- new type in category:
        table.insert(categories[cat],
                     { type = k, inherit = cat, desc = v.desc or k, })
      end
    end

    -- Sort categories and owned types.
    table.sort(categories, sortTypes)
    for i = 1, #categories do
        table.sort(categories[i], sortTypes)
    end

    -- Menu items for categories and owned types.
    local item, selcat, selitem, flag
    for i = 1, #categories do
        local cat = categories[i]
        cat.text = itemFormat:format(i, ' ', cat.desc)
        cat.id = i
        for j = 1, #cat do
            item, flag = cat[j], ' '
            if item.type == selected then
                catMenuProps.SelectIndex = j
                selcat, selitem, flag = cat, j, '*'
            end
            item.text = itemFormat:format(j, flag, item.desc)
        end
    end

    -- Menu for choice of type.
    local bkey = { BreakKey = 'BACK', }
    local bkeys = { bkey }
    catMenuProps.Title = selcat and selcat.desc or 'Types:'
    local result = selcat and far.Menu(catMenuProps, selcat, bkeys) or bkey
    menuProps.SelectIndex = selcat and selcat.id
    while result and result.BreakKey do
        local cat, flag = far.Menu(menuProps, categories)
        if not cat then return selected end
        menuProps.SelectIndex = flag
        catMenuProps.Title = cat.desc or cat.type
        catMenuProps.SelectIndex = selcat and flag == selcat.id and selitem or nil
        result = far.Menu(catMenuProps, cat, bkeys)
    end
    return result and result.type or selected
end ---- showTypes

end -- do

-- Choose type for areaid.
function unit.chooseType (areaid)
  local newtype = unit.showTypes(areaid.type)
  if newtype then context.handle.changeType(areaid, newtype) end
end ----

do
  local areas = { -- Area with types:
    [F.WTYPE_VIEWER] = 'viewers',
    [F.WTYPE_EDITOR] = 'editors',
  } ---

-- Choose type for current FAR area.
function unit.chooseCurrentType ()
  local area = areas[far.AdvControl(F.ACTL_GETWINDOWINFO, -1).Type or '']
  if not area then return end

  local areaCfg = ctxdata[area]
  if not areaCfg then return end
  unit.chooseType(areaCfg.current)
end --

end -- do

---------------------------------------- Additional
do
  local editors = ctxdata.editors
  local viewers = ctxdata.viewers

  if not editors or not viewers then
    far.Message("No editors or viewers table",
                "manageData script", nil, nil)
  end

  local s = tostring
  local LineFmt = '%s| %#2s %#8s - %s'
  local LineSep = ('-'):rep(1+2+2+1+8+3+15)
  local LineCap = LineFmt:format('-', '#', 'type', 'description')

function unit.showFileList ()
  local types, tp = types
  local t = { LineCap, LineSep }
  -- current open file:
  if rawget(editors, 'current') then
    tp = editors.current.type
    t[3] = LineFmt:format('e', '*', s(tp), s(types[tp].desc))
    t[4] = LineSep
  elseif rawget(viewers, 'current') then
    tp = viewers.current.type
    t[3] = LineFmt:format('v', '*', s(tp), s(types[tp].desc))
    t[4] = LineSep
  end

  -- other open files:
  for k, v in pairs(editors) do
    if k ~= 'current' then
      tp = v.type
      t[#t+1] = LineFmt:format('e', s(k), s(tp), s(types[tp].desc))
    end
  end
  for k, v in pairs(viewers) do
    if k ~= 'current' then
      tp = v.type
      t[#t+1] = LineFmt:format('v', s(k), s(tp), s(types[tp].desc))
    end
  end

  local s = #t > 2 and table.concat(t, '\n') or ''
  far.Message(s ~= '' and s or "No open files",
              "Open files list", nil, s ~= '' and 'l' or nil)
end ---- showFileList

end -- do

--------------------------------------------------------------------------------
context.manage = unit -- 'manage' table in context
--------------------------------------------------------------------------------
