--!strict
local Lighting = game:GetService("Lighting")

local World = {}

local ivory = Color3.fromRGB(232, 226, 214)
local marble = Color3.fromRGB(238, 234, 226)
local brass = Color3.fromRGB(168, 138, 86)
local ink = Color3.fromRGB(16, 14, 18)
local wine = Color3.fromRGB(86, 24, 34)
local glassCol = Color3.fromRGB(150, 178, 198)
local neon = Color3.fromRGB(118, 168, 255)
local gold = Color3.fromRGB(212, 175, 110)
local stone = Color3.fromRGB(42, 40, 46)
local water = Color3.fromRGB(36, 64, 82)
local carpet = Color3.fromRGB(48, 22, 28)

local root: Folder
local waypoints: { Vector3 } = {}
local spawns: { Vector3 } = {}
local tasks: { BasePart } = {}

-- Floor height. Keep near default Studio spawn so Play Solo never drops into the void.
local Y = 0

local function part(props: { [string]: any }): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.TopSurface.Smooth
	p.BottomSurface = Enum.BottomSurface.Smooth
	p.CastShadow = true
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = root
	return p
end

local function light(parent: BasePart, color: Color3, brightness: number, range: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Shadows = false
	l.Parent = parent
end

local function wp(v: Vector3)
	table.insert(waypoints, v)
end

function World.waypoints(): { Vector3 }
	return waypoints
end

function World.spawns(): { Vector3 }
	return spawns
end

function World.tasks(): { BasePart }
	return tasks
end

function World.floorY(): number
	return Y
end

function World.applyLighting()
	Lighting.ClockTime = 20.4
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(92, 84, 98)
	Lighting.OutdoorAmbient = Color3.fromRGB(62, 68, 96)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 196, 140)
	Lighting.ColorShift_Bottom = Color3.fromRGB(48, 56, 96)
	Lighting.FogColor = Color3.fromRGB(24, 26, 44)
	Lighting.FogStart = 180
	Lighting.FogEnd = 900
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.45
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 0.55
	pcall(function()
		Lighting.Technology = Enum.Technology.ShadowMap
	end)

	for _, n in ipairs({ "Atmosphere", "ColorCorrection", "Bloom", "DepthOfField", "Sky", "SunRaysEffect" }) do
		local old = Lighting:FindFirstChild(n)
		if old then
			old:Destroy()
		end
	end

	local atm = Instance.new("Atmosphere")
	atm.Density = 0.06
	atm.Offset = 0.28
	atm.Color = Color3.fromRGB(110, 104, 128)
	atm.Decay = Color3.fromRGB(48, 44, 70)
	atm.Glare = 0.22
	atm.Haze = 0.22
	atm.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.06
	cc.Contrast = 0.05
	cc.Saturation = 0.08
	cc.TintColor = Color3.fromRGB(255, 244, 232)
	cc.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.22
	bloom.Size = 18
	bloom.Threshold = 1.15
	bloom.Parent = Lighting

	-- Keep the default sky textures. Blank skybox IDs render as a black void.
	local sky = Instance.new("Sky")
	sky.CelestialBodiesShown = true
	sky.StarCount = 2500
	sky.SunAngularSize = 8
	sky.MoonAngularSize = 12
	sky.Parent = Lighting
end

local function makeTask(name: string, pos: Vector3, color: Color3)
	local t = part({
		Name = "Task_" .. name,
		Size = Vector3.new(3.2, 1.2, 3.2),
		Position = pos,
		Material = Enum.Material.Metal,
		Color = color,
		Shape = Enum.PartType.Cylinder,
	})
	t.Orientation = Vector3.new(0, 0, 90)
	light(t, color, 2, 14)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Complete"
	prompt.ObjectText = name
	prompt.HoldDuration = 1.4
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = t
	table.insert(tasks, t)
	wp(pos)
end

local function chandelier(pos: Vector3)
	local stem = part({
		Size = Vector3.new(0.35, 6, 0.35),
		Position = pos + Vector3.new(0, 3, 0),
		Material = Enum.Material.Metal,
		Color = brass,
	})
	local bowl = part({
		Size = Vector3.new(6.5, 0.6, 6.5),
		Position = pos,
		Material = Enum.Material.Glass,
		Color = gold,
		Transparency = 0.15,
		Shape = Enum.PartType.Ball,
	})
	light(bowl, Color3.fromRGB(255, 220, 170), 6, 42)
	light(stem, Color3.fromRGB(255, 200, 140), 2, 20)
end

local function column(x: number, z: number, y: number, h: number)
	part({
		Size = Vector3.new(1.6, h, 1.6),
		Position = Vector3.new(x, y + h / 2, z),
		Material = Enum.Material.Marble,
		Color = marble,
	})
	part({
		Size = Vector3.new(2.3, 0.5, 2.3),
		Position = Vector3.new(x, y + h, z),
		Material = Enum.Material.Marble,
		Color = ivory,
	})
end

local function city()
	local rng = Random.new(80)
	for i = 1, 48 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(130, 280)
		local h = rng:NextNumber(40, 170)
		local w = rng:NextNumber(10, 22)
		local d = rng:NextNumber(10, 22)
		local x = math.cos(a) * r
		local z = math.sin(a) * r
		local tower = part({
			Size = Vector3.new(w, h, d),
			Position = Vector3.new(x, h / 2, z),
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(12, 14, 22),
			CanCollide = false,
		})
		if i % 3 == 0 then
			local band = part({
				Size = Vector3.new(w + 0.4, 2.4, d + 0.4),
				Position = Vector3.new(x, h * rng:NextNumber(0.4, 0.9), z),
				Material = Enum.Material.Neon,
				Color = if i % 6 == 0 then gold else neon,
				CanCollide = false,
			})
			light(band, band.Color, 2.4, 48)
		end
		tower.CastShadow = false
	end
end

function World.build()
	local existing = workspace:FindFirstChild("Highrise")
	if existing then
		existing:Destroy()
	end
	root = Instance.new("Folder")
	root.Name = "Highrise"
	root.Parent = workspace
	waypoints = {}
	spawns = {}
	tasks = {}

	-- Floor
	part({
		Name = "Floor",
		Size = Vector3.new(148, 2, 140),
		Position = Vector3.new(0, Y, -14),
		Material = Enum.Material.Marble,
		Color = marble,
	})
	-- Carpet runner
	part({
		Size = Vector3.new(10, 0.2, 70),
		Position = Vector3.new(0, Y + 1.1, 0),
		Material = Enum.Material.Fabric,
		Color = carpet,
	})
	-- Ceiling
	local ceiling = part({
		Name = "Ceiling",
		Size = Vector3.new(148, 1.5, 112),
		Position = Vector3.new(0, Y + 22, 0),
		Material = Enum.Material.SmoothPlastic,
		Color = ink,
	})
	local downLight = Instance.new("SurfaceLight")
	downLight.Face = Enum.NormalId.Bottom
	downLight.Brightness = 2.4
	downLight.Range = 48
	downLight.Angle = 90
	downLight.Color = Color3.fromRGB(255, 226, 190)
	downLight.Parent = ceiling

	-- Outer walls
	local walls = {
		{ Vector3.new(148, 20, 2), Vector3.new(0, Y + 11, 56) },
		{ Vector3.new(148, 20, 2), Vector3.new(0, Y + 11, -56) },
		{ Vector3.new(2, 20, 112), Vector3.new(74, Y + 11, 0) },
		{ Vector3.new(2, 20, 112), Vector3.new(-74, Y + 11, 0) },
	}
	for _, w in ipairs(walls) do
		part({
			Size = w[1],
			Position = w[2],
			Material = Enum.Material.Marble,
			Color = ivory,
		})
	end

	-- Glass north wall (terrace)
	part({
		Name = "GlassNorth",
		Size = Vector3.new(70, 16, 0.4),
		Position = Vector3.new(0, Y + 10, 38),
		Material = Enum.Material.Glass,
		Color = glassCol,
		Transparency = 0.45,
		Reflectance = 0.25,
	})

	-- Interior partitions
	part({ Size = Vector3.new(2, 16, 36), Position = Vector3.new(-28, Y + 10, -8), Material = Enum.Material.Marble, Color = ivory })
	part({ Size = Vector3.new(2, 16, 36), Position = Vector3.new(28, Y + 10, -8), Material = Enum.Material.Marble, Color = ivory })
	part({ Size = Vector3.new(24, 16, 2), Position = Vector3.new(-48, Y + 10, 10), Material = Enum.Material.Marble, Color = ivory })
	part({ Size = Vector3.new(24, 16, 2), Position = Vector3.new(48, Y + 10, 10), Material = Enum.Material.Marble, Color = ivory })
	part({ Size = Vector3.new(36, 16, 2), Position = Vector3.new(0, Y + 10, -28), Material = Enum.Material.Marble, Color = ivory })

	for x = -20, 20, 10 do
		column(x, -18, Y + 1, 16)
		column(x, 18, Y + 1, 16)
	end

	chandelier(Vector3.new(0, Y + 16, 0))
	chandelier(Vector3.new(-40, Y + 16, -16))
	chandelier(Vector3.new(40, Y + 16, -16))
	chandelier(Vector3.new(0, Y + 16, 28))
	chandelier(Vector3.new(0, Y + 16, -40))

	-- Ceiling neon strips so the hall is never dark
	for z = -40, 32, 18 do
		local strip = part({
			Size = Vector3.new(90, 0.2, 0.6),
			Position = Vector3.new(0, Y + 21.1, z),
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 214, 160),
			CastShadow = false,
		})
		light(strip, Color3.fromRGB(255, 220, 170), 2.2, 28)
	end

	local fill = part({
		Name = "FillLight",
		Size = Vector3.new(1, 1, 1),
		Position = Vector3.new(0, Y + 14, 0),
		Transparency = 1,
		CanCollide = false,
		CastShadow = false,
	})
	light(fill, Color3.fromRGB(255, 230, 200), 3.5, 90)

	-- Brass trim along floor
	for _, z in ipairs({ -54, 54 }) do
		part({
			Size = Vector3.new(146, 0.3, 0.4),
			Position = Vector3.new(0, Y + 1.15, z),
			Material = Enum.Material.Metal,
			Color = brass,
		})
	end

	-- Pool terrace (north)
	part({
		Name = "Terrace",
		Size = Vector3.new(80, 1.4, 36),
		Position = Vector3.new(0, Y - 0.2, 72),
		Material = Enum.Material.SmoothPlastic,
		Color = stone,
	})
	local pool = part({
		Name = "Pool",
		Size = Vector3.new(36, 1.2, 16),
		Position = Vector3.new(0, Y + 0.4, 74),
		Material = Enum.Material.Glass,
		Color = water,
		Transparency = 0.35,
		Reflectance = 0.4,
	})
	light(pool, Color3.fromRGB(70, 140, 180), 3, 28)
	part({
		Size = Vector3.new(38, 1.6, 1),
		Position = Vector3.new(0, Y + 1.2, 65.5),
		Material = Enum.Material.Marble,
		Color = marble,
	})
	part({
		Size = Vector3.new(38, 1.6, 1),
		Position = Vector3.new(0, Y + 1.2, 82.5),
		Material = Enum.Material.Marble,
		Color = marble,
	})

	-- Rain over terrace
	local rainBox = part({
		Name = "Rain",
		Size = Vector3.new(80, 1, 36),
		Position = Vector3.new(0, Y + 24, 72),
		Transparency = 1,
		CanCollide = false,
		CastShadow = false,
	})
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(180, 190, 210))
	pe.Size = NumberSequence.new(0.08, 0.02)
	pe.Lifetime = NumberRange.new(0.7, 1.1)
	pe.Rate = 220
	pe.Speed = NumberRange.new(40, 55)
	pe.SpreadAngle = Vector2.new(4, 4)
	pe.EmissionDirection = Enum.NormalId.Bottom
	pe.LightInfluence = 0
	pe.Parent = rainBox

	-- Furniture: lounge
	for i = -1, 1 do
		part({
			Size = Vector3.new(8, 1.4, 3.2),
			Position = Vector3.new(i * 12, Y + 1.8, 8),
			Material = Enum.Material.Fabric,
			Color = wine,
		})
		part({
			Size = Vector3.new(8, 2.2, 0.5),
			Position = Vector3.new(i * 12, Y + 2.6, 9.4),
			Material = Enum.Material.Fabric,
			Color = wine,
		})
	end
	part({
		Size = Vector3.new(10, 0.6, 4),
		Position = Vector3.new(0, Y + 1.4, 2),
		Material = Enum.Material.Marble,
		Color = ivory,
	})
	part({
		Size = Vector3.new(4, 0.2, 4),
		Position = Vector3.new(0, Y + 1.8, 2),
		Material = Enum.Material.Metal,
		Color = brass,
	})

	-- Gallery paintings (west)
	for i = 1, 4 do
		local z = -30 + i * 8
		part({
			Size = Vector3.new(0.3, 6, 4.5),
			Position = Vector3.new(-72.6, Y + 10, z),
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(20 + i * 12, 16, 28),
		})
		part({
			Size = Vector3.new(0.2, 6.4, 4.9),
			Position = Vector3.new(-72.4, Y + 10, z),
			Material = Enum.Material.Metal,
			Color = brass,
		})
	end

	-- Kitchen counters (east)
	part({
		Size = Vector3.new(18, 2.2, 4),
		Position = Vector3.new(52, Y + 2.2, -8),
		Material = Enum.Material.SmoothPlastic,
		Color = ink,
	})
	part({
		Size = Vector3.new(18, 0.2, 4.2),
		Position = Vector3.new(52, Y + 3.4, -8),
		Material = Enum.Material.Marble,
		Color = marble,
	})
	for i = 0, 3 do
		part({
			Size = Vector3.new(0.8, 1.6, 0.8),
			Position = Vector3.new(46 + i * 4, Y + 4.4, -8),
			Material = Enum.Material.Glass,
			Color = wine,
			Transparency = 0.25,
		})
	end

	-- Elevator bank (south)
	for i = -1, 1 do
		part({
			Size = Vector3.new(8, 14, 1),
			Position = Vector3.new(i * 12, Y + 8, -54.4),
			Material = Enum.Material.Metal,
			Color = brass,
		})
		part({
			Size = Vector3.new(6, 12, 0.4),
			Position = Vector3.new(i * 12, Y + 7, -53.9),
			Material = Enum.Material.SmoothPlastic,
			Color = ink,
		})
		light(part({
			Size = Vector3.new(1, 0.3, 0.3),
			Position = Vector3.new(i * 12, Y + 14, -53.6),
			Material = Enum.Material.Neon,
			Color = gold,
		}), gold, 2.4, 12)
	end

	-- Helipad accent
	part({
		Size = Vector3.new(16, 0.4, 16),
		Position = Vector3.new(48, Y + 1.3, 72),
		Material = Enum.Material.Metal,
		Color = ink,
	})
	part({
		Size = Vector3.new(10, 0.2, 1.2),
		Position = Vector3.new(48, Y + 1.6, 72),
		Material = Enum.Material.Neon,
		Color = gold,
	})

	-- Neon HIGHRISE sign
	local sign = part({
		Name = "Sign",
		Size = Vector3.new(28, 3.2, 0.4),
		Position = Vector3.new(0, Y + 18.5, 37.6),
		Material = Enum.Material.Neon,
		Color = gold,
		CanCollide = false,
	})
	light(sign, gold, 3.2, 36)

	makeTask("Guest book", Vector3.new(-40, Y + 1.6, -16), brass)
	makeTask("Wine cellar", Vector3.new(48, Y + 1.6, -22), wine)
	makeTask("Piano", Vector3.new(-48, Y + 1.6, 22), ivory)
	makeTask("Fuse box", Vector3.new(40, Y + 1.6, 22), Color3.fromRGB(80, 80, 90))
	makeTask("Vault keypad", Vector3.new(58, Y + 1.6, -40), gold)

	-- Piano body
	part({
		Size = Vector3.new(8, 1.8, 3.4),
		Position = Vector3.new(-48, Y + 2, 26),
		Material = Enum.Material.SmoothPlastic,
		Color = ink,
	})

	-- Spawn pads in lobby hall
	for i = 1, 8 do
		local a = (i / 8) * math.pi * 2
		local s = Vector3.new(math.cos(a) * 10, Y + 4, math.sin(a) * 8)
		table.insert(spawns, s)
		wp(s)
	end
	wp(Vector3.new(0, Y + 4, 70))
	wp(Vector3.new(-50, Y + 4, -20))
	wp(Vector3.new(50, Y + 4, -20))
	wp(Vector3.new(-50, Y + 4, 20))
	wp(Vector3.new(50, Y + 4, 20))
	wp(Vector3.new(0, Y + 4, -40))
	wp(Vector3.new(48, Y + 4, 70))

	city()

	-- Lobby connected to the south hall (no gap, no void)
	part({
		Name = "LobbyFloor",
		Size = Vector3.new(48, 2, 48),
		Position = Vector3.new(0, Y, -72),
		Material = Enum.Material.Marble,
		Color = marble,
	})
	part({
		Size = Vector3.new(48, 12, 2),
		Position = Vector3.new(0, Y + 7, -95),
		Material = Enum.Material.Marble,
		Color = ivory,
	})
	chandelier(Vector3.new(0, Y + 14, -72))

	-- Void catcher under the whole map
	part({
		Name = "Catch",
		Size = Vector3.new(500, 4, 500),
		Position = Vector3.new(0, Y - 24, 0),
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(10, 12, 18),
		CastShadow = false,
	})

	World.LobbySpawn = Vector3.new(0, Y + 5, 0)
end

World.LobbySpawn = Vector3.new(0, 5, 0)

return World
