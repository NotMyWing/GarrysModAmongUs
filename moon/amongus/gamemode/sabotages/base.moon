sabotageBase = {
	--- Returns whether the sabotage can be started
	CanStart: => not @GetActive! and not @GetDisabled! and not @IsOnCooldown!

	--- Returns the sabotage handler class name.
	GetHandler: => @__handler

	--- Returns the sabotage ID. This ID is the same on both the server and client.
	GetID: => @__id

	--- Returns the sabotage VGUI ID. This is used for creating and tying VGUIs to sabotages.
	GetVGUIID: => "sabotage.#{@GetID!}"

	--- Starts the sabotage.
	Start: =>
		return if true == hook.Call "GMAU SabotageStart", nil, @

		if SERVER
			@SetActive true

		@OnStart!

	--- Internal function.
	-- Called whenever one of the active buttons gets activated.
	ButtonUse: (playerTable, button) =>
		@OnButtonUse playerTable, button

	--- Ends the sabotage.
	End: =>
		return if true == hook.Call "GMAU SabotageEnd", nil, @

		if SERVER
			@SetActive false

		@OnEnd!

	--- Internal function.
	-- Called only when a player submits arbitrary data through VGUI.
	Submit: (playerTable, data) =>
		return if true == hook.Call "GMAU SabotageSubmit", nil, @

		@OnSubmit playerTable, data

	--- Refreshes the sabotage cooldown.
	-- If the sabotage is paused, this calls @SetCooldownOverride instead.
	RefreshCooldown: =>
		if @GetPaused!
			@SetCooldownOverride @GetCooldown!
		else
			@SetNextUse CurTime! + @GetCooldown!

	--- Returns whether the sabotage is on cooldown.
	IsOnCooldown: => (@GetCooldownOverride! ~= 0) or (not @__nextUse or @__nextUse > CurTime!)

	--- Sets the sabotage cooldown.
	-- Not to be confused with @SetNextUse.
	SetCooldown: (value) =>
		@__cooldown = value
		if SERVER
			@SetDirty!

	--- Gets the sabotage cooldown.
	GetCooldown: => @__cooldown or 30

	--- Sets when the sabotage can be activated.
	SetNextUse: (value) =>
		@__nextUse = value
		if SERVER
			@SetDirty!

	--- Gets when the sabotage can be activated.
	GetNextUse: => @__nextUse

	--- Sets the activation buttons.
	-- This function accepts either a table or entities as vararg.
	SetActivationButtons: (...) =>
		if @__oldActivationButtons
			for btn in *@__oldActivationButtons
				GAMEMODE.GameData.SabotageButtons[btn] = nil

		inputTable = { ... }

		if "table" == type inputTable[1]
			@__activationButtons = inputTable[1]
		else
			@__activationButtons = inputTable

		for btn in *@__activationButtons
			GAMEMODE.GameData.SabotageButtons[btn] = @GetID!

		@__oldActivationButtons = @__activationButtons

		if SERVER
			@SetDirty!

	--- Gets the activation buttons.
	GetActivationButtons: => @__activationButtons or {}

	--- Sets whether the sabotage is major.
	SetMajor: (value) =>
		@__major = value
		if SERVER
			@SetDirty!

	--- Gets whether the sabotage is major.
	GetMajor: => @__major or false

	--- Sets whether the sabotage is active.
	-- This is an internal function.
	-- Don't call it unless you know what you're doing.
	-- If you want to start the sabotage, call @Start instead.
	SetActive: (value) =>
		@__active = value

		if CLIENT
			if value
				@Start!
			else
				@End!
		else
			@SetDirty!

	--- Gets whether the sabotage is active.
	GetActive: => @__active or false

	--- Sets whether the sabotage is disabled.
	SetDisabled: (value) =>
		@__disabled = value
		if SERVER
			@SetDirty!

	--- Gets whether the sabotage is disabled.
	GetDisabled: => @__disabled or false

	--- Sets the cooldown override.
	-- This is mostly a value displayed for the imposters.
	SetCooldownOverride: (value) =>
		@__cooldownOverride = value
		if SERVER
			@SetDirty!

	--- Gets the cooldown override.
	GetCooldownOverride: => @__cooldownOverride or 0

	--- Sets whether the sabotage is paused.
	SetPaused: (value) =>
		if SERVER
			if @__paused ~= value
				-- Paused
				if value
					@SetCooldownOverride math.max 0, @GetNextUse! - CurTime!

				-- Unpaused
				else
					@SetNextUse CurTime! + @GetCooldownOverride!
					@SetCooldownOverride 0

				@SetDirty!

		@__paused = value

	--- Gets whether the sabotage is paused.
	GetPaused: (value) => @__paused or false

	--
	-- OVERRIDE AREA
	--

	--- Called when the sabotage class is created.
	-- Not to be confused with OnStart.
	Init: (data = {}) =>
		if SERVER
			if data.Cooldown
				@SetCooldown data.Cooldown

	--- Called when the sabotage is started. Shared.
	OnStart: =>
		if SERVER
			-- If this sabotage is major, disable the meeting button.
			if @GetMajor!
				GAMEMODE\SetMeetingDisabled true

			for sabotage in *GAMEMODE.GameData.Sabotages
				-- If this sabotage is major, disable ALL other sabotages.
				if @GetMajor!
					sabotage\SetDisabled true
				-- Otherwise disable major sabotages only.
				elseif not @GetMajor! and sabotage\GetMajor!
					sabotage\SetDisabled true

	--- Called whenever a sabotage button is pressed. Shared.
	OnButtonUse: (playerTable, button) =>
		@End!

	--- Called when custom data is submitted.
	-- This does NOT get called on the client despite being in the shared
	-- method zone. On the server, this gets called whenever a client
	-- submits custom data through an opened VGUI tied to the sabotage.
	OnSubmit: (playerTable, data) =>

	--- Called when the sabotage ends. Shared.
	-- This function is guaranteed to be called, even during clean-ups.
	OnEnd: =>
		if SERVER
			@RefreshCooldown!

			-- If this sabotage is major, enable the meeting button.
			if @GetMajor!
				GAMEMODE\SetMeetingDisabled false

			-- Check if this sabotage was the last active one.
			lastActive = true
			for sabotage in *GAMEMODE.GameData.Sabotages
				if sabotage ~= @ and sabotage\GetActive!
					lastActive = false

			if lastActive
				-- Re-enable all sabotages.
				for sabotage in *GAMEMODE.GameData.Sabotages
					sabotage\SetDisabled false

					-- If we're major, refresh all other major sabotages.
					if sabotage\GetMajor! and @GetMajor!
						sabotage\RefreshCooldown!
}

if SERVER
	with sabotageBase
		--- Sets whether the task is persistent.
		-- Persistent tasks don't get cleared during the meetings.
		.SetPersistent = (value) => @__persistent = value

		--- Gets whether the task is persistent.
		.GetPersistent = => @__persistent or false

		--- Marks the sabotage dirty, notifying the game mode that
		-- the data should be broadcasted to the clients.
		.SetDirty = =>
			-- This sends an update packet next tick.
			-- Really jank, I know.
			handle = "NMW AU Sabotage Dirty #{@GetID!}"
			GAMEMODE.GameData.Timers[handle] = true

			timer.Create handle, 0, 1, ->
				@__netUpdate!

		--- Internal function.
		-- Sets up default accessors.
		.SetupNetwork = =>
			@__accessorTable = {
				"Net_BroadcastSabotageData": {
					"ActivationButtons"
					"Major"
					"Active"
				}
				"Net_BroadcastSabotageDataImposter": {
					"NextUse"
					"Disabled"
					"Paused"
					"CooldownOverride"
				}
			}

			@__oldData = {}

		-- The backbone of the network update pipeline.
		-- There's little reason you should be calling this manually.
		.__netUpdate = =>
			handle = "NMW AU Sabotage Dirty #{@GetID!}"
			if timer.Exists handle
				timer.Remove handle

			for method, accessors in pairs @__accessorTable
				if not @__oldData[method]
					@__oldData[method] = {}

				oldData = @__oldData[method]
				packet = {}

				changed = false
				for accessor in *accessors
					value = @["Get#{accessor}"] @
					if not oldData or value ~= oldData[accessor]
						oldData[accessor] = value
						packet[accessor] = value
						changed = true

				if changed
					GAMEMODE[method] GAMEMODE, @GetID!, packet

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
		-- @param imposter Is it imposter-specific?
		.SetNetworkable = (accessor, imposter) =>
			if imposter
				table.insert @__accessorTable["Net_BroadcastSabotageDataImposter"], accessor
			else
				table.insert @__accessorTable["Net_BroadcastSabotageData"], accessor

sabotageBase.__index = {}

return sabotageBase
