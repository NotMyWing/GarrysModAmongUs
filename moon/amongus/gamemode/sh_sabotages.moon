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

		print "Registered sabotage handler \"#{.Handler}\" (#{path})"
		include "sabotages/#{.Handler}.lua"

GM.Sabotage_Init = =>
	table.Empty @GameData.Sabotages
	for i, sabotage in ipairs @MapManifest.Sabotages or {}
		if @Sabotage_Handlers[sabotage.Handler]
			instance = instantiateSabotage @Sabotage_Handlers[sabotage.Handler]
			instance.__handler = sabotage.Handler
			instance.__id = i

			if SERVER
				@GameData.Lookup_SabotageByVGUIID[instance\GetVGUIID!] = instance
				instance\SetupNetwork!

			instance\Init sabotage.CustomData
			instance\RefreshCooldown!

			print "Instantiated sabotage ##{i} (#{sabotage.Handler})"

			table.insert @GameData.Sabotages, instance

GM.Sabotage_Start = (playerTable, id) =>
	if @GameData.Imposters[playerTable] and not @GameData.Vented[playerTable]
		if instance = @GameData.Sabotages[id]
			if instance\CanStart!
				instance\Start!

GM.Sabotage_OpenVGUI = (playerTable, sabotage, button, callback) =>
	if @Player_OpenVGUI playerTable, sabotage\GetVGUIID!, callback
		if IsValid playerTable.entity
			@Net_OpenSabotageVGUI playerTable, sabotage, button

GM.Sabotage_Submit = (playerTable, data) =>
	sabotage = @GameData.Lookup_SabotageByVGUIID[@GameData.CurrentVGUI[playerTable]]
	if sabotage and sabotage\GetActive!
		sabotage\Submit playerTable, data

GM.Sabotage_ForceEndAll = =>
	for sabotage in *@GameData.Sabotages
		sabotage\End!

GM.Sabotage_EndNonPersistent = =>
	for sabotage in *@GameData.Sabotages
		if not sabotage\GetPersistent!
			sabotage\End!

GM.Sabotage_PauseAll = =>
	for sabotage in *@GameData.Sabotages
		sabotage\SetPaused true

GM.Sabotage_UnPauseAll = =>
	for sabotage in *@GameData.Sabotages
		sabotage\SetPaused false