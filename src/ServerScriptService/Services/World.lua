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

local root: Instance
local waypoints: { Vector3 } = {}
local spawns: { Vector3 } = {}
local tasks: { BasePart } = {}

local STAND = 8
World.LobbySpawn = Vector3.new(0, STAND, 58)

local function box(name: string, size: Vector3, pos: Vector3, color: Color3, mat: Enum.Material, parent: Instance): BasePart
	local p = parent:FindFirstChild(name)
	if not (p and p:IsA("BasePart")) then
		p = Instance.new("Part")
		p.Name = name
		p.Parent = parent
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
	return pos.Y > 3 and pos.Y < 36 and math.abs(pos.X) < 55 and pos.Z > -30 and pos.Z < 110
end

function World.safe(pos: Vector3): Vector3
	return Vector3.new(math.clamp(pos.X, -18, 18), STAND, math.clamp(pos.Z, -18, 70))
end

function World.applyLighting()
	Lighting.ClockTime = 17.4
	Lighting.Brightness = 2.6
	Lighting.Ambient = Color3.fromRGB(80, 72, 70)
	Lighting.OutdoorAmbient = Color3.fromRGB(70, 68, 82)
	Lighting.FogStart = 90
	Lighting.FogEnd = 280
	Lighting.GlobalShadows = false
	pcall(function()
		Lighting.Technology = Enum.Technology.Compatibility
	end)
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
		map = Instance.new("Model")
		map.Name = "Highrise"
		map.Parent = workspace
	end
	root = map
	waypoints = {}
	spawns = {}
	tasks = {}

	-- Giant catch so you cannot fall even if Rojo stacks parts.
	box("Catch", Vector3.new(240, 8, 260), Vector3.new(0, 0, 40), Color3.fromRGB(48, 44, 40), Enum.Material.Slate, map)

	-- Outdoor lobby plaza in front of the mansion (look toward -Z at the facade).
	box("Plaza", Vector3.new(72, 2, 56), Vector3.new(0, 5, 52), stone, Enum.Material.Cobblestone, map)
	box("Path", Vector3.new(10, 0.4, 28), Vector3.new(0, 6.2, 38), carpet, Enum.Material.Fabric, map)
	local fountain = box("Fountain", Vector3.new(8, 2, 8), Vector3.new(0, 7, 62), brass, Enum.Material.Metal, map)
	light(fountain, gold, 3, 24)
	box("FountainTop", Vector3.new(3, 4, 3), Vector3.new(0, 10, 62), gold, Enum.Material.Neon, map)

	for _, x in ipairs({ -28, 28 }) do
		for _, z in ipairs({ 40, 64 }) do
			local lamp = box("Lamp_" .. x .. "_" .. z, Vector3.new(0.6, 12, 0.6), Vector3.new(x, 12, z), ink, Enum.Material.Metal, map)
			light(lamp, Color3.fromRGB(255, 210, 150), 2.5, 20)
		end
	end

	-- Street in front of the plaza
	box("Street", Vector3.new(90, 1, 28), Vector3.new(0, 5.1, 78), Color3.fromRGB(28, 28, 32), Enum.Material.Asphalt, map)
	box("CurbL", Vector3.new(2, 1.2, 28), Vector3.new(-44, 5.7, 78), stone, Enum.Material.Slate, map)
	box("CurbR", Vector3.new(2, 1.2, 28), Vector3.new(44, 5.7, 78), stone, Enum.Material.Slate, map)
	box("FarShopA", Vector3.new(22, 14, 8), Vector3.new(-22, 13, 94), Color3.fromRGB(48, 36, 40), Enum.Material.Brick, map)
	box("FarShopB", Vector3.new(22, 14, 8), Vector3.new(22, 13, 94), Color3.fromRGB(36, 40, 52), Enum.Material.Brick, map)
	local night = box("NightSign", Vector3.new(18, 3, 0.5), Vector3.new(0, 16, 90), gold, Enum.Material.Neon, map)
	night.CanCollide = false
	light(night, gold, 4, 28)
	if not night:FindFirstChild("SignGui") then
		local ng = Instance.new("SurfaceGui")
		ng.Name = "SignGui"
		ng.Face = Enum.NormalId.Back
		ng.Parent = night
		local nlab = Instance.new("TextLabel")
		nlab.BackgroundTransparency = 1
		nlab.Size = UDim2.fromScale(1, 1)
		nlab.Font = Enum.Font.GothamBlack
		nlab.Text = "80TH STREET"
		nlab.TextColor3 = ink
		nlab.TextScaled = true
		nlab.Parent = ng
	end

	-- Atelier shop
	box("ShopFloor", Vector3.new(16, 1, 14), Vector3.new(26, 6.2, 50), wood, Enum.Material.Wood, map)
	box("ShopAwning", Vector3.new(16, 0.5, 14), Vector3.new(26, 13, 50), wine, Enum.Material.Fabric, map)
	box("ShopPostA", Vector3.new(0.7, 7, 0.7), Vector3.new(19, 9.5, 44), brass, Enum.Material.Metal, map)
	box("ShopPostB", Vector3.new(0.7, 7, 0.7), Vector3.new(33, 9.5, 44), brass, Enum.Material.Metal, map)
	box("ShopCounter", Vector3.new(10, 3, 2), Vector3.new(26, 7.6, 46), wood, Enum.Material.Wood, map)
	local shopSign = box("ShopSign", Vector3.new(10, 2.2, 0.4), Vector3.new(26, 14.2, 44), gold, Enum.Material.Neon, map)
	shopSign.CanCollide = false
	light(shopSign, gold, 3, 18)
	if not shopSign:FindFirstChild("SignGui") then
		local sgui = Instance.new("SurfaceGui")
		sgui.Name = "SignGui"
		sgui.Face = Enum.NormalId.Back
		sgui.Parent = shopSign
		local slab = Instance.new("TextLabel")
		slab.BackgroundTransparency = 1
		slab.Size = UDim2.fromScale(1, 1)
		slab.Font = Enum.Font.GothamBlack
		slab.Text = "ATELIER"
		slab.TextColor3 = ink
		slab.TextScaled = true
		slab.Parent = sgui
	end
	local clerk = box("ShopClerk", Vector3.new(2, 4, 1), Vector3.new(26, 8.4, 52), Color3.fromRGB(16, 16, 18), Enum.Material.SmoothPlastic, map)
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

	local bw = box("BoardWins", Vector3.new(0.6, 16, 12), Vector3.new(-38, 14, 42), ink, Enum.Material.SmoothPlastic, map)
	bw.CFrame = CFrame.new(-38, 14, 42) * CFrame.Angles(0, math.rad(90), 0)
	local bk = box("BoardKills", Vector3.new(0.6, 16, 12), Vector3.new(-38, 14, 58), ink, Enum.Material.SmoothPlastic, map)
	bk.CFrame = CFrame.new(-38, 14, 58) * CFrame.Angles(0, math.rad(90), 0)
	local br = box("BoardRobux", Vector3.new(0.6, 16, 12), Vector3.new(38, 14, 42), ink, Enum.Material.SmoothPlastic, map)
	br.CFrame = CFrame.new(38, 14, 42) * CFrame.Angles(0, math.rad(-90), 0)
	box("PodiumWins", Vector3.new(4, 1, 4), Vector3.new(-34, 6.6, 42), gold, Enum.Material.Metal, map)
	box("PodiumKills", Vector3.new(4, 1, 4), Vector3.new(-34, 6.6, 58), Color3.fromRGB(220, 80, 90), Enum.Material.Metal, map)
	box("PodiumRobux", Vector3.new(4, 1, 4), Vector3.new(34, 6.6, 42), Color3.fromRGB(120, 220, 140), Enum.Material.Metal, map)

	-- Mansion interior
	box("InteriorFloor", Vector3.new(48, 2, 48), Vector3.new(0, 5, 0), wood, Enum.Material.Wood, map)
	box("CarpetIn", Vector3.new(10, 0.25, 30), Vector3.new(0, 6.15, 0), carpet, Enum.Material.Fabric, map)
	box("Ceiling", Vector3.new(48, 2, 48), Vector3.new(0, 20, 0), ink, Enum.Material.SmoothPlastic, map)
	box("WallS", Vector3.new(48, 16, 2), Vector3.new(0, 13, -24), ivory, Enum.Material.Marble, map)
	box("WallN", Vector3.new(48, 16, 2), Vector3.new(0, 13, 24), ivory, Enum.Material.Marble, map)
	box("WallE", Vector3.new(2, 16, 48), Vector3.new(24, 13, 0), ivory, Enum.Material.Marble, map)
	box("WallW", Vector3.new(2, 16, 48), Vector3.new(-24, 13, 0), ivory, Enum.Material.Marble, map)

	-- Door hole: thin dark opening in the north wall facing the plaza
	local door = box("Doorway", Vector3.new(8, 10, 2.4), Vector3.new(0, 11, 24), Color3.fromRGB(18, 14, 16), Enum.Material.SmoothPlastic, map)
	door.CanCollide = false
	door.Transparency = 0.35

	-- Facade above/around the door, facing the plaza
	box("Facade", Vector3.new(52, 22, 3), Vector3.new(0, 16, 26.5), ivory, Enum.Material.Marble, map)
	local sign = box("Sign", Vector3.new(20, 4, 0.6), Vector3.new(0, 18, 28.2), gold, Enum.Material.Neon, map)
	sign.CanCollide = false
	light(sign, gold, 5, 32)
	if not sign:FindFirstChild("SignGui") then
		local sg = Instance.new("SurfaceGui")
		sg.Name = "SignGui"
		sg.Face = Enum.NormalId.Front
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

	-- Clear old tasks then place new
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
	table.insert(waypoints, Vector3.new(0, STAND, 58))
	table.insert(waypoints, Vector3.new(0, STAND, 40))
	table.insert(waypoints, Vector3.new(26, STAND, 48))
	table.insert(waypoints, Vector3.new(-20, STAND, 50))
	table.insert(waypoints, Vector3.new(0, STAND, 78))
	World.LobbySpawn = Vector3.new(0, STAND, 58)

	local spawnInst = map:FindFirstChild("LobbySpawn")
	if not (spawnInst and spawnInst:IsA("SpawnLocation")) then
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

	print("[Highrise] Plaza + mansion ready.")
end

return World
