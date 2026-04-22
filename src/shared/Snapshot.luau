local Snapshot = {}

local POS_SCALE = 100
local I16_MIN = -32768
local I16_MAX = 32767

local function quantize(n: number): number
	return math.clamp(math.round(n * POS_SCALE), I16_MIN, I16_MAX)
end

function Snapshot.encode(enemies): buffer
	local ids = {}
	for id in enemies do
		table.insert(ids, id)
	end

	local count = #ids
	local buf = buffer.create(2 + count * 8)
	buffer.writeu16(buf, 0, count)

	for i, id in ids do
		local pos = enemies[id].position
		local offset = 2 + (i - 1) * 8
		buffer.writeu16(buf, offset, id)
		buffer.writei16(buf, offset + 2, quantize(pos.X))
		buffer.writei16(buf, offset + 4, quantize(pos.Y))
		buffer.writei16(buf, offset + 6, quantize(pos.Z))
	end

	return buf
end

function Snapshot.decode(buf: buffer): {[number]: Vector3}
	local result = {}
	local count = buffer.readu16(buf, 0)

	for i = 1, count do
		local offset = 2 + (i - 1) * 8
		local id = buffer.readu16(buf, offset)
		local x = buffer.readi16(buf, offset + 2) / POS_SCALE
		local y = buffer.readi16(buf, offset + 4) / POS_SCALE
		local z = buffer.readi16(buf, offset + 6) / POS_SCALE
		result[id] = Vector3.new(x, y, z)
	end

	return result
end

return Snapshot