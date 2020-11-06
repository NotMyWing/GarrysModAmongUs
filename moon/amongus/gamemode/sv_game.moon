
GM.Game_GameOver = (reason) =>
	for index, ply in ipairs player.GetAll!
		ply\Freeze true

	@Player_CloseVGUIsForEveryone!
	@Net_BroadcastDead!
	@Net_BroadcastGameOver reason

	handle = "gameOver"

	@GameData.Timers[handle] = true
	timer.Create handle, @SplashScreenTime - 1, 1, ->
		@SetGameInProgress false
		@Restart!

GM.Game_CheckWin = (reason) =>
	if not @IsGameInProgress! or timer.Exists "gameOver"
		return

	if not reason
		reason = if @GetTimeLimit! == 0
			@Logger.Info "Game over. Crewmates have won! (time out)"
			@GameOverReason.Crewmate

		elseif @GameData.CompletedTasks >= @GameData.TotalTasks
			@Logger.Info "Game over. Crewmates have won! (task win)"
			@GameOverReason.Crewmate

		else
			numImposters = 0
			numPlayers = 0

			-- Count imposters and players and decide whether the game is over.
			for _, ply in pairs @GameData.PlayerTables
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

	for handle, _ in pairs @GameData.Timers
		timer.Remove handle

	@PurgeGameData!

	@SetGameInProgress false
	@SetCommunicationsDisabled false

	@Player_UnhideEveryone!
	@Net_BroadcastCountdown 0

	@SetGameCommencing false

	timer.Remove "NMW AU CheckWin"

	if not soft
		game.CleanUpMap!

GM.Game_Start = =>
	-- Bail if the manifest is missing or malformed.
	if not @MapManifest or not @MapManifest.Tasks
		return

	-- Bail if the game is already in progress.
	if @IsGameInProgress!
		return

	-- Bail if we don't have enough players.
	-- TO-DO: print chat message.
	if #player.GetAll! - @ConVars.ImposterCount\GetInt! * 2 < 1
		return

	handle = "tryStartGame"
	@GameData.Timers[handle] = true

	-- Count players.
	playerMemo = player.GetAll!

	time = @ConVars.Countdown\GetFloat! + 0.5
	@Net_BroadcastCountdown CurTime! + time
	@Logger.Info "Starting in #{time} s."

	@SetGameCommencing true
	@ConVarSnapshot_Take!
	@Net_BroadcastConVarSnapshots @ConVarSnapshot_ExportAll!

	timer.Create handle, time, 1, ->
		@SetGameCommencing false

		-- Don't start in case somebody has left.
		for _, ply in ipairs playerMemo
			if not IsValid ply
				@Logger.Warn "Couldn't start the round! Someone left after the countdown."
				return

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
		for _, ply in ipairs player.GetAll!
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

		-- Shuffle.
		memo = {}
		table.sort @GameData.PlayerTables, (a, b) ->
			-- I use this for testing.
			-- Ignore.
			-- if not a.entity\IsBot!
			--	memo[a] = 1
			-- if not b.entity\IsBot!
			--	memo[b] = 1

			memo[a] = memo[a] or math.random!
			memo[b] = memo[b] or math.random!
			memo[a] > memo[b]

		for index, ply in ipairs @GameData.PlayerTables
			-- Give the player a color.
			-- TO-DO: make customizable.
			ply.color = @Colors[math.floor(#@Colors / #@GameData.PlayerTables) * index]

			-- Make the first N players imposters.
			if index <= @ConVarSnapshots.ImposterCount\GetInt!
				@GameData.Imposters[ply] = true

			with ply.entity
				\Freeze true
				\SetColor ply.color
				\SetNW2Int "NMW AU Meetings", @ConVarSnapshots.MeetingsPerPlayer\GetInt!

		-- Shuffle the player table one more time.
		-- We don't want to broadcast the previous table
		-- since it'd reveal the imposters right away.
		memo = {}
		table.sort @GameData.PlayerTables, (a, b) ->
			memo[a] = memo[a] or math.random!
			memo[b] = memo[b] or math.random!
			memo[a] > memo[b]

		-- Broadcast the important stuff that players must know about the game.
		@SetGameInProgress true
		@Net_BroadcastGameStart!

		@Logger.Info "Starting the game with #{#@GameData.PlayerTables} players"
		@Logger.Info "There are #{@ConVars.ImposterCount\GetInt!} imposter(s) among them"

		-- Start the game after a dramatic pause.
		-- Teleport players while they're staring at the splash screen.
		timer.Create handle, 2, 1, ->
			@Game_StartRound!

			for index, ply in ipairs @GameData.PlayerTables
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
				for index, ply in ipairs @GameData.PlayerTables
					if IsValid ply.entity
						ply.entity\Freeze fal

					if @GameData.Imposters[ply]
						@Player_RefreshKillCooldown ply

				@SetGameState @GameState.Playing

				-- Assign the tasks to players.
				@Task_AssignToPlayers!
				@Sabotage_Init!

				@Meeting_ResetCooldown!

				-- Check if suddenly something went extremely wrong during the windup time.
				@Game_CheckWin!

GM.Game_Restart = =>
	@Game_CleanUp!

	spawns = ents.FindByClass "info_player_start"
	players = player.GetAll!

	-- Spawn, prepare and spread players around.
	for index, ply in ipairs players
		ply\SetColor @Colors[math.floor(#@Colors / #players) * index]
		ply\SetRenderMode RENDERGROUP_OPAQUE

		ply\UnSpectate!
		ply\Freeze false
		ply\Spawn!

		-- ???????
		if #spawns ~= 0
			point = spawns[(index % #spawns) + 1]
			ply\SetPos point\GetPos!
			ply\SetAngles point\GetAngles!
			ply\SetEyeAngles point\GetAngles!

	@SetGameState @GameState.Preparing

GM.Game_StartRound = =>
	-- Spawn the players and spread them around.
	spawns = ents.FindByClass "info_player_start"
	for index, ply in ipairs @GameData.PlayerTables
		if IsValid ply.entity
			with ply.entity
				point = spawns[(index % #spawns) + 1]
				\Spawn!
				\SetPos point\GetPos!
				\SetAngles point\GetAngles!
				\SetEyeAngles point\GetAngles!

	-- Call janitors to get rid of the bodies.
	bodies = ents.FindByClass "prop_ragdoll"
	for _, body in ipairs bodies
		if 0 ~= body\GetNW2Int "NMW AU PlayerID"
			body\Remove!

	for ply in pairs @GameData.Imposters
		@Player_RefreshKillCooldown ply

	@Meeting_ResetCooldown!
