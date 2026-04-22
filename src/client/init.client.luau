local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Snapshot = require(ReplicatedStorage.Shared.Snapshot)

local snapshotCount = 0
local lastLog = 0

Remotes.EnemySnapshot.OnClientEvent:Connect(function(buf)
	snapshotCount += 1

	local now = os.clock()
	if now - lastLog >= 2 then
		lastLog = now
		local positions = Snapshot.decode(buf)
		local n = 0
		for _ in positions do n += 1 end
		print(("[client] snapshots=%d, last packet decoded %d enemies, buffer size=%d bytes"):format(
			snapshotCount, n, buffer.len(buf)
		))
	end
end)