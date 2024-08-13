#include "ForceField.lua"
#include "Utils.lua"
--[[
    This script is a wrapper for ForceField.lua. Where ForceField.lua covers the 
    "physics" of the forces moving around, this covers the fire and SFX and wraps
    that field. 
]]--


PYRO = {} -- Static PyroField options
PYRO.MIN_PLAYER_PUSH = 1
PYRO.MAX_PLAYER_PUSH = 5
PYRO.MAX_PLAYER_VEL = 10
PYRO.MIN_IMPULSE = 50
PYRO.MAX_IMPULSE = 800
PYRO.GRAVITY = 0.5

function inst_pyro()
    local inst = {}
    inst.flames = {}
    inst.flames_per_spawn = 5
    inst.flame_light_intensity = 4 
    inst.cool_particle_size = 1
    inst.hot_particle_size = 0.5
    inst.smoke_life = 1
    inst.smoke_amount_n = 0.2
    inst.flame_amount_n = 1
    inst.render_flames = true
    inst.flame_puff_life = 0.5
    inst.flame_jitter = 0
    inst.flame_alpha_start = 1
    inst.flame_alpha_end = 0
    inst.flame_alpha_graph = "linear"
    inst.flame_alpha_fadein = 0
    inst.flame_alpha_fadeout = 1
    inst.fire_ignition_radius = 1
    inst.fire_density = 1
    inst.physical_damage_factor = 0.5
    inst.max_player_hurt = 0.5
    inst.color_cool = Vec(7.7, 1, 0.8)
    inst.color_hot = Vec(7.7, 1, 0.8)
    inst.jitter_hot = 0
    inst.jitter_cool = 0.5
    inst.fade_magnitude = 20
    inst.max_flames = 400
    inst.combustion_temp = 200
    inst.ff = inst_force_field_ff()
    inst.debug = false
    return inst
end

function inst_flame(pos)
    -- A flame object is rendered as a point light in a diffusing smoke particle.
    local inst = {}
    inst.pos = pos
    -- Parent FORCE FIELD POINT that this flame was spawned for.
    inst.parent = nil
    return inst
end

function make_flame_effect(pyro, flame, dt)
    local intensity = pyro.flame_light_intensity
    local opacity = pyro.flame_opacity
    local puff_color_value = 1
    local color = HSVToRGB(blend_color(flame.parent.t_n, pyro.color_cool, pyro.color_hot))
    PointLight(flame.pos, color[1], color[2], color[3], intensity)
    ParticleReset()
    ParticleType("smoke")
    ParticleAlpha(opacity, 
        pyro.flame_alpha_end, 
        pyro.flame_alpha_graph, 
        pyro.flame_alpha_fadein, 
        pyro.flame_alpha_fadeout)
    -- ParticleDrag(0.25)
    local particle_size = fraction_to_range_value(flame.parent.t_n, pyro.cool_particle_size, pyro.hot_particle_size)
    ParticleRadius(particle_size)
    local smoke_color = HSVToRGB(Vec(0, 0, puff_color_value))
    ParticleColor(smoke_color[1], smoke_color[2], smoke_color[3])
    ParticleGravity(PYRO.GRAVITY)
    local tile = 0
    if math.random(2) == 1 then tile = 5 end
    ParticleTile(tile)
    -- Apply a little random jitter if specified by the options, for the specified lifetime
    -- in options.
    SpawnParticle(VecAdd(flame.pos, random_vec(pyro.flame_jitter)), Vec(), pyro.flame_puff_life)
    if math.random() < pyro.smoke_amount_n then
        make_smoke(pyro, flame.pos, {partical_size = partical_size})
    end

end

function make_smoke (pyro, pos, options)
    local partical_size = options.partical_size or 0.3
    -- Set up a smoke puff
    ParticleReset()
    ParticleType("smoke")
    -- ParticleDrag(0)
    ParticleAlpha(0.9, 0.5, "linear", 0.1, 0.5)
    ParticleRadius(particle_size)
    smoke_color = HSVToRGB(Vec(0, 0, 0.1))
    ParticleColor(smoke_color[1], smoke_color[2], smoke_color[3])
    ParticleGravity(PYRO.GRAVITY)
    -- apply a little random jitter to the smoke puff based on the flame position,
    -- for the specified lifetime of the particle.
    SpawnParticle(VecAdd(pos, random_vec(0.1)), Vec(), pyro.smoke_life)
end

function burn_fx(pyro)
    -- Start fires throught the native Teardown mechanism. Base these effects on the
    -- lower resolution metafield for better performance (typically)
    -- local points = flatten(pyro.ff.field)
    local num_fires = round((pyro.fire_density / pyro.fire_ignition_radius)^3)
    for i = 1, #pyro.flames do
        local point = pyro.flames[i].parent
        if point.t >= pyro.combustion_temp then
            for j = 1, num_fires do
                local random_dir = random_vec(1)
                -- cast in some random dir and start a fire if you hit something. 
                local hit, dist = QueryRaycast(point.pos, random_dir, pyro.fire_ignition_radius)
                if hit then 
                    local burn_at = VecAdd(point.pos, VecScale(random_dir, dist))
                    SpawnFire(burn_at)
                end
            end
        end
    end
end

function make_flame_effects(pyro, dt)
    -- for every flame instance, make the appropriate effect
    for i = 1, #pyro.flames do
        local flame = pyro.flames[i]
        make_flame_effect(pyro, flame, dt)
    end
end

function spawn_flames(pyro)
    -- Spawn flame instances to render based on the underlying base force field vectors.
    local new_flames = {}
    local points = flatten(pyro.ff.field)
    for i = 1, #points do
        local point = points[i]
        spawn_flame_group(pyro, point, new_flames)     
    end
    while #new_flames > pyro.max_flames do
        table.remove(new_flames, math.random(#new_flames))
    end
    pyro.flames = new_flames
end

function spawn_flame_group(pyro, point, flame_table, pos)
    pos = pos or point.pos
    for i = 1, pyro.flames_per_spawn do
        if math.random() < pyro.flame_amount_n then 
            local jitter = fraction_to_range_value(point.t_n, pyro.jitter_cool, pyro.jitter_hot)
            local offset_dir = VecNormalize(random_vec(jitter))
            local flame_pos = VecAdd(pos, VecScale(offset_dir, pyro.ff.resolution))
            local flame = inst_flame(pos)
            flame.parent = point
            table.insert(flame_table, flame)
        end
    end
end

function flame_update(pyro, dt)
    force_field_update(pyro.ff, dt)
    
    if pyro.render_flames then 
        spawn_flames(pyro)
        if not pyro.debug then 
            make_flame_effects(pyro, dt)
            burn_fx(pyro)
        end
    end

end

function is_combusting(temperature, pressure) 

end

function flame_tick(pyro, dt)
    force_field_tick(pyro.ff, dt)
end
