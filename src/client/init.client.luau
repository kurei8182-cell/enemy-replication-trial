local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Snapshot = require(ReplicatedStorage.Shared.Snapshot)
local Config = require(ReplicatedStorage.Shared.Config)
local AdminUI = require(script:WaitForChild("AdminUI"))

local player = Players.LocalPlayer

local enemyFolder = Instance.new("Folder")
enemyFolder.Name = "ClientEnemies"
enemyFolder.Parent = workspace

local BASE_SIZE = Vector3.new(2, 4, 2)
local LERP_RATE = 18

local models = {}
local targetPositions = {}

local materialByValue = {}
for _, mat in Enum.Material:GetEnumItems() do
    materialByValue[mat.Value] = mat
end

local function buildEnemyPart(id: number, pos: Vector3, color: Color3, materialValue: number, scale: number): Part
    local part = Instance.new("Part")
    part.Name = "Enemy_" .. id
    part.Size = BASE_SIZE * scale
    part.Color = color
    part.Material = materialByValue[materialValue] or Enum.Material.Plastic
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = true
    part.CanTouch = false
    part.CFrame = CFrame.new(pos)
    part:SetAttribute("EnemyId", id)

    local click = Instance.new("ClickDetector")
    click.MaxActivationDistance = 64
    click.Parent = part

    click.MouseClick:Connect(function()
        print(("[client] clicked enemy %d"):format(id))
        Remotes.EnemyClicked:FireServer(id)
    end)

    part.Parent = enemyFolder
    return part
end

Remotes.EnemySpawned.OnClientEvent:Connect(function(id, pos, color, materialValue, scale)
    if models[id] then return end
    models[id] = buildEnemyPart(id, pos, color, materialValue, scale)
    targetPositions[id] = pos
end)

Remotes.EnemyRemoved.OnClientEvent:Connect(function(id)
    local part = models[id]
    if part then part:Destroy() end
    models[id] = nil
    targetPositions[id] = nil
end)

Remotes.EnemySnapshot.OnClientEvent:Connect(function(buf)
    local positions = Snapshot.decode(buf)
    for id, pos in positions do
        if models[id] then
            targetPositions[id] = pos
        end
    end
end)

RunService.RenderStepped:Connect(function(dt)
    local alpha = 1 - math.exp(-LERP_RATE * dt)
    for id, part in models do
        local target = targetPositions[id]
        if target then
            local current = part.Position
            local nextPos = current:Lerp(target, alpha)
            part.CFrame = CFrame.new(nextPos)
        end
    end
end)

-- Admin UI Wiring
local ui = AdminUI.mount({
    rate = Config.Spawn.Rate,
    cap = Config.Spawn.Max,
})

local function sendRate()
    local n = tonumber(ui.rateBox.Text)
    if n then
        Remotes.AdminAction:FireServer("setRate", n)
    else
        ui.rateBox.Text = tostring(Config.Spawn.Rate)
    end
end

local function sendCap()
    local n = tonumber(ui.capBox.Text)
    if n then
        Remotes.AdminAction:FireServer("setCap", n)
    else
        ui.capBox.Text = tostring(Config.Spawn.Max)
    end
end

ui.rateBox.FocusLost:Connect(sendRate)
ui.capBox.FocusLost:Connect(sendCap)

ui.killBtn.MouseButton1Click:Connect(function()
    Remotes.AdminAction:FireServer("killAll")
end)

print("[client] renderer online")