CURRENT_VERSION = "1.0"
TOOL_NAME = "EX2"
DEBUG_MODE = true

-- delimeters
DELIM = {}
DELIM.VEC = ":"
DELIM.STRINGS = "~"
DELIM.ENUM_PAIR = "&"
DELIM.OPTION_SET = "|"
DELIM.OPTION = ";"

-- registry related delimeters and strings
REG = {}
REG.DELIM = "."
REG.TOOL_KEY = "ex2"
REG.TOOL_NAME = "savegame.mod.tool." .. REG.TOOL_KEY .. ".quarkhopper"
REG.TOOL_OPTION = "option"
REG.PREFIX_TOOL_OPTIONS = REG.TOOL_NAME .. REG.DELIM .. REG.TOOL_OPTION
REG.TOOL_KEYBIND = "keybind"
REG.PREFIX_TOOL_KEYBIND = REG.TOOL_NAME .. REG.DELIM .. REG.TOOL_KEYBIND

-- Keybinds
function setup_keybind(name, reg, default_key)
    local keybind = {["name"] = name, ["reg"] = reg}
    keybind.key = GetString(REG.PREFIX_TOOL_KEYBIND..REG.DELIM..keybind.reg)
    if keybind.key == "" then 
        keybind.key = default_key
        SetString(REG.PREFIX_TOOL_KEYBIND..REG.DELIM..keybind.reg, keybind.key)
    end
    return keybind
end

KEY = {}
KEY.PLANT_BOMB = setup_keybind("Plant bomb", "plant_bomb", "LMB")
KEY.PLANT_GROUP = setup_keybind("Plant 50 bombs", "plant_group", "uparrow")
KEY.DETONATE = setup_keybind("Detonate bombs", "detonate", "downarrow")
KEY.STOP_FIRE = setup_keybind("Stop fire", "stop_fire", "MMB")
KEY.OPTIONS = setup_keybind("Options", "options", "O")

-- set on init
TOOL_OPTIONS = {}
CONSTS = {}

-- Aesthetics
CONSTS.ASH_COLOR = Vec(0, 0, 0.7)
CONSTS.FLAME_COLOR_HOT = Vec(7.6, 0.6, 0.9)
CONSTS.FLAME_COLOR_DEFAULT = Vec(7.7, 1, 0.8)
CONSTS.FLAME_LIFE_MIN = 0.3
CONSTS.FLAME_LIFE_MAX = 0.5
CONSTS.FLAME_ALPHA_START = 1
CONSTS.FLAME_ALPHA_END = 1
CONSTS.FLAME_ALPHA_GRAPH = "linear"
CONSTS.FLAME_ALPHA_FADEIN = 0
CONSTS.FLAME_ALPHA_FADEOUT = 1
CONSTS.SMOKE_LIFE = 1
CONSTS.SMOKE_AMOUNT = 0 -- 0.1

-- Behavior
CONSTS.EXPLOSION_F = 10 -- fuel compressed into the bomb
CONSTS.EXPLOSION_MAX_F = 10 ^ 10
CONSTS.EXPLOSION_MAX_T = 10 ^ 10
CONSTS.EXPLOSION_MAX_P = 10 ^ 10
CONSTS.AMBIENT_F = 0 -- that would be scary
CONSTS.AMBIENT_T = 10 ^ 1
CONSTS.AMBIENT_P = 10 ^ 1
CONSTS.COMBUSTION_T = 200 -- cull the point
CONSTS.COMBUSTION_F = 1 -- cull the point
-- these values are linear
CONSTS.BURN_RATE = 10 ^ -3 -- constant added to the fuel burn calculation
CONSTS.STORED_ENERGY = 1 -- units of heat per unit of fuel
CONSTS.IDEAL_RATIO_F_P = 1
CONSTS.IDEAL_RATIO_F_T = 1
CONSTS.HEAT_FACTOR = 10 -- directional vector component due to heat rise
CONSTS.EXTEND_SAMPLES = 10

-- Interaction
CONSTS.SPARK_MIN_HURT_AMOUNT = 0.01
CONSTS.SPARK_HURT_ADJUSTMENT = 0.005
CONSTS.SPARK_HOLE_SOFT_RADIUS = 1
CONSTS.SPARK_HOLE_MED_RADIUS = 0.5
CONSTS.SPARK_HOLE_HARD_RADIUS = 0.1

-- UI 
UI = {}
UI.OPTION_TEXT_SIZE = 18
UI.OPTION_CONTROL_WIDTH = 250
UI.OPTION_COLOR_SLIDER_WIDTH = UI.OPTION_CONTROL_WIDTH
UI.OPTION_STANDARD_SLIDER_WIDTH = UI.OPTION_CONTROL_WIDTH
UI.OPTION_BUMP_BUTTON_WIDTH = 4