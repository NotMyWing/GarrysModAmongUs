hook.Add "Move", "NMW AU Move", (ply, mvd) ->
	@ = GAMEMODE

	-- No hud? Have we not loaded the game mode yet?
	-- How are we moving then???
	return if CLIENT and not (IsValid(@Hud) or IsValid(@GameData))

	playerTable = @GameData.Lookup_PlayerByEntity[ply]
	isAlive = not GAMEMODE.GameData.DeadPlayers[playerTable]

	if isAlive and mvd\KeyDown IN_DUCK
		mvd\SetButtons bit.band mvd\GetButtons!, bit.bnot IN_DUCK

	if isAlive and mvd\KeyDown IN_JUMP
		mvd\SetButtons bit.band mvd\GetButtons!, bit.bnot IN_JUMP

	if mvd\KeyDown IN_SPEED
		mvd\SetButtons bit.band mvd\GetButtons!, bit.bnot IN_SPEED

	if isAlive and mvd\KeyDown IN_WALK
		mvd\SetButtons bit.band mvd\GetButtons!, bit.bnot IN_WALK

	if (CLIENT and (@GameData.Vented or (IsValid(@Hud.CurrentVGUI) and @Hud.CurrentVGUI\IsVisible!) or IsValid(@Hud.Kill))) or
		(SERVER and (@GameData.CurrentVGUI[playerTable] or @GameData.Vented[playerTable]))
			mvd\SetVelocity Vector 0, 0, 0
			return true

hook.Add "PlayerFootstep", "NMW AU Footsteps", (ply) -> true if ply\IsDead!
hook.Add "EntityEmitSound", "NMW AU Ragdoll Sounds", (t) ->
	false if IsValid(t.Entity) and t.Entity\GetClass! == "prop_ragdoll"
