include "shared.lua"
include "sv_net.lua"
include "sv_spectate.lua"
include "sv_resources.lua"
include "sv_lookups.lua"

AddCSLuaFile "sh_lookups.lua"
AddCSLuaFile "vgui/vgui_shutup.lua"
AddCSLuaFile "vgui/vgui_splash.lua"
AddCSLuaFile "vgui/vgui_hud.lua"
AddCSLuaFile "vgui/vgui_meeting.lua"
AddCSLuaFile "vgui/vgui_eject.lua"
AddCSLuaFile "vgui/vgui_blink.lua"
AddCSLuaFile "vgui/vgui_vent.lua"
AddCSLuaFile "cl_hud.lua"
AddCSLuaFile "cl_net.lua"
AddCSLuaFile "cl_render.lua"

resource.AddWorkshop "2227901495"

lastStateCheck = CurTime!
GM.Think = =>
	if @IsGameInProgress! and CurTime! - lastStateCheck >= 5
		lastStateCheck = CurTime!
		@CheckWin!

hook.Add "PlayerDisconnected", "NMW AU CheckWin", ->
	if GAMEMODE.GameData.ActivePlayers
		GAMEMODE\CheckWin!

GM.GameOver = (reason) =>
	for index, ply in ipairs player.GetAll!
		ply\Freeze true

	@SetGameInProgress false
	@BroadcastDead!
	@BroadcastGameOver reason

	handle = "game"

	@GameData.Timers[handle] = true
	timer.Create handle, 9, 1, ->
		@Restart!

GM.CheckWin = =>
	if not @IsGameInProgress!
		return

	numImposters = 0
	numPlayers = 0

	for _, ply in pairs @GameData.ActivePlayers
		if IsValid(ply.entity) and not @GameData.DeadPlayers[ply]
			if @GameData.Imposters[ply]
				numImposters += 1
			else
				numPlayers += 1

	reason = if numImposters == 0
		@GameOverReason.Crewmate
	elseif numImposters >= numPlayers
		@GameOverReason.Imposter

	if reason
		@GameOver!
		return true

GM.PlayerSpawn = (ply) =>
	ply\SetModel "models/kaesar/amongus/amongus.mdl"
	with defaultSpeed = 200
		ply\SetSlowWalkSpeed defaultSpeed
		ply\SetWalkSpeed defaultSpeed
		ply\SetRunSpeed  defaultSpeed
		ply\SetMaxSpeed  defaultSpeed

	ply\SetTeam 1
	ply\SetNoCollideWithTeammates true

GM.StartMeeting = (ply, bodyColor) =>
	aply = @GameData.ActivePlayersMap[ply]

	handle = "meeting"
	if @GameData.DeadPlayers[aply] 
		return

	if timer.Exists handle
		return

	for index, ply in ipairs player.GetAll!
		ply\Freeze true

	@GameData.Timers[handle] = true
	timer.Create handle, 0.2, 1, ->
		@BroadcastDead!
		@BroadcastMeeting aply.id, bodyColor

		timer.Create handle, 3, 1, ->
			for imposter, _ in pairs @GameData.Imposters
				if @GameData.Vented[imposter]
					@GameData.Vented[imposter] = false
					@NotifyVent imposter, @VentNotifyReason.UnVent

			spawns = ents.FindByClass "info_player_start"
			for index, ply in ipairs @GameData.ActivePlayers
				if IsValid ply.entity
					with ply.entity
						point = spawns[(index % #spawns) + 1]
						\SetPos point\GetPos!
						\SetAngles point\GetAngles!
						\SetEyeAngles point\GetAngles!
	
			@BroadcastDiscuss aply.id

			timer.Create handle, @ConVars.VotePreTime\GetInt! + 3, 1, ->
				@Voting = true
				table.Empty @GameData.Votes
				table.Empty @GameData.VotesMap

				for _, ply in ipairs player.GetAll!
					if false and ply\IsBot!
						skip = math.random! > 0.8
						rnd = table.Random @GetAlivePlayers!
						@Vote ply, not skip and rnd

				timer.Create handle, @ConVars.VoteTime\GetInt!, 1, ->
					@VoteEnd!

	return true

GM.CleanUp = =>
	for handle, _ in pairs @GameData.Timers
		timer.Remove handle

	GAMEMODE\PurgeGameData!

	@SetGameInProgress false
	@Voting = false

	@UnhideEveryone!

	game.CleanUpMap!

GM.Restart = =>
	@CleanUp!

	spawns = ents.FindByClass "info_player_start"

	players = player.GetAll!
	for index, ply in ipairs players
		ply\UnSpectate!
		ply\Freeze false
		ply\Spawn!
		ply\SetColor @Colors[math.floor(#@Colors / #players) * index]
		ply\SetRenderMode RENDERGROUP_OPAQUE

		point = spawns[(index % #spawns) + 1]
		ply\SetPos point\GetPos!
		ply\SetAngles point\GetAngles!
		ply\SetEyeAngles point\GetAngles!
		@SendGameState ply, @GameState.Preparing

GM.StartGame = =>
	@CleanUp!

	handle = "game"
	@GameData.Timers[handle] = true

	@GameData.ActivePlayers = {}
	@GameData.ActivePlayersMapId = {}
	id = 0
	for _, ply in ipairs player.GetAll!
		id += 1
		t = {
			steamid: ply\SteamID!
			nickname: ply\Nick!
			entity: ply
			id: id
		}

		table.insert @GameData.ActivePlayers, t
		@GameData.ActivePlayersMapId[id] = t

	@BroadcastCountdown CurTime! + 3
	@SetGameInProgress true
	timer.Create handle, 3, 1, ->
		memo = {}
		table.sort @GameData.ActivePlayers, (a, b) ->
			if not a.entity\IsBot!
				memo[a] = 1
			if not b.entity\IsBot!
				memo[b] = 1

			memo[a] = memo[a] or math.random!
			memo[b] = memo[b] or math.random!
			memo[a] > memo[b]

		for index, ply in ipairs @GameData.ActivePlayers
			@GameData.ActivePlayersMap[ply.entity] = ply
			if index <= @ConVars.ImposterCount\GetInt!
				@GameData.Imposters[ply] = true

			if IsValid ply.entity
				with ply.entity
					ply.color = @Colors[math.floor(#@Colors / #@GameData.ActivePlayers) * index]

					\Freeze true
					\SetColor ply.color
					\SetNW2Int "NMW AU Meetings", @ConVars.MeetingsPerPlayer\GetInt!

			print string.format "%s is %s", ply.entity\Nick!, @GameData.Imposters[ply] and "an imposter" or "a crewmate"

		memo = {}
		table.sort @GameData.ActivePlayers, (a, b) ->
			memo[a] = memo[a] or math.random!
			memo[b] = memo[b] or math.random!
			memo[a] > memo[b]

		@BroadcastStart!

		timer.Create handle, 2, 1, ->
			@StartRound!

			for index, ply in ipairs @GameData.ActivePlayers
				if IsValid ply.entity
					ply.entity\Freeze true

			timer.Create handle, @SplashScreenTime - 2, 1, ->
				if @CheckWin!
					return

				for index, ply in ipairs @GameData.ActivePlayers
					if IsValid ply.entity
						ply.entity\Freeze false

					@SendGameState ply.entity, @GameState.Playing

				for ply in pairs @GameData.Imposters
					if IsValid ply.entity
						@UpdateKillCooldown ply

				@ResetMeetingCooldown!

GM.ResetMeetingCooldown = =>
	SetGlobalFloat "NMW AU NextMeeting", CurTime! + @ConVars.MeetingCooldown\GetFloat!

GM.StartRound = =>
	spawns = ents.FindByClass "info_player_start"
	for index, ply in ipairs @GameData.ActivePlayers
		if IsValid ply.entity
			with ply.entity
				point = spawns[(index % #spawns) + 1]
				\Spawn!
				\SetPos point\GetPos!
				\SetAngles point\GetAngles!
				\SetEyeAngles point\GetAngles!

	bodies = ents.FindByClass "prop_ragdoll"
	for index, body in ipairs bodies
		if 0 ~= body\GetNW2Int "NMW AU PlayerID"
			body\Remove!

	for ply in pairs @GameData.Imposters
		@UpdateKillCooldown ply

	@ResetMeetingCooldown!

concommand.Add "au_debug_start", ->
	GAMEMODE\Restart!

	GAMEMODE\StartGame!

concommand.Add "au_debug_restart", ->
	GAMEMODE\Restart!

hook.Add "CanPlayerSuicide", "NMW AU Suicide", ->
	return false

hook.Add "EntityTakeDamage", "NMW AU Damage", (target, dmg) ->
	dmg\ScaleDamage 0

hook.Add "PlayerUse", "NMW AU Use", (activator, ent) ->
	aply = GAMEMODE.GameData.ActivePlayersMap[activator]
	if aply and GAMEMODE\IsGameInProgress!
		bodyid = ent\GetNW2Int "NMW AU PlayerID"
		victim = GAMEMODE.GameData.ActivePlayersMapId[bodyid]
		if victim
			GAMEMODE\StartMeeting activator, victim.color

hook.Add "FindUseEntity", "NMW AU FindUse", (ply, default) ->
	_, usable = GAMEMODE\TracePlayer ply
	return usable

GM.UnVent = (playerTable) =>
	if vent = @GameData.Vented[playerTable]
		@GameData.VentCooldown[playerTable] = CurTime! + 1.5

		@NotifyVent playerTable, @VentNotifyReason.UnVent
		playerTable.entity\SetPos vent\GetPos!

		handle = "vent" .. playerTable.nickname
		@BroadcastVent playerTable.entity, vent\GetPos!, true
		timer.Create handle, 0.5, 1, ->
			@GameData.Vented[playerTable] = nil
			if IsValid playerTable.entity
				@UnhidePlayer playerTable.entity
				playerTable.entity\SetPos vent\GetPos! + Vector 0, 0, 5

GM.PackVentLinks = (vent) =>
	if vent.Links and #vent.Links > 0
		links = {}

		for _, link in ipairs vent.Links
			table.insert links, link\GetName! or "N/A"

		return links

GM.VentTo = (playerTable, targetVentId) =>
	vent = @GameData.Vented[playerTable]

	if @GameData.Imposters[playerTable] and vent and vent.Links and IsValid(vent.Links[targetVentId]) and (@GameData.VentCooldown[playerTable] or 0) <= CurTime!
		targetVent = vent.Links[targetVentId]
		@GameData.Vented[playerTable] = targetVent
		
		@NotifyVent playerTable, @VentNotifyReason.Move, @PackVentLinks targetVent
		@GameData.VentCooldown[playerTable] = CurTime! + 0.25

		if IsValid playerTable.entity
			playerTable.entity\SetPos targetVent\GetPos!
			playerTable.entity\SetEyeAngles targetVent.ViewAngle

GM.Vent = (playerTable, vent) =>
	if @GameData.Imposters[playerTable] and not @GameData.Vented[playerTable]
		@NotifyVent playerTable, @VentNotifyReason.Vent, @PackVentLinks vent

		@GameData.Vented[playerTable] = vent
		@GameData.VentCooldown[playerTable] = CurTime! + 0.75

		handle = "vent" .. playerTable.nickname

		if IsValid playerTable.entity
			playerTable.entity\SetPos vent\GetPos!
			playerTable.entity\SetEyeAngles vent.ViewAngle

			@BroadcastVent playerTable.entity, vent\GetPos!
			@HidePlayer playerTable.entity

		timer.Create handle, 0.125, 1, ->
			if IsValid playerTable.entity
				playerTable.entity\SetPos vent\GetPos!
				if vent.ViewAngle
					playerTable.entity\SetEyeAngles vent.ViewAngle

hook.Add "KeyPress", "NMW AU KeyPress", (ply, key) ->
	@ = GAMEMODE

	playerTable = @GameData.ActivePlayersMap[ply]
	switch key
		when IN_USE
			if @GameData.Imposters[playerTable] and @GameData.Vented[playerTable] and (@VentCooldown[playerTable] or 0) <= CurTime!
				@UnVent playerTable
