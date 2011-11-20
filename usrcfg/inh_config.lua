--[[ User data ]]--

----------------------------------------
--[[ description:
  -- Configuration with inherit using.
  -- Конфигурация с использованием inherit.
--]]
--------------------------------------------------------------------------------
local data = {
  --_meta_ = { basis = 'user', merge = 'none' },
  _meta_ = { basis = 'common', merge = 'strange' },
  -- param values for check inheritance:
  source  = { param = 'from source' },
  main    = { param = 'from main' },
  -- param value is from 'main' as type inheritance:
  lua     = { other = 'from lua' },
  -- param value is from 'source' as data inheritance:
  lua_inh = { other = 'from lua_inh', inherit = 'source' },
} --

return data
--------------------------------------------------------------------------------
