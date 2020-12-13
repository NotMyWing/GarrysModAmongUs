taskTable = {
	Name: "inspectSample"
	Type: GM.TaskType.Long
	Time: 60
	Init: =>
		@Base.Init @

		if SERVER
			@SetMaxSteps 2
			@SetNetworkable "Anomaly"

	-- Resets the anomaly and cooking time.
	ResetAnomaly: =>
		if SERVER
			@SetAnomaly math.random 1, 5
			@SetTimeout CurTime! + @Time

	OnAdvance: (btn, data) =>
		-- The player asked us to start the task.
		if @GetCurrentStep! == 1
			@SetCurrentStep 2
			@ResetAnomaly!

		elseif @GetTimeout! - CurTime! < 0
			-- the player is dumb
			if data ~= @GetAnomaly!
				@SetAnomaly 0
				@SetCurrentStep 1

			-- The player has submitted the right vial.
			else
				@SetCompleted true

	SetAnomaly: (value) =>
		@__anomaly = value
		if SERVER
			@SetDirty!

	GetAnomaly: => @__anomaly or 0
}

if CLIENT
	TRANSLATE = GAMEMODE.Lang.GetEntry

	ASSETS = {asset, Material("au/gui/tasks/inspectsample/#{asset}.png", "smooth") for asset in *{
		"background"
		"square_button"
		"circle_button"
		"test_tube"
		"fluid"
		"rack_back"
		"rack_front"
		"shelf"
		"bottom_panel"
		"top_panel"
		"nozzle"
	}}

	SOUNDS = {
		button: "au/panel_med_button.wav"
		fail:   "au/panel_med_buttonfail.wav"
		appear: "au/panel_med_reagentappear.wav"
		liquid: "au/panel_medbay_liquid.wav"
	}

	taskTable.CreateVGUI = =>
		base = vgui.Create "AmongUsTaskBase"

		with base
			\Setup with vgui.Create "DImage"
				local shelf
				failTime = 0
				testTubes = {}

				max_size = ScrH! * 0.8

				width, height = GAMEMODE.Render.FitMaterial ASSETS.background,
					max_size, max_size

				topPanelWidth, topPanelHeight = GAMEMODE.Render.FitMaterial ASSETS.top_panel, width, height
				bottomPanelWidth, bottomPanelHeight = GAMEMODE.Render.FitMaterial ASSETS.bottom_panel, width, height
				bottomPanelPosX = (width / 2) - (bottomPanelWidth / 2)
				bottomPanelPosY = height - bottomPanelHeight + 1

				\SetSize width, height
				\SetMaterial ASSETS.background

				-- That's a LOT of hard-coded things, man.
				shelfWidth, shelfHeight = GAMEMODE.Render.FitMaterial ASSETS.shelf, 486 / 500 * width, height

				shelfPosX = (width / 2) - (shelfWidth / 2)
				shelfPosY = 154 / 500 * height

				testTubeSpacing = (64  / 490) * shelfWidth
				testTubeWidth, testTubeHeight = GAMEMODE.Render.FitMaterial ASSETS.test_tube, 34 / 500 * width, height
				testTubeStartX  = (shelfWidth / 2) - ((testTubeSpacing * 4 / 2) + (testTubeWidth / 2))
				testTubeStartY = 0

				nozzleWidth, nozzleHeight = GAMEMODE.Render.FitMaterial ASSETS.nozzle, 38 / 504 * width, 40 / 504 * width
				nozzleOffsetX = (width / 2) - ((testTubeSpacing * 4 / 2) + (nozzleWidth / 2))
				nozzleOffsetY = topPanelHeight - (nozzleHeight * 0.1)

				-- Top label.
				-- Cannot be assigned text to.
				with \Add "Panel"
					labelWidth  = (197 / 504) * topPanelWidth
					labelHeight = (20  / 58 ) * topPanelHeight
					labelPositionX = (topPanelWidth  / 2) - (labelWidth / 2)
					labelPositionY = (topPanelHeight / 2) - (labelHeight / 2)

					surface.CreateFont "NMW AU Inspect Top", {
						font: "Lucida Console"
						size: labelHeight
					}

					\SetSize labelWidth     , labelHeight
					\SetPos  labelPositionX , labelPositionY
					\SetZPos 10

					with \Add "DLabel"
						\SetSize \GetParent!\GetSize!
						\SetContentAlignment 4

						\SetFont "NMW AU Inspect Top"
						\SetColor Color 0, 255, 0
						.Think = ->
							time = math.max 0, @GetTimeout! - CurTime!
							\SetText tostring if @GetCompleted!
								TRANSLATE "tasks.inspectSample.thankYou"
							elseif @GetCurrentStep! == 2 and time > 0
								TRANSLATE("tasks.inspectSample.eta") math.floor time
							elseif failTime ~= 0
								TRANSLATE "tasks.inspectSample.badResult"
							else
								""

				-- Bottom label.
				-- Can be assigned text to.
				local bottomLabel
				with \Add "Panel"
					labelWidth  = (278 / 504) * bottomPanelWidth
					labelHeight = (28  / 111 ) * bottomPanelHeight
					labelPositionX = bottomPanelPosX + (bottomPanelWidth  / 2) - (labelWidth / 2)
					labelPositionY = bottomPanelPosY + (78 / 111 * bottomPanelHeight) - (labelHeight / 2)

					surface.CreateFont "NMW AU Inspect Bottom", {
						font: "Lucida Console"
						size: labelHeight * 0.9
						weight: 500
					}

					\SetSize labelWidth     , labelHeight
					\SetPos  labelPositionX , labelPositionY
					\SetZPos 10

					bottomLabel = with \Add "DLabel"
						\SetSize 0, labelHeight
						\SetContentAlignment 5

						\SetFont "NMW AU Inspect Bottom"
						\SetColor Color 0, 255, 0

						move = (state = true) ->
							currentWidth = \GetSize!

							if currentWidth > labelWidth
								callback = -> move not state

								length = 0.025 * #\GetText!

								if state
									\MoveTo labelWidth - currentWidth, 0, length, 1, nil, callback
								else
									\MoveTo 0, 0, length, 1, nil, callback

						.oldSetText = .SetText
						.SetText = (...) =>
							@oldSetText ...

							@NewAnimation 0, 0, 0, ->
								@SizeToContentsX!
								@SetWide @GetWide! * 1.025

								currentX = @GetPos!

								-- I hate this. I really didn't want to find a better way.
								-- I **need** to call MoveTo to reset previous animations since
								-- Garry's Mod doesn't give me a way of resetting them otherwise.
								\SetPos(1) if currentX == 0
								@NewAnimation 0, 0, 0, ->
									@MoveTo 0, 0, 0.25, nil, nil, move

						\SetText tostring TRANSLATE "tasks.inspectSample.hello"

				-- Paints test tubes depending on the current anomaly value.
				paintTestTubesAnomaly = ->
					for i = 1, 5
						testTubes[i]\SetColor if i == @GetAnomaly!
							Color 255, 0, 0
						else
							Color 0, 0, 255

					bottomLabel\SetText tostring TRANSLATE "tasks.inspectSample.selectAnomaly"

				-- Sets up the timeout checker.
				-- This is why we can't have nice things.
				setupCheckThink = ->
					.Think = ->
						return if @GetCurrentStep! ~= 2
						return if @GetTimeout! > CurTime!

						surface.PlaySound SOUNDS.appear
						shelf\MoveTo shelfPosX, shelfPosY, 1, 0.5, 0.3, ->
							@shelfVisible = true

						paintTestTubesAnomaly!

						.Think = nil

				-- Let's create the shelf.
				shelf = with \Add "DImage"
					\SetMaterial ASSETS.shelf
					\SetSize shelfWidth, shelfHeight

					-- If the task is in progress, hide the shelf.
					if @GetCurrentStep! == 2 and (@GetTimeout! - CurTime! > 0)
						setupCheckThink!

						\SetPos shelfPosX, bottomPanelPosY
						@shelfVisible = false

						bottomLabel\SetText tostring TRANSLATE "tasks.inspectSample.randomText"

					-- Or, if the shelf isn't visible, pop it up.
					elseif not @shelfVisible
						\SetPos shelfPosX, bottomPanelPosY
						\MoveTo shelfPosX, shelfPosY, 1, 0.5, 0.3, ->
							@shelfVisible = true

							if @GetCurrentStep! == 1
								bottomLabel\SetText tostring TRANSLATE "tasks.inspectSample.pressToStart"

						surface.PlaySound SOUNDS.appear

					-- Otherwise just put it where it belongs.
					else
						\SetPos shelfPosX, shelfPosY
						bottomLabel\SetText tostring TRANSLATE "tasks.inspectSample.pressToStart"

					-- Rack back.
					with \Add "DImage"
						\SetSize shelfWidth, shelfHeight
						\SetMaterial ASSETS.rack_back


					-- Create test tubes.
					for i = 1, 5
						with \Add "DImage"
							\SetSize testTubeWidth, testTubeHeight
							\SetPos testTubeStartX + (i - 1) * testTubeSpacing, 0
							\SetMaterial ASSETS.test_tube

					-- Create a fluid per test tube.
					for i = 1, 5
						table.insert testTubes, with \Add "DPanel"
							\SetSize testTubeWidth, testTubeHeight
							\SetPos testTubeStartX + (i - 1) * testTubeSpacing, 0

							color = Color 255, 255, 255
							.SetColor = (value) => color = value
							.GetColor = => color

							.Paint = (_, w, h) ->
								surface.SetAlphaMultiplier 0.5
								render.PushFilterMag TEXFILTER.ANISOTROPIC
								render.PushFilterMin TEXFILTER.ANISOTROPIC

								surface.SetMaterial ASSETS.fluid
								surface.SetDrawColor color
								surface.DrawTexturedRect 0, 0, w, h

								render.PopFilterMin!
								render.PopFilterMag!
								surface.SetAlphaMultiplier 1

					-- Create rack front.
					with \Add "DImage"
						\SetSize shelfWidth, shelfHeight
						\SetMaterial ASSETS.rack_front

					-- Paint the test tubes if the task in progress.
					if @GetCurrentStep! == 2 and (@GetTimeout! - CurTime! < 0)
						paintTestTubesAnomaly!

				-- Create the floating nozzle.
				nozzle = with \Add "DImage"
					\SetSize nozzleWidth   , nozzleHeight
					\SetPos  nozzleOffsetX , nozzleOffsetY
					\SetMaterial ASSETS.nozzle

				-- Create the top panel.
				with \Add "DImage"
					\SetSize topPanelWidth, topPanelHeight
					\SetMaterial ASSETS.top_panel

				-- Create the bottom panel.
				with \Add "DImage"
					\SetPos bottomPanelPosX, bottomPanelPosY
					\SetSize bottomPanelWidth, bottomPanelHeight
					\SetMaterial ASSETS.bottom_panel

				buttonWidth, buttonHeight = GAMEMODE.Render.FitMaterial ASSETS.square_button, (32 / 500) * bottomPanelWidth, (32 / 500) * bottomPanelWidth
				buttonPositionX = bottomPanelPosX + (418 / 500 * bottomPanelWidth ) - (buttonWidth  / 2)
				buttonPositionY = bottomPanelPosY + (155 / 228 * bottomPanelHeight) - (buttonHeight / 2)

				-- Create the start button.
				with \Add "DImageButton"
					\SetPos buttonPositionX, buttonPositionY
					\SetSize buttonWidth, buttonHeight

					\SetMaterial ASSETS.square_button

					.DoClick = -> with nozzle
						-- Bail if completed.
						return if @GetCompleted!

						-- Return if the shelf isn't visible.
						return unless @shelfVisible

						-- Return if there's an anomaly.
						return if @GetAnomaly! ~= 0

						-- Return if the step is 2.
						-- This means that the player has already clicked the button.
						return if @GetCurrentStep! == 2

						-- Update the label.
						bottomLabel\SetText tostring TRANSLATE "tasks.inspectSample.addingReagent"

						-- Set the current step on the client side.
						-- We shouldn't be messing with netvars on the client side, but here we are.
						@SetCurrentStep 2

						-- Play the sound and submit the task.
						surface.PlaySound SOUNDS.button
						base\Submit false

						-- Hide the shelf so it doesn't pop up the next time the player opens the UI.
						@shelfVisible = false

						-- Setup dumb animation stuff.
						initialDelay      = 0.5
						delayBetweenSteps = 0.35
						step, maxSteps    = 0, 6

						-- Animate.
						callback = ->
							currentX, currentY = \GetPos!

							-- If we're at 0, just wait.
							if step == 0
								\NewAnimation initialDelay, 0, 0, callback

							else
								-- If beaker #step exists, then paint it blue.
								-- Why am I null-checking this, again?
								if testTubes[step]
									testTubes[step]\SetColor Color 0, 0, 255
									surface.PlaySound SOUNDS.liquid

								-- Move onto the next beaker.
								if step <= maxSteps - 2
									\MoveTo currentX + testTubeSpacing, currentY,
										delayBetweenSteps, 0.1, -1, callback

								-- Move back to the original position.
								elseif step == maxSteps - 1
									bottomLabel\SetText tostring TRANSLATE "tasks.inspectSample.randomText"

									\MoveTo nozzleOffsetX, nozzleOffsetY, 1, 0.5, -1, callback

								-- Hide the shelf.
								elseif step == maxSteps
									surface.PlaySound SOUNDS.appear
									shelf\MoveTo shelfPosX, shelfPosY + shelfHeight * 1.5, 2, 0.5, 0.3, ->
										-- Set off the think hook to check the timeout.
										-- This is bad, yet here we are.
										setupCheckThink!

							step += 1

						callback!

				-- Create circly buttons under the test tubes.
				circleButtonWidth, circleButtonHeight = GAMEMODE.Render.FitMaterial ASSETS.circle_button, (32 / 500) * bottomPanelWidth, (32 / 500) * bottomPanelWidth

				circleOffsetX = bottomPanelPosX + (width / 2) - ((testTubeSpacing * 4 / 2) + (circleButtonWidth / 2))
				circleOffsetY = bottomPanelPosY + ((30 / 114) * bottomPanelHeight) - (circleButtonHeight / 2)

				circleButtons = {}

				for i = 1, 5
					table.insert circleButtons, with \Add "DImageButton"
						\SetMaterial ASSETS.circle_button
						\SetPos circleOffsetX + (i - 1) * testTubeSpacing, circleOffsetY
						\SetSize circleButtonWidth, circleButtonHeight

						-- Handle the circly button press.
						.DoClick = ->
							-- Bail if completed.
							return if @GetCompleted!

							-- Bail if there are no anomalies.
							return if @GetAnomaly! == 0

							-- Bail if the task is still going.
							return if CurTime! < @GetTimeout!

							-- Return if failTime is set.
							return if failTime ~= 0

							-- If incorrect, play the sound and set off the fail animation.
							if i ~= @GetAnomaly!
								surface.PlaySound SOUNDS.fail
								failTime = SysTime! + 1.5
								bottomLabel\SetText tostring TRANSLATE "tasks.inspectSample.badResult"

								-- Hide the shelf.
								@shelfVisible = false
								surface.PlaySound SOUNDS.appear
								shelf\MoveTo shelfPosX, shelfPosY + shelfHeight * 1.5, 1, 0.5, 0.3, ->
									bottomLabel\SetText tostring TRANSLATE "tasks.inspectSample.oneMore"
									failTime = 0

									-- Once the shelf has been hidden, reset all circly buttons.
									for circleButton in *circleButtons
										circleButton\SetColor Color 255, 255, 255

									-- Reset all test tubes.
									for beaker in *testTubes
										beaker\SetColor Color 255, 255, 255

									-- Unhide the shelf.
									surface.PlaySound SOUNDS.appear
									shelf\MoveTo shelfPosX, shelfPosY, 2, 0.25, 0.3, ->
										@shelfVisible = true
										bottomLabel\SetText tostring TRANSLATE "tasks.inspectSample.pressToStart"

							-- If correct, just play the sound.
							else
								-- Set completed on the client side to make the lives
								-- of laggy players better.
								@SetCompleted true

								surface.PlaySound SOUNDS.button
								bottomLabel\SetText tostring TRANSLATE "tasks.inspectSample.testComplete"

							base\Submit i == @GetAnomaly!, i

						color = Color 255, 255, 255
						.Think = ->
							-- We only want to mess with the color when the task is waiting
							-- for the player to submit the result, or when the player
							-- has made an error selecting the anomaly.
							return unless failTime ~= 0 or (@GetAnomaly! ~= 0 and @GetTimeout! < CurTime!)

							with color
								-- If the fail time is a thing, blink.
								-- Otherwise make the buttons "breathe".
								.r, .g, .b = if failTime <= SysTime! or (failTime > SysTime! and (math.floor(SysTime! * 8) % 2 ~= 0))
									t = 0.5 * (1 + math.sin SysTime!)

									rb = Lerp t, 255, 128
									g  = Lerp t, 255, 255

									rb, g, rb
								else
									255, 80, 80

							\SetColor color

			\Popup!

		return base

return taskTable
