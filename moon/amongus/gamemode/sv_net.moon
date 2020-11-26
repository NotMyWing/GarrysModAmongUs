--- All things netcode.
-- Handles pretty much everything related to networking stuff between the server and clients.
-- @module sv_net

util.AddNetworkString "NMW AU Flow"

--- Sends the game state update.
-- @param ply Player entity.
GM.Net_UpdateGameState = (ply) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.GameState, @FlowSize
	net.WriteUInt @GameData.State, 4
	net.Send ply

--- Sends the game state update to everyone.
GM.Net_BroadcastGameState = =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.GameState, @FlowSize
	net.WriteUInt @GameData.State, 4
	net.Broadcast!

--- Broadcasts a countdown.
-- @param time Absolute time based on CurTime().
GM.Net_BroadcastCountdown = (time) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.GameCountdown, @FlowSize
	net.WriteDouble time
	net.Broadcast!

--- Notifies the players that they should open their meeting tablets.
-- @param playerTable Meeting caller.
GM.Net_BroadcastDiscuss = (playerTable) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.MeetingOpenDiscuss, @FlowSize
	net.WriteUInt playerTable.id, 8
	net.Broadcast!

--- Notifies the players that they should open their meeting tablets.
-- @param reason Why did we eject? See shared.moon.
-- @param playerTable The ejected player. Optional.
GM.Net_BroadcastEject = (reason, playerTable) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.MeetingEject, @FlowSize
	net.WriteUInt (reason or 0), 4
	if playerTable
		net.WriteBool true
		net.WriteUInt playerTable.id, 8
	else
		net.WriteBool false

	confirm = @ConVarSnapshots.ConfirmEjects\GetBool!
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

--- Notifies the players that somebody has called the meeting.
-- @param playerTable Meeting caller.
GM.Net_BroadcastMeeting = (playerTable, bodyColor) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.MeetingStart, @FlowSize
	net.WriteUInt playerTable.id, 8
	if bodyColor
		net.WriteBool true
		net.WriteColor bodyColor
	else
		net.WriteBool false

	net.Broadcast!

--- Notifies the players that somebody has just voted.
-- @param playerTable Meeting caller.
-- @param current How many votes we still need?
GM.Net_BroadcastVote = (playerTable, remaining) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.MeetingVote, @FlowSize
	net.WriteUInt playerTable.id, 8
	net.WriteUInt remaining, 8
	net.Broadcast!

--- Notifies the players about the meeting results.
-- @param results Meeting/voting results.
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

--- Notifies the players that the game is over.
-- Are we losing son?
-- @param reason Why did we lose? See shared.moon.
GM.Net_BroadcastGameOver = (reason) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.GameOver, @FlowSize
	net.WriteUInt reason, 4
	net.WriteUInt table.Count(@GameData.Imposters), 8
	for imposter in pairs @GameData.Imposters
		net.WriteUInt imposter.id, 8

	net.Broadcast!

--- Notifies the nearby players that someone has vented.
-- Spawns a ghost entity for everyone around the spot.
-- IMPORTANT: this function accepts ENTITIES, not PLAYER TABLES.
-- TO-DO: it should not.
-- @param ply Player entity.
-- @param where Where?
-- @param appearing Is the person venting out?
GM.Net_BroadcastVent = (ply, where, appearing = false) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.VentAnim, @FlowSize
	net.WriteEntity ply
	net.WriteVector where
	net.WriteBool appearing
	net.SendPVS where

--- Updates the player with the current game data.
-- IMPORTANT! This function accepts ENTITIES, not PLAYER TABLES.
-- If, for some reason, you want to call this.
-- You shouldn't, really. Unless you know what you're doing.
-- @param ply Player entity.
GM.Net_UpdateGameData = (ply) =>
	playerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[ply]

	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.GameStart, @FlowSize

	net.WriteTable @ConVarSnapshot_ExportAll!

	net.WriteUInt #@GameData.PlayerTables, 8
	for aply in *@GameData.PlayerTables
		net.WriteString aply.steamid
		net.WriteString aply.nickname
		net.WriteColor aply.color
		net.WriteEntity aply.entity
		net.WriteUInt aply.id, 8

	net.WriteUInt table.Count(@GameData.Imposters), 8
	if @GameData.Imposters[playerTable]
		net.WriteBool true
		for imposter in pairs @GameData.Imposters
			net.WriteUInt imposter.id, 8
	else
		net.WriteBool false

	dead = {}
	for deadPlayerTable in pairs @GameData.DeadPlayers
		table.insert dead, deadPlayerTable.id

	net.WriteUInt #dead, 8
	for id in *dead
		net.WriteUInt id, 8

	net.WriteUInt @GameData.CompletedTasks or 0, 32

	net.Send ply

--- Updates everyone with the current game data.
-- Don't call this unless you have a solid reason to.
GM.Net_BroadcastGameStart = =>
	for index, ply in ipairs @GameData.PlayerTables
		if IsValid ply.entity
			@Net_UpdateGameData ply.entity

--- Notifies the player that his kill cooldown has changed.
-- @param playerTable An imposter.
-- @param cd New cooldown, absolute time based on CurTime().
GM.Net_UpdateKillCooldown = (playerTable, cd) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.KillCooldown, @FlowSize
	net.WriteDouble cd
	net.Send playerTable.entity

--- Notifies the player that his kill cooldown has been (un-)paused.
-- @param playerTable An imposter.
-- @param pause Has the cooldown been paused?
-- @param remainder If the cooldown has been paused, send the remaining time.
GM.Net_PauseKillCooldown = (playerTable, remainder) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.KillCooldownPause, @FlowSize
	net.WriteDouble remainder

	net.Send playerTable.entity

--- Updates all players with the new dead players table.
GM.Net_BroadcastDead = =>
	dead = {}
	for playerTable in pairs @GameData.DeadPlayers
		table.insert dead, playerTable.id

	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.BroadcastDead, @FlowSize
	net.WriteUInt #dead, 8
	for id in *dead
		net.WriteUInt id, 8

	net.Broadcast!

--- Updates all ghosts with the new dead players table.
GM.Net_BroadcastDeadToGhosts = =>
	dead = {}
	for playerTable in pairs @GameData.DeadPlayers
		table.insert dead, playerTable.id

	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.BroadcastDead, @FlowSize
	net.WriteUInt #dead, 8
	for id in *dead
		net.WriteUInt id, 8

	net.Send for playerTable in pairs @GameData.DeadPlayers
		continue unless IsValid playerTable.entity

		playerTable.entity

--- Notifies the player that he has, in fact, just commited a crime.
-- @param playerTable An imposter.
GM.Net_KillNotify = (playerTable) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.KillRequest, @FlowSize
	net.Send playerTable.entity

--- Notifies the player that he has, in fact, just vented.
-- @param playerTable An imposter.
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

--- Updates the player with the new task data.
-- Even if nothing has been visually changed, this creates a "beep" sound.
-- The implementation of this method is currently atrocious.
-- @param playerTable The tasked crewmate.
-- @param taskInstance The task instance.
GM.Net_UpdateTaskData = (playerTable, taskName, packet) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.TasksUpdateData, @FlowSize
	net.WriteString taskName
	net.WriteTable packet
	net.Send playerTable.entity

--- Broadcasts the new task count.
-- @param count New task count.
GM.Net_BroadcastTaskCount = (count, total) =>
	-- Don't broadcast if comms are sabotaged.
	if @GetCommunicationsDisabled!
		return

	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.TasksUpdateCount, @FlowSize
	net.WriteUInt count, 32
	net.WriteUInt total, 32
	net.Broadcast!

--- Notifies the players that it's time to close their tasks.
GM.Net_BroadcastCloseVGUI = =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.CloseVGUI, @FlowSize
	net.Broadcast!

--- Notifies the player that it's time to close their tasks.
-- @param playerTable The tasked crewmate.
GM.Net_SendCloseVGUI = (playerTable) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.CloseVGUI, @FlowSize
	net.Send playerTable.entity

--- Notifies the player that he's dead.
-- @param playerTable The killed.
-- @param killerTable The killer.
GM.Net_SendNotifyKilled = (playerTable, killerTable) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.NotifyKilled, @FlowSize
	net.WriteUInt killerTable.id, 8

	net.Send playerTable.entity

--- Broadcasts sabotage data to players.
-- The packet must be a valid accessor table.
-- @param id Sabotage ID.
-- @param packet Data table.
-- @param imposter Optional. Broadcast to imposters only?
GM.Net_BroadcastSabotageData = (id, packet, imposter = false) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.SabotageData, @FlowSize
	net.WriteUInt id, 8
	net.WriteTable packet

	if not imposter
		net.Broadcast!
	else
		players = {}
		for ply in pairs @GameData.Imposters
			if IsValid ply.entity
				table.insert players, ply.entity

		net.Send players

--- Broadcasts imposter-specific sabotage data to the imposters.
-- The packet must be a valid accessor table.
-- @param id Sabotage ID.
-- @param packet Data table.
GM.Net_BroadcastSabotageDataImposter = (id, packet) =>
	@Net_BroadcastSabotageData id, packet, true

--- Broadcasts ConVar snapshots.
-- @param snapshots ConVar snapshots.
GM.Net_BroadcastConVarSnapshots = (snapshots) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.ConVarSnapshots, @FlowSize
	net.WriteTable snapshots
	net.Broadcast!

--- Sends a connect/disconnect update to everyone.
-- @param snapshots ConVar snapshots.
GM.Net_BroadcastConnectDisconnect = (nickname, connected, spectator = false) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.ConnectDisconnect, @FlowSize
	net.WriteString nickname
	net.WriteBool connected
	net.WriteBool spectator
	net.Broadcast!

--- Tells the player to open a VGUI.
-- @param playerTable Player table.
-- @param id Sabotage ID.
-- @param packet Data table.
GM.Net_OpenVGUI = (playerTable, data) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.OpenVGUI, @FlowSize
	net.WriteTable data
	net.Send playerTable.entity

--- Sends a game chat error message to the player.
-- @param messageData
GM.Net_SendGameChatError = (playerTable) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.GameChatNotification, @FlowSize
	net.Send playerTable.entity

--- Sends a ShowHelp ack.
GM.Net_SendShowHelp = (ply) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.ShowHelp, @FlowSize
	net.Send ply

net.Receive "NMW AU Flow", (len, ply) ->
	playerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[ply]

	switch net.ReadUInt GAMEMODE.FlowSize
		--
		-- Player wants to kill somebody.
		--
		when GAMEMODE.FlowTypes.KillRequest
			if playerTable and GAMEMODE.IsGameInProgress! and GAMEMODE.GameData.Imposters[playerTable] and not ply\IsFrozen!
				target = net.ReadEntity!

				if target = GAMEMODE.GameData.Lookup_PlayerByEntity[target]
					GAMEMODE\Player_Kill target, playerTable

		--
		-- Player wants to vent to a different spot.
		--
		when GAMEMODE.FlowTypes.VentRequest
			if playerTable and GAMEMODE.IsGameInProgress! and GAMEMODE.GameData.Vented[playerTable] and not ply\IsFrozen!
				target = net.ReadUInt 8
				GAMEMODE\Player_VentTo playerTable, target

		--
		-- Player wants to submit a vote.
		--
		when GAMEMODE.FlowTypes.MeetingVote
			if playerTable and GAMEMODE.IsGameInProgress!
				skip = net.ReadBool!
				target = if not skip
					net.ReadUInt 8

				target = GAMEMODE.GameData.Lookup_PlayerByID[target]
				GAMEMODE\Meeting_Vote playerTable, target

		--
		-- Player wants to sync the game data.
		--
		when GAMEMODE.FlowTypes.RequestUpdate
			if not ply\GetNWBool "NMW AU Initalized"
				ply\SetNWBool "NMW AU Initialized", true

				if GAMEMODE.IsGameInProgress!
					GAMEMODE\Net_UpdateGameData ply

				GAMEMODE\Net_UpdateGameState ply

		--
		-- Player has closed the task window.
		--
		when GAMEMODE.FlowTypes.CloseVGUI
			if playerTable
				GAMEMODE\Player_CloseVGUI playerTable

		--
		-- Player has submitted a task.
		--
		when GAMEMODE.FlowTypes.TasksSubmit
			if playerTable
				GAMEMODE\Task_Submit playerTable, net.ReadUInt 32

		--
		-- Player has requested a sabotage.
		--
		when GAMEMODE.FlowTypes.SabotageRequest
			if playerTable
				GAMEMODE\Sabotage_Start playerTable, net.ReadUInt 8

		--
		-- Player has submitted a sabotage.
		--
		when GAMEMODE.FlowTypes.SabotageSubmit
			if playerTable
				GAMEMODE\Sabotage_Submit playerTable, net.ReadUInt 32

--- Sets whether the game is in progress.
-- @bool state You guessed it again.
GM.SetGameInProgress = (state) => SetGlobalBool "NMW AU GameInProgress", state

--- Sets the current time limit.
-- You pretty much don't ever need to call this manually.
-- This is used internally by the timeout timer.
-- Setting this would just cause the value to get overwritten back.
-- @param value You guessed it again.
GM.SetTimeLimit = (value) => SetGlobalInt "NMW AU TimeLimit", value

--- Sets whether the communications are sabotaged.
-- This hides the task bar, task list and map icons for crewmates.
-- Can potentially affect objects on the map.
-- @bool state You guessed it again.
GM.SetCommunicationsDisabled = (value) =>
	SetGlobalBool "NMW AU CommsDisabled", value

	if not value and @GameData.CompletedTasks
		@Net_BroadcastTaskCount @GameData.CompletedTasks, @GameData.TotalTasks

--- Sets whether the meeting button is disabled.
-- This is automatically called whenever a major sabotage is (de-)activated.
-- @bool state You guessed it again.
GM.SetMeetingDisabled = (value) =>
	SetGlobalBool "NMW AU MeetingDisabled", value

--- Sets whether the meeting button is in progress.
-- @bool state You guessed it again.
GM.SetMeetingInProgress = (value) =>
	SetGlobalBool "NMW AU MeetingInProgress", value

--- Sets whether the game is commencing.
-- This is mostly used to lock clientside convar displays.
-- @bool state You guessed it again.
GM.SetGameCommencing = (value) =>
	SetGlobalBool "NMW AU GameCommencing", value

--- Sets the game state.
-- @return You guessed it again.
GM.SetGameState = (newState) =>
	@GameData.State = newState
	@Net_BroadcastGameState newState

--- Sets whether the game flow is controlled by the server.
-- @return You guessed it again.
GM.SetOnAutoPilot = (newState) =>
	SetGlobalBool "NMW AU AutoPilot", newState
