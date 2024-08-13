#include "script/Utils.lua"
#include "script/Defs.lua"
#include "script/Types.lua"
#include "script/GameOptions.lua"
#include "script/Init.lua"
#include "script/Explosion.lua"
#include "script/Mapping.lua"

------------------------------------------------
-- INIT
-------------------------------------------------
function init()
	RegisterTool(REG.TOOL_KEY, TOOL_NAME, nil, 5)
	SetBool("game.tool."..REG.TOOL_KEY..".enabled", true)
	SetFloat("game.tool."..REG.TOOL_KEY..".ammo", 1000)

	bombs = {}
	explosions = {}
	plantRate = 0.3
	plantTimer = 0
	shootTimer = 0
	shootLock = false
	
	load_option_sets(false)
	init_pyro(TOOL_OPTIONS)
	
	editingOptions = nil
	
	set_spawn_area_parameters()
	spawn_sound = LoadSound("MOD/snd/AddGroup.ogg")

	suspend_ticks = false	
end

-------------------------------------------------
-- Drawing
-------------------------------------------------

function draw()
	if GetString("game.player.tool") ~= REG.TOOL_KEY or
		GetPlayerVehicle() ~= 0 then return end
	
	if editingOptions ~= nil then
		drawOptionModal(editingOptions)
	end

	UiTranslate(0, UiHeight() - UI.OPTION_TEXT_SIZE * 6)
	UiAlign("left")
	UiFont("bold.ttf", UI.OPTION_TEXT_SIZE)
	UiTextOutline(0,0,0,1,0.5)
	UiColor(1,1,1)
	UiText(KEY.PLANT_BOMB.key.." to plant bomb", true)
	UiText(KEY.PLANT_GROUP.key.." to plant 10 randomly around (now: "..#bombs..")", true)
	UiText(KEY.DETONATE.key.." to detonate", true)
	UiText(KEY.OPTIONS.key.." for options", true)
	UiText(KEY.STOP_FIRE.key.." to stop all explosions")
end

function drawOptionModal(options)
	UiMakeInteractive()
	UiPush()
		local margins = {}
		margins.x0, margins.y0, margins.x1, margins.y1 = UiSafeMargins()

		local box = {
			width = (margins.x1 - margins.x0) - 300,
			height = (margins.y1 - margins.y0) - 300
		}

		UiModalBegin()
			UiAlign("left top")
			UiPush()
				-- borders and background
				UiTranslate(UiCenter(), UiMiddle())
				UiAlign("center middle")
				UiColor(1, 1, 1)
				UiRect(box.width + 5, box.height + 5)
				UiColor(0.2, 0.2, 0.2)
				UiRect(box.width, box.height)
			UiPop()
			UiPush()
				-- options
				UiTranslate(200, 180)
				UiFont("bold.ttf", UI.OPTION_TEXT_SIZE)
				UiTextOutline(0,0,0,1,0.5)
				UiColor(1,1,1)
				UiAlign("left top")
				UiPush()
					for i = 1, #options.options do
						local option = options.options[i]
						drawOption(option)
						if math.fmod(i, 7) == 0 then 
							UiPop()
							UiTranslate(UI.OPTION_CONTROL_WIDTH * 2, 0)
							UiPush()
						else
							UiTranslate(0, 100)
						end
					end
				UiPop()
			UiPop()
			UiPush()
				-- instructions
				UiAlign("center middle")
				UiTranslate(UiCenter(), UiHeight() - 180)
				UiFont("bold.ttf", UI.OPTION_TEXT_SIZE)
				UiTextOutline(0,0,0,1,0.5)
				UiColor(1,1,1)
				UiText("Press [Return/Enter] to save, [Backspace] to cancel, [Delete] to reset to defaults")
			UiPop()
			if InputPressed("return") then 
				save_option_set(options)
				load_option_set(options.name)
				editingOptions = nil 
			end
			if InputPressed("backspace") then
				load_option_set(options.name)
				editingOptions = nil
			end
            if InputPressed("delete") then
				option_set_reset(options.name)
				editingName = editingOptions.name
				load_option_sets()
				if editingName == "general" then
					editingOptions = TOOL_OPTIONS
				end
            end
		UiModalEnd()
	UiPop()
end

function drawOption(option)
	UiPush()
		UiPush()
			-- label and value
			UiAlign("left middle")
			UiFont("bold.ttf", UI.OPTION_TEXT_SIZE)
			local line = option.friendly_name.." = "
			if option.type == option_type.color then
				UiText(line)
				local sampleColor = HSVToRGB(option.value) 
				UiColor(sampleColor[1], sampleColor[2], sampleColor[3])
				UiTranslate(UiGetTextSize(line), 0)
				UiRect(50,20)
			elseif option.type == option_type.enum then
				UiText(line..get_enum_key(option.value, option.accepted_values))
			else
				UiText(line..round_to_place(option.value, 1))
			end
		UiPop()
		UiPush()
			-- control
			UiAlign("left")
			UiTranslate(0,30)
			local value = makeOptionControl(option, UI.OPTION_CONTROL_WIDTH)
			set_option_value(option, value)
		UiPop()
	UiPop()
end

function makeOptionControl(option, width)
	local k = get_keys_and_values(option.accepted_values)
	local enumValueCount = #k
	UiPush()
		-- convert the value to a slider fraction [0,1]
		local value = option.value
		if option.type == option_type.enum then
			value = range_value_to_fraction(value, 1, enumValueCount)
		elseif option.type == option_type.numeric then 
			value = range_value_to_fraction(value, option.range.lower, option.range.upper)
		end

		-- generate controls
		local colorHue, colorSaturation, colorValue
		local bumpAmount = 0
		if option.type == option_type.color then
			colorHue = drawSlider(value[1]/359, UI.OPTION_COLOR_SLIDER_WIDTH, "H", 30)
			UiTranslate(0, 20)
			colorSaturation = drawSlider(value[2], UI.OPTION_COLOR_SLIDER_WIDTH, "S", 30)
			UiTranslate(0, 20)
			colorValue = drawSlider(value[3], UI.OPTION_COLOR_SLIDER_WIDTH, "V", 30)
		else
			UiTranslate(15,0)
			value = drawSlider(value, UI.OPTION_STANDARD_SLIDER_WIDTH)
			UiTranslate(-15,-15)
			if UiImageButton("MOD/img/up.png") then
				bumpAmount = option.step				
			end
			UiTranslate(0, 15)
			if UiImageButton("MOD/img/down.png") then
				bumpAmount = 0 - option.step
			end
		end

		-- convert back to an appropriate value
		if option.type == option_type.numeric then 
			local range = option.range.upper - option.range.lower
			value = (value * range) + option.range.lower
			if option.integer then
				value = round(value)
			end
			value = bracket_value(value + bumpAmount, option.range.upper, option.range.lower)
		elseif option.type == option_type.enum then 
			local range = enumValueCount - 1
			value = round((value * range) + 1)
			value = bracket_value(value + bumpAmount, enumValueCount, 1)
		elseif option.type == option_type.color then
			value = Vec(colorHue*359, colorSaturation, colorValue)
		end
	UiPop()
	return value
end

function drawSlider(value, width, label, labelWidth)
	local returnValue = nil
	UiPush()
		UiAlign("left middle")
		local controlWidth = width
		if label ~= nil then
			if labelWidth == nil then 
				local labelWidth, _ = UiGetTextSize(label)
			end
			local controlWidth = width - 5 - labelWidth
			UiText(label)
			UiTranslate(labelWidth + 5, 0)
		else
			controlWidth = width
		end
		UiTranslate(8,0)
		UiRect(controlWidth, 2)
		UiTranslate(-8,0)
		local returnValue = UiSlider("ui/common/dot.png", "x", value * controlWidth, 0, controlWidth) / controlWidth
	UiPop()
	return returnValue
end

-------------------------------------------------
-- UPDATE 
-------------------------------------------------

function update(dt)
	if not suspend_ticks then 
		-- shut down updates if there's an error in init so we don't flood 
		-- away the error message
		if TOOL_OPTIONS.pyro == nil then suspend_ticks = true end
		flame_update(TOOL_OPTIONS.pyro, dt)
		explosion_tick(dt)
	end
end

function tick(dt)
	handleInput(dt)
	flame_tick(TOOL_OPTIONS.pyro, dt)
end

-------------------------------------------------
-- Input handler
-------------------------------------------------

function handleInput(dt)
	if editingOptions ~= nil then return end

	plantTimer = math.max(plantTimer - dt, 0)

	if GetString("game.player.tool") == REG.TOOL_KEY and
	GetPlayerVehicle() == 0 then 
		-- options menus
		if InputPressed(KEY.OPTIONS.key) then 
			editingOptions = TOOL_OPTIONS
		else
			-- plant bomb
			if not shootLock and
			plantTimer == 0 and
			InputDown(KEY.PLANT_BOMB.key) then
				-- sticky version
				local camera = GetPlayerCameraTransform()
				local shoot_dir = TransformToParentVec(camera, Vec(0, 0, -1))
				local hit, dist, normal, shape = QueryRaycast(camera.pos, shoot_dir, 100, 0, true)
				if hit then 
					local drop_pos = VecAdd(camera.pos, VecScale(shoot_dir, dist))
					local bomb = Spawn("MOD/prefab/Decoder.xml", Transform(drop_pos), false, true)[2]
					table.insert(bombs, bomb)
					plantTimer = plantRate
				end
				-- local camera = GetPlayerCameraTransform()
				-- local dropPos = TransformToParentPoint(camera, Vec(0.2, -0.2, -1.25))
				-- local bomb = Spawn("MOD/prefab/Decoder.xml", Transform(dropPos), false, true)[2]
				-- table.insert(bombs, bomb)
				-- plantTimer = plantRate
			end
			
			-- detonate
			if not shootLock and
			GetPlayerGrabShape() == 0 and
			InputDown(KEY.DETONATE.key) then
				detonateAll()
			end
		
			if InputPressed(KEY.STOP_FIRE.key) then
				-- stop all explosions and cancel bomb
				for i=1, #explosions do
					local explosion = explosions[i]
					explosion.sparks = {} 
				end	
			end

			-- plant a group around the map
			if InputPressed(KEY.PLANT_GROUP.key) then 
				local player_trans = GetPlayerTransform()
				PlaySound(spawn_sound, player_trans.pos, 50)
				for i = 1, 10 do
					local spawnPos = find_spawn_location()
					if spawnPos ~= nil then 
						local trans = Transform(spawnPos) --, QuatEuler(math.random(0,359),math.random(0,359),math.random(0,359)))
						local bomb = Spawn("MOD/prefab/Decoder.xml", trans, false, true)[2]
						table.insert(bombs, bomb)
					end					
				end
			end
		end
	end
end

-------------------------------------------------
-- Support functions
-------------------------------------------------

function load_option_sets(reset)
	
	if reset == true then 
		option_set_reset("general")
	end
	
	TOOL_OPTIONS = load_option_set("general", true)
	init_pyro(TOOL_OPTIONS)
end


