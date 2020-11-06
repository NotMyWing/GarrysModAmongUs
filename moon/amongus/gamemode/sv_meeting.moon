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

	@Player_CloseVGUIsForEveryone!
	@Sabotage_EndNonPersistent!
	@SetMeetingInProgress true

	@GameData.Timers[handle] = true
	timer.Create handle, 0.2, 1, ->
		@Net_BroadcastDead!
		@Net_BroadcastMeeting aply, bodyColor
		if bodyColor
			@Logger.Info "#{ply\Nick!} has found a body! Calling a meeting"
		else
			@Logger.Info "#{ply\Nick!} has called a meeting"

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

			timer.Create handle, @ConVarSnapshots.VotePreTime\GetInt! + 3, 1, ->
				@GameData.Voting = true
				table.Empty @GameData.Votes
				table.Empty @GameData.VotesMap

				if @ConVarSnapshots.MeetingBotVote\GetBool!
					for _, ply in ipairs player.GetAll!
						if ply\IsBot!
							handle = "BotVote #{ply\Nick!}"
							GAMEMODE.GameData.Timers[handle] = true
							timer.Create handle, (math.random 1, 50 * math.min 5, @ConVarSnapshots.VoteTime\GetInt!) / 50, 1, ->
								GAMEMODE.GameData.Timers[handle] = nil

								skip = math.random! > 0.8
								rnd = table.Random @GetAlivePlayers!
								@Meeting_Vote @GameData.Lookup_PlayerByEntity[ply], not skip and rnd

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
		for _, ply in pairs @GameData.PlayerTables
			if (IsValid(ply.entity) and not ply.entity\IsBot! and not GAMEMODE.GameData.DeadPlayers[ply]) or
				(@ConVarSnapshots.MeetingBotVote\GetBool! and ply.entity\IsBot!)
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

	timer.Create handle, @ConVarSnapshots.VotePostTime\GetInt!, 1, ->
		@Net_BroadcastEject reason, ejected

		if ejected
			@Logger.Info "#{ejected.nickname} has been ejected"
			@Player_SetDead ejected
		else
			@Logger.Info "Nobody has been ejected during the meeting"

		timer.Pause "NMW AU CheckWin"
		timer.Create handle, 8, 1, ->
			for index, ply in ipairs player.GetAll!
				ply\Freeze false

			if not @Game_CheckWin!
				@Game_StartRound!

			timer.UnPause "NMW AU CheckWin"
			if timer.Exists "timelimit"
				timer.UnPause "timelimit"

			@Sabotage_RefreshAllCooldowns!
			@SetMeetingInProgress false

GM.Meeting_ResetCooldown = =>
	SetGlobalFloat "NMW AU NextMeeting", CurTime! + @ConVarSnapshots.MeetingCooldown\GetFloat!
