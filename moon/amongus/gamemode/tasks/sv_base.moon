taskBase = {
	--- Sets the max amount of steps the task has.
	-- This value is displayed in the top-left corner of the player screen.
	-- Must be set exactly ONCE, during the init.
	-- The player will NOT know about further updates.
	SetMaxSteps: (steps) =>
		@__isMultiStep = steps > 1
		@__maxSteps = steps

	--- Duh.
	GetMaxSteps: => @__maxSteps or 1

	--- Duh.
	IsMultiStep: => @__isMultiStep or false

	--- Duh.
	GetName: => @name

	--- Sets the current step.
	-- This value is displayed in the top-left corner of the player screen.
	SetCurrentStep: (value) => @__currentStep = value

	--- Duh.
	GetCurrentStep: => @__currentStep or 1

	--- Sets the timeout.
	-- This value is displayed in the top-left corner of the player screen.
	-- Useful for tasks like "Inspect Sample".
	SetTimeout: (value) => @__timeout = value

	--- Duh.
	GetTimeout: => @__timeout or 0

	--- Sets the internal state.
	-- This can be useful to tell VGUIs what they should be displaying
	-- depending on the current state of the task.
	--
	-- While it's very similar to the current step, this value isn't
	-- displayed anywhere on the player's screen.
	SetCurrentState: (value) => @__state = value

	--- Gets the internal state. Returns 1 by default.
	GetCurrentState: => @__state or 1

	--- Sets the activation button.
	-- Activation button is the entity the player needs to press in order to
	-- activate the task. The entity MUST be func_ or prop_task_button and MUST have
	-- the same targetname as the task.
	SetActivationButton: (entity, important) =>
		@__button = entity
		@__isPositionImportant = important

	--- Duh.
	GetActivationButton: => @__button

	--- Sets the custom name for the task.
	-- Useful if you want your task to specify some extra info.
	-- The value is displayed in the top-left corner. Keep it short.
	SetCustomName: (value) => @__customName = value
	GetCustomName: => @__customName

	--- Gets the assigned player.
	-- For quite obvious reasons, you're not allowed to set it.
	GetAssignedPlayer: => @__assignedPlayer


	--- Sets the custom area for the task.
	-- This isn't useful.
	-- Why would you?
	SetCustomArea: (value) => @__customArea = value
	GetCustomArea: => @__customArea

	--- Completes the task.
	-- Counts it towards the pool and prohibits the player from accessing it.
	Complete: =>
		if not @__isCompleted
			@__isCompleted = true

			GAMEMODE.GameData.CompletedTasks += 1
			GAMEMODE.GameData.Tasks[@__assignedPlayer][@Name] = nil
			GAMEMODE\Net_BroadcastTaskCount GAMEMODE.GameData.CompletedTasks

	--- Duh.
	IsCompleted: => @__isCompleted

	--- Notifies the assigned player about the changes in the task.
	-- This networks
	--   * @GetState!
	--   * @GetCurrentStep!
	--   * @GetActivationButton! (+ @__isPositionImportant)
	--   * @GetTimeout!
	NetworkTaskData: => GAMEMODE\Net_UpdateTaskData @__assignedPlayer, @

	AdvanceInternal: =>
		if @IsMultiStep!
			if @GetCurrentStep! >= @GetMaxSteps!
				@Complete!
			else
				@SetCurrentStep @GetCurrentStep! + 1
		else
			@Complete!

	--- Can we visualize?
	CanVisual: =>
		return GAMEMODE.ConVarSnapshots.TasksVisual\GetBool!

	--- Triggers the "OnTaskUse" output of the current button.
	-- This doesn't get called if the user couldn't actually use the task for some reason.
	-- Does nothing if "au_tasks_enable_visual" is set to 0.
	UseVisual: =>
		if not @CanVisual!
			return

		btn = @GetActivationButton!
		if IsValid btn
			btn\Fire "OnTaskUse"

	--- Triggers the "OnTaskCancel" output of the current button.
	-- This gets called strictly when the player cancels the task prematurely.
	-- This includes meetings.
	-- Does nothing if "au_tasks_enable_visual" is set to 0.
	CancelVisual: (btn = @GetActivationButton!) =>
		if not @CanVisual!
			return

		if IsValid btn
			btn\Fire "OnTaskCancel"

	--- Triggers the "OnTaskAdvance" output of the current button.
	-- This gets called whenever the task is submitted but not completed.
	-- Does nothing if "au_tasks_enable_visual" is set to 0.
	AdvanceVisual: (btn = @GetActivationButton!) =>
		if not @CanVisual!
			return

		btn = @GetActivationButton!
		if IsValid btn
			btn\Fire "OnTaskAdvance"

	--- Triggers the "OnTaskComplete" output of the current button.
	-- This gets called strictly when the task is completed.
	-- Does nothing if "au_tasks_enable_visual" is set to 0.
	CompleteVisual: (btn = @GetActivationButton!) =>
		if not @CanVisual!
			return

		btn = @GetActivationButton!
		if IsValid btn
			btn\Fire "OnTaskComplete"

	--
	-- OVERRIDE THESE FUNCTIONS.
	--

	--- "Advances" the task.
	-- This is the function you need to override if you want custom logic.
	-- Make sure to call @NetworkTaskData! if you need to, well, network
	-- the data to the assigned player.
	Advance: (btn = @GetActivationButton!) =>
		@AdvanceInternal!
		@NetworkTaskData!

	--- Called when the task button is used.
	-- Return false to prevent.
	Use: => true
}

taskBase.__index = {}

return taskBase
