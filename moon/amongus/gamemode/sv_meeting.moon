skipPlaceholder = { id: 0 }

GM.Meeting_Start = (ply, bodyColor) =>
	if not @IsGameInProgress!
		return

	aply = @GameData.Lookup_PlayerByEntity[ply]

	handle = "meeting"
	if @GameData.DeadPlayers[aply]
		return

	if timer.Exists handle
		return

	if timer.Exists "timelimit"
		timer.Pause "timelimit"

	for index, ply in ipairs player.GetAll!
		ply\Freeze true

	@Player_CloseTasksForEveryone!

	@GameData.Timers[handle] = true
	timer.Create handle, 0.2, 1, ->
		@Net_BroadcastDead!
		@Net_BroadcastMeeting aply, bodyColor

		timer.Create handle, 3, 1, ->
			spawns = ents.FindByClass "info_player_start"
			for index, ply in ipairs @GameData.PlayerTables
				if IsValid ply.entity
					with ply.entity
						point = spawns[(index % #spawns) + 1]
						\SetPos point\GetPos!
						\SetAngles point\GetAngles!
						\SetEyeAngles point\GetAngles!

						if @GameData.Vented[ply] and not @GameData.DeadPlayers[ply]
							@Player_Unhide playerTable.entity
							@Player_UnPauseKillCooldown playerTable
							@Net_NotifyVent ply, @VentNotifyReason.UnVent
							@GameData.Vented[ply] = false

			@Net_BroadcastDiscuss aply

			timer.Create handle, @ConVars.VotePreTime\GetInt! + 3, 1, ->
				@GameData.Voting = true
				table.Empty @GameData.Votes
				table.Empty @GameData.VotesMap

				for _, ply in ipairs player.GetAll!
					if false and ply\IsBot!
						skip = math.random! > 0.8
						rnd = table.Random @GetAlivePlayers!
						@Meeting_Vote ply, not skip and rnd

				timer.Create handle, @ConVars.VoteTime\GetInt!, 1, ->
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
		for _, ply in pairs @GameData.PlayerTables
			if IsValid(ply.entity) and not GAMEMODE.GameData.DeadPlayers[ply]
				countAlive += 1

		needed = table.Count(@GameData.VotesMap)

		@BroadcastVote playerTable, countAlive, needed

		if needed >= countAlive
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

	if not voteTable[1]
		return voteTable, @EjectReason.Vote

	if voteTable[1] and voteTable[2] and #voteTable[1].votes == #voteTable[2].votes
		return voteTable, @EjectReason.Tie

	if voteTable[1].target.id == 0
		return voteTable, @EjectReason.Skipped

	return voteTable, @EjectReason.Vote, voteTable[1].target

GM.Meeting_End = =>
	handle = "meeting"

	voteTable, reason, ejected = @Meeting_FinalizeVotes!
	@Net_BroadcastMeetingEnd voteTable

	timer.Create handle, @ConVars.VotePostTime\GetInt!, 1, ->
		@Net_BroadcastEject reason, ejected

		if ejected
			@Player_SetDead ejected

		timer.Pause "NMW AU CheckWin"
		timer.Create handle, 8, 1, ->
			for index, ply in ipairs player.GetAll!
				ply\Freeze false

			if not @CheckWin!
				@StartRound!

			timer.UnPause "NMW AU CheckWin"
			if timer.Exists "timelimit"
				timer.UnPause "timelimit"

GM.Meeting_ResetCooldown = =>
	SetGlobalFloat "NMW AU NextMeeting", CurTime! + @ConVars.MeetingCooldown\GetFloat!
