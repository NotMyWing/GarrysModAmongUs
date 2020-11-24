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
		"button"
		"circlebutton"
		"fluid"
		"glassback"
		"glassfront"
		"glassshelf"
		"overlay"
		"thing"
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
				@shelfVisible = false
				local shelf
				failTime = 0
				beakers = {}

				max_size = ScrH! * 0.8

				width, height = GAMEMODE.Render.FitMaterial ASSETS.background,
					max_size, max_size

				\SetSize width, height
				\SetMaterial ASSETS.background

				-- That's a LOT of hard-coded things, man.
				shelfPosX   = (8   / 506) * width
				shelfPosY   = (160 / 502) * height

				shelfWidth  = (490 / 506) * width
				shelfHeight = (225 / 502) * height

				fluidWidth   = (30  / 506) * width
				fluidHeight  = (87  / 502) * height
				fluidStartX  = (104 / 506) * width
				fluidStartY  = (48  / 502) * height
				fluidSpacing = (63  / 506) * width

				thingWidth   = (41 / 506) * width
				thingHeight  = (43 / 502) * height
				thingOffsetX = (shelfPosX + fluidStartX + fluidWidth / 2) - thingWidth / 2
				thingOffsetY = (58 / 502) * height

				-- Top label.
				-- Cannot be assigned text to.
				with \Add "Panel"
					labelPositionX = (155 / 506) * width
					labelPositionY = (19  / 502) * height
					labelWidth  = (197 / 506) * width
					labelHeight = (20  / 502) * height

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
					labelPositionX = (114 / 506) * width
					labelPositionY = (450 / 502) * height
					labelWidth  = (278 / 506) * width
					labelHeight = (28  / 502) * height

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

				-- Paints beakers depending on the current anomaly value.
				paintBeakersAnomaly = ->
					for i = 1, 5
						beakers[i]\SetColor if i == @GetAnomaly!
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

						paintBeakersAnomaly!

						.Think = nil

				-- Let's create the shelf.
				shelf = with \Add "DImage"
					\SetMaterial ASSETS.glassshelf
					\SetSize shelfWidth, shelfHeight

					-- If the task is in progress, hide the shelf.
					if @GetCurrentStep! == 2 and (@GetTimeout! - CurTime! > 0)
						setupCheckThink!

						\SetPos shelfPosX, shelfPosY + shelfHeight * 1
						@shelfVisible = false

						bottomLabel\SetText tostring TRANSLATE "tasks.inspectSample.randomText"

					-- Or, if the shelf isn't visible, pop it up.
					elseif not @shelfVisible
						\SetPos shelfPosX, shelfPosY + shelfHeight * 1
						\MoveTo shelfPosX, shelfPosY, 1, 0.5, 0.3, ->
							@shelfVisible = true

							if @GetCurrentStep! == 1
								bottomLabel\SetText tostring TRANSLATE "tasks.inspectSample.pressToStart"

						surface.PlaySound SOUNDS.appear

					-- Otherwise just put it where it belongs.
					else
						\SetPos shelfPosX, shelfPosY
						bottomLabel\SetText tostring TRANSLATE "tasks.inspectSample.pressToStart"

					-- Glass, background.
					with \Add "DImage"
						\SetSize shelfWidth, shelfHeight
						\SetMaterial ASSETS.glassback

					-- Glass and beakers, front.
					with \Add "DImage"
						\SetSize shelfWidth, shelfHeight
						\SetMaterial ASSETS.glassfront

						-- Create a fluid per beaker.
						for i = 1, 5
							table.insert beakers, with \Add "DPanel"
								\SetSize fluidWidth, fluidHeight
								\SetPos fluidStartX + (i - 1) * fluidSpacing, fluidStartY

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

					-- Paint the beakers if the task in progress.
					if @GetCurrentStep! == 2 and (@GetTimeout! - CurTime! < 0)
						paintBeakersAnomaly!

				-- Create the floating "thing".
				-- I have no idea how it's called.
				thing = with \Add "DImage"
					\SetSize thingWidth   , thingHeight
					\SetPos  thingOffsetX , thingOffsetY
					\SetMaterial ASSETS.thing

				-- Create the overlay.
				with \Add "DImage"
					\SetSize width, height
					\SetMaterial ASSETS.overlay

				buttonPositionX = (406 / 506) * width
				buttonPositionY = (449 / 502) * height
				buttonSize      = (32  / 502) * height

				-- Create the start button.
				with \Add "DImageButton"
					\SetPos buttonPositionX, buttonPositionY
					\SetSize buttonSize, buttonSize

					\SetMaterial ASSETS.button

					.DoClick = -> with thing
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
								if beakers[step]
									beakers[step]\SetColor Color 0, 0, 255
									surface.PlaySound SOUNDS.liquid

								-- Move onto the next beaker.
								if step <= maxSteps - 2
									\MoveTo currentX + fluidSpacing, currentY,
										delayBetweenSteps, 0.1, -1, callback

								-- Move back to the original position.
								elseif step == maxSteps - 1
									bottomLabel\SetText tostring TRANSLATE "tasks.inspectSample.randomText"

									\MoveTo thingOffsetX, thingOffsetY, 1, 0.5, -1, callback

								-- Hide the shelf.
								elseif step == maxSteps
									surface.PlaySound SOUNDS.appear
									shelf\MoveTo shelfPosX, shelfPosY + shelfHeight * 1.5, 2, 0.5, 0.3, ->
										-- Set off the think hook to check the timeout.
										-- This is bad, yet here we are.
										setupCheckThink!

							step += 1

						callback!

				-- Create circly buttons under the beakers.
				circleSize    = (32 / 502) * height

				circleOffsetX = (shelfPosX + fluidStartX + fluidWidth / 2) - circleSize / 2
				circleOffsetY = (406 / 502) * height

				circleButtons = {}

				for i = 1, 5
					table.insert circleButtons, with \Add "DImageButton"
						\SetMaterial ASSETS.circlebutton
						\SetPos circleOffsetX + (i - 1) * fluidSpacing, circleOffsetY
						\SetSize circleSize, circleSize

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

									-- Reset all beakers.
									for beaker in *beakers
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
