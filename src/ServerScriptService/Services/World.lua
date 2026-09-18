--!nocheck
local Lighting = game:GetService("Lighting")

local World = {}

local ivory = Color3.fromRGB(196, 180, 158)
local brass = Color3.fromRGB(176, 138, 72)
local ink = Color3.fromRGB(18, 14, 16)
local wine = Color3.fromRGB(92, 22, 32)
local gold = Color3.fromRGB(214, 168, 88)
local carpet = Color3.fromRGB(72, 18, 28)
local wood = Color3.fromRGB(58, 38, 26)
local stone = Color3.fromRGB(118, 108, 96)
local plaster = Color3.fromRGB(168, 156, 138)
local dark = Color3.fromRGB(28, 24, 22)

local waypoints = {}
local spawns = {}
local tasks = {}
local STAND = 8
World.LobbySpawn = Vector3.new(0, STAND, 62)

local function box(name, size, pos, color, mat, parent)
	local existing = parent:FindFirstChild(name)
	local p
	if existing and existing:IsA("BasePart") then
		p = existing
	else
		if existing then
			existing:Destroy()
		end
		p = Instance.new("Part")
		p.Name = name
		p.Parent = parent
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

local function light(parent, color, brightness, range)
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

local function labelPart(part, text, face)
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
	lab.Font = Enum.Font.GothamBold
	lab.Text = text
	lab.TextColor3 = Color3.fromRGB(236, 224, 200)
	lab.TextScaled = true
	lab.Parent = sg
end

local function roomShell(id, cx, cz, sx, sz, parent, wallColor)
	local y = 5
	local h = 16
	box(id .. "_Floor", Vector3.new(sx, 2, sz), Vector3.new(cx, y, cz), wood, Enum.Material.Wood, parent)
	box(id .. "_Ceil", Vector3.new(sx, 1.4, sz), Vector3.new(cx, y + h, cz), dark, Enum.Material.SmoothPlastic, parent)
	box(id .. "_Carpet", Vector3.new(sx - 8, 0.2, sz - 8), Vector3.new(cx, y + 1.12, cz), carpet, Enum.Material.Fabric, parent)
	local lamp = box(id .. "_Lamp", Vector3.new(3, 0.4, 3), Vector3.new(cx, y + h - 1.2, cz), Color3.fromRGB(255, 210, 150), Enum.Material.Neon, parent)
	lamp.CanCollide = false
	light(lamp, Color3.fromRGB(255, 200, 140), 1.6, 28)
	return y
end

function World.waypoints()
	return waypoints
end
function World.spawns()
	return spawns
end
function World.tasks()
	return tasks
end
function World.floorY()
	return 6
end
function World.hrpHeight()
	return STAND
end
function World.contains(pos)
	return pos.Y > 3 and pos.Y < 42 and math.abs(pos.X) < 110 and pos.Z > -90 and pos.Z < 130
end
function World.safe(pos)
	return Vector3.new(math.clamp(pos.X, -70, 70), STAND, math.clamp(pos.Z, -70, 80))
end

function World.applyLighting()
	Lighting.ClockTime = 20.2
	Lighting.Brightness = 1.4
	Lighting.Ambient = Color3.fromRGB(42, 36, 34)
	Lighting.OutdoorAmbient = Color3.fromRGB(36, 34, 40)
	Lighting.FogColor = Color3.fromRGB(18, 14, 16)
	Lighting.FogStart = 40
	Lighting.FogEnd = 160
	Lighting.GlobalShadows = false
	for _, n in ipairs({ "Atmosphere", "ColorCorrection", "Bloom", "Sky" }) do
		local old = Lighting:FindFirstChild(n)
		if old then
			old:Destroy()
		end
	end
	Instance.new("Sky").Parent = Lighting
	local atm = Instance.new("Atmosphere")
	atm.Density = 0.38
	atm.Offset = 0.12
	atm.Color = Color3.fromRGB(40, 32, 28)
	atm.Decay = Color3.fromRGB(10, 8, 8)
	atm.Haze = 1.4
	atm.Parent = Lighting
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = -0.04
	cc.Contrast = 0.12
	cc.Saturation = -0.08
	cc.TintColor = Color3.fromRGB(255, 230, 210)
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
		map = Instance.new("Model")
		map.Name = "Highrise"
		map.Parent = workspace
	end

	waypoints = {}
	spawns = {}
	tasks = {}

	box("Catch", Vector3.new(360, 8, 360), Vector3.new(0, 0, 10), Color3.fromRGB(22, 20, 18), Enum.Material.Slate, map)

	-- STREET LOBBY
	box("Plaza", Vector3.new(90, 2, 64), Vector3.new(0, 5, 58), stone, Enum.Material.Cobblestone, map)
	box("Path", Vector3.new(12, 0.4, 36), Vector3.new(0, 6.2, 42), carpet, Enum.Material.Fabric, map)
	box("Steps", Vector3.new(12, 1.4, 8), Vector3.new(0, 6.3, 24), ivory, Enum.Material.Marble, map)
	local fountain = box("Fountain", Vector3.new(10, 2.2, 10), Vector3.new(0, 7.1, 68), brass, Enum.Material.Metal, map)
	light(fountain, gold, 2.4, 26)
	box("FountainTop", Vector3.new(3.2, 5, 3.2), Vector3.new(0, 10.4, 68), gold, Enum.Material.Neon, map)
	box("Street", Vector3.new(110, 1, 32), Vector3.new(0, 5.1, 88), Color3.fromRGB(22, 22, 26), Enum.Material.Asphalt, map)
	box("CurbL", Vector3.new(2, 1.4, 32), Vector3.new(-54, 5.8, 88), stone, Enum.Material.Slate, map)
	box("CurbR", Vector3.new(2, 1.4, 32), Vector3.new(54, 5.8, 88), stone, Enum.Material.Slate, map)
	for _, x in ipairs({ -34, 34 }) do
		for _, z in ipairs({ 44, 72 }) do
			local lamp = box("Lamp_" .. x .. "_" .. z, Vector3.new(0.7, 14, 0.7), Vector3.new(x, 13, z), ink, Enum.Material.Metal, map)
			light(lamp, Color3.fromRGB(255, 186, 120), 2.2, 22)
		end
	end
	box("FarShopA", Vector3.new(26, 16, 10), Vector3.new(-28, 14, 104), Color3.fromRGB(42, 30, 32), Enum.Material.Brick, map)
	box("FarShopB", Vector3.new(26, 16, 10), Vector3.new(28, 14, 104), Color3.fromRGB(30, 34, 46), Enum.Material.Brick, map)
	local night = box("NightSign", Vector3.new(22, 3.2, 0.5), Vector3.new(0, 17, 98), gold, Enum.Material.Neon, map)
	night.CanCollide = false
	labelPart(night, "80TH STREET", Enum.NormalId.Back)

	box("ShopFloor", Vector3.new(18, 1, 16), Vector3.new(32, 6.2, 52), wood, Enum.Material.Wood, map)
	box("ShopAwning", Vector3.new(18, 0.5, 16), Vector3.new(32, 14, 52), wine, Enum.Material.Fabric, map)
	local shopSign = box("ShopSign", Vector3.new(12, 2.4, 0.4), Vector3.new(32, 15.2, 45), gold, Enum.Material.Neon, map)
	shopSign.CanCollide = false
	labelPart(shopSign, "ATELIER", Enum.NormalId.Back)
	local clerk = box("ShopClerk", Vector3.new(2, 4.4, 1.2), Vector3.new(32, 8.6, 54), Color3.fromRGB(12, 12, 14), Enum.Material.SmoothPlastic, map)
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

	local bw = box("BoardWins", Vector3.new(0.6, 16, 12), Vector3.new(-44, 14, 44), ink, Enum.Material.SmoothPlastic, map)
	bw.CFrame = CFrame.new(-44, 14, 44) * CFrame.Angles(0, math.rad(90), 0)
	local bk = box("BoardKills", Vector3.new(0.6, 16, 12), Vector3.new(-44, 14, 60), ink, Enum.Material.SmoothPlastic, map)
	bk.CFrame = CFrame.new(-44, 14, 60) * CFrame.Angles(0, math.rad(90), 0)
	local br = box("BoardRobux", Vector3.new(0.6, 16, 12), Vector3.new(44, 14, 44), ink, Enum.Material.SmoothPlastic, map)
	br.CFrame = CFrame.new(44, 14, 44) * CFrame.Angles(0, math.rad(-90), 0)
	box("PodiumWins", Vector3.new(4, 1, 4), Vector3.new(-40, 6.6, 44), gold, Enum.Material.Metal, map)
	box("PodiumKills", Vector3.new(4, 1, 4), Vector3.new(-40, 6.6, 60), Color3.fromRGB(180, 50, 60), Enum.Material.Metal, map)
	box("PodiumRobux", Vector3.new(4, 1, 4), Vector3.new(40, 6.6, 44), Color3.fromRGB(90, 180, 110), Enum.Material.Metal, map)

	-- FACADE + DOOR into foyer
	box("FacadeL", Vector3.new(28, 28, 4), Vector3.new(-20, 19, 20), ivory, Enum.Material.Marble, map)
	box("FacadeR", Vector3.new(28, 28, 4), Vector3.new(20, 19, 20), ivory, Enum.Material.Marble, map)
	box("FacadeTop", Vector3.new(14, 10, 4), Vector3.new(0, 28, 20), ivory, Enum.Material.Marble, map)
	local sign = box("Sign", Vector3.new(22, 4.2, 0.6), Vector3.new(0, 26, 22.4), gold, Enum.Material.Neon, map)
	sign.CanCollide = false
	light(sign, gold, 3.5, 30)
	labelPart(sign, "HIGHRISE", Enum.NormalId.Front)

	-- MANSION ROOMS (z <= 16)
	roomShell("Foyer", 0, 0, 40, 32, map, plaster)
	box("FoyerWallN_L", Vector3.new(14, 16, 2), Vector3.new(-13, 13, 16), plaster, Enum.Material.Marble, map)
	box("FoyerWallN_R", Vector3.new(14, 16, 2), Vector3.new(13, 13, 16), plaster, Enum.Material.Marble, map)
	box("FoyerWallS_L", Vector3.new(14, 16, 2), Vector3.new(-13, 13, -16), plaster, Enum.Material.Marble, map)
	box("FoyerWallS_R", Vector3.new(14, 16, 2), Vector3.new(13, 13, -16), plaster, Enum.Material.Marble, map)
	box("FoyerWallE_T", Vector3.new(2, 16, 10), Vector3.new(20, 13, 8), plaster, Enum.Material.Marble, map)
	box("FoyerWallE_B", Vector3.new(2, 16, 10), Vector3.new(20, 13, -8), plaster, Enum.Material.Marble, map)
	box("FoyerWallW_T", Vector3.new(2, 16, 10), Vector3.new(-20, 13, 8), plaster, Enum.Material.Marble, map)
	box("FoyerWallW_B", Vector3.new(2, 16, 10), Vector3.new(-20, 13, -8), plaster, Enum.Material.Marble, map)
	box("Stairs", Vector3.new(8, 6, 10), Vector3.new(0, 8, -6), ivory, Enum.Material.Marble, map)

	roomShell("Ballroom", -52, -8, 44, 40, map, plaster)
	box("BallN", Vector3.new(44, 16, 2), Vector3.new(-52, 13, 12), plaster, Enum.Material.Marble, map)
	box("BallS", Vector3.new(44, 16, 2), Vector3.new(-52, 13, -28), plaster, Enum.Material.Marble, map)
	box("BallW", Vector3.new(2, 16, 40), Vector3.new(-74, 13, -8), plaster, Enum.Material.Marble, map)
	box("BallE_T", Vector3.new(2, 16, 14), Vector3.new(-30, 13, 4), plaster, Enum.Material.Marble, map)
	box("BallE_B", Vector3.new(2, 16, 14), Vector3.new(-30, 13, -20), plaster, Enum.Material.Marble, map)
	box("PianoBody", Vector3.new(10, 2, 4), Vector3.new(-62, 7.2, -18), ink, Enum.Material.Wood, map)
	box("Hide_CurtainL", Vector3.new(1, 10, 8), Vector3.new(-72, 11, -8), wine, Enum.Material.Fabric, map)

	roomShell("Library", 52, -8, 44, 40, map, plaster)
	box("LibN", Vector3.new(44, 16, 2), Vector3.new(52, 13, 12), plaster, Enum.Material.Marble, map)
	box("LibS", Vector3.new(44, 16, 2), Vector3.new(52, 13, -28), plaster, Enum.Material.Marble, map)
	box("LibE", Vector3.new(2, 16, 40), Vector3.new(74, 13, -8), plaster, Enum.Material.Marble, map)
	box("LibW_T", Vector3.new(2, 16, 14), Vector3.new(30, 13, 4), plaster, Enum.Material.Marble, map)
	box("LibW_B", Vector3.new(2, 16, 14), Vector3.new(30, 13, -20), plaster, Enum.Material.Marble, map)
	box("ShelvesA", Vector3.new(16, 10, 2), Vector3.new(52, 11, -26), wood, Enum.Material.Wood, map)
	box("ShelvesB", Vector3.new(2, 10, 16), Vector3.new(72, 11, -8), wood, Enum.Material.Wood, map)
	box("Hide_Desk", Vector3.new(8, 3.2, 3), Vector3.new(44, 7.8, -8), wood, Enum.Material.Wood, map)

	roomShell("Kitchen", -52, -52, 40, 36, map, plaster)
	box("KitN_L", Vector3.new(14, 16, 2), Vector3.new(-62, 13, -34), plaster, Enum.Material.Marble, map)
	box("KitN_R", Vector3.new(14, 16, 2), Vector3.new(-42, 13, -34), plaster, Enum.Material.Marble, map)
	box("KitS", Vector3.new(40, 16, 2), Vector3.new(-52, 13, -70), plaster, Enum.Material.Marble, map)
	box("KitW", Vector3.new(2, 16, 36), Vector3.new(-72, 13, -52), plaster, Enum.Material.Marble, map)
	box("KitE", Vector3.new(2, 16, 36), Vector3.new(-32, 13, -52), plaster, Enum.Material.Marble, map)
	box("Counters", Vector3.new(16, 3, 3), Vector3.new(-60, 7.6, -66), Color3.fromRGB(90, 90, 96), Enum.Material.Metal, map)
	box("Hide_Island", Vector3.new(8, 3.4, 4), Vector3.new(-48, 7.8, -52), wood, Enum.Material.Wood, map)

	roomShell("Dining", 0, -52, 40, 36, map, plaster)
	box("DinN_L", Vector3.new(14, 16, 2), Vector3.new(-13, 13, -34), plaster, Enum.Material.Marble, map)
	box("DinN_R", Vector3.new(14, 16, 2), Vector3.new(13, 13, -34), plaster, Enum.Material.Marble, map)
	box("DinS", Vector3.new(40, 16, 2), Vector3.new(0, 13, -70), plaster, Enum.Material.Marble, map)
	box("DinW_T", Vector3.new(2, 16, 12), Vector3.new(-20, 13, -42), plaster, Enum.Material.Marble, map)
	box("DinW_B", Vector3.new(2, 16, 12), Vector3.new(-20, 13, -62), plaster, Enum.Material.Marble, map)
	box("DinE_T", Vector3.new(2, 16, 12), Vector3.new(20, 13, -42), plaster, Enum.Material.Marble, map)
	box("DinE_B", Vector3.new(2, 16, 12), Vector3.new(20, 13, -62), plaster, Enum.Material.Marble, map)
	box("Table", Vector3.new(16, 2.4, 6), Vector3.new(0, 7.4, -52), wood, Enum.Material.Wood, map)
	box("Hide_UnderTable", Vector3.new(14, 1.2, 4), Vector3.new(0, 6.8, -52), dark, Enum.Material.Wood, map).CanCollide = false

	roomShell("Master", 52, -52, 40, 36, map, plaster)
	box("MasN_L", Vector3.new(14, 16, 2), Vector3.new(42, 13, -34), plaster, Enum.Material.Marble, map)
	box("MasN_R", Vector3.new(14, 16, 2), Vector3.new(62, 13, -34), plaster, Enum.Material.Marble, map)
	box("MasS", Vector3.new(40, 16, 2), Vector3.new(52, 13, -70), plaster, Enum.Material.Marble, map)
	box("MasW_T", Vector3.new(2, 16, 12), Vector3.new(32, 13, -42), plaster, Enum.Material.Marble, map)
	box("MasW_B", Vector3.new(2, 16, 12), Vector3.new(32, 13, -62), plaster, Enum.Material.Marble, map)
	box("MasE", Vector3.new(2, 16, 36), Vector3.new(72, 13, -52), plaster, Enum.Material.Marble, map)
	box("Bed", Vector3.new(10, 2.2, 14), Vector3.new(58, 7.3, -58), wine, Enum.Material.Fabric, map)
	box("Hide_Closet", Vector3.new(6, 10, 4), Vector3.new(68, 11, -42), wood, Enum.Material.Wood, map)
	box("ClosetGap", Vector3.new(2, 8, 3.2), Vector3.new(65, 10, -42), dark, Enum.Material.Wood, map).CanCollide = false

	for _, ch in ipairs(map:GetChildren()) do
		if string.sub(ch.Name, 1, 5) == "Task_" then
			ch:Destroy()
		end
	end
	local function addTask(name, pos, color)
		local t = box("Task_" .. name, Vector3.new(2.4, 1.1, 2.4), pos, color, Enum.Material.Metal, map)
		light(t, color, 1.6, 10)
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
	addTask("Guest book", Vector3.new(-8, 6.7, 4), brass)
	addTask("Piano", Vector3.new(-62, 6.7, -16), ivory)
	addTask("Wine", Vector3.new(-60, 6.7, -62), wine)
	addTask("Fuse box", Vector3.new(62, 6.7, 0), Color3.fromRGB(80, 80, 88))
	addTask("Safe", Vector3.new(58, 6.7, -44), gold)

	spawns = {
		Vector3.new(0, STAND, 4),
		Vector3.new(-52, STAND, -8),
		Vector3.new(52, STAND, -8),
		Vector3.new(-52, STAND, -52),
		Vector3.new(0, STAND, -52),
		Vector3.new(52, STAND, -52),
		Vector3.new(-20, STAND, 0),
		Vector3.new(20, STAND, 0),
	}
	World.LobbySpawn = Vector3.new(0, STAND, 62)

	local spawnInst = map:FindFirstChild("LobbySpawn")
	if not (spawnInst and spawnInst:IsA("SpawnLocation")) then
		if spawnInst then
			spawnInst:Destroy()
		end
		spawnInst = Instance.new("SpawnLocation")
		spawnInst.Name = "LobbySpawn"
		spawnInst.Parent = map
	end
	local sp = spawnInst
	sp.Size = Vector3.new(12, 1, 12)
	sp.CFrame = CFrame.new(0, 6.5, 62)
	sp.Anchored = true
	sp.Transparency = 1
	sp.CanCollide = true
	sp.Neutral = true
	sp.Duration = 0
	sp.Enabled = true

	print("[Highrise] HR-15 mansion ready")
end

return World
