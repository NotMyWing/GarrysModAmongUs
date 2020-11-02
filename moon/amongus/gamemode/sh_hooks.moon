hook.Add "Move", "NMW AU Move", (ply, mvd) ->
	@ = GAMEMODE

	if mvd\KeyDown IN_DUCK
		mvd\SetButtons bit.band mvd\GetButtons!, bit.bnot IN_DUCK

	if mvd\KeyDown IN_JUMP
		mvd\SetButtons bit.band mvd\GetButtons!, bit.bnot IN_JUMP

	if mvd\KeyDown IN_SPEED
		mvd\SetButtons bit.band mvd\GetButtons!, bit.bnot IN_SPEED

	if mvd\KeyDown IN_WALK
		mvd\SetButtons bit.band mvd\GetButtons!, bit.bnot IN_WALK

	playerTable = @GameData.Lookup_PlayerByEntity[ply]

	if (CLIENT and (@GameData.Vented or IsValid(@Hud.CurrentVGUI) or IsValid(@Hud.Kill))) or
		(SERVER and (@GameData.CurrentVGUI[playerTable] or @GameData.Vented[playerTable]))
			mvd\SetVelocity Vector 0, 0, 0
			return true

hook.Add "PlayerFootstep", "NMW AU Footsteps", (ply) ->
	aply = GAMEMODE.GameData.Lookup_PlayerByEntity[ply]
	if GAMEMODE.GameData.DeadPlayers and GAMEMODE.GameData.DeadPlayers[aply]
		return true

hook.Add "EntityEmitSound", "NMW AU Ragdoll Sounds", (t) ->
	if IsValid(t.Entity) and t.Entity\GetClass! == "prop_ragdoll"
		return false
