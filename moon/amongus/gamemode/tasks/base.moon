taskBase = {
	Init: =>
		if CLIENT
			@CreateTaskEntry!

	--- Sets the max amount of steps the task has.
	-- This value is displayed in the top-left corner of the player screen.
	SetMaxSteps: (steps) =>
		@__maxSteps = steps

		if SERVER
			@SetDirty!

	--- Gets the max amount of steps.
	GetMaxSteps: => @__maxSteps or 1

	--- Sets the current step.
	-- This value is displayed in the top-left corner of the player screen.
	SetCurrentStep: (value) =>
		@__currentStep = value
		if SERVER
			@SetDirty!

	--- Gets the current step.
	GetCurrentStep: => @__currentStep or 1

	--- Sets the timeout.
	-- This value is displayed in the top-left corner of the player screen.
	-- Useful for tasks like "Inspect Sample".
	SetTimeout: (value) => @__timeout = value

	--- Gets the current step.
	GetTimeout: => @__timeout or 0

	--- Sets the internal state.
	-- This can be useful to tell VGUIs what they should be displaying
	-- depending on the current state of the task.
	--
	-- While it's very similar to the current step, this value isn't
	-- displayed anywhere on the player's screen.
	SetCurrentState: (value) =>
		@__state = value
		if SERVER
			@SetDirty!

	--- Gets the current state. Returns 1 by default.
	GetCurrentState: => @__state or 1

	--- Sets the activation button.
	-- Activation button is the entity the player needs to press in order to
	-- activate the task. The entity MUST be func_ or prop_task_button and MUST have
	-- the same targetname as the task.
	SetActivationButton: (entity) =>
		@__button = entity
		if SERVER
			@SetDirty!

	--- Duh.
	GetActivationButton: => @__button

	SetPositionImportant: (value) =>
		@__positionImportant = value
		if SERVER
			@SetDirty!

	GetPositionImportant: => @__positionImportant or false

	--- Sets the custom name for the task.
	-- Useful if you want your task to specify some extra info.
	-- The value is displayed in the top-left corner. Keep it short.
	SetCustomName: (value) =>
		@__customName = value
		if SERVER
			@SetDirty!

	--- Gets the custom name.
	GetCustomName: => @__customName

	--- Sets the custom area for the task.
	-- This isn't useful.
	-- Why would you?
	SetCustomArea: (value) =>
		@__customArea = value
		if SERVER
			@SetDirty!

	--- Gets the custom area.
	GetCustomArea: => @__customArea

	--- Sets whether the task is completed.
	-- This can only be set ONCE! For quite obvious reasons.
	SetCompleted: (value) =>
		return if @GetCompleted!

		@__completed = value
		if SERVER
			GAMEMODE.GameData.CompletedTasks += 1
			GAMEMODE.GameData.Tasks[@GetAssignedPlayer!][@GetName!] = nil
			GAMEMODE\Net_BroadcastTaskCount GAMEMODE.GameData.CompletedTasks, GAMEMODE.GameData.TotalTasks

			@OnComplete @GetActivationButton!
			@CompleteVisual @GetActivationButton!

			GAMEMODE\Game_CheckWin!
			@SetDirty!

	--- Gets whether the task has been completed.
	GetCompleted: => @__completed or false

	--- Called when the task button is used.
	-- Return false to prevent.
	CanUse: => true

	--- Returns the task id.
	-- This is useful so you don't have to come up with random timer names.
	GetID: => "#{@GetAssignedPlayer!.entity\GetCreationID!} #{@GetName!}"

	--- Sets the assigned player.
	-- This is provided for the game mode to assign the player.
	-- There's little reason you should be calling this.
	SetAssignedPlayer: (value) =>
		if SERVER and @__assignedPlayer
			return

		@__assignedPlayer = value

	--- Gets the assigned player.
	-- Always returns the local player table on the client realm.
	GetAssignedPlayer: =>
		if CLIENT
			GAMEMODE.GameData.Lookup_PlayerByEntity[LocalPlayer!]
		else
			@__assignedPlayer

	-- Sets the task name.
	-- This is provided for the game mode to assign the name.
	-- There's little reason you should be calling this.
	-- Perhaps, you're looking for @SetCustomName?
	SetName: (value) =>
		return if @__name

		@__name = value

	GetName: => @__name
}

if SERVER
	with taskBase
		--- Can we visualize?
		.CanVisual = => GAMEMODE.ConVarSnapshots.TasksVisual\GetBool!

		--- Triggers the "OnTaskUse" output of the current button.
		-- This doesn't get called if the user couldn't actually use the task for some reason.
		-- Does nothing if "au_tasks_enable_visual" is set to 0.
		-- There's little reason you should be calling this.
		.UseVisual = (btn = @GetActivationButton!) =>
			return unless @CanVisual!

			activator = @GetAssignedPlayer!.entity

			if IsValid(btn) and IsValid activator
				btn\TriggerOutput "OnTaskUse", activator

		--- Internal function.
		-- Called whenever player closes the GUI without advancing the task.
		-- There's little reason you should be calling this.
		.Cancel = (btn) =>
			if not @GetCompleted! and btn == @GetActivationButton!
				@OnCancel btn
				@CancelVisual btn

		--- Triggers the "OnTaskCancel" output of the current button.
		-- This gets called strictly when the player cancels the task prematurely.
		-- This includes meetings.
		-- Does nothing if "au_tasks_enable_visual" is set to 0.
		-- There's little reason you should be calling this.
		.CancelVisual = (btn = @GetActivationButton!) =>
			return unless @CanVisual!

			activator = @GetAssignedPlayer!.entity

			if IsValid(btn) and IsValid activator
				btn\TriggerOutput "OnTaskCancel", activator

		--- Internal function.
		-- Called whenever the assigned player uses the button. (opens the UI)
		.Use = (btn) =>
			@OnUse btn

		--- Internal function.
		-- This gets called when the assignet player submits the task.
		-- You should only be calling this if your custom task doesn't have a VGUI.
		-- DO NOT override this unless you know what you're doing.
		.Advance = (btn = @GetActivationButton!) =>
			oldStep = @GetCurrentStep!
			oldState = @GetCurrentState!
			@OnAdvance btn

			if not @GetCompleted! and (@GetCurrentState! ~= oldState or @GetCurrentStep! ~= oldStep)
				@AdvanceVisual btn

		--- Triggers the "OnTaskAdvance" output of the current button.
		-- This gets called whenever the task is submitted but not completed.
		-- Does nothing if "au_tasks_enable_visual" is set to 0.
		-- There's little reason you should be calling this.
		.AdvanceVisual = (btn = @GetActivationButton!) =>
			return unless @CanVisual!

			activator = @GetAssignedPlayer!.entity

			if IsValid(btn) and IsValid activator
				btn\TriggerOutput "OnTaskAdvance", activator

		--- Triggers the "OnTaskComplete" output of the current button.
		-- This gets called strictly when the task is completed.
		-- Does nothing if "au_tasks_enable_visual" is set to 0.
		-- There's little reason you should be calling this.
		.CompleteVisual = (btn = @GetActivationButton!) =>
			return unless @CanVisual!

			activator = @GetAssignedPlayer!.entity

			if IsValid(btn) and IsValid activator
				btn\TriggerOutput "OnTaskComplete", activator

		--- Marks the task dirty, notifying the game mode that
		-- the data should be broadcasted to the client.
		.SetDirty = =>
			return unless IsValid @GetAssignedPlayer!.entity

			-- This sends an update packet next tick.
			-- Really jank, I know.
			handle = "NMW AU Task Dirty #{@GetID!}"
			GAMEMODE.GameData.Timers[handle] = true

			timer.Create handle, 0, 1, ->
				@__netUpdate!

		--- Internal function.
		-- Sets up default accessors.
		.SetupNetwork = =>
			@__accessorTable = {
				"CurrentStep"
				"MaxSteps"
				"Timeout"
				"CurrentState"
				"ActivationButton"
				"PositionImportant"
				"CustomName"
				"CustomArea"
				"Completed"
			}

			@__oldData = {}

		-- The backbone of the network update pipeline.
		-- There's little reason you should be calling this manually.
		.__netUpdate = =>
			handle = "NMW AU Task Dirty #{@GetID!}"
			if timer.Exists handle
				timer.Remove handle

			return unless IsValid @GetAssignedPlayer!.entity

			packet = {}

			changed = false
			for accessor in *@__accessorTable
				value = @["Get#{accessor}"] @

				if not @__oldData or value ~= @__oldData[accessor]
					@__oldData[accessor] = value
					packet[accessor] = value == nil and "_nil" or value
					changed = true

			if changed
				GAMEMODE\Net_UpdateTaskData @GetAssignedPlayer!, @GetName!, packet

		--- Forces a network update.
		-- This should only be called when it's required to issue an
		-- update immediately.
		--
		-- An example of that would be clean up, during which it's important
		-- to issue an update packet immediately before the sabotage table is
		-- cleared on the client.
		.ForceUpdate = =>
			@__netUpdate!

		--- Defines a pair of Get/Set methods as networkable.
		-- This will automatically broadcast the new state of the accessor to
		-- everyone, provided @SetDirty is called.
		--
		-- Your sabotage handler MUST have a valid pair of matching Get/Set methods,
		-- otherwise this will completely break the network update pipeline.
		--
		-- For example, if you passed `MyCustomData` to this function, your class
		-- must have both `GetMyCustomData` and `SetMyCustomData` methods.
		--
		-- Don't forget to call @SetDirty on the server realm inside the
		-- setter implementation if you want the value to get propagated.
		--
		-- @param accessor Accessor.
		.SetNetworkable = (accessor) =>
			table.insert @__accessorTable, accessor

		--
		-- OVERRIDE AREA.
		--

		--- Called whenever the assigned player uses the button. (opens the UI)
		-- Don't forget to base-call this if you want a VGUI.
		.OnUse = (btn) =>
			@UseVisual btn
			playerTable = @GetAssignedPlayer!
			if GAMEMODE\Player_CanOpenVGUI playerTable
				GAMEMODE\Player_OpenVGUI playerTable, @GetName!, { taskName: @GetName! }, (-> @Cancel btn)

		--- Called whenever the assigned player closes the GUI without advancing the task.
		.OnCancel = (btn) =>

		--- Called whenever the assigned player finishes the task using the provided button.
		.OnComplete = (btn) =>

		--- Called whenever the assigned player submits the task.
		-- This is the function you need to override if you want custom logic.
		.OnAdvance = (btn) =>
			if @GetMaxSteps! > 1
				if @GetCurrentStep! >= @GetMaxSteps!
					@SetCompleted true
				else
					@SetCurrentStep @GetCurrentStep! + 1
			else
				@SetCompleted true

else
	TRANSLATE = GM.Lang.GetEntry

	with taskBase
		.Submit = =>
			GAMEMODE\Net_SendSubmitTask!

		.CreateTaskEntry = =>
			@__taskEntry = with GAMEMODE\HUD_AddTaskEntry!
				neutral = Color 255, 255, 255
				completed = Color 0, 221, 0
				progress = Color 255, 255, 0

				.Think = ->
					local text
					local color

					if IsValid @GetActivationButton!
						button = @GetActivationButton!

						timeout = (@GetTimeout! or 0) - CurTime!
						timeoutText = if timeout > 0
							string.format " (%ds)", math.floor timeout
						else
							""

						area = TRANSLATE @GetCustomArea! or button\GetArea!
						name = TRANSLATE "task." .. ((@GetCustomName! or @GetName!) or "undefined")

						text = "#{area}: #{name}"
						if @GetMaxSteps! > 1 and not @GetCompleted!
							text ..= " (#{@GetCurrentStep! - 1}/#{@GetMaxSteps!})"

						color = if @GetCompleted!
							completed
						elseif @GetCurrentStep! > 1 or @GetCurrentState! > 1
							progress
						else
							neutral

						text = text .. timeoutText
					else
						text = "???"

					if text ~= .__oldText
						\SetText text
						.__oldText = text

					if color and color ~= .__oldColor
						\SetColor color
						.__oldColor = color

taskBase.__index = {}

return taskBase
