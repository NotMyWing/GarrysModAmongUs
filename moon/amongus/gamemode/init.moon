include "shared.lua"
include "sv_net.lua"
include "sv_spectate.lua"
include "sv_resources.lua"

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
	if GetGlobalBool("NMW AU GameInProgress") and CurTime! - lastStateCheck >= 5
		lastStateCheck = CurTime!
		@CheckWin!

with GM
	.KillCooldownRemainders = {}
	.ActivePlayersMapId = {}
	.ActivePlayersMap = {}
	.ActivePlayers = {}
	.KillCooldowns = {}
	.DeadPlayers = {}
	.Imposters = {}
	.Timers = {}
	.VotesMap = {}
	.Votes = {}
	.Vented = {}
	.VentCooldown = {}

hook.Add "PlayerDisconnected", "NMW AU CheckWin", ->
	if GAMEMODE.ActivePlayers
		GAMEMODE\CheckWin!

GM.CheckWin = =>
	if not GetGlobalBool "NMW AU GameInProgress"
		return

	numImposters = 0
	numPlayers = 0

	for _, ply in pairs @ActivePlayers
		if IsValid(ply.entity) and not @DeadPlayers[ply]
			if @Imposters[ply]
				numImposters += 1
			else
				numPlayers += 1

	reason = if numImposters == 0
		@GameOverReason.Crewmate
	elseif numImposters >= numPlayers
		@GameOverReason.Imposter

	if reason
		SetGlobalBool "NMW AU GameInProgress", false

		for index, ply in ipairs player.GetAll!
			ply\Freeze true

		@BroadcastDead!
		@BroadcastGameOver reason

		handle = "game"
		@Timers[handle] = true

		timer.Create handle, 9, 1, ->
			@Restart!

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
	aply = @ActivePlayersMap[ply]

	handle = "meeting"
	if @DeadPlayers[aply] 
		return

	if timer.Exists handle
		return

	for index, ply in ipairs player.GetAll!
		ply\Freeze true

	@Timers[handle] = true
	timer.Create handle, 0.2, 1, ->
		@BroadcastDead!
		@BroadcastMeeting aply.id, bodyColor

		timer.Create handle, 3, 1, ->
			for imposter, _ in pairs @Imposters
				if @Vented[imposter]
					@Vented[imposter] = false
					@NotifyVent imposter, @VentNotifyReason.UnVent

			spawns = ents.FindByClass "info_player_start"
			for index, ply in ipairs @ActivePlayers
				if IsValid ply.entity
					with ply.entity
						point = spawns[(index % #spawns) + 1]
						\SetPos point\GetPos!
						\SetAngles point\GetAngles!
						\SetEyeAngles point\GetAngles!
	
			@BroadcastDiscuss aply.id

			timer.Create handle, @ConVars.VotePreTime\GetInt! + 3, 1, ->
				@Voting = true
				table.Empty @Votes
				table.Empty @VotesMap

				for _, ply in ipairs player.GetAll!
					if false and ply\IsBot!
						skip = math.random! > 0.8
						rnd = table.Random @GetAlivePlayers!
						@Vote ply, not skip and rnd

				timer.Create handle, @ConVars.VoteTime\GetInt!, 1, ->
					@VoteEnd!

	return true

GM.CleanUp = =>
	for handle, _ in pairs @Timers
		timer.Remove handle

	table.Empty @Timers
	table.Empty @Imposters
	table.Empty @Vented
	table.Empty @VentCooldown
	table.Empty @ActivePlayers
	table.Empty @ActivePlayersMap
	table.Empty @ActivePlayersMapId
	table.Empty @DeadPlayers
	table.Empty @KillCooldowns
	table.Empty @KillCooldownRemainders
	table.Empty @Votes
	table.Empty @VotesMap

	SetGlobalBool "NMW AU GameInProgress", false
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
	@Timers[handle] = true

	@ActivePlayers = {}
	@ActivePlayersMapId = {}
	id = 0
	for _, ply in ipairs player.GetAll!
		id += 1
		t = {
			steamid: ply\SteamID!
			nickname: ply\Nick!
			entity: ply
			id: id
		}

		table.insert @ActivePlayers, t
		@ActivePlayersMapId[id] = t

	@BroadcastCountdown CurTime! + 3
	SetGlobalBool "NMW AU GameInProgress", true
	timer.Create handle, 3, 1, ->
		memo = {}
		table.sort @ActivePlayers, (a, b) ->
			if not a.entity\IsBot!
				memo[a] = 1
			if not b.entity\IsBot!
				memo[b] = 1

			memo[a] = memo[a] or math.random!
			memo[b] = memo[b] or math.random!
			memo[a] > memo[b]

		for index, ply in ipairs @ActivePlayers
			@ActivePlayersMap[ply.entity] = ply
			if index <= @ConVars.ImposterCount\GetInt!
				@Imposters[ply] = true

			if IsValid ply.entity
				with ply.entity
					ply.color = @Colors[math.floor(#@Colors / #@ActivePlayers) * index]

					\Freeze true
					\SetColor ply.color
					\SetNW2Int "NMW AU Meetings", @ConVars.MeetingsPerPlayer\GetInt!

			print string.format "%s is %s", ply.entity\Nick!, @Imposters[ply] and "an imposter" or "a crewmate"

		memo = {}
		table.sort @ActivePlayers, (a, b) ->
			memo[a] = memo[a] or math.random!
			memo[b] = memo[b] or math.random!
			memo[a] > memo[b]

		@BroadcastStart!

		timer.Create handle, 2, 1, ->
			@StartRound!

			for index, ply in ipairs @ActivePlayers
				if IsValid ply.entity
					ply.entity\Freeze true

			timer.Create handle, @SplashScreenTime - 2, 1, ->
				if @CheckWin!
					return

				for index, ply in ipairs @ActivePlayers
					if IsValid ply.entity
						ply.entity\Freeze false

					@SendGameState ply.entity, @GameState.Playing

				for ply in pairs @Imposters
					if IsValid ply.entity
						@UpdateKillCooldown ply

				@ResetMeetingCooldown!

GM.ResetMeetingCooldown = =>
	SetGlobalFloat "NMW AU NextMeeting", CurTime! + @ConVars.MeetingCooldown\GetFloat!

GM.StartRound = =>
	spawns = ents.FindByClass "info_player_start"
	for index, ply in ipairs @ActivePlayers
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

	for ply in pairs @Imposters
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
	aply = GAMEMODE.ActivePlayersMap[activator]
	if aply and GetGlobalBool "NMW AU GameInProgress"
		bodyid = ent\GetNW2Int "NMW AU PlayerID"
		victim = GAMEMODE.ActivePlayersMapId[bodyid]
		if victim
			GAMEMODE\StartMeeting activator, victim.color

hook.Add "FindUseEntity", "NMW AU FindUse", (ply, default) ->
	_, usable = GAMEMODE\TracePlayer ply
	return usable

GM.UnVent = (playerTable) =>
	if vent = @Vented[playerTable]
		@VentCooldown[playerTable] = CurTime! + 1.5

		@NotifyVent playerTable, @VentNotifyReason.UnVent
		playerTable.entity\SetPos vent\GetPos!

		handle = "vent" .. playerTable.nickname
		@BroadcastVent playerTable.entity, vent\GetPos!, true
		timer.Create handle, 0.5, 1, ->
			@Vented[playerTable] = nil
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
	vent = @Vented[playerTable]

	if @Imposters[playerTable] and vent and vent.Links and IsValid(vent.Links[targetVentId]) and (@VentCooldown[playerTable] or 0) <= CurTime!
		targetVent = vent.Links[targetVentId]
		@Vented[playerTable] = targetVent
		
		@NotifyVent playerTable, @VentNotifyReason.Move, @PackVentLinks targetVent
		@VentCooldown[playerTable] = CurTime! + 0.25

		if IsValid playerTable.entity
			playerTable.entity\SetPos targetVent\GetPos!
			playerTable.entity\SetEyeAngles targetVent.ViewAngle

GM.Vent = (playerTable, vent) =>
	if @Imposters[playerTable] and not @Vented[playerTable]
		@NotifyVent playerTable, @VentNotifyReason.Vent, @PackVentLinks vent

		@Vented[playerTable] = vent
		@VentCooldown[playerTable] = CurTime! + 0.75

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

	playerTable = @ActivePlayersMap[ply]
	switch key
		when IN_USE
			if @Imposters[playerTable] and @Vented[playerTable] and (@VentCooldown[playerTable] or 0) <= CurTime!
				@UnVent playerTable
