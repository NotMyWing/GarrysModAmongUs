--- Shared module for defining and managing tasks.
-- @module sh_tasks

if SERVER
	AddCSLuaFile "tasks/base.lua"

TASK_BASE = include "tasks/base.lua"

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

GM.Task_Instantiate = (taskTable) =>
	taskInstance = {
		Base: TASK_BASE
	}

	setmetatable taskInstance, {
		__index: (name) =>
			val = rawget taskTable, name
			if val == nil
				val = rawget TASK_BASE, name

			return val
	}

	return taskInstance

if CLIENT
	--- Opens the task VGUI.
	hook.Add "GMAU OpenVGUI", "NMW AU OpenTaskVGUI", (data) ->
		return unless data.taskName

		instance = GAMEMODE.GameData.MyTasks[data.taskName]
		if instance and instance.CreateVGUI
			GAMEMODE\HUD_OpenVGUI instance\CreateVGUI!
			return true

else
	taskMapToPool = (map) -> [v for k, v in pairs map]

	--- Assigns the tasks to current players.
	-- This assumes that the gamedata table is properly filled.
	-- Yes, this implies that you shouldn't call this.
	GM.Task_AssignToPlayers = =>
		-- What in the world is happening there?
		return unless @MapManifest.Tasks

		shuffle = @Util.Shuffle

		pools = {
			[taskMapToPool @TaskCollection.Short]: @ConVarSnapshots.TasksShort\GetInt!
			[taskMapToPool @TaskCollection.Long]:  @ConVarSnapshots.TasksLong\GetInt!
		}

		-- Pick N random common tasks from the pool.
		commonTasks = {}

		for task in *shuffle taskMapToPool @TaskCollection.Common
			if #commonTasks < @ConVarSnapshots.TasksCommon\GetInt!
				table.insert commonTasks, task
			else
				break

		totalTasks = 0
		table.Empty @GameData.Tasks

		-- Assign tasks to each player, including imposters.
		-- Imposters get tasks too, but can't complete them and their
		-- tasks don't count towards the pool.
		for playerTable in *@GameData.PlayerTables
			@GameData.Tasks[playerTable] = {}

			-- Don't assign tasks to leavers.
			continue unless IsValid playerTable.entity


			-- Don't assign tasks to bots, but create their table to prevent
			-- the logic from dying horribly.
			continue if playerTable.entity\IsBot! and not @ConVarSnapshots.DistributeTasksToBots\GetBool!

			-- Instantiates the provided task.
			-- Duplicate code is bad!
			instantiate = (taskTable) ->
				taskInstance = @Task_Instantiate taskTable
				with taskInstance
					\SetAssignedPlayer playerTable
					\SetName taskTable.Name
					\SetupNetwork!
					\Init!
					\SetDirty!

					if not IsValid \GetActivationButton!
						ent = GAMEMODE.Util.FindEntsByTaskName .Name, true
						if IsValid ent[1]
							\SetActivationButton ent[1]
						else
							@Logger.Error "Task #{.Name} has NO suitable buttons on the map. Ignoring."
							return

					@GameData.Tasks[playerTable][.Name] = taskInstance
					if not @GameData.Imposters[playerTable]
						totalTasks += 1

				return true

			-- Assign the picked common tasks.
			for task in *commonTasks
				instantiate task

			-- Now, pick N random tasks from each pool and assign.
			for pool, maxCount in pairs pools
				count = 0
				for task in *shuffle pool
					if count < maxCount and instantiate task
						count += 1
					else
						break

		@GameData.TotalTasks = totalTasks
		@GameData.CompletedTasks = 0

	--- Forces the player into doing the task.
	-- This will fail if the player is too far from the activation button.
	-- This will also fail if the player isn't tasked with the provided task.
	-- This will also fail if the button did not consent.
	-- Yes.
	-- @param playerTable The tasked crewmate.
	-- @string name Name of the task.
	GM.Task_Start = (playerTable, name) =>
		return unless IsValid playerTable.entity

		task = (@GameData.Tasks[playerTable] or {})[name]
		return unless task

		ent = task\GetActivationButton!
		return unless IsValid ent

		if task and playerTable.entity\GetPos!\Distance(ent\GetPos!) <= 128 and task\CanUse!
			task\Use ent

		return

	--- Submits the current task. Tied to VGUI. This function will fail
	-- if the player isn't actually doing any tasks at this moment.
	-- @param playerTable The tasked crewmate.
	GM.Task_Submit = (playerTable) =>
		currentVGUI = @GameData.CurrentVGUI[playerTable]
		currentTask = (@GameData.Tasks[playerTable] or {})[currentVGUI]

		if currentTask and not currentTask\GetCompleted!
			if IsValid playerTable.entity
				ent = currentTask\GetActivationButton!

				return unless playerTable.entity\TestPVS ent

				currentTask\Advance ent
