--BLINKER
--blinks with pre-configured rate
--can be turned on|off
--slow blinker will automatically turn on after programming
--fast blinker must be turned on first

---------------------------------
--configurable variables
local blinks = {
a = "blink",
b = "blink",
c = "switch",
d = "none"
}

local rate = 0.2
----------------------------------

if event.type == "program" then
  mem.var = {blink = true}
  if rate < 1 then
     mem.var.blink = false
  else
    interrupt(0.5, "blink")
  end
end

if event.type == "interrupt" and event.iid == "blink" then
  if mem.var.blink then
    for p, v in pairs(port) do
      if blinks[p] == "blink" then
        port[p] = not v
      end
    end
  end
  interrupt(rate, "blink")
end

if event.type == "on" or event.type == "off" then
  local prt = event.pin.name:lower()
  if blinks[prt] == "switch" then
    mem.var.blink = pin[prt]
    if pin[prt] then
      if rate < 1 then
        interrupt(rate, "blink")
      end
    else
      for p, v in pairs(port) do
        if blinks[p] == "blink" then
          port[p] = false
        end
      end
    end
  end
end
