GM.SpectateMap = {}

GM.Spectate_CycleEntity = (ply, delta = 0) =>
	pool = {}
	local cur, first
	for otherPly in *player.GetAll!
		if ply ~= otherPly and not otherPly\IsDead! and otherPly\GetObserverMode! == 0
			table.insert pool, otherPly

	@SpectateMap[ply] = (((@SpectateMap[ply] or 1) + delta - 1) % #pool) + 1
	if @SpectateMap[ply] ~= @SpectateMap[ply]
		@SpectateMap[ply] = 1

	if ply\GetObserverMode! == OBS_MODE_ROAMING
		ply\Spectate OBS_MODE_CHASE

	ply\SpectateEntity pool[@SpectateMap[ply]]

GM.Spectate_CycleMode = (ply) =>
	current = ply\GetObserverMode!

	switch current
		when OBS_MODE_ROAMING
			ply\Spectate OBS_MODE_CHASE

		when OBS_MODE_CHASE
			ply\Spectate OBS_MODE_IN_EYE

		when OBS_MODE_IN_EYE
			ply\Spectate OBS_MODE_ROAMING

		else
			ply\Spectate OBS_MODE_ROAMING

hook.Add "KeyPress", "NMW AU Spectate Cycle", (ply, key) ->
	if ply\GetObserverMode! > 0
		switch key
			when IN_ATTACK
				GAMEMODE\Spectate_CycleEntity ply, 1
			when IN_ATTACK2
				GAMEMODE\Spectate_CycleEntity ply, -1
			when IN_JUMP
				GAMEMODE\Spectate_CycleMode ply
			when IN_DUCK
				ply\Spectate OBS_MODE_ROAMING

	return

GM.__specInitialized = {}
hook.Add "PlayerSpawn", "NMW AU Spec", (ply) ->
	if not GAMEMODE.__specInitialized[ply]
		GAMEMODE.__specInitialized[ply] = true
		if GAMEMODE\IsGameInProgress!
			GAMEMODE\Player_HideForAlivePlayers ply
			GAMEMODE\Spectate_CycleMode ply
		else
			preferred = math.floor math.min #GAMEMODE.Colors,
				math.max 1, ply\GetInfoNum "au_preferred_color", 1

			ply\SetPlayerColor GAMEMODE.Colors[preferred]\ToVector!

		GAMEMODE\Net_BroadcastConnectDisconnect ply\Nick!, true, GAMEMODE\IsGameInProgress!

	return
