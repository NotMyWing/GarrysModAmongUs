VGUI_SPLASH = include "vgui/vgui_splash.lua"
VGUI_MEETING = include "vgui/vgui_meeting.lua"
VGUI_EJECT = include "vgui/vgui_eject.lua"

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
	net.WriteUInt @FlowTypes.Vote, @FlowSize
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
	when GAMEMODE.FlowTypes.GameStart
		GAMEMODE\PurgeGameData!

		playerCount = net.ReadUInt 8
		for i = 1, playerCount
			t = {
				steamid: net.ReadString!
				nickname: net.ReadString!
				color: net.ReadColor!
				entity: net.ReadEntity!
				id: net.ReadUInt 8
			}
			table.insert GAMEMODE.GameData.ActivePlayers, t
			GAMEMODE.GameData.ActivePlayersMapId[t.id] = t
			GAMEMODE.GameData.ActivePlayersMap[t.entity] = t

		GAMEMODE.ImposterCount = net.ReadUInt 8
		imposter = net.ReadBool!
		if imposter
			for i = 1, GAMEMODE.ImposterCount
				plyid = net.ReadUInt 8
				ply = GAMEMODE.GameData.ActivePlayersMapId[plyid]
				GAMEMODE.GameData.Imposters[ply] = true

		count = net.ReadUInt 8
		for i = 1, count
			id = net.ReadUInt 8
			if playerTable = GAMEMODE.GameData.ActivePlayersMapId[id]
				GAMEMODE.GameData.DeadPlayers[playerTable] = true

		GAMEMODE\HUDReset!
		GAMEMODE.Hud.Splash = with vgui.CreateFromTable VGUI_SPLASH, GAMEMODE.Hud
			\DisplayShush!

	when GAMEMODE.FlowTypes.Countdown
		if IsValid GAMEMODE.Hud
			GAMEMODE.Hud\Countdown net.ReadDouble!

	when GAMEMODE.FlowTypes.SetDead
		if GAMEMODE.GameData.ActivePlayersMapId
			count = net.ReadUInt 8
			for i = 1, count
				id = net.ReadUInt 8
				if playerTable = GAMEMODE.GameData.ActivePlayersMapId[id]
					GAMEMODE.GameData.DeadPlayers[playerTable] = true

	when GAMEMODE.FlowTypes.KillRequest
		surface.PlaySound "au/impostor_kill.wav"
		GAMEMODE\Blink 0.1, 0, 0

	when GAMEMODE.FlowTypes.NotifyVent
		reason = net.ReadUInt 4
		switch reason
			when GAMEMODE.VentNotifyReason.Vent
				surface.PlaySound "au/vent_open.wav"
				GAMEMODE.GameData.Vented = true

			when GAMEMODE.VentNotifyReason.UnVent
				surface.PlaySound "au/vent_open.wav"
				GAMEMODE.GameData.Vented = false

			when GAMEMODE.VentNotifyReason.Move
				surface.PlaySound table.Random moveSounds

		hasLinks = net.ReadBool!
		if hasLinks
			links = {}
			count = net.ReadUInt 8
			for i = 1, count
				table.insert links, net.ReadString!

			GAMEMODE\HUDShowVents links

		GAMEMODE\Blink 0.35, nil, 0

	when GAMEMODE.FlowTypes.KillCooldown
		GAMEMODE.KillCooldown = net.ReadDouble!

	when GAMEMODE.FlowTypes.VentAnim
		ent = net.ReadEntity!
		pos = net.ReadVector!
		appearing = net.ReadBool!

		if ent ~= LocalPlayer!
			GAMEMODE\CreateVentAnim ent, pos, appearing

	when GAMEMODE.FlowTypes.Meeting
		plyid = net.ReadUInt 8
		ply = GAMEMODE.GameData.ActivePlayersMapId[plyid]

		if IsValid GAMEMODE.Hud.Meeting
			GAMEMODE.Hud.Meeting\Remove!

		isBody = net.ReadBool!
		bodyColor = isBody and net.ReadColor!

		GAMEMODE.Hud.Meeting = with vgui.CreateFromTable VGUI_MEETING, GAMEMODE.Hud
			\StartEmergency ply, bodyColor

	when GAMEMODE.FlowTypes.OpenDiscuss
		plyid = net.ReadUInt 8
		ply = GAMEMODE.GameData.ActivePlayersMapId[plyid]

		if IsValid GAMEMODE.Hud.Meeting
			GAMEMODE.Hud.Meeting\OpenDiscuss ply

	when GAMEMODE.FlowTypes.Vote
		plyid = net.ReadUInt 8
		ply = GAMEMODE.GameData.ActivePlayersMapId[plyid]

		if IsValid GAMEMODE.Hud.Meeting
			GAMEMODE.Hud.Meeting\ApplyVote ply
	
	when GAMEMODE.FlowTypes.VoteEnd
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

	when GAMEMODE.FlowTypes.Eject
		if IsValid GAMEMODE.Hud.Meeting
			GAMEMODE.Hud.Meeting\Close!

		if IsValid GAMEMODE.Hud.Eject
			GAMEMODE.Hud.Eject\Remove!

		reason = net.ReadUInt 4
		ply = if net.ReadBool!
			GAMEMODE.GameData.ActivePlayersMapId[net.ReadUInt 8]

		confirm = net.ReadBool!
		imposter, remaining = if confirm
			net.ReadBool!, net.ReadUInt 8

		GAMEMODE.Hud.Eject = with vgui.CreateFromTable VGUI_EJECT, GAMEMODE.Hud
			\Eject reason, ply, confirm, imposter, remaining

	when GAMEMODE.FlowTypes.GameState
		state = net.ReadUInt 4

		if state == GAMEMODE.GameState.Preparing
			GAMEMODE\PurgeGameData!
			GAMEMODE\HUDReset!

			GAMEMODE.Hud\SetupButtons state
		else
			GAMEMODE.Hud\SetupButtons state, GAMEMODE.IGameData.mposters[GAMEMODE.GameData.ActivePlayersMap[LocalPlayer!]]

	when GAMEMODE.FlowTypes.GameOver
		reason = net.ReadUInt 4

		GAMEMODE.Hud.Splash = with vgui.CreateFromTable VGUI_SPLASH, GAMEMODE.Hud
			GAMEMODE.ImposterCount = net.ReadUInt 8
			for i = 1, GAMEMODE.ImposterCount
				plyid = net.ReadUInt 8
				ply = GAMEMODE.GameData.ActivePlayersMapId[plyid]
				GAMEMODE.GameData.Imposters[ply] = true

			\DisplayGameOver reason