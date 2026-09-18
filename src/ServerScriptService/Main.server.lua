--!strict
local Players = game:GetService("Players")

local Config = require(game.ReplicatedStorage.Shared.Config)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local Shop = require(game.ReplicatedStorage.Shared.Shop)
local Data = require(script.Parent.Services.Data)
local Monetization = require(script.Parent.Services.Monetization)
local Round = require(script.Parent.Services.Round)

Remotes.init()
Monetization.start()

workspace:WaitForChild("Highrise", 30)

local function pushProfile(player: Player)
	Remotes.get("Profile"):FireClient(player, Data.get(player.UserId), Monetization.snapshot(player))
end

local function setupPlayer(player: Player)
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
print("[Highrise] " .. Config.Title .. " live.")
