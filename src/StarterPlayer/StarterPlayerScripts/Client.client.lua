--!strict
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local Config = require(game.ReplicatedStorage.Shared.Config)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local Shop = require(game.ReplicatedStorage.Shared.Shop)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
end)

local state = {
	phase = "Lobby",
	role = "Innocent",
	remaining = Config.LobbySeconds,
	winner = nil :: string?,
	coins = 0,
	owned = {} :: { string },
	equipped = Shop.defaults(),
	passes = {} :: { [string]: boolean },
	objective = "Shop, then wait for the night to start.",
	aliveCount = 0,
}
local lastSync = os.clock()

local function owns(id: string): boolean
	for _, x in ipairs(state.owned) do
		if x == id then
			return true
		end
	end
	return false
end

local gui = Instance.new("ScreenGui")
gui.Name = "HighriseHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function attachFill(char: Model)
	local hum = char:WaitForChild("Humanoid", 8)
	if hum and hum:IsA("Humanoid") then
		pcall(function()
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		end)
		hum.JumpPower = Config.JumpPower
	end
	local hrp = char:WaitForChild("HumanoidRootPart", 8)
	if not hrp or hrp:FindFirstChild("HighriseFill") then
		return
	end
	local l = Instance.new("PointLight")
	l.Name = "HighriseFill"
	l.Brightness = 1.2
	l.Range = 28
	l.Color = Color3.fromRGB(255, 226, 190)
	l.Shadows = false
	l.Parent = hrp
end
player.CharacterAdded:Connect(attachFill)
if player.Character then
	task.spawn(attachFill, player.Character)
end

local function mk(className: string, props: { [string]: any }, parent: Instance?): Instance
	local i = Instance.new(className)
	for k, v in props do
		(i :: any)[k] = v
	end
	if parent then
		i.Parent = parent
	end
	return i
end

local ivory = Color3.fromRGB(232, 226, 214)
local ink = Color3.fromRGB(10, 10, 12)
local muted = Color3.fromRGB(168, 162, 154)

local top = mk("Frame", {
	BackgroundColor3 = ink,
	BackgroundTransparency = 0.22,
	BorderSizePixel = 0,
	Position = UDim2.new(0.5, -210, 0, 18),
	Size = UDim2.fromOffset(420, 64),
}, gui) :: Frame
mk("UICorner", { CornerRadius = UDim.new(0, 16) }, top)
mk("UIStroke", { Color = Color3.fromRGB(70, 64, 56), Thickness = 1, Transparency = 0.4 }, top)

local title = mk("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 6),
	Size = UDim2.fromOffset(200, 22),
	Font = Enum.Font.GothamMedium,
	Text = Config.Title .. "  " .. Config.BuildId,
	TextColor3 = ivory,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
}, top) :: TextLabel

local phaseLab = mk("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 30),
	Size = UDim2.fromOffset(220, 24),
	Font = Enum.Font.GothamBold,
	Text = "LOBBY",
	TextColor3 = ivory,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
}, top) :: TextLabel

local timerLab = mk("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(1, -140, 0, 10),
	Size = UDim2.fromOffset(124, 44),
	Font = Enum.Font.GothamBold,
	Text = "0:22",
	TextColor3 = ivory,
	TextSize = 28,
	TextXAlignment = Enum.TextXAlignment.Right,
}, top) :: TextLabel

local roleCard = mk("Frame", {
	BackgroundColor3 = ink,
	BackgroundTransparency = 0.12,
	BorderSizePixel = 0,
	Position = UDim2.new(0.5, -160, 0.5, -70),
	Size = UDim2.fromOffset(320, 140),
	Visible = false,
	ZIndex = 5,
}, gui) :: Frame
mk("UICorner", { CornerRadius = UDim.new(0, 20) }, roleCard)
local roleTitle = mk("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(20, 24),
	Size = UDim2.fromOffset(280, 36),
	Font = Enum.Font.GothamBold,
	Text = "INNOCENT",
	TextColor3 = ivory,
	TextSize = 28,
	ZIndex = 6,
}, roleCard) :: TextLabel
local roleBody = mk("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(20, 68),
	Size = UDim2.fromOffset(280, 50),
	Font = Enum.Font.Gotham,
	Text = "",
	TextColor3 = muted,
	TextSize = 15,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 6,
}, roleCard) :: TextLabel

local toast = mk("TextLabel", {
	BackgroundColor3 = ink,
	BackgroundTransparency = 0.15,
	BorderSizePixel = 0,
	Position = UDim2.new(0.5, -180, 1, -140),
	Size = UDim2.fromOffset(360, 40),
	Font = Enum.Font.Gotham,
	Text = "",
	TextColor3 = ivory,
	TextSize = 15,
	Visible = false,
	ZIndex = 8,
}, gui) :: TextLabel
mk("UICorner", { CornerRadius = UDim.new(0, 12) }, toast)

local coinsLab = mk("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 20, 1, -48),
	Size = UDim2.fromOffset(200, 28),
	Font = Enum.Font.GothamMedium,
	Text = "0 coins",
	TextColor3 = ivory,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
}, gui) :: TextLabel

local hint = mk("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0.5, -260, 1, -96),
	Size = UDim2.fromOffset(520, 24),
	Font = Enum.Font.Gotham,
	Text = "WASD move  ·  Click to attack  ·  E on tasks  ·  Shop bottom-right",
	TextColor3 = muted,
	TextSize = 13,
}, gui) :: TextLabel

local obj = mk("TextLabel", {
	BackgroundColor3 = ink,
	BackgroundTransparency = 0.25,
	BorderSizePixel = 0,
	Position = UDim2.new(0.5, -220, 0, 90),
	Size = UDim2.fromOffset(440, 28),
	Font = Enum.Font.Gotham,
	Text = "Shop, then wait for the night to start.",
	TextColor3 = ivory,
	TextSize = 14,
}, gui) :: TextLabel
mk("UICorner", { CornerRadius = UDim.new(0, 10) }, obj)

local aliveLab = mk("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 20, 1, -72),
	Size = UDim2.fromOffset(220, 22),
	Font = Enum.Font.GothamMedium,
	Text = "",
	TextColor3 = muted,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
}, gui) :: TextLabel

local shopBtn = mk("TextButton", {
	BackgroundColor3 = ivory,
	BorderSizePixel = 0,
	Position = UDim2.new(1, -132, 1, -56),
	Size = UDim2.fromOffset(112, 40),
	Font = Enum.Font.GothamBold,
	Text = "Shop",
	TextColor3 = ink,
	TextSize = 16,
	AutoButtonColor = true,
}, gui) :: TextButton
mk("UICorner", { CornerRadius = UDim.new(0, 12) }, shopBtn)

local shop = mk("Frame", {
	BackgroundColor3 = Color3.fromRGB(14, 14, 16),
	BorderSizePixel = 0,
	Position = UDim2.new(0.5, -280, 0.5, -210),
	Size = UDim2.fromOffset(560, 420),
	Visible = false,
	ZIndex = 10,
}, gui) :: Frame
mk("UICorner", { CornerRadius = UDim.new(0, 22) }, shop)
mk("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(24, 16),
	Size = UDim2.fromOffset(300, 28),
	Font = Enum.Font.GothamBold,
	Text = "Atelier",
	TextColor3 = ivory,
	TextSize = 22,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 11,
}, shop)
local shopClose = mk("TextButton", {
	BackgroundTransparency = 1,
	Position = UDim2.new(1, -48, 0, 12),
	Size = UDim2.fromOffset(36, 36),
	Font = Enum.Font.GothamBold,
	Text = "X",
	TextColor3 = muted,
	TextSize = 18,
	ZIndex = 11,
}, shop) :: TextButton

local list = mk("ScrollingFrame", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 56),
	Size = UDim2.new(1, -32, 1, -72),
	CanvasSize = UDim2.fromOffset(0, 900),
	ScrollBarThickness = 4,
	ZIndex = 11,
	BorderSizePixel = 0,
}, shop) :: ScrollingFrame
mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)

local function row(text: string, sub: string, action: string, key: string, order: number)
	local f = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(22, 22, 26),
		BorderSizePixel = 0,
		Size = UDim2.new(1, -8, 0, 58),
		LayoutOrder = order,
		ZIndex = 12,
	}, list) :: Frame
	mk("UICorner", { CornerRadius = UDim.new(0, 12) }, f)
	mk("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.fromOffset(300, 22),
		Font = Enum.Font.GothamMedium,
		Text = text,
		TextColor3 = ivory,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
	}, f)
	mk("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 30),
		Size = UDim2.fromOffset(320, 18),
		Font = Enum.Font.Gotham,
		Text = sub,
		TextColor3 = muted,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
	}, f)
	local b = mk("TextButton", {
		BackgroundColor3 = ivory,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -118, 0.5, -14),
		Size = UDim2.fromOffset(104, 28),
		Font = Enum.Font.GothamBold,
		Text = action,
		TextColor3 = ink,
		TextSize = 12,
		ZIndex = 13,
	}, f) :: TextButton
	mk("UICorner", { CornerRadius = UDim.new(0, 8) }, b)
	b.MouseButton1Click:Connect(function()
		if key:sub(1, 5) == "rbx:" then
			Remotes.get("RobuxBuy"):FireServer(key:sub(6))
		elseif key:sub(1, 5) == "buy:" then
			Remotes.get("ShopBuy"):FireServer(key:sub(6))
		elseif key:sub(1, 6) == "equip:" then
			Remotes.get("ShopEquip"):FireServer(key:sub(7))
		end
	end)
end

local function rebuildShop()
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local i = 1
	for _, p in ipairs(Config.Products) do
		row(p.name, "Robux  " .. tostring(p.robux), "Buy", "rbx:" .. p.key, i)
		i += 1
	end
	for _, p in ipairs(Config.Passes) do
		local have = state.passes[p.key] == true
		row(p.name, p.perks .. "  ·  R$ " .. tostring(p.robux), if have then "Owned" else "Buy", "rbx:" .. p.key, i)
		i += 1
	end
	for _, it in ipairs(Shop.Items) do
		local have = owns(it.id)
		local sub = if it.vip then "VIP exclusive" else (if it.price == 0 then "Starter" else it.price .. " coins")
		local act = if have then "Equip" else "Buy"
		local key = if have then "equip:" .. it.id else "buy:" .. it.id
		row(it.name, it.slot .. "  ·  " .. sub, act, key, i)
		i += 1
	end
	list.CanvasSize = UDim2.fromOffset(0, i * 66)
end

shopBtn.MouseButton1Click:Connect(function()
	shop.Visible = not shop.Visible
	if shop.Visible then
		rebuildShop()
	end
end)
shopClose.MouseButton1Click:Connect(function()
	shop.Visible = false
end)

local function notify(msg: string)
	toast.Text = msg
	toast.Visible = true
	task.delay(2.4, function()
		if toast.Text == msg then
			toast.Visible = false
		end
	end)
end

local ROLE_COPY = {
	Murderer = "Silence the floor. One strike. Don't get seen.",
	Sheriff = "One gold round. Hit the killer. Miss, and you're done.",
	Innocent = "Finish tasks. Stay alive. The revolver can be picked up.",
}

Remotes.get("RoundState").OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end
	state.phase = payload.phase or state.phase
	if typeof(payload.remaining) == "number" then
		state.remaining = payload.remaining
		lastSync = os.clock()
	end
	state.winner = payload.winner
	if typeof(payload.objective) == "string" then
		state.objective = payload.objective
		obj.Text = payload.objective
	end
	if typeof(payload.aliveCount) == "number" then
		state.aliveCount = payload.aliveCount
		aliveLab.Text = if state.phase == "Round" then (tostring(payload.aliveCount) .. " alive") else ""
	end
	phaseLab.Text = string.upper(state.phase)
	if state.phase == "Over" and payload.winner then
		notify(payload.winner .. " win the night.")
	end
end)

Remotes.get("RoleReveal").OnClientEvent:Connect(function(role, ph)
	if typeof(role) == "string" then
		state.role = role
	end
	if ph == "Reveal" or ph == "Round" then
		roleTitle.Text = string.upper(state.role)
		roleBody.Text = ROLE_COPY[state.role] or ""
		roleCard.Visible = true
		if ph == "Round" then
			task.delay(2.5, function()
				roleCard.Visible = false
			end)
		end
	else
		roleCard.Visible = false
	end
end)

Remotes.get("Notify").OnClientEvent:Connect(function(msg)
	if typeof(msg) == "string" then
		notify(msg)
	end
end)

Remotes.get("Profile").OnClientEvent:Connect(function(profile, passes)
	if typeof(profile) == "table" then
		state.coins = profile.coins or 0
		state.owned = profile.owned or state.owned
		state.equipped = profile.equipped or state.equipped
		coinsLab.Text = tostring(state.coins) .. " coins"
	end
	if typeof(passes) == "table" then
		state.passes = passes
	end
	if shop.Visible then
		rebuildShop()
	end
end)

Remotes.get("AttackFx").OnClientEvent:Connect(function(kind, pos, look)
	if typeof(pos) ~= "Vector3" then
		return
	end
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = if kind == "gun" then Color3.fromRGB(255, 220, 140) else Color3.fromRGB(220, 220, 230)
	p.Size = if kind == "gun" then Vector3.new(0.2, 0.2, 8) else Vector3.new(0.3, 0.3, 3)
	p.CFrame = CFrame.lookAt(pos, pos + (look or Vector3.zAxis)) * CFrame.new(0, 0, -p.Size.Z / 2)
	p.Parent = workspace
	TweenService:Create(p, TweenInfo.new(0.18), { Transparency = 1 }):Play()
	task.delay(0.2, function()
		p:Destroy()
	end)
end)

local function tryAttack()
	if state.phase ~= "Round" then
		return
	end
	if state.role ~= "Murderer" and state.role ~= "Sheriff" then
		return
	end
	Remotes.get("Attack"):FireServer()
end

UIS.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		tryAttack()
	end
end)

-- Task prompts. Never block the HUD/timer on this.
task.spawn(function()
	local folder = workspace:WaitForChild("HighriseMap", 30) or workspace:WaitForChild("Highrise", 5)
	if not folder then
		return
	end
	local function bind(t: Instance)
		if string.sub(t.Name, 1, 5) ~= "Task_" then
			return
		end
		local prompt = t:FindFirstChildOfClass("ProximityPrompt") or t:WaitForChild("ProximityPrompt", 2)
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Triggered:Connect(function()
				Remotes.get("TaskDo"):FireServer(t.Name)
			end)
		end
	end
	for _, t in ipairs(folder:GetChildren()) do
		bind(t)
	end
	folder.ChildAdded:Connect(bind)
end)

-- Mobile attack button
if UIS.TouchEnabled then
	local atk = mk("TextButton", {
		BackgroundColor3 = ivory,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -96, 1, -160),
		Size = UDim2.fromOffset(72, 72),
		Font = Enum.Font.GothamBold,
		Text = "USE",
		TextColor3 = ink,
		TextSize = 16,
	}, gui) :: TextButton
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, atk)
	atk.MouseButton1Click:Connect(tryAttack)
end

RunService.RenderStepped:Connect(function()
	local left = math.max(0, math.floor(state.remaining - (os.clock() - lastSync) + 0.5))
	local m = math.floor(left / 60)
	local s = left % 60
	timerLab.Text = string.format("%d:%02d", m, s)
	title.Text = if state.phase == "Round" then string.upper(state.role) else (Config.Title .. "  " .. Config.BuildId)
end)

task.defer(function()
	Remotes.get("RequestState"):FireServer()
	local cam = workspace.CurrentCamera
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart", 8)
	if cam and hrp then
		cam.CameraType = Enum.CameraType.Custom
		cam.CFrame = CFrame.lookAt(hrp.Position + Vector3.new(0, 6, 14), hrp.Position + Vector3.new(0, 2, -8))
	end
end)
