GM.LoadManifest = =>
	pathsToCheck = {
		{ "amongus/gamemode/manifest/#{game.GetMap!}.lua", "LUA" }
		if @FolderName ~= "amongus"
			{ "#{@FolderName}/gamemode/manifest/#{game.GetMap!}.lua" , "LUA" }

		{ "amongus/manifest/#{game.GetMap!}.lua", "LUA" }
	}

	for pathToCheck in *pathsToCheck
		-- This can, and most likely will be null because the second element
		-- is nullable. See `pathsToCheck = { ... }` above.
		if not pathToCheck
			continue

		filePath, location = unpack pathToCheck
		@Logger.Info "Checking #{filePath} for a valid manifest..."

		-- Check if the file actually exists.
		if file.Exists filePath, location

			-- If it does, include it and check if it's a valid manifest table.
			manifest = include filePath
			if not manifest or "table" ~= type manifest
				@Logger.Error "Map #{game.GetMap!} has malformed manifest!"
				@Logger.Error "Expected type \"table\", got \"#{type manifest}\""
				return

			-- If it is, AddCSLuaFile it, otherwise bail out.
			if SERVER
				AddCSLuaFile filePath

			@Logger.Info "Found the manifest file!"
			@MapManifest = manifest

			-- Check if "Tasks" sub-table if valid.
			if @MapManifest.Tasks and type(@MapManifest.Tasks) == "table" and #@MapManifest.Tasks > 0
				@Logger.Info "Found #{#@MapManifest.Tasks} tasks, registering..."

				-- If it is, scan it for tasks and register everything.
				for taskName in *@MapManifest.Tasks
					if SERVER
						AddCSLuaFile "tasks/#{taskName}.lua"

					taskTable = include "tasks/#{taskName}.lua"
					if taskTable
						taskTable.Name or= taskName

						@Task_Register taskTable
					else
						@Logger.Error "Task #{taskName} returned invalid table."
			else
				@Logger.Error "Found NO tasks for #{game.GetMap!}! The game mode will not function properly!"

			-- Check if "Sabotages" sub-table if valid.
			if @MapManifest.Sabotages and type(@MapManifest.Sabotages) == "table"
				@Logger.Info "Found #{#@MapManifest.Sabotages} sabotages, registering..."

				-- If it is, scan it for sabotages and register everything.
				-- Unlike the task block, this is all being handled by a dedicated method.
				-- Less code! Prettier!
				for sabotage in *@MapManifest.Sabotages
					@Sabotage_Register sabotage
			else
				@Logger.Warn "Found no sabotages...?"

			-- Everything's fine, don't check other files.
			break

		if not @MapManifest
			@Logger.Error "Couldn't find the manifest file for #{game.GetMap!}! The game mode will not function properly!"
			-- Default to an empty table so that things don't die horribly.
			@MapManifest = {}

GM\LoadManifest!
