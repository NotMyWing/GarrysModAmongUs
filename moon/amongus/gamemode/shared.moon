AddCSLuaFile()

GM.Name 		= "Among Us"
GM.Author 		= "NotMyWing with assets by InnerSloth"
GM.Email 		= ""
GM.Website 		= ""

GM.GameStates =
	LOBBY: 1
	PLAYING: 2
	MEETING: 3

flags = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
GM.ConVars = 
	ImposterCount: CreateConVar "au_imposter_count", 1, flags, "", 1, 4
	KillCooldown: CreateConVar "au_kill_cooldown", 5, flags, "", 1, 60
	VotePreTime: CreateConVar "au_vote_pre_time", 5, flags, "", 1, 60
	VoteTime: CreateConVar "au_vote_time", 5, flags, "", 1, 60
	VotePostTime: CreateConVar "au_vote_post_time", 5, flags, "", 1, 60
	MeetingCooldown: CreateConVar "au_meeting_cooldown", 10, flags, "", 1, 60
	MeetingsPerPlayer: CreateConVar "au_meeting_available", 2, flags, "", 1, 5
	ConfirmEjects: CreateConVar "au_vote_confirm_ejects", 1, flags, "", 0, 1

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
	SetDead: 4
	KillCooldown: 5
	GameState: 6
	GameOver: 7
	Meeting: 8
	OpenDiscuss: 9
	Eject: 10
	Vote: 11
	VoteEnd: 12
	NotifyVent: 13
	VentAnim: 14
	VentRequest: 15
	RequestUpdate: 16
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

GM.Move = (ply, mvd) =>
	if mvd\KeyDown IN_DUCK
		mvd\SetButtons bit.band mvd\GetButtons!, bit.bnot IN_DUCK

	if mvd\KeyDown IN_JUMP
		mvd\SetButtons bit.band mvd\GetButtons!, bit.bnot IN_JUMP

	if mvd\KeyDown IN_SPEED
		mvd\SetButtons bit.band mvd\GetButtons!, bit.bnot IN_SPEED

	if mvd\KeyDown IN_WALK
		mvd\SetButtons bit.band mvd\GetButtons!, bit.bnot IN_WALK

	if @GameData.ActivePlayersMap
		playerTable = @GameData.ActivePlayersMap[ply]

		if (CLIENT and @GameData.Vented) or (SERVER and @GameData.Vented[playerTable])
			mvd\SetVelocity Vector 0, 0, 0
			return true

GM.SplashScreenTime = 8

GM.GetAlivePlayers = =>
	players = {}

	if @GameData.ActivePlayers and @GameData.DeadPlayers
		for _, v in ipairs @GameData.ActivePlayers
			disconnected = not IsValid v.entity
			if not disconnected and not @GameData.DeadPlayers[v]
				table.insert players, v

	return players

whitelist = {
	"func_button": true
	"func_door": true
	"func_door_rotating": true
	"func_meeting_button": true
	"player": true
	"prop_ragdoll": true
	"prop_physics": true
	"func_vent": true
}

export distSort_memo = {}
export distSort_player = nil
export distSort = (a, b) ->
	distSort_memo[a] or= (a\GetPos! - distSort_player\GetPos!)\Length!
	distSort_memo[b] or= (b\GetPos! - distSort_player\GetPos!)\Length!

	return distSort_memo[a] > distSort_memo[b]

GM.TracePlayer = (ply) =>
	size = 60
	dir = ply\GetAimVector!
	angle = math.cos math.rad 45 
	startPos = ply\GetPos! + Vector 0, 0, 20

	entities = ents.FindInCone startPos, dir, size, angle
	
	usable = {}
	killable = {}

	lply = GAMEMODE.GameData.ActivePlayersMap and GAMEMODE.GameData.ActivePlayersMap[ply]
	if not lply or (SERVER and @GameData.Vented[lply]) or (CLIENT and @GameData.Vented)
		return

	for _, ent in ipairs entities
		if SERVER and not ply\TestPVS ent
			continue
	
		if whitelist[ent\GetClass!]
			aply = GAMEMODE.GameData.ActivePlayersMap and GAMEMODE.GameData.ActivePlayersMap[ent]

			isKillable = aply and ent\IsPlayer! and GAMEMODE.GameData.Imposters[lply] and 
				not GAMEMODE.GameData.Imposters[aply] and not GAMEMODE.GameData.DeadPlayers[aply]

			isUsable = not isKillable and not ent\IsPlayer!
			if isKillable
				table.insert killable, ent
			if isUsable
				table.insert usable, ent

	distSort_memo = {}
	distSort_player = ply
	table.sort usable, distSort
	table.sort killable, distSort

	return killable[#killable], usable[#usable]

hook.Add "PlayerFootstep", "NMW AU Footsteps", (ply) ->
	aply = GAMEMODE.GameData.ActivePlayersMap[ply]
	if GAMEMODE.GameData.DeadPlayers and GAMEMODE.GameData.DeadPlayers[aply] 
		return true

GM.PlayerSwitchWeapon = (ply, oldWeapon, newWeapon) =>
	return true

GM.IsGameInProgress = => GetGlobalBool "NMW AU GameInProgress"