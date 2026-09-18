--!strict
-- Street-lobby boards like MM2 / BedWars / DOORS: top 10 + #1 avatar on a podium.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Data = require(script.Parent.Data)

local Boards = {}

type Row = { userId: number, name: string, value: number }

local KINDS = {
	{ key = "wins", title = "MOST WINS", color = Color3.fromRGB(232, 186, 96) },
	{ key = "kills", title = "MOST KILLS", color = Color3.fromRGB(220, 80, 90) },
	{ key = "robux", title = "MOST ROBUX SPENT", color = Color3.fromRGB(120, 220, 140) },
}

local stores: { [string]: OrderedDataStore } = {}
local lastRows: { [string]: { Row } } = { wins = {}, kills = {}, robux = {} }

local function storeOf(key: string): OrderedDataStore?
	if stores[key] then
		return stores[key]
	end
	local ok, s = pcall(function()
		return DataStoreService:GetOrderedDataStore("HR13_" .. key)
	end)
	if ok and s then
		stores[key] = s
		return s
	end
	return nil
end

function Boards.submit(player: Player)
	local p = Data.get(player.UserId)
	local values = { wins = p.wins, kills = p.kills, robux = p.robuxSpent }
	for key, value in pairs(values) do
		local st = storeOf(key)
		if st then
			pcall(function()
				st:SetAsync(tostring(player.UserId), math.max(0, math.floor(value)))
			end)
		end
	end
end

local function liveRows(key: string): { Row }
	local rows: { Row } = {}
	local seen: { [number]: boolean } = {}
	local st = storeOf(key)
	if st then
		local ok, pages = pcall(function()
			return st:GetSortedAsync(false, 10)
		end)
		if ok and pages then
			local page = pages:GetCurrentPage()
			for _, entry in ipairs(page) do
				local uid = tonumber(entry.key)
				if uid then
					seen[uid] = true
					local name = "Player"
					pcall(function()
						name = Players:GetNameFromUserIdAsync(uid)
					end)
					table.insert(rows, { userId = uid, name = name, value = entry.value })
				end
			end
		end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if not seen[plr.UserId] then
			local prof = Data.get(plr.UserId)
			local value = if key == "wins" then prof.wins elseif key == "kills" then prof.kills else prof.robuxSpent
			table.insert(rows, { userId = plr.UserId, name = plr.DisplayName, value = value })
		end
	end
	table.sort(rows, function(a, b)
		if a.value == b.value then
			return a.userId < b.userId
		end
		return a.value > b.value
	end)
	while #rows > 10 do
		table.remove(rows)
	end
	return rows
end

local function mannequin(parent: Instance, cf: CFrame, color: Color3): Model
	local model = Instance.new("Model")
	model.Name = "Champ"
	local function limb(name: string, size: Vector3, at: CFrame, col: Color3)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.Size = size
		p.CFrame = at
		p.Color = col
		p.Material = Enum.Material.SmoothPlastic
		p.Parent = model
		return p
	end
	local hrp = limb("HumanoidRootPart", Vector3.new(2, 2, 1), cf, color)
	hrp.Transparency = 1
	limb("Torso", Vector3.new(2, 2, 1), cf, color)
	limb("Head", Vector3.new(1.2, 1.2, 1.2), cf * CFrame.new(0, 1.6, 0), Color3.fromRGB(230, 210, 190))
	limb("Left Arm", Vector3.new(1, 2, 1), cf * CFrame.new(-1.5, 0, 0), Color3.fromRGB(230, 210, 190))
	limb("Right Arm", Vector3.new(1, 2, 1), cf * CFrame.new(1.5, 0, 0), Color3.fromRGB(230, 210, 190))
	limb("Left Leg", Vector3.new(1, 2, 1), cf * CFrame.new(-0.5, -2, 0), Color3.fromRGB(20, 20, 24))
	limb("Right Leg", Vector3.new(1, 2, 1), cf * CFrame.new(0.5, -2, 0), Color3.fromRGB(20, 20, 24))
	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R6
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = model
	model.PrimaryPart = hrp
	model.Parent = parent
	return model
end

local function loadAvatar(holder: Model, userId: number, cf: CFrame)
	if userId <= 0 then
		return
	end
	task.spawn(function()
		local ok, model = pcall(function()
			return Players:CreateHumanoidModelFromUserId(userId)
		end)
		if not ok or not model or not holder.Parent then
			return
		end
		for _, ch in ipairs(holder:GetChildren()) do
			if ch:IsA("BasePart") or ch:IsA("Humanoid") or ch:IsA("Accessory") then
				ch:Destroy()
			end
		end
		model.Name = "Avatar"
		model.Parent = holder
		pcall(function()
			model:PivotTo(cf)
		end)
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
			end
		end
		local hum = model:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			hum.WalkSpeed = 0
			hum.JumpPower = 0
		end
	end)
end

local function paintBoard(part: BasePart, title: string, accent: Color3, rows: { Row }, podiumCF: CFrame)
	local gui = part:FindFirstChild("BoardGui")
	if gui then
		gui:Destroy()
	end
	gui = Instance.new("SurfaceGui")
	gui.Name = "BoardGui"
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 40
	gui.Parent = part

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
	bg.BorderSizePixel = 0
	bg.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = accent
	stroke.Thickness = 3
	stroke.Parent = bg

	local head = Instance.new("TextLabel")
	head.BackgroundTransparency = 1
	head.Size = UDim2.new(1, -16, 0, 40)
	head.Position = UDim2.fromOffset(8, 8)
	head.Font = Enum.Font.GothamBlack
	head.Text = title
	head.TextColor3 = accent
	head.TextScaled = true
	head.Parent = bg

	for i = 1, 10 do
		local row = rows[i]
		local line = Instance.new("TextLabel")
		line.BackgroundTransparency = if i == 1 then 0.85 else 1
		line.BackgroundColor3 = accent
		line.Position = UDim2.new(0, 10, 0, 48 + (i - 1) * 22)
		line.Size = UDim2.new(1, -20, 0, 20)
		line.Font = if i == 1 then Enum.Font.GothamBold else Enum.Font.Gotham
		line.TextXAlignment = Enum.TextXAlignment.Left
		line.TextColor3 = if i == 1 then accent else Color3.fromRGB(230, 224, 214)
		line.TextSize = 16
		if row then
			line.Text = string.format("%d.  %s    %d", i, row.name, row.value)
		else
			line.Text = string.format("%d.  —", i)
		end
		line.Parent = bg
	end

	local folder = part.Parent
	if not folder then
		return
	end
	local old = folder:FindFirstChild(part.Name .. "_Champ")
	if old then
		old:Destroy()
	end
	local top = rows[1]
	local color = accent
	local dummy = mannequin(folder, podiumCF, color)
	dummy.Name = part.Name .. "_Champ"
	if top then
		loadAvatar(dummy, top.userId, podiumCF)
	end
end

function Boards.refresh()
	local map = workspace:FindFirstChild("Highrise")
	if not map then
		return
	end
	local layout = {
		wins = { part = "BoardWins", podium = CFrame.new(-34, 9, 42) * CFrame.Angles(0, math.rad(90), 0) },
		kills = { part = "BoardKills", podium = CFrame.new(-34, 9, 58) * CFrame.Angles(0, math.rad(90), 0) },
		robux = { part = "BoardRobux", podium = CFrame.new(34, 9, 42) * CFrame.Angles(0, math.rad(-90), 0) },
	}
	for _, kind in ipairs(KINDS) do
		local rows = liveRows(kind.key)
		lastRows[kind.key] = rows
		local spec = layout[kind.key]
		local part = map:FindFirstChild(spec.part)
		if part and part:IsA("BasePart") then
			paintBoard(part, kind.title, kind.color, rows, spec.podium)
		end
	end
end

function Boards.start()
	task.spawn(function()
		task.wait(1)
		Boards.refresh()
		while true do
			task.wait(15)
			for _, p in ipairs(Players:GetPlayers()) do
				Boards.submit(p)
			end
			Boards.refresh()
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		Boards.submit(p)
	end)
end

return Boards
