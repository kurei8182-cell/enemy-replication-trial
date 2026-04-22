local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:WaitForChild("Remotes")

local function get(name: string, className: string): Instance
	local existing = folder:FindFirstChild(name)
	if existing then return existing end

	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = folder
	return inst
end

return {
	EnemySpawned = get("EnemySpawned", "RemoteEvent"),
	EnemyRemoved = get("EnemyRemoved", "RemoteEvent"),
	EnemySnapshot = get("EnemySnapshot", "UnreliableRemoteEvent"),
	EnemyClicked = get("EnemyClicked", "RemoteEvent"),
	AdminAction = get("AdminAction", "RemoteEvent"),
}