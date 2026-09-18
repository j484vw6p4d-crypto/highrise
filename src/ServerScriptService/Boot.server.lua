--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")

local World = require(script.Parent.Services.World)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local Config = require(game.ReplicatedStorage.Shared.Config)

Remotes.init()

pcall(function()
	workspace.Gravity = 196.2
	workspace.FallenPartsDestroyHeight = -500
end)

-- Ground FIRST, before scripts can fail and before Baseplate is removed.
World.ensureGround()
World.applyLighting()

StarterPlayer.CameraMaxZoomDistance = 18
StarterPlayer.CameraMinZoomDistance = 8
StarterPlayer.EnableMouseLockOption = true
StarterPlayer.CharacterWalkSpeed = Config.WalkLobby
StarterPlayer.CharacterJumpPower = Config.JumpPower
pcall(function()
	StarterPlayer.DevComputerCameraMovementMode = Enum.DevComputerCameraMovementMode.Classic
	StarterPlayer.AutoJumpEnabled = false
end)
StarterGui.ResetPlayerGuiOnSpawn = false

local function placeCharacter(char: Model)
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		hrp = char:WaitForChild("HumanoidRootPart", 8) :: BasePart?
	end
	if not hrp then
		return
	end
	local dest = CFrame.new(World.LobbySpawn)
	hrp.Anchored = true
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	pcall(function()
		char:PivotTo(dest)
	end)
	hrp.CFrame = dest
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = Config.WalkLobby
		hum.JumpPower = Config.JumpPower
		if hum.Health <= 0 then
			hum.Health = hum.MaxHealth
		end
		pcall(function()
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		end)
	end
	task.delay(0.12, function()
		if hrp.Parent then
			if hrp.Position.Y < 3 then
				hrp.CFrame = dest
			end
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.Anchored = false
		end
	end)
end

local function hook(player: Player)
	player.RespawnTime = 1
	player.CharacterAdded:Connect(function(char)
		task.defer(function()
			placeCharacter(char)
		end)
		task.delay(0.3, function()
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp and hrp.Position.Y < 3 then
				placeCharacter(char)
			end
		end)
	end)
	if player.Character then
		placeCharacter(player.Character)
	end
end

for _, p in ipairs(Players:GetPlayers()) do
	hook(p)
end
Players.PlayerAdded:Connect(hook)

RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp and (hrp.Position.Y < 2.4 or hrp.Position.Y > 80) then
			hrp.AssemblyLinearVelocity = Vector3.zero
			pcall(function()
				char:PivotTo(CFrame.new(World.LobbySpawn))
			end)
			hrp.CFrame = CFrame.new(World.LobbySpawn)
		end
	end
end)

for _, n in ipairs({ "Baseplate", "SpawnLocation", "Spawn" }) do
	local inst = workspace:FindFirstChild(n)
	if inst then
		inst:Destroy()
	end
end

local ok, err = pcall(function()
	World.build()
end)
if not ok then
	warn("[Highrise] World.build failed: ", err)
end

local spawn = Instance.new("SpawnLocation")
spawn.Name = "LobbySpawn"
spawn.Size = Vector3.new(16, 1, 16)
spawn.CFrame = CFrame.new(0, 1.5, 0)
spawn.Anchored = true
spawn.Transparency = 1
spawn.CanCollide = true
spawn.Neutral = true
spawn.Duration = 10
spawn.Parent = workspace

local amb = Instance.new("Sound")
amb.Name = "HighriseBed"
amb.Looped = true
amb.Volume = 0.1
amb.PlaybackSpeed = 0.85
amb.SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
amb.Parent = SoundService
pcall(function()
	amb:Play()
end)

print("[Highrise] Ground + house ready. spawn=", World.LobbySpawn)
