--[[ LuaFAR context ]]--
--[[ tables.concat test ]]--

local utils = context.utils
local tables = context.tables

utils.message('tables.concat', tables.concat('12', nil, 'qwerty', nil, 'abc'))
