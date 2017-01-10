--[[ LFc testing ]]--

----------------------------------------
--[[ description:
  -- Test: Handling configuration (descs_config).
  -- Тест: Обработка конфигурации (descs_config).
--]]
--------------------------------------------------------------------------------

----------------------------------------
local ctxdata = ctxdata
local types = ctxdata.config.types

----------------------------------------
local descs = require "context.cfg.descs_config"
--context.config.register{ key = 'type_descs', name = 'descs', mode = 'asmeta'}

----------------------------------------
local function type_desc (ctype)

  return types[ctype] and types[ctype].desc or "" -- "none"

end --

local function typeDesc (ctype)

  return descs[ctype] or "" -- "none"

end --

---------------------------------------- main
do
  local StrFmt = "%#7s : %#16s | %s"

  local tps = { 'lua', 'main', 'config', 'ini', 'reg', 'awk' }
  local t = { StrFmt:format("type", "type desc", "Full type description") }

for _, tp in pairs(tps) do
  t[#t + 1] = StrFmt:format(tp, type_desc(tp), typeDesc(tp))

end

far.Message(table.concat(t, "\n"), "types short and full descriptions", nil, "l")

end -- do
--------------------------------------------------------------------------------
