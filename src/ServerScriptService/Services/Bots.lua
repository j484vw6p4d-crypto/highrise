--!strict
local Players = game:GetService("Players")

local World = require(script.Parent.World)

local Bots = {}
local models: { Model } = {}
local running = false

local NAMES = { "Adler", "Voss", "Quinn", "Marlowe", "Sable", "Ives" }
local COLORS = {
	Color3.fromRGB(16, 16, 18),
	Color3.fromRGB(228, 220, 206),
	Color3.fromRGB(78, 22, 32),
	Color3.fromRGB(18, 28, 48),
	Color3.fromRGB(40, 36, 42),
}

local function randomWp(): Vector3
	local w = World.waypoints()
	if #w == 0 then
		return World.LobbySpawn
	end
	return World.safe(w[math.random(1, #w)])
end

local function limb(model: Model, name: string, size: Vector3, cf: CFrame, color: Color3): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Massless = true
	p.CanCollide = name == "HumanoidRootPart"
	p.Anchored = false
	p.Parent = model
	return p
end

local function weld(a: BasePart, b: BasePart, c0: CFrame)
	local w = Instance.new("Weld")
	w.Part0 = a
	w.Part1 = b
	w.C0 = c0
	w.Parent = a
end

local function makeDummy(name: string, bodyColor: Color3, pos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = name
	local cf = CFrame.new(World.safe(pos))
	local hrp = limb(model, "HumanoidRootPart", Vector3.new(2, 2, 1), cf, bodyColor)
	hrp.Transparency = 1
	local torso = limb(model, "Torso", Vector3.new(2, 2, 1), cf, bodyColor)
	local head = limb(model, "Head", Vector3.new(1.2, 1.2, 1.2), cf * CFrame.new(0, 1.6, 0), Color3.fromRGB(230, 210, 190))
	local la = limb(model, "Left Arm", Vector3.new(1, 2, 1), cf * CFrame.new(-1.5, 0, 0), Color3.fromRGB(230, 210, 190))
	local ra = limb(model, "Right Arm", Vector3.new(1, 2, 1), cf * CFrame.new(1.5, 0, 0), Color3.fromRGB(230, 210, 190))
	local ll = limb(model, "Left Leg", Vector3.new(1, 2, 1), cf * CFrame.new(-0.5, -2, 0), Color3.fromRGB(20, 20, 24))
	local rl = limb(model, "Right Leg", Vector3.new(1, 2, 1), cf * CFrame.new(0.5, -2, 0), Color3.fromRGB(20, 20, 24))
	weld(hrp, torso, CFrame.new())
	weld(hrp, head, CFrame.new(0, 1.6, 0))
	weld(hrp, la, CFrame.new(-1.5, 0, 0))
	weld(hrp, ra, CFrame.new(1.5, 0, 0))
	weld(hrp, ll, CFrame.new(-0.5, -2, 0))
	weld(hrp, rl, CFrame.new(0.5, -2, 0))
	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R6
	hum.MaxHealth = 100
	hum.Health = 100
	hum.WalkSpeed = 14
	hum.JumpPower = 0
	hum.HipHeight = 2
	hum.DisplayName = name
	hum.Parent = model
	model.PrimaryPart = hrp
	return model
end

function Bots.clear()
	for _, m in ipairs(models) do
		if m.Parent then
			m:Destroy()
		end
	end
	table.clear(models)
end

function Bots.list(): { Model }
	return models
end

function Bots.spawn(count: number)
	Bots.clear()
	local parent = workspace:FindFirstChild("Highrise") or workspace
	for i = 1, count do
		local color = COLORS[((i - 1) % #COLORS) + 1]
		local spawnList = World.spawns()
		local pos = if #spawnList > 0 then spawnList[((i - 1) % #spawnList) + 1] else World.LobbySpawn
		local model = makeDummy("Guest " .. NAMES[((i - 1) % #NAMES) + 1], color, pos)
		model:SetAttribute("IsBot", true)
		model:SetAttribute("BotIndex", i)
		model.Parent = parent
		table.insert(models, model)
	end
end

function Bots.startBrain(getRole: (Model | Player) -> string, attack: (any, any) -> (), shoot: (any, any) -> ())
	running = true
	task.spawn(function()
		while running do
			for _, model in ipairs(models) do
				if not model.Parent then
					continue
				end
				local hum = model:FindFirstChildOfClass("Humanoid")
				local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
				if not hum or hum.Health <= 0 or not hrp then
					continue
				end
				if not World.contains(hrp.Position) then
					hrp.CFrame = CFrame.new(World.safe(hrp.Position))
					hrp.AssemblyLinearVelocity = Vector3.zero
				end
				local role = getRole(model)
				local targetPos = randomWp()
				local nearest: Model | Player? = nil
				local nearestDist = 1e9

				local function consider(inst: Instance, pos: Vector3)
					if inst == model then
						return
					end
					local d = (pos - hrp.Position).Magnitude
					if d < nearestDist then
						nearestDist = d
						nearest = inst :: any
					end
				end

				for _, other in ipairs(models) do
					if other ~= model and other.Parent then
						local oh = other:FindFirstChildOfClass("Humanoid")
						local op = other:FindFirstChild("HumanoidRootPart") :: BasePart?
						if oh and oh.Health > 0 and op then
							consider(other, op.Position)
						end
					end
				end
				for _, plr in ipairs(Players:GetPlayers()) do
					local ch = plr.Character
					local oh = ch and ch:FindFirstChildOfClass("Humanoid")
					local op = ch and ch:FindFirstChild("HumanoidRootPart") :: BasePart?
					if oh and oh.Health > 0 and op then
						consider(plr, op.Position)
					end
				end

				if role == "Murderer" and nearest and nearestDist < 50 then
					local tpart = if typeof(nearest) == "Instance" and nearest:IsA("Player")
						then nearest.Character and nearest.Character:FindFirstChild("HumanoidRootPart")
						elseif typeof(nearest) == "Instance" then (nearest :: Model):FindFirstChild("HumanoidRootPart")
						else nil
					if tpart then
						targetPos = World.safe((tpart :: BasePart).Position)
						if nearestDist < 7 then
							attack(model, nearest)
						end
					end
				elseif role == "Sheriff" and nearest and nearestDist < 55 then
					local nRole = getRole(nearest)
					if nRole == "Murderer" then
						local tpart = if typeof(nearest) == "Instance" and nearest:IsA("Player")
							then nearest.Character and nearest.Character:FindFirstChild("HumanoidRootPart")
							elseif typeof(nearest) == "Instance" then (nearest :: Model):FindFirstChild("HumanoidRootPart")
							else nil
						if tpart then
							targetPos = World.safe((tpart :: BasePart).Position)
							if nearestDist < 45 then
								shoot(model, nearest)
							end
						end
					end
				elseif role == "Innocent" and nearest and nearestDist < 16 then
					local nRole = getRole(nearest)
					if nRole == "Murderer" then
						local nhrp: BasePart? = nil
						if typeof(nearest) == "Instance" and nearest:IsA("Player") then
							local ch = nearest.Character
							nhrp = ch and (ch:FindFirstChild("HumanoidRootPart") :: BasePart?)
						elseif typeof(nearest) == "Instance" then
							nhrp = (nearest :: Model):FindFirstChild("HumanoidRootPart") :: BasePart?
						end
						if nhrp then
							local away = hrp.Position - nhrp.Position
							if away.Magnitude > 0.2 then
								targetPos = World.safe(hrp.Position + away.Unit * 20)
							end
						end
					end
				end

				pcall(function()
					hum:MoveTo(World.safe(targetPos))
				end)
			end
			task.wait(0.9)
		end
	end)
end

function Bots.stop()
	running = false
end

return Bots
