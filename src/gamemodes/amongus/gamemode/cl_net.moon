--- All things network.
-- Responsible for sending and receiving information to/from the server.
-- @module cl_net

TRANSLATE = GM.Lang.GetEntry

--- Tell the server that we want to hop to a different vent.
-- This will do absolutely nothing if the player is not vented, or
-- if he's not an imposter to begin with.
-- The list of vents is provided by the server via the NotifyVent flow type.
-- @int vent Target vent ID.
GM.Net_VentRequest = (vent) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.VentRequest, @FlowSize
	net.WriteUInt vent, 8
	net.SendToServer!

--- Tell the server that we want to kill a person.
-- @param ply The person to be killed.
GM.Net_KillRequest = (ply) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.KillRequest, @FlowSize
	net.WriteEntity ply
	net.SendToServer!

--- Sends a vote to the server.
-- This will fail horribly if there isn't a vote in progress.
-- @param id ID. Zero to skip.
GM.Net_SendVote = (id) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.MeetingVote, @FlowSize
	net.WriteBool not id
	if id
		net.WriteUInt id, 8

	net.SendToServer!

--- Notifies the server that the task has been completed.
-- This will fail horribly if the player isn't doing any tasks.
GM.Net_SendSubmitTask = (data = 0) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.TasksSubmit, @FlowSize
	net.WriteUInt data, 32
	net.SendToServer!

--- Notifies the server that the task window has been closed.
-- This will fail horribly if the player doesn't have anything open.
-- @param name Task name.
GM.Net_SendCloseVGUI = =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.CloseVGUI, @FlowSize
	net.SendToServer!

GM.Net_SabotageRequest = (id) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.SabotageRequest, @FlowSize
	net.WriteUInt id, 8
	net.SendToServer!

GM.Net_SendSubmitSabotage = (data = 0) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.SabotageSubmit, @FlowSize
	net.WriteUInt data, 32
	net.SendToServer!

GM.Net_UpdateMyColor = =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.UpdateMyColor, @FlowSize
	net.SendToServer!

GM.Net_MeetingRequest = =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.MeetingStart, @FlowSize
	net.SendToServer!

net.Receive "NMW AU Flow", -> switch net.ReadUInt GAMEMODE.FlowSize
	--
	-- Define player tables and other necessary game data.
	--
	when GAMEMODE.FlowTypes.GameStart
		GAMEMODE\PurgeGameData!

		-- Read ConVar snapshots.
		-- Again.
		GAMEMODE\ConVarSnapshot_ImportAll net.ReadTable!

		-- Fill player tables.
		playerCount = net.ReadUInt 8
		for i = 1, playerCount
			playerTable = {
				steamid: net.ReadString!
				nickname: net.ReadString!
				color: net.ReadColor!
				entity: net.ReadEntity!
				id: net.ReadUInt 8
			}

			table.insert GAMEMODE.GameData.PlayerTables, playerTable
			GAMEMODE.GameData.Lookup_PlayerByID[playerTable.id] = playerTable
			GAMEMODE.GameData.Lookup_PlayerByEntity[playerTable.entity] = playerTable

		-- Read imposters.
		-- If we're an imposter, let us be aware of other imposters.
		GAMEMODE.ImposterCount = net.ReadUInt 8
		imposter = net.ReadBool!
		if imposter
			for i = 1, GAMEMODE.ImposterCount
				playerTable = GAMEMODE.GameData.Lookup_PlayerByID[net.ReadUInt 8]
				if playerTable
					GAMEMODE.GameData.Imposters[playerTable] = true

		-- Read dead people.
		-- Most of the time this is useless, and is only ever necessary
		-- to let the new players (spectators) know about dead people.
		count = net.ReadUInt 8
		for i = 1, count
			id = net.ReadUInt 8
			if playerTable = GAMEMODE.GameData.Lookup_PlayerByID[id]
				GAMEMODE.GameData.DeadPlayers[playerTable] = true


		-- Read the current amount of tasks.
		GAMEMODE.GameData.CompletedTasks = net.ReadUInt 32

		-- Reset the HUD and display the splash.
		GAMEMODE\HUD_Reset!
		GAMEMODE\HUD_DisplayShush!

		-- Add evil stuff to the map.
		if imposter
			GAMEMODE\HUD_InitializeImposterMap!

		system.FlashWindow!

	--
	-- Display a countdown.
	--
	when GAMEMODE.FlowTypes.GameCountdown
		return unless IsValid GAMEMODE.Hud

		GAMEMODE\HUD_Countdown net.ReadDouble!

		system.FlashWindow!

	--
	-- Read dead people. This gets sent before the meeting.
	-- I'm honestly not sure why this isn't a part of the
	-- meeting net message.
	--
	when GAMEMODE.FlowTypes.BroadcastDead
		if GAMEMODE.GameData.Lookup_PlayerByID
			count = net.ReadUInt 8
			for i = 1, count
				id = net.ReadUInt 8
				if playerTable = GAMEMODE.GameData.Lookup_PlayerByID[id]
					GAMEMODE.GameData.DeadPlayers[playerTable] = true

	--
	-- Blink whenever we've made a successful kill.
	-- Reuses "Kill Request" since it doesn't make sense
	-- to add a new flow type just for this.
	--
	when GAMEMODE.FlowTypes.KillRequest
		surface.PlaySound "au/impostor_kill.ogg"
		GAMEMODE\HUD_Blink 0.1, 0, 0

	--
	-- Pretty self-descriptive.
	--
	when GAMEMODE.FlowTypes.KillCooldown
		GAMEMODE.GameData.KillCooldownOverride = nil
		GAMEMODE.GameData.KillCooldown = net.ReadDouble!

	--
	-- Notifies us that we've vented.
	-- This includes getting into, out or hopping between the vents.
	--
	when GAMEMODE.FlowTypes.NotifyVent
		reason = net.ReadUInt 4

		-- Play a contextual sound.
		switch reason
			when GAMEMODE.VentNotifyReason.Vent
				surface.PlaySound "au/vent_open.ogg"
				GAMEMODE.GameData.Vented = true

			when GAMEMODE.VentNotifyReason.UnVent
				surface.PlaySound "au/vent_open.ogg"
				GAMEMODE.GameData.Vented = false
				GAMEMODE.GameData.UnVentTime = CurTime! + 0.65

			when GAMEMODE.VentNotifyReason.Move
				surface.PlaySound table.Random {
					"au/vent_move1.ogg"
					"au/vent_move2.ogg"
					"au/vent_move3.ogg"
				}

		-- Fetch what is known about connected vents.
		hasLinks = net.ReadBool!
		if hasLinks
			links = {}
			count = net.ReadUInt 8
			for i = 1, count
				table.insert links, net.ReadString!

			GAMEMODE\HUD_ShowVents links

		GAMEMODE\HUD_Blink 0.35, nil, 0

	--
	-- Play a fake player venting animation.
	--
	when GAMEMODE.FlowTypes.VentAnim
		ent = net.ReadEntity!
		pos = net.ReadVector!
		ang = net.ReadAngle!
		appearing = net.ReadBool!

		if ent ~= LocalPlayer!
			GAMEMODE\CreateVentAnim ent, pos, ang, appearing

	--
	-- Meeting 1/4.
	-- Display the splash and the screen itself, after a short delay.
	--
	when GAMEMODE.FlowTypes.MeetingStart
		return unless IsValid GAMEMODE.Hud

		if IsValid GAMEMODE.Hud.Meeting
			GAMEMODE.Hud.Meeting\Remove!

		caller = GAMEMODE.GameData.Lookup_PlayerByID[net.ReadUInt 8]

		-- Is this a body report?
		bodyColor = net.ReadBool! and net.ReadColor!
		GAMEMODE\HUD_DisplayMeeting caller, bodyColor
		GAMEMODE\HUD_HideTaskList true

		system.FlashWindow!

	--
	-- Meeting 2/4.
	-- Unlocks voting.
	-- Reading the caller is kind of redundant, but whatever.
	--
	when GAMEMODE.FlowTypes.MeetingOpenDiscuss
		return unless IsValid GAMEMODE.Hud
		return unless IsValid GAMEMODE.Hud.Meeting

		caller = GAMEMODE.GameData.Lookup_PlayerByID[net.ReadUInt 8]
		time = net.ReadDouble!
		GAMEMODE.Hud.Meeting\OpenDiscuss caller, time

		system.FlashWindow!

	--
	-- Meeting 2/4.
	-- Makes an "I Voted" icon pop up above the voter.
	--
	when GAMEMODE.FlowTypes.MeetingVote
		return unless IsValid GAMEMODE.Hud
		return unless IsValid GAMEMODE.Hud.Meeting

		voter = GAMEMODE.GameData.Lookup_PlayerByID[net.ReadUInt 8]
		if voter
			remaining = net.ReadUInt 8
			GAMEMODE.Hud.Meeting\ApplyVote voter, remaining

			system.FlashWindow!

	--
	-- Meeting 3/4.
	-- Disables voting.
	-- Shows the results.
	--
	when GAMEMODE.FlowTypes.MeetingEnd
		return unless IsValid GAMEMODE.Hud
		return unless IsValid GAMEMODE.Hud.Meeting

		results = {}
		resultsLength = net.ReadUInt 8
		for i = 1, resultsLength
			t = {
				targetid: net.ReadUInt 8
				votes: {}
			}
			numVoters = net.ReadUInt 8

			for i = 1, numVoters
				table.insert t.votes, net.ReadUInt 8

			table.insert results, t

		time = net.ReadDouble!

		GAMEMODE.Hud.Meeting\End results, time

		system.FlashWindow!

	--
	-- Meeting 4/4.
	-- Eject animation.
	-- Prints the reason.
	--
	when GAMEMODE.FlowTypes.MeetingEject
		return unless IsValid GAMEMODE.Hud

		if IsValid GAMEMODE.Hud.Meeting
			GAMEMODE.Hud.Meeting\Close!

		if IsValid GAMEMODE.Hud.Eject
			GAMEMODE.Hud.Eject\Remove!

		reason = net.ReadUInt 4
		ply = if net.ReadBool!
			GAMEMODE.GameData.Lookup_PlayerByID[net.ReadUInt 8]

		if ply
			GAMEMODE.GameData.DeadPlayers[ply] = true

		-- Are confirms enabled?
		-- If so, read the role and how many imposters remain
		confirm = net.ReadBool!
		imposter, remaining, total = if confirm
			net.ReadBool!, net.ReadUInt(8), net.ReadUInt(8)

		GAMEMODE\HUD_DisplayEject reason, ply, confirm, imposter, remaining, total
		GAMEMODE\HUD_HideTaskList false

		system.FlashWindow!

	--
	-- React to game states.
	-- I honestly don't like this.
	--
	when GAMEMODE.FlowTypes.GameState
		state = net.ReadUInt 4

		switch state
			when GAMEMODE.GameState.Preparing
				GAMEMODE\HUD_Reset!
				GAMEMODE\PurgeGameData!
				GAMEMODE.Hud\SetupButtons state
			else
				GAMEMODE.Hud\SetupButtons state, GAMEMODE.GameData.Imposters[GAMEMODE.GameData.Lookup_PlayerByEntity[LocalPlayer!]]
				GAMEMODE\Sabotage_Init!

	--
	-- Display the game over screen when the game is over.
	-- Reveal the imposters.
	--
	when GAMEMODE.FlowTypes.GameOver
		return unless IsValid GAMEMODE.Hud

		reason = net.ReadUInt 4

		GAMEMODE.ImposterCount = net.ReadUInt 8
		for i = 1, GAMEMODE.ImposterCount
			plyid = net.ReadUInt 8
			if ply = GAMEMODE.GameData.Lookup_PlayerByID[plyid]
				GAMEMODE.GameData.Imposters[ply] = true

		GAMEMODE\HUD_DisplayGameOver reason

		system.FlashWindow!

	--
	-- Update the task data.
	-- Show the message if the task is complete.
	--
	when GAMEMODE.FlowTypes.TasksUpdateData
		name = net.ReadString!
		packet = net.ReadTable!

		instance = GAMEMODE.GameData.MyTasks[name]

		local wasCreated
		if not instance
			wasCreated = true

			instance = GAMEMODE\Task_Instantiate GAMEMODE.TaskCollection.All[name]
			GAMEMODE.GameData.MyTasks[name] = instance

			instance\SetName name
			instance\Init!

		oldActivationButton = instance\GetActivationButton!

		for accessor, value in pairs packet
			instance["Set#{accessor}"] instance, value ~= "_nil" and value

		if not instance\GetCompleted!
			if not wasCreated
				surface.PlaySound "au/task_inprogress.ogg"

			if instance\GetActivationButton! ~= oldActivationButton
				GAMEMODE\HUD_TrackTaskOnMap oldActivationButton, false
				GAMEMODE\HUD_TrackTaskOnMap instance\GetActivationButton!
		else
			surface.PlaySound "au/task_complete.ogg"
			GAMEMODE\HUD_TrackTaskOnMap instance\GetActivationButton!, false
			GAMEMODE\HUD_CreateTaskCompletePopup!

	--
	-- Someone has completed a task.
	--
	when GAMEMODE.FlowTypes.TasksUpdateCount
		GAMEMODE.GameData.CompletedTasks = net.ReadUInt 32
		GAMEMODE.GameData.TotalTasks = net.ReadUInt 32

		return unless IsValid GAMEMODE.Hud
		GAMEMODE\HUD_UpdateTaskAmount GAMEMODE.GameData.CompletedTasks / GAMEMODE.GameData.TotalTasks

	--
	-- The server wants us to close the task screen.
	--
	when GAMEMODE.FlowTypes.CloseVGUI
		return unless IsValid GAMEMODE.Hud

		GAMEMODE\HUD_CloseVGUI!

	--
	-- The server wants us to close the task screen.
	--
	when GAMEMODE.FlowTypes.NotifyKilled
		killer = net.ReadUInt 8

		killerPlayerTable = GAMEMODE.GameData.Lookup_PlayerByID[killer]
		localPlayerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[LocalPlayer!]

		if killerPlayerTable and localPlayerTable
			GAMEMODE\HUD_PlayKill killerPlayerTable, localPlayerTable
			GAMEMODE.GameData.DeadPlayers[localPlayerTable] = true

		system.FlashWindow!

	--
	-- The server has paused our kill cooldown.
	--
	when GAMEMODE.FlowTypes.KillCooldownPause
		GAMEMODE.GameData.KillCooldownOverride = net.ReadDouble!

	--
	-- The server has sabotage data updates for us.
	--
	when GAMEMODE.FlowTypes.SabotageData
		id = net.ReadUInt 8
		packet = net.ReadTable!

		if instance = GAMEMODE.GameData.Sabotages[id]
			for accessor, value in pairs packet
				instance["Set#{accessor}"] instance, value ~= "nil" and value

	--
	-- The server requested us to open a VGUI.
	--
	when GAMEMODE.FlowTypes.OpenVGUI
		identifier = net.ReadString!
		data = net.ReadTable! or {}

		success, result = pcall ->
			hook.Call "GMAU OpenVGUI", nil, data, identifier

		if not success
			GAMEMODE.Logger.Error "Couldn't open VGUI! Error: #{result}"
			result = nil

		-- oh no
		if result == nil
			GAMEMODE\Net_SendCloseVGUI!

	--
	-- The server provided us with the new ConVar snapshots.
	--
	when GAMEMODE.FlowTypes.ConVarSnapshots
		GAMEMODE\ConVarSnapshot_ImportAll net.ReadTable!

	--
	-- The server provided us with the new ConVar snapshots.
	--
	when GAMEMODE.FlowTypes.ConnectDisconnect
		nickname = net.ReadString!
		connected = net.ReadBool!
		spectator = net.ReadBool!

		chat.AddText Color(220, 32, 32), "[Among Us] ", Color(255, 255, 255), tostring if connected
			surface.PlaySound "au/player_spawn.ogg"

			if spectator
				TRANSLATE("connected.spectating") nickname
			else
				TRANSLATE("connected.spawned") nickname
		else
			surface.PlaySound "au/player_disconnect.ogg"

			TRANSLATE("connected.disconnected") nickname

	when GAMEMODE.FlowTypes.GameChatNotification
		chat.AddText Color(220, 32, 32), "[Among Us] ", Color(255, 255, 0), tostring TRANSLATE "chat.noTalkingDuringGame"
