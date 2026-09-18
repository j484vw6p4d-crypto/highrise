--!strict
local Config = {
	Title = "Highrise",
	BuildId = "HR-15",
	Tagline = "Black-tie murder on the 80th floor.",

	LobbySeconds = 22,
	RevealSeconds = 5,
	RoundSeconds = 140,
	GraceSeconds = 8,
	BotFillTo = 4,
	MinPlayersToStart = 1,

	WalkLobby = 16,
	WalkInnocent = 16,
	WalkSheriff = 17,
	WalkMurderer = 18,
	JumpPower = 40,

	KnifeRange = 7.5,
	KnifeCooldown = 0.8,
	GunRange = 180,
	GunReload = 3.2,
	GunSpread = 0.012,

	Coins = {
		WinMurderer = 80,
		WinInnocent = 45,
		WinSheriff = 70,
		Kill = 25,
		Survive = 12,
		Task = 8,
		VipMultiplier = 2,
		DoubleCoinsPass = 2,
	},

	Products = {
		{ key = "coins_800", name = "800 Coins", coins = 800, robux = 79, id = 0 },
		{ key = "coins_4500", name = "4,500 Coins", coins = 4500, robux = 399, id = 0 },
		{ key = "coins_12000", name = "12,000 Coins", coins = 12000, robux = 799, id = 0 },
	},
	Passes = {
		{
			key = "vip",
			name = "VIP",
			robux = 399,
			id = 0,
			perks = "2x coins, gold nametag, Gilded tuxedo",
		},
		{
			key = "double_coins",
			name = "Double Coins",
			robux = 199,
			id = 0,
			perks = "Permanent 2x coin multiplier",
		},
		{
			key = "sheriff_luck",
			name = "Sheriff Luck",
			robux = 249,
			id = 0,
			perks = "+35% chance to be Sheriff",
		},
	},

	DataStoreName = "Highrise_v1",
	DataStoreKey = "p_",
}

return Config
