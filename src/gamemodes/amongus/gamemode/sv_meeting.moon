DISCUSS_SPLASH_TIME = 3

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
	@Net_BroadcastTaskCount @GameData.CompletedTasks, @GameData.TotalTasks

	if bodyColor
		@Logger.Info "#{playerTable.nickname} has found a body! Calling a meeting"
	else
		@Logger.Info "#{playerTable.nickname} has called a meeting"

	hook.Call "GMAU MeetingStart", nil, playerTable.entity, bodyColor

	timer.Pause "NMW AU CheckWin"
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
						@Meeting_Vote ply\GetAUPlayerTable!, not skip and rnd or nil

			timer.Create handle, @ConVarSnapshots.VoteTime\GetInt!, 1, ->
				@Meeting_End!

	return true

GM.Meeting_Vote = (voter, target = 0) =>
	-- Bail if the meeting isn't in progress.
	return unless @IsGameInProgress!
	return unless @IsMeetingInProgress!

	if "Player" == type voter
		voter = voter\GetAUPlayerTable!
	return unless voter

	-- Bail if already voted.
	return if @GameData.VotesMap[voter]

	-- Bail if dead.
	return if @GameData.DeadPlayers[voter]

	-- If the provided target is a player, try getting the table.
	if "Player" == type target
		target = target\GetAUPlayerTable!

	local targetTable

	-- If the provided target is a player, retrieve the id.
	if "table" == type target
		targetTable = target
		target = target.id

	-- If the provided target is a number, do a boundary check.
	if "number" == type target
		target = math.floor target

		return unless target == 0 or @GameData.Lookup_PlayerByID[target]

	targetTable or= @GameData.Lookup_PlayerByID[target]

	-- Bail if dead.
	return if @GameData.DeadPlayers[targetTable]

	-- Why are we still here?
	return unless target

	@GameData.VotesMap[voter] = true

	-- Create a table for the target if doesn't exist and put our vote.
	@GameData.Votes[target] or= {}
	table.insert @GameData.Votes[target], voter.id

	-- Count all alive players.
	countAlive = 0
	for ply in *@GameData.PlayerTables
		if IsValid(ply.entity) and (not ply.entity\IsBot! or
			(ply.entity\IsBot! and @ConVarSnapshots.MeetingBotVote\GetBool!)) and
			not GAMEMODE.GameData.DeadPlayers[ply]
				countAlive += 1

	-- Count all current votes.
	currentVotes = table.Count @GameData.VotesMap

	-- Broadcast the vote. End the meeting if we have enough votes.
	@Net_BroadcastVote voter, countAlive - currentVotes
	if currentVotes >= countAlive
		timer.Destroy "meeting"
		@Meeting_End!

GM.Meeting_FinalizeVotes = =>
	voteTable = {}
	for target, votes in pairs @GameData.Votes
		table.insert voteTable, {
			:target
			:votes
		}

	table.sort voteTable, (a, b) ->
		return #a.votes > #b.votes

	-- Player has been ejected.
	return voteTable, @EjectReason.Vote if not voteTable[1]

	-- Tie.
	return voteTable, @EjectReason.Tie if voteTable[1] and voteTable[2] and
		#voteTable[1].votes == #voteTable[2].votes

	-- Skip.
	return voteTable, @EjectReason.Skipped if voteTable[1].target == 0

	return voteTable, @EjectReason.Vote, voteTable[1].target

GM.Meeting_End = =>
	handle = "meeting"

	voteTable, reason, ejected = @Meeting_FinalizeVotes!

	if ejected
		ejected = @GameData.Lookup_PlayerByID[ejected]

	-- Calculate the extra time and anonymize the votes if required.
	shouldAnonymize = @ConVarSnapshots.VoteAnonymous\GetBool!
	maxVotes = 0
	for vote in *voteTable
		voteCount = #vote.votes
		maxVotes = voteCount if voteCount > maxVotes

		if shouldAnonymize
			for i = 1, voteCount
				vote.votes[i] = 0

	-- Calculate the total time and broadcast the end of the meeting.
	time = @ConVarSnapshots.VotePostTime\GetInt! + (math.min(8, maxVotes) * 0.5 - .1)
	@Net_BroadcastMeetingEnd voteTable, CurTime! + time

	timer.Create handle, time, 1, ->
		-- Wait {time} seconds, then broadcast the eject animation to the players.
		@Net_BroadcastEject reason, ejected

		if ejected
			@Logger.Info "#{ejected.nickname} has been ejected"
		else
			@Logger.Info "Nobody has been ejected during the meeting"

		timer.Create handle, 8, 1, ->
			-- The meeting is no longer in progress. Update variables and fire hooks.
			@SetMeetingInProgress false
			hook.Call "GMAU MeetingEnd", nil, reason, ejected

			-- Actualy eject the most voted person.
			if ejected
				@Player_SetDead ejected

			-- Check if someone has won.
			return if @Game_CheckWin!

			-- Unfreeze everyone.
			for ply in *player.GetAll!
				ply\Freeze false

			-- Restart the round and reset the timelimit timer if exists.
			@Game_StartRound!
			timer.UnPause "NMW AU CheckWin"
			if timer.Exists "timelimit"
				timer.UnPause "timelimit"

GM.Meeting_ResetCooldown = =>
	SetGlobalFloat "NMW AU NextMeeting", CurTime! + @ConVarSnapshots.MeetingCooldown\GetFloat!
