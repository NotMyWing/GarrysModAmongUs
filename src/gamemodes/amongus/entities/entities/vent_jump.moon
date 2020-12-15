AddCSLuaFile!

ENT.Base  = "base_anim"
ENT.Type  = "anim"
ENT.RenderGroup = RENDERGROUP_OPAQUE


ENT.Initialize = =>
	@__remove = CurTime! + 0.5

-- yeah
ventJumpEq = (x) -> (5200 * -math.pow x, 2)/231 + (2320 * x)/231

ENT.Think = =>
	if CurTime! > @__remove
		@Remove!
		return

	value = (@__remove - CurTime!) / 0.5
	if not @Appearing
		value = 1 - value

	@__initialPos or= @GetPos!

	mod = ventJumpEq value
	@SetPos @__initialPos + Vector(0, 0, 10) * mod
