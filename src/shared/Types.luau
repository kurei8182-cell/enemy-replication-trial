export type Variation = {
	color: Color3,
	material: Enum.Material,
	scale: number,
}

export type Enemy = {
	id: number,
	position: Vector3,
	velocity: Vector3,
	targetUserId: number?,
	variation: Variation,
	lastAttackAt: number,
}

return {}