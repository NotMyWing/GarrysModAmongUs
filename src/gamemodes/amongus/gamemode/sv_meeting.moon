DISCUSS_SPLASH_TIME = 3

skipPlaceholder = { id: 0 }

GM.Meeting_Start = (playerTable, bodyColor) =>
	if "Player" == type playerTable
		playerTable = playerTable\GetAUPlayerTable!
	return unless playerTable
	return if @GameData.DeadPlayers[playerTable]
	return unless @IsGameInProgress!

	handle = "meeting"
	return if timer.Exists handle

	if timer.Exists "timelimit"
		timer.Pause "timelimit"

	for ply in *player.GetAll!
		ply\Freeze true

	@Player_CloseVGUIsForEveryone!
	@Sabotage_EndNonPersistent!
	@SetMeetingInProgress true

	@Net_BroadcastDead!
	@Net_BroadcastMeeting playerTable, bodyColor

	if bodyColor
		@Logger.Info "#{playerTable.nickname} has found a body! Calling a meeting"
	else
		@Logger.Info "#{playerTable.nickname} has called a meeting"

	hook.Call "GMAU MeetingStart", nil, bodyColor

	@GameData.Timers[handle] = true
	timer.Create handle, 3, 1, ->
		-- Call janitors to get rid of the bodies.
		bodies = ents.FindByClass "prop_ragdoll"
		for body in *bodies
			continue unless @IsPlayerBody body

			body\Remove!

		-- Try find meeting start positions.
		spawns = ents.FindByClass "info_player_meeting"
		if #spawns == 0
			-- We found no meeting start positions. Fall back to regular spawn points.
			spawns = ents.FindByClass "info_player_start"
			if #spawns == 0
				-- We found literally nothing.
				return error "Couldn't find any spawn positions"

		for index, otherPlayerTable in ipairs @GameData.PlayerTables
			continue unless IsValid otherPlayerTable.entity

			with otherPlayerTable.entity
				-- Unvent vented players.
				-- The reason why this block isn't just calling Player_UnVent
				-- is that we don't want to play animations in front of everyone.
				if @GameData.Vented[otherPlayerTable]
					@Player_Unhide otherPlayerTable.entity
					@Player_UnPauseKillCooldown otherPlayerTable
					@Net_NotifyVent otherPlayerTable, @VentNotifyReason.UnVent
					@GameData.Vented[otherPlayerTable] = false

				-- Spread the players around.
				point = spawns[((index - 1) % #spawns) + 1]
				\SetPos point\GetPos!
				\SetAngles point\GetAngles!
				\SetEyeAngles point\GetAngles!

		time = @ConVarSnapshots.VotePreTime\GetInt! + DISCUSS_SPLASH_TIME
		@Net_BroadcastDiscuss playerTable, CurTime! + time

		-- Wait for the meeting to start.
		timer.Create handle, time, 1, ->
			@GameData.Voting = true
			table.Empty @GameData.Votes
			table.Empty @GameData.VotesMap

			-- If the convar is set, make bots vote.
			if @ConVarSnapshots.MeetingBotVote\GetBool!
				for ply in *player.GetAll!
					continue unless ply\IsBot!

					botHandle = "BotVote #{ply\Nick!}"
					GAMEMODE.GameData.Timers[botHandle] = true

					time = (math.random 1, 50 * math.min 5, @ConVarSnapshots.VoteTime\GetInt!) / 50
					timer.Create botHandle, time, 1, ->
						GAMEMODE.GameData.Timers[botHandle] = nil

						skip = math.random! > 0.8
						rnd = table.Random @GetAlivePlayers!
						@Meeting_Vote ply\GetAUPlayerTable!, not skip and rnd

			timer.Create handle, @ConVarSnapshots.VoteTime\GetInt!, 1, ->
				@Meeting_End!

	return true

GM.Meeting_Vote = (playerTable, target) =>
	if playerTable and @IsGameInProgress! and @GameData.Voting and not @GameData.VotesMap[playerTable] and not @GameData.DeadPlayers[playerTable]
		@GameData.VotesMap[playerTable] = true

		if not target
			target = skipPlaceholder

		@GameData.Votes[target] or= {}
		table.insert @GameData.Votes[target], playerTable

		countAlive = 0
		for ply in *@GameData.PlayerTables
			if IsValid(ply.entity) and (not ply.entity\IsBot! or
				(ply.entity\IsBot! and @ConVarSnapshots.MeetingBotVote\GetBool!)) and
				not GAMEMODE.GameData.DeadPlayers[ply]
					countAlive += 1

		voted = table.Count(@GameData.VotesMap)

		@Net_BroadcastVote playerTable, countAlive - voted

		if voted >= countAlive
			timer.Destroy "meeting"
			@Meeting_End!

GM.Meeting_FinalizeVotes = =>
	voteTable = {}
	for target, votes in pairs @GameData.Votes
		table.insert voteTable, {
			:target
			:votes
		}

	@GameData.Voting = false

	table.sort voteTable, (a, b) ->
		return #a.votes > #b.votes

	-- Player has been ejected.
	return voteTable, @EjectReason.Vote if not voteTable[1]

	-- Tie.
	return voteTable, @EjectReason.Tie if voteTable[1] and voteTable[2] and
		#voteTable[1].votes == #voteTable[2].votes

	-- Skip.
	return voteTable, @EjectReason.Skipped if voteTable[1].target.id == 0

	return voteTable, @EjectReason.Vote, voteTable[1].target

GM.Meeting_End = =>
	handle = "meeting"

	voteTable, reason, ejected = @Meeting_FinalizeVotes!

	-- Calculate the extra time.
	maxVotes = 0
	for vote in *voteTable
		voteCount = #vote.votes
		maxVotes = voteCount if voteCount > maxVotes

	time = @ConVarSnapshots.VotePostTime\GetInt! + (math.min(8, maxVotes) * 0.5 - .1)
	@Net_BroadcastMeetingEnd voteTable, CurTime! + time

	timer.Create handle, time, 1, ->
		@Net_BroadcastEject reason, ejected

		if ejected
			@Logger.Info "#{ejected.nickname} has been ejected"
			@Player_SetDead ejected
		else
			@Logger.Info "Nobody has been ejected during the meeting"

		timer.Pause "NMW AU CheckWin"
		timer.Create handle, 8, 1, ->
			for ply in *player.GetAll!
				ply\Freeze false

			if not @Game_CheckWin!
				@Game_StartRound!

			timer.UnPause "NMW AU CheckWin"
			if timer.Exists "timelimit"
				timer.UnPause "timelimit"

			@SetMeetingInProgress false

			hook.Call "GMAU MeetingEnd"

GM.Meeting_ResetCooldown = =>
	SetGlobalFloat "NMW AU NextMeeting", CurTime! + @ConVarSnapshots.MeetingCooldown\GetFloat!
