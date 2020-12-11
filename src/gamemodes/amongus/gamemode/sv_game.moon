
GM.Game_GameOver = (reason) =>
	for ply in *player.GetAll!
		ply\Freeze true

	@Player_CloseVGUIsForEveryone!
	@Net_BroadcastDead!
	@Net_BroadcastGameOver reason
	@Sabotage_ForceEndAll!

	-- Pack crewmates and imposters for the hook.
	hookCrewmates, hookImposters = {}, {}
	for ply in *@GameData.PlayerTables
		table.insert (@GameData.Imposters[ply] and hookImposters or hookCrewmates),
			ply.entity

	hook.Call "GMAU GameEnd", nil, hookCrewmates, hookImposters

	handle = "gameOver"
	@GameData.Timers[handle] = true
	timer.Create handle, @SplashScreenTime - 1, 1, ->
		@Game_Restart!

GM.Game_CheckWin = (reason) =>
	return if not @IsGameInProgress! or timer.Exists "gameOver"

	if not reason
		reason = if @GetTimeLimit! == 0
			@Logger.Info "Game over. Crewmates have won! (time out)"
			@GameOverReason.Crewmate

		elseif @GameData.CompletedTasks and (@GameData.CompletedTasks >= @GameData.TotalTasks)
			@Logger.Info "Game over. Crewmates have won! (task win)"
			@GameOverReason.Crewmate

		else
			numImposters = 0
			numPlayers = 0

			-- Count imposters and players and decide whether the game is over.
			for ply in *@GameData.PlayerTables
				if IsValid(ply.entity) and not @GameData.DeadPlayers[ply]
					if @GameData.Imposters[ply]
						numImposters += 1
					else
						numPlayers += 1

			if numImposters == 0
				@Logger.Info "Game over. Crewmates have won!"
				@GameOverReason.Crewmate

			elseif numImposters >= numPlayers
				@Logger.Info "Game over. Imposters have won!"
				@GameOverReason.Imposter

	if reason
		@Game_GameOver reason

		return true

GM.Game_CleanUp = (soft) =>
	-- Shut all ongoing sabotages down gracefully.
	if @GameData.Sabotages
		@Sabotage_ForceEndAll!

	for handle in pairs @GameData.Timers
		timer.Remove handle

	@PurgeGameData!

	@Player_UnhideEveryone!
	@Net_BroadcastCountdown 0

	@SetGameCommencing false
	@SetGameInProgress false
	@SetMeetingDisabled false
	@SetMeetingInProgress false
	@SetCommunicationsDisabled false

	timer.Remove "NMW AU CheckWin"

	if not soft
		game.CleanUpMap false, {
			"env_soundscape"
			"env_soundscape_proxy"
			"env_soundscape_triggerable"
		}

GM.Game_Start = =>
	-- Bail if the manifest is missing or malformed.
	return unless @MapManifest and @MapManifest.Tasks

	-- Bail if the game is already in progress.
	return if @IsGameInProgress!

	-- Fetch a table of initialized players.
	initializedPlayers = @GetFullyInitializedPlayers!

	-- Bail if we don't have enough players.
	-- TO-DO: print chat message.
	return if #initializedPlayers < @ConVars.MinPlayers\GetInt!

	handle = "tryStartGame"
	@GameData.Timers[handle] = true

	time = @ConVars.Countdown\GetFloat! + 0.5
	@Net_BroadcastCountdown CurTime! + time
	@Logger.Info "Starting in #{time} s."

	@SetGameCommencing true
	@ConVarSnapshot_Take!
	@Net_BroadcastConVarSnapshots @ConVarSnapshot_ExportAll!

	timer.Create handle, time, 1, ->
		@SetGameCommencing false

		-- Reset the player table.
		initializedPlayers = @GetFullyInitializedPlayers!

		-- Bail if we don't have enough players. Again.
		-- TO-DO: print chat message.
		return if #initializedPlayers < @ConVars.MinPlayers\GetInt!

		-- Create the time limit timer if the cvar is set.
		-- That's quite an interesting sentence.
		timelimit = @ConVarSnapshots.TimeLimit\GetInt!
		timelimitHandle = "timelimitHandle"
		if timelimit > 0
			@GameData.Timers[timelimitHandle] = true

			@SetTimeLimit timelimit
			timer.Create timelimitHandle, 1, timelimit, ->
				remainder = timer.RepsLeft timelimitHandle
				@SetTimeLimit remainder
				if remainder == 0
					@Game_CheckWin!

			timer.Pause timelimitHandle
		else
			@SetTimeLimit -1

		-- Create player "accounts" that we're going
		-- to use during the entire game.
		id = 0
		for ply in *initializedPlayers
			id += 1
			t = {
				steamid: ply\SteamID!
				nickname: ply\Nick!
				entity: ply
				id: id
			}

			table.insert @GameData.PlayerTables, t
			@GameData.Lookup_PlayerByID[id] = t
			@GameData.Lookup_PlayerByEntity[ply] = t

		-- Make everyone else spectators.
		for ply in *player.GetAll!
			if not @GameData.Lookup_PlayerByEntity[ply]
				@Player_HideForAlivePlayers ply
				@Spectate_CycleMode ply

		-- Shuffle.
		memo = {}
		table.sort @GameData.PlayerTables, (a, b) ->
			-- I use this for testing.
			-- Ignore.
			-- if not a.entity\IsBot!
			--	memo[a] = 1
			-- if not b.entity\IsBot!
			-- 	memo[b] = 1

			memo[a] = memo[a] or math.random!
			memo[b] = memo[b] or math.random!
			memo[a] > memo[b]

		imposterCount = math.min GAMEMODE.ConVarSnapshots.ImposterCount\GetInt!, @GetImposterCount #initializedPlayers
		for index, ply in ipairs @GameData.PlayerTables
			-- Make the first N players imposters.
			if index <= imposterCount
				@GameData.Imposters[ply] = true

			with ply.entity
				\Freeze true
				\SetNWInt "NMW AU Meetings", @ConVarSnapshots.MeetingsPerPlayer\GetInt!

		-- Shuffle the player table one more time.
		-- We don't want to broadcast the previous table
		-- since it'd reveal the imposters right away.
		memo = {}
		table.sort @GameData.PlayerTables, (a, b) ->
			memo[a] = memo[a] or math.random!
			memo[b] = memo[b] or math.random!
			memo[a] > memo[b]

		-- Assign colors to players in rounds.
		colorRounds = math.ceil #@GameData.PlayerTables / #@Colors
		for round = 1, colorRounds
			colors = [color for color in *@Colors]

			lowerBound = 1 + (round - 1) * #@Colors
			upperBound = round * #@Colors
			slicedPlayers = [ply for ply in *@GameData.PlayerTables[lowerBound, upperBound]]

			-- Sort by time.
			table.sort slicedPlayers, (a, b) ->
				a.entity\TimeConnected! < b.entity\TimeConnected!

			assigned = {}

			-- Assign preferred colors first
			for ply in *slicedPlayers
				preferred = math.floor math.min #@Colors,
					math.max 1, ply.entity\GetInfoNum "au_preferred_color", 1

				if preferred ~= 0 and colors[preferred]
					ply.color = colors[preferred]
					ply.entity\SetPlayerColor ply.color\ToVector!

					colors[preferred] = nil
					assigned[ply] = true

			-- Iterate again, assigning random colors to the rest of the players.
			for ply in *slicedPlayers
				continue if assigned[ply]

				color, id = table.Random colors

				ply.color = color
				ply.entity\SetPlayerColor ply.color\ToVector!

				colors[id] = nil

		-- Broadcast the important stuff that players must know about the game.
		@SetGameInProgress true
		@Net_BroadcastGameStart!

		@Logger.Info "Starting the game with #{#@GameData.PlayerTables} players"
		@Logger.Info "There are #{imposterCount} imposter(s) among them"

		-- Start the game after a dramatic pause.
		-- Teleport players while they're staring at the splash screen.
		timer.Create handle, 2, 1, ->
			@Game_StartRound true

			for ply in *@GameData.PlayerTables
				if IsValid ply.entity
					ply.entity\Freeze true

			timer.Create handle, @SplashScreenTime - 2, 1, ->
				@Logger.Info "Game begins! GL & HF"

				-- Set off the timeout timer.
				if timer.Exists timelimitHandle
					timer.UnPause timelimitHandle

				-- Otherwise start the game and fire up the background check timer.
				timer.Create "NMW AU CheckWin", 5, 0, ->
					if GAMEMODE\IsGameInProgress!
						GAMEMODE\Game_CheckWin!
					else
						timer.Remove "NMW AU CheckWin"

				-- Unfreeze everyone and broadcast buttons.
				for ply in *@GameData.PlayerTables
					if IsValid ply.entity
						ply.entity\Freeze fal

					if @GameData.Imposters[ply]
						@Player_RefreshKillCooldown ply, 10

				@SetGameState @GameState.Playing

				-- Assign the tasks to players.
				@Task_AssignToPlayers!
				@Sabotage_Init!

				@Meeting_ResetCooldown!

				-- Check if suddenly something went extremely wrong during the windup time.
				@Game_CheckWin!

				-- Pack crewmates and imposters for the hook.
				hookCrewmates, hookImposters = {}, {}
				for ply in *@GameData.PlayerTables
					table.insert (@GameData.Imposters[ply] and hookImposters or hookCrewmates),
						ply.entity

				hook.Call "GMAU GameStart", nil, hookCrewmates, hookImposters

GM.Game_Restart = =>
	@Game_CleanUp!

	spawns = ents.FindByClass "info_player_start"
	players = player.GetAll!

	-- Spawn, prepare and spread players around.
	for index, ply in ipairs players
		ply\SetColor Color 255, 255, 255, 255
		ply\SetRenderMode RENDERGROUP_OPAQUE

		ply\UnSpectate!
		ply\Freeze false
		ply\Spawn!
		ply\SetMoveType MOVETYPE_WALK

		if #spawns ~= 0
			point = spawns[((index - 1) % #spawns) + 1]
			ply\SetPos point\GetPos!
			ply\SetAngles point\GetAngles!
			ply\SetEyeAngles point\GetAngles!
		else
			return error "Couldn't find any spawn positions"

	@SetGameState @GameState.Preparing
	hook.Call "GMAU Restart"

GM.Game_StartRound = (first = false) =>
	spawns = ents.FindByClass "info_player_start"
	if #spawns == 0
		return error "Couldn't find any spawn positions"

	-- Spawn the players and spread them around.
	for index, ply in ipairs @GameData.PlayerTables
		if IsValid ply.entity
			with ply.entity
				point = spawns[((index - 1) % #spawns) + 1]
				\Spawn!
				\SetPos point\GetPos!
				\SetAngles point\GetAngles!
				\SetEyeAngles point\GetAngles!

	-- Call janitors to get rid of the bodies.
	bodies = ents.FindByClass "prop_ragdoll"
	for body in *bodies
		continue unless @IsPlayerBody body

		body\Remove!

	if not first
		-- Refresh kill cooldowns.
		for ply in pairs @GameData.Imposters
			@Player_RefreshKillCooldown ply, first and 10 or nil

	@Meeting_ResetCooldown!

GM.Game_RestartAutoPilotTimer = =>
	time = @ConVars.WarmupTime\GetFloat!

	SetGlobalFloat "NMW AU AutoPilotTimer", CurTime! + time
	timer.Create "NMW AU AutoPilot", time, 0, ->
		@Game_Start!

GM.Game_StopAutoPilotTimer = =>
	SetGlobalFloat "NMW AU AutoPilotTimer", 0
	if timer.Exists "NMW AU AutoPilot"
		timer.Remove "NMW AU AutoPilot"

hook.Add "KeyPress", "NMW AU GameStart", (ply, key) -> with GAMEMODE
	if (ply\IsAdmin! or ply\IsListenServerHost!) and key == IN_JUMP
		-- Bail if the game is in progress.
		return if \IsGameInProgress!

		-- Bail if the game is being managed automatically.
		return if GAMEMODE.ConVars.ForceAutoWarmup\GetBool! or GAMEMODE\IsOnAutoPilot!

		if \IsGameCommencing!
			.Logger.Warn "Admin #{ply\Nick!} has stopped the countdown!"

			timer.Destroy "tryStartGame"
			\Game_CleanUp true
		else
			GAMEMODE\Game_Start!
			if \IsGameCommencing!
				.Logger.Info "Admin #{ply\Nick!} has started the countdown"

	return

hook.Add "PlayerDisconnected", "NMW AU CheckWin", (ply) -> with GAMEMODE
	initializedPlayers = \GetFullyInitializedPlayers!

	if (\IsGameInProgress! or \IsGameCommencing!) and #initializedPlayers <= 1
		.Logger.Info "Everyone left. Stopping the game."
		\Game_Restart!
		return

	if \IsGameInProgress!
		if playerTable = .GameData.Lookup_PlayerByEntity[ply]
			\Player_SetDead playerTable
			\Player_CloseVGUI playerTable

			-- If the player was a crewmate and he had tasks,
			-- "complete" his tasks and broadcast the new count.
			if .GameData.Tasks and .GameData.Tasks[playerTable] and not .GameData.Imposters[playerTable]
				count = table.Count .GameData.Tasks[playerTable]
				if count > 0
					.GameData.CompletedTasks += table.Count .GameData.Tasks[playerTable]
					table.Empty .GameData.Tasks[playerTable]

					\Net_BroadcastTaskCount .GameData.CompletedTasks, .GameData.TotalTasks

			if not \IsMeetingInProgress!
				\Game_CheckWin!
	else
		if timer.Exists "tryStartGame"
			.Logger.Warn "Couldn't start the round! Someone left after the countdown"

			timer.Destroy "tryStartGame"
			\Game_CleanUp true

	return

timer.Create "NMW AU AutoPilotChecker", 0.25, 0, ->
	if GAMEMODE\IsGameInProgress! or GAMEMODE\IsGameCommencing!
		if timer.Exists "NMW AU AutoPilot"
			GAMEMODE\Game_StopAutoPilotTimer!

		return

	initializedPlayerCount = #GAMEMODE\GetFullyInitializedPlayers!
	auto = GAMEMODE.ConVars.ForceAutoWarmup\GetBool! or GAMEMODE\IsOnAutoPilot!
	enough = initializedPlayerCount >= GAMEMODE.ConVars.MinPlayers\GetInt!

	GAMEMODE\SetFullyInitializedPlayerCount initializedPlayerCount

	if enough and auto and not timer.Exists "NMW AU AutoPilot"
		GAMEMODE.Logger.Info "Starting the automated round management"
		GAMEMODE\Game_RestartAutoPilotTimer!

	elseif (not auto or not enough) and timer.Exists "NMW AU AutoPilot"
		GAMEMODE.Logger.Info "Stopping the automated round management"
		GAMEMODE\Game_StopAutoPilotTimer!
