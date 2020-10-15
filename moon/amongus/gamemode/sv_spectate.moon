GM.SpectateMap = {}

GM.CycleSpectateEntity = (ply, delta = 0) =>
	pool = {}
	local cur, first
	for i, otherPly in ipairs player.GetAll!
		if ply ~= otherPly and otherPly\Alive! and otherPly\GetObserverMode! > 0
			table.insert pool, otherPly

	@SpectateMap[ply] = (((@SpectateMap[ply] or 1) + delta - 1) % #pool) + 1

	if ply\GetObserverMode! == OBS_MODE_ROAMING
		ply\Spectate OBS_MODE_CHASE

	ply\SpectateEntity pool[@SpectateMap[ply]]

GM.CycleSpectateMode = (ply) =>
	current = ply\GetObserverMode!

	switch current
		when OBS_MODE_ROAMING
			ply\Spectate OBS_MODE_CHASE

		when OBS_MODE_CHASE
			ply\Spectate OBS_MODE_IN_EYE

		when OBS_MODE_IN_EYE
			ply\Spectate OBS_MODE_ROAMING

hook.Add "KeyPress", "NMW AU Spectate Cycle", (ply, key) ->
	if ply\GetObserverMode! > 0
		switch key
			when IN_ATTACK
				GAMEMODE\CycleSpectateEntity ply, 1
			when IN_ATTACK2
				GAMEMODE\CycleSpectateEntity ply, -1
			when IN_JUMP
				GAMEMODE\CycleSpectateMode ply
			when IN_DUCK
				ply\Spectate OBS_MODE_ROAMING

hook.Add "PlayerInitialSpawn", "NMW AU Spec", (ply) ->
	if GetGlobalBool("NMW AU GameInProgress")
		GAMEMODE\CycleSpectateEntity ply