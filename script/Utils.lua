#include "Defs.lua"

function random_in_range(low, high)
	return (math.random() * (high - low)) + low
end

function split_string(inputString, separator)
	if inputString == nil or inputString == "" then return {} end
	if separator == nil then
			separator = "%s"
	end
	local t={}
	for str in string.gmatch(inputString, "([^"..separator.."]+)") do
			table.insert(t, str)
	end
	return t
end

function join_strings(inputTable, delimeter)
	if inputTable == nil or #inputTable == 0 then return "" end
	if #inputTable == 1 then return tostring(inputTable[1]) end
	
	local concatString = tostring(inputTable[1])
	for i=2, #inputTable do
		concatString = concatString..delimeter..tostring(inputTable[i])
	end
	
	return concatString
end

function vec_to_string(vec)
	return vec[1]..DELIM.VEC
	..vec[2]..DELIM.VEC
	..vec[3]
end

function string_to_vec(vecString)
	local parts = split_string(vecString, DELIM.VEC)
	return Vec(parts[1], parts[2], parts[3])
end

-- function random_vec(scale)
-- 	scale = scale or 1
-- 	return VecScale(VecNormalize(Vec(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5)), scale)
-- end

function random_vec(magnitude)
	return Vec(random_vec_component(magnitude), random_vec_component(magnitude), random_vec_component(magnitude))
end

function burst_pattern_dirs(num_dirs, angle_step, variation, home_dir)
    home_dir = home_dir or random_vec(1)
    local dirs = {}
    for i = 1, num_dirs do
        local x_rot = (i * vary_by_fraction(angle_step, variation)) % 360
        local y_rot = (i * vary_by_fraction(angle_step, variation)) % 360
        local z_rot = (i * vary_by_fraction(angle_step, variation)) % 360
        local a = QuatEuler(x_rot, y_rot, z_rot)
        local v = VecNormalize(QuatRotateVec(a, home_dir))
        table.insert(dirs, v)
    end
    return dirs
end

function vary_by_fraction(value, fraction)
    local variation = value * fraction
    return value + random_float(-variation, variation)
end

function random_vec_component(magnitude)
	return (math.random() * magnitude * 2) - magnitude
end 

function vary_by_percentage(value, variation)
	return value + (value * random_vec_component(variation))
end

function round_vec(vec)
    return Vec(
        round(vec[1]),
        round(vec[2]),
        round(vec[3])
    )
end

function vecs_equal(vec_a, vec_b)
    return vec_a[1] == vec_b[1] and
        vec_a[2] == vec_b[2] and
        vec_a[3] == vec_b[3]
end

function blend_color(fraction, color_a, color_b)
    local a = fraction_to_range_value(fraction, color_a[1], color_b[1])
    local b = fraction_to_range_value(fraction, color_a[2], color_b[2])
    local c = fraction_to_range_value(fraction, color_a[3], color_b[3])
    local color = Vec(a, b, c)
    return color
end

function random_float(low, high)
    return (math.random() * (high - low)) + low
end

function fraction_to_range_value(fraction, min, max)
	local range = max - min
	return (range * fraction) + min
end

function range_value_to_fraction(value, min, max)
	local frac = (value - min) / (max - min)
	return frac
end

function get_keys_and_values(t)
	keys = {}
	values = {}
	for k,v in pairs(t) do
		table.insert(keys, k)
		table.insert(values, v)
	end
	return keys, values
end

function bracket_value(value, max, min)
	return math.max(math.min(max, value), min)
end

function round_to_place(value, place)
	multiplier = math.pow(10, place)
	rounded = math.floor(value * multiplier)
	return rounded / multiplier
end

function round(value)
	return math.floor(value + 0.5)
end

function shallow_copy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function debug_option(option) 
	DebugPrint("name: "..option.name..", range upper: "..option.range.upper..", range lower: "..option.range.lower)
end


function is_number(value)
	if tonumber(value) ~= nil then
		return true
	end
    return false
end

function similarity(value_a, value_b, std_dev)
	local a = math.abs(value_a - value_b) / std_dev
	return 1 / (1 + a)
end

function normalize(value, mean, std_dev)
	local a = (math.abs(value) - mean) / std_dev
	local b = 1 - (1 / (1 + a))
	if value < 0 then 
		return b * -1
	end
	return b
end

function mean_values(values)
	return sum_values(values) / #values
end

function sum_values(values) 
	local sum = 0
	for i = 1, #values do
		sum = sum + values[i]
	end
	return sum
end

function std_dev(values, mean)
	local m = mean or mean_values(values)
	local vm
	local sum = 0
	local count = 0
  
	for i = 1, #values do
		v = values[i]
		vm = v - m
		sum = sum + (vm * vm)
		count = count + 1
	end
  
	return math.sqrt(sum / (count-1))
end

stringToBoolean={ ["true"]=true, ["false"]=false }


	