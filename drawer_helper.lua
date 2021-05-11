--Drawer helper
--helps to fill drawer from a chest
--uses LCD display to show if all ok or if something stuck
--switches to the idle (slow) mode if no items is detected last 3 cycles

--configurable variables: ports and blink rate
local drawer = "black" --not really intended
local loop = "yellow"
local blink = "white"
local blink_rate = 1
local idle_rate = 10
------------------------


if event.type == "program" then
  mem.var = {
    state = "ready",
    last_item = "",
    prelast_item = "",
    slow_down = 0,
    draw = false,
  }
  digiline_send("lcd", "Standby...")
end

if event.type == "item" then
  if mem.var.state == "on" then
    local itemname = event.item.name
    local position = itemname:find(":")
    local length = itemname:len()
    local output = itemname:sub(1, position) .. "\n"
    while position < length do
      output = output .. itemname:sub(position + 1, position + 12) .. "\n"
      position = position + 12
    end
    mem.var.prelast_item = mem.var.last_item
    mem.var.last_item = output
    mem.var.slow_down = 0
    digiline_send("lcd", "Last item: \n" .. output)
  else
    return loop
  end
end

if event.type == "on" and mem.var.state ~= "on" then
  mem.var.state = "on"
  interrupt(blink_rate, "blink")
  port[blink] = true
end

if event.type == "off" then
  mem.var.state = "off"
  digiline_send("lcd", "Drawer helper OFF")
  port[blink] = false
end

if event.type == "interrupt" then
  if mem.var.state == "on" then
    port[blink] = not port[blink]
    mem.var.slow_down = mem.var.slow_down + 1
    if mem.var.slow_down < 5 then
      interrupt(blink_rate, "blink")
    else
      interrupt(idle_rate, "blink")
      digiline_send("lcd", "IDLE. Last item: \n" .. mem.var.last_item)
    end
  elseif mem.var.state == "error" then
    port[blink] = false
    mem.var.draw = not mem.var.draw
    if mem.var.draw then
      digiline_send("lcd", "Item STUCK: " .. mem.var.prelast_item)
    else
      digiline_send("lcd", " ")
    end
    interrupt(blink_rate, "blink")
  else
    port[blink] = false
  end
end

if event.type == "digiline" and event.channel == "error" then
  if mem.var.state == "on" then
    mem.var.state = "error"
    digiline_send("lcd", "Item STUCK: " .. mem.var.prelast_item)
  end
end
