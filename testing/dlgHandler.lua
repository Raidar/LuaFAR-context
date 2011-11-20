local flags=far.Flags

local dlgHandler={}
local dlgMT={ __index=dlgHandler }

function dlgHandler.run(dlg)
    return far.DialogRun(dlg.handle)
end

function dlgHandler.free(dlg)
    far.DialogFree(dlg.handle)
    setmetatable(dlg, {})
    dlg.handle=nil
end

function dlgHandler.redraw(dlg)
    return far.SendDlgMessage(dlg.handle, flags.DM_REDRAW) -- FAR3: Проверить на DM_SETREDRAW.
end

function dlgHandler.close(dlg)
    return far.SendDlgMessage(dlg.handle, flags.DM_CLOSE)
end

function dlgHandler.enable(dlg, id, state)
    return far.SendDlgMessage(dlg.handle, flags.DM_ENABLE, id, state)
end

function dlgHandler.show(dlg, id, state)
    return far.SendDlgMessage(dlg.handle, flags.DM_SHOWITEM, id, state)
end

function dlgHandler.focus(dlg, id, state)
    return far.SendDlgMessage(dlg.handle, flags.DM_SETFOCUS, id, state)
end

function dlgHandler.getText(dlg, id)
    return far.SendDlgMessage(dlg.handle, flags.DM_GETTEXT, id)
end

function dlgHandler.setText(dlg, id, text)
    return far.SendDlgMessage(dlg.handle, flags.DM_SETTEXT, id, text)
end

function dlgHandler.getListPos(dlg, id)
    return far.SendDlgMessage(dlg.handle, flags.DM_LISTGETCURPOS, id)
end

function dlgHandler.setListPos(dlg, id, pos)
    return far.SendDlgMessage(dlg.handle, flags.DM_LISTSETCURPOS, id, pos)
end

local function newDialogHandler(...)
    local handle=...
    if type(handle)=='userdata' then
        return setmetatable({ handle=handle }, dlgMT)
    else
        return setmetatable( {handle=far.DialogInit(...)}, dlgMT)
    end
end

return newDialogHandler
