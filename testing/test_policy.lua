
ctxdata.config.test = nil
context.config.register{ key = 'test' }

local msg = ''
for k, v in pairs(ctxdata.config.test) do
    msg = ("%s\n%s - %s"):format(msg, k, tostring(v))
end
far.Message(msg)
