




--- THIS IS A OLD AND OUTDATED VERSION
--- USE BLINKER_MEGA INSTEAD
--- https://github.com/Ghaydn/misc_minetest_scripts/blob/main/blinker_mega.lua
--- I'm keeping this file only for history



















--BLINKER
--version 1.0.1

--can be used with mesecons-luacontroller and pipeworks luacontrolled tube
--
--blinks with pre-configured rate
--can be turned on|off
--can automatically turn on after programming
--Will automatically turn off when no sinal on detector for some wait time
--(if wait_time > 0 and detector port is defined)
--Can blink in different phase
--
--
--License: GNU AGPL
--Copyright Ghaydn (ghaydn@ya.ru), 2022
--
--https://github.com/Ghaydn/misc_minetest_scripts/blob/main/blinker.lua
--

-----------------------------------------------------
-----------------------------------------------------
-- configurable variables----------------------------

local rate = 0.1        
local sequence = { -- blinking sequence
	{"d", "b"},    -- list or ports that will be ON at current step
	{"b"},         -- all other ports will be OFF
	{},            -- there can be also empty steps with all ports off
	{"d", "c"},    -- any reasonable number of steps is allowed
}

--- These variables can be undefined
local switch = "a"      -- if undefined, then autostart will be enabled anyway
local autostart = false

local detector-- = "b"      -- if defined, then after wait time blinker will automatically
local wait_time = 5			-- turn off if there will be no new signals on detector port

local killswitch-- = "c"  -- will immediately stop on signal from this port


-- if any input port is defined, then this port will be skipped while playing the sequence


-----------------------------------------------------
-----------------------------------------------------
-- FUNCTIONS-----------------------------------------
	
local blink = function()
  for p, v in pairs(port) do
	port[p] = false
  end
  
  for _, p in ipairs(sequence[mem.var.step]) do
	if p ~= switch and p ~= killswitch and p ~= detector then  
		port[p] = true
	end
  end

  mem.var.step = mem.var.step + 1
  if mem.var.step > #sequence then mem.var.step = 1 end
end

-----------------------------------------------------

local start_blink = function()
  mem.var.blink = true
  mem.var.time = 0
  mem.var.step = 1
  interrupt(rate, "blink")
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
		mem.var.time = mem.var.time + rate
	  end
	  
	  if mem.var.time > wait_time then
        end_blink()
	  else
		interrupt(rate, "blink")  
	  end
	else  
      interrupt(rate, "blink")
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
  if prt == switch then
      start_blink()
  
  --Detector  
  elseif prt == detector then
    mem.var.time = 0
	
  --Killswitch
  elseif prt == killswitch then
	end_blink()  
  end
end
