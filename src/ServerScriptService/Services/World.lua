--!nocheck
local Lighting = game:GetService("Lighting")

local World = {}

local ivory = Color3.fromRGB(210, 196, 176)
local brass = Color3.fromRGB(196, 154, 82)
local ink = Color3.fromRGB(22, 18, 20)
local wine = Color3.fromRGB(110, 28, 38)
local gold = Color3.fromRGB(232, 186, 96)
local carpet = Color3.fromRGB(92, 24, 36)
local wood = Color3.fromRGB(72, 48, 32)
local stone = Color3.fromRGB(140, 128, 114)
local plaster = Color3.fromRGB(214, 202, 184)
local cream = Color3.fromRGB(236, 226, 208)
local navy = Color3.fromRGB(36, 44, 62)

local waypoints = {}
local spawns = {}
local tasks = {}
local STAND = 8
World.LobbySpawn = Vector3.new(0, STAND, 72)

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
	local l = parent:FindFirstChildOfClass("PointLight")
	if not l then
		l = Instance.new("PointLight")
		l.Parent = parent
	end
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Shadows = false
	return l
end

local function labelPart(part, text, face, textColor)
	local sg = part:FindFirstChild("SignGui")
	if not sg then
		sg = Instance.new("SurfaceGui")
		sg.Name = "SignGui"
		sg.Face = face
		sg.Parent = part
	end
	local lab = sg:FindFirstChildWhichIsA("TextLabel")
	if not lab then
		lab = Instance.new("TextLabel")
		lab.BackgroundTransparency = 1
		lab.Size = UDim2.fromScale(1, 1)
		lab.Font = Enum.Font.GothamBold
		lab.TextScaled = true
		lab.Parent = sg
	end
	lab.Text = text
	lab.TextColor3 = textColor or Color3.fromRGB(16, 12, 12)
end

local function roomShell(id, cx, cz, sx, sz, parent)
	local y = 5
	local h = 16
	box(id .. "_Floor", Vector3.new(sx, 2, sz), Vector3.new(cx, y, cz), wood, Enum.Material.Wood, parent)
	box(id .. "_Ceil", Vector3.new(sx, 1.4, sz), Vector3.new(cx, y + h, cz), cream, Enum.Material.SmoothPlastic, parent)
	box(id .. "_Carpet", Vector3.new(math.max(6, sx - 10), 0.2, math.max(6, sz - 10)), Vector3.new(cx, y + 1.12, cz), carpet, Enum.Material.Fabric, parent)
	local lamp = box(id .. "_Lamp", Vector3.new(4, 0.4, 4), Vector3.new(cx, y + h - 1.1, cz), Color3.fromRGB(255, 230, 180), Enum.Material.Neon, parent)
	lamp.CanCollide = false
	light(lamp, Color3.fromRGB(255, 220, 170), 4, 42)
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
	return pos.Y > 2 and pos.Y < 80 and math.abs(pos.X) < 160 and pos.Z > -90 and pos.Z < 230
end
function World.safe(pos)
	if pos.Z > 118 then
		return Vector3.new(math.clamp(pos.X, -24, 24), math.clamp(pos.Y, STAND, 56), math.clamp(pos.Z, 118, 210))
	end
	return Vector3.new(math.clamp(pos.X, -80, 80), STAND, math.clamp(pos.Z, -70, 110))
end

function World.applyLighting()
	Lighting.ClockTime = 17.2
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(110, 100, 92)
	Lighting.OutdoorAmbient = Color3.fromRGB(90, 86, 100)
	Lighting.FogColor = Color3.fromRGB(180, 168, 158)
	Lighting.FogStart = 140
	Lighting.FogEnd = 380
	Lighting.GlobalShadows = false
	for _, n in ipairs({ "Atmosphere", "ColorCorrection", "Bloom", "Sky" }) do
		local old = Lighting:FindFirstChild(n)
		if old then
			old:Destroy()
		end
	end
	Instance.new("Sky").Parent = Lighting
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.06
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

	box("Catch", Vector3.new(500, 8, 520), Vector3.new(0, 0, 40), Color3.fromRGB(48, 44, 40), Enum.Material.Slate, map)

	box("Plaza", Vector3.new(110, 2, 80), Vector3.new(0, 5, 68), stone, Enum.Material.Cobblestone, map)
	box("Path", Vector3.new(12, 0.4, 44), Vector3.new(0, 6.2, 48), carpet, Enum.Material.Fabric, map)
	box("Steps", Vector3.new(12, 1.4, 8), Vector3.new(0, 6.3, 26), ivory, Enum.Material.Marble, map)
	local fountain = box("Fountain", Vector3.new(10, 2.2, 10), Vector3.new(0, 7.1, 78), brass, Enum.Material.Metal, map)
	light(fountain, gold, 3.2, 30)
	box("FountainTop", Vector3.new(3.2, 5, 3.2), Vector3.new(0, 10.4, 78), gold, Enum.Material.Neon, map)
	box("Street", Vector3.new(130, 1, 34), Vector3.new(0, 5.1, 108), Color3.fromRGB(36, 36, 40), Enum.Material.Asphalt, map)
	box("CurbL", Vector3.new(2, 1.4, 34), Vector3.new(-64, 5.8, 108), stone, Enum.Material.Slate, map)
	box("CurbR", Vector3.new(2, 1.4, 34), Vector3.new(64, 5.8, 108), stone, Enum.Material.Slate, map)
	for _, x in ipairs({ -36, 36 }) do
		for _, z in ipairs({ 48, 88 }) do
			local lamp = box("Lamp_" .. x .. "_" .. z, Vector3.new(0.7, 14, 0.7), Vector3.new(x, 13, z), ink, Enum.Material.Metal, map)
			light(lamp, Color3.fromRGB(255, 210, 150), 3, 26)
		end
	end
	box("FarShopA", Vector3.new(28, 16, 10), Vector3.new(-30, 14, 124), Color3.fromRGB(56, 40, 42), Enum.Material.Brick, map)
	box("FarShopB", Vector3.new(28, 16, 10), Vector3.new(30, 14, 124), Color3.fromRGB(40, 46, 62), Enum.Material.Brick, map)
	local night = box("NightSign", Vector3.new(24, 3.2, 0.5), Vector3.new(0, 18, 118), gold, Enum.Material.Neon, map)
	night.CanCollide = false
	labelPart(night, "80TH STREET", Enum.NormalId.Back)

	box("ShopFloor", Vector3.new(28, 1, 22), Vector3.new(40, 6.2, 58), Color3.fromRGB(70, 88, 120), Enum.Material.Carpet, map)
	box("ShopCeil", Vector3.new(28, 1, 22), Vector3.new(40, 16, 58), Color3.fromRGB(80, 86, 96), Enum.Material.SmoothPlastic, map)
	box("ShopWallE", Vector3.new(1.2, 10, 22), Vector3.new(54, 11.2, 58), Color3.fromRGB(50, 56, 66), Enum.Material.Concrete, map)
	box("ShopWallN", Vector3.new(16, 10, 1.2), Vector3.new(46, 11.2, 69), Color3.fromRGB(50, 56, 66), Enum.Material.Concrete, map)
	box("ShopWallS", Vector3.new(28, 10, 1.2), Vector3.new(40, 11.2, 47), Color3.fromRGB(50, 56, 66), Enum.Material.Concrete, map)
	box("ShopShelfA", Vector3.new(10, 6, 2), Vector3.new(48, 9.4, 66), wood, Enum.Material.Wood, map)
	box("ShopShelfB", Vector3.new(2, 6, 10), Vector3.new(52, 9.4, 56), wood, Enum.Material.Wood, map)
	box("ShopCase", Vector3.new(8, 4, 3), Vector3.new(32, 8.4, 50), Color3.fromRGB(160, 140, 90), Enum.Material.Glass, map)
	for i = 1, 6 do
		local crate = box("ShopCrate_" .. i, Vector3.new(2.2, 1.6, 2.2), Vector3.new(46 + (i % 3) * 2.4, 7.4, 54 + math.floor((i - 1) / 3) * 3), Color3.fromRGB(160, 70 + i * 12, 50), Enum.Material.SmoothPlastic, map)
		crate.CanCollide = false
	end
	local shopGlow = box("ShopStar", Vector3.new(8, 8, 0.4), Vector3.new(40, 18, 47.6), Color3.fromRGB(190, 140, 255), Enum.Material.Neon, map)
	shopGlow.CanCollide = false
	light(shopGlow, Color3.fromRGB(210, 170, 255), 3, 24)
	labelPart(shopGlow, "SHOP", Enum.NormalId.Front, Color3.fromRGB(255, 255, 255))
	local clerk = box("ShopClerk", Vector3.new(2, 4.4, 1.2), Vector3.new(40, 8.6, 62), Color3.fromRGB(12, 12, 14), Enum.Material.SmoothPlastic, map)
	clerk.CanCollide = false
	light(clerk, Color3.fromRGB(255, 220, 180), 2.2, 18)
	if not clerk:FindFirstChild("OpenShop") then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "OpenShop"
		prompt.ActionText = "Browse Atelier"
		prompt.ObjectText = "SHOP"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = clerk
	end

	local bw = box("BoardWins", Vector3.new(0.6, 16, 12), Vector3.new(-50, 14, 50), ink, Enum.Material.SmoothPlastic, map)
	bw.CFrame = CFrame.new(-50, 14, 50) * CFrame.Angles(0, math.rad(90), 0)
	local bk = box("BoardKills", Vector3.new(0.6, 16, 12), Vector3.new(-50, 14, 68), ink, Enum.Material.SmoothPlastic, map)
	bk.CFrame = CFrame.new(-50, 14, 68) * CFrame.Angles(0, math.rad(90), 0)
	local br = box("BoardRobux", Vector3.new(0.6, 16, 12), Vector3.new(-50, 14, 86), ink, Enum.Material.SmoothPlastic, map)
	br.CFrame = CFrame.new(-50, 14, 86) * CFrame.Angles(0, math.rad(90), 0)
	box("PodiumWins", Vector3.new(4, 1, 4), Vector3.new(-44, 6.6, 50), gold, Enum.Material.Metal, map)
	box("PodiumKills", Vector3.new(4, 1, 4), Vector3.new(-44, 6.6, 68), Color3.fromRGB(180, 50, 60), Enum.Material.Metal, map)
	box("PodiumRobux", Vector3.new(4, 1, 4), Vector3.new(-44, 6.6, 86), Color3.fromRGB(90, 180, 110), Enum.Material.Metal, map)

	-- Townhouse west of the plaza (walk-in living + bedroom)
	roomShell("Town", -92, 64, 36, 28, map)
	box("TownWallE_N", Vector3.new(2, 16, 10), Vector3.new(-74, 13, 72), plaster, Enum.Material.Marble, map)
	box("TownWallE_S", Vector3.new(2, 16, 10), Vector3.new(-74, 13, 56), plaster, Enum.Material.Marble, map)
	box("TownWallW", Vector3.new(2, 16, 28), Vector3.new(-110, 13, 64), plaster, Enum.Material.Marble, map)
	box("TownWallN", Vector3.new(36, 16, 2), Vector3.new(-92, 13, 78), plaster, Enum.Material.Marble, map)
	box("TownWallS", Vector3.new(36, 16, 2), Vector3.new(-92, 13, 50), plaster, Enum.Material.Marble, map)
	box("TownSofa", Vector3.new(10, 1.8, 3.4), Vector3.new(-96, 7.1, 70), navy, Enum.Material.Fabric, map)
	box("TownTable", Vector3.new(6, 1.4, 6), Vector3.new(-88, 6.9, 64), wood, Enum.Material.Wood, map)
	box("TownBed", Vector3.new(8, 2, 12), Vector3.new(-100, 7.2, 58), wine, Enum.Material.Fabric, map)
	box("TownShelf", Vector3.new(10, 8, 1.4), Vector3.new(-92, 10, 51.4), wood, Enum.Material.Wood, map)
	box("TownTV", Vector3.new(8, 4, 0.4), Vector3.new(-84, 10, 76.6), Color3.fromRGB(20, 22, 28), Enum.Material.SmoothPlastic, map)
	local townSign = box("TownSign", Vector3.new(10, 2.2, 0.4), Vector3.new(-74, 16, 64), gold, Enum.Material.Neon, map)
	townSign.CanCollide = false
	labelPart(townSign, "CLUBHOUSE", Enum.NormalId.Right)

	-- Waiting obby behind the street
	box("ObbyPad", Vector3.new(36, 1, 16), Vector3.new(0, 6.2, 138), Color3.fromRGB(40, 36, 34), Enum.Material.Slate, map)
	local obbySign = box("ObbySign", Vector3.new(16, 3, 0.5), Vector3.new(0, 12, 131), gold, Enum.Material.Neon, map)
	obbySign.CanCollide = false
	labelPart(obbySign, "WAITING OBBY", Enum.NormalId.Front)
	local ox, oz = 0, 148
	for i = 1, 12 do
		ox = ((i % 2 == 0) and 8 or -8)
		oz = 146 + i * 5
		local y = 6 + i * 2.2
		local pad = box("Obby_" .. i, Vector3.new(8, 1, 4), Vector3.new(ox, y, oz), if i == 12 then gold else Color3.fromRGB(70 + i * 8, 50, 40), Enum.Material.Slate, map)
		if i == 12 then
			light(pad, gold, 3, 18)
			labelPart(pad, "TOP", Enum.NormalId.Top, Color3.fromRGB(20, 12, 8))
		end
	end

	box("FacadeL", Vector3.new(28, 28, 4), Vector3.new(-20, 19, 22), ivory, Enum.Material.Marble, map)
	box("FacadeR", Vector3.new(28, 28, 4), Vector3.new(20, 19, 22), ivory, Enum.Material.Marble, map)
	box("FacadeTop", Vector3.new(14, 10, 4), Vector3.new(0, 28, 22), ivory, Enum.Material.Marble, map)
	local sign = box("Sign", Vector3.new(22, 4.2, 0.6), Vector3.new(0, 26, 24.4), gold, Enum.Material.Neon, map)
	sign.CanCollide = false
	light(sign, gold, 4, 32)
	labelPart(sign, "HIGHRISE", Enum.NormalId.Front)

	roomShell("Foyer", 0, 0, 40, 36, map)
	box("FoyerWallN_L", Vector3.new(14, 16, 2), Vector3.new(-13, 13, 18), plaster, Enum.Material.Marble, map)
	box("FoyerWallN_R", Vector3.new(14, 16, 2), Vector3.new(13, 13, 18), plaster, Enum.Material.Marble, map)
	box("FoyerWallS_L", Vector3.new(14, 16, 2), Vector3.new(-13, 13, -18), plaster, Enum.Material.Marble, map)
	box("FoyerWallS_R", Vector3.new(14, 16, 2), Vector3.new(13, 13, -18), plaster, Enum.Material.Marble, map)
	box("FoyerWallE_T", Vector3.new(2, 16, 12), Vector3.new(20, 13, 8), plaster, Enum.Material.Marble, map)
	box("FoyerWallE_B", Vector3.new(2, 16, 12), Vector3.new(20, 13, -8), plaster, Enum.Material.Marble, map)
	box("FoyerWallW_T", Vector3.new(2, 16, 12), Vector3.new(-20, 13, 8), plaster, Enum.Material.Marble, map)
	box("FoyerWallW_B", Vector3.new(2, 16, 12), Vector3.new(-20, 13, -8), plaster, Enum.Material.Marble, map)
	box("SofaA", Vector3.new(10, 1.6, 3.2), Vector3.new(-8, 7, 6), wine, Enum.Material.Fabric, map)
	box("SofaB", Vector3.new(10, 1.6, 3.2), Vector3.new(8, 7, 6), wine, Enum.Material.Fabric, map)
	box("FoyerTable", Vector3.new(6, 1.4, 6), Vector3.new(0, 6.9, 2), wood, Enum.Material.Wood, map)

	roomShell("Ballroom", -52, -8, 44, 40, map)
	box("BallN", Vector3.new(44, 16, 2), Vector3.new(-52, 13, 12), plaster, Enum.Material.Marble, map)
	box("BallS", Vector3.new(44, 16, 2), Vector3.new(-52, 13, -28), plaster, Enum.Material.Marble, map)
	box("BallW", Vector3.new(2, 16, 40), Vector3.new(-74, 13, -8), plaster, Enum.Material.Marble, map)
	box("BallE_T", Vector3.new(2, 16, 14), Vector3.new(-30, 13, 4), plaster, Enum.Material.Marble, map)
	box("BallE_B", Vector3.new(2, 16, 14), Vector3.new(-30, 13, -20), plaster, Enum.Material.Marble, map)
	box("PianoBody", Vector3.new(10, 2, 4), Vector3.new(-62, 7.2, -18), ink, Enum.Material.Wood, map)
	box("Hide_CurtainL", Vector3.new(1, 10, 8), Vector3.new(-72, 11, -8), wine, Enum.Material.Fabric, map)
	box("BallChairs", Vector3.new(12, 2, 2), Vector3.new(-48, 7.2, 4), wood, Enum.Material.Wood, map)

	roomShell("Library", 52, -8, 44, 40, map)
	box("LibN", Vector3.new(44, 16, 2), Vector3.new(52, 13, 12), plaster, Enum.Material.Marble, map)
	box("LibS", Vector3.new(44, 16, 2), Vector3.new(52, 13, -28), plaster, Enum.Material.Marble, map)
	box("LibE", Vector3.new(2, 16, 40), Vector3.new(74, 13, -8), plaster, Enum.Material.Marble, map)
	box("LibW_T", Vector3.new(2, 16, 14), Vector3.new(30, 13, 4), plaster, Enum.Material.Marble, map)
	box("LibW_B", Vector3.new(2, 16, 14), Vector3.new(30, 13, -20), plaster, Enum.Material.Marble, map)
	box("ShelvesA", Vector3.new(16, 10, 2), Vector3.new(52, 11, -26), wood, Enum.Material.Wood, map)
	box("ShelvesB", Vector3.new(2, 10, 16), Vector3.new(72, 11, -8), wood, Enum.Material.Wood, map)
	box("Hide_Desk", Vector3.new(8, 3.2, 3), Vector3.new(44, 7.8, -8), wood, Enum.Material.Wood, map)
	box("LibChair", Vector3.new(3, 3, 3), Vector3.new(44, 7.6, -4), wine, Enum.Material.Fabric, map)

	roomShell("Kitchen", -52, -52, 40, 36, map)
	box("KitN_L", Vector3.new(14, 16, 2), Vector3.new(-62, 13, -34), plaster, Enum.Material.Marble, map)
	box("KitN_R", Vector3.new(14, 16, 2), Vector3.new(-42, 13, -34), plaster, Enum.Material.Marble, map)
	box("KitS", Vector3.new(40, 16, 2), Vector3.new(-52, 13, -70), plaster, Enum.Material.Marble, map)
	box("KitW", Vector3.new(2, 16, 36), Vector3.new(-72, 13, -52), plaster, Enum.Material.Marble, map)
	box("KitE", Vector3.new(2, 16, 36), Vector3.new(-32, 13, -52), plaster, Enum.Material.Marble, map)
	box("Counters", Vector3.new(16, 3, 3), Vector3.new(-60, 7.6, -66), Color3.fromRGB(170, 170, 176), Enum.Material.SmoothPlastic, map)
	box("Hide_Island", Vector3.new(8, 3.4, 4), Vector3.new(-48, 7.8, -52), wood, Enum.Material.Wood, map)
	box("Fridge", Vector3.new(4, 8, 3), Vector3.new(-68, 10, -66), Color3.fromRGB(200, 200, 206), Enum.Material.Metal, map)

	roomShell("Dining", 0, -52, 40, 36, map)
	box("DinN_L", Vector3.new(14, 16, 2), Vector3.new(-13, 13, -34), plaster, Enum.Material.Marble, map)
	box("DinN_R", Vector3.new(14, 16, 2), Vector3.new(13, 13, -34), plaster, Enum.Material.Marble, map)
	box("DinS", Vector3.new(40, 16, 2), Vector3.new(0, 13, -70), plaster, Enum.Material.Marble, map)
	box("DinW_T", Vector3.new(2, 16, 12), Vector3.new(-20, 13, -42), plaster, Enum.Material.Marble, map)
	box("DinW_B", Vector3.new(2, 16, 12), Vector3.new(-20, 13, -62), plaster, Enum.Material.Marble, map)
	box("DinE_T", Vector3.new(2, 16, 12), Vector3.new(20, 13, -42), plaster, Enum.Material.Marble, map)
	box("DinE_B", Vector3.new(2, 16, 12), Vector3.new(20, 13, -62), plaster, Enum.Material.Marble, map)
	box("Table", Vector3.new(16, 2.4, 6), Vector3.new(0, 7.4, -52), wood, Enum.Material.Wood, map)
	box("DinChairA", Vector3.new(2, 3, 2), Vector3.new(-4, 7.6, -46), wine, Enum.Material.Fabric, map)
	box("DinChairB", Vector3.new(2, 3, 2), Vector3.new(4, 7.6, -46), wine, Enum.Material.Fabric, map)
	box("DinChairC", Vector3.new(2, 3, 2), Vector3.new(-4, 7.6, -58), wine, Enum.Material.Fabric, map)
	box("DinChairD", Vector3.new(2, 3, 2), Vector3.new(4, 7.6, -58), wine, Enum.Material.Fabric, map)

	roomShell("Master", 52, -52, 40, 36, map)
	box("MasN_L", Vector3.new(14, 16, 2), Vector3.new(42, 13, -34), plaster, Enum.Material.Marble, map)
	box("MasN_R", Vector3.new(14, 16, 2), Vector3.new(62, 13, -34), plaster, Enum.Material.Marble, map)
	box("MasS", Vector3.new(40, 16, 2), Vector3.new(52, 13, -70), plaster, Enum.Material.Marble, map)
	box("MasW_T", Vector3.new(2, 16, 12), Vector3.new(32, 13, -42), plaster, Enum.Material.Marble, map)
	box("MasW_B", Vector3.new(2, 16, 12), Vector3.new(32, 13, -62), plaster, Enum.Material.Marble, map)
	box("MasE", Vector3.new(2, 16, 36), Vector3.new(72, 13, -52), plaster, Enum.Material.Marble, map)
	box("Bed", Vector3.new(10, 2.2, 14), Vector3.new(58, 7.3, -58), wine, Enum.Material.Fabric, map)
	box("Nightstand", Vector3.new(3, 2, 3), Vector3.new(50, 7.2, -52), wood, Enum.Material.Wood, map)
	box("Hide_Closet", Vector3.new(6, 10, 4), Vector3.new(68, 11, -42), wood, Enum.Material.Wood, map)

	for _, ch in ipairs(map:GetChildren()) do
		if string.sub(ch.Name, 1, 5) == "Task_" then
			ch:Destroy()
		end
	end
	local function addTask(name, pos, color)
		local t = box("Task_" .. name, Vector3.new(2.4, 1.1, 2.4), pos, color, Enum.Material.Metal, map)
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
		Vector3.new(-12, STAND, 0),
		Vector3.new(12, STAND, 0),
	}
	World.LobbySpawn = Vector3.new(0, STAND, 72)

	local spawnInst = map:FindFirstChild("LobbySpawn")
	if not (spawnInst and spawnInst:IsA("SpawnLocation")) then
		if spawnInst then
			spawnInst:Destroy()
		end
		spawnInst = Instance.new("SpawnLocation")
		spawnInst.Name = "LobbySpawn"
		spawnInst.Parent = map
	end
	spawnInst.Size = Vector3.new(12, 1, 12)
	spawnInst.CFrame = CFrame.new(0, 6.5, 72)
	spawnInst.Anchored = true
	spawnInst.Transparency = 1
	spawnInst.CanCollide = true
	spawnInst.Neutral = true
	spawnInst.Duration = 0
	spawnInst.Enabled = true

	print("[Highrise] HR-17 lobby house + obby + mansion ready")
end

return World
