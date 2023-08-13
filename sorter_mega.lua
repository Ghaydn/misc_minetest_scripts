-- SORTER
-- version 1.0.1
-- for use with pipeworks lua tube
-- 
-- Supports 4 additional functions:
-- 1. find - just a re-implemented string.find, because normal one
-- is disabled in luacontroller
-- 2. array_find - search item name (or something else) in the array
-- of elements; array is just an indexed table
-- 3. is_mod - checks whether a string contains selected modname
-- 4. string_begins - checks whether a string begins with some substring
-- 
-- 
-- License: GNU AGPL
-- Copyright Ghaydn (ghaydn@ya.ru), 2023
-- 
-- https://github.com/Ghaydn/misc_minetest_scripts/blob/main/sorter_mega.lua
-- 



--- ports
--- you can name these as you want, depending on what's on the end of pipes

local cobble_processor = "red"
local signs_bot_chest = "green"
local plant_drawer = "blue"

local ta4_chest = "white"


-- default 
local default = "black"


--------------------------------------------------------------------------------

-- string.find is disabled in luacontroller, so let's write custom one

local function find(str, pattern)
    
    -- check length
    local pattern_len = pattern:len()
    local str_len = str:len()
    
    if str_len < pattern_len then return nil end
    
    local max_pos = str_len - pattern_len + 1
    
    -- searching here
    for pos = 1, max_pos do
        if str:sub(pos, pos + pattern_len) == pattern then return pos end
    end
    
    -- not found
    return nil

end

--------------------------------------------------------------------------------

-- search for the first exact matching value in a table that looks like an array
local function array_find(array, pattern)
	
	for i, v in ipairs(array) do
		
		if v == pattern then return i end
		
	end
	
	return nil
end

--------------------------------------------------------------------------------

-- check if this item name belongs to a specific mod
-- it's simpler than using find

local function is_mod(str, modname)
    
    local modlength = modname:len() + 1
    
    local sub = str:sub(1, modlength)
    
    return (sub == modname..":")

end

--------------------------------------------------------------------------------

local function string_begins(str, pattern)
	
	local length = pattern:len()
	
	local sub = str:sub(1, length)
	
	return (sub == pattern)
end

--------------------------------------------------------------------------------
-----   SORTING EXAMPLE  -------------------------------------------------------
--------------------------------------------------------------------------------


if event.type == "item" then

    local item = event.item.name
    
    
    ---- Example of "array_find" use
    
    local send_to_cobble = {
		"default:cobble",
		"default:gravel",
		"techage:bauxite_cobble",
		"techage:bauxite_gravel"
	}
	
	if array_find(send_to_cobble, item)
    then
        return cobble_processor
    end
    
    ---- send ores to process
    
    -- example of "is_mod" use
    
    if is_mod(item, "signs_bot")
    
    then
        return signs_bot_chest
    end
    
    ---- example of "find" use
    
    if find(item, "sapling")
    or find(item, "wood")
    or find(item, "planks")
    or find(item, "leaves")
    or find(item, "shroom") -- MUshroom or ethereal ILLUMIshroom
    or find(item, "fung")   -- fungUS, fungAL etc
    then
        return plant_drawer
    end
    
    ---- example if "string_begins" use
        
    if string_begins(item, "techage:ta4")
    
    then
		return ta4_chest
    end

    
    return default
    
end
