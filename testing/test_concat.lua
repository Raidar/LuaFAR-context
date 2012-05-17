--[[ LuaFAR context ]]--
--[[ tables.concat test ]]--

local utils = require 'context.utils.useUtils'
local tables = require 'context.utils.useTables'

utils.message('tables.concat', tables.concat('12', nil, 'qwerty', nil, 'abc'))
