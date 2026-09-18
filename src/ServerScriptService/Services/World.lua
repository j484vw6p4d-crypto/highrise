--!strict
local Lighting = game:GetService("Lighting")

local World = {}

local ivory = Color3.fromRGB(236, 228, 214)
local marble = Color3.fromRGB(245, 238, 226)
local brass = Color3.fromRGB(196, 154, 82)
local ink = Color3.fromRGB(22, 18, 24)
local wine = Color3.fromRGB(120, 28, 40)
local gold = Color3.fromRGB(232, 186, 96)
local carpet = Color3.fromRGB(92, 24, 36)
local wood = Color3.fromRGB(72, 48, 32)

local root: Instance
local waypoints: { Vector3 } = {}
local spawns: { Vector3 } = {}
local tasks: { BasePart } = {}

-- Tight room. Walls are 20 studs from spawn so they fill the camera.
local FLOOR_TOP = 1
local HALF = 22
local WALL_H = 16
local STAND_Y = 5

World.LobbySpawn = Vector3.new(0, STAND_Y, 0)

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
	return pos.Y > -4 and pos.Y < 40 and math.abs(pos.X) < HALF + 8 and math.abs(pos.Z) < HALF + 8
end

function World.safe(pos: Vector3): Vector3
	return Vector3.new(
		math.clamp(pos.X, -HALF + 4, HALF - 4),
		STAND_Y,
		math.clamp(pos.Z, -HALF + 4, HALF - 4)
	)
end

function World.applyLighting()
	Lighting.ClockTime = 17
	Lighting.Brightness = 4
	Lighting.Ambient = Color3.fromRGB(140, 128, 120)
	Lighting.OutdoorAmbient = Color3.fromRGB(110, 108, 120)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 210, 160)
	Lighting.ColorShift_Bottom = Color3.fromRGB(80, 70, 90)
	Lighting.FogStart = 200
	Lighting.FogEnd = 800
	Lighting.GlobalShadows = false
	pcall(function()
		Lighting.Technology = Enum.Technology.Compatibility
	end)
	for _, n in ipairs({ "Atmosphere", "ColorCorrection", "Bloom", "DepthOfField", "Sky", "SunRaysEffect" }) do
		local old = Lighting:FindFirstChild(n)
		if old then
			old:Destroy()
		end
	end
	local sky = Instance.new("Sky")
	sky.CelestialBodiesShown = true
	sky.Parent = Lighting
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.12
	cc.Contrast = 0.06
	cc.Saturation = 0.1
	cc.TintColor = Color3.fromRGB(255, 244, 230)
	cc.Parent = Lighting
end

local function makeTask(name: string, pos: Vector3, color: Color3)
	local t = part({
		Name = "Task_" .. name,
		Size = Vector3.new(3, 1.4, 3),
		Position = pos,
		Material = Enum.Material.Metal,
		Color = color,
	})
	light(t, color, 2.4, 14)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Complete"
	prompt.ObjectText = name
	prompt.HoldDuration = 1
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = t
	table.insert(tasks, t)
	wp(Vector3.new(pos.X, STAND_Y, pos.Z))
end

function World.ensureGround()
	-- Intentionally empty. The old 1024-stud dark slab looked like an empty world.
end

function World.ensureShell()
	World.build()
end

function World.build()
	-- Never Destroy HighriseMap while Rojo is connected — it respawns stacked.
	local map = workspace:FindFirstChild("HighriseMap")
	if not (map and map:IsA("Model")) then
		map = Instance.new("Model")
		map.Name = "HighriseMap"
		map.Parent = workspace
	end
	root = map
	waypoints = {}
	spawns = {}
	tasks = {}

	local function box(name: string, size: Vector3, pos: Vector3, color: Color3, mat: Enum.Material): BasePart
		local p = map:FindFirstChild(name)
		if not (p and p:IsA("BasePart")) then
			p = part({ Name = name }, map)
		end
		local b = p :: BasePart
		b.Anchored = true
		b.CanCollide = true
		b.Size = size
		b.CFrame = CFrame.new(pos)
		b.Color = color
		b.Material = mat
		b.Transparency = 0
		b.TopSurface = Enum.TopSurface.Smooth
		b.BottomSurface = Enum.BottomSurface.Smooth
		return b
	end

	box("HR_Floor", Vector3.new(HALF * 2, 2, HALF * 2), Vector3.new(0, 1, 0), marble, Enum.Material.Marble)
	box("HR_Ceiling", Vector3.new(HALF * 2, 2, HALF * 2), Vector3.new(0, WALL_H, 0), ink, Enum.Material.SmoothPlastic)
	box("HR_WallS", Vector3.new(HALF * 2, WALL_H, 2), Vector3.new(0, WALL_H / 2 + 1, -HALF), ivory, Enum.Material.Marble)
	box("HR_WallN", Vector3.new(HALF * 2, WALL_H, 2), Vector3.new(0, WALL_H / 2 + 1, HALF), ivory, Enum.Material.Marble)
	box("HR_WallE", Vector3.new(2, WALL_H, HALF * 2), Vector3.new(HALF, WALL_H / 2 + 1, 0), ivory, Enum.Material.Marble)
	box("HR_WallW", Vector3.new(2, WALL_H, HALF * 2), Vector3.new(-HALF, WALL_H / 2 + 1, 0), ivory, Enum.Material.Marble)
	local sign = box("HR_Sign", Vector3.new(16, 3, 0.6), Vector3.new(0, 10, -HALF + 1.4), gold, Enum.Material.Neon)
	sign.CanCollide = false
	light(sign, gold, 4, 28)
	if not sign:FindFirstChild("SignGui") then
		local sg = Instance.new("SurfaceGui")
		sg.Name = "SignGui"
		sg.Face = Enum.NormalId.Back
		sg.Parent = sign
		local lab = Instance.new("TextLabel")
		lab.BackgroundTransparency = 1
		lab.Size = UDim2.fromScale(1, 1)
		lab.Font = Enum.Font.GothamBlack
		lab.Text = "HIGHRISE"
		lab.TextColor3 = ink
		lab.TextScaled = true
		lab.Parent = sg
	end

	for _, ch in ipairs(map:GetChildren()) do
		if ch:GetAttribute("HRFurn") then
			ch:Destroy()
		end
	end

	local function furn(props: { [string]: any }): BasePart
		local p = part(props, map)
		p:SetAttribute("HRFurn", true)
		return p
	end

	furn({
		Name = "Carpet",
		Size = Vector3.new(10, 0.25, 28),
		Position = Vector3.new(0, 2.15, 0),
		Material = Enum.Material.Fabric,
		Color = carpet,
	})
	for _, x in ipairs({ -14, 14 }) do
		for _, z in ipairs({ -12, 12 }) do
			furn({
				Size = Vector3.new(2, WALL_H - 2, 2),
				Position = Vector3.new(x, WALL_H / 2, z),
				Material = Enum.Material.Marble,
				Color = ivory,
			})
		end
	end
	for _, pos in ipairs({
		Vector3.new(0, 12, 0),
		Vector3.new(-10, 12, -8),
		Vector3.new(10, 12, -8),
		Vector3.new(-10, 12, 8),
		Vector3.new(10, 12, 8),
	}) do
		local bowl = furn({
			Size = Vector3.new(3, 0.4, 3),
			Position = pos,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 220, 170),
			CanCollide = false,
		})
		light(bowl, Color3.fromRGB(255, 220, 170), 3.5, 24)
	end
	furn({
		Size = Vector3.new(10, 1.2, 3.2),
		Position = Vector3.new(0, 2.7, 8),
		Material = Enum.Material.Wood,
		Color = wood,
	})

	local function addTask(name: string, pos: Vector3, color: Color3)
		local t = furn({
			Name = "Task_" .. name,
			Size = Vector3.new(3, 1.4, 3),
			Position = pos,
			Material = Enum.Material.Metal,
			Color = color,
		})
		light(t, color, 2.4, 14)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Complete"
		prompt.ObjectText = name
		prompt.HoldDuration = 1
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = t
		table.insert(tasks, t)
		wp(Vector3.new(pos.X, STAND_Y, pos.Z))
	end
	addTask("Guest book", Vector3.new(-14, 2.8, -8), brass)
	addTask("Wine cellar", Vector3.new(14, 2.8, 8), wine)
	addTask("Piano", Vector3.new(-14, 2.8, 8), ivory)
	addTask("Fuse box", Vector3.new(14, 2.8, -8), Color3.fromRGB(90, 90, 100))

	spawns = {
		Vector3.new(12, STAND_Y, 12),
		Vector3.new(-12, STAND_Y, 12),
		Vector3.new(12, STAND_Y, -12),
		Vector3.new(-12, STAND_Y, -12),
		Vector3.new(0, STAND_Y, 14),
		Vector3.new(0, STAND_Y, -14),
	}
	for _, s in ipairs(spawns) do
		wp(s)
	end
	World.LobbySpawn = Vector3.new(0, STAND_Y, 4)

	local spawnInst = map:FindFirstChild("LobbySpawn")
	if not (spawnInst and spawnInst:IsA("SpawnLocation")) then
		spawnInst = Instance.new("SpawnLocation")
		spawnInst.Name = "LobbySpawn"
		spawnInst.Parent = map
	end
	local sp = spawnInst :: SpawnLocation
	sp.Size = Vector3.new(8, 1, 8)
	sp.CFrame = CFrame.new(0, 2.5, 4)
	sp.Anchored = true
	sp.Transparency = 1
	sp.CanCollide = true
	sp.Neutral = true
	sp.Duration = 0
	sp.Enabled = true

	print("[Highrise] Room posed around spawn.")
end

return World
