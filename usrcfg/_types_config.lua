--[[ User data ]]--

----------------------------------------
--[[ description:
  -- Used types.
  -- Используемые типы.
--]]
----------------------------------------
--[[
  -- CHOOSE merge mode in _meta_ field of table!
  -- DON'T use mode { basis = 'user', merge = 'none' }
     for types because default types are lost.
--]]
--------------------------------------------------------------------------------
local types = {
  _meta_ = { basis = 'base', merge = 'update' },

  -- types for localization test
  --_itself_ = { inherit = '_itself_', desc = '_itself_ inherit' },
  --_indir_1_ = { inherit = '_indir_2_', desc = '_indirect_ inherit 1' },
  --_indir_2_ = { inherit = '_indir_1_', desc = '_indirect_ inherit 2' },

  -- ADD new types here!
  --newlang = { inherit = 'main', desc = 'New language',
  --            masks = {'%.newlang$'}, firstline = {'^#!%s-%S*new-lang'} },
} --- types

return types
--------------------------------------------------------------------------------
