--!strict
do
	local p = workspace:FindFirstChild("HR_CATCH")
	if not p then
		p = Instance.new("Part")
		p.Name = "HR_CATCH"
		p.Parent = workspace
	end
	if p:IsA("BasePart") then
		p.Anchored = true
		p.Size = Vector3.new(280, 8, 300)
		p.CFrame = CFrame.new(0, 0, 40)
		p.Material = Enum.Material.Slate
		p.Color = Color3.fromRGB(48, 44, 40)
		p.CanCollide = true
	end
end

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterGui = game:GetService("StarterGui")

local Config = require(game.ReplicatedStorage.Shared.Config)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local Shop = require(game.ReplicatedStorage.Shared.Shop)
local World = require(script.Parent.Services.World)
local Data = require(script.Parent.Services.Data)
local Monetization = require(script.Parent.Services.Monetization)
local Round = require(script.Parent.Services.Round)
local Boards = require(script.Parent.Services.Boards)

Remotes.init()

pcall(function()
	workspace.Gravity = 196.2
	workspace.FallenPartsDestroyHeight = -2000
	workspace.StreamingEnabled = false
end)

World.applyLighting()
World.build()

local function sinkDefaults()
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst.Name == "Baseplate" and inst:IsA("BasePart") then
			inst.CFrame = CFrame.new(0, -400, 0)
			inst.Anchored = true
			inst.CanCollide = false
			inst.Transparency = 1
		elseif inst:IsA("SpawnLocation") and inst.Name ~= "LobbySpawn" then
			inst.Enabled = false
			inst.Neutral = false
			inst.CanCollide = false
			inst.Transparency = 1
			inst.CFrame = CFrame.new(0, -400, 0)
		end
	end
end

local function putOnFloor(char: Model)
	if not workspace:FindFirstChild("Highrise") then
		World.build()
	end
	local dest = CFrame.new(World.LobbySpawn)
	pcall(function()
		char:PivotTo(dest)
	end)
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		hrp.CFrame = dest
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end
end

local function hookWorldPrompts()
	local map = workspace:FindFirstChild("Highrise")
	if not map then
		return
	end
	local clerk = map:FindFirstChild("ShopClerk")
	local shopPrompt = clerk and clerk:FindFirstChild("OpenShop")
	if shopPrompt and shopPrompt:IsA("ProximityPrompt") and not shopPrompt:GetAttribute("Hooked") then
		shopPrompt:SetAttribute("Hooked", true)
		shopPrompt.Triggered:Connect(function(plr)
			Remotes.get("OpenShop"):FireClient(plr)
		end)
	end
	for _, t in ipairs(World.tasks()) do
		local prompt = t:FindFirstChildOfClass("ProximityPrompt")
		if prompt and not prompt:GetAttribute("Hooked") then
			prompt:SetAttribute("Hooked", true)
			prompt.Triggered:Connect(function(plr)
				Round.doTask(plr, t)
			end)
		end
	end
end

sinkDefaults()
hookWorldPrompts()

task.spawn(function()
	while true do
		if not workspace:FindFirstChild("Highrise") then
			pcall(World.build)
		end
		local catch = workspace:FindFirstChild("HR_CATCH")
		if not (catch and catch:IsA("BasePart")) then
			local p = Instance.new("Part")
			p.Name = "HR_CATCH"
			p.Anchored = true
			p.Size = Vector3.new(280, 8, 300)
			p.CFrame = CFrame.new(0, 0, 40)
			p.Material = Enum.Material.Slate
			p.Color = Color3.fromRGB(48, 44, 40)
			p.Parent = workspace
		end
		sinkDefaults()
		hookWorldPrompts()
		for _, plr in ipairs(Players:GetPlayers()) do
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") and hrp.Position.Y < 3 then
				putOnFloor(char)
			end
		end
		task.wait(0.25)
	end
end)

for _, p in ipairs(Players:GetPlayers()) do
	if p.Character then
		putOnFloor(p.Character)
	end
	p.CharacterAdded:Connect(putOnFloor)
end
Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(putOnFloor)
	if p.Character then
		putOnFloor(p.Character)
	end
end)

StarterPlayer.CameraMaxZoomDistance = 22
StarterPlayer.CameraMinZoomDistance = 8
StarterPlayer.EnableMouseLockOption = true
StarterPlayer.CharacterWalkSpeed = Config.WalkLobby
StarterPlayer.CharacterJumpPower = Config.JumpPower
StarterGui.ResetPlayerGuiOnSpawn = false

Monetization.start()
Boards.start()

local function pushProfile(player: Player)
	Remotes.get("Profile"):FireClient(player, Data.get(player.UserId), Monetization.snapshot(player))
end

local function setupPlayer(player: Player)
	player.RespawnTime = 2
	Data.load(player)
	if not player:FindFirstChild("leaderstats") then
		local ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = player
		local coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Value = Data.get(player.UserId).coins
		coins.Parent = ls
		local wins = Instance.new("IntValue")
		wins.Name = "Wins"
		wins.Value = Data.get(player.UserId).wins
		wins.Parent = ls
		local robux = Instance.new("IntValue")
		robux.Name = "Robux"
		robux.Value = Data.get(player.UserId).robuxSpent
		robux.Parent = ls
		player:GetAttributeChangedSignal("Coins"):Connect(function()
			coins.Value = player:GetAttribute("Coins") or 0
		end)
		player:GetAttributeChangedSignal("Wins"):Connect(function()
			wins.Value = player:GetAttribute("Wins") or 0
		end)
		player:GetAttributeChangedSignal("RobuxSpent"):Connect(function()
			robux.Value = player:GetAttribute("RobuxSpent") or 0
		end)
	end
	pushProfile(player)
end

for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, p)
end
Players.PlayerAdded:Connect(setupPlayer)

Remotes.get("ShopBuy").OnServerEvent:Connect(function(player, id)
	if typeof(id) ~= "string" then
		return
	end
	local item = Shop.get(id)
	if not item then
		return
	end
	local profile = Data.get(player.UserId)
	if Data.owns(profile, id) then
		return
	end
	if item.vip then
		if not Monetization.ownsPass(player, "vip") then
			Remotes.get("Notify"):FireClient(player, "VIP required.")
			return
		end
		Data.grant(profile, id)
		pushProfile(player)
		return
	end
	if profile.coins < item.price then
		Remotes.get("Notify"):FireClient(player, "Not enough coins.")
		return
	end
	profile.coins -= item.price
	player:SetAttribute("Coins", profile.coins)
	Data.grant(profile, id)
	profile.equipped[item.slot] = id
	pushProfile(player)
	Remotes.get("Notify"):FireClient(player, "Purchased " .. item.name)
end)

Remotes.get("ShopEquip").OnServerEvent:Connect(function(player, id)
	if typeof(id) ~= "string" then
		return
	end
	local item = Shop.get(id)
	if not item then
		return
	end
	local profile = Data.get(player.UserId)
	if not Data.owns(profile, id) then
		if item.vip and Monetization.ownsPass(player, "vip") then
			Data.grant(profile, id)
		else
			return
		end
	end
	profile.equipped[item.slot] = id
	pushProfile(player)
end)

Round.start()
print("[Highrise] live. lighting=", Lighting.ClockTime, "map=", workspace:FindFirstChild("Highrise") ~= nil, "build=", Config.BuildId)
