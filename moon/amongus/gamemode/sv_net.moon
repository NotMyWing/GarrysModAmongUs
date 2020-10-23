util.AddNetworkString "NMW AU Flow"

--- Sends the game state update.
-- IMPORTANT! This function accepts ENTITIES, not PLAYER TABLES.
-- If, for some reason, you want to call this.
-- @param ply Player entity.
-- @param state New state. See shared.moon.
GM.Net_SendGameState = (ply, state) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.GameState, @FlowSize
	net.WriteUInt state, 4
	net.Send ply

--- Broadcasts a countdown.
-- @param time Absolute time based on CurTime().
GM.Net_BroadcastCountdown = (time) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.Countdown, @FlowSize
	net.WriteDouble time
	net.Broadcast!

--- Notifies the players that they should open their meeting tablets.
-- @param playerTable Meeting caller.
GM.Net_BroadcastDiscuss = (playerTable) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.OpenDiscuss, @FlowSize
	net.WriteUInt playerTable.id, 8
	net.Broadcast!

--- Notifies the players that they should open their meeting tablets.
-- @param reason Why did we eject? See shared.moon.
-- @param playerTable The ejected player. Optional.
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

--- Notifies the players that somebody has called the meeting.
-- @param playerTable Meeting caller.
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

--- Notifies the players that somebody has just voted.
-- @param playerTable Meeting caller.
-- @param current How many players have voted so far?
-- @param total How many votes are we expecting total?
GM.BroadcastVote = (playerTable, current, total) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.MeetingVote, @FlowSize
	net.WriteUInt playerTable.id, 8
	net.WriteUInt current, 8
	net.WriteUInt total, 8
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

	net.WriteUInt #@GameData.PlayerTables, 8
	for _, aply in ipairs @GameData.PlayerTables
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
	for deadPlayerTable, _ in pairs @GameData.DeadPlayers
		table.insert dead, deadPlayerTable.id

	net.WriteUInt #dead, 8
	for _, id in ipairs dead
		net.WriteUInt id, 8

	net.WriteUInt @GameData.CompletedTasks, 8
	net.WriteUInt @GameData.TotalTasks, 8
	if playerTable
		-- Send each task and the info the player should be aware of.
		playerTasks = @GameData.Tasks[playerTable]

		net.WriteUInt table.Count(playerTasks), 8
		for name, taskInstance in pairs playerTasks
			net.WriteString name
			net.WriteEntity taskInstance\GetActivationButton!
			net.WriteBool   taskInstance.__isPositionImportant or false

			net.WriteBool taskInstance\IsMultiStep!
			net.WriteUInt taskInstance\GetMaxSteps!, 16
			net.WriteUInt taskInstance\GetCurrentStep!, 16

			net.WriteUInt taskInstance\GetCurrentState!, 16
			net.WriteDouble taskInstance\GetTimeout!

			net.WriteString taskInstance\GetCustomName! or ""
			net.WriteString taskInstance\GetCustomArea! or ""

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
GM.Net_PauseKillCooldown = (playerTable, pause, remainder) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.KillCooldownPause, @FlowSize
	net.WriteBool pause

	if not pause
		net.WriteDouble remainder

	net.Send ply.entity

--- Updates all players with the new dead players table.
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

--- Notifies the player that he's tasked with a task and should open the VGUI.
-- @table playerTable The tasked crewmate.
-- @string name Name of the task.
GM.Net_OpenTaskVGUI = (playerTable, name) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.TasksOpenVGUI, @FlowSize
	net.WriteString name
	net.Send playerTable.entity

--- Updates the player with the new task data.
-- Even if nothing has been visually changed, this creates a "beep" sound.
-- The implementation of this method is currently atrocious.
-- @table playerTable The tasked crewmate.
-- @table taskInstance The task instance.
GM.Net_UpdateTaskData = (playerTable, taskInstance) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.TasksUpdateData, @FlowSize

	net.WriteString taskInstance.Name
	net.WriteBool taskInstance\IsCompleted!
	if not taskInstance\IsCompleted!
		net.WriteEntity taskInstance\GetActivationButton!
		net.WriteBool taskInstance.__isPositionImportant or false
		net.WriteUInt taskInstance\GetCurrentStep!, 16
		net.WriteUInt taskInstance\GetCurrentState!, 16
		net.WriteDouble taskInstance\GetTimeout!
		net.WriteString taskInstance\GetCustomName! or ""
		net.WriteString taskInstance\GetCustomArea! or ""

	net.Send playerTable.entity

--- Broadcasts the new task count.
-- @param count New task count.
GM.Net_BroadcastTaskCount = (count) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.TasksUpdateCount, @FlowSize
	net.WriteUInt count, 8
	net.Broadcast!

--- Notifies the players that it's time to close their tasks.
GM.Net_BroadcastTaskClose = =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.TasksCloseVGUI, @FlowSize
	net.Broadcast!

--- Notifies the player that it's time to close their tasks.
GM.Net_SendTaskClose = (playerTable) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.TasksCloseVGUI, @FlowSize
	net.Send playerTable.entity

net.Receive "NMW AU Flow", (len, ply) ->
	playerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[ply]

	switch net.ReadUInt GAMEMODE.FlowSize
		--
		-- Player wants to kill somebody.
		--
		-- TO-DO: this should either validate the distance or be replaced-
		-- completely with a server-side trace.
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
			if not ply.nwm_au_updated
				ply.nwm_au_updated = true

				if GAMEMODE.IsGameInProgress!
					GAMEMODE\Net_UpdateGameData ply

		--
		-- Player has closed the task window.
		--
		when GAMEMODE.FlowTypes.TasksCloseVGUI
			if playerTable
				GAMEMODE\Player_CloseTask playerTable

		--
		-- Player has submitted a task.
		--
		when GAMEMODE.FlowTypes.TasksSubmit
			if playerTable
				name = net.ReadString!

				GAMEMODE\Player_SubmitTask playerTable, name

GM.SetGameInProgress = (state) => SetGlobalBool "NMW AU GameInProgress", state
