--!strict
local PathfindingService = game:GetService("PathfindingService")
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
		return Vector3.new(0, 185, 0)
	end
	return w[math.random(1, #w)]
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
	for i = 1, count do
		local desc = Instance.new("HumanoidDescription")
		desc.TorsoColor = COLORS[((i - 1) % #COLORS) + 1]
		desc.HeadColor = Color3.fromRGB(230, 210, 190)
		desc.LeftArmColor = desc.HeadColor
		desc.RightArmColor = desc.HeadColor
		desc.LeftLegColor = Color3.fromRGB(20, 20, 24)
		desc.RightLegColor = Color3.fromRGB(20, 20, 24)
		desc.Shirt = 0
		local ok, model = pcall(function()
			return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
		end)
		if not ok or not model then
			model = Instance.new("Model")
			local hrp = Instance.new("Part")
			hrp.Name = "HumanoidRootPart"
			hrp.Size = Vector3.new(2, 2, 1)
			hrp.Anchored = false
			hrp.Parent = model
			local hum = Instance.new("Humanoid")
			hum.Parent = model
			model.PrimaryPart = hrp
		end
		model.Name = "Guest " .. NAMES[((i - 1) % #NAMES) + 1]
		model:SetAttribute("IsBot", true)
		model:SetAttribute("BotIndex", i)
		local spawns = World.spawns()
		local pos = if #spawns > 0 then spawns[((i - 1) % #spawns) + 1] else Vector3.new(0, 185, 0)
		model:PivotTo(CFrame.new(pos))
		model.Parent = workspace:FindFirstChild("Highrise") or workspace
		local hum = model:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.DisplayName = model.Name
			hum.WalkSpeed = 14
			hum.JumpPower = 0
		end
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

				if role == "Murderer" and nearest and nearestDist < 80 then
					local tpart = if typeof(nearest) == "Instance" and nearest:IsA("Player")
						then nearest.Character and nearest.Character:FindFirstChild("HumanoidRootPart")
						elseif typeof(nearest) == "Instance" then (nearest :: Model):FindFirstChild("HumanoidRootPart")
						else nil
					if tpart then
						targetPos = (tpart :: BasePart).Position
						if nearestDist < 7 then
							attack(model, nearest)
						end
					end
				elseif role == "Sheriff" and nearest and nearestDist < 70 then
					local nRole = getRole(nearest)
					if nRole == "Murderer" then
						local tpart = if typeof(nearest) == "Instance" and nearest:IsA("Player")
							then nearest.Character and nearest.Character:FindFirstChild("HumanoidRootPart")
							elseif typeof(nearest) == "Instance" then (nearest :: Model):FindFirstChild("HumanoidRootPart")
							else nil
						if tpart then
							targetPos = (tpart :: BasePart).Position
							if nearestDist < 60 then
								shoot(model, nearest)
							end
						end
					end
				elseif role == "Innocent" and nearest and nearestDist < 18 then
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
								targetPos = hrp.Position + away.Unit * 24
							end
						end
					end
				end

				pcall(function()
					hum:MoveTo(targetPos)
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
