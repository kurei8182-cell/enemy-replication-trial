local Config = {}

Config.Platform = {
	Name = "Platform",
	Size = 50,
}

Config.Spawn = {
	Rate = 1,
	Max = 20,
	HeightOffset = 3,
}

Config.Enemy = {
	BaseSpeed = 12,
	AttackRange = 4,
	AttackCooldown = 1.5,
	SnapshotRate = 15,
}

Config.Variations = {
	Colors = {
		Color3.fromRGB(200, 60, 60),
		Color3.fromRGB(60, 140, 200),
		Color3.fromRGB(90, 180, 90),
		Color3.fromRGB(210, 180, 70),
		Color3.fromRGB(170, 90, 200),
	},
	Materials = {
		Enum.Material.Plastic,
		Enum.Material.Metal,
		Enum.Material.Slate,
		Enum.Material.Neon,
	},
	SizeRange = {min = 0.8, max = 1.4},
}

return Config