AddCSLuaFile()

GM.Name 		= "Among Us"
GM.Author 		= "NotMyWing with assets by InnerSloth"
GM.Email 		= ""
GM.Website 		= ""

GM.GameStates =
	LOBBY: 1
	PLAYING: 2
	MEETING: 3

flags = bit.bor FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_GAMEDLL

GM.ConVars =
	ImposterCount: CreateConVar "au_imposter_count", 1, flags, "", 1, 4
	KillCooldown: CreateConVar "au_kill_cooldown", 20, flags, "", 1, 60
	VotePreTime: CreateConVar "au_vote_pre_time", 15, flags, "", 1, 60
	VoteTime: CreateConVar "au_vote_time", 30, flags, "", 1, 60
	VotePostTime: CreateConVar "au_vote_post_time", 5, flags, "", 1, 60
	MeetingCooldown: CreateConVar "au_meeting_cooldown", 20, flags, "", 1, 60
	MeetingsPerPlayer: CreateConVar "au_meeting_available", 2, flags, "", 1, 5
	ConfirmEjects: CreateConVar "au_vote_confirm_ejects", 1, flags, "", 0, 1

	TasksShort: CreateConVar "au_tasks_short", 2, flags, "", 0, 5
	TasksLong: CreateConVar "au_tasks_long", 1, flags, "", 0, 5
	TasksCommon: CreateConVar "au_tasks_common", 1, flags, "", 0, 5
	TasksVisual: CreateConVar "au_tasks_enable_visual", 0, flags, "", 0, 1

	KillDistanceMod: CreateConVar "au_killdistance_mod", 1, flags, "", 1, 3
	DistributeTasksToBots: CreateConVar "au_debug_bot_tasks", 0, flags, "", 0, 1

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

GM.GameState = {
	Preparing: 1
	Playing: 2
}

GM.GameOverReason = {
	Imposter: 1
	Crewmate: 2
}

GM.EjectReason = {
	Vote: 1
	Tie: 2
	Skipped: 3
}

GM.VentNotifyReason = {
	Vent: 1
	UnVent: 2
	Move: 3
}

GM.FlowSize = math.ceil math.log table.Count(GM.FlowTypes) + 1, 2

GM.SplashScreenTime = 8

GM.GetAlivePlayers = =>
	players = {}

	if @GameData.PlayerTables and @GameData.DeadPlayers
		for _, v in ipairs @GameData.PlayerTables
			disconnected = not IsValid v.entity
			if not disconnected and not @GameData.DeadPlayers[v]
				table.insert players, v

	return players

export distSort_memo = {}
export distSort_player = nil
export distSort = (a, b) ->
	distSort_memo[a] or= (a\GetPos! - distSort_player\GetPos!)\Length!
	distSort_memo[b] or= (b\GetPos! - distSort_player\GetPos!)\Length!

	return distSort_memo[a] > distSort_memo[b]

GM.Util = {}

--- Shuffles the table.
-- While this function returns a table, it mutates
-- the input table as well. It only returns it back
-- for the sake of your convenience.
-- @table t The table you need to shuffle.
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
-- @boolean first Should this function only return the first found entity?
GM.Util.FindEntsByTaskName = (taskname, first = false) ->
	with t = {}
		for _, ent in ipairs ents.GetAll!
			if ent.GetTaskName and ent\GetTaskName! == taskname
				table.insert t, ent
				if first
					return t

GM.TracePlayer = (ply) =>
	startPos = ply\GetPos! + Vector 0, 0, 20
	entities = ents.FindInSphere startPos, 96 * @ConVars.KillDistanceMod\GetFloat!

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
				if nearestPoint\Distance(ply\GetPos!) <= 96
					table.insert usable, ent

	distSort_memo = {}
	distSort_player = ply
	table.sort usable, distSort
	table.sort killable, distSort

	return killable[#killable], usable[#usable]

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
