-- BLINKER
-- version 1.2.0
-- can be used with mesecons-luacontroller and pipeworks luacontrolled tube
-- 
-- blinks with pre-configured rate
-- can be turned on|off
-- can automatically turn on after programming
-- Will automatically turn off when no sinal on detector for some wait time
-- (if wait_time > 0 and detector port is defined)
-- Can blink in different phase
-- Can accept and send digiline messages
-- 
-- 
-- License: GNU AGPL
-- Copyright Ghaydn (ghaydn@ya.ru), 2022-2024
-- 
-- https://github.com/Ghaydn/misc_minetest_scripts/blob/main/blinker_mega.lua
-- 

-----------------------------------------------------
-----------------------------------------------------
-- configurable variables----------------------------

local rate = 0.2
local sequence = { 		-- blinking sequence
	{"blue"},      		-- list or ports that will be ON at current step
	{"white"},     		-- all other ports will be OFF
	{{channel = "lcd", msg = "Bang!"}}  -- can also periodically send digiline messages
--	{},            		-- there can be also empty steps with all ports off
--	{"red", "blue", {channel = "foo", msg = "bar"}},    -- any reasonable number of steps is allowed
}

--- These variables can be undefined
local switch = "red"      		-- if undefined, then autostart will be enabled anyway
local autostart = false			-- if true, will autostart even if switch is defined

local detector-- = "black"      -- if defined, then after wait time blinker will automatically
-- detector = "self"        	-- "self" means that detector is this tube detecting an item
local wait_time = 5				-- turn off if there will be no new signals on detector port

local killswitch-- = "green"  	-- will immediately stop on signal from this port
-- killswitch = "self"
-- can also be "self", then an item passing through is acting as a killswitch

-- Switch, killswitch and detector can also be digiline channel names.
-- "Switch" channel accept messages "on" and "off"
-- Other channels accept any messages

-- alternatively, it can accept digiline commands by this channel
local digiline_channel = "blinker"

-- messages can be:
-- "on", "start", {command = "start"} - starts blinking
-- "off", "stop", {command = "stop"} - stops blinking
-- {command = "detected"} - acts like a detector
--
-- {command = "configure",     -- changes parameters, such as:
--    sequence = {},              --
--    rate = 0.2                  --
--    sorting = {}                --
-- }

-- if any input port is defined, then this port will be skipped while playing the sequence


-- Lua tubes only
local sorting = {
	
	["default:aspen_leaves"] = "blue",
	["ethereal:orange_leaves"] = "blue",
	["misc"] = "black",

}
-----------------------

-----------------------------------------------------
-----------------------------------------------------
-- FUNCTIONS-----------------------------------------
	
local blink = function()
  for p, v in pairs(port) do
	port[p] = false
  end
  
  for _, p in ipairs(mem.var.sequence[mem.var.step]) do
	if type(p) == "string" then
		if p ~= switch and p ~= killswitch and p ~= detector then  
			port[p] = true
		end
	elseif type(p) == "table" then
		if p.channel ~= nil and p.msg ~= nil then
			digiline_send(p.channel, p.msg)
		end
	end
  end

  mem.var.step = mem.var.step + 1
  if mem.var.step > #mem.var.sequence then mem.var.step = 1 end
end

-----------------------------------------------------

local start_blink = function()
  mem.var.time = 0
  mem.var.step = 1
  mem.var.blink = true
  interrupt(mem.var.rate, "blink")
  blink()
end

-- set all ports off
local end_blink = function()
  mem.var.blink = false
  for p, _ in pairs(port) do
	port[p] = false
  end
  
end

-----------------------------------------------------
-----------------------------------------------------
-- EVENTS--------------------------------------------

if event.type == "program" then
  mem.var = {
	blink = false,
	step = 1,  
	time = 0,
	sequence = sequence,
	rate = rate,
	sorting = sorting,
  }

  if not switch or autostart then
	start_blink()
  end
end


---Main timer
if event.type == "interrupt" and event.iid == "blink" then
  if mem.var.blink then
	blink()  
	if wait_time and wait_time > 0 and detector then
		
	  -- add time only if no signal on detector
	  if port[detector] then
		mem.var.time = 0
	  else
		mem.var.time = mem.var.time + mem.var.rate
	  end
	  
	  if mem.var.time > wait_time then
        end_blink()
	  else
		interrupt(mem.var.rate, "blink")  
	  end
	else  
      interrupt(mem.var.rate, "blink")
	end
  end
end

-----------
-- Switch OFF

if event.type == "off" then
  local prt = event.pin.name:lower()
  --Switch
  if prt == switch then
	  end_blink()
  end
end

---Inputs
if event.type == "on" then
  local prt = event.pin.name:lower()
	
  --Switch
  if prt == switch and not mem.var.blink then
      start_blink()
  
  --Detector  
  elseif prt == detector then
    mem.var.time = 0
	
  --Killswitch
  elseif prt == killswitch then
	end_blink()  
  end
end

---------
-- items (lua tubes only)

if event.type == "item" then
	
	-- reset wait time if self is detector
	if detector == "self" then
		mem.var.time = 0
	end
	
	-- immediately stop if an item is passing through
	if killswitch == "self" then
		end_blink()
	end
	
	local item = event.item.name
	
	-- sort items here
	for template, tube in pairs(mem.var.sorting) do
		if item == template then return tube end
	end
	
	return mem.var.sorting.misc
end

----------

if event.type == "digiline" then
	
	if event.channel == switch then
		if event.msg == "on" then
			start_blink()
		elseif event.msg == "off" then
			end_blink()
		end
	elseif event.channel == detector then
		mem.var.time = 0
	elseif event.channel == killswitch then
		end_blink()
	elseif channel == digiline_channel then
		local msg = event.msg
		if type(msg) == "string" then
		
			if msg == "on" or msg == "start" then
				start_blink()
				
			elseif msg == "off" or msg == "stop" then
				end_blink()
			end
			
		elseif type(msg) == "table" then
		
			if msg.command == "start" or msg.command == "on" then
				start_blink()
				
			elseif msg.command == "stop" or msg.command == "off" then
				end_blink()
				
			elseif msg.command == "detected" then
				mem.var.time = 0
				
			elseif msg.command == "configure" then
			
				if msg.sequence ~= nil and type(msg.sequence) == "table" then
					mem.var.sequence = msg.sequence
				end
				
				if msg.rate ~= nil and type(msg.rate) == "number" and msg.rate > 0 then
					mem.var.rate = msg.rate
				end
				
				if msg.sorting ~= nil and type(msg.sorting) == "table" then
					mem.var.sorting = msg.sorting
				end
				
			end
		end
	end
end
