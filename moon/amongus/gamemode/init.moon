-- Obligatory includes
include "shared.lua"
include "sh_gamedata.lua"
include "sh_lang.lua"

include "sv_net.lua"
include "sv_spectate.lua"
include "sv_resources.lua"
include "sv_player.lua"
include "sv_meeting.lua"

include "sh_hooks.lua"
include "sh_tasks.lua"
include "sh_sabotages.lua"
include "sh_manifest.lua"

-- Obligatory client stuff
AddCSLuaFile "sh_lang.lua"
AddCSLuaFile "sh_gamedata.lua"
AddCSLuaFile "sh_tasks.lua"
AddCSLuaFile "sh_sabotages.lua"
AddCSLuaFile "sh_hooks.lua"
AddCSLuaFile "vgui/vgui_splash.lua"
AddCSLuaFile "vgui/vgui_hud.lua"
AddCSLuaFile "vgui/vgui_meeting.lua"
AddCSLuaFile "vgui/vgui_eject.lua"
AddCSLuaFile "vgui/vgui_blink.lua"
AddCSLuaFile "vgui/vgui_vent.lua"
AddCSLuaFile "vgui/vgui_task_base.lua"
AddCSLuaFile "vgui/vgui_sabotage_base.lua"
AddCSLuaFile "vgui/vgui_task_placeholder.lua"
AddCSLuaFile "vgui/vgui_kill.lua"
AddCSLuaFile "vgui/vgui_map.lua"
AddCSLuaFile "vgui/kills/remover.lua"
AddCSLuaFile "cl_hud.lua"
AddCSLuaFile "cl_net.lua"
AddCSLuaFile "cl_render.lua"
AddCSLuaFile "sh_manifest.lua"

GM.GameOver = (reason) =>
	for index, ply in ipairs player.GetAll!
		ply\Freeze true

	@SetGameInProgress false
	@Player_CloseVGUIsForEveryone!
	@Net_BroadcastDead!
	@Net_BroadcastGameOver reason

	handle = "game"

	@GameData.Timers[handle] = true
	timer.Create handle, 9, 1, ->
		@Restart!

GM.CheckWin = (reason) =>
	if not @IsGameInProgress!
		return

	if not reason
		reason = if @GetTimeLimit! == 0
			@GameOverReason.Crewmate
		elseif @GameData.CompletedTasks >= @GameData.TotalTasks
			@GameOverReason.Crewmate
		else
			numImposters = 0
			numPlayers = 0

			-- Count imposters and players and decide whether the game is over.
			for _, ply in pairs @GameData.PlayerTables
				if IsValid(ply.entity) and not @GameData.DeadPlayers[ply]
					if @GameData.Imposters[ply]
						numImposters += 1
					else
						numPlayers += 1

			if numImposters == 0
				@GameOverReason.Crewmate
			elseif numImposters >= numPlayers
				@GameOverReason.Imposter

	if reason
		@GameOver reason
		return true

GM.CleanUp = =>
	-- Shut all ongoing sabotages down gracefully.
	if @GameData.Sabotages
		@Sabotage_ForceEndAll!

	for handle, _ in pairs @GameData.Timers
		timer.Remove handle

	@PurgeGameData!

	@SetGameInProgress false
	@SetCommunicationsDisabled false

	@Player_UnhideEveryone!
	timer.Remove "NMW AU CheckWin"

	game.CleanUpMap!

GM.Restart = =>
	@CleanUp!

	spawns = ents.FindByClass "info_player_start"
	players = player.GetAll!

	-- Spawn, prepare and spread players around.
	for index, ply in ipairs players
		ply\SetColor @Colors[math.floor(#@Colors / #players) * index]
		ply\SetRenderMode RENDERGROUP_OPAQUE

		ply\UnSpectate!
		ply\Freeze false
		ply\Spawn!

		-- ???????
		if #spawns ~= 0
			point = spawns[(index % #spawns) + 1]
			ply\SetPos point\GetPos!
			ply\SetAngles point\GetAngles!
			ply\SetEyeAngles point\GetAngles!

	@SetGameState @GameState.Preparing

GM.StartGame = =>
	-- Bail if the manifest is missing or malformed.
	if not @MapManifest or not @MapManifest.Tasks
		return

	-- Bail if we don't have enough players.
	-- TO-DO: print chat message.
	if #player.GetAll! - @ConVars.ImposterCount\GetInt! * 2 < 1
		return

	@CleanUp!

	handle = "game"
	@GameData.Timers[handle] = true

	-- Count players.
	playerMemo = player.GetAll!

	time = @ConVars.Countdown\GetFloat! + 0.5
	@Net_BroadcastCountdown CurTime! + time

	timer.Create handle, time, 1, ->
		-- Don't start in case somebody has left.
		for _, ply in ipairs playerMemo
			if not IsValid ply
				return

		-- Create the time limit timer if the cvar is set.
		-- That's quite an interesting sentence.
		timelimit = @ConVars.TimeLimit\GetInt!
		timelimitHandle = "timelimitHandle"
		if timelimit > 0
			@GameData.Timers[timelimitHandle] = true

			@SetTimeLimit timelimit
			timer.Create timelimitHandle, 1, timelimit, ->
				remainder = timer.RepsLeft timelimitHandle
				@SetTimeLimit remainder
				if remainder == 0
					@CheckWin!

			timer.Pause timelimitHandle
		else
			@SetTimeLimit -1

		-- Create player "accounts" that we're going
		-- to use during the entire game.
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
			@GameData.Lookup_PlayerByEntity[ply] = t

		-- Shuffle.
		memo = {}
		table.sort @GameData.PlayerTables, (a, b) ->
			-- I use this for testing.
			-- Ignore.
			-- if not a.entity\IsBot!
			--	memo[a] = 1
			-- if not b.entity\IsBot!
			--	memo[b] = 1

			memo[a] = memo[a] or math.random!
			memo[b] = memo[b] or math.random!
			memo[a] > memo[b]

		for index, ply in ipairs @GameData.PlayerTables
			-- Give the player a color.
			-- TO-DO: make customizable.
			ply.color = @Colors[math.floor(#@Colors / #@GameData.PlayerTables) * index]

			-- Make the first N players imposters.
			if index <= @ConVars.ImposterCount\GetInt!
				@GameData.Imposters[ply] = true

			with ply.entity
				\Freeze true
				\SetColor ply.color
				\SetNW2Int "NMW AU Meetings", @ConVars.MeetingsPerPlayer\GetInt!

		-- Shuffle the player table one more time.
		-- We don't want to broadcast the previous table
		-- since it'd reveal the imposters right away.
		memo = {}
		table.sort @GameData.PlayerTables, (a, b) ->
			memo[a] = memo[a] or math.random!
			memo[b] = memo[b] or math.random!
			memo[a] > memo[b]

		-- Assign the tasks to players.
		@Task_AssignToPlayers!

		-- Broadcast the important stuff that players must know about the game.
		@SetGameInProgress true
		@Net_BroadcastGameStart!

		-- Start the game after a dramatic pause.
		-- Teleport players while they're staring at the splash screen.
		timer.Create handle, 2, 1, ->
			@StartRound!

			for index, ply in ipairs @GameData.PlayerTables
				if IsValid ply.entity
					ply.entity\Freeze true

			--
			timer.Create handle, @SplashScreenTime - 2, 1, ->
				-- Check if suddenly something went extremely wrong during the windup time.
				if @CheckWin!
					return

				-- Set off the timeout timer.
				if timer.Exists timelimitHandle
					timer.UnPause timelimitHandle

				-- Otherwise start the game and fire up the background check timer.
				timer.Create "NMW AU CheckWin", 5, 0, ->
					if GAMEMODE\IsGameInProgress!
						GAMEMODE\CheckWin!
					else
						timer.Remove "NMW AU CheckWin"

				-- Unfreeze everyone and broadcast buttons.
				for index, ply in ipairs @GameData.PlayerTables
					if IsValid ply.entity
						ply.entity\Freeze fal

					if @GameData.Imposters[ply]
						@Player_RefreshKillCooldown ply

				@Sabotage_Init!
				@SetGameState @GameState.Playing

				@Meeting_ResetCooldown!

GM.StartRound = =>
	-- Spawn the players and spread them around.
	spawns = ents.FindByClass "info_player_start"
	for index, ply in ipairs @GameData.PlayerTables
		if IsValid ply.entity
			with ply.entity
				point = spawns[(index % #spawns) + 1]
				\Spawn!
				\SetPos point\GetPos!
				\SetAngles point\GetAngles!
				\SetEyeAngles point\GetAngles!

	-- Call janitors to get rid of the bodies.
	bodies = ents.FindByClass "prop_ragdoll"
	for _, body in ipairs bodies
		if 0 ~= body\GetNW2Int "NMW AU PlayerID"
			body\Remove!

	for ply in pairs @GameData.Imposters
		@Player_RefreshKillCooldown ply

	@Meeting_ResetCooldown!

GM.SetGameState = (newState) =>
	@GameData.State = newState
	@Net_BroadcastGameState newState

concommand.Add "au_debug_start", ->
	GAMEMODE\Restart!

	GAMEMODE\StartGame!

concommand.Add "au_debug_restart", ->
	GAMEMODE\Restart!

-- Disable changing important ConVars during the game.
for _, convar in pairs GM.ConVars
	-- Prevent the game from dying.
	changing = false

	cvars.AddChangeCallback convar\GetName!, ((cvar, old, new) ->
		if not changing
			changing = true
			if GAMEMODE\IsGameInProgress!
				convar\SetString old
			changing = false
	), "NMW AU Protect"

hook.Add "Initialize", "NMW AU Initialize", ->
	GAMEMODE\Restart!

	-- screw implicit returns man
	return
