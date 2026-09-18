-- Runs before spawn. Puts a floor under you even if the server is late.
local function ensure()
	if workspace:FindFirstChild("Highrise") then
		return
	end
	if workspace:FindFirstChild("HR_CATCH") then
		return
	end
	local p = Instance.new("Part")
	p.Name = "HR_CATCH"
	p.Anchored = true
	p.Size = Vector3.new(80, 4, 80)
	p.CFrame = CFrame.new(0, 0, 0)
	p.Material = Enum.Material.Wood
	p.Color = Color3.fromRGB(72, 48, 32)
	p.TopSurface = Enum.TopSurface.Smooth
	p.BottomSurface = Enum.BottomSurface.Smooth
	p.Parent = workspace
	local w1 = Instance.new("Part")
	w1.Name = "HR_CATCH_WALL"
	w1.Anchored = true
	w1.Size = Vector3.new(80, 16, 2)
	w1.CFrame = CFrame.new(0, 8, -40)
	w1.Color = Color3.fromRGB(210, 198, 178)
	w1.Material = Enum.Material.Marble
	w1.Parent = workspace
end

ensure()
task.defer(ensure)
workspace.ChildRemoved:Connect(function(ch)
	if ch.Name == "Highrise" or ch.Name == "HR_CATCH" then
		task.defer(ensure)
	end
end)

local lp = game:GetService("Players").LocalPlayer
local function lift(char: Model)
	local hrp = char:WaitForChild("HumanoidRootPart", 8)
	if hrp and hrp:IsA("BasePart") then
		if hrp.Position.Y < 4 then
			hrp.CFrame = CFrame.new(0, 8, 6)
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
	end
end
lp.CharacterAdded:Connect(lift)
if lp.Character then
	task.spawn(lift, lp.Character)
end
