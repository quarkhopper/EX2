#include "Utils.lua"

-- This field works on the principle of PV = nRT. Simplifying R=1 and V=1 since 
-- all simulation is done in equivolume units

FF = {}
FF.DEBUG_COUNT = 3
FF.DEBUG_COUNTER = 0

function inst_force_field_ff()
    -- create a force field instance.
    local inst = {}
    -- The field is a hashed multidim array for fast location searching
    inst.field = {}
    inst.resolution = 0.5
    inst.extend_scale = 1.0
    inst.extend_samples = 5
    inst.max_sim_points = 100
    inst.ambient_f = 0
    inst.ambient_t = 20
    inst.ambient_p = 20
    inst.max_f = 10000
    inst.max_t = 10000
    inst.max_p = 10000
    inst.heat_factor = 0.01
    inst.sd_f = nil
    inst.sd_t = nil
    inst.sd_p = nil
    inst.mean_f = nil
    inst.mean_t = nil
    inst.mean_p = nil
    inst.combustion_f = 10
    inst.burn_rate = 1
    inst.stored_energy = 1
    inst.ideal_ratio_f_p = 1
    inst.ideal_ratio_f_t = 1
    inst.sd_point_min_n = 1
    inst.mean_f_min = 1
    inst.debug = false
    return inst
end

function reset_ff(ff)
    ff.field = {}
end

function inst_field_point(coord, resolution, ff)
    local inst = {}
    inst.resolution = resolution
    inst.coord = coord
    -- local half_res = resolution/2
    inst.pos = VecScale(coord, inst.resolution)
    -- inst.pos = VecAdd(VecScale(coord, inst.resolution), VecScale(Vec(1,1,1), half_res))
    inst.f = 0
    inst.t = ff.ambient_t
    inst.p = 0
    inst.f_n = 0
    inst.t_n = 0
    inst.p_n = 0
    inst.f_buf = {}
    inst.t_buf = {}
    inst.p_buf = {}
    -- transferred in from another field point, yet to be integrated
    inst.trans_f = 0
    inst.trans_t = 0
    inst.cull = false
    inst.dirs = {}
    inst.primes = {}
    inst.hit_count = 0
    inst.hit_loss_n = 0
    inst.propagate_part_n = 0
    return inst
end

function inject(ff, pos, fuel) 
    local coord = pos_to_coord(pos, ff.resolution)
    local point = field_get(ff.field, coord)
    if point == nil then 
        point = inst_field_point(coord, ff.resolution, ff)
        -- insert a point into the field
        field_put(ff.field, point, point.coord)
    end
    point.f = fuel   
    point.t = ff.combustion_t
end

-- used for consuming effects
function update_point_calcs(ff, point)
    -- pressure is initially calculated from heat and fuel
    -- assuming it was in a constrained volume PV = nRT
    point.p = point.f * point.t
    point.f_n = point.f / ff.max_f
    point.t_n = point.t / ff.max_t
    point.p_n = point.p / ff.max_p
end

function synchronize(ff)
    local points = flatten(ff.field)    
    ff.num_points = #points
    local all_f = {}
    local all_t = {}
    local all_p = {}
    for i = 1, #points do
        local point = points[i]
        point.f = math.max(0, math.min(ff.max_f, point.f + (point.trans_f or 0)))
        point.t = math.max(0, math.min(ff.max_t, point.t + (point.trans_t or 0)))
        point.trans_f = 0
        point.trans_t = 0
        -- some culling
        if point.t >= ff.combustion_t and
            point.f >= ff.combustion_f then
            table.insert(all_f, point.f)
            table.insert(all_t, point.t)
            table.insert(all_p, point.p)
        else
            point.cull = true
        end
    end
    ff.mean_f = mean_values(all_f)
    ff.mean_t = mean_values(all_t)
    ff.mean_p = mean_values(all_p)
    ff.sd_f = std_dev(all_f, ff.mean_f)
    ff.sd_t = std_dev(all_t, ff.mean_t)
    ff.sd_p = std_dev(all_p, ff.mean_p)
    -- if ff.mean_f < ff.mean_f_min then reset_ff(ff) end
end

function resolve_dirs(ff, dt)
    local points = flatten(ff.field)    
    ff.num_points = #points
    for i = 1, #points do
        local point = points[i]
        update_point_calcs(ff, point)
        point.dirs = burst_pattern_dirs(ff.extend_samples, 60, 0.2)
        for j = 1, #point.dirs do
            local trans_dir = point.dirs[j]
            -- instead of using F=ma acceleration on the gas we're 
            -- going to just going to come up with a unitless value
            -- from heat (creating force) over fuel (roughtly, mass)
            local heat_mag = (point.t / point.f) * ff.heat_factor
            trans_dir = VecNormalize(VecAdd(trans_dir, Vec(0, heat_mag, 0)))
        end
    end
end

function resolve_primes(ff, dt)
    local points = flatten(ff.field)    
    ff.num_points = #points
    for i = 1, #points do
        local point = points[i]
        point.hit_count = 0
        point.primes = {}
        for j = 1, #point.dirs do
            local trans_dir = point.dirs[j]
            local hit, dist, normal, shape = QueryRaycast(point.pos, trans_dir, 2 * ff.resolution * ff.extend_scale)
            if not hit then 
                local coord_prime = round_vec(VecAdd(point.coord, VecScale(trans_dir, ff.extend_scale)))
                if not vecs_equal(coord_prime, point.coord) then 
                    local point_prime = field_get(ff.field, coord_prime)
                    if point_prime == nil then 
                        point_prime = inst_field_point(coord_prime, ff.resolution, ff)
                        point_prime.f = ff.ambient_f
                        point_prime.p = ff.ambient_p
                        point_prime.t = ff.ambient_t
                    end
                    table.insert(point.primes, point_prime)
                    field_put(ff.field, point_prime, coord_prime)
                end
            else
                point.hit_count = point.hit_count + 1
            end
        end
        point.hit_loss_n = point.hit_count / ff.extend_samples
        point.propagate_part_n = (1 - point.hit_loss_n) / (ff.extend_samples - point.hit_count)
    end
end

function burn_fuel(ff, dt) 
    local points = flatten(ff.field)    
    ff.num_points = #points
    FF.DEBUG_COUNTER = 0 
    for i = 1, #points do
        local point = points[i]
        update_point_calcs(ff, point) 
        -- as you add more fuel you need higher pressure and temp 
            if point.p > 0 and point.t > 0 then 
                local ratio_f_p = point.f / point.p
                local ratio_f_t = point.f / point.t
                local efficiency_t = (1 / (1 + math.abs(ratio_f_t - ff.ideal_ratio_f_t))) ^ 2
                local efficiency_p = (1 / (1 + math.abs(ratio_f_p - ff.ideal_ratio_f_p))) ^ 2
                if ff.debug and FF.DEBUG_COUNTER < FF.DEBUG_COUNT then
                    DebugPrint("---------------------------------------------")
                    DebugPrint("ratio_f_t: "..tostring(ratio_f_t)..", ideal: "..tostring(ff.ideal_ratio_f_t)..", efficientcy_t: "..tostring(efficiency_t)..", fuel: "..tostring(point.f)..", temp: "..tostring(point.t))
                    DebugPrint("ratio_f_p: "..tostring(ratio_f_p)..", ideal: "..tostring(ff.ideal_ratio_f_p)..", efficientcy_p: "..tostring(efficiency_p)..", fuel: "..tostring(point.f)..", pressure: "..tostring(point.p))
                    FF.DEBUG_COUNTER = math.min(FF.DEBUG_COUNT, FF.DEBUG_COUNTER + 1)
                end
                local factor = math.min(1, efficiency_t * efficiency_p * ff.burn_rate)
                local burn_f = point.f * factor
                point.f = math.max(0, point.f - burn_f)
                -- consumate thermal rise
                local burn_t = burn_f * ff.stored_energy
                point.t = math.max(0, point.t + point.t * factor)
        end
    end

end

function propagate_values(ff, dt)
    local points = flatten(ff.field)    
    ff.num_points = #points
    for i = 1, #points do
        local point = points[i]
        update_point_calcs(ff, point)
        -- taking a fraction of the fuel aimed at a predetermined target (prime)
        point.trans_f = point.trans_f or 0
        for j = 1, #point.primes do
            local point_prime = point.primes[j]
            -- pressure differential factor
            local p_d_n = (point.p - point_prime.p) / point.p
            local trans_n = math.max(0, point.propagate_part_n * p_d_n)
            -- if trans_n > 1 then DebugPrint(trans_n) end
            local trans_f = point.f * trans_n
            point_prime.trans_f = point_prime.trans_f + trans_f
            point.trans_f = point.trans_f - trans_f
        end
        -- heat loss to surroundings
        point.trans_t = point.trans_t - point.hit_loss_n * point.t
    end
end

function cull_field(ff)
    -- Remove points above the set limit of points to simulate in the field. 
    local points = flatten(ff.field)
    if #points > ff.max_sim_points then
        while #points > ff.max_sim_points do
            local index = math.random(#points)
            if index ~= 0 then 
                local remove_point = points[index]
                field_put(ff.field, nil, remove_point.coord)
                table.remove(points, index)
            end
        end
    end

    for i = 1, #points do
        local point = points[i]
        if point.cull then 
            field_put(ff.field, nil, point.coord)
        end
    end
end

function pos_to_coord(pos, resolution)
    return Vec(
        math.floor(pos[1] / resolution),
        math.floor(pos[2] / resolution),
        math.floor(pos[3] / resolution))
end

function field_put(field, value, coord)
    -- Puts a value into a field at a coordinate.
    -- Fields are a hashed multidim array. They automatically allocate when 
    -- needed and will automatically deallocate when elements are set to nil.
    -- Optimized for fast access.

    -- field["points"] is a cache of the flattened
    -- multidimensional array. Clearing it forces
    -- regeneration. This is cleared whenever the field changes. 

    local xk = tostring(coord[1])
    local yk = tostring(coord[2])
    local zk = tostring(coord[3])

    -- allocate
    if field[xk] == nil then
        field[xk] = {}
    end

    if field[xk][yk] == nil then
        field[xk][yk] = {}
    end

    if field[xk][yk][zk] == nil then 
        field["points"] = nil
    end

    -- set
    field[xk][yk][zk] = value

    -- deallocate
    if value == nil then 
        field["points"] = nil
        local count = pairs(field[xk][yk])
        if count == 0 then 
            field[xk][yk] = nil
        end

        count = pairs(field[xk])
        if count == 0 then 
            field[xk] = nil
        end
    end
end

function field_get(field, coord)
    -- Get a value from a field coordinate.
    -- See field_put() for description of what a field is and how it
    -- operates.
    local xk = tostring(coord[1])
    local yk = tostring(coord[2])
    local zk = tostring(coord[3])
    if field[xk] == nil then
        return nil
    end
    if field[xk][yk] == nil then
        return nil
    end
    if field[xk][yk][zk] == nil then
        return nil
    end
    return field[xk][yk][zk]
end

function flatten(field)
    -- flatten the entire field into a list of points (values at coordinates).
    -- Will return a cached list unless that list is nil.
    if field["points"] == nil then 
        local points = {}
        for x, yt in pairs(field) do
            for y, zt in pairs(yt) do
                for z, point in pairs (zt) do
                    table.insert(points, point)
                end
            end
        end
        field["points"] = points
    end

    return shallow_copy(field["points"])
end

function debug_field(ff)
    local points = flatten(ff.field)
    for i = 1, #points do
        local point = points[i]
        DebugCross(point.pos, 1, 0, 0, normalize(point.t, ff.mean_t, ff.sd_t))
        DebugCross(point.pos, 0, 1, 0, normalize(point.f, ff.mean_f, ff.sd_f))
        DebugCross(point.pos, 0, 0, 1, normalize(point.p, ff.mean_p, ff.sd_p))
    end
end

function force_field_update(ff, dt)
    synchronize(ff)
    cull_field(ff)
    burn_fuel(ff, dt)
    resolve_dirs(ff, dt)
    resolve_primes(ff, dt)
    propagate_values(ff, dt)
    if ff.debug then 
        debug_field(ff)
    end
end

function force_field_tick(ff, dt) 
end

point_type = enum {
	"base",
	"meta"
}

curve_type = enum {
    "linear",
    "sqrt",
    "square"
}