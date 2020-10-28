--- All things player.
-- Handles everything related to players, from hiding to killing and venting.
-- @module sv_player

--- Hides or unhides the player in question.
-- This does in fact HIDE the player, preventing the server from
-- transmitting his data to others completely.
-- @param ply Player entity.
-- @param hide Should we hide?
GM.Player_Hide = (ply, hide = true) =>
	for _, otherPly in ipairs player.GetAll!
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
	for _, ply in ipairs player.GetAll!
		@Player_Unhide ply

--- Sets the player as dead.
-- @param playerTable Player table.
GM.Player_SetDead = (playerTable) =>
	if IsValid playerTable.entity
		color = playerTable.entity\GetColor!
		color.a = 32
		playerTable.entity\SetColor color
		playerTable.entity\SetRenderMode RENDERMODE_TRANSCOLOR

		-- Hide the player for alive players.
		-- Unhide the player for dead players, and the other way around.
		for _, otherPlayerTable in pairs @GameData.PlayerTables
			if otherPlayerTable == playerTable or not IsValid(otherPlayerTable.entity)
				continue

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
	-- Bail if one of the players is invalid. The game mode will handle the killing internally.
	if not (IsValid(victimTable.entity) and IsValid(victimTable.entity))
		return

	-- Bail if one of the players is dead.
	if @GameData.DeadPlayers[attackerTable] or @GameData.DeadPlayers[victimTable]
		return

	-- Bail if the attacker is not an imposter, or if the target is an imposter.
	if not @GameData.Imposters[attackerTable] or @GameData.Imposters[victimTable]
		return

	-- Bail if player has a cooldown.
	if @GameData.KillCooldowns[attackerTable] > CurTime!
		return

	-- Bail if the kill cooldown is paused
	if @GameData.KillCooldownRemainders[attackerTable]
		return

	-- Bail if the attacker is too far.
	if (@BaseUseRadius * @ConVars.KillDistanceMod\GetFloat!) <
		victimTable.entity\GetPos!\Distance attackerTable.entity\GetPos!
		return

	with corpse = ents.Create "prop_ragdoll"
		\SetPos victimTable.entity\GetPos!
		\SetAngles victimTable.entity\GetAngles!
		\SetModel victimTable.entity\GetModel!
		\SetColor victimTable.entity\GetColor!
		\SetCollisionGroup COLLISION_GROUP_DEBRIS_TRIGGER
		\SetNW2Int "NMW AU PlayerID", victimTable.id
		\SetUseType SIMPLE_USE
		\Spawn!
		\Activate!
		\PhysWake!
		if bone = \TranslatePhysBoneToBone 5
			\ManipulateBoneScale bone, Vector 0, 0, 0

		if IsValid attackerTable.entity
			if phys = \GetPhysicsObject!
				phys\SetVelocity (victimTable.entity\GetPos! - attackerTable.entity\GetPos!)\GetNormalized! * 250

			attackerTable.entity\SetPos victimTable.entity\GetPos!

	@Player_SetDead victimTable
	@Net_KillNotify attackerTable
	@Player_RefreshKillCooldown attackerTable

	@Net_SendNotifyKilled victimTable, attackerTable
	@Player_CloseTask victimTable
	@Net_SendTaskClose victimTable

	@CheckWin!

--- Bumps the kill cooldown of a player.
-- @param playerTable Player table.
GM.Player_RefreshKillCooldown = (playerTable) =>
	cd = CurTime! + @ConVars.KillCooldown\GetFloat!
	@GameData.KillCooldowns[playerTable] = cd

	if IsValid playerTable.entity
		@Net_UpdateKillCooldown playerTable, cd

--- Pauses the kill cooldown of a player.
-- @param playerTable Player table.
GM.Player_PauseKillCooldown = (playerTable, pause = true) =>
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
	@Player_PauseKillCooldown playerTable, false

--- Helper function that packs all known vent links into a table of strings.
-- @param vent Vent entity.
packVentLinks = (vent) ->
	links = {}
	if vent.Links and #vent.Links > 0
		for _, link in ipairs vent.Links
			table.insert links, link\GetName! or "N/A"

	return links

--- Teleports an already vented person to a different vent.
-- @param playerTable Player table.
-- @param targetVentId Target vent ID. Must a string. Vent IDs are currently defined in Hammer per-vent.
GM.Player_VentTo = (playerTable, targetVentId) =>
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

		timer.Create handle, 0.125, 1, ->
			if IsValid playerTable.entity
				playerTable.entity\SetPos vent\GetPos!
				if vent.ViewAngle
					playerTable.entity\SetEyeAngles vent.ViewAngle

--- Unvents a vented person.
-- You don't have to check.
-- @param playerTable Player table.
GM.Player_UnVent = (playerTable, instant) =>
	if vent = @GameData.Vented[playerTable]
		@Player_UnPauseKillCooldown playerTable
		@GameData.VentCooldown[playerTable] = CurTime! + 1.5

		if IsValid playerTable.entity
			@Net_NotifyVent playerTable, @VentNotifyReason.UnVent

		outPoint = Vector(0, 0, 1) + vent\NearestPoint vent\GetPos! + Vector 0, 0, 1024
		playerTable.entity\SetPos outPoint

		handle = "vent" .. playerTable.nickname
		@Net_BroadcastVent playerTable.entity, vent\GetPos!, true
		timer.Create handle, 0.5, 1, ->
			@GameData.Vented[playerTable] = nil
			if IsValid playerTable.entity
				@Player_Unhide playerTable.entity

--- Forces the player into doing the task.
-- This will fail if the player is too far from the activation button.
-- This will also fail if the player isn't tasked with the provided task.
-- This will also fail if the button did not consent.
-- Yes.
-- @param playerTable The tasked crewmate.
-- @string name Name of the task.
GM.Player_StartTask = (playerTable, name) =>
	task = (@GameData.Tasks[playerTable] or {})[name]

	if task and not @GameData.CurrentTask[playerTable]
		ent = task\GetActivationButton!

		if playerTable.entity\GetPos!\Distance(ent\GetPos!) > 128
			return

		if not task\Use!
			return

		@GameData.CurrentTask[playerTable] = task
		task\UseVisual!

		if IsValid playerTable.entity
			@Net_OpenTaskVGUI playerTable, name

--- Closes the current task for the player.
-- @param playerTable The tasked crewmate.
GM.Player_CloseTask = (playerTable) =>
	currentTask = @GameData.CurrentTask[playerTable]

	if currentTask
		currentTask\CancelVisual!

		@GameData.CurrentTask[playerTable] = nil

--- Submits the current task. This function will fail
-- if the player isn't actually doing any tasks at this moment,
-- or if the current task doesn't math the provided one.
-- @param playerTable The tasked crewmate.
-- @string name Name of the task.
GM.Player_SubmitTask = (playerTable, name) =>
	task = (@GameData.Tasks[playerTable] or {})[name]

	if task and (@GameData.CurrentTask[playerTable] == task)
		if IsValid playerTable.entity
			ent = task\GetActivationButton!

			if not playerTable.entity\TestPVS ent
				return

		btn = task\GetActivationButton!
		task\Advance!

		if task\IsCompleted!
			task\CompleteVisual!
			@CheckWin!
		else
			task\AdvanceVisual btn

--- Closes the current task for everybody.
GM.Player_CloseTasksForEveryone = =>
	for _, playerTable in pairs @GameData.PlayerTables
		@Player_CloseTask playerTable

	@Net_BroadcastTaskClose!

GM.PlayerSpawn = (ply) =>
	ply\SetModel "models/kaesar/amongus/amongus.mdl"
	with defaultSpeed = 200
		ply\SetSlowWalkSpeed defaultSpeed
		ply\SetWalkSpeed defaultSpeed
		ply\SetRunSpeed  defaultSpeed
		ply\SetMaxSpeed  defaultSpeed

	ply\SetTeam 1
	ply\SetNoCollideWithTeammates true

hook.Add "PlayerDisconnected", "NMW AU CheckWin", (ply) -> with GAMEMODE
	if \IsGameInProgress!
		if playerTable = .GameData.Lookup_PlayerByEntity[ply]
			\Player_SetDead playerTable

			-- If the player was a crewmate and he had tasks,
			-- "complete" his tasks and broadcast the new count.
			if not .GameData.Imposters[playerTable]
				count = table.Count .GameData.Tasks[playerTable]
				if count > 0
					.GameData.CompletedTasks += table.Count .GameData.Tasks[playerTable]
					table.Empty .GameData.Tasks[playerTable]

					\Net_BroadcastTaskCount .GameData.CompletedTasks

			\CheckWin!

hook.Add "CanPlayerSuicide", "NMW AU Suicide", ->
	return false

hook.Add "EntityTakeDamage", "NMW AU Damage", (target, dmg) ->
	dmg\ScaleDamage 0

-- Handle body reports.
hook.Add "PlayerUse", "NMW AU Use", (activator, ent) ->
	aply = GAMEMODE.GameData.Lookup_PlayerByEntity[activator]
	if aply and GAMEMODE\IsGameInProgress!
		bodyid = ent\GetNW2Int "NMW AU PlayerID"
		victim = GAMEMODE.GameData.Lookup_PlayerByID[bodyid]
		if victim
			GAMEMODE\Meeting_Start activator, victim.color

hook.Add "FindUseEntity", "NMW AU FindUse", (ply, default) ->
	_, usable = GAMEMODE\TracePlayer ply

	return usable or false

-- Handle unvent requests.
hook.Add "KeyPress", "NMW AU UnVent", (ply, key) ->
	if key == IN_USE
		@ = GAMEMODE
		playerTable = @GameData.Lookup_PlayerByEntity[ply]
		if @GameData.Imposters[playerTable] and @GameData.Vented[playerTable] and (@GameData.VentCooldown[playerTable] or 0) <= CurTime!
			@Player_UnVent playerTable
