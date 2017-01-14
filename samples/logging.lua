--[[ Logging ]]--
--[[ Логирование ]]--

----------------------------------------
--[[ description:
  -- Sample: Logging table.
  -- Пример: Логирование таблицы.
--]]
----------------------------------------
--[[ uses:
  serial,
  LuaFAR.
  -- group: Debug.
--]]
--------------------------------------------------------------------------------

local serial = require "serial"

--------------------------------------------------------------------------------
local unit = {}

----------------------------------------
function unit.StrToTab (s) --> (table)

  local t, n = {}, 0

  s:gsub("[^\n]+", function (v)
                     n = n + 1
                     t[n] = v

                   end)
  t.n = n

  return t

end ---- StrToTab

function unit.SaveToTable (name, value)

  local s = serial.SaveToString(name, value)

  return unit.StrToTab(s)

end ----

function unit.Show (data, name) --| (menu)

  return far.Show(unpack(unit.SaveToTable(name or "data", data)))

end ----

--------------------------------------------------------------------------------
return unit
--------------------------------------------------------------------------------
