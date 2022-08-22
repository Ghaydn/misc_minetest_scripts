--Drawer helper
--Version 1.0
--
--helps to fill drawer from a chest
--uses LCD display to show if all ok or if something stuck
--switches to the idle (slow) mode if no items is detected last 3 cycles
--
--License: GNU AGPL
--Copyright Ghaydn (ghaydn@ya.ru), 2021
--
--Ver
--
--https://github.com/Ghaydn/misc_minetest_scripts/blob/main/drawer_helper.lua


-----------------------------------------------------
-----------------------------------------------------
-- configurable variables----------------------------

-- port colors
local drawer = "black"     -- TUBE: where to send items
local loop = "yellow"      -- TUBE: where to send items on error
local switch = "blue"      -- PIN: turn on/off switch
local detector = "yellow"  -- PIN: error detector
local blink = "white"	   -- PORT: where to blink to get items
local alarm = "red"        -- PORT: alarm light (mese signal)

-- rates
local blink_rate = 1
local idle_rate = 10
local wait_time = 3        -- if errors appear faster than this delay then enter to alarm state

local lcd = "lcd" -- name of lcd channel
------------------------


-----------------------------------------------------
-----------------------------------------------------
-- Events--------------------------------------------

-- Startup
if event.type == "program" then
	mem.var = {
		state = "ready",
		last_item = "",
		prelast_item = "",
		slow_down = 0,
		last_error = 0
	}
	digiline_send(lcd, "Standby...")
end


-- Item event
if event.type == "item" then
	
  -- normal state: send items to the drawer
	if mem.var.state == "on" then
		local itemname = event.item.name
		mem.var.prelast_item = mem.var.last_item
		mem.var.last_item = itemname
		-- reset slow mode if any item passed
		mem.var.slow_down = 0
		-- show itemname on the LCD
		digiline_send(lcd, "Last item: \n" .. itemname)
		return drawer
	
		-- other states: send items back to the chest  
	else
		return loop
	end
  
end

-- Input event
if event.type == "on" then
	local pin = event.pin.name:lower()
	
	-- Turned on
	if pin == switch then
		if mem.var.state == "off" or mem.var.state == "ready" then
			mem.var.state = "on"
			interrupt(blink_rate, "blink")
			port[blink] = true
		end
	
	-- Got an error signal: items went to the wrong tube
	elseif pin == detector then
		-- panic only if was in normal mode
		if mem.var.state == "on" then
			
			local time = os.datetable()
			
			-- this must be enough
			local err_time = time.sec + time.min * 60 + time.hour * 3600
			
			-- remember last error time and item
			if math.abs(mem.var.last_error - err_time) > wait_time then
				mem.var.stuck = mem.var.prelast_item
				mem.var.last_error = err_time
				
			-- okay, now it's an error
			else
				mem.var.state = "error"
				digiline_send(lcd, "Item STUCK: " .. mem.var.stuck)
			end
			
		end
	end

end

-- Turn off
if event.type == "off" then
	local pin = event.pin.name:lower()
	
	-- Turned on
	if pin == switch then
		mem.var.state = "off"
		digiline_send(lcd, "Drawer helper OFF")
		port[blink] = false
	end
end

-- various blinking events
if event.type == "interrupt" then
	
	-- bling main port in normal state
	if mem.var.state == "on" then
		port[blink] = not port[blink]
		
		-- turn to slow mode if no items passed in 5 blinks
		mem.var.slow_down = mem.var.slow_down + 1
		if mem.var.slow_down < 5 then
			-- fast mode blinking
			interrupt(blink_rate, "blink")
		else
			-- slow mode blinking
			interrupt(idle_rate, "blink")
			digiline_send(lcd, "IDLE. Last item: \n" .. mem.var.last_item)
		end
	
	-- blink alarm port in error state
	elseif mem.var.state == "error" then
		port[blink] = false
		-- caption will show and hide
		if port[blink] then
			digiline_send(lcd, "Item STUCK: " .. mem.var.stuck)
		else
			digiline_send(lcd, " ")
		end
		interrupt(blink_rate, "blink")
	else
		port[blink] = false
	end
end
