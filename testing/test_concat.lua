--[[ LuaFAR context ]]--
--[[ tables.concat test ]]--

local utils = context.utils
local tables = require 'context.utils.useTables'

utils.message('tables.concat', tables.concat('12', nil, 'qwerty', nil, 'abc'))
