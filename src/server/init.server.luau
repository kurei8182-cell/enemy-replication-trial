local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local enemies = {}
local nextId = 1
local spawnAccumulator = 0
local currentSpawnRate = Config.Spawn.Rate
local currentMaxEnemies = Config.Spawn.Max

local platform = workspace:WaitForChild(Config.Platform.Name)

local function rollVariation()
    local colors = Config.Variations.Colors
    local mats = Config.Variations.Materials
    local sizeRange = Config.Variations.SizeRange

    return {
        color = colors[math.random(1, #colors)],
        material = mats[math.random(1, #mats)],
        scale = sizeRange.min + math.random() * (sizeRange.max - sizeRange.min),
    }
end

local function randomSpawnPosition()
    local half = Config.Platform.Size / 2 - 2
    local x = (math.random() * 2 - 1) * half
    local z = (math.random() * 2 - 1) * half
    local y = platform.Position.Y + platform.Size.Y / 2 + Config.Spawn.HeightOffset
    return Vector3.new(platform.Position.X + x, y, platform.Position.Z + z)
end

local function spawnEnemy()
    local id = nextId
    nextId += 1

    local enemy = {
        id = id,
        position = randomSpawnPosition(),
        velocity = Vector3.zero,
        targetUserId = nil,
        variation = rollVariation(),
        lastAttackAt = 0,
    }
    enemies[id] = enemy

    Remotes.EnemySpawned:FireAllClients(
        id,
        enemy.position,
        enemy.variation.color,
        enemy.variation.material.Value,
        enemy.variation.scale
    )
end

local function countEnemies()
    local n = 0
    for _ in enemies do n += 1 end
    return n
end

RunService.Heartbeat:Connect(function(dt)
    if currentSpawnRate <= 0 then return end

    spawnAccumulator += dt
    local interval = 1 / currentSpawnRate

    while spawnAccumulator >= interval do
        spawnAccumulator -= interval
        if countEnemies() < currentMaxEnemies then
            spawnEnemy()
        end
    end
end)

print(("[server] spawner online, platform=%s, rate=%d/s, cap=%d"):format(
    platform.Name, currentSpawnRate, currentMaxEnemies
))