--- Shared things.
-- Defines the game mode metadata fields, enums and exports some useful things.
-- @module shared

AddCSLuaFile()

GM.Name 		= "Among Us"
GM.Author 		= "NotMyWing and contributors, with assets by InnerSloth"
GM.Email 		= "winwyv@gmail.com"
GM.Website 		= "https://github.com/NotMyWing/GarrysModAmongUs"

flags = bit.bor FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_GAMEDLL

--- Table of all ConVars the game mode is using.
-- These are tracked and cannot be changed during the round.
-- @table GM.ConVars
-- @field ImposterCount (Integer) Max imposters.
-- @field KillCooldown (Integer) Kill cooldown.
-- @field KillDistanceMod (Number) Kill distance multiplier.
-- @field ConfirmEjects (Bool) Should the ejects be confirmed?
-- @field MeetingCooldown (Integer) Meeting cooldown.
-- @field MeetingsPerPlayer (Integer) How many meetings a crewmate can call.
-- @field VoteTime (Integer) How long the voting lasts.
-- @field VotePreTime (Integer) How long the pre-voting state lasts.
-- @field VotePostTime (Integer) How long the post-voting state lasts.
-- @field TasksShort (Integer) Max short tasks crewmates can get.
-- @field TasksLong (Integer) Max long tasks crewmates can get.
-- @field TasksCommon (Integer) Max common tasks crewmates can get.
-- @field TasksVisual (Bool) Should the visual parts of tasks be enabled?
-- @field DistributeTasksToBots (Bool) Should bot get any tasks?
GM.ConVars =
	ImposterCount:   CreateConVar "au_imposter_count"  , 1 , flags, "", 1, 4
	KillCooldown:    CreateConVar "au_kill_cooldown"   , 20, flags, "", 1, 60
	KillDistanceMod: CreateConVar "au_killdistance_mod", 1 , flags, "", 1, 3
	ConfirmEjects:   CreateConVar "au_confirm_ejects"  , 1 , flags, "", 0, 1

	MeetingCooldown:   CreateConVar "au_meeting_cooldown"      , 20, flags, "", 1, 60
	MeetingsPerPlayer: CreateConVar "au_meeting_available"     , 2 , flags, "", 1, 5
	VoteTime:          CreateConVar "au_meeting_vote_time"     , 30, flags, "", 1, 90
	VotePreTime:       CreateConVar "au_meeting_vote_pre_time" , 15, flags, "", 1, 60
	VotePostTime:      CreateConVar "au_meeting_vote_post_time", 5 , flags, "", 1, 20

	TasksShort:  CreateConVar "au_tasks_short"        , 2, flags, "", 0, 5
	TasksLong:   CreateConVar "au_tasks_long"         , 1, flags, "", 0, 5
	TasksCommon: CreateConVar "au_tasks_common"       , 1, flags, "", 0, 5
	TasksVisual: CreateConVar "au_tasks_enable_visual", 0, flags, "", 0, 1

	DistributeTasksToBots: CreateConVar "au_debug_bot_tasks" , 0, flags, "", 0, 1

--- Enum of all colors players can get.
-- @warning This isn't the best approach. Needs fixing.
-- @table GM.Colors
GM.Colors = {
	Color 0, 0, 0
	Color 0, 0, 255
	Color 0, 21, 68
	Color 0, 71, 84
	Color 0, 95, 57
	Color 0, 100, 1
	Color 0, 118, 255
	Color 0, 125, 181
	Color 0, 143, 156
	Color 0, 155, 255
	Color 0, 174, 126
	Color 0, 185, 23
	Color 0, 255, 0
	Color 0, 255, 120
	Color 0, 255, 198
	Color 1, 0, 103
	Color 1, 208, 255
	Color 1, 255, 254
	Color 14, 76, 161
	Color 38, 52, 0
	Color 67, 0, 44
	Color 95, 173, 78
	Color 98, 14, 0
	Color 104, 61, 59
	Color 106, 130, 108
	Color 107, 104, 130
	Color 117, 68, 177
	Color 119, 77, 0
	Color 120, 130, 49
	Color 122, 71, 130
	Color 126, 45, 210
	Color 133, 169, 0
	Color 144, 251, 146
	Color 145, 208, 203
	Color 149, 0, 58
	Color 150, 138, 232
	Color 152, 255, 82
	Color 158, 0, 142
	Color 164, 36, 0
	Color 165, 255, 210
	Color 167, 87, 64
	Color 181, 0, 255
	Color 187, 136, 0
	Color 189, 198, 255
	Color 189, 211, 147
	Color 190, 153, 112
	Color 194, 140, 159
	Color 213, 255, 0
	Color 222, 255, 116
	Color 229, 111, 254
	Color 232, 94, 190
	Color 254, 137, 0
	Color 255, 0, 0
	Color 255, 0, 86
	Color 255, 0, 246
	Color 255, 2, 157
	Color 255, 110, 65
	Color 255, 116, 163
	Color 255, 147, 126
	Color 255, 166, 254
	Color 255, 177, 103
	Color 255, 219, 102
	Color 255, 229, 2
	Color 255, 238, 232
}

-- luadoc is dumb

--- Enum of all flow types.
--
-- "Flow" is a reliable channel used for pretty much everything
-- related to networking data between the server and clients.
--
-- Using one channel guarantees the lack of race conditions.
-- Besides, polluting the game with tens of random network strings is just bad.
-- @table GM.FlowTypes
-- @field GameStart 1
-- @field Countdown 2
-- @field KillRequest 3
-- @field BroadcastDead 4
-- @field KillCooldown 5
-- @field GameState 6
-- @field GameOver 7
-- @field Meeting 8
-- @field OpenDiscuss 9
-- @field Eject 10
-- @field MeetingVote 11
-- @field MeetingEnd 12
-- @field NotifyVent 13
-- @field VentAnim 14
-- @field VentRequest 15
-- @field RequestUpdate 16
-- @field TasksUpdateData 17
-- @field TasksSubmit 18
-- @field TasksOpenVGUI 19
-- @field TasksCloseVGUI 20
-- @field TasksUpdateCount 21
-- @field NotifyKilled 22
GM.FlowTypes = {
	GameStart: 1
	Countdown: 2
	KillRequest: 3
	BroadcastDead: 4
	KillCooldown: 5
	GameState: 6
	GameOver: 7
	Meeting: 8
	OpenDiscuss: 9
	Eject: 10
	MeetingVote: 11
	MeetingEnd: 12
	NotifyVent: 13
	VentAnim: 14
	VentRequest: 15
	RequestUpdate: 16
	TasksUpdateData: 17
	TasksSubmit: 18
	TasksOpenVGUI: 19
	TasksCloseVGUI: 20
	TasksUpdateCount: 21
	NotifyKilled: 22
}

GM.FlowSize = math.ceil math.log table.Count(GM.FlowTypes) + 1, 2

--- Enum of game states.
-- @warning This is probably redundant?
-- @field Preparing 1
-- @field Playing 2
GM.GameState = {
	Preparing: 1
	Playing: 2
}

--- Enum of all reasons why a round can end.
-- @table GM.GameOverReason
-- @field Imposter 1
-- @field Crewmate 2
GM.GameOverReason = {
	Imposter: 1
	Crewmate: 2
}

--- Enum of all reasons why a crewmate can be ejected.
-- @table GM.EjectReason
-- @field Vote 1
-- @field Tie 2
-- @field Skipped 3
GM.EjectReason = {
	Vote: 1
	Tie: 2
	Skipped: 3
}

--- Enum of all actions related to vents.
-- @table GM.VentNotifyReason
-- @field Vent 1
-- @field UnVent 2
-- @field Move 3
GM.VentNotifyReason = {
	Vent: 1
	UnVent: 2
	Move: 3
}

GM.SplashScreenTime = 8
GM.BaseUseRadius = 96

--- Fetches all valid and alive players.
-- This is only ever used once, and not for the gameplay reasons.
-- If you want to iterate through alive players, consider looking at
-- GAMEMODE.GameData.PlayerTables and using the
-- GAMEMODE.GameData.DeadPlayers lookup table instead.
GM.GetAlivePlayers = =>
	players = {}

	if @GameData.PlayerTables and @GameData.DeadPlayers
		for _, v in ipairs @GameData.PlayerTables
			disconnected = not IsValid v.entity
			if not disconnected and not @GameData.DeadPlayers[v]
				table.insert players, v

	return players

GM.Util = {}

--- Sorts the table of entities based on how close an entity is to the specified one.
-- While this function returns a table, it mutates
-- the input table as well. It only returns it back
-- for the sake of your convenience.
-- @param tbl Table of entities.
-- @param entity Entity we're sorting agaist.
-- @return The sorted table.
GM.Util.SortByDistance = (tbl, entity) ->
	memo = {}
	table.sort tbl, (a, b) ->
		memo[a] or= (a\GetPos! - entity\GetPos!)\Length!
		memo[b] or= (b\GetPos! - entity\GetPos!)\Length!

		return memo[a] > memo[b]

	return tbl

--- Shuffles the table.
-- While this function returns a table, it mutates
-- the input table as well. It only returns it back
-- for the sake of your convenience.
-- @param t The table you need to shuffle.
-- @return The shuffled table.
GM.Util.Shuffle = (t) ->
	memo = {}
	table.sort t, (a, b) ->
		memo[a] = memo[a] or math.random!
		memo[b] = memo[b] or math.random!
		memo[a] > memo[b]

	return t

whitelist = {
	"func_button": true
	"func_door": true
	"func_door_rotating": true
	"func_meeting_button": true
	"prop_meeting_button": true
	"player": true
	"prop_ragdoll": true
	"prop_physics": true
	"func_vent": true
	"prop_vent": true
	"func_task_button": true
	"prop_task_button": true
}

--- Finds all entities with the matching task name field.
-- @string taskname You guessed it.
-- @bool first Should this function only return the first found entity?
GM.Util.FindEntsByTaskName = (taskname, first = false) ->
	with t = {}
		for _, ent in ipairs ents.GetAll!
			if ent.GetTaskName and ent\GetTaskName! == taskname
				table.insert t, ent
				if first
					return t

--- Finds a pair of the closest interactable and killable entities
-- within the reach of the player in question.
-- @param ply The player ENTITY.
-- @return The closest killable entity. Nullable.
-- @return The closest usable entity. Nullable.
GM.TracePlayer = (ply) =>
	startPos = ply\WorldSpaceCenter!
	entities = ents.FindInSphere startPos, @BaseUseRadius * @ConVars.KillDistanceMod\GetFloat!

	usable = {}
	killable = {}

	playerTable = @GameData.Lookup_PlayerByEntity[ply]
	if not playerTable or (SERVER and @GameData.Vented[playerTable]) or (CLIENT and @GameData.Vented)
		return

	for _, ent in ipairs entities
		if ent == ply
			continue

		if whitelist[ent\GetClass!]
			if SERVER and not ply\TestPVS ent
				continue

			-- Task buttons.
			if ent\GetClass! == "func_task_button" or ent\GetClass! == "prop_task_button"
				name = ent\GetTaskName!

				-- Quite simply just bail out if the player is an imposter.
				if @GameData.Imposters[playerTable]
					continue

				if SERVER
					-- Bail out if the player doesn't have this task, or if it's not the current button.
					if not (@GameData.Tasks[playerTable] and @GameData.Tasks[playerTable][name]) or
						ent ~= @GameData.Tasks[playerTable][name]\GetActivationButton!
							continue

				if CLIENT
					-- Bail out if the local player doesn't have this task, or if he's completed it already.
					if not @GameData.MyTasks[name] or
						@GameData.MyTasks[name].completed or ent ~= @GameData.MyTasks[name].entity
							continue

			-- Prevent dead players from being able to target corpses.
			if ent\GetClass! == "prop_ragdoll" and @GameData.DeadPlayers[playerTable]
				continue

			-- Prevent regular players from using vents.
			if (ent\GetClass! == "func_vent" or ent\GetClass! == "prop_vent") and not @GameData.Imposters[playerTable]
				continue

			otherPlayerTable = @GameData.Lookup_PlayerByEntity[ent]

			isKillable = otherPlayerTable and ent\IsPlayer! and not ent\IsDormant! and @GameData.Imposters[playerTable] and
				not @GameData.Imposters[otherPlayerTable] and not @GameData.DeadPlayers[otherPlayerTable]

			isUsable = not isKillable and not ent\IsPlayer!
			if isKillable
				table.insert killable, ent
			elseif isUsable
				nearestPoint = ent\NearestPoint startPos
				if nearestPoint\Distance(ply\GetPos!) <= @BaseUseRadius
					table.insert usable, ent

	GAMEMODE.Util.SortByDistance usable, ply
	GAMEMODE.Util.SortByDistance killable, ply

	return killable[#killable], usable[#usable]

--- Returns whether the game is progress.
-- @return You guessed it.
GM.IsGameInProgress = => GetGlobalBool "NMW AU GameInProgress"

GM.LoadManifest = =>
	-- Default to an empty table so that things don't die horribly.
	@MapManifest = {}

	dir = @FolderName or "amongus"
	fileName = "#{dir}/gamemode/manifest/#{game.GetMap!}.lua"

	if file.Exists fileName, "LUA"
		if SERVER
			AddCSLuaFile fileName

		@MapManifest = include fileName

		print "Found the manifest file for #{game.GetMap!}"
	else
		print "Couldn't find the manifest file for #{game.GetMap!}! The game mode will not work properly."

hook.Add "Initialize", "NMW AU LoadManifest", ->
	GAMEMODE\LoadManifest!
