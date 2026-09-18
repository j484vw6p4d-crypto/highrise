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

-- Playable box. Floor top is 10. Walls keep you in. Bedrock makes falling impossible.
local FLOOR_TOP = 10
local HALF_X = 68
local HALF_Z = 52
local WALL_H = 22

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
	return FLOOR_TOP
end

function World.hrpHeight(): number
	return FLOOR_TOP + 3.2
end

function World.contains(pos: Vector3): boolean
	return math.abs(pos.X) < 85
		and math.abs(pos.Z) < 85
		and pos.Y > FLOOR_TOP - 6
		and pos.Y < FLOOR_TOP + 50
end

function World.safe(pos: Vector3): Vector3
	return Vector3.new(
		math.clamp(pos.X, -HALF_X + 8, HALF_X - 8),
		math.clamp(pos.Y, FLOOR_TOP + 3.2, FLOOR_TOP + 8),
		math.clamp(pos.Z, -HALF_Z + 8, HALF_Z - 8)
	)
end

function World.applyLighting()
	Lighting.ClockTime = 20.5
	Lighting.Brightness = 3.2
	Lighting.Ambient = Color3.fromRGB(100, 92, 104)
	Lighting.OutdoorAmbient = Color3.fromRGB(70, 74, 100)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 196, 140)
	Lighting.ColorShift_Bottom = Color3.fromRGB(48, 56, 96)
	Lighting.FogColor = Color3.fromRGB(24, 26, 44)
	Lighting.FogStart = 220
	Lighting.FogEnd = 1200
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.5
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 0.5
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
	atm.Density = 0.05
	atm.Offset = 0.3
	atm.Color = Color3.fromRGB(110, 104, 128)
	atm.Decay = Color3.fromRGB(48, 44, 70)
	atm.Glare = 0.2
	atm.Haze = 0.18
	atm.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.08
	cc.Contrast = 0.04
	cc.Saturation = 0.08
	cc.TintColor = Color3.fromRGB(255, 244, 232)
	cc.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.2
	bloom.Size = 16
	bloom.Threshold = 1.2
	bloom.Parent = Lighting

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
	light(t, color, 2, 12)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Complete"
	prompt.ObjectText = name
	prompt.HoldDuration = 1.2
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = t
	table.insert(tasks, t)
	wp(pos + Vector3.new(0, 2, 0))
end

local function chandelier(pos: Vector3)
	local stem = part({
		Size = Vector3.new(0.35, 6, 0.35),
		Position = pos + Vector3.new(0, 3, 0),
		Material = Enum.Material.Metal,
		Color = brass,
	})
	local bowl = part({
		Size = Vector3.new(6, 0.55, 6),
		Position = pos,
		Material = Enum.Material.Glass,
		Color = gold,
		Transparency = 0.15,
		Shape = Enum.PartType.Ball,
	})
	light(bowl, Color3.fromRGB(255, 220, 170), 5, 36)
	light(stem, Color3.fromRGB(255, 200, 140), 1.6, 16)
end

local function column(x: number, z: number)
	part({
		Size = Vector3.new(1.6, WALL_H - 2, 1.6),
		Position = Vector3.new(x, FLOOR_TOP + (WALL_H - 2) / 2, z),
		Material = Enum.Material.Marble,
		Color = marble,
	})
	part({
		Size = Vector3.new(2.2, 0.45, 2.2),
		Position = Vector3.new(x, FLOOR_TOP + WALL_H - 2, z),
		Material = Enum.Material.Marble,
		Color = ivory,
	})
end

-- Wall with a centered doorway so rooms connect.
local function wallDoor(size: Vector3, pos: Vector3, doorWidth: number, alongX: boolean)
	if alongX then
		local side = (size.X - doorWidth) / 2
		part({
			Size = Vector3.new(side, size.Y, size.Z),
			Position = pos + Vector3.new(-(doorWidth + side) / 2, 0, 0),
			Material = Enum.Material.Marble,
			Color = ivory,
		})
		part({
			Size = Vector3.new(side, size.Y, size.Z),
			Position = pos + Vector3.new((doorWidth + side) / 2, 0, 0),
			Material = Enum.Material.Marble,
			Color = ivory,
		})
		part({
			Size = Vector3.new(doorWidth, 4, size.Z),
			Position = pos + Vector3.new(0, size.Y / 2 - 2, 0),
			Material = Enum.Material.Marble,
			Color = ivory,
		})
	else
		local side = (size.Z - doorWidth) / 2
		part({
			Size = Vector3.new(size.X, size.Y, side),
			Position = pos + Vector3.new(0, 0, -(doorWidth + side) / 2),
			Material = Enum.Material.Marble,
			Color = ivory,
		})
		part({
			Size = Vector3.new(size.X, size.Y, side),
			Position = pos + Vector3.new(0, 0, (doorWidth + side) / 2),
			Material = Enum.Material.Marble,
			Color = ivory,
		})
		part({
			Size = Vector3.new(size.X, 4, doorWidth),
			Position = pos + Vector3.new(0, size.Y / 2 - 2, 0),
			Material = Enum.Material.Marble,
			Color = ivory,
		})
	end
end

local function city()
	local rng = Random.new(80)
	for i = 1, 40 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(140, 300)
		local h = rng:NextNumber(50, 180)
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
		tower.CastShadow = false
		if i % 3 == 0 then
			local band = part({
				Size = Vector3.new(w + 0.4, 2.4, d + 0.4),
				Position = Vector3.new(x, h * rng:NextNumber(0.4, 0.9), z),
				Material = Enum.Material.Neon,
				Color = if i % 6 == 0 then gold else neon,
				CanCollide = false,
			})
			band.CastShadow = false
			light(band, band.Color, 2, 40)
		end
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

	-- Solid bedrock: you cannot fall through this.
	part({
		Name = "Bedrock",
		Size = Vector3.new(420, 40, 420),
		Position = Vector3.new(0, FLOOR_TOP - 20, 0),
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(10, 12, 18),
		CastShadow = false,
	})

	-- Marble playable floor on top of bedrock
	part({
		Name = "Floor",
		Size = Vector3.new(HALF_X * 2, 2, HALF_Z * 2),
		Position = Vector3.new(0, FLOOR_TOP - 1, 0),
		Material = Enum.Material.Marble,
		Color = marble,
	})
	part({
		Size = Vector3.new(10, 0.2, 70),
		Position = Vector3.new(0, FLOOR_TOP + 0.15, 0),
		Material = Enum.Material.Fabric,
		Color = carpet,
	})

	-- Ceiling
	local ceiling = part({
		Name = "Ceiling",
		Size = Vector3.new(HALF_X * 2, 2, HALF_Z * 2),
		Position = Vector3.new(0, FLOOR_TOP + WALL_H, 0),
		Material = Enum.Material.SmoothPlastic,
		Color = ink,
	})
	local downLight = Instance.new("SurfaceLight")
	downLight.Face = Enum.NormalId.Bottom
	downLight.Brightness = 2.6
	downLight.Range = 50
	downLight.Angle = 90
	downLight.Color = Color3.fromRGB(255, 226, 190)
	downLight.Parent = ceiling

	-- Outer envelope (sealed). North face is glass so the city is visible.
	part({
		Name = "WallS",
		Size = Vector3.new(HALF_X * 2, WALL_H, 3),
		Position = Vector3.new(0, FLOOR_TOP + WALL_H / 2, -HALF_Z),
		Material = Enum.Material.Marble,
		Color = ivory,
	})
	part({
		Name = "WallE",
		Size = Vector3.new(3, WALL_H, HALF_Z * 2),
		Position = Vector3.new(HALF_X, FLOOR_TOP + WALL_H / 2, 0),
		Material = Enum.Material.Marble,
		Color = ivory,
	})
	part({
		Name = "WallW",
		Size = Vector3.new(3, WALL_H, HALF_Z * 2),
		Position = Vector3.new(-HALF_X, FLOOR_TOP + WALL_H / 2, 0),
		Material = Enum.Material.Marble,
		Color = ivory,
	})
	part({
		Name = "WallN",
		Size = Vector3.new(HALF_X * 2, WALL_H, 2),
		Position = Vector3.new(0, FLOOR_TOP + WALL_H / 2, HALF_Z),
		Material = Enum.Material.Glass,
		Color = glassCol,
		Transparency = 0.35,
		Reflectance = 0.28,
	})

	-- Invisible outer cage, taller than jump height
	local cageH = 60
	local cage = {
		{ Vector3.new(180, cageH, 4), Vector3.new(0, FLOOR_TOP + cageH / 2, 90) },
		{ Vector3.new(180, cageH, 4), Vector3.new(0, FLOOR_TOP + cageH / 2, -90) },
		{ Vector3.new(4, cageH, 180), Vector3.new(90, FLOOR_TOP + cageH / 2, 0) },
		{ Vector3.new(4, cageH, 180), Vector3.new(-90, FLOOR_TOP + cageH / 2, 0) },
	}
	for i, w in ipairs(cage) do
		part({
			Name = "Cage" .. i,
			Size = w[1],
			Position = w[2],
			Transparency = 1,
			CanCollide = true,
			CastShadow = false,
		})
	end

	-- Interior rooms with doorways
	wallDoor(Vector3.new(2, 16, 40), Vector3.new(-30, FLOOR_TOP + 8, -6), 10, false)
	wallDoor(Vector3.new(2, 16, 40), Vector3.new(30, FLOOR_TOP + 8, -6), 10, false)
	wallDoor(Vector3.new(40, 16, 2), Vector3.new(0, FLOOR_TOP + 8, -24), 12, true)

	for x = -16, 16, 16 do
		column(x, -16)
		column(x, 16)
	end

	chandelier(Vector3.new(0, FLOOR_TOP + 16, 0))
	chandelier(Vector3.new(-38, FLOOR_TOP + 16, -14))
	chandelier(Vector3.new(38, FLOOR_TOP + 16, -14))
	chandelier(Vector3.new(0, FLOOR_TOP + 16, 28))
	chandelier(Vector3.new(0, FLOOR_TOP + 16, -36))

	for z = -36, 28, 16 do
		local strip = part({
			Size = Vector3.new(80, 0.2, 0.5),
			Position = Vector3.new(0, FLOOR_TOP + WALL_H - 1.2, z),
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 214, 160),
			CastShadow = false,
		})
		light(strip, Color3.fromRGB(255, 220, 170), 1.8, 24)
	end

	local fill = part({
		Name = "FillLight",
		Size = Vector3.new(1, 1, 1),
		Position = Vector3.new(0, FLOOR_TOP + 12, 0),
		Transparency = 1,
		CanCollide = false,
		CastShadow = false,
	})
	light(fill, Color3.fromRGB(255, 230, 200), 3.2, 80)

	-- Indoor pool (walkable glass, not a hole)
	part({
		Name = "PoolDeck",
		Size = Vector3.new(44, 0.4, 18),
		Position = Vector3.new(0, FLOOR_TOP + 0.25, 34),
		Material = Enum.Material.SmoothPlastic,
		Color = stone,
	})
	local pool = part({
		Name = "Pool",
		Size = Vector3.new(32, 0.4, 12),
		Position = Vector3.new(0, FLOOR_TOP + 0.45, 34),
		Material = Enum.Material.Glass,
		Color = water,
		Transparency = 0.3,
		Reflectance = 0.4,
	})
	light(pool, Color3.fromRGB(70, 140, 180), 2.6, 22)
	-- Rail around pool
	for _, rz in ipairs({ 26, 42 }) do
		part({
			Size = Vector3.new(46, 3, 0.4),
			Position = Vector3.new(0, FLOOR_TOP + 1.7, rz),
			Material = Enum.Material.Metal,
			Color = brass,
		})
	end
	for _, rx in ipairs({ -22, 22 }) do
		part({
			Size = Vector3.new(0.4, 3, 16),
			Position = Vector3.new(rx, FLOOR_TOP + 1.7, 34),
			Material = Enum.Material.Metal,
			Color = brass,
		})
	end

	-- Lounge sofas
	for i = -1, 1 do
		part({
			Size = Vector3.new(8, 1.4, 3.2),
			Position = Vector3.new(i * 12, FLOOR_TOP + 0.85, 8),
			Material = Enum.Material.Fabric,
			Color = wine,
		})
		part({
			Size = Vector3.new(8, 2.2, 0.5),
			Position = Vector3.new(i * 12, FLOOR_TOP + 1.6, 9.4),
			Material = Enum.Material.Fabric,
			Color = wine,
		})
	end
	part({
		Size = Vector3.new(10, 0.5, 4),
		Position = Vector3.new(0, FLOOR_TOP + 0.4, 2),
		Material = Enum.Material.Marble,
		Color = ivory,
	})
	part({
		Size = Vector3.new(4, 0.2, 4),
		Position = Vector3.new(0, FLOOR_TOP + 0.75, 2),
		Material = Enum.Material.Metal,
		Color = brass,
	})

	-- Gallery paintings (west room)
	for i = 1, 4 do
		local z = -20 + i * 8
		part({
			Size = Vector3.new(0.3, 6, 4.5),
			Position = Vector3.new(-66.4, FLOOR_TOP + 9, z),
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(20 + i * 12, 16, 28),
		})
		part({
			Size = Vector3.new(0.2, 6.4, 4.9),
			Position = Vector3.new(-66.2, FLOOR_TOP + 9, z),
			Material = Enum.Material.Metal,
			Color = brass,
		})
	end

	-- Kitchen (east)
	part({
		Size = Vector3.new(16, 2.2, 4),
		Position = Vector3.new(48, FLOOR_TOP + 1.2, -8),
		Material = Enum.Material.SmoothPlastic,
		Color = ink,
	})
	part({
		Size = Vector3.new(16, 0.2, 4.2),
		Position = Vector3.new(48, FLOOR_TOP + 2.4, -8),
		Material = Enum.Material.Marble,
		Color = marble,
	})
	for i = 0, 3 do
		part({
			Size = Vector3.new(0.8, 1.6, 0.8),
			Position = Vector3.new(42 + i * 4, FLOOR_TOP + 3.4, -8),
			Material = Enum.Material.Glass,
			Color = wine,
			Transparency = 0.25,
		})
	end

	-- Elevators (south, decorative, solid)
	for i = -1, 1 do
		part({
			Size = Vector3.new(8, 14, 1),
			Position = Vector3.new(i * 12, FLOOR_TOP + 8, -HALF_Z + 2.2),
			Material = Enum.Material.Metal,
			Color = brass,
		})
		part({
			Size = Vector3.new(6, 12, 0.4),
			Position = Vector3.new(i * 12, FLOOR_TOP + 7, -HALF_Z + 2.6),
			Material = Enum.Material.SmoothPlastic,
			Color = ink,
		})
		light(part({
			Size = Vector3.new(1, 0.3, 0.3),
			Position = Vector3.new(i * 12, FLOOR_TOP + 14, -HALF_Z + 3),
			Material = Enum.Material.Neon,
			Color = gold,
		}), gold, 2, 10)
	end

	local sign = part({
		Name = "Sign",
		Size = Vector3.new(28, 3.2, 0.4),
		Position = Vector3.new(0, FLOOR_TOP + 17, HALF_Z - 1.4),
		Material = Enum.Material.Neon,
		Color = gold,
		CanCollide = false,
	})
	light(sign, gold, 3, 32)

	local hrpY = World.hrpHeight()
	makeTask("Guest book", Vector3.new(-40, FLOOR_TOP + 0.7, -14), brass)
	makeTask("Wine cellar", Vector3.new(46, FLOOR_TOP + 0.7, -20), wine)
	makeTask("Piano", Vector3.new(-46, FLOOR_TOP + 0.7, 18), ivory)
	makeTask("Fuse box", Vector3.new(40, FLOOR_TOP + 0.7, 18), Color3.fromRGB(80, 80, 90))
	makeTask("Vault keypad", Vector3.new(50, FLOOR_TOP + 0.7, -36), gold)

	part({
		Size = Vector3.new(8, 1.8, 3.4),
		Position = Vector3.new(-46, FLOOR_TOP + 1.05, 22),
		Material = Enum.Material.SmoothPlastic,
		Color = ink,
	})

	-- Spawn ring in the open hall (all inside the box)
	for i = 1, 8 do
		local a = (i / 8) * math.pi * 2
		local s = Vector3.new(math.cos(a) * 10, hrpY, math.sin(a) * 8)
		table.insert(spawns, s)
		wp(s)
	end
	wp(Vector3.new(0, hrpY, 20))
	wp(Vector3.new(-40, hrpY, -12))
	wp(Vector3.new(40, hrpY, -12))
	wp(Vector3.new(-40, hrpY, 16))
	wp(Vector3.new(40, hrpY, 16))
	wp(Vector3.new(0, hrpY, -32))
	wp(Vector3.new(-20, hrpY, 0))
	wp(Vector3.new(20, hrpY, 0))

	city()

	-- Visible spawn disc
	part({
		Name = "SpawnPad",
		Size = Vector3.new(14, 0.3, 14),
		Position = Vector3.new(0, FLOOR_TOP + 0.2, 0),
		Material = Enum.Material.Metal,
		Color = brass,
	})

	World.LobbySpawn = Vector3.new(0, hrpY, 0)
end

World.LobbySpawn = Vector3.new(0, 13.2, 0)

return World
