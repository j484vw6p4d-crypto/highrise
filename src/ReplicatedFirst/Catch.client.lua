-- Local safety floor so the first frame is never a void. Server map replaces this.
if workspace:FindFirstChild("HR_CATCH") then
	return
end
local p = Instance.new("Part")
p.Name = "HR_CATCH"
p.Anchored = true
p.Size = Vector3.new(220, 8, 220)
p.CFrame = CFrame.new(0, 0, 20)
p.Material = Enum.Material.Slate
p.Color = Color3.fromRGB(48, 44, 40)
p.Parent = workspace
