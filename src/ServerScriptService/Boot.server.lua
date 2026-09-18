--!strict
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")

local World = require(script.Parent.Services.World)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local Config = require(game.ReplicatedStorage.Shared.Config)

Remotes.init()

pcall(function()
	workspace.Gravity = 196.2
	workspace.FallenPartsDestroyHeight = -5000
end)

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

World.applyLighting()

for _, n in ipairs({ "Baseplate", "SpawnLocation", "Spawn" }) do
	local inst = workspace:FindFirstChild(n)
	if inst then
		inst:Destroy()
	end
end
local terrain = workspace:FindFirstChildOfClass("Terrain")
if terrain then
	pcall(function()
		terrain:Clear()
	end)
end

World.build()

local spawn = Instance.new("SpawnLocation")
spawn.Name = "LobbySpawn"
spawn.Size = Vector3.new(12, 1, 12)
spawn.Position = Vector3.new(0, World.floorY() + 0.55, 0)
spawn.Anchored = true
spawn.Transparency = 1
spawn.CanCollide = true
spawn.Neutral = true
spawn.Duration = 8
spawn.Parent = workspace

local function harden(char: Model)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = Config.WalkLobby
		hum.JumpPower = Config.JumpPower
		hum.HipHeight = math.max(hum.HipHeight, 2)
		pcall(function()
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
		end)
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		hrp.CFrame = CFrame.new(World.LobbySpawn)
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end
end

local function hook(player: Player)
	player.RespawnTime = 2
	if player.Character then
		harden(player.Character)
	end
	player.CharacterAdded:Connect(function(char)
		task.wait(0.05)
		harden(char)
	end)
end

for _, p in ipairs(Players:GetPlayers()) do
	hook(p)
end
Players.PlayerAdded:Connect(hook)

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

print("[Highrise] World ready. spawn=", World.LobbySpawn)
