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

		@__closeButton = with @Add "DImageButton"
			\SetText ""
			\SetMaterial ASSETS.close
			\SetSize ScrH! * 0.09, ScrH! * 0.09
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
	Popup: =>
		@MakePopup!
		@AlphaTo 255, 0.1, 0.01
		surface.PlaySound @GetAppearSound!

		currentX, currentY = @GetPos!
		if currentY == 0
			@SetPos currentX, 1

		@MoveTo 0, 0, 0.2, nil, nil, ->
			if @OnClose
				@OnClose!

	--- Closes the UI.
	Close: =>
		@AlphaTo 0, 0.1
		surface.PlaySound @GetDisappearSound!

		currentX, currentY = @GetPos!
		if currentY == ScrH!
			@SetPos currentX, currentY - 1

		@MoveTo 0, ScrH!, 0.1, nil, nil, ->
			if @OnClose
				@OnClose!

			@Remove!

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
		if gui.IsGameUIVisible!
			gui.HideGameUI!
			@Close!

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

	Paint: =>

}, "DPanel"

------------------------
--  SABOTAGE UI BASE  --
------------------------
vgui.Register "AmongUsSabotageBase", {
	Think: =>
		@BaseClass.Think @

		if @__sabotage
			if not @__closed and not @__sabotage\GetActive!
				@__closed = true
				@Close!

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
				@Close!

}, "AmongUsVGUIBase"
