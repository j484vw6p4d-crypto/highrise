--!strict
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Config = require(game.ReplicatedStorage.Shared.Config)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local Shop = require(game.ReplicatedStorage.Shared.Shop)
local World = require(script.Parent.World)
local Data = require(script.Parent.Data)
local Monetization = require(script.Parent.Monetization)
local Bots = require(script.Parent.Bots)

type Actor = Player | Model

local Round = {}

local phase = "Lobby"
local deadline = 0
local roles: { [string]: string } = {}
local alive: { [string]: boolean } = {}
local gunReady: { [string]: boolean } = {}
local knifeCd: { [string]: number } = {}
local gunDropped: BasePart? = nil
local sheriffId: string? = nil
local murdererId: string? = nil
local weaponsAt = 0
local dyingLock: { [string]: boolean } = {}

local function keyOf(actor: Actor): string
	if typeof(actor) == "Instance" and actor:IsA("Player") then
		return "p" .. actor.UserId
	end
	return "b" .. tostring((actor :: Model):GetAttribute("BotIndex") or actor.Name)
end

local function isPlayer(actor: Actor): boolean
	return typeof(actor) == "Instance" and actor:IsA("Player")
end

local function characterOf(actor: Actor): Model?
	if isPlayer(actor) then
		return (actor :: Player).Character
	end
	return actor :: Model
end

local function hrpOf(actor: Actor): BasePart?
	local c = characterOf(actor)
	return c and (c:FindFirstChild("HumanoidRootPart") :: BasePart?)
end

local function humOf(actor: Actor): Humanoid?
	local c = characterOf(actor)
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function actorFromKey(k: string): Actor?
	if string.sub(k, 1, 1) == "p" then
		local id = tonumber(string.sub(k, 2))
		if id then
			return Players:GetPlayerByUserId(id)
		end
	end
	for _, m in ipairs(Bots.list()) do
		if keyOf(m) == k then
			return m
		end
	end
	return nil
end

local function allActors(): { Actor }
	local list: { Actor } = {}
	for _, p in ipairs(Players:GetPlayers()) do
		table.insert(list, p)
	end
	for _, m in ipairs(Bots.list()) do
		table.insert(list, m)
	end
	return list
end

local function remaining(): number
	return math.max(0, math.ceil(deadline - os.clock()))
end

local function aliveCount(): number
	local n = 0
	for _, on in pairs(alive) do
		if on then
			n += 1
		end
	end
	return n
end

local function objectiveFor(player: Player): string
	if phase == "Lobby" then
		return "Shop, then wait for the night to start."
	end
	if phase == "Reveal" then
		return "Remember your role."
	end
	if phase == "Over" then
		return "Next night incoming."
	end
	if os.clock() < weaponsAt then
		return "Grace — weapons live in a moment."
	end
	local role = roles[keyOf(player)]
	if role == "Murderer" then
		return "Knife the guests. Don't get shot."
	end
	if role == "Sheriff" then
		return "Shoot only the murderer. One round."
	end
	return "Survive. Finish tasks. Pick up the gun if it drops."
end

local function pushState(extra: { [string]: any }?, toPlayer: Player?)
	local payload = {
		phase = phase,
		remaining = remaining(),
		endsAt = os.time() + remaining(),
		alive = alive,
		aliveCount = aliveCount(),
		rolesHidden = phase ~= "Reveal" and phase ~= "Round" and phase ~= "Over",
		title = Config.Title,
		grace = os.clock() < weaponsAt,
	}
	if extra then
		for k, v in extra do
			payload[k] = v
		end
	end
	local function send(p: Player)
		payload.objective = objectiveFor(p)
		Remotes.get("RoundState"):FireClient(p, payload)
		local k = keyOf(p)
		Remotes.get("RoleReveal"):FireClient(p, roles[k], phase)
	end
	if toPlayer then
		send(toPlayer)
		return
	end
	for _, p in ipairs(Players:GetPlayers()) do
		send(p)
	end
end

local function applySuit(actor: Actor)
	local char = characterOf(actor)
	if not char then
		return
	end
	local color = Color3.fromRGB(16, 16, 18)
	if isPlayer(actor) then
		local prof = Data.get((actor :: Player).UserId)
		local item = Shop.get(prof.equipped.suit or "suit_black")
		if item then
			color = item.color
		end
	end
	for _, n in ipairs({ "Torso", "UpperTorso", "LowerTorso" }) do
		local p = char:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			p.Color = color
		end
	end
end

local function weldWeapon(actor: Actor, slot: string)
	local char = characterOf(actor)
	if not char then
		return
	end
	local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm") or char:FindFirstChild("HumanoidRootPart")
	if not hand or not hand:IsA("BasePart") then
		return
	end
	local old = char:FindFirstChild("HeldWeapon")
	if old then
		old:Destroy()
	end
	local k = keyOf(actor)
	local role = roles[k]
	if role ~= "Murderer" and role ~= "Sheriff" then
		return
	end
	local color = if role == "Murderer" then Color3.fromRGB(196, 196, 204) else Color3.fromRGB(212, 175, 110)
	if isPlayer(actor) then
		local prof = Data.get((actor :: Player).UserId)
		local id = if role == "Murderer" then prof.equipped.knife else prof.equipped.gun
		local item = Shop.get(id)
		if item then
			color = item.color
		end
	end
	local w = Instance.new("Part")
	w.Name = "HeldWeapon"
	w.Massless = true
	w.CanCollide = false
	w.Material = Enum.Material.Metal
	w.Color = color
	w.Size = if role == "Murderer" then Vector3.new(0.25, 0.2, 2.2) else Vector3.new(0.35, 0.35, 1.6)
	w.Parent = char
	local weld = Instance.new("Weld")
	weld.Part0 = hand
	weld.Part1 = w
	weld.C0 = CFrame.new(0, -0.2, -1.1)
	weld.Parent = w
end

local function teleport(actor: Actor, pos: Vector3)
	local dest = CFrame.new(World.safe(pos))
	local char = characterOf(actor)
	local hrp = hrpOf(actor)
	if char then
		pcall(function()
			char:PivotTo(dest)
		end)
	end
	if not hrp then
		return
	end
	if isPlayer(actor) then
		hrp.Anchored = true
	end
	hrp.CFrame = dest
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	if isPlayer(actor) then
		task.delay(0.12, function()
			if hrp.Parent then
				if hrp.Position.Y < 3 then
					hrp.CFrame = dest
				end
				hrp.Anchored = false
			end
		end)
	end
end

local function setSpeed(actor: Actor)
	local hum = humOf(actor)
	if not hum then
		return
	end
	local k = keyOf(actor)
	local role = roles[k]
	if role == "Murderer" then
		hum.WalkSpeed = Config.WalkMurderer
	elseif role == "Sheriff" then
		hum.WalkSpeed = Config.WalkSheriff
	elseif phase == "Round" then
		hum.WalkSpeed = Config.WalkInnocent
	else
		hum.WalkSpeed = Config.WalkLobby
	end
	hum.JumpPower = Config.JumpPower
	pcall(function()
		hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	end)
end

local function dropGun(at: Vector3)
	if gunDropped then
		gunDropped:Destroy()
	end
	local p = Instance.new("Part")
	p.Name = "DroppedGun"
	p.Size = Vector3.new(0.5, 0.4, 2)
	p.Color = Color3.fromRGB(212, 175, 110)
	p.Material = Enum.Material.Metal
	p.Anchored = true
	p.Position = at + Vector3.new(0, 1.4, 0)
	p.Parent = workspace:FindFirstChild("Highrise") or workspace
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick up revolver"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 10
	prompt.Parent = p
	prompt.Triggered:Connect(function(player)
		Round.pickupGun(player)
	end)
	gunDropped = p
end

local function kill(victim: Actor, killer: Actor?)
	local k = keyOf(victim)
	if not alive[k] then
		return
	end
	alive[k] = false
	local hum = humOf(victim)
	local hrp = hrpOf(victim)
	if hum then
		hum.Health = 0
	end
	if roles[k] == "Sheriff" and hrp then
		dropGun(hrp.Position)
		sheriffId = nil
	end
	if isPlayer(victim) then
		Remotes.get("Notify"):FireClient(victim :: Player, "You were killed.")
	end
	if killer and isPlayer(killer) then
		local prof = Data.get((killer :: Player).UserId)
		prof.kills += 1
		Data.addCoins(killer :: Player, Config.Coins.Kill * Monetization.coinMultiplier(killer :: Player))
	end
	Remotes.get("Notify"):FireAllClients((if isPlayer(victim) then (victim :: Player).DisplayName else (victim :: Model).Name) .. " has fallen.")
	pushState()
	Round.checkWin()
end

function Round.getRole(actor: Actor): string
	return roles[keyOf(actor)] or "Innocent"
end

function Round.checkWin()
	if phase ~= "Round" then
		return
	end
	local murdAlive = murdererId ~= nil and alive[murdererId] == true
	local others = 0
	for k, on in pairs(alive) do
		if on and k ~= murdererId then
			others += 1
		end
	end
	if not murdAlive then
		Round.endRound("Innocents")
	elseif others <= 0 then
		Round.endRound("Murderer")
	end
end

function Round.endRound(winner: string)
	if phase == "Over" then
		return
	end
	phase = "Over"
	deadline = os.clock() + 8
	Bots.stop()
	for k, on in pairs(alive) do
		local actor = actorFromKey(k)
		if actor and isPlayer(actor) and on then
			local plr = actor :: Player
			local prof = Data.get(plr.UserId)
			local role = roles[k]
			local pay = Config.Coins.Survive
			if winner == "Murderer" and role == "Murderer" then
				pay = Config.Coins.WinMurderer
				prof.wins += 1
			elseif winner == "Innocents" and role ~= "Murderer" then
				pay = if role == "Sheriff" then Config.Coins.WinSheriff else Config.Coins.WinInnocent
				prof.wins += 1
			end
			Data.addCoins(plr, pay * Monetization.coinMultiplier(plr))
			plr:SetAttribute("Wins", prof.wins)
			Remotes.get("Profile"):FireClient(plr, prof, Monetization.snapshot(plr))
		end
	end
	pushState({ winner = winner })
end

function Round.pickupGun(player: Player)
	if phase ~= "Round" then
		return
	end
	local k = keyOf(player)
	if not alive[k] or roles[k] == "Murderer" then
		return
	end
	if not gunDropped then
		return
	end
	local hrp = hrpOf(player)
	if not hrp or (hrp.Position - gunDropped.Position).Magnitude > 14 then
		return
	end
	roles[k] = "Sheriff"
	sheriffId = k
	gunReady[k] = true
	gunDropped:Destroy()
	gunDropped = nil
	weldWeapon(player, "gun")
	setSpeed(player)
	Remotes.get("RoleReveal"):FireClient(player, "Sheriff", phase)
	Remotes.get("Notify"):FireClient(player, "You picked up the revolver.")
	pushState()
end

function Round.attack(attacker: Actor, targetHint: any)
	if phase ~= "Round" then
		return
	end
	if os.clock() < weaponsAt then
		return
	end
	local ak = keyOf(attacker)
	if not alive[ak] then
		return
	end
	local role = roles[ak]
	local ahrp = hrpOf(attacker)
	if not ahrp then
		return
	end
	local now = os.clock()

	local function nearestVictim(maxRange: number, needLook: boolean): Actor?
		local best: Actor? = nil
		local bestD = maxRange
		local look = ahrp.CFrame.LookVector
		for _, other in ipairs(allActors()) do
			local ok = keyOf(other)
			if ok == ak or not alive[ok] then
				continue
			end
			local ohrp = hrpOf(other)
			if not ohrp then
				continue
			end
			local offset = ohrp.Position - ahrp.Position
			local d = offset.Magnitude
			if d > bestD then
				continue
			end
			if needLook then
				local dir = offset.Unit
				if look:Dot(dir) < 0.55 then
					continue
				end
			end
			best = other
			bestD = d
		end
		return best
	end

	if role == "Murderer" then
		if (knifeCd[ak] or 0) > now then
			return
		end
		knifeCd[ak] = now + Config.KnifeCooldown
		local vic = nearestVictim(Config.KnifeRange, false)
		Remotes.get("AttackFx"):FireAllClients("knife", ahrp.Position, ahrp.CFrame.LookVector)
		if vic then
			kill(vic, attacker)
		end
		return
	end

	if role == "Sheriff" then
		if gunReady[ak] == false then
			return
		end
		gunReady[ak] = false
		Remotes.get("AttackFx"):FireAllClients("gun", ahrp.Position, ahrp.CFrame.LookVector)
		local vic = nearestVictim(Config.GunRange, true)
		task.delay(Config.GunReload, function()
			if roles[ak] == "Sheriff" and alive[ak] then
				gunReady[ak] = true
			end
		end)
		if not vic then
			return
		end
		if roles[keyOf(vic)] == "Innocent" or roles[keyOf(vic)] == "Sheriff" then
			-- MM2: shooting an innocent kills the sheriff.
			kill(attacker, nil)
			return
		end
		kill(vic, attacker)
	end
end

function Round.doTask(player: Player, part: BasePart)
	if phase ~= "Round" then
		return
	end
	local k = keyOf(player)
	if not alive[k] or roles[k] == "Murderer" then
		return
	end
	local hrp = hrpOf(player)
	if not hrp or (hrp.Position - part.Position).Magnitude > 14 then
		return
	end
	if player:GetAttribute("Task_" .. part.Name) then
		return
	end
	player:SetAttribute("Task_" .. part.Name, true)
	Data.addCoins(player, Config.Coins.Task * Monetization.coinMultiplier(player))
	Remotes.get("Notify"):FireClient(player, "Task complete.")
	Remotes.get("Profile"):FireClient(player, Data.get(player.UserId), Monetization.snapshot(player))
end

function Round.assignRoles()
	table.clear(roles)
	table.clear(alive)
	table.clear(gunReady)
	table.clear(knifeCd)
	local actors = allActors()
	if #actors == 0 then
		return
	end
	local weighted: { Actor } = {}
	for _, a in ipairs(actors) do
		local w = 1
		if isPlayer(a) then
			w = Monetization.sheriffWeight(a :: Player)
		end
		local copies = math.max(1, math.floor(w * 100))
		for _ = 1, math.min(copies, 135) do
			table.insert(weighted, a)
		end
		alive[keyOf(a)] = true
		roles[keyOf(a)] = "Innocent"
	end
	local sheriff = weighted[math.random(1, #weighted)]
	local murderer = actors[math.random(1, #actors)]
	local guard = 0
	while keyOf(murderer) == keyOf(sheriff) and #actors > 1 and guard < 12 do
		murderer = actors[math.random(1, #actors)]
		guard += 1
	end
	roles[keyOf(sheriff)] = "Sheriff"
	roles[keyOf(murderer)] = "Murderer"
	sheriffId = keyOf(sheriff)
	murdererId = keyOf(murderer)
	gunReady[sheriffId] = true
end

function Round.beginPlay()
	phase = "Reveal"
	deadline = os.clock() + Config.RevealSeconds
	Round.assignRoles()
	local spawns = World.spawns()
	local i = 1
	for _, actor in ipairs(allActors()) do
		local pos = if #spawns > 0 then spawns[((i - 1) % #spawns) + 1] else World.LobbySpawn
		teleport(actor, pos)
		applySuit(actor)
		weldWeapon(actor, "held")
		setSpeed(actor)
		local hum = humOf(actor)
		if hum then
			hum.WalkSpeed = 0
		end
		if isPlayer(actor) then
			Monetization.applyNametag(actor :: Player)
		end
		i += 1
	end
	weaponsAt = os.clock() + Config.RevealSeconds + Config.GraceSeconds
	pushState()
	task.delay(Config.RevealSeconds, function()
		if phase ~= "Reveal" then
			return
		end
		phase = "Round"
		deadline = os.clock() + Config.RoundSeconds
		for _, actor in ipairs(allActors()) do
			setSpeed(actor)
		end
		task.delay(Config.GraceSeconds, function()
			if phase == "Round" then
				Bots.startBrain(Round.getRole, Round.attack, Round.attack)
				pushState()
			end
		end)
		pushState()
	end)
end

function Round.lobby()
	phase = "Lobby"
	deadline = os.clock() + Config.LobbySeconds
	weaponsAt = 0
	table.clear(dyingLock)
	Bots.stop()
	pushState()
	local need = math.max(0, Config.BotFillTo - #Players:GetPlayers())
	pcall(function()
		Bots.spawn(need)
	end)
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			teleport(p, World.LobbySpawn)
			applySuit(p)
			setSpeed(p)
			Monetization.applyNametag(p)
		end
	end
	pushState()
	print("[Highrise] Lobby. remaining=", remaining(), "players=", #Players:GetPlayers(), "bots=", #Bots.list())
end

function Round.rescue()
	for _, p in ipairs(Players:GetPlayers()) do
		local hrp = hrpOf(p)
		if hrp and not World.contains(hrp.Position) then
			teleport(p, World.LobbySpawn)
		end
	end
	for _, m in ipairs(Bots.list()) do
		local hrp = m:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp and not World.contains(hrp.Position) then
			hrp.CFrame = CFrame.new(World.safe(hrp.Position))
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
	end
end

function Round.tick()
	Round.rescue()
	if os.clock() < deadline then
		return
	end
	if phase == "Lobby" then
		if #allActors() >= Config.MinPlayersToStart then
			Round.beginPlay()
		else
			deadline = os.clock() + Config.LobbySeconds
			pushState()
		end
	elseif phase == "Round" then
		Round.endRound("Innocents")
	elseif phase == "Over" then
		Round.lobby()
	end
end

function Round.start()
	local function bindHumanoid(player: Player, char: Model)
		local hum = char:WaitForChild("Humanoid", 5)
		if not hum or not hum:IsA("Humanoid") then
			return
		end
		hum.Died:Connect(function()
			local k = keyOf(player)
			if dyingLock[k] then
				return
			end
			if phase == "Round" and alive[k] then
				dyingLock[k] = true
				alive[k] = false
				if roles[k] == "Sheriff" then
					local hrp = hrpOf(player)
					if hrp then
						dropGun(hrp.Position)
					end
					sheriffId = nil
				end
				Remotes.get("Notify"):FireAllClients(player.DisplayName .. " has fallen.")
				pushState()
				Round.checkWin()
				task.delay(1, function()
					dyingLock[k] = false
				end)
			end
		end)
	end

	local function onCharacter(player: Player)
		task.wait(0.08)
		local char = player.Character
		if char then
			bindHumanoid(player, char)
		end
		teleport(player, World.LobbySpawn)
		if phase == "Round" then
			alive[keyOf(player)] = alive[keyOf(player)] == true
			if not alive[keyOf(player)] then
				roles[keyOf(player)] = roles[keyOf(player)] or "Innocent"
			end
		end
		applySuit(player)
		setSpeed(player)
		Monetization.applyNametag(player)
		if phase == "Round" or phase == "Reveal" then
			weldWeapon(player, "held")
		end
		pushState(nil, player)
	end

	local function hookPlayer(player: Player)
		player.CharacterAdded:Connect(function()
			onCharacter(player)
		end)
		if player.Character then
			task.spawn(onCharacter, player)
		end
	end

	for _, p in ipairs(Players:GetPlayers()) do
		hookPlayer(p)
	end
	Players.PlayerAdded:Connect(hookPlayer)

	Remotes.get("Attack").OnServerEvent:Connect(function(player)
		Round.attack(player)
	end)
	Remotes.get("TaskDo").OnServerEvent:Connect(function(player, name)
		if typeof(name) ~= "string" then
			return
		end
		for _, t in ipairs(World.tasks()) do
			if t.Name == name then
				Round.doTask(player, t)
				return
			end
		end
	end)
	Remotes.get("PickupGun").OnServerEvent:Connect(function(player)
		Round.pickupGun(player)
	end)
	Remotes.get("RequestState").OnServerEvent:Connect(function(player)
		pushState(nil, player)
		Remotes.get("Profile"):FireClient(player, Data.get(player.UserId), Monetization.snapshot(player))
	end)
	task.spawn(function()
		Round.lobby()
		local acc = 0
		while true do
			Round.tick()
			acc += 0.25
			if acc >= 1 then
				acc = 0
				pushState()
			end
			task.wait(0.25)
		end
	end)
end

return Round
