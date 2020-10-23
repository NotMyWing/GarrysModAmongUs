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
		@Player_Hide playerTable.entity

		color = playerTable.entity\GetColor!
		color.a = 32
		playerTable.entity\SetColor color
		playerTable.entity\SetRenderMode RENDERMODE_TRANSCOLOR

	@GameData.DeadPlayers[playerTable] = true

--- Attempts to get the person killed.
-- If instead you just want to mark the player as dead,
-- use GAMEMODE\Player_SetDead instead.
-- @param victimTable Victim player table.
-- @param attackerTable Attacker player table.
GM.Player_Kill = (victimTable, attackerTable) =>
	-- ho boy
	if not ((@GameData.DeadPlayers[attackerTable]) or (@GameData.DeadPlayers[victimTable])) and
		(@GameData.Imposters[attackerTable] and not @GameData.Imposters[victimTable]) and
		(@GameData.KillCooldowns[attackerTable] >= CurTime!) or
		(@GameData.KillCooldownRemainders[attackerTable])
			return

	if attackerTable
		@Player_RefreshKillCooldown attackerTable

	if IsValid victimTable.entity
		@Player_CloseTask victimTable
		@Net_SendTaskClose victimTable

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
	if IsValid attackerTable.entity
		@Net_KillNotify attackerTable

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
		remainder = if pause
			CurTime! - @GameData.KillCooldowns[playerTable]

		if remainder
			@GameData.KillCooldownRemainders[playerTable] = remainder
		else
			@GameData.KillCooldowns[playerTable] = CurTime! + @GameData.KillCooldownPauses[playerTable]
			@GameData.KillCooldownRemainders[playerTable] = nil

		if IsValid playerTable.entity
			@Net_PauseKillCooldown playerTable, pause, remainder

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
			playerTable.entity\SetEyeAngles vent.ViewAngle

			@Net_BroadcastVent playerTable.entity, vent\GetPos!
			@Player_Hide playerTable.entity

		timer.Create handle, 0.125, 1, ->
			if IsValid playerTable.entity
				playerTable.entity\SetPos vent\GetPos!
				if vent.ViewAngle
					playerTable.entity\SetEyeAngles vent.ViewAngle

--- Unvents a vented person.
-- You don't have to check.
-- @param playerTable Player table.
GM.Player_UnVent = (playerTable) =>
	if vent = @GameData.Vented[playerTable]
		@GameData.VentCooldown[playerTable] = CurTime! + 1.5

		if IsValid playerTable.entity
			@Net_NotifyVent playerTable, @VentNotifyReason.UnVent

		playerTable.entity\SetPos vent\GetPos!

		handle = "vent" .. playerTable.nickname
		@Net_BroadcastVent playerTable.entity, vent\GetPos!, true
		timer.Create handle, 0.5, 1, ->
			@GameData.Vented[playerTable] = nil
			if IsValid playerTable.entity
				@Player_Unhide playerTable.entity
				playerTable.entity\SetPos vent\GetPos! + Vector 0, 0, 5

--- Forces the player into doing the task.
-- This will fail if the player is too far from the activation button.
-- This will also fail if the player isn't tasked with the provided task.
-- This will also fail if the button did not consent.
-- Yes.
-- @table playerTable The tasked crewmate.
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

		if IsValid playerTable.entity
			@Net_OpenTaskVGUI playerTable, name

--- Closes the current task for the player.
-- @table playerTable The tasked crewmate.
GM.Player_CloseTask = (playerTable) =>
	if @GameData.CurrentTask[playerTable]
		@GameData.CurrentTask[playerTable] = nil

--- Submits the current task. This function will fail
-- if the player isn't actually doing any tasks at this moment,
-- or if the current task doesn't math the provided one.
-- @table playerTable The tasked crewmate.
-- @string name Name of the task.
GM.Player_SubmitTask = (playerTable, name) =>
	task = (@GameData.Tasks[playerTable] or {})[name]

	if task and (@GameData.CurrentTask[playerTable] == task)
		if IsValid playerTable.entity
			ent = task\GetActivationButton!

			if not playerTable.entity\TestPVS ent
				return

		task\Advance!

		if task\IsCompleted!
			@CheckWin!

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

hook.Add "PlayerDisconnected", "NMW AU CheckWin", ->
	if GAMEMODE.GameData.PlayerTables
		GAMEMODE\CheckWin!

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
