ASSETS = {
	close: Material "au/gui/closebutton.png", "smooth"
}

-----------------------------
--  GENERAL-USE VGUI BASE  --
-----------------------------
vgui.Register "AmongUsVGUIBase", {
	Init: =>
		@SetZPos 30002
		@SetSize ScrW!, ScrH!
		@SetPos 0, ScrH!
		@SetDeleteOnClose true

		@__isOpened = false
		@__closeButton = with @Add "DImageButton"
			\SetText ""
			\SetMaterial ASSETS.close
			\SetSize ScrH! * 0.09, ScrH! * 0.09
			\SetZPos 1
			\Hide!

	-- Prepares the base using the provided panel.
	-- @param content Panel to put in the middle.
	Setup: (content) =>
		content\SetParent @
		content\Center!
		@NewAnimation 0, 0, 0, ->
			closeButton = @GetCloseButton!

			if IsValid closeButton
				with closeButton
					\Show!

					x, y = content\GetPos!
					x -= ScrH! * 0.11
					\SetPos x, y

					.DoClick = ->
						@Close!

	--- Makes the UI pop up.
	Popup: (force = false) =>
		return false if @__isOpened
		return false if not force and @__isAnimating
		@__isOpened = true

		@MakePopup!
		@SetKeyboardInputEnabled false

		@SetVisible true
		@AlphaTo 255, 0.1, 0.01
		surface.PlaySound @GetAppearSound!

		currentX, currentY = @GetPos!
		if currentY == 0
			@SetPos currentX, 1

		@__isAnimating = true
		@MoveTo 0, 0, 0.2, nil, nil, ->
			@__isAnimating = false

			if @OnOpen
				@OnOpen!

		return true

	--- Closes the UI.
	Close: (force = false) =>
		return false unless @__isOpened
		return false if not force and @__isAnimating
		@SetMouseInputEnabled false

		@__isOpened = false

		@AlphaTo 0, 0.1
		surface.PlaySound @GetDisappearSound!

		currentX, currentY = @GetPos!
		if currentY == ScrH!
			@SetPos currentX, currentY - 1

		@__isAnimating = true
		@MoveTo 0, ScrH!, 0.1, nil, nil, ->
			@__isAnimating = false

			if @OnClose
				@OnClose!

			if @GetDeleteOnClose!
				@Remove!
			else
				@SetVisible false

		return true

	--- Handles mouse clicks.
	OnMousePressed: (keyCode) =>
		if MOUSE_LEFT == keyCode
			@wasPressed = true

	--- Handles mouse clicks 2.
	OnMouseReleased: =>
		if @wasPressed
			@Close!

	--- Handles mouse clicks 3.
	OnCursorExited: => @wasPressed = false

	--- Closes the UI when Escape is pressed.
	Think: =>
		if @__isOpened and gui.IsGameUIVisible!
			gui.HideGameUI!
			@Close true

	--- Tells the server that the player is no longer using the UI.
	OnRemove: => GAMEMODE\Net_SendCloseVGUI!

	--- Sets the apper sound.
	-- @param value Path to sound.
	SetAppearSound: (value) => @__appearSound = value
	GetAppearSound: => @__appearSound or "au/panel_genericappear.ogg"

	--- Sets the disappear sound.
	-- @param value Path to sound.
	SetDisappearSound: (value) => @__disappearSound = value
	GetDisappearSound: => @__disappearSound or "au/panel_genericdisappear.ogg"

	--- Gets the close button.
	GetCloseButton: => @__closeButton

	--- Sets whether the panel should be deleted on close.
	SetDeleteOnClose: (value) => @__deleteOnClose = value
	GetDeleteOnClose: => @__deleteOnClose or false

	Paint: =>

}, "Panel"

------------------------
--  SABOTAGE UI BASE  --
------------------------
vgui.Register "AmongUsSabotageBase", {
	Think: =>
		@BaseClass.Think @

		if @__sabotage
			if not @__closed and not @__sabotage\GetActive!
				@__closed = true
				@Close true

	Submit: (data = 0, autoClose = true) =>
		GAMEMODE\Net_SendSubmitSabotage data

		if autoClose
			@NewAnimation 0, 2, 0, ->
				@Close true

	SetSabotage: (value) => @__sabotage = value
	GetSabotage: => @__sabotage

}, "AmongUsVGUIBase"

--------------------
--  TASK UI BASE  --
--------------------
vgui.Register "AmongUsTaskBase", {
	Submit: (autoClose = true, data = 0) =>
		GAMEMODE\Net_SendSubmitTask data

		if autoClose
			@NewAnimation 0, 2, 0, ->
				@Close true

}, "AmongUsVGUIBase"
