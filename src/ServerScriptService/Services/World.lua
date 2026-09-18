--!strict
local Lighting = game:GetService("Lighting")

local World = {}

local ivory = Color3.fromRGB(210, 198, 178)
local brass = Color3.fromRGB(196, 154, 82)
local ink = Color3.fromRGB(28, 22, 26)
local wine = Color3.fromRGB(120, 28, 40)
local gold = Color3.fromRGB(232, 186, 96)
local carpet = Color3.fromRGB(92, 24, 36)
local wood = Color3.fromRGB(72, 48, 32)
local stone = Color3.fromRGB(140, 128, 114)

local waypoints: { Vector3 } = {}
local spawns: { Vector3 } = {}
local tasks: { BasePart } = {}

local STAND = 8
World.LobbySpawn = Vector3.new(0, STAND, 58)

local function box(name: string, size: Vector3, pos: Vector3, color: Color3, mat: Enum.Material, parent: Instance): BasePart
	local existing = parent:FindFirstChild(name)
	local p: BasePart
	if existing and existing:IsA("BasePart") then
		p = existing
	else
		if existing then
			existing:Destroy()
		end
		local n = Instance.new("Part")
		n.Name = name
		n.Parent = parent
		p = n
	end
	p.Anchored = true
	p.CanCollide = true
	p.Size = size
	p.CFrame = CFrame.new(pos)
	p.Color = color
	p.Material = mat
	p.Transparency = 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local function light(parent: BasePart, color: Color3, brightness: number, range: number)
	if parent:FindFirstChildOfClass("PointLight") then
		return
	end
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Shadows = false
	l.Parent = parent
end

local function labelPart(part: BasePart, text: string, face: Enum.NormalId)
	if part:FindFirstChild("SignGui") then
		return
	end
	local sg = Instance.new("SurfaceGui")
	sg.Name = "SignGui"
	sg.Face = face
	sg.Parent = part
	local lab = Instance.new("TextLabel")
	lab.BackgroundTransparency = 1
	lab.Size = UDim2.fromScale(1, 1)
	lab.Font = Enum.Font.GothamBlack
	lab.Text = text
	lab.TextColor3 = ink
	lab.TextScaled = true
	lab.Parent = sg
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
	return 6
end

function World.hrpHeight(): number
	return STAND
end

function World.contains(pos: Vector3): boolean
	return pos.Y > 3 and pos.Y < 40 and math.abs(pos.X) < 70 and pos.Z > -40 and pos.Z < 120
end

function World.safe(pos: Vector3): Vector3
	return Vector3.new(math.clamp(pos.X, -20, 20), STAND, math.clamp(pos.Z, -18, 80))
end

function World.applyLighting()
	Lighting.ClockTime = 17.4
	Lighting.Brightness = 2.6
	Lighting.Ambient = Color3.fromRGB(80, 72, 70)
	Lighting.OutdoorAmbient = Color3.fromRGB(70, 68, 82)
	Lighting.FogStart = 90
	Lighting.FogEnd = 280
	Lighting.GlobalShadows = false
	for _, n in ipairs({ "Atmosphere", "ColorCorrection", "Bloom", "Sky" }) do
		local old = Lighting:FindFirstChild(n)
		if old then
			old:Destroy()
		end
	end
	Instance.new("Sky").Parent = Lighting
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.04
	cc.Contrast = 0.08
	cc.Saturation = 0.06
	cc.TintColor = Color3.fromRGB(255, 236, 220)
	cc.Parent = Lighting
end

function World.ensureGround() end
function World.ensureShell()
	World.build()
end

function World.build()
	local map = workspace:FindFirstChild("Highrise")
	if not (map and map:IsA("Model")) then
		if map then
			map:Destroy()
		end
		local m = Instance.new("Model")
		m.Name = "Highrise"
		m.Parent = workspace
		map = m
	end

	waypoints = {}
	spawns = {}
	tasks = {}

	box("Catch", Vector3.new(280, 8, 300), Vector3.new(0, 0, 40), Color3.fromRGB(48, 44, 40), Enum.Material.Slate, map)

	box("Plaza", Vector3.new(80, 2, 60), Vector3.new(0, 5, 54), stone, Enum.Material.Cobblestone, map)
	box("Path", Vector3.new(10, 0.4, 32), Vector3.new(0, 6.2, 40), carpet, Enum.Material.Fabric, map)
	box("Steps", Vector3.new(10, 1.2, 6), Vector3.new(0, 6.2, 26), ivory, Enum.Material.Marble, map)

	local fountain = box("Fountain", Vector3.new(8, 2, 8), Vector3.new(0, 7, 64), brass, Enum.Material.Metal, map)
	light(fountain, gold, 3, 24)
	box("FountainTop", Vector3.new(3, 4, 3), Vector3.new(0, 10, 64), gold, Enum.Material.Neon, map)

	for _, x in ipairs({ -30, 30 }) do
		for _, z in ipairs({ 40, 68 }) do
			local lamp = box("Lamp_" .. x .. "_" .. z, Vector3.new(0.6, 12, 0.6), Vector3.new(x, 12, z), ink, Enum.Material.Metal, map)
			light(lamp, Color3.fromRGB(255, 210, 150), 2.5, 20)
		end
	end

	box("Street", Vector3.new(96, 1, 30), Vector3.new(0, 5.1, 82), Color3.fromRGB(28, 28, 32), Enum.Material.Asphalt, map)
	box("CurbL", Vector3.new(2, 1.2, 30), Vector3.new(-47, 5.7, 82), stone, Enum.Material.Slate, map)
	box("CurbR", Vector3.new(2, 1.2, 30), Vector3.new(47, 5.7, 82), stone, Enum.Material.Slate, map)
	box("FarShopA", Vector3.new(24, 14, 8), Vector3.new(-24, 13, 98), Color3.fromRGB(48, 36, 40), Enum.Material.Brick, map)
	box("FarShopB", Vector3.new(24, 14, 8), Vector3.new(24, 13, 98), Color3.fromRGB(36, 40, 52), Enum.Material.Brick, map)
	local night = box("NightSign", Vector3.new(20, 3, 0.5), Vector3.new(0, 16, 94), gold, Enum.Material.Neon, map)
	night.CanCollide = false
	light(night, gold, 4, 28)
	labelPart(night, "80TH STREET", Enum.NormalId.Back)

	box("ShopFloor", Vector3.new(16, 1, 14), Vector3.new(28, 6.2, 50), wood, Enum.Material.Wood, map)
	box("ShopAwning", Vector3.new(16, 0.5, 14), Vector3.new(28, 13, 50), wine, Enum.Material.Fabric, map)
	box("ShopPostA", Vector3.new(0.7, 7, 0.7), Vector3.new(21, 9.5, 44), brass, Enum.Material.Metal, map)
	box("ShopPostB", Vector3.new(0.7, 7, 0.7), Vector3.new(35, 9.5, 44), brass, Enum.Material.Metal, map)
	box("ShopCounter", Vector3.new(10, 3, 2), Vector3.new(28, 7.6, 46), wood, Enum.Material.Wood, map)
	local shopSign = box("ShopSign", Vector3.new(10, 2.2, 0.4), Vector3.new(28, 14.2, 44), gold, Enum.Material.Neon, map)
	shopSign.CanCollide = false
	light(shopSign, gold, 3, 18)
	labelPart(shopSign, "ATELIER", Enum.NormalId.Back)
	local clerk = box("ShopClerk", Vector3.new(2, 4, 1), Vector3.new(28, 8.4, 52), Color3.fromRGB(16, 16, 18), Enum.Material.SmoothPlastic, map)
	clerk.CanCollide = false
	if not clerk:FindFirstChild("OpenShop") then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "OpenShop"
		prompt.ActionText = "Open shop"
		prompt.ObjectText = "Atelier"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = clerk
	end

	local bw = box("BoardWins", Vector3.new(0.6, 16, 12), Vector3.new(-40, 14, 42), ink, Enum.Material.SmoothPlastic, map)
	bw.CFrame = CFrame.new(-40, 14, 42) * CFrame.Angles(0, math.rad(90), 0)
	local bk = box("BoardKills", Vector3.new(0.6, 16, 12), Vector3.new(-40, 14, 58), ink, Enum.Material.SmoothPlastic, map)
	bk.CFrame = CFrame.new(-40, 14, 58) * CFrame.Angles(0, math.rad(90), 0)
	local br = box("BoardRobux", Vector3.new(0.6, 16, 12), Vector3.new(40, 14, 42), ink, Enum.Material.SmoothPlastic, map)
	br.CFrame = CFrame.new(40, 14, 42) * CFrame.Angles(0, math.rad(-90), 0)
	box("PodiumWins", Vector3.new(4, 1, 4), Vector3.new(-36, 6.6, 42), gold, Enum.Material.Metal, map)
	box("PodiumKills", Vector3.new(4, 1, 4), Vector3.new(-36, 6.6, 58), Color3.fromRGB(220, 80, 90), Enum.Material.Metal, map)
	box("PodiumRobux", Vector3.new(4, 1, 4), Vector3.new(36, 6.6, 42), Color3.fromRGB(120, 220, 140), Enum.Material.Metal, map)

	box("InteriorFloor", Vector3.new(48, 2, 48), Vector3.new(0, 5, 0), wood, Enum.Material.Wood, map)
	box("CarpetIn", Vector3.new(10, 0.25, 30), Vector3.new(0, 6.15, 0), carpet, Enum.Material.Fabric, map)
	box("Ceiling", Vector3.new(48, 2, 48), Vector3.new(0, 20, 0), ink, Enum.Material.SmoothPlastic, map)
	box("WallS", Vector3.new(48, 16, 2), Vector3.new(0, 13, -24), ivory, Enum.Material.Marble, map)
	box("WallE", Vector3.new(2, 16, 48), Vector3.new(24, 13, 0), ivory, Enum.Material.Marble, map)
	box("WallW", Vector3.new(2, 16, 48), Vector3.new(-24, 13, 0), ivory, Enum.Material.Marble, map)
	box("WallN_L", Vector3.new(18, 16, 2), Vector3.new(-15, 13, 24), ivory, Enum.Material.Marble, map)
	box("WallN_R", Vector3.new(18, 16, 2), Vector3.new(15, 13, 24), ivory, Enum.Material.Marble, map)
	box("WallN_Top", Vector3.new(12, 6, 2), Vector3.new(0, 18, 24), ivory, Enum.Material.Marble, map)

	box("FacadeL", Vector3.new(20, 22, 3), Vector3.new(-16, 16, 27), ivory, Enum.Material.Marble, map)
	box("FacadeR", Vector3.new(20, 22, 3), Vector3.new(16, 16, 27), ivory, Enum.Material.Marble, map)
	box("FacadeTop", Vector3.new(12, 8, 3), Vector3.new(0, 23, 27), ivory, Enum.Material.Marble, map)
	local sign = box("Sign", Vector3.new(20, 4, 0.6), Vector3.new(0, 22, 29), gold, Enum.Material.Neon, map)
	sign.CanCollide = false
	light(sign, gold, 5, 32)
	labelPart(sign, "HIGHRISE", Enum.NormalId.Front)

	for _, x in ipairs({ -14, 14 }) do
		for _, z in ipairs({ -10, 10 }) do
			box("Pillar_" .. x .. "_" .. z, Vector3.new(2, 14, 2), Vector3.new(x, 13, z), ivory, Enum.Material.Marble, map)
		end
	end

	for _, pos in ipairs({
		Vector3.new(0, 16, 0),
		Vector3.new(-12, 16, -8),
		Vector3.new(12, 16, -8),
		Vector3.new(-12, 16, 8),
		Vector3.new(12, 16, 8),
	}) do
		local bowl = box("Light_" .. tostring(pos), Vector3.new(2.4, 0.35, 2.4), pos, Color3.fromRGB(255, 214, 160), Enum.Material.Neon, map)
		bowl.CanCollide = false
		light(bowl, Color3.fromRGB(255, 214, 160), 3, 20)
	end

	box("Sofa", Vector3.new(10, 1.4, 3), Vector3.new(0, 6.8, -12), wood, Enum.Material.Wood, map)
	box("SofaTop", Vector3.new(10, 0.3, 3.2), Vector3.new(0, 7.6, -12), wine, Enum.Material.Fabric, map)

	for _, ch in ipairs(map:GetChildren()) do
		if string.sub(ch.Name, 1, 5) == "Task_" then
			ch:Destroy()
		end
	end
	local function addTask(name: string, pos: Vector3, color: Color3)
		local t = box("Task_" .. name, Vector3.new(2.6, 1.2, 2.6), pos, color, Enum.Material.Metal, map)
		light(t, color, 2, 12)
		if not t:FindFirstChildOfClass("ProximityPrompt") then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Complete"
			prompt.ObjectText = name
			prompt.HoldDuration = 1
			prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false
			prompt.Parent = t
		end
		table.insert(tasks, t)
		table.insert(waypoints, Vector3.new(pos.X, STAND, pos.Z))
	end
	addTask("Guest book", Vector3.new(-16, 6.7, -8), brass)
	addTask("Wine cellar", Vector3.new(16, 6.7, 8), wine)
	addTask("Piano", Vector3.new(-16, 6.7, 8), ivory)
	addTask("Fuse box", Vector3.new(16, 6.7, -8), Color3.fromRGB(90, 90, 100))

	spawns = {
		Vector3.new(14, STAND, 14),
		Vector3.new(-14, STAND, 14),
		Vector3.new(14, STAND, -14),
		Vector3.new(-14, STAND, -14),
		Vector3.new(0, STAND, 12),
		Vector3.new(0, STAND, -12),
	}
	for _, s in ipairs(spawns) do
		table.insert(waypoints, s)
	end
	World.LobbySpawn = Vector3.new(0, STAND, 58)

	local spawnInst = map:FindFirstChild("LobbySpawn")
	if not (spawnInst and spawnInst:IsA("SpawnLocation")) then
		if spawnInst then
			spawnInst:Destroy()
		end
		spawnInst = Instance.new("SpawnLocation")
		spawnInst.Name = "LobbySpawn"
		spawnInst.Parent = map
	end
	local sp = spawnInst :: SpawnLocation
	sp.Size = Vector3.new(12, 1, 12)
	sp.CFrame = CFrame.new(0, 6.5, 58)
	sp.Anchored = true
	sp.Transparency = 1
	sp.CanCollide = true
	sp.Neutral = true
	sp.Duration = 0
	sp.Enabled = true

	print("[Highrise] HR-14 plaza + mansion ready")
end

return World
