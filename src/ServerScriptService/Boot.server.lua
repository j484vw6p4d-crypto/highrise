--!strict
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")

local World = require(script.Parent.Services.World)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)

Remotes.init()

pcall(function()
	workspace.Gravity = 196.2
end)

StarterPlayer.CameraMaxZoomDistance = 18
StarterPlayer.CameraMinZoomDistance = 8
StarterPlayer.EnableMouseLockOption = true
StarterPlayer.CharacterWalkSpeed = 16
StarterPlayer.CharacterJumpPower = 50
pcall(function()
	StarterPlayer.DevComputerCameraMovementMode = Enum.DevComputerCameraMovementMode.Classic
end)

StarterGui.ResetPlayerGuiOnSpawn = false

-- Light first so Play Solo is never a black frame.
World.applyLighting()

-- Strip the default baseplate BEFORE the penthouse exists so they cannot clip.
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
spawn.Position = Vector3.new(World.LobbySpawn.X, World.floorY() + 1.6, World.LobbySpawn.Z)
spawn.Anchored = true
spawn.Transparency = 1
spawn.CanCollide = true
spawn.Neutral = true
spawn.Duration = 0
spawn.Parent = workspace

local function putInLobby(player: Player)
	local char = player.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		hrp.CFrame = CFrame.new(World.LobbySpawn)
		hrp.AssemblyLinearVelocity = Vector3.zero
	end
end

local function hook(player: Player)
	if player.Character then
		putInLobby(player)
	end
	player.CharacterAdded:Connect(function()
		task.wait(0.1)
		putInLobby(player)
	end)
end

for _, p in ipairs(Players:GetPlayers()) do
	hook(p)
end
Players.PlayerAdded:Connect(hook)

local amb = Instance.new("Sound")
amb.Name = "HighriseBed"
amb.Looped = true
amb.Volume = 0.12
amb.PlaybackSpeed = 0.85
amb.SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
amb.Parent = SoundService
pcall(function()
	amb:Play()
end)

print("[Highrise] World ready. Lighting=", Lighting.ClockTime, "spawn=", World.LobbySpawn)
