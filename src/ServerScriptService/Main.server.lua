--!strict
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

Remotes.init()

pcall(function()
	workspace.Gravity = 196.2
	workspace.FallenPartsDestroyHeight = -500
	workspace.StreamingEnabled = false
end)

-- Floor FIRST. Never delete the Baseplate until there is something to stand on.
World.applyLighting()
World.build()

local function wipeDefaults()
	local kill = {}
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst.Name == "Baseplate" or inst.Name == "Spawn" then
			table.insert(kill, inst)
		elseif inst:IsA("SpawnLocation") and inst.Name ~= "LobbySpawn" then
			table.insert(kill, inst)
		end
	end
	for _, inst in ipairs(kill) do
		inst:Destroy()
	end
end
wipeDefaults()

local function putOnFloor(char: Model)
	local dest = CFrame.new(World.LobbySpawn)
	pcall(function()
		char:PivotTo(dest)
	end)
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		hrp.CFrame = dest
		hrp.AssemblyLinearVelocity = Vector3.zero
	end
end

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
		player:GetAttributeChangedSignal("Coins"):Connect(function()
			coins.Value = player:GetAttribute("Coins") or 0
		end)
		player:GetAttributeChangedSignal("Wins"):Connect(function()
			wins.Value = player:GetAttribute("Wins") or 0
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
