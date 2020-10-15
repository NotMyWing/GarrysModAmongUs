util.AddNetworkString "NMW AU Flow"

GM.SendGameState = (ply, state) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.GameState, @FlowSize
	net.WriteUInt state, 4
	net.Send ply

GM.BroadcastCountdown = (target) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.Countdown, @FlowSize
	net.WriteDouble target
	net.Broadcast!

GM.BroadcastDiscuss = (plyid) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.OpenDiscuss, @FlowSize
	net.WriteUInt plyid, 8
	net.Broadcast!

GM.BroadcastEject = (reason, plyid) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.Eject, @FlowSize
	net.WriteUInt (reason or 0), 4
	if plyid
		net.WriteBool true
		net.WriteUInt plyid, 8
	else
		net.WriteBool false

	confirm = @ConVars.ConfirmEjects\GetBool!
	net.WriteBool confirm
	if confirm
		imposter = @GameData.Imposters[@GameData.Lookup_PlayerByID[plyid]]
		net.WriteBool imposter

		numImposters = 0
		for _, ply in pairs @GameData.PlayerTables
			if IsValid(ply.entity) and not @GameData.DeadPlayers[ply] and @GameData.Imposters[ply] and ply.id ~= plyid
				numImposters += 1

		net.WriteUInt numImposters, 8

	net.Broadcast!

GM.BroadcastMeeting = (plyid, bodyColor) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.Meeting, @FlowSize
	net.WriteUInt plyid, 8
	if bodyColor
		net.WriteBool true
		net.WriteColor bodyColor
	else
		net.WriteBool false

	net.Broadcast!

GM.BroadcastVote = (plyid, current, remaining) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.Vote, @FlowSize
	net.WriteUInt plyid, 8
	net.WriteUInt current, 8
	net.WriteUInt remaining, 8
	net.Broadcast!

GM.BroadcastVoteEnd = (results) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.VoteEnd, @FlowSize
	net.WriteUInt #results, 8
	for _, result in pairs results
		net.WriteUInt result.target.id, 8
		net.WriteUInt #result.votes, 8
		for _, voter in pairs result.votes
			net.WriteUInt voter.id, 8

	net.Broadcast!

GM.BroadcastGameOver = (reason) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.GameOver, @FlowSize
	net.WriteUInt reason, 4
	net.WriteUInt table.Count(@GameData.Imposters), 8
	for imposter in pairs @GameData.Imposters
		net.WriteUInt imposter.id, 8

	net.Broadcast!

GM.BroadcastVent = (ply, where, appearing = false) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.VentAnim, @FlowSize
	net.WriteEntity ply
	net.WriteVector where
	net.WriteBool appearing
	net.SendPVS where

GM.SendGameData = (ply) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.GameStart, @FlowSize

	net.WriteUInt #@GameData.PlayerTables, 8
	for _, aply in ipairs @GameData.PlayerTables
		net.WriteString aply.steamid
		net.WriteString aply.nickname
		net.WriteColor aply.color
		net.WriteEntity aply.entity
		net.WriteUInt aply.id, 8

	net.WriteUInt table.Count(@GameData.Imposters), 8
	if @GameData.Imposters[GAMEMODE.GameData.Lookup_PlayerByEntity[ply]]
		net.WriteBool true
		for imposter in pairs @GameData.Imposters
			net.WriteUInt imposter.id, 8
	else
		net.WriteBool false

	dead = {}
	for deadPlayerTable, _ in pairs @GameData.DeadPlayers
		table.insert dead, deadPlayerTable.id

	net.WriteUInt #dead, 8
	for _, id in ipairs dead
		net.WriteUInt id, 8

	net.Send ply

GM.BroadcastStart = =>
	for index, ply in ipairs @GameData.PlayerTables
		if IsValid ply.entity
			@SendGameData ply.entity

GM.UpdateKillCooldown = (ply) =>
	cd = CurTime! + @ConVars.KillCooldown\GetFloat!
	@GameData.KillCooldowns[ply] = cd

	if IsValid ply.entity
		net.Start "NMW AU Flow"
		net.WriteUInt @FlowTypes.KillCooldown, @FlowSize
		net.WriteDouble cd
		net.Send ply.entity

GM.PauseKillCooldown = (ply, pause = true) =>
	if @GameData.KillCooldowns[ply]
		net.Start "NMW AU Flow"
		net.WriteUInt @FlowTypes.KillCooldownPause, @FlowSize

		remainder = if pause
			CurTime! - @GameData.KillCooldowns[ply]

		if remainder
			@GameData.KillCooldownRemainders[ply] = remainder
		else
			@GameData.KillCooldowns[ply] = CurTime! + @PauseKillCooldown[ply]
			@GameData.KillCooldownRemainders[ply] = nil

		if IsValid ply.entity
			if remainder
				net.WriteBool true
				net.WriteDouble remainder
			else
				net.WriteBool false

			net.Send ply.entity

GM.UnPauseKillCooldown = (ply) =>
	@PauseKillCooldown false

GM.SetDead = (playerTable) =>
	if IsValid playerTable.entity
		@HidePlayer playerTable.entity

	@GameData.DeadPlayers[playerTable] = true

GM.BroadcastDead = =>
	dead = {}
	for playerTable, _ in pairs @GameData.DeadPlayers
		table.insert dead, playerTable.id

	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.SetDead, @FlowSize
	net.WriteUInt #dead, 8
	for _, id in ipairs dead
		net.WriteUInt id, 8

	net.Broadcast!

GM.KillReply = (ply) =>
	if IsValid ply.entity
		net.Start "NMW AU Flow"
		net.WriteUInt @FlowTypes.KillRequest, @FlowSize
		net.Send ply.entity

GM.NotifyVent = (playerTable, reason, links) =>
	if IsValid playerTable.entity
		net.Start "NMW AU Flow"
		net.WriteUInt @FlowTypes.NotifyVent, @FlowSize
		net.WriteUInt reason, 4

		net.WriteBool not not links
		if links
			net.WriteUInt #links, 8
			for i = 1, #links
				net.WriteString links[i]

		net.Send playerTable.entity

GM.Kill = (victim, attacker, silent) =>
	if attacker
		if not (@GameData.Imposters[attacker]) or (@GameData.Imposters[victim]) or
			(@GameData.KillCooldowns[attacker] >= CurTime!) or
			(@GameData.KillCooldownRemainders[attacker])
				return

	if not @GameData.DeadPlayers[plvictimy]
		if attacker
			@UpdateKillCooldown attacker

		if not silent
			if IsValid victim.entity
				with corpse = ents.Create "prop_ragdoll"
					\SetPos victim.entity\GetPos!
					\SetAngles victim.entity\GetAngles!
					\SetModel victim.entity\GetModel!
					\SetColor victim.entity\GetColor!
					\SetCollisionGroup COLLISION_GROUP_DEBRIS_TRIGGER
					\SetNW2Int "NMW AU PlayerID", victim.id
					\SetUseType SIMPLE_USE
					\Spawn!
					\Activate!
					\PhysWake!
					if bone = \TranslatePhysBoneToBone 5
						\ManipulateBoneScale bone, Vector 0, 0, 0

					if attacker and IsValid attacker.entity
						if phys = \GetPhysicsObject!
							phys\SetVelocity (victim.entity\GetPos! - attacker.entity\GetPos!)\GetNormalized! * 250

						attacker.entity\SetPos victim.entity\GetPos!

			color = victim.entity\GetColor!
			color.a = 32
			victim.entity\SetColor color
			victim.entity\SetRenderMode RENDERMODE_TRANSCOLOR

		@SetDead victim
		if attacker
			@KillReply attacker

		if not silent
			@CheckWin!

GM.VoteEnd = =>
	handle = "meeting"

	voteTable, reason, ejected = @FinalizeVotes!
	@BroadcastVoteEnd voteTable

	timer.Create handle, @ConVars.VotePostTime\GetInt!, 1, ->
		@BroadcastEject reason, ejected and ejected.id

		if ejected
			@Kill ejected, nil, true

		timer.Create handle, 8, 1, ->
			for index, ply in ipairs player.GetAll!
				ply\Freeze false

			if not @CheckWin!
				@StartRound!

skipPlaceholder = { id: 0 }

GM.Vote = (playerTable, target) =>
	if playerTable and @IsGameInProgress! and @Voting and not @GameData.VotesMap[playerTable] and not @GameData.DeadPlayers[playerTable]
		@GameData.VotesMap[playerTable] = true

		if not target
			target = skipPlaceholder

		@Votes[target] or= {}
		table.insert @Votes[target], playerTable

		countAlive = 0
		for _, ply in pairs @GameData.PlayerTables
			if IsValid(ply.entity) and not GAMEMODE.GameData.DeadPlayers[ply]
				countAlive += 1

		needed = table.Count(@GameData.VotesMap)

		@BroadcastVote playerTable.id, countAlive, needed

		if needed >= countAlive
			timer.Destroy "meeting"
			@VoteEnd!

GM.FinalizeVotes = =>
	voteTable = {}
	for target, votes in pairs @Votes
		table.insert voteTable, {
			:target
			:votes
		}

	@Voting = false

	table.sort voteTable, (a, b) ->
		return #a.votes > #b.votes

	if not voteTable[1]
		return voteTable, @EjectReason.Vote

	if voteTable[1] and voteTable[2] and #voteTable[1].votes == #voteTable[2].votes
		return voteTable, @EjectReason.Tie

	if voteTable[1].target.id == 0
		return voteTable, @EjectReason.Skipped

	return voteTable, @EjectReason.Vote, voteTable[1].target

net.Receive "NMW AU Flow", (len, ply) ->
	playerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[ply]

	switch net.ReadUInt GAMEMODE.FlowSize
		when GAMEMODE.FlowTypes.KillRequest
			if playerTable and @IsGameInProgress! and GAMEMODE.GameData.Imposters[playerTable] and not ply\IsFrozen!
				target = net.ReadEntity!

				if target = GAMEMODE.GameData.Lookup_PlayerByEntity[target]
					GAMEMODE\Kill target, playerTable

		when GAMEMODE.FlowTypes.VentRequest
			if playerTable and @IsGameInProgress! and GAMEMODE.GameData.Vented[playerTable] and not ply\IsFrozen!
				target = net.ReadUInt 8
				GAMEMODE\VentTo playerTable, target

		when GAMEMODE.FlowTypes.Vote
			if playerTable and @IsGameInProgress!
				skip = net.ReadBool!
				target = if not skip
					net.ReadUInt 8

				target = GAMEMODE.GameData.Lookup_PlayerByID[target]
				GAMEMODE\Vote playerTable, target

		when GAMEMODE.FlowTypes.RequestUpdate
			if not ply.nwm_au_updated
				ply.nwm_au_updated = true
				
				GAMEMODE\SendGameData ply

GM.HidePlayer = (ply, hide = true) =>
	for _, otherPly in ipairs player.GetAll!
		if otherPly ~= ply
			ply\SetPreventTransmit otherPly, hide

GM.UnhidePlayer = (ply) =>
	@HidePlayer ply, false

GM.UnhideEveryone = =>
	for _, ply in ipairs player.GetAll!
		@UnhidePlayer ply

GM.SetGameInProgress = (state) => SetGlobalBool "NMW AU GameInProgress", state