--- All things player.
-- Handles everything related to players, from hiding to killing and venting.
-- @module sv_player

--- Hides or unhides the player in question.
-- This does in fact HIDE the player, preventing the server from
-- transmitting his data to others completely.
-- @param ply Player entity.
-- @param hide Should we hide?
GM.Player_Hide = (ply, hide = true) =>
	for otherPly in *player.GetAll!
		if otherPly ~= ply
			ply\SetPreventTransmit otherPly, hide

--- Unhides the player.
-- A small wrapper for my, as well as your, convenience.
-- @param ply Player entity.
GM.Player_Unhide = (ply) =>
	@Player_Hide ply, false

--- Unhides everyone.
-- A small wrapper for my, as well as your, convenience.
GM.Player_UnhideEveryone = =>
	for ply in *player.GetAll!
		@Player_Unhide ply

--- Sets the player as dead.
-- @param playerTable Player table.
GM.Player_SetDead = (playerTable) =>
	if "Player" == type playerTable
		playerTable = playerTable\GetAUPlayerTable!
	return unless playerTable

	if IsValid playerTable.entity
		color = playerTable.entity\GetColor!
		color.a = 90
		playerTable.entity\SetColor color
		playerTable.entity\SetRenderMode RENDERMODE_TRANSCOLOR

		-- Hide the player for alive players.
		-- Unhide the player for dead players, and the other way around.
		for otherPlayerTable in *@GameData.PlayerTables
			continue if otherPlayerTable == playerTable or not IsValid(otherPlayerTable.entity)

			if @GameData.DeadPlayers[otherPlayerTable]
				playerTable.entity\SetPreventTransmit otherPlayerTable.entity, false
				otherPlayerTable.entity\SetPreventTransmit playerTable.entity, false
			else
				playerTable.entity\SetPreventTransmit otherPlayerTable.entity, true

	@GameData.DeadPlayers[playerTable] = true

--- Attempts to get the person killed.
-- If instead you just want to mark the player as dead,
-- use GAMEMODE\Player_SetDead instead.
-- @param victimTable Victim player table.
-- @param attackerTable Attacker player table.
GM.Player_Kill = (victimTable, attackerTable) =>
	if "Player" == type victimTable
		victimTable = victimTable\GetAUPlayerTable!
	return unless victimTable

	if "Player" == type attackerTable
		attackerTable = attackerTable\GetAUPlayerTable!
	return unless attackerTable

	-- Bail if one of the players is invalid. The game mode will handle the killing internally.
	return unless (IsValid(victimTable.entity) and IsValid(victimTable.entity))

	-- Bail if not in the PVS.
	return unless victimTable.entity\TestPVS(attackerTable.entity) and
		attackerTable.entity\TestPVS(victimTable.entity)

	-- Bail if one of the players is dead.
	return if @GameData.DeadPlayers[attackerTable] or @GameData.DeadPlayers[victimTable]

	-- Bail if the attacker is not an imposter, or if the target is an imposter.
	return unless @GameData.Imposters[attackerTable] or @GameData.Imposters[victimTable]

	-- Bail if player has a cooldown.
	return if @GameData.KillCooldowns[attackerTable] > CurTime!

	-- Bail if the kill cooldown is paused
	return if @GameData.KillCooldownRemainders[attackerTable]

	-- Bail if the attacker is too far.
	-- A fairly sophisticated check.
	radius = (@BaseUseRadius * @ConVarSnapshots.KillDistanceMod\GetFloat!)
	return if radius * radius <
		(victimTable.entity\NearestPoint attackerTable.entity\GetPos!)\DistToSqr(
			attackerTable.entity\NearestPoint victimTable.entity\GetPos!)

	with corpse = ents.Create "prop_ragdoll"
		\SetPos victimTable.entity\GetPos!
		\SetAngles victimTable.entity\GetAngles!
		\SetModel "models/amongus/player/corpse.mdl"
		\SetCollisionGroup COLLISION_GROUP_DEBRIS_TRIGGER
		\SetUseType SIMPLE_USE

		-- Garbage-tier workaround because NW vars are not accessible in OnEntityCreated.
		\SetDTInt 15, victimTable.id

		\Spawn!
		\Activate!
		\PhysWake!

		if IsValid attackerTable.entity
			phys = \GetPhysicsObject!

			if IsValid phys
				phys\SetVelocity (victimTable.entity\GetPos! - attackerTable.entity\GetPos!)\GetNormalized! * 250

			attackerTable.entity\SetPos victimTable.entity\GetPos!

	@Player_SetDead victimTable
	@Net_KillNotify attackerTable
	@Player_RefreshKillCooldown attackerTable

	@Net_SendNotifyKilled victimTable, attackerTable
	@Player_CloseVGUI victimTable
	@Net_BroadcastDeadToGhosts!

	@Game_CheckWin!

--- Bumps the kill cooldown of a player.
-- @param playerTable Player table.
GM.Player_RefreshKillCooldown = (playerTable) =>
	if "Player" == type playerTable
		playerTable = playerTable\GetAUPlayerTable!
	return unless playerTable

	cd = CurTime! + @ConVarSnapshots.KillCooldown\GetFloat!
	@GameData.KillCooldowns[playerTable] = cd

	if IsValid playerTable.entity
		@Net_UpdateKillCooldown playerTable, cd

--- Pauses the kill cooldown of a player.
-- @param playerTable Player table.
GM.Player_PauseKillCooldown = (playerTable, pause = true) =>
	if "Player" == type playerTable
		playerTable = playerTable\GetAUPlayerTable!
	return unless playerTable

	if @GameData.KillCooldowns[playerTable]
		if pause
			remainder = math.max 0, @GameData.KillCooldowns[playerTable] - CurTime!

			@GameData.KillCooldownRemainders[playerTable] = remainder
			@Net_PauseKillCooldown playerTable, remainder

		else
			newCooldown = CurTime! + (@GameData.KillCooldownRemainders[playerTable] or 0)

			@GameData.KillCooldowns[playerTable] = newCooldown
			@GameData.KillCooldownRemainders[playerTable] = nil
			@Net_UpdateKillCooldown playerTable, newCooldown

--- Pauses the kill cooldown of a player.
-- Convenience wrapper.
-- @param playerTable Player table.
GM.Player_UnPauseKillCooldown = (playerTable) =>
	if "Player" == type playerTable
		playerTable = playerTable\GetAUPlayerTable!
	return unless playerTable

	@Player_PauseKillCooldown playerTable, false

--- Helper function that packs all known vent links into a table of strings.
-- @param vent Vent entity.
packVentLinks = (vent) ->
	links = {}
	if vent.Links and #vent.Links > 0
		for link in *vent.Links
			table.insert links, link\GetName! or "N/A"

	return links

--- Teleports an already vented person to a different vent.
-- @param playerTable Player table.
-- @param targetVentId Target vent ID. Must a string. Vent IDs are currently defined in Hammer per-vent.
GM.Player_VentTo = (playerTable, targetVentId) =>
	if "Player" == type playerTable
		playerTable = playerTable\GetAUPlayerTable!
	return unless playerTable

	vent = @GameData.Vented[playerTable]

	if vent and vent.Links and @GameData.Imposters[playerTable] and IsValid(vent.Links[targetVentId]) and (@GameData.VentCooldown[playerTable] or 0) <= CurTime!
		targetVent = vent.Links[targetVentId]
		@GameData.Vented[playerTable] = targetVent

		if IsValid playerTable.entity
			@Net_NotifyVent playerTable, @VentNotifyReason.Move, packVentLinks targetVent

		@GameData.VentCooldown[playerTable] = CurTime! + 0.25

		if IsValid playerTable.entity
			playerTable.entity\SetPos targetVent\GetPos!
			if targetVent.ViewAngle
				playerTable.entity\SetEyeAngles targetVent.ViewAngle

--- Puts a non-vented person into a vent.
-- @param playerTable Player table.
-- @param vent Vent entity.
GM.Player_Vent = (playerTable, vent) =>
	if "Player" == type playerTable
		playerTable = playerTable\GetAUPlayerTable!
	return unless playerTable

	if not @GameData.DeadPlayers[playerTable] and @GameData.Imposters[playerTable] and not @GameData.Vented[playerTable]
		if IsValid playerTable.entity
			@Net_NotifyVent playerTable, @VentNotifyReason.Vent, packVentLinks vent

		@GameData.Vented[playerTable] = vent
		@GameData.VentCooldown[playerTable] = CurTime! + 0.75

		handle = "vent" .. playerTable.nickname

		if IsValid playerTable.entity
			playerTable.entity\SetPos vent\GetPos!
			if vent.ViewAngle
				playerTable.entity\SetEyeAngles vent.ViewAngle

			@Net_BroadcastVent playerTable.entity, vent\GetPos!
			@Player_Hide playerTable.entity
			@Player_PauseKillCooldown playerTable

			vent\TriggerOutput "OnVentIn", playerTable.entity

		-- @Sabotage_PauseAll!
		timer.Create handle, 0.125, 1, ->
			if IsValid playerTable.entity
				playerTable.entity\SetPos vent\GetPos!
				if vent.ViewAngle
					playerTable.entity\SetEyeAngles vent.ViewAngle

--- Unvents a vented person.
-- You don't have to check.
-- @param playerTable Player table.
GM.Player_UnVent = (playerTable, instant) =>
	if "Player" == type playerTable
		playerTable = playerTable\GetAUPlayerTable!
	return unless playerTable

	if vent = @GameData.Vented[playerTable]
		@Player_UnPauseKillCooldown playerTable
		@GameData.VentCooldown[playerTable] = CurTime! + 1.5

		if IsValid playerTable.entity
			@Net_NotifyVent playerTable, @VentNotifyReason.UnVent

		outPoint = Vector(0, 0, 1) + vent\NearestPoint vent\GetPos! + Vector 0, 0, 1024
		playerTable.entity\SetPos outPoint

		handle = "vent" .. playerTable.nickname
		@Net_BroadcastVent playerTable.entity, vent\GetPos!, true

		vent\TriggerOutput "OnVentOut", playerTable.entity

		timer.Create handle, 0.5, 1, ->
			@GameData.Vented[playerTable] = nil
			-- if 0 == table.Count @GameData.Vented
			--	@Sabotage_UnPauseAll!

			if IsValid playerTable.entity
				@Player_Unhide playerTable.entity

--- Closes the current VGUI if the player has any opened.
-- @param playerTable Player table.
GM.Player_CloseVGUI = (playerTable) =>
	if "Player" == type playerTable
		playerTable = playerTable\GetAUPlayerTable!
	return unless playerTable

	currentVGUI = @GameData.CurrentVGUI[playerTable]

	if currentVGUI
		@GameData.CurrentVGUI[playerTable] = nil
		@Player_UnPauseKillCooldown playerTable
		@Net_SendCloseVGUI playerTable

		if @GameData.VGUICallback[playerTable]
			@GameData.VGUICallback[playerTable]!

--- This function returns whether the player can open a new VGUI.
-- @param playerTable Player table.
GM.Player_CanOpenVGUI = (playerTable) =>
	if "Player" == type playerTable
		playerTable = playerTable\GetAUPlayerTable!
	return unless playerTable

	-- Bail if the player is in a vent.
	return false if @GameData.Vented[playerTable]

	-- Bail if there's already a screen.
	return false if @GameData.CurrentVGUI[playerTable]

	return true

--- Opens a VGUI for a player.
-- This is the primary function that allows the game mode to keep track of
-- people with opened VGUIs, such as tasks, sabotages, security cams or
-- practically anything else. This also pauses the kill timer.
--
-- This function returns whether the GUI has been opened.
-- If the player is already staring at a VGUI, or if he's vented,
-- or if his cooldown is paused by something, this will return false.
--
-- @param playerTable Player table.
-- @param vgui Identifier. Virtually anything. Preferably string.
-- @param data Extra data to pass to the client.
-- @param callback Optional callback to call when the GUI is closed.
GM.Player_OpenVGUI = (playerTable, vgui, data = {}, callback) =>
	if "Player" == type playerTable
		playerTable = playerTable\GetAUPlayerTable!
	return unless playerTable

	return false unless @Player_CanOpenVGUI playerTable

	@GameData.CurrentVGUI[playerTable] = vgui
	@Player_PauseKillCooldown playerTable

	@GameData.VGUICallback[playerTable] = callback
	@Net_OpenVGUI playerTable, data

	return true

--- Closes the current VGUI for everybody.
GM.Player_CloseVGUIsForEveryone = =>
	for playerTable in *@GameData.PlayerTables
		@Player_CloseVGUI playerTable

	@Net_BroadcastCloseVGUI!

GM.PlayerSpawn = (ply) =>
	defaultModel = @GetDefaultPlayerModel!

	if nil == hook.Call "PlayerSetModel", @, ply
		ply\SetModel defaultModel

	with defaultSpeed = 200
		ply\SetSlowWalkSpeed defaultSpeed
		ply\SetWalkSpeed defaultSpeed
		ply\SetRunSpeed  defaultSpeed
		ply\SetMaxSpeed  defaultSpeed

	ply\SetViewOffset Vector 0, 0, 64 - 16
	ply\SetTeam 1
	ply\SetNoCollideWithTeammates true


hook.Add "PlayerInitialSpawn", "NMW AU AutoPilot", (ply) -> with GAMEMODE
	oldAutoPilot = \IsOnAutoPilot!

	ply\SetNWBool("NMW AU Host", true) if ply\IsListenServerHost!

	if oldAutoPilot
		newAutoPilot = true
		for ply in *player.GetAll!
			if ply\IsAdmin! or ply\IsListenServerHost!
				newAutoPilot = false
				break

		if not newAutoPilot and oldAutoPilot
			-- to-do: pront this in the chat
			if not .ConVars.ForceAutoWarmup\GetBool!
				.Logger.Info "An admin (#{ply\Nick!}) has just connected"
				.Logger.Info "Upcoming rounds will now be managed manually"

			\SetOnAutoPilot newAutoPilot

	return

hook.Add "PlayerDisconnected", "NMW AU AutoPilot", (ply) -> with GAMEMODE
	GAMEMODE\Net_BroadcastConnectDisconnect ply\Nick!, false

	oldAutoPilot = \IsOnAutoPilot!
	if oldAutoPilot
		newAutoPilot = false
		for ply in *player.GetAll!
			if ply\IsAdmin! or ply\IsListenServerHost!
				newAutoPilot = true
				break

		if newAutoPilot and not oldAutoPilot
			-- to-do: pront this in the chat
			if not .ConVars.ForceAutoWarmup\GetBool!
				.Logger.Info "The last admin (#{ply\Nick!}) has just left"
				.Logger.Info "Upcoming rounds will now be managed by the server"

			\SetOnAutoPilot newAutoPilot

	return

hook.Add "CanPlayerSuicide", "NMW AU Suicide", -> false

hook.Add "EntityTakeDamage", "NMW AU Damage", (target, dmg) ->
	dmg\ScaleDamage 0

hook.Add "FindUseEntity", "NMW AU FindUse", (ply, default) ->
	usable = GAMEMODE\TracePlayer ply, GAMEMODE.TracePlayerFilter.Usable

	return IsValid(usable) and usable or false

hook.Add "KeyPress", "NMW AU KeyPress", (ply, key) ->
	-- Handle unvent requests.
	if key == IN_USE
		@ = GAMEMODE
		playerTable = @GameData.Lookup_PlayerByEntity[ply]
		if @GameData.Imposters[playerTable] and @GameData.Vented[playerTable] and (@GameData.VentCooldown[playerTable] or 0) <= CurTime!
			@Player_UnVent playerTable

	-- Handle body reports.
	if key == IN_RELOAD
		playerTable = ply\GetAUPlayerTable!
		return unless playerTable and GAMEMODE\IsGameInProgress!

		body = GAMEMODE\TracePlayer ply, GAMEMODE.TracePlayerFilter.Reportable
		return unless IsValid body

		if victimTable = GAMEMODE\GetPlayerTableFromCorpse body
			GAMEMODE\Meeting_Start playerTable, victimTable.color

	return

hook.Add "PlayerSpray", "NMW AU DeadSpray", (ply) ->
	return if GAMEMODE.ConVarSnapshots.DeadChat\GetBool! or not GAMEMODE\IsGameInProgress!

	playerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[ply]

	return not (playerTable and not GAMEMODE.GameData.DeadPlayers[playerTable])

shutYourUp = (listener, talker) ->
	-- Console message...?
	return unless IsValid(listener) and IsValid(talker)

	-- No talking during game, unless it's a meeting.
	if not GAMEMODE.ConVarSnapshots.GameChat\GetBool! and GAMEMODE\IsGameInProgress! and not GAMEMODE\IsMeetingInProgress!
		playerTable = talker\GetAUPlayerTable!

		return false if playerTable and not talker\IsDead!

	-- If talker is dead, only display the message to other dead players.
	return false if not GAMEMODE.ConVarSnapshots.DeadChat\GetBool! and
		(talker\IsDead! and not listener\IsDead!)

hook.Add "PlayerCanHearPlayersVoice", "NMW AU DeadChat", shutYourUp
hook.Add "PlayerCanSeePlayersChat", "NMW AU DeadChat", (_, _, a, b) -> shutYourUp a, b

hook.Add "PlayerSay", "NMW AU DeadChat", (ply) ->
	-- Suppress and notify if the player is trying to talk during the game.
	if not GAMEMODE.ConVarSnapshots.GameChat\GetBool! and GAMEMODE\IsGameInProgress! and not GAMEMODE\IsMeetingInProgress!
		playerTable = ply\GetAUPlayerTable!

		if playerTable and not ply\IsDead!
			GAMEMODE\Net_SendGameChatError playerTable
			return ""

	return

hook.Add "IsSpawnpointSuitable", "NMW AU SpawnSuitable", -> true

hook.Add "ShowHelp", "NMW AU ShowHelp", (ply) -> GAMEMODE\Net_SendShowHelp ply
