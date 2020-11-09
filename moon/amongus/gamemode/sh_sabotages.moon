if SERVER
	AddCSLuaFile "sabotages/base.lua"

META = include "sabotages/base.lua"

instantiateSabotage = (tbl) ->
	instance = {
		Base: META
	}

	setmetatable instance, {
		__index: (name) =>
			val = rawget tbl, name
			if val == nil
				val = rawget META, name

			return val
	}

	return instance

GM.Sabotage_Handlers = {}

GM.Sabotage_Register = (sabotage) => with sabotage
	if not .Handler
		return

	@Sabotage_Handlers[.Handler] or= do
		path = "sabotages/#{.Handler}.lua"
		if SERVER
			AddCSLuaFile path

		@Logger.Info "* Registered sabotage handler \"#{.Handler}\" (#{path})"
		include "sabotages/#{.Handler}.lua"

GM.Sabotage_Init = =>
	if not @MapManifest or not @MapManifest.Sabotages
		return

	table.Empty @GameData.Sabotages
	for i, sabotage in ipairs @MapManifest.Sabotages
		if @Sabotage_Handlers[sabotage.Handler]
			instance = instantiateSabotage @Sabotage_Handlers[sabotage.Handler]
			instance.__handler = sabotage.Handler
			instance.__id = i

			if SERVER
				@GameData.Lookup_SabotageByVGUIID[instance\GetVGUIID!] = instance
				instance\SetupNetwork!

			instance\Init sabotage.CustomData
			instance\RefreshCooldown!

			@Logger.Info "Instantiated sabotage ##{i} (#{sabotage.Handler})"

			table.insert @GameData.Sabotages, instance

if CLIENT
	--- Opens the sabotage UI.
	hook.Add "GMAU OpenVGUI", "NMW AU OpenSabotageVGUI", (data) ->
		if not data.sabotageId
			return

		if instance = GAMEMODE.GameData.Sabotages[data.sabotageId]
			instance\ButtonUse GAMEMODE.GameData.Lookup_PlayerByEntity[LocalPlayer!], data.button
			GAMEMODE\HUD_OpenVGUI instance\CreateVGUI!
			return true

else
	GM.Sabotage_Start = (playerTable, id) =>
		if not @IsMeetingInProgress! and
			@GameData.Imposters[playerTable] and
			not @GameData.Vented[playerTable] and
			IsValid playerTable.entity

				_, usable = GAMEMODE\TracePlayer playerTable.entity
				if usable
					return

				if instance = @GameData.Sabotages[id]
					if instance\CanStart!
						instance\Start!

	GM.Sabotage_OpenVGUI = (playerTable, sabotage, button, callback) =>
		@Player_OpenVGUI playerTable, sabotage\GetVGUIID!, {
			sabotageId: sabotage\GetID!
			:button
		}, callback

	GM.Sabotage_Submit = (playerTable, data) =>
		sabotage = @GameData.Lookup_SabotageByVGUIID[@GameData.CurrentVGUI[playerTable]]
		if sabotage and sabotage\GetActive!
			sabotage\Submit playerTable, data

	GM.Sabotage_ForceEndAll = =>
		for sabotage in *@GameData.Sabotages
			if sabotage\GetActive!
				sabotage\End!
				sabotage\ForceUpdate!

	GM.Sabotage_EndNonPersistent = =>
		for sabotage in *@GameData.Sabotages
			if sabotage\GetActive! and not sabotage\GetPersistent!
				sabotage\End!

	GM.Sabotage_PauseAll = =>
		for sabotage in *@GameData.Sabotages
			sabotage\SetPaused true

	GM.Sabotage_UnPauseAll = =>
		for sabotage in *@GameData.Sabotages
			sabotage\SetPaused false

	GM.Sabotage_EnableAll = (enable = true) =>
		for sabotage in *@GameData.Sabotages
			sabotage\SetDisabled not enable

	GM.Sabotage_RefreshAllCooldowns = (customCooldown) =>
		for sabotage in *@GameData.Sabotages
			if customCooldown
				sabotage\SetNextUse CurTime! + customCooldown
			else
				sabotage\RefreshCooldown!
