#include "Utils.lua"
#include "Defs.lua"
#include "HSVRGB.lua"

-------------------------------------------------
-- Enums
-------------------------------------------------

function enum(source)
	local enumTable = {}
    for i = 1, #source do
        local value = source[i]
        enumTable[value] = i
    end

    return enumTable
end

function enum_to_string(source)
	if source == nil then return "" end
	local keyTable = {}
	local valueTable = {}
	for k, v in pairs(source) do
		keyTable[#keyTable + 1] = k
		valueTable[#valueTable + 1] = v
	end

	return join_strings(keyTable, DELIM.STRINGS).. 
		DELIM.ENUM_PAIR.. 
		join_strings(valueTable, DELIM.STRINGS)
end

function string_to_enum(source)
	if source == nil or source == "" then return {} end
	local parts = split_string(source, DELIM.ENUM_PAIR)
	local keys = split_string(parts[1], DELIM.STRINGS)
	local values = split_string(parts[2], DELIM.STRINGS)
	
	local enumTable = {}
	for i = 1, #keys do
  		enumTable[keys[i]] = tonumber(values[i])
	end
	
	return enumTable
end

function get_enum_key(value, enumTable)
	for k, v in pairs(enumTable) do
		if v == value then
			return k
		end
	end
end


