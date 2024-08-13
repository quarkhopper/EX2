#include "Utils.lua"
#include "Defs.lua"
#include "Types.lua"
#include "HSVRGB.lua"

function init_pyro(tool)
    local pyro = inst_pyro()
    pyro.color_cool = tool.flame_color_cool.value
    pyro.color_hot = tool.flame_color_hot.value
    pyro.jitter_cool = 0.2
    pyro.jitter_hot = 0.2
    pyro.flame_puff_life = fraction_to_range_value(tool.flame_life.value, CONSTS.FLAME_LIFE_MIN, CONSTS.FLAME_LIFE_MAX)
    pyro.flame_amount_n = tool.flame_amount.value
    pyro.flame_alpha_start = CONSTS.FLAME_ALPHA_START
    pyro.flame_alpha_end = CONSTS.FLAME_ALPHA_END
    pyro.flame_alpha_graph = CONSTS.FLAME_ALPHA_GRAPH
    pyro.flame_alpha_fadein = CONSTS.FLAME_ALPHA_FADEIN
    pyro.flame_alpha_fadeout = CONSTS.FLAME_ALPHA_FADEOUT
    pyro.fade_magnitude = 1
    pyro.hot_particle_size = 0.3
    pyro.cool_particle_size = 0.4
    pyro.smoke_life = CONSTS.SMOKE_LIFE
    pyro.smoke_amount_n = CONSTS.SMOKE_AMOUNT
    pyro.max_player_hurt = 0.1
    pyro.flames_per_spawn = 10
    pyro.flame_light_intensity = 1
    pyro.fire_ignition_radius = tool.fire_ignition_radius.value
    pyro.fire_density = 10
    pyro.max_flames = tool.max_flames.value
    pyro.debug = DEBUG_MODE
    pyro.ff.resolution = 0.5
    pyro.ff.max_sim_points = tool.max_sim_points.value
    pyro.ff.max_f = CONSTS.EXPLOSION_MAX_F
    pyro.ff.max_t = CONSTS.EXPLOSION_MAX_T
    pyro.ff.max_p = CONSTS.EXPLOSION_MAX_P
    pyro.ff.ambient_f = CONSTS.AMBIENT_F
    pyro.ff.ambient_t = CONSTS.AMBIENT_T
    pyro.ff.ambient_p = CONSTS.AMBIENT_P
    pyro.ff.explosion_f = CONSTS.EXPLOSION_F
    pyro.ff.combustion_t = CONSTS.COMBUSTION_T
    pyro.ff.combustion_f = CONSTS.COMBUSTION_F
    pyro.ff.burn_rate = CONSTS.BURN_RATE
    pyro.ff.stored_energy = CONSTS.STORED_ENERGY
    pyro.ff.ideal_ratio_f_p = CONSTS.IDEAL_RATIO_F_P
    pyro.ff.ideal_ratio_f_t = CONSTS.IDEAL_RATIO_F_T
    pyro.ff.extend_scale = 1.25
    pyro.ff.extend_samples = CONSTS.EXTEND_SAMPLES
	pyro.ff.heat_factor = CONSTS.HEAT_FACTOR
    pyro.ff.debug = DEBUG_MODE
    tool.pyro = pyro
end
