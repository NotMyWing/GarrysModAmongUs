include "shared.lua"
include "sv_net.lua"
include "sv_spectate.lua"
include "sv_resources.lua"
include "sv_player.lua"
include "sv_meeting.lua"

AddCSLuaFile "sh_gamedata.lua"
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

GM.GameOver = (reason) =>
	for index, ply in ipairs player.GetAll!
		ply\Freeze true

	@SetGameInProgress false
	@Net_BroadcastDead!
	@Net_BroadcastGameOver reason

	handle = "game"

	@GameData.Timers[handle] = true
	timer.Create handle, 9, 1, ->
		@Restart!

GM.CheckWin = =>
	if not @IsGameInProgress!
		return

	numImposters = 0
	numPlayers = 0

	for _, ply in pairs @GameData.PlayerTables
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
		@GameOver reason
		return true

GM.CleanUp = =>
	for handle, _ in pairs @GameData.Timers
		timer.Remove handle

	GAMEMODE\PurgeGameData!

	@SetGameInProgress false
	@Player_UnhideEveryone!

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
		@Net_SendGameState ply, @GameState.Preparing

GM.StartGame = =>
	@CleanUp!

	handle = "game"
	@GameData.Timers[handle] = true

	@GameData.PlayerTables = {}
	@GameData.Lookup_PlayerByID = {}
	id = 0
	for _, ply in ipairs player.GetAll!
		id += 1
		t = {
			steamid: ply\SteamID!
			nickname: ply\Nick!
			entity: ply
			id: id
		}

		table.insert @GameData.PlayerTables, t
		@GameData.Lookup_PlayerByID[id] = t

	@Net_BroadcastCountdown CurTime! + 3
	
	timer.Create handle, 3, 1, ->
		memo = {}
		table.sort @GameData.PlayerTables, (a, b) ->
			if not a.entity\IsBot!
				memo[a] = 1
			if not b.entity\IsBot!
				memo[b] = 1

			memo[a] = memo[a] or math.random!
			memo[b] = memo[b] or math.random!
			memo[a] > memo[b]

		for index, ply in ipairs @GameData.PlayerTables
			@GameData.Lookup_PlayerByEntity[ply.entity] = ply
			if index <= @ConVars.ImposterCount\GetInt!
				@GameData.Imposters[ply] = true

			if IsValid ply.entity
				with ply.entity
					ply.color = @Colors[math.floor(#@Colors / #@GameData.PlayerTables) * index]

					\Freeze true
					\SetColor ply.color
					\SetNW2Int "NMW AU Meetings", @ConVars.MeetingsPerPlayer\GetInt!

			print string.format "%s is %s", ply.entity\Nick!, @GameData.Imposters[ply] and "an imposter" or "a crewmate"

		memo = {}
		table.sort @GameData.PlayerTables, (a, b) ->
			memo[a] = memo[a] or math.random!
			memo[b] = memo[b] or math.random!
			memo[a] > memo[b]

		@Net_BroadcastGameStart!
		@SetGameInProgress true

		timer.Create handle, 2, 1, ->
			@StartRound!

			for index, ply in ipairs @GameData.PlayerTables
				if IsValid ply.entity
					ply.entity\Freeze true

			timer.Create handle, @SplashScreenTime - 2, 1, ->
				if @CheckWin!
					return

				for index, ply in ipairs @GameData.PlayerTables
					if IsValid ply.entity
						ply.entity\Freeze false

					@Net_SendGameState ply.entity, @GameState.Playing

				for ply in pairs @GameData.Imposters
					if IsValid ply.entity
						@Player_UpdateKillCooldown ply

				@Meeting_ResetCooldown!

GM.StartRound = =>
	spawns = ents.FindByClass "info_player_start"
	for index, ply in ipairs @GameData.PlayerTables
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
		@Player_UpdateKillCooldown ply

	@Meeting_ResetCooldown!

concommand.Add "au_debug_start", ->
	GAMEMODE\Restart!

	GAMEMODE\StartGame!

concommand.Add "au_debug_restart", ->
	GAMEMODE\Restart!
