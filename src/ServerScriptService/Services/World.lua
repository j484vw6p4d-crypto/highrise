--!strict
local Lighting = game:GetService("Lighting")

local World = {}

local ivory = Color3.fromRGB(210, 198, 178)
local marble = Color3.fromRGB(186, 170, 148)
local brass = Color3.fromRGB(196, 154, 82)
local ink = Color3.fromRGB(28, 22, 26)
local wine = Color3.fromRGB(120, 28, 40)
local gold = Color3.fromRGB(232, 186, 96)
local carpet = Color3.fromRGB(92, 24, 36)
local wood = Color3.fromRGB(72, 48, 32)

local root: Instance
local waypoints: { Vector3 } = {}
local spawns: { Vector3 } = {}
local tasks: { BasePart } = {}

local HALF = 20
local WALL_H = 14
local STAND_Y = 6

World.LobbySpawn = Vector3.new(0, STAND_Y, 6)

local function part(props: { [string]: any }, parent: Instance?): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.TopSurface.Smooth
	p.BottomSurface = Enum.BottomSurface.Smooth
	p.CastShadow = false
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
	return 1
end

function World.hrpHeight(): number
	return STAND_Y
end

function World.contains(pos: Vector3): boolean
	return pos.Y > 1 and pos.Y < 30 and math.abs(pos.X) < HALF - 1 and math.abs(pos.Z) < HALF - 1
end

function World.safe(pos: Vector3): Vector3
	return Vector3.new(
		math.clamp(pos.X, -HALF + 5, HALF - 5),
		STAND_Y,
		math.clamp(pos.Z, -HALF + 5, HALF - 5)
	)
end

function World.applyLighting()
	Lighting.ClockTime = 17.5
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(90, 80, 78)
	Lighting.OutdoorAmbient = Color3.fromRGB(70, 68, 80)
	Lighting.FogStart = 80
	Lighting.FogEnd = 220
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
	sky.Parent = Lighting
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.04
	cc.Contrast = 0.08
	cc.Saturation = 0.05
	cc.TintColor = Color3.fromRGB(255, 236, 220)
	cc.Parent = Lighting
end

function World.ensureGround() end

function World.ensureShell()
	World.build()
end

function World.build()
	for _, name in ipairs({ "HighriseMap", "Highrise", "HighriseGround" }) do
		local inst = workspace:FindFirstChild(name)
		if inst then
			inst:Destroy()
		end
	end

	root = Instance.new("Model")
	root.Name = "Highrise"
	root.Parent = workspace
	waypoints = {}
	spawns = {}
	tasks = {}

	-- Thin floor. Top face = y=1. Character stands at y=6.
	part({
		Name = "Floor",
		Size = Vector3.new(HALF * 2, 1, HALF * 2),
		CFrame = CFrame.new(0, 0.5, 0),
		Material = Enum.Material.Wood,
		Color = wood,
	})
	part({
		Name = "Carpet",
		Size = Vector3.new(12, 0.2, 24),
		CFrame = CFrame.new(0, 1.1, 0),
		Material = Enum.Material.Fabric,
		Color = carpet,
	})
	part({
		Name = "Ceiling",
		Size = Vector3.new(HALF * 2, 1, HALF * 2),
		CFrame = CFrame.new(0, WALL_H + 0.5, 0),
		Material = Enum.Material.SmoothPlastic,
		Color = ink,
	})
	part({
		Name = "WallS",
		Size = Vector3.new(HALF * 2, WALL_H, 1.5),
		CFrame = CFrame.new(0, WALL_H / 2 + 1, -HALF),
		Material = Enum.Material.Marble,
		Color = ivory,
	})
	part({
		Name = "WallN",
		Size = Vector3.new(HALF * 2, WALL_H, 1.5),
		CFrame = CFrame.new(0, WALL_H / 2 + 1, HALF),
		Material = Enum.Material.Marble,
		Color = ivory,
	})
	part({
		Name = "WallE",
		Size = Vector3.new(1.5, WALL_H, HALF * 2),
		CFrame = CFrame.new(HALF, WALL_H / 2 + 1, 0),
		Material = Enum.Material.Marble,
		Color = ivory,
	})
	part({
		Name = "WallW",
		Size = Vector3.new(1.5, WALL_H, HALF * 2),
		CFrame = CFrame.new(-HALF, WALL_H / 2 + 1, 0),
		Material = Enum.Material.Marble,
		Color = ivory,
	})

	local sign = part({
		Name = "Sign",
		Size = Vector3.new(16, 3, 0.5),
		CFrame = CFrame.new(0, 9, -HALF + 1.2),
		Material = Enum.Material.Neon,
		Color = gold,
		CanCollide = false,
	})
	light(sign, gold, 5, 30)
	local sg = Instance.new("SurfaceGui")
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

	for _, x in ipairs({ -10, 10 }) do
		for _, z in ipairs({ -8, 8 }) do
			part({
				Size = Vector3.new(1.6, WALL_H - 1, 1.6),
				CFrame = CFrame.new(x, WALL_H / 2 + 1, z),
				Material = Enum.Material.Marble,
				Color = ivory,
			})
		end
	end

	for _, pos in ipairs({
		Vector3.new(0, 11, 0),
		Vector3.new(-8, 11, -6),
		Vector3.new(8, 11, -6),
		Vector3.new(-8, 11, 6),
		Vector3.new(8, 11, 6),
	}) do
		local bowl = part({
			Size = Vector3.new(2.4, 0.35, 2.4),
			CFrame = CFrame.new(pos),
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 214, 160),
			CanCollide = false,
		})
		light(bowl, Color3.fromRGB(255, 214, 160), 3, 22)
	end

	part({
		Size = Vector3.new(10, 1.4, 3),
		CFrame = CFrame.new(0, 1.8, 8),
		Material = Enum.Material.Wood,
		Color = wood,
	})
	part({
		Size = Vector3.new(10, 0.25, 3.2),
		CFrame = CFrame.new(0, 2.55, 8),
		Material = Enum.Material.Fabric,
		Color = wine,
	})

	local function addTask(name: string, pos: Vector3, color: Color3)
		local t = part({
			Name = "Task_" .. name,
			Size = Vector3.new(2.6, 1.2, 2.6),
			CFrame = CFrame.new(pos),
			Material = Enum.Material.Metal,
			Color = color,
		})
		light(t, color, 2, 12)
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
	addTask("Guest book", Vector3.new(-12, 1.7, -8), brass)
	addTask("Wine cellar", Vector3.new(12, 1.7, 8), wine)
	addTask("Piano", Vector3.new(-12, 1.7, 8), ivory)
	addTask("Fuse box", Vector3.new(12, 1.7, -8), Color3.fromRGB(90, 90, 100))

	spawns = {
		Vector3.new(10, STAND_Y, 10),
		Vector3.new(-10, STAND_Y, 10),
		Vector3.new(10, STAND_Y, -10),
		Vector3.new(-10, STAND_Y, -10),
		Vector3.new(0, STAND_Y, 12),
		Vector3.new(0, STAND_Y, -10),
	}
	for _, s in ipairs(spawns) do
		wp(s)
	end
	World.LobbySpawn = Vector3.new(0, STAND_Y, 6)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = CFrame.new(0, 1.5, 6)
	spawn.Anchored = true
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Enabled = true
	spawn.Parent = root

	print("[Highrise] Lua room ready.")
end

return World
