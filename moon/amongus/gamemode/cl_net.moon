GM.VentRequest = (vent) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.VentRequest, @FlowSize
	net.WriteUInt vent, 8
	net.SendToServer!

GM.KillRequest = (ply) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.KillRequest, @FlowSize
	net.WriteEntity ply
	net.SendToServer!

GM.SendVote = (plyid) =>
	net.Start "NMW AU Flow"
	net.WriteUInt @FlowTypes.MeetingVote, @FlowSize
	net.WriteBool not plyid
	if plyid
		net.WriteUInt plyid, 8

	net.SendToServer!

moveSounds = {
	"au/vent_move1.wav"
	"au/vent_move2.wav"
	"au/vent_move3.wav"
}

net.Receive "NMW AU Flow", -> switch net.ReadUInt GAMEMODE.FlowSize
	--
	-- Define player tables and other necessary game data.
	--
	when GAMEMODE.FlowTypes.GameStart
		GAMEMODE\PurgeGameData!

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

		-- Reset the HUD and display the splash.
		GAMEMODE\HUDReset!
		GAMEMODE\HUD_DisplayShush!

	--
	-- Display a countdown.
	--
	when GAMEMODE.FlowTypes.Countdown
		if IsValid GAMEMODE.Hud
			GAMEMODE.Hud\Countdown net.ReadDouble!

	--
	-- Read dead people. This gets sent before the meeting.
	-- I'm honestly not sure why this isn't a mart of the
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
		surface.PlaySound "au/impostor_kill.wav"
		GAMEMODE\Blink 0.1, 0, 0

	--
	-- Pretty self-descriptive.
	--
	when GAMEMODE.FlowTypes.KillCooldown
		GAMEMODE.KillCooldown = net.ReadDouble!

	--
	-- Display a countdown.
	--
	when GAMEMODE.FlowTypes.NotifyVent
		reason = net.ReadUInt 4

		-- Play a contextual sound.
		switch reason
			when GAMEMODE.VentNotifyReason.Vent
				surface.PlaySound "au/vent_open.wav"
				GAMEMODE.GameData.Vented = true

			when GAMEMODE.VentNotifyReason.UnVent
				surface.PlaySound "au/vent_open.wav"
				GAMEMODE.GameData.Vented = false

			when GAMEMODE.VentNotifyReason.Move
				surface.PlaySound table.Random moveSounds

		-- Fetch what is known about connected vents.
		hasLinks = net.ReadBool!
		if hasLinks
			links = {}
			count = net.ReadUInt 8
			for i = 1, count
				table.insert links, net.ReadString!

			GAMEMODE\HUDShowVents links

		GAMEMODE\Blink 0.35, nil, 0

	--
	-- Play a fake player venting animation.
	--
	when GAMEMODE.FlowTypes.VentAnim
		ent = net.ReadEntity!
		pos = net.ReadVector!
		appearing = net.ReadBool!

		if ent ~= LocalPlayer!
			GAMEMODE\CreateVentAnim ent, pos, appearing

	--
	-- Meeting 1/4.
	-- Display the splash and the screen itself, after a short delay.
	--
	when GAMEMODE.FlowTypes.Meeting
		if IsValid GAMEMODE.Hud.Meeting
			GAMEMODE.Hud.Meeting\Remove!

		caller = GAMEMODE.GameData.Lookup_PlayerByID[net.ReadUInt 8]

		-- Is this a body report?
		bodyColor = net.ReadBool! and net.ReadColor!
		GAMEMODE\HUD_DisplayMeeting caller, bodyColor

	--
	-- Meeting 2/4.
	-- Unlocks voting.
	-- Reading the caller is kind of redundant, but whatever.
	--
	when GAMEMODE.FlowTypes.OpenDiscuss
		caller = GAMEMODE.GameData.Lookup_PlayerByID[net.ReadUInt 8]
		GAMEMODE.Hud.Meeting\OpenDiscuss caller

	--
	-- Meeting 2/4.
	-- Makes an "I Voted" icon pop up above the voter.
	--
	when GAMEMODE.FlowTypes.MeetingVote
		voter = GAMEMODE.GameData.Lookup_PlayerByID[net.ReadUInt 8]
		GAMEMODE.Hud.Meeting\ApplyVote voter

	--
	-- Meeting 3/4.
	-- Disables voting.
	-- Shows the results.
	--
	when GAMEMODE.FlowTypes.MeetingEnd
		if IsValid GAMEMODE.Hud.Meeting
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

			GAMEMODE.Hud.Meeting\End results

	--
	-- Meeting 4/4.
	-- Eject animation.
	-- Prints the reason.
	--
	when GAMEMODE.FlowTypes.Eject
		if IsValid GAMEMODE.Hud.Meeting
			GAMEMODE.Hud.Meeting\Close!

		if IsValid GAMEMODE.Hud.Eject
			GAMEMODE.Hud.Eject\Remove!

		reason = net.ReadUInt 4
		ply = if net.ReadBool!
			GAMEMODE.GameData.Lookup_PlayerByID[net.ReadUInt 8]

		-- Are confirms enabled?
		-- If so, read the role and how many imposters remain
		confirm = net.ReadBool!
		imposter, remaining, total = if confirm
			net.ReadBool!, net.ReadUInt(8), net.ReadUInt(8)

		GAMEMODE\HUD_DisplayEject reason, ply, confirm, imposter, remaining, total

	--
	-- React to game states.
	-- I honestly don't like this.
	--
	when GAMEMODE.FlowTypes.GameState
		state = net.ReadUInt 4

		switch state
			when GAMEMODE.GameState.Preparing
				GAMEMODE\PurgeGameData!
				GAMEMODE\HUDReset!

				GAMEMODE.Hud\SetupButtons state
			else
				GAMEMODE.Hud\SetupButtons state, GAMEMODE.GameData.Imposters[GAMEMODE.GameData.Lookup_PlayerByEntity[LocalPlayer!]]

	--
	-- Display the game over screen when the game is over.
	-- Reveal the imposters.
	--
	when GAMEMODE.FlowTypes.GameOver
		reason = net.ReadUInt 4

		GAMEMODE.ImposterCount = net.ReadUInt 8
		for i = 1, GAMEMODE.ImposterCount
			plyid = net.ReadUInt 8
			ply = GAMEMODE.GameData.Lookup_PlayerByID[plyid]
			GAMEMODE.GameData.Imposters[ply] = true

		GAMEMODE\HUD_DisplayGameOver reason