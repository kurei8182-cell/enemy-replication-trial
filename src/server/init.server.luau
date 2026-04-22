local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Snapshot = require(ReplicatedStorage.Shared.Snapshot)

local enemies = {}
local nextId = 1
local spawnAccumulator = 0
local currentSpawnRate = Config.Spawn.Rate
local currentMaxEnemies = Config.Spawn.Max

local platform = workspace:WaitForChild(Config.Platform.Name)

-- [STEP 1 ADDITIONS] --
local PLATFORM_HALF = Config.Platform.Size / 2

local function isOnPlatform(pos: Vector3): boolean
    local center = platform.Position
    local dx = math.abs(pos.X - center.X)
    local dz = math.abs(pos.Z - center.Z)
    return dx <= PLATFORM_HALF and dz <= PLATFORM_HALF
end

local function getClosestPlayerOnPlatform(fromPos: Vector3): (Player?, number)
    local closest = nil
    local closestDist = math.huge
    for _, player in Players:GetPlayers() do
        local char = player.Character
        if not char then continue end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        
        if not isOnPlatform(root.Position) then continue end
        
        local dist = (root.Position - fromPos).Magnitude
        if dist < closestDist then
            closestDist = dist
            closest = player
        end
    end
    return closest, closestDist
end

local function getPlayerRootPos(userId: number): Vector3?
    local player = Players:GetPlayerByUserId(userId)
    if not player then return nil end
    
    local char = player.Character
    if not char then return nil end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    
    return root.Position
end

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

-- New Removal Function
local function removeEnemy(id)
    if not enemies[id] then return end
    enemies[id] = nil
    Remotes.EnemyRemoved:FireAllClients(id)
end

local function countEnemies()
    local n = 0
    for _ in enemies do n += 1 end
    return n
end

-- [LOOP LOGIC] --
local targetReevalAccumulator = 0
local TARGET_REEVAL_INTERVAL = 0.25

local snapshotAccumulator = 0
local SNAPSHOT_INTERVAL = 1 / Config.Enemy.SnapshotRate

RunService.Heartbeat:Connect(function(dt)
    spawnAccumulator += dt
    if currentSpawnRate > 0 then
        local interval = 1 / currentSpawnRate
        while spawnAccumulator >= interval do
            spawnAccumulator -= interval
            if countEnemies() < currentMaxEnemies then
                spawnEnemy()
            end
        end
    else
        spawnAccumulator = 0
    end
    
    targetReevalAccumulator += dt
    local reevalThisTick = targetReevalAccumulator >= TARGET_REEVAL_INTERVAL
    if reevalThisTick then
        targetReevalAccumulator = 0
    end
    
    local now = os.clock()
    for id, enemy in enemies do
        if reevalThisTick then
            local closest = getClosestPlayerOnPlatform(enemy.position)
            enemy.targetUserId = closest and closest.UserId or nil
        end
        
        if enemy.targetUserId then
            local targetPos = getPlayerRootPos(enemy.targetUserId)
            if targetPos then
                local flatTarget = Vector3.new(targetPos.X, enemy.position.Y, targetPos.Z)
                local toTarget = flatTarget - enemy.position
                local dist = toTarget.Magnitude
                
                if dist > 0.1 then
                    enemy.velocity = toTarget.Unit * Config.Enemy.BaseSpeed
                else
                    enemy.velocity = Vector3.zero
                end
                
                if dist <= Config.Enemy.AttackRange and now - enemy.lastAttackAt >= Config.Enemy.AttackCooldown then
                    enemy.lastAttackAt = now
                    print(("[enemy %d] attacks player %d"):format(id, enemy.targetUserId))
                end
            else
                enemy.velocity = Vector3.zero
            end
        else
            enemy.velocity = Vector3.zero
        end
        
        enemy.position += enemy.velocity * dt
        
        if not isOnPlatform(enemy.position) then
            local center = platform.Position
            local clampedX = math.clamp(enemy.position.X, center.X - PLATFORM_HALF, center.X + PLATFORM_HALF)
            local clampedZ = math.clamp(enemy.position.Z, center.Z - PLATFORM_HALF, center.Z + PLATFORM_HALF)
            enemy.position = Vector3.new(clampedX, enemy.position.Y, clampedZ)
        end
    end

    snapshotAccumulator += dt
    if snapshotAccumulator >= SNAPSHOT_INTERVAL then
        snapshotAccumulator = 0
        local buf = Snapshot.encode(enemies)
        Remotes.EnemySnapshot:FireAllClients(buf)
    end
end)

Remotes.EnemyClicked.OnServerEvent:Connect(function(player, id)
    if type(id) ~= "number" then return end
    if not enemies[id] then return end
    print(("[server] player %s clicked enemy %d"):format(player.Name, id))
end)

Players.PlayerAdded:Connect(function(player)
    for id, enemy in enemies do
        Remotes.EnemySpawned:FireClient(
            player,
            id,
            enemy.position,
            enemy.variation.color,
            enemy.variation.material.Value,
            enemy.variation.scale
        )
    end
end)

-- [ADMIN CONTROLS] --
local function setRate(n)
    currentSpawnRate = math.clamp(n, 0, 10)
    spawnAccumulator = 0
end

local function setCap(n)
    currentMaxEnemies = math.clamp(math.floor(n), 0, 100)
end

local function killAll()
    local ids = {}
    for id in enemies do
        table.insert(ids, id)
    end
    for _, id in ids do
        removeEnemy(id)
    end
end

Remotes.AdminAction.OnServerEvent:Connect(function(player, action, value)
    if action == "setRate" and type(value) == "number" then
        setRate(value)
        print(("[admin] %s set spawn rate to %.2f/s"):format(player.Name, currentSpawnRate))
    elseif action == "setCap" and type(value) == "number" then
        setCap(value)
        print(("[admin] %s set cap to %d"):format(player.Name, currentMaxEnemies))
    elseif action == "killAll" then
        killAll()
        print(("[admin] %s killed all enemies"):format(player.Name))
    end
end)

print(("[server] spawner online, platform=%s, rate=%d/s, cap=%d"):format(
    platform.Name, currentSpawnRate, currentMaxEnemies
))