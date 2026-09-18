--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Config = require(game.ReplicatedStorage.Shared.Config)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local Shop = require(game.ReplicatedStorage.Shared.Shop)
local Data = require(script.Parent.Data)

local Monetization = {}
local receiptLock: { [string]: boolean } = {}

local function findProduct(keyOrId: any)
	for _, p in ipairs(Config.Products) do
		if p.key == keyOrId or p.id == keyOrId then
			return p
		end
	end
	return nil
end

local function findPass(keyOrId: any)
	for _, p in ipairs(Config.Passes) do
		if p.key == keyOrId or p.id == keyOrId then
			return p
		end
	end
	return nil
end

function Monetization.ownsPass(player: Player, key: string): boolean
	if player:GetAttribute("Dev_" .. key) == true then
		return true
	end
	local pass = findPass(key)
	if not pass or pass.id <= 0 then
		return false
	end
	local ok, owned = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
	end)
	return ok and owned == true
end

function Monetization.coinMultiplier(player: Player): number
	local m = 1
	if Monetization.ownsPass(player, "vip") then
		m = math.max(m, Config.Coins.VipMultiplier)
	end
	if Monetization.ownsPass(player, "double_coins") then
		m *= Config.Coins.DoubleCoinsPass
	end
	return m
end

function Monetization.sheriffWeight(player: Player): number
	return if Monetization.ownsPass(player, "sheriff_luck") then 1.35 else 1
end

local function grantProduct(player: Player, product): boolean
	if not product then
		return false
	end
	Data.addCoins(player, product.coins)
	Data.addRobux(player, product.robux or 0)
	Remotes.get("Notify"):FireClient(player, "Purchased " .. product.name)
	Remotes.get("Profile"):FireClient(player, Data.get(player.UserId), Monetization.snapshot(player))
	return true
end

local function grantPass(player: Player, pass)
	player:SetAttribute("Dev_" .. pass.key, true)
	Data.addRobux(player, pass.robux or 0)
	if pass.key == "vip" then
		local profile = Data.get(player.UserId)
		Data.grant(profile, "suit_gold")
		profile.equipped.suit = "suit_gold"
	end
	Remotes.get("Notify"):FireClient(player, "Unlocked " .. pass.name)
	Remotes.get("Profile"):FireClient(player, Data.get(player.UserId), Monetization.snapshot(player))
end

function Monetization.snapshot(player: Player): { [string]: boolean }
	local s: { [string]: boolean } = {}
	for _, pass in ipairs(Config.Passes) do
		s[pass.key] = Monetization.ownsPass(player, pass.key)
	end
	return s
end

function Monetization.prompt(player: Player, key: string)
	local product = findProduct(key)
	if product then
		if product.id <= 0 then
			-- Studio / unset IDs: grant so Play Solo can test the full loop.
			grantProduct(player, product)
			return
		end
		MarketplaceService:PromptProductPurchase(player, product.id)
		return
	end
	local pass = findPass(key)
	if pass then
		if pass.id <= 0 then
			grantPass(player, pass)
			return
		end
		MarketplaceService:PromptGamePassPurchase(player, pass.id)
	end
end

function Monetization.start()
	MarketplaceService.ProcessReceipt = function(receipt)
		local id = receipt.PurchaseId
		if receiptLock[id] then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local product = findProduct(receipt.ProductId)
		if not product then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if grantProduct(player, product) then
			receiptLock[id] = true
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, bought)
		if not bought then
			return
		end
		local pass = findPass(passId)
		if pass then
			grantPass(player, pass)
		end
	end)

	Remotes.get("RobuxBuy").OnServerEvent:Connect(function(player, key)
		if typeof(key) ~= "string" then
			return
		end
		Monetization.prompt(player, key)
	end)
end

-- apply VIP nametag
function Monetization.applyNametag(player: Player)
	local char = player.Character
	if not char then
		return
	end
	local head = char:FindFirstChild("Head")
	if not head then
		return
	end
	local old = head:FindFirstChild("VipTag")
	if old then
		old:Destroy()
	end
	if not Monetization.ownsPass(player, "vip") then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "VipTag"
	gui.Size = UDim2.fromOffset(80, 18)
	gui.StudsOffset = Vector3.new(0, 2.4, 0)
	gui.AlwaysOnTop = true
	gui.Parent = head
	local lab = Instance.new("TextLabel")
	lab.BackgroundTransparency = 1
	lab.Size = UDim2.fromScale(1, 1)
	lab.Font = Enum.Font.GothamBold
	lab.Text = "VIP"
	lab.TextColor3 = Shop.get("suit_gold").color
	lab.TextScaled = true
	lab.Parent = gui
end

return Monetization
