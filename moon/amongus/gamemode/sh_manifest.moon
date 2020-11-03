GM.LoadManifest = =>
	-- Default to an empty table so that things don't die horribly.
	@MapManifest = {}

	dir = @FolderName or "amongus"
	fileName = "#{dir}/gamemode/manifest/#{game.GetMap!}.lua"

	if file.Exists fileName, "LUA"
		if SERVER
			AddCSLuaFile fileName

		@MapManifest = include fileName

		GAMEMODE.Logger.Info "Found the manifest file for #{game.GetMap!}"

		if @MapManifest.Tasks and type(@MapManifest.Tasks) == "table"
			GAMEMODE.Logger.Info "Found #{#@MapManifest.Tasks} tasks for #{game.GetMap!}"
			for taskName in *@MapManifest.Tasks
				if SERVER
					AddCSLuaFile "tasks/#{taskName}.lua"

				taskTable = include "tasks/#{taskName}.lua"
				if taskTable
					taskTable.Name or= taskName

					@Task_Register taskTable
				else
					GAMEMODE.Logger.Error "Task #{taskName} returned invalid table."

		if @MapManifest.Sabotages and type(@MapManifest.Sabotages) == "table"
			GAMEMODE.Logger.Info "Found #{#@MapManifest.Sabotages} sabotages for #{game.GetMap!}"
			for sabotage in *@MapManifest.Sabotages
				@Sabotage_Register sabotage
	else
		GAMEMODE.Logger.Error "Couldn't find the manifest file for #{game.GetMap!}! The game mode will not work properly."

GM\LoadManifest!
