
GM.Player_Hide = (ply, hide = true) =>
	for _, otherPly in ipairs player.GetAll!
		if otherPly ~= ply
			ply\SetPreventTransmit otherPly, hide

GM.Player_Unhide = (ply) =>
	@Player_Hide ply, false

GM.Player_UnhideEveryone = =>
	for _, ply in ipairs player.GetAll!
		@Player_Unhide ply

GM.Player_SetDead = (playerTable) =>
	if IsValid playerTable.entity
		@Player_Hide playerTable.entity

		color = playerTable.entity\GetColor!
		color.a = 32
		playerTable.entity\SetColor color
		playerTable.entity\SetRenderMode RENDERMODE_TRANSCOLOR

	@GameData.DeadPlayers[playerTable] = true

GM.Player_Kill = (victimTable, attackerTable, silent) =>
	if attackerTable
		if not ((@GameData.DeadPlayers[attackerTable]) or (@GameData.DeadPlayers[victimTable])) or
			(@GameData.Imposters[attackerTable]) or (@GameData.Imposters[victimTable]) or
			(@GameData.KillCooldowns[attackerTable] >= CurTime!) or
			(@GameData.KillCooldownRemainders[attackerTable])
				return

	if not @GameData.DeadPlayers[victimTable]
		if attackerTable
			@Player_UpdateKillCooldown attackerTable

		if not silent
			if IsValid victimTable.entity
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

					if attackerTable and IsValid attackerTable.entity
						if phys = \GetPhysicsObject!
							phys\SetVelocity (victimTable.entity\GetPos! - attackerTable.entity\GetPos!)\GetNormalized! * 250

						attackerTable.entity\SetPos victimTable.entity\GetPos!

		@Player_SetDead victimTable
		if attackerTable and IsValid attackerTable.entity
			@Net_KillNotify attackerTable

		if not silent
			@CheckWin!

GM.Player_UpdateKillCooldown = (playerTable) =>
	cd = CurTime! + @ConVars.KillCooldown\GetFloat!
	@GameData.KillCooldowns[playerTable] = cd

	if IsValid playerTable.entity
		@Net_UpdateKillCooldown playerTable, cd

GM.Player_PauseKillCooldown = (ply, pause = true) =>
	if @GameData.KillCooldowns[ply]
		remainder = if pause
			CurTime! - @GameData.KillCooldowns[ply]

		if remainder
			@GameData.KillCooldownRemainders[ply] = remainder
		else
			@GameData.KillCooldowns[ply] = CurTime! + @GameData.KillCooldownPauses[ply]
			@GameData.KillCooldownRemainders[ply] = nil

		if IsValid ply.entity
			@Net_PauseKillCooldown playerTable, pause, remainder

GM.Player_UnPauseKillCooldown = (ply) =>
	@Player_PauseKillCooldown false

packVentLinks = (vent) ->
	if vent.Links and #vent.Links > 0
		links = {}

		for _, link in ipairs vent.Links
			table.insert links, link\GetName! or "N/A"

		return links

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

hook.Add "PlayerUse", "NMW AU Use", (activator, ent) ->
	aply = GAMEMODE.GameData.Lookup_PlayerByEntity[activator]
	if aply and GAMEMODE\IsGameInProgress!
		bodyid = ent\GetNW2Int "NMW AU PlayerID"
		victim = GAMEMODE.GameData.Lookup_PlayerByID[bodyid]
		if victim
			GAMEMODE\Meeting_Start activator, victim.color

hook.Add "FindUseEntity", "NMW AU FindUse", (ply, default) ->
	_, usable = GAMEMODE\TracePlayer ply
	return usable

hook.Add "KeyPress", "NMW AU UnVent", (ply, key) ->
	if key == IN_USE
		@ = GAMEMODE
		playerTable = @GameData.Lookup_PlayerByEntity[ply]
		if @GameData.Imposters[playerTable] and @GameData.Vented[playerTable] and (@GameData.VentCooldown[playerTable] or 0) <= CurTime!
			@Player_UnVent playerTable