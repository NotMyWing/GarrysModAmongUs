util.AddNetworkString "NMW AU Flow"

GM.Net_SendGameState = (ply, state) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.GameState, @FlowSize
	net.WriteUInt state, 4
	net.Send ply

GM.Net_BroadcastCountdown = (time) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.Countdown, @FlowSize
	net.WriteDouble time
	net.Broadcast!

GM.Net_BroadcastDiscuss = (playerTable) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.OpenDiscuss, @FlowSize
	net.WriteUInt playerTable.id, 8
	net.Broadcast!

GM.Net_BroadcastEject = (reason, playerTable) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.Eject, @FlowSize
	net.WriteUInt (reason or 0), 4
	if playerTable
		net.WriteBool true
		net.WriteUInt playerTable.id, 8
	else
		net.WriteBool false

	confirm = @ConVars.ConfirmEjects\GetBool!
	net.WriteBool confirm
	if confirm
		imposter = playerTable and @GameData.Imposters[playerTable]
		net.WriteBool imposter

		numImposters = 0
		for imposter in pairs @GameData.Imposters
			if not @GameData.DeadPlayers[imposter] and not (playerTable and imposter.id == playerTable.id)
				numImposters += 1

		net.WriteUInt numImposters, 8
		net.WriteUInt table.Count(@GameData.Imposters), 8

	net.Broadcast!

GM.Net_BroadcastMeeting = (playerTable, bodyColor) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.Meeting, @FlowSize
	net.WriteUInt playerTable.id, 8
	if bodyColor
		net.WriteBool true
		net.WriteColor bodyColor
	else
		net.WriteBool false

	net.Broadcast!

GM.BroadcastVote = (playerTable, current, remaining) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.MeetingVote, @FlowSize
	net.WriteUInt playerTable.id, 8
	net.WriteUInt current, 8
	net.WriteUInt remaining, 8
	net.Broadcast!

GM.Net_BroadcastMeetingEnd = (results) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.MeetingEnd, @FlowSize
	net.WriteUInt #results, 8
	for _, result in pairs results
		net.WriteUInt result.target.id, 8
		net.WriteUInt #result.votes, 8
		for _, voter in pairs result.votes
			net.WriteUInt voter.id, 8

	net.Broadcast!

GM.Net_BroadcastGameOver = (reason) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.GameOver, @FlowSize
	net.WriteUInt reason, 4
	net.WriteUInt table.Count(@GameData.Imposters), 8
	for imposter in pairs @GameData.Imposters
		net.WriteUInt imposter.id, 8

	net.Broadcast!

GM.Net_BroadcastVent = (ply, where, appearing = false) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.VentAnim, @FlowSize
	net.WriteEntity ply
	net.WriteVector where
	net.WriteBool appearing
	net.SendPVS where

GM.Net_UpdateGameData = (ply) =>
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

GM.Net_BroadcastGameStart = =>
	for index, ply in ipairs @GameData.PlayerTables
		if IsValid ply.entity
			@Net_UpdateGameData ply.entity

GM.Net_UpdateKillCooldown = (playerTable, cd) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.KillCooldown, @FlowSize
	net.WriteDouble cd
	net.Send playerTable.entity

GM.Net_PauseKillCooldown = (playerTable, pause, remainder) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.KillCooldownPause, @FlowSize
	net.WriteBool pause

	if not pause
		net.WriteDouble remainder

	net.Send ply.entity

GM.Net_BroadcastDead = =>
	dead = {}
	for playerTable, _ in pairs @GameData.DeadPlayers
		table.insert dead, playerTable.id

	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.BroadcastDead, @FlowSize
	net.WriteUInt #dead, 8
	for _, id in ipairs dead
		net.WriteUInt id, 8

	net.Broadcast!

GM.Net_KillNotify = (playerTable) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.KillRequest, @FlowSize
	net.Send playerTable.entity

GM.Net_NotifyVent = (playerTable, reason, links) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.NotifyVent, @FlowSize
	net.WriteUInt reason, 4

	net.WriteBool not not links
	if links
		net.WriteUInt #links, 8
		for i = 1, #links
			net.WriteString links[i]

	net.Send playerTable.entity

net.Receive "NMW AU Flow", (len, ply) ->
	playerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[ply]

	switch net.ReadUInt GAMEMODE.FlowSize
		when GAMEMODE.FlowTypes.KillRequest
			if playerTable and GAMEMODE.IsGameInProgress! and GAMEMODE.GameData.Imposters[playerTable] and not ply\IsFrozen!
				target = net.ReadEntity!

				if target = GAMEMODE.GameData.Lookup_PlayerByEntity[target]
					GAMEMODE\Player_Kill target, playerTable

		when GAMEMODE.FlowTypes.VentRequest
			if playerTable and GAMEMODE.IsGameInProgress! and GAMEMODE.GameData.Vented[playerTable] and not ply\IsFrozen!
				target = net.ReadUInt 8
				GAMEMODE\Player_VentTo playerTable, target

		when GAMEMODE.FlowTypes.MeetingVote
			if playerTable and GAMEMODE.IsGameInProgress!
				skip = net.ReadBool!
				target = if not skip
					net.ReadUInt 8

				target = GAMEMODE.GameData.Lookup_PlayerByID[target]
				GAMEMODE\Meeting_Vote playerTable, target

		when GAMEMODE.FlowTypes.RequestUpdate
			if not ply.nwm_au_updated
				ply.nwm_au_updated = true
				
				if GAMEMODE.IsGameInProgress!
					GAMEMODE\Net_UpdateGameData ply

GM.SetGameInProgress = (state) => SetGlobalBool "NMW AU GameInProgress", state