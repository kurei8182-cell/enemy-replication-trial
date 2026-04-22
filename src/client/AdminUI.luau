local Players = game:GetService("Players")

local AdminUI = {}

local function makeFrame(parent, size, pos)
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.Position = pos
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	return frame
end

local function makeLabel(parent, text, pos)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 120, 0, 24)
	label.Position = pos
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(220, 220, 225)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.Parent = parent
	return label
end

local function makeTextBox(parent, initial, pos)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, 60, 0, 24)
	box.Position = pos
	box.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
	box.BorderSizePixel = 0
	box.Text = tostring(initial)
	box.TextColor3 = Color3.fromRGB(240, 240, 240)
	box.Font = Enum.Font.GothamMedium
	box.TextSize = 14
	box.ClearTextOnFocus = false
	box.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = box

	return box
end

local function makeButton(parent, text, pos, color)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 190, 0, 32)
	btn.Position = pos
	btn.BackgroundColor3 = color
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.AutoButtonColor = true
	btn.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn

	return btn
end

function AdminUI.mount(initial)
	local gui = Instance.new("ScreenGui")
	gui.Name = "AdminUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local panel = makeFrame(gui, UDim2.new(0, 220, 0, 140), UDim2.new(0, 16, 0, 16))

	makeLabel(panel, "spawn rate /s", UDim2.new(0, 12, 0, 12))
	local rateBox = makeTextBox(panel, initial.rate, UDim2.new(0, 140, 0, 12))

	makeLabel(panel, "max enemies", UDim2.new(0, 12, 0, 44))
	local capBox = makeTextBox(panel, initial.cap, UDim2.new(0, 140, 0, 44))

	local killBtn = makeButton(panel, "Kill All", UDim2.new(0, 12, 0, 88), Color3.fromRGB(180, 60, 60))

	return {
		rateBox = rateBox,
		capBox = capBox,
		killBtn = killBtn,
	}
end

return AdminUI