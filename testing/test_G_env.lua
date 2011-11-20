--undecl_var -- Undeclared variable
global_var = "global" -- Global variable

local Env = setmetatable({}, {__index = _G})
Env.other_var = "other"

local f, SError = loadfile("D:\\Lib\\Lua\\LuaFAR\\context\\testing\\test_G_scr.lua")
if not f then return far.Message(SError, "test_G_env") end

setfenv(f, Env)()
