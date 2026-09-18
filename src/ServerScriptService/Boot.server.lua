--!strict
local Lighting = game:GetService("Lighting")
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

World.applyLighting()
World.build()

-- Remove default baseplate / spawn if present
for _, n in ipairs({ "Baseplate", "SpawnLocation" }) do
	local inst = workspace:FindFirstChild(n)
	if inst then
		inst:Destroy()
	end
end

local spawn = Instance.new("SpawnLocation")
spawn.Name = "LobbySpawn"
spawn.Size = Vector3.new(8, 1, 8)
spawn.Position = World.LobbySpawn - Vector3.new(0, 4, 0)
spawn.Anchored = true
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Neutral = true
spawn.Duration = 0
spawn.Parent = workspace

-- Ambient bed
local amb = Instance.new("Sound")
amb.Name = "HighriseBed"
amb.Looped = true
amb.Volume = 0.18
amb.PlaybackSpeed = 0.85
amb.SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
amb.Parent = SoundService
pcall(function()
	amb:Play()
end)

print("[Highrise] World ready. Lighting=", Lighting.ClockTime)
