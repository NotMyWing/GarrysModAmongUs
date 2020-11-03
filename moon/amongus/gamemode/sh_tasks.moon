--- Shared module using for localizing strings.
-- @module sh_tasks

-- Various task collections.
-- Pretty much none of these aside from All
-- are needed on the client, but whatever.
GM.TaskCollection or= {}
GM.TaskCollection.Short  or= {}
GM.TaskCollection.Long   or= {}
GM.TaskCollection.Common or= {}
GM.TaskCollection.All    or= {}

--- Registers a task.
-- @param taskTable Task table. See default tasks for examples.
GM.Task_Register = (taskTable = {}) =>
	with taskTable
		if not .Name
			@Logger.Error "Tried to register a task with no name"
			return

		collection = switch .Type
			when @TaskType.Short
				@TaskCollection.Short
			when @TaskType.Long
				@TaskCollection.Long
			when @TaskType.Common
				@TaskCollection.Common
			else
				@Logger.Error "Task #{.name} has bad type: #{.Type}"
				return

		if collection
			@Logger.Info "* Registered task #{.Name}"

			collection[.Name] = taskTable

			@TaskCollection.All[.Name] = taskTable

if CLIENT
	--- Opens the task VGUI.
	-- @string name Task name.
	-- @param data Task data. Normally this should be GAMEMODE.GameData.MyTasks[name].
	GM.Task_OpenTaskVGUI = (name, data) =>
		taskClass = @TaskCollection.All[name]

		if taskClass and taskClass.CreateVGUI
			@HUD_CloseMap!

			@HUD_OpenVGUI taskClass\CreateVGUI data
else
	taskBase = include "tasks/sv_base.lua"

	instantiateTask = (taskTable) ->
		taskInstance = {}
		setmetatable taskInstance, {
			__index: (name) =>
				val = rawget taskTable, name
				if val == nil
					val = rawget taskBase, name

				return val
		}

		return taskInstance

	taskMapToPool = (map) ->
		pool = {}
		for _, element in pairs map
			table.insert pool, element

		return pool

	--- Assigns the tasks to current players.
	-- This assumes that the gamedata table is properly filled.
	-- Yes, this implies that you shouldn't call this.
	GM.Task_AssignToPlayers = =>
		if not @MapManifest.Tasks
			-- What in the world is happening there?
			return

		shuffle = @Util.Shuffle

		pools = {
			[taskMapToPool @TaskCollection.Short]: @ConVarSnapshots.TasksShort\GetInt!
			[taskMapToPool @TaskCollection.Long]:  @ConVarSnapshots.TasksLong\GetInt!
		}

		-- Pick N random common tasks from the pool.
		commonTasks = {}

		for _, task in ipairs shuffle taskMapToPool @TaskCollection.Common
			if #commonTasks < @ConVarSnapshots.TasksCommon\GetInt!
				table.insert commonTasks, task
			else
				break

		totalTasks = 0
		@GameData.Tasks = {}

		-- Assign tasks to each player, including imposters.
		-- Imposters get tasks too, but can't complete them and their
		-- tasks don't count towards the pool.
		for _, playerTable in pairs @GameData.PlayerTables
			@GameData.Tasks[playerTable] = {}

			-- Don't assign tasks to bots, but create their table to prevent
			-- the logic from dying horribly.
			if IsValid(playerTable.entity) and playerTable.entity\IsBot! and not @ConVarSnapshots.DistributeTasksToBots\GetBool!
				continue

			-- Assign the picked common tasks.
			for id, task in ipairs commonTasks
				taskInstance = instantiateTask task
				taskInstance.__assignedPlayer = playerTable

				if taskInstance.Initialize
					taskInstance\Initialize!

				if not IsValid taskInstance\GetActivationButton!
					ent = GAMEMODE.Util.FindEntsByTaskName task.Name, true
					if IsValid ent[1]
						taskInstance\SetActivationButton ent[1]
					else
						@Logger.Error "Task #{task.Name} has NO suitable buttons on the map. Ignoring."
						continue

				@GameData.Tasks[playerTable][taskInstance.Name] = taskInstance
				if not @GameData.Imposters[playerTable]
					totalTasks += 1

			-- Now, pick N random tasks from each pool.
			for pool, maxCount in pairs pools
				count = 0
				for _, task in ipairs shuffle pool
					if count < maxCount
						taskInstance = instantiateTask task
						taskInstance.__assignedPlayer = playerTable

						if taskInstance.Initialize
							taskInstance\Initialize!

						if not IsValid taskInstance\GetActivationButton!
							ent = GAMEMODE.Util.FindEntsByTaskName task.Name, true
							if IsValid ent[1]
								taskInstance\SetActivationButton ent[1]
							else
								@Logger.Error "Task #{task.Name} has NO suitable buttons on the map. Ignoring."
								continue

						count += 1

						@GameData.Tasks[playerTable][taskInstance.Name] = taskInstance
						if not @GameData.Imposters[playerTable]
							totalTasks += 1
					else
						break

		@GameData.TotalTasks = totalTasks
		@GameData.CompletedTasks = 0
