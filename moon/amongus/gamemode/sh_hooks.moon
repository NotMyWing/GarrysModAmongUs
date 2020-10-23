GM.Move = (ply, mvd) =>
	if mvd\KeyDown IN_DUCK
		mvd\SetButtons bit.band mvd\GetButtons!, bit.bnot IN_DUCK

	if mvd\KeyDown IN_JUMP
		mvd\SetButtons bit.band mvd\GetButtons!, bit.bnot IN_JUMP

	if mvd\KeyDown IN_SPEED
		mvd\SetButtons bit.band mvd\GetButtons!, bit.bnot IN_SPEED

	if mvd\KeyDown IN_WALK
		mvd\SetButtons bit.band mvd\GetButtons!, bit.bnot IN_WALK

	if @GameData.Lookup_PlayerByEntity
		playerTable = @GameData.Lookup_PlayerByEntity[ply]

		if (CLIENT and (@GameData.Vented or IsValid(@Hud.TaskScreen))) or
			(SERVER and (@GameData.CurrentTask[playerTable] or @GameData.Vented[playerTable]))
				mvd\SetVelocity Vector 0, 0, 0
				return true

hook.Add "PlayerFootstep", "NMW AU Footsteps", (ply) ->
	aply = GAMEMODE.GameData.Lookup_PlayerByEntity[ply]
	if GAMEMODE.GameData.DeadPlayers and GAMEMODE.GameData.DeadPlayers[aply]
		return true
