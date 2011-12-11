local far23 = context.use.far23
local dlgHandler=require 'context.utils.dlgHandler'

local flags = far.Flags
local descriptors = ctxdata.descriptors
local configure
local dialog
local history={}
local calledFunction

local Guid = win.Uuid("22b07e07-c09f-4a0a-864a-8523f3a1c5ce")

local function setForEach (array, key, value)
    for k, v in pairs(array) do
       if type(v) == 'table' then
           rawset(v, key, value)
       end
    end
end

local function cyclednext (t, i)
    local ni, nv = i + 1, t[i + 1]
    if not nv then
      ni, nv = 1, t[1]
    end
    return ni, nv
end

local function copySizes (t1, t2, shifty)
    for i = 2, 5 do
        t2[i] = t1[i] + (i%2==1 and shifty or 0)
    end
end

local function equal (a,b)
    return type(a) == type(b) and a == b
end

local messages = {
    emptyDsc = { 'Empty descriptor', 'Warning', false, 'w' },
    unsupportedVal = 'Value "%s" is unsupported.',
}

local function setInitialValue (dsc)
    if dsc.tbl then return { _meta_ = { _gencfg = {} } } end
    if dsc.edt then
        if dsc.edt[1] then return dsc.edt[1] end
        if dsc.edt.accept then return dsc.edt.accept() end
        return ''
    end
    return nil
end

local comboLists = {}
local function makeListFromTable (value, tbl, mode, twolevels)
    if comboLists[tbl] then return comboLists[tbl] end
    local mode = mode or 'keys'
    local t = { _elements_ = {} }
    comboLists[tbl]=t

    local argtbl
    local makeList

    if mode == 'keys' then
        makeList = function (atbl)
            for k, v in pairs(atbl) do
                if type(k) == 'string' and not k:match('^_') then
                    local el = { Text = k }
                    if el.Text= = value then
                        el.Flags = { LIF_SELECTED = true }
                    end
                    table.insert(t, el)
                    t._elements_[k] = #t


                end
            end
        end
    elseif mode == 'values' then
        makeList = function(atbl)
            for i = 1, #atbl do
                local el = { Text = atbl[i] }
                if el.Text == value then
                    el.Flags = { LIF_SELECTED = true }
                end
                table.insert(t, el)
                t._elements_[atbl[i]] = #t
            end
        end
    else
        return {}
    end

    if twolevels then
        for i = 1, #tbl do
            makeList(tbl[i])
        end
    else
        makeList(tbl)
    end

    table.sort(t, function (a, b) return a.Text < b.Text end)
    return t
end

local function makeEdtFld (dsc, value, cvalue)
    local value = value or setInitialValue(dsc)
    local res
    if dsc.tbl then
        res = { "DI_BUTTON",       0,0,0,0,    0,0,{},0, 'Edit', tbl=value, dsc=dsc.tbl}
    elseif dsc.edt then
        if dsc.edt.sources then
           res = { "DI_COMBOBOX",     0,0,0,0,  0,
                                    makeListFromTable(value, dsc.edt.sources, 'keys', true),
                                    { DIF_DROPDOWNLIST=dsc.edt.limit,
                                      DIF_LISTWRAPMODE=true }, 0, iterable=true, dsc=dsc.edt }
        elseif #dsc.edt>0 then
           res = { "DI_COMBOBOX",     0,0,0,0,  0,
                                    makeListFromTable(value, dsc.edt, 'values'),
                                    { DIF_DROPDOWNLIST=dsc.edt.limit,
                                      DIF_LISTWRAPMODE=true }, 0, tostring(value), iterable=true, dsc=dsc.edt }
        else
            res = { "DI_EDIT",     0,0,0,0,    0,0,{},0, tostring(value), dsc=dsc.edt}
        end
    end

    if not res then
        --far.Message('Unknown type', '', nil, 'w')
        return
    end
    res.value = value
    res.initvalue = value
    res.edt = true
    return res
end

local dialogLine={ chkStates={ [0]=false, [1]=true, [3]=nil } }
dialogLine.__mt={ }

function dialogLine.__mt.__newindex (t, k, v)
    rawset(t, k, v)
    if type(v) == 'table' then v.line = t end
end

function dialogLine.__mt.__index (t, k)
    if k=='value' then
        return t.chk.value and t.edt and t.edt.value or t.chk.value
    end
    return dialogLine[k]
end

function dialogLine.switchChk (line, handle, id, state)
    line.chk.value = dialogLine.chkStates[state]

    local ast = line.ast
    if ast then
        local hidden = equal(line.initvalue, line.value)
        ast[8].DIF_HIDDEN = hidden
        handle:show(ast.id, hidden and 0 or 1)
    end
    if not line.edt then
        handle:redraw()
        return true
    end

    handle:enable(line.edt.id, line.chk.value and 1 or 0)
    handle:redraw()
end

function dialogLine.editChange (line, handle, id, el)
    if line.edt then
        local newval = handle:getText(line.edt.id)
        line.edt[10]   = newval
        line.edt.value = newval
    end

    local ast = line.ast
    if not ast then return false end
    local hidden = equal(line.initvalue, line.value)
    ast[8].DIF_HIDDEN = hidden
    handle:show(ast.id, hidden and 0 or 1)

    return true
end

function dialogLine.editCheck (line, handle, id, el)
    local edt = line.edt
    if not edt then return end

    if type(edt.ListItems) == 'table' and
       edt.ListItems._elements_[edt.value] then
        return
    end

    if edt.dsc.accept then
        edt.value = edt.dsc:accept(edt.value)
    end

    local ast = line.ast
    if not edt.value then
       edt.value = edt.initvalue
       edt.Data  = edt.value

       handle:setText(edt.id, edt.value)
       if ast then ast[8].DIF_HIDDEN = true end
       handle:redraw()
       return
    end

    if ast then
        local hidden=equal(line.initvalue, line.value)
        ast[8].DIF_HIDDEN=hidden
        handle:show(ast.id, hidden and 0 or 1)
    end
end

function dialogLine.new ()
    local t = {}
    setmetatable(t, dialogLine.__mt)
    return t
end

local function makeLine (key, value, dsc)
    local line = dialogLine.new()
    line.initvalue = value
    line.name = key and
        {"DI_TEXT",         0,0,0,0,    0,0,0,0,
         dsc.key.toName and dsc.key.toName(key) or key, dsc = dsc} or
        dsc.key.sources and
        { "DI_COMBOBOX",     0,0,0,0,  0,
         makeListFromTable(nil, dsc.key.sources, 'keys', true),
         { DIF_DROPDOWNLIST = false, DIF_LISTWRAPMODE = true }, 0 } or
        {"DI_EDIT",         0,0,0,0,    0,0,0,0, ''}
    local chkstate = type(value) == 'nil' and 2 or value and 1 or 0
    line.chk = { "DI_CHECKBOX",  0,8,0,0,    0, chkstate, { DIF_3STATE=true }, 0, value=value}
    line.ast = { "DI_TEXT", 0,0,0,0,    0,0, { DIF_HIDDEN=true }, 0, "*" }
    line.edt = makeEdtFld(dsc, value)
    if line.edt then
        line.edt[8].DIF_DISABLE = not value
        line.edt.line=line
    end
    return line
end

local function addNewElement (handle)
    local dlgArgs = history[#history]
    if not (dlgArgs.activeElement == 'list' or dlgArgs.activeElement == 'array') then
        return false
    end
    local dialog = dlgArgs.dialog
    local lines = dlgArgs.lines

    if dlgArgs.activeElement == 'list' then
        local dsc = dlgArgs.dsc.list
        local line = makeLine(nil, setInitialValue(dsc), dsc)
        if not line then return false end

        calledFunction = function ()
            local lastline=lines[#lines]
            copySizes(lastline.name, line.name, 1)
            table.insert(lines, line)
            dialog._ = line.name
            dlgArgs.focus = line.name.id

            local ast = { "DI_TEXT", 0,0,0,0, 0, 0, {DIF_HIDDEN=false}, 0, "*" }
            dialog._ = ast
            line.ast = ast

            local chk = { "DI_CHECKBOX",  0,0,0,0,    0,line.edt and 1 or 2, { DIF_3STATE=true },0 }
            line.chk = chk
            dialog._ = chk

            copySizes(lastline.ast, line.ast, 1)
            copySizes(lastline.chk, line.chk, 1)
            copySizes(lastline.edt, line.edt, 1)
            dialog._ = line.edt
            far.Dialog(Guid, unpack(history[#history],1,8))
        end
    else
        --TODO: array
        far.Message ' array '
        return false
    end

    handle:close()
    return true
end

local function iterateElement (handle, id, element)
    if not element or not element.iterable then return false end

    if element.Type == 'DI_COMBOBOX' then
        local pos = handle:getListPos(element.id)
        local items = element[7]
        pos.SelectPos = pos.SelectPos+1
        if pos.SelectPos > #items then pos.SelectPos = 1 end
        handle:setListPos(element.id, pos)
        handle:redraw()
        return true
    end

    far.Message 'haha here'
    return true
end

local function dlgProc (hndl, msg, p1, p2)
    local handle = dlgHandler(hndl)

    local dlgargs = history[#history]
    local dialog = dlgargs.dialog

    p1 = p1+1
    if msg == flags.DN_DRAWDIALOG then
        if dlgargs.focus then
            handle:focus(dlgargs.focus)
            return true
        end

    elseif msg == flags.DN_EDITCHANGE then
        return dialog[p1].line:editChange(handle, p1, p2)

    elseif msg == flags.DN_CONTROLINPUT then -- FAR3: p2 теперь InputRecord.
        local VirKey = far.ParseInput(Input) -- FAR23
        if not VirKey then return false end
        --if not VirKey then return DlgMouseClick(hDlg, p1, p2) end

        local key = far.FarInputRecordToName(VirKey)
        if key == 'BS' then
            if dialog[p1].Type~='DI_EDIT' and dialog[p1].Type~='DI_COMBOBOX' and #history>1 then
                table.remove(history, #history)
                dialog=history[#history].dialog
                --TODO: save focus
                calledFunction = function() far.Dialog(unpack(history[#history],1,8)) end
                handle:close()
                return true
            end
        elseif key == 'Enter' then
            return iterateElement(handle, p1, dialog[p1])
        elseif key == 'Ins' then
            return addNewElement(handle)
        end
        return false

    elseif msg == flags.DN_BTNCLICK then
        if dialog[p1].tbl then
           dlgargs.focus=p1-1
           configure(dialog[p1].tbl, dialog[p1].dsc)
           handle:close()
           return true
        elseif dialog[p1].line then
           return dialog[p1].line:switchChk(handle,p1,p2)
        elseif dialog[p1].switch and dlgargs.lastFocus then
           return chahgeElementType(handle, dlgargs.lastFocus, dialog[dlgargs.lastFocus])
        elseif dialog[p1].new then
           return addNewElement(handle)
        end

    elseif msg==flags.DN_GOTFOCUS then
        if dialog[p1].edt then
            dlgargs.lastFocus=p1-1
        end

    elseif msg==flags.DN_KILLFOCUS then
        if dialog[p1].line then
            return dialog[p1].line:editCheck(handle, p1, p2)
        end
--    elseif msg==flags.DN_CLOSE then
    end
end

configure = function(tbl, dsc, show)
    local dlgLines, activeElement = {}
    if show and show=='opts' or dsc.options then
        local opts,opt=dsc.options
        for i=1,#opts do
            opt=opts[i]
            local val
            if tbl._meta_ and tbl._meta_._gencfg and tbl._meta_._gencfg[opt.key] then val=nil
            else val=tbl[opt.key] end
            local line=makeLine(opt.key, val, opt)
            if line then table.insert(dlgLines, line) end
        end
        activeElement='options'
    elseif  show and show=='list' or dsc.list then
        for k,v in pairs(tbl) do
            if not k:match('^_') and not tbl._meta_._gencfg[k] then
                local line=makeLine(k, v, dsc.list)
                if line then table.insert( dlgLines, line) end
            end
        end
        table.sort(dlgLines, function(a,b) return a.name[10]<b.name[10] end)
        activeElement='list'
    elseif  show and show=='array' or dsc.array then
        for i=1,#tbl do
            local line=makeOptLine(i, tbl[i], dsc.array)
            if line then table.insert( dlgLines, line) end
        end
        activeElement='array'
    else
        far.Message( 'Empty descriptor' )
        return
    end

    dialog=far2.dialog.NewDialog()
    local fw1, fw2, fw3, fw4=40,1,5,20
    local width,height,x1,y1=fw1+fw2+fw3+fw4+10,20,5,5
    local w1=49
    local w2=w1+12+12
    local dialogArgs={ x1, y1, x1+3+width, y1+3+height, nil, dialog, nil, dlgProc, lines=dlgLines, tbl=tbl, dsc=dsc, dialog=dialog, activeElement=activeElement }
    local y,x0=4,5
                   -- 01            02 03 04 05    06 07 08                                                               09  10
    dialog.opt   = { "DI_BUTTON",    1, 2, 1, 2,    0, 0, 0, { DIF_CENTERGROUP=true, DIF_NOFOCUS=true, DIF_DISABLE=true }, 0, "Options (&1)" }
    dialog.list  = { "DI_BUTTON",    1, 2, 1, 2,    0, 0, 0, { DIF_CENTERGROUP=true, DIF_NOFOCUS=true, DIF_DISABLE=true }, 0, "List (&2)"    }
    dialog.array = { "DI_BUTTON",    1, 2, 1, 2,    0, 0, 0, { DIF_CENTERGROUP=true, DIF_NOFOCUS=true, DIF_DISABLE=true }, 0, "Array (&3)"   }

    for i=1,math.min(#dlgLines, 20) do
        x=x0
        local line=dlgLines[i]
        local el=line.name
        el[2],el[3],el[4],el[5]=x,y,x+fw1,y
        dialog._=el
        el=line.ast
        x=x+fw1+2
        el[2],el[3],el[4],el[5]=x,y,x+fw2,y
        dialog._=el
        el=line.chk
        x=x+fw2+1
        el[2],el[3],el[4],el[5]=x,y,x+fw3,y
        dialog._=el
        x=x+fw3+1

        if line.edt then
            el=line.edt
            el[2],el[3],el[4],el[5]=x,y,x+fw4,y
            dialog._=el
        end
        y=y+1
    end

--    dialog._ = { "DI_TEXT",           1, height, 1, height,    0,0, { DIF_CENTERGROUP=true }, 0,                      "Fields: " }
    dialog.new    = { "DI_BUTTON",    1, height, 1, height,    0,0, { DIF_CENTERGROUP=true,
                                                                      DIF_DISABLE= activeElement=='options' },
                                                                      0,   "&New", new=true }
--    dialog._ = { "DI_TEXT",      1, height, 1, height,    0,0, { DIF_CENTERGROUP=true }, 0,                      "Changes: " }
    dialog._ = { "DI_BUTTON",    1, height, 1, height,    0,0, { DIF_CENTERGROUP=true, DIF_DISABLE=true }, 0,                      "&Undo" }
    dialog._ = { "DI_BUTTON",    1, height, 1, height,    0,0, { DIF_CENTERGROUP=true, DIF_DISABLE=true }, 0,                      "&Save" }
    dialog._ = { "DI_BUTTON",    1, height, 1, height,    0,0, { DIF_CENTERGROUP=true, DIF_DISABLE=true }, 0,                      "U&ndo all" }
    dialog._ = { "DI_BUTTON",    1, height, 1, height,    0,0, { DIF_CENTERGROUP=true, DIF_DISABLE=true }, 0,                      "S&ave all" }

    dialog._      = { "DI_SINGLEBOX",    x0-2, 3, width+1, height-1,    0,0,0,0, "" }
    dialog._ = { "DI_TEXT", width-11, height-1, width-11, height-1, 0,0, { DIF_DISABLE=true }, 0,  "[  ]" }
    dialog._ = { "DI_TEXT", width-5, height-1, width-5, height-1, 0,0, { DIF_DISABLE=true }, 0,  "[  ]" }


    dialog._      = { "DI_DOUBLEBOX",    x0-2, 1, width+1, height+2,    0,0,0,0,                                           "Configuration" }
    dialog.ok     = { "DI_BUTTON",    1, height+1, 1, height+1,    0,0, { DIF_CENTERGROUP=true }, 0,                      "&OK" }
    dialog.cancel = { "DI_BUTTON",    1, height+1, 1, height+1,    0,0, { DIF_CENTERGROUP=true }, 0,                      "&Cancel" }
    dialog.cancel = { "DI_BUTTON",    1, height+1, 1, height+1,    0,0, { DIF_CENTERGROUP=true }, 0,                      "&Back" }

    table.insert(history, dialogArgs)

    calledFunction = function() far.Dialog(unpack(dialogArgs,1,8)) end
end

local menuFlags = { FMENU_AUTOHIGHLIGHT = 1, FMENU_WRAPMODE = 1 }
local menuProps= { Flags = menuFlags, Title = "Context modules configuration" }
local function configMenu()
    history={}
    local items={}
    for k, v in pairs(descriptors) do
        local cfgs=v.configs
        for i=1, #cfgs do
            if v.dsc and type(cfgs[i])=='table' then
                table.insert(items, { text=v.dsc.titles[i] or k..' (unnamed)', tbl=cfgs[i], dsc=v.dsc })
            end
        end
    end

    local p=far.Menu(menuProps, items )
    if not p then return end
    configure(p.tbl, p.dsc)

    while calledFunction do
       local fun=calledFunction
       calledFunction=nil
       fun()
    end
end

context.configure={
    configure=configMenu,
}

configMenu()