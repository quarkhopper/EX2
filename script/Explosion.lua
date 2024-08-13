#include "PyroField.lua"
#include "Utils.lua"
#include "Types.lua"
#include "Defs.lua"
#include "HSVRGB.lua"

boomSound = LoadSound("MOD/snd/toiletBoom.ogg")
rumbleSound = LoadSound("MOD/snd/rumble.ogg")

function explosion_tick(dt)
	local undetonated = {}
	for i=1, #bombs do
		local bomb = bombs[i]
		if IsShapeBroken(bomb) then
			detonate(bomb)
		else
			table.insert(undetonated, bomb)
		end
	end
	bombs = undetonated
end

function detonateAll()
	for i=1, #bombs do
		local bomb = bombs[i]
		detonate(bomb)
	end
	bombs = {}
end

function detonate(bomb)
	local bombTrans = GetShapeWorldTransform(bomb)
	createExplosion(bombTrans.pos)
	-- Explosion(bombTrans.pos, 3)
	PlaySound(boomSound, bombTrans.pos, 5)
	PlaySound(rumbleSound, bombTrans.pos, 5)
end

function createExplosion(pos)
	for i = 1, TOOL_OPTIONS.explosion_seeds.value do
		local inj_dir = VecNormalize(random_vec(1)) 
		local inj_pos = VecAdd(pos, VecScale(inj_dir, math.random() * TOOL_OPTIONS.explosion_radius.value))
		inject(TOOL_OPTIONS.pyro.ff, inj_pos, CONSTS.EXPLOSION_F)
	end
end

function makeSmoke(pos, options)
	local movement = options.movement or random_vec(1)
	local lifetime = options.smokeLife or CONSTS.SMOKE_LIFE
	local gravity = options.gravity or 1
	local smokeSize = options.smokeSize or math.random(2,5) * 0.1
	local smokeColor = options.smokeColor or HSVToRGB(Vec(0, 0, 0.2))
	local alphaStart = options.alphaStart or 0
	local alphaEnd = options.alphaEnd or 0.8
	local alphaGraph = options.alphaFunction or "easeout"
	local alphaFadeIn = options.alphaFadeIn or 0
	local alphaFadeOut = options.alphaFadeOut or 1
	local drag = options.drag or 0.5

	-- smoke puff
	ParticleReset()
	ParticleType("smoke")
	ParticleDrag(drag)
	ParticleAlpha(alphaStart, alphaEnd, alphaGraph, alphaFadeIn, alphaFadeOut)
	ParticleRadius(smokeSize)
	ParticleColor(smokeColor[1], smokeColor[2], smokeColor[3])
	ParticleGravity(gravity * 0.25)
	SpawnParticle(VecAdd(pos, random_vec(CONSTS.SPARK_JIGGLE)), movement, lifetime)
end
