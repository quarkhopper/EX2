#include "Types.lua"

function create_option_set()
	local inst = {}
	inst.name = "Unnamed"
	inst.display_name = "Unnamed option set"
	inst.version = CURRENT_VERSION
	inst.options = {}

	return inst
end

function option_set_to_string(inst)
	local ser_parts = {inst.name, inst.display_name, inst.version}
	for i = 1, #inst.options do
		ser_parts[#ser_parts + 1] = option_to_string(inst.options[i])
	end
	return join_strings(ser_parts, DELIM.OPTION_SET)
end

function save_option_set(inst)
	if inst.name == "" or inst.name == nil then return end
	SetString(REG.PREFIX_TOOL_OPTIONS.."."..inst.name, option_set_to_string(inst))
end

function load_option_set(name, create_if_not_found)
	local ser = GetString(REG.PREFIX_TOOL_OPTIONS.."."..name)
	if ser == "" then
		if create_if_not_found then
			local oset = create_option_set_by_name(name)
			return oset
		else 
			return nil
		end
	end
	local options = option_set_from_string(ser)
	options.name = name
	return options
end

function set_option_value(inst, value) 
	if inst.type == option_type.numeric then
		inst.value = bracket_value(value, inst.range.upper, inst.range.lower) or 0
	else
		inst.value = value
	end
end

function option_set_from_string(ser)
	local options = create_option_set()
	options.options = {}
	local option_sers = split_string(ser, DELIM.OPTION_SET)
	options.name = option_sers[1]
	options.display_name = option_sers[2]
	options.version = option_sers[3]
	local parse_start_index = 4
	for i = parse_start_index, #option_sers do
		local option_ser = option_sers[i]
		local option = option_from_string(option_ser)
		options[option.key] = option
		table.insert(options.options, option)
	end
	return options
end

function reset_all_options()
	-- This is an emergency reset that the main menu option screen uses.
	-- it does not rely on the TOOL globals being loaded.
	local option_set_keys = {"general"}
	for i = 1, #option_set_keys do
		option_set_reset(option_set_keys[i])
	end
end

function option_set_reset(name)
	ClearKey(REG.PREFIX_TOOL_OPTIONS.."."..name)
end

function create_option(o_type, value, key, friendly_name)
	local inst = {}
	inst.type = o_type or option_type.numeric
	inst.value = value
	inst.range = {}
	inst.range.upper = 1
	inst.range.lower = 0
	inst.step = 1
	inst.accepted_values = {}
	inst.key = key or "unnamed_option"
	inst.friendly_name = friendly_name or "Unnamed option"

	return inst
end

function option_to_string(inst)
	local parts = {}
	parts[1] = tostring(inst.type)
	if inst.type == option_type.color then
		parts[2] = vec_to_string(inst.value)
	else
		parts[2] = inst.value
	end
	parts[3] = tostring(inst.range.lower)
	parts[4] = tostring(inst.range.upper)
	parts[5] = tostring(inst.step)
	parts[6] = enum_to_string(inst.accepted_values)
	parts[7] = inst.key
	parts[8] = inst.friendly_name

	return join_strings(parts, DELIM.OPTION)
end

function option_set_value(inst, value)
	if inst.type == option_type.numeric then
		inst.value = bracket_value(value, inst.range.upper, inst.range.lower) or 0
	else
		inst.value = value
	end
end

function option_from_string(ser)
	local option = create_option()
	local parts = split_string(ser, DELIM.OPTION)
	option.type = tonumber(parts[1])
	if option.type == option_type.bool then
		option.value = string_to_boolean[parts[2]]
	elseif option.type == option_type.color then
		option.value = string_to_vec(parts[2])
	else
		option.value = tonumber(parts[2])
	end
	
	if parts[3] ~= nil then
		option.range.lower = tonumber(parts[3])
	end
	if parts[4] ~= nil then
		option.range.upper = tonumber(parts[4])
	end
	if parts[5] ~= nil then
		option.step = tonumber(parts[5])
	end
	if parts[6] ~= nil then 
		option.accepted_values = string_to_enum(parts[6])
	end
	option.key = parts[7]
	option.friendly_name = parts[8]

	return option
end

function create_general_option_set()
    local oSet = create_option_set()
    oSet.name = "general"
    oSet.version = CURRENT_VERSION

	oSet.max_flames = create_option(
		option_type.numeric, 
		1000,
		"max_flames",
		"Max visible flames")
	oSet.max_flames.range.lower = 10
	oSet.max_flames.range.upper = 5000
	oSet.max_flames.integer = true
	oSet.max_flames.step = 1
	oSet.options[#oSet.options + 1] = oSet.max_flames

	oSet.max_sim_points = create_option(
		option_type.numeric, 
		1000,
		"max_sim_points",
		"Max sim points")
	oSet.max_sim_points.range.lower = 10
	oSet.max_sim_points.range.upper = 10000
	oSet.max_sim_points.integer = true
	oSet.max_sim_points.step = 1
	oSet.options[#oSet.options + 1] = oSet.max_sim_points		
	
	oSet.explosion_seeds = create_option(
		option_type.numeric, 
		500,
		"explosion_seeds",
		"Explosion seeds")
	oSet.explosion_seeds.range.lower = 1
	oSet.explosion_seeds.range.upper = 1000
	oSet.explosion_seeds.integer = true
	oSet.explosion_seeds.step = 1
	oSet.options[#oSet.options + 1] = oSet.explosion_seeds	

	oSet.explosion_radius = create_option(
		option_type.numeric, 
		5,
		"explosion_radius",
		"Explosion radius")
	oSet.explosion_radius.range.lower = 1
	oSet.explosion_radius.range.upper = 20
	oSet.explosion_radius.integer = true
	oSet.explosion_radius.step = 0.1
	oSet.options[#oSet.options + 1] = oSet.explosion_radius	

	-- oSet.ash_max_life = create_option(
	-- 	option_type.numeric, 
	-- 	4,
	-- 	"ash_max_life",
	-- 	"Max lifetime of ash particles (secs)")
	-- oSet.ash_max_life.range.lower = 0
	-- oSet.ash_max_life.range.upper = 10
	-- oSet.ash_max_life.step = 0.5
	-- oSet.options[#oSet.options + 1] = oSet.ash_max_life		

	-- oSet.ash_max_speed = create_option(
	-- 	option_type.numeric, 
	-- 	3,
	-- 	"ash_max_speed",
	-- 	"Max speed of ash particles (m/s)")
	-- oSet.ash_max_speed.range.lower = 0
	-- oSet.ash_max_speed.range.upper = 10
	-- oSet.ash_max_speed.step = 0.5
	-- oSet.options[#oSet.options + 1] = oSet.ash_max_speed	

	-- oSet.ash_tile_radius = create_option(
	-- 	option_type.numeric, 
	-- 	0.3,
	-- 	"ash_tile_radius",
	-- 	"Ash particle radius (m)")
	-- oSet.ash_tile_radius.range.lower = 0.1
	-- oSet.ash_tile_radius.range.upper = 5
	-- oSet.ash_tile_radius.step = 0.5
	-- oSet.options[#oSet.options + 1] = oSet.ash_tile_radius	
	
	-- oSet.ash_gravity = create_option(
	-- 	option_type.numeric, 
	-- 	0,
	-- 	"ash_gravity",
	-- 	"Ash particle gravity (m/s/s)")
	-- oSet.ash_gravity.range.lower = -10
	-- oSet.ash_gravity.range.upper = 10
	-- oSet.ash_gravity.step = 0.1
	-- oSet.options[#oSet.options + 1] = oSet.ash_gravity	

	-- oSet.ash_drag = create_option(
	-- 	option_type.numeric, 
	-- 	0,
	-- 	"ash_drag",
	-- 	"Ash particle drag")
	-- oSet.ash_drag.range.lower = 0
	-- oSet.ash_drag.range.upper = 1
	-- oSet.ash_drag.step = 0.01
	-- oSet.options[#oSet.options + 1] = oSet.ash_drag	

	oSet.fire_ignition_radius = create_option(
		option_type.numeric, 
		8,
		"fire_ignition_radius",
		"Fire ignition radius (m)")
	oSet.fire_ignition_radius.range.lower = 0
	oSet.fire_ignition_radius.range.upper = 20
	oSet.fire_ignition_radius.step = 0.1
	oSet.options[#oSet.options + 1] = oSet.fire_ignition_radius	

	oSet.flame_color_hot = create_option(
		option_type.color,
		CONSTS.FLAME_COLOR_HOT,
		"flame_color_hot",
		"Hot flame color")
	oSet.options[#oSet.options + 1] = oSet.flame_color_hot

	oSet.flame_color_cool = create_option(
		option_type.color,
		CONSTS.FLAME_COLOR_DEFAULT,
		"flame_color_cool",
		"Cool flame color")
	oSet.options[#oSet.options + 1] = oSet.flame_color_cool

	oSet.flame_amount = create_option(
		option_type.numeric, 
		0.3,
		"flame_amount",
		"Simulated flame amount")
	oSet.flame_amount.range.lower = 0
	oSet.flame_amount.range.upper = 1
	oSet.flame_amount.step = 0.001
	oSet.options[#oSet.options + 1] = oSet.flame_amount

	oSet.flame_life = create_option(
		option_type.numeric, 
		2,
		"flame_life",
		"Flame life")
	oSet.flame_life.range.lower = 0
	oSet.flame_life.range.upper = 10
	oSet.flame_life.step = 0.1
	oSet.options[#oSet.options + 1] = oSet.flame_life
    return oSet
end

function create_option_set_by_name(name)
	if name == "general" then
		return create_general_option_set()		
	end
end

option_type = enum {
	"numeric",
	"enum",
	"bool",
	"color"
}

on_off = enum {
	"off",
	"on"
}
