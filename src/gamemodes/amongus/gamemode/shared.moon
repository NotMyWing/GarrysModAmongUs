--- Shared things.
-- Defines the game mode metadata fields, enums and exports some useful things.
-- @module shared

export GAMEMODE = GAMEMODE or GM

AddCSLuaFile()

GM.Name 		= "Among Us"
GM.Author 		= "NotMyWing and contributors, with assets by InnerSloth"
GM.Email 		= "winwyv@gmail.com"
GM.Website 		= "https://github.com/NotMyWing/GarrysModAmongUs"

GM.Version    = "{{CI_GAMEMODE_VERSION}}"
GM.WorkshopID = "{{CI_WORKSHOP_ID}}"

GM.Version    = "manual-build" if GM.Version    == "{{" .. "CI_GAMEMODE_VERSION}}"
GM.WorkshopID = nil            if GM.WorkshopID == "{{" .. "CI_WORKSHOP_ID}}"

flags = bit.bor FCVAR_ARCHIVE, FCVAR_REPLICATED

--- Table of all ConVars the game mode is using.
-- These are tracked and cannot be changed during the round.
-- @table GM.ConVars
-- @field ImposterCount (Integer) Max. imposters.
-- @field ImposterCount (Integer) Min. players.
-- @field KillCooldown (Integer) Kill cooldown.
-- @field KillDistanceMod (Number) Kill distance multiplier.
-- @field ConfirmEjects (Bool) Should the ejects be confirmed?
-- @field DeadChat (Bool) Should dead players be able to talk?
-- @field GameChat (Bool) Should players be able to talk during the game?
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
-- @field TimeLimit (Integer) Round time limit.
-- @field Countdown (Integer) How long the pre-round countdown lasts.
-- @field WarmupTime (Integer) How long should the warmup phase last?
-- @field ForceAutoWarmup (Bool) Should the automated round management be forced?
GM.ConVars =
	ImposterCount:   CreateConVar "au_max_imposters"   , 1 , flags, "", 1, 10
	MinPlayers:      CreateConVar "au_min_players"     , 3 , flags, "", 3, 128
	KillCooldown:    CreateConVar "au_kill_cooldown"   , 20, flags, "", 1, 60
	KillDistanceMod: CreateConVar "au_killdistance_mod", 1 , flags, "", 1, 3
	ConfirmEjects:   CreateConVar "au_confirm_ejects"  , 1 , flags, "", 0, 1
	DeadChat:        CreateConVar "au_dead_chat"       , 0 , flags, "", 0, 1
	GameChat:        CreateConVar "au_game_chat"       , 0 , flags, "", 0, 1

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
	MeetingBotVote:        CreateConVar "au_debug_bot_vote"  , 0, flags, "", 0, 1

	TimeLimit: CreateConVar "au_time_limit", 600, flags, "", 0, 1200
	Countdown: CreateConVar "au_countdown" , 5  , flags, "", 1, 10

	WarmupTime:      CreateConVar "au_warmup_time"      , 60, flags, "", 0, 120
	ForceAutoWarmup: CreateConVar "au_warmup_force_auto", 0 , flags, "", 0, 1

	PlayerModel: CreateConVar "au_player_model", "models/amongus/player/player.mdl",
		flags, ""

--- Enum of all colors players can get.
-- @table GM.Colors
GM.Colors = {
	Color 255, 39, 39
	Color 255, 137, 18
	Color 255, 255, 26
	Color 149, 255, 26
	Color 0, 230, 76
	Color 0, 250, 250
	Color 51, 51, 255
	Color 197, 26, 255
	Color 255, 39, 145
	Color 128, 70, 31
	Color 250, 250, 250
	Color 128, 128, 128
	Color 20, 20, 20

	Color 255, 107, 107
	Color 255, 166, 77
	Color 255, 255, 115
	Color 179, 255, 102
	Color 98, 245, 147
	Color 128, 255, 255
	Color 102, 102, 255
	Color 223, 128, 255
	Color 255, 114, 164
	Color 173, 107, 61

	Color 179, 18, 18
	Color 207, 103, 0
	Color 191, 191, 0
	Color 98, 183, 0
	Color 0, 115, 38
	Color 0, 169, 169
	Color 28, 28, 140
	Color 143, 0, 143
	Color 178, 0, 89
	Color 74, 41, 18
}

--- Enum of all flow types.
--
-- "Flow" is a reliable channel used for pretty much everything
-- related to networking data between the server and clients.
--
-- Using one channel guarantees the lack of race conditions.
-- Besides, polluting the game with tens of random network strings is just bad.
GM.FlowTypes = { value, i for i, value in ipairs {
	"RequestUpdate"

	"GameStart"
	"GameState"
	"GameOver"
	"GameCountdown"
	"GameChatNotification"

	"BroadcastDead"

	"KillRequest"
	"KillCooldown"
	"KillCooldownPause"

	"MeetingStart"
	"MeetingOpenDiscuss"
	"MeetingVote"
	"MeetingEnd"
	"MeetingEject"

	"NotifyKilled"
	"NotifyVent"

	"VentAnim"
	"VentRequest"

	"TasksUpdateData"
	"TasksSubmit"
	"TasksUpdateCount"

	"CloseVGUI"
	"OpenVGUI"

	"SabotageData"
	"SabotageRequest"
	"SabotageSubmit"

	"ConVarSnapshots"
	"ConnectDisconnect"
	"ShowHelp"
	"UpdateMyColor"
}}

GM.FlowSize = math.ceil math.log table.Count(GM.FlowTypes) + 1, 2

--- Enum of all task types available in the game mode.
-- @field Short 1
-- @field Long 2
-- @field Common 3
GM.TaskType = {
	Short: 1
	Long: 2
	Common: 3
}

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

--- Enum of TracePlayer filters.
GM.TracePlayerFilter = {
	None: 0
	Usable: 1
	Reportable: 2
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
		for v in *@GameData.PlayerTables
			disconnected = not IsValid v.entity
			if not disconnected and not @GameData.DeadPlayers[v]
				table.insert players, v

	return players

GM.Util = {}

--- Shuffles the table.
-- While this function returns a table, it mutates
-- the input table as well. It only returns it back
-- for the sake of your convenience.
-- @param t The table you need to shuffle.
-- @return The shuffled table.
GM.Util.Shuffle = (t) ->
	for i = #t, 2, -1
		j = math.random i
		t[i], t[j] = t[j], t[i]

	return t

--- Finds all entities with the matching task name field.
-- @string taskname You guessed it.
-- @bool first Should this function only return the first found entity?
GM.Util.FindEntsByTaskName = (taskname, first = false) ->
	with t = {}
		for ent in *ents.GetAll!
			if ent.GetTaskName and ent\GetTaskName! == taskname
				table.insert t, ent
				if first
					return t

--- Finds a pair of the closest interactable and reportable
-- within the reach of the player in question.
-- Prioritizes hightlightable entities.
-- @param ply The player.
-- @param filter Optional filter.
-- @return The closest usable entity. Nullable.
-- @return The closest reportable entity. Nullable.
GM.TracePlayer = (playerTable, filter = 0) =>
	startTime = SysTime!
	return unless @IsGameInProgress!

	-- Fetch the player table if we haven't been provided one.
	if "Player" == type playerTable
		playerTable = playerTable\GetAUPlayerTable!

	-- Bail if the player table is invalid, or if the player is in a vent.
	return if not playerTable or
		(SERVER and @GameData.Vented[playerTable]) or
		(CLIENT and @GameData.Vented)

	ply = playerTable.entity

	startPos = ply\EyePos!
	entities = ents.FindInSphere startPos, @BaseUseRadius

	-- Define all three classes of entities this function can possibly report.
	local usable, highlightable, reportable
	distMemo = {}

	for ent in *entities
		-- Simply check if the entity isn't the player.
		continue if ent == ply

		-- Check if the entity is in PVS.
		-- This is the only check that can't be done on the client, unfortunately.
		continue if SERVER and not ply\TestPVS ent

		-- Calculate the nearest point to the cursor.
		if not distMemo[ent]
			nearestPoint = ent\NearestPoint startPos
			distMemo[ent] = nearestPoint\DistToSqr ply\EyePos! + ply\GetAimVector! * 32

		isBody = @IsPlayerBody ent

		-- Store if body.
		if isBody and (filter == @TracePlayerFilter.None or filter == @TracePlayerFilter.Reportable)
			-- Only return the body if the player isn't dead.
			continue if @GameData.DeadPlayers[playerTable]

			reportable = ent if not reportable or distMemo[ent] > distMemo[reportable]
			continue

		-- Bail if the filter is set to target bodies.
		elseif filter == @TracePlayerFilter.Reportable
			continue

		isUsable = not isBody and not ent\IsPlayer!
		continue if not isUsable

		isHightlightable = @ShouldHighlightEntity ent

		-- If we found a highlightable entity already and the current entity isn't highlightable,
		-- then bail since there's no point in checking it.
		if highlightable and not isHightlightable
			continue

		-- Return if the current found entity is farther than the last stored.
		otherDist = distMemo[highlightable or usable]
		continue if otherDist and otherDist < distMemo[ent]

		-- No point entities. No view models.
		continue if not ent\GetModel! or ent\GetModelRadius! == 0

		entClass = ent\GetClass!

		-- Don't match triggers.
		continue if string.match entClass, "^trigger_"

		-- Task buttons.
		if entClass == "func_task_button" or entClass == "prop_task_button"
			name = ent\GetTaskName!

			-- Quite simply just bail out if the player is an imposter.
			continue if @GameData.Imposters[playerTable]

			-- Bail if the meeting is in progress.
			continue if @IsMeetingInProgress!

			if SERVER
				-- Bail out if the player doesn't have this task, or if it's not the current button,
				-- or if the button doesn't consent.
				continue if not (@GameData.Tasks[playerTable] and @GameData.Tasks[playerTable][name]) or
					ent ~= @GameData.Tasks[playerTable][name]\GetActivationButton! or
					not @GameData.Tasks[playerTable][name]\CanUse!

			if CLIENT
				-- Bail out if the local player doesn't have this task, or if he's completed it already, or
				-- if the button doesn't consent.
				continue if not @GameData.MyTasks[name] or
					@GameData.MyTasks[name]\GetCompleted! or ent ~= @GameData.MyTasks[name]\GetActivationButton! or
					not @GameData.MyTasks[name]\CanUse!

		-- Prevent dead players from being able to target corpses.
		continue if entClass == "prop_ragdoll" and @GameData.DeadPlayers[playerTable]

		-- Prevent regular players from using vents.
		continue if (entClass == "func_vent" or entClass == "prop_vent") and not @GameData.Imposters[playerTable]

		-- Only highlight sabotage buttons when they're active, and when the player isn't dead.
		if (entClass == "func_sabotage_button" or entClass == "prop_sabotage_button")
			continue if @GameData.DeadPlayers[playerTable] or not @GameData.SabotageButtons[ent]
			continue if @IsMeetingInProgress!

		-- Only highlight doors when requested by sabotages.
		if (entClass == "func_door" or entClass == "func_door_rotating")
			continue if @GameData.DeadPlayers[playerTable] or not @GameData.SabotageButtons[ent]

		-- Only hightlight meeting buttons when the cooldown has passed, and when the player isn't dead.
		if (entClass == "func_meeting_button" or entClass == "prop_meeting_button")
			continue if @GameData.DeadPlayers[playerTable]
			continue if @IsMeetingDisabled!
			continue if @IsMeetingInProgress!
			continue if 0 >= ply\GetNWInt "NMW AU Meetings"

			time = GetGlobalFloat("NMW AU NextMeeting") - CurTime!

			continue if time > 0

		if isHightlightable
			highlightable = ent

		usable = ent

	export LAST_TRACE_PLAYER_TIME = 1000 * (SysTime! - startTime)

	return switch filter
		when @TracePlayerFilter.Reportable
			reportable

		when @TracePlayerFilter.Usable
			usable

		else
			usable, reportable

--- Returns whether the game is progress.
-- @return You guessed it.
GM.IsGameInProgress = => GetGlobalBool "NMW AU GameInProgress"

--- Returns the time limit.
-- If there's no time limit, this will return -1.
-- @return You guessed it.
GM.GetTimeLimit = => GetGlobalInt "NMW AU TimeLimit"

--- Returns whether the communications are disabled (sabotaged).
-- @return You guessed it.
GM.GetCommunicationsDisabled = => GetGlobalInt "NMW AU CommsDisabled"

--- Returns whether calling the meeting button is impossible (sabotaged).
-- @return You guessed it.
GM.IsMeetingDisabled = => GetGlobalBool "NMW AU MeetingDisabled"

--- Returns whether calling the meeting is in progress.
-- @return You guessed it.
GM.IsMeetingInProgress = => GetGlobalBool "NMW AU MeetingInProgress"

--- Returns whether the game is commencing.
-- @return You guessed it.
GM.IsGameCommencing = => GetGlobalBool "NMW AU GameCommencing"

--- Returns whether the game flow is controlled by the server.
-- @return You guessed it.
GM.IsOnAutoPilot = => GetGlobalBool "NMW AU AutoPilot"

--- Returns a table of fully initialized players.
GM.GetFullyInitializedPlayers = => return for ply in *player.GetAll!
	if ply\IsBot! or ply\GetNWBool "NMW AU Initialized"
		ply
	else
		continue

--- Gets the imposter count based on the provided number.
GM.GetImposterCount = (_, count) -> math.floor(((count or _) - 1)/6) + 1

--- Tells the game mode that the entity should be highlighted as usable.
-- @param entity Entity to be highlighted.
-- @param highlight Should the entity be highlighted?
-- @param color Optional color. Defaults to white.
GM.SetUseHighlight = (entity, highlight = false, color = Color(255, 255, 255)) =>
	entity\SetNWBool "NMW AU UseHighlight", highlight
	if highlight
		entity\SetNWVector "NMW AU HighlightColor", color\ToVector!

--- Gets whether the entity should be highlighted.
-- @param entity Entity.
GM.ShouldHighlightEntity = (entity) =>
	return false unless IsValid entity
	return true if entity\GetNWBool "NMW AU UseHighlight"

	return true if switch string.match entity\GetClass!, "[^_]*_(.+)"
		when "task_button", "meeting_button", "vent", "sabotage_button"
			true

	return true if hook.Call "GMAU ShouldHighlight", nil, entity
	return true if @IsPlayerBody entity

	return false

--- Returns whether the entity is a player body.
-- @param entity Entity.
GM.IsPlayerBody = (entity) => 0 < entity\GetDTInt 15

--- Returns the player table associated with the corpse. Can be nil.
-- @param entity Entity.
GM.GetPlayerTableFromCorpse = (entity) => @GameData.Lookup_PlayerByID[entity\GetDTInt 15]

--- Returns the default player model.
GM.GetDefaultPlayerModel = =>
	defaultModel = @ConVars.PlayerModel\GetString!
	if nil == defaultModel or "" == defaultModel
		defaultModel = @ConVars.PlayerModel\GetDefault!

	return defaultModel

local logger
logger = {
	__log: (...) ->
		MsgC Color( 255, 69, 0 ), "[Among Us] ",
			CLIENT and Color(227, 220, 110) or Color(151, 218, 229),
			CLIENT and "[Client] " or "[Server] ",
			...
		MsgN!

	Info: (...) ->
		logger.__log Color(220, 220, 220), "[Info] ", Color(255, 255, 255), ...

	Warn: (...) ->
		logger.__log Color(255, 255, 0), "[Warn] ", Color(255, 255, 160), ...

	Error: (...) ->
		logger.__log Color(255, 0, 0), "[Err!] ", Color(255, 80, 80), ...
}

GM.Logger = logger
