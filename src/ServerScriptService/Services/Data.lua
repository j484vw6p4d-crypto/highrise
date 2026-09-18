--!strict
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Config = require(game.ReplicatedStorage.Shared.Config)
local Shop = require(game.ReplicatedStorage.Shared.Shop)

export type Profile = {
	coins: number,
	wins: number,
	kills: number,
	owned: { string },
	equipped: { [string]: string },
}

local Data = {}
local cache: { [number]: Profile } = {}
local store = DataStoreService:GetDataStore(Config.DataStoreName)

local function fresh(): Profile
	local eq = Shop.defaults()
	return {
		coins = 0,
		wins = 0,
		kills = 0,
		owned = { "suit_black", "knife_steel", "gun_gold" },
		equipped = eq,
	}
end

function Data.get(userId: number): Profile
	if cache[userId] then
		return cache[userId]
	end
	return fresh()
end

function Data.owns(profile: Profile, id: string): boolean
	for _, x in ipairs(profile.owned) do
		if x == id then
			return true
		end
	end
	return false
end

function Data.grant(profile: Profile, id: string)
	if not Data.owns(profile, id) then
		table.insert(profile.owned, id)
	end
end

function Data.load(player: Player)
	local key = Config.DataStoreKey .. player.UserId
	local ok, data = pcall(function()
		return store:GetAsync(key)
	end)
	local p: Profile = fresh()
	if ok and typeof(data) == "table" then
		p.coins = data.coins or 0
		p.wins = data.wins or 0
		p.kills = data.kills or 0
		p.owned = data.owned or p.owned
		p.equipped = data.equipped or p.equipped
	end
	cache[player.UserId] = p
	player:SetAttribute("Coins", p.coins)
	player:SetAttribute("Wins", p.wins)
end

function Data.save(player: Player)
	local p = cache[player.UserId]
	if not p then
		return
	end
	local key = Config.DataStoreKey .. player.UserId
	pcall(function()
		store:SetAsync(key, p)
	end)
end

function Data.addCoins(player: Player, amount: number)
	local p = Data.get(player.UserId)
	p.coins += math.max(0, math.floor(amount))
	player:SetAttribute("Coins", p.coins)
end

Players.PlayerRemoving:Connect(function(player)
	Data.save(player)
	cache[player.UserId] = nil
end)

game:BindToClose(function()
	for _, plr in ipairs(Players:GetPlayers()) do
		Data.save(plr)
	end
end)

return Data
