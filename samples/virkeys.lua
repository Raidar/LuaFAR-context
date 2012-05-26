-- Key names show

local F = far.Flags
local format = string.format

local fkeys = require "far2.keynames"
local InputRecordToName = fkeys.InputRecordToName

local VKeys = win.GetVirtualKeys()

local count = 0
for k, v in pairs(VKeys) do
  if type(k) == 'number' and k > count then
    count = k
  end
end

local line = "----------------------------------------"
local t = { line }

for k = 1, count do
  local v = VKeys[k]
  if v then
    local Input = {
      EventType       = F.KEY_EVENT,
      --KeyDown         = true,
      --RepeatCount     = 1,
      VirtualKeyCode  = k,
      --VirtualScanCode = 0x00,
      --UnicodeChar     = "",
      ControlKeyState = 0x00,
    } ---
    local s = InputRecordToName(Input) or ""
    if s:len() <= 1 or s ~= s:upper() then
      t[#t + 1] = format("%s -> %s", v, s)
      Input.ControlKeyState = 0x0100 -- ENHANCED_KEY
      s = InputRecordToName(Input) or ""
      local s = format("%s -> %s", v, s)
      if s ~= t[#t] then
        t[#t + 1] = s.." (enhanced)"
      end
    end
  end
end

t[#t + 1] = line

far.Show(unpack(t))
