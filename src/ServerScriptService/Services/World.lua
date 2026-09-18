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

local root: Instance
local waypoints: { Vector3 } = {}
local spawns: { Vector3 } = {}
local tasks: { BasePart } = {}

-- House sits on y=0 ground. Default Studio spawn is here. Nobody can fall through.
local FLOOR_TOP = 1
local HALF_X = 68
local HALF_Z = 52
local WALL_H = 20
local STAND_Y = 5

local function part(props: { [string]: any }, parent: Instance?): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.TopSurface.Smooth
	p.BottomSurface = Enum.BottomSurface.Smooth
	p.CastShadow = true
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent or root
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
	return STAND_Y
end

function World.contains(pos: Vector3): boolean
	return pos.Y > -2 and pos.Y < 45 and math.abs(pos.X) < 250 and math.abs(pos.Z) < 250
end

function World.safe(pos: Vector3): Vector3
	return Vector3.new(
		math.clamp(pos.X, -HALF_X + 10, HALF_X - 10),
		STAND_Y,
		math.clamp(pos.Z, -HALF_Z + 10, HALF_Z - 10)
	)
end

function World.ensureGround()
	local g = workspace:FindFirstChild("HighriseGround")
	if g and g:IsA("BasePart") then
		return g
	end
	return part({
		Name = "HighriseGround",
		Size = Vector3.new(1024, 32, 1024),
		Position = Vector3.new(0, -16, 0),
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(12, 14, 20),
		CastShadow = false,
	}, workspace)
end

-- Marble box that exists even if the rest of build() errors.
function World.ensureShell()
	World.ensureGround()
	local function findPart(name: string): BasePart?
		local a = workspace:FindFirstChild(name)
		if a and a:IsA("BasePart") then
			return a
		end
		local m = workspace:FindFirstChild("HighriseMap")
		if m then
			local b = m:FindFirstChild(name)
			if b and b:IsA("BasePart") then
				return b
			end
		end
		return nil
	end
	local function box(name: string, size: Vector3, pos: Vector3, color: Color3, mat: Enum.Material, trans: number?)
		local existing = findPart(name)
		if existing then
			return existing
		end
		return part({
			Name = name,
			Size = size,
			Position = pos,
			Material = mat,
			Color = color,
			Transparency = trans or 0,
			Locked = true,
		}, workspace)
	end
	box("HR_Floor", Vector3.new(140, 2, 110), Vector3.new(0, 0, 0), marble, Enum.Material.Marble)
	box("HR_Ceiling", Vector3.new(140, 2, 110), Vector3.new(0, 21, 0), ink, Enum.Material.SmoothPlastic)
	box("HR_WallS", Vector3.new(140, 20, 3), Vector3.new(0, 11, -55), ivory, Enum.Material.Marble)
	box("HR_WallN", Vector3.new(140, 20, 2), Vector3.new(0, 11, 54), glassCol, Enum.Material.Glass, 0.35)
	box("HR_WallE", Vector3.new(3, 20, 110), Vector3.new(70, 11, 0), ivory, Enum.Material.Marble)
	box("HR_WallW", Vector3.new(3, 20, 110), Vector3.new(-70, 11, 0), ivory, Enum.Material.Marble)
	if #spawns == 0 then
		for i = 1, 8 do
			local a = (i / 8) * math.pi * 2
			table.insert(spawns, Vector3.new(math.cos(a) * 28, STAND_Y, math.sin(a) * 22))
		end
	end
	World.LobbySpawn = Vector3.new(0, STAND_Y, 0)
end

function World.applyLighting()
	Lighting.ClockTime = 16.5
	Lighting.Brightness = 3.4
	Lighting.Ambient = Color3.fromRGB(120, 110, 115)
	Lighting.OutdoorAmbient = Color3.fromRGB(90, 92, 110)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 196, 140)
	Lighting.ColorShift_Bottom = Color3.fromRGB(48, 56, 96)
	Lighting.FogStart = 250
	Lighting.FogEnd = 1400
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
	-- No dense Atmosphere. That was rendering as a black void in Play Solo.
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
	wp(Vector3.new(pos.X, STAND_Y, pos.Z))
end

local function chandelier(pos: Vector3)
	local bowl = part({
		Size = Vector3.new(6, 0.55, 6),
		Position = pos,
		Material = Enum.Material.Glass,
		Color = gold,
		Transparency = 0.15,
		Shape = Enum.PartType.Ball,
	})
	part({
		Size = Vector3.new(0.35, 6, 0.35),
		Position = pos + Vector3.new(0, 3, 0),
		Material = Enum.Material.Metal,
		Color = brass,
	})
	light(bowl, Color3.fromRGB(255, 220, 170), 5, 36)
end

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
	end
end

local function city()
	local rng = Random.new(80)
	for i = 1, 36 do
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
	World.ensureShell()

	local existing = workspace:FindFirstChild("Highrise")
	if existing then
		existing:Destroy()
	end
	root = Instance.new("Model")
	root.Name = "Highrise"
	root.Parent = workspace
	waypoints = {}
	spawns = {}
	tasks = {}

	part({
		Name = "Floor",
		Size = Vector3.new(HALF_X * 2, 1, HALF_Z * 2),
		Position = Vector3.new(0, FLOOR_TOP - 0.5, 0),
		Material = Enum.Material.Marble,
		Color = marble,
	})
	part({
		Size = Vector3.new(10, 0.2, 70),
		Position = Vector3.new(0, FLOOR_TOP + 0.15, 0),
		Material = Enum.Material.Fabric,
		Color = carpet,
	})

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

	wallDoor(Vector3.new(2, 14, 36), Vector3.new(-30, FLOOR_TOP + 7, -4), 10, false)
	wallDoor(Vector3.new(2, 14, 36), Vector3.new(30, FLOOR_TOP + 7, -4), 10, false)
	wallDoor(Vector3.new(36, 14, 2), Vector3.new(0, FLOOR_TOP + 7, -22), 12, true)

	chandelier(Vector3.new(0, FLOOR_TOP + 14, 0))
	chandelier(Vector3.new(-38, FLOOR_TOP + 14, -12))
	chandelier(Vector3.new(38, FLOOR_TOP + 14, -12))
	chandelier(Vector3.new(0, FLOOR_TOP + 14, 24))
	chandelier(Vector3.new(0, FLOOR_TOP + 14, -32))

	for z = -32, 24, 16 do
		local strip = part({
			Size = Vector3.new(80, 0.2, 0.5),
			Position = Vector3.new(0, FLOOR_TOP + WALL_H - 1.2, z),
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 214, 160),
			CastShadow = false,
		})
		light(strip, Color3.fromRGB(255, 220, 170), 1.8, 24)
	end
	light(part({
		Name = "FillLight",
		Size = Vector3.new(1, 1, 1),
		Position = Vector3.new(0, FLOOR_TOP + 10, 0),
		Transparency = 1,
		CanCollide = false,
		CastShadow = false,
	}), Color3.fromRGB(255, 230, 200), 3.2, 80)

	local pool = part({
		Name = "Pool",
		Size = Vector3.new(28, 0.4, 10),
		Position = Vector3.new(0, FLOOR_TOP + 0.35, 32),
		Material = Enum.Material.Glass,
		Color = water,
		Transparency = 0.3,
		Reflectance = 0.4,
	})
	light(pool, Color3.fromRGB(70, 140, 180), 2.4, 20)
	part({
		Size = Vector3.new(36, 0.3, 14),
		Position = Vector3.new(0, FLOOR_TOP + 0.2, 32),
		Material = Enum.Material.SmoothPlastic,
		Color = stone,
	})

	for i = -1, 1 do
		part({
			Size = Vector3.new(8, 1.4, 3.2),
			Position = Vector3.new(i * 12, FLOOR_TOP + 0.85, 8),
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

	for i = 1, 4 do
		local z = -16 + i * 8
		part({
			Size = Vector3.new(0.3, 6, 4.5),
			Position = Vector3.new(-66.4, FLOOR_TOP + 8, z),
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(20 + i * 12, 16, 28),
		})
	end

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

	for i = -1, 1 do
		part({
			Size = Vector3.new(8, 14, 1),
			Position = Vector3.new(i * 12, FLOOR_TOP + 8, -HALF_Z + 2.2),
			Material = Enum.Material.Metal,
			Color = brass,
		})
	end

	light(part({
		Name = "Sign",
		Size = Vector3.new(28, 3.2, 0.4),
		Position = Vector3.new(0, FLOOR_TOP + 16, HALF_Z - 1.4),
		Material = Enum.Material.Neon,
		Color = gold,
		CanCollide = false,
	}), gold, 3, 32)

	makeTask("Guest book", Vector3.new(-40, FLOOR_TOP + 0.7, -12), brass)
	makeTask("Wine cellar", Vector3.new(46, FLOOR_TOP + 0.7, -18), wine)
	makeTask("Piano", Vector3.new(-46, FLOOR_TOP + 0.7, 16), ivory)
	makeTask("Fuse box", Vector3.new(40, FLOOR_TOP + 0.7, 16), Color3.fromRGB(80, 80, 90))
	makeTask("Vault keypad", Vector3.new(50, FLOOR_TOP + 0.7, -32), gold)

	part({
		Size = Vector3.new(8, 1.8, 3.4),
		Position = Vector3.new(-46, FLOOR_TOP + 1.05, 20),
		Material = Enum.Material.SmoothPlastic,
		Color = ink,
	})

	part({
		Name = "SpawnPad",
		Size = Vector3.new(16, 0.35, 16),
		Position = Vector3.new(0, FLOOR_TOP + 0.2, 0),
		Material = Enum.Material.Metal,
		Color = brass,
	})

	for i = 1, 8 do
		local a = (i / 8) * math.pi * 2
		local s = Vector3.new(math.cos(a) * 28, STAND_Y, math.sin(a) * 22)
		table.insert(spawns, s)
		wp(s)
	end
	wp(Vector3.new(0, STAND_Y, 18))
	wp(Vector3.new(-36, STAND_Y, -10))
	wp(Vector3.new(36, STAND_Y, -10))
	wp(Vector3.new(-36, STAND_Y, 14))
	wp(Vector3.new(36, STAND_Y, 14))
	wp(Vector3.new(0, STAND_Y, -28))
	wp(Vector3.new(-18, STAND_Y, 0))
	wp(Vector3.new(18, STAND_Y, 0))

	city()

	World.LobbySpawn = Vector3.new(0, STAND_Y, 0)
end

World.LobbySpawn = Vector3.new(0, STAND_Y, 0)

return World
