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
	p.Anchored = true
	p.CanCollide = false
	p.Parent = model
	return p
end

local function makeDummy(name: string, bodyColor: Color3, pos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = name
	local stand = World.safe(pos)
	local cf = CFrame.new(stand)
	local hrp = limb(model, "HumanoidRootPart", Vector3.new(2, 2, 1), cf, bodyColor)
	hrp.Transparency = 1
	hrp.CanCollide = false
	limb(model, "Torso", Vector3.new(2, 2, 1), cf, bodyColor)
	limb(model, "Head", Vector3.new(1.2, 1.2, 1.2), cf * CFrame.new(0, 1.6, 0), Color3.fromRGB(230, 210, 190))
	limb(model, "Left Arm", Vector3.new(1, 2, 1), cf * CFrame.new(-1.5, 0, 0), Color3.fromRGB(230, 210, 190))
	limb(model, "Right Arm", Vector3.new(1, 2, 1), cf * CFrame.new(1.5, 0, 0), Color3.fromRGB(230, 210, 190))
	limb(model, "Left Leg", Vector3.new(1, 2, 1), cf * CFrame.new(-0.5, -2, 0), Color3.fromRGB(20, 20, 24))
	limb(model, "Right Leg", Vector3.new(1, 2, 1), cf * CFrame.new(0.5, -2, 0), Color3.fromRGB(20, 20, 24))
	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R6
	hum.MaxHealth = 100
	hum.Health = 100
	hum.WalkSpeed = 14
	hum.JumpPower = 0
	hum.DisplayName = name
	hum.Parent = model
	model.PrimaryPart = hrp
	model:SetAttribute("WalkTo", stand)
	return model
end

local function setModelCFrame(model: Model, cf: CFrame)
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local offset = cf * hrp.CFrame:Inverse()
	for _, ch in ipairs(model:GetChildren()) do
		if ch:IsA("BasePart") then
			ch.CFrame = offset * ch.CFrame
			ch.Anchored = true
			ch.AssemblyLinearVelocity = Vector3.zero
		end
	end
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
	local parent = workspace:FindFirstChild("HighriseMap") or workspace:FindFirstChild("Highrise") or workspace
	local spawnList = World.spawns()
	local fallback = {
		Vector3.new(28, 5, 22),
		Vector3.new(-28, 5, 22),
		Vector3.new(28, 5, -22),
		Vector3.new(-28, 5, -22),
		Vector3.new(0, 5, 30),
		Vector3.new(0, 5, -30),
	}
	for i = 1, count do
		local color = COLORS[((i - 1) % #COLORS) + 1]
		local pos: Vector3
		if #spawnList > 0 then
			pos = spawnList[((i - 1) % #spawnList) + 1]
		else
			pos = fallback[((i - 1) % #fallback) + 1]
		end
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
			local dt = 0.2
			for _, model in ipairs(models) do
				if not model.Parent then
					continue
				end
				local hum = model:FindFirstChildOfClass("Humanoid")
				local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
				if not hum or hum.Health <= 0 or not hrp then
					continue
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
					if getRole(nearest) == "Murderer" then
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
					if getRole(nearest) == "Murderer" then
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

				targetPos = World.safe(targetPos)
				local now = Vector3.new(hrp.Position.X, World.hrpHeight(), hrp.Position.Z)
				local delta = Vector3.new(targetPos.X - now.X, 0, targetPos.Z - now.Z)
				local step = math.min(14 * dt, delta.Magnitude)
				local nextPos = now
				if delta.Magnitude > 0.4 then
					nextPos = now + delta.Unit * step
					setModelCFrame(model, CFrame.lookAt(nextPos, nextPos + delta.Unit))
				else
					setModelCFrame(model, CFrame.new(World.safe(now)))
				end
			end
			task.wait(0.2)
		end
	end)
end

function Bots.stop()
	running = false
end

return Bots
