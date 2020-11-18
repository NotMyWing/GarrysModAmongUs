taskTable = {
	Name: "alignEngineOutput"
	Type: GM.TaskType.Short
	Init: =>
		@Base.Init @

		if SERVER
			@buttons = GAMEMODE.Util.FindEntsByTaskName @Name
			@SetMaxSteps #@buttons

			@SetActivationButton @buttons[@GetCurrentStep!]

	OnAdvance: =>
		step = @GetCurrentStep!

		if step >= @GetMaxSteps!
			@SetCompleted true
		else
			@SetCurrentStep step + 1
			@SetActivationButton @buttons[step + 1]
}

if CLIENT
	ASSETS_DIR = "au/gui/tasks/alignengineoutput/"
	ASSETS = {
		base:         Material ASSETS_DIR .. "base.png"        , "smooth"
		dottedline:   Material ASSETS_DIR .. "dottedline.png"  , "smooth noclamp"
		engine:       Material ASSETS_DIR .. "engine.png"      , "smooth"
		slider:       Material ASSETS_DIR .. "slider.png"      , "smooth"
		slidershadow: Material ASSETS_DIR .. "slidershadow.png", "smooth"
	}

	SUBMIT_TRESHOLD = 0.75

	taskTable.CreateVGUI = =>
		base = vgui.Create "AmongUsTaskBase"

		with base
			\Setup with vgui.Create "Panel"
				local submitTime, submitted
				theta = 0

				maxSize = 0.8 * math.min ScrH!, ScrW!

				panelWidth, panelHeight = GAMEMODE.Render.FitMaterial ASSETS.base, maxSize, maxSize
				\SetSize panelWidth, panelHeight

				-- Check the submit time and submit the task if above 1 second.
				.Think = ->
					if not submitted and submitTime and (SysTime! - submitTime > 1)
						submitted = true

						base\Submit!
						@__sliderPosition = nil

				window = with \Add "DPanel"
					windowPosX   = (32  / 500) * panelWidth
					windowPosY   = (30  / 500) * panelHeight
					windowWidth  = (316 / 500) * panelWidth
					windowHeight = (442 / 500) * panelHeight

					engineSpriteWidth  = (381 / 500) * panelWidth
					engineSpriteHeight = (189 / 500) * panelHeight

					dottedLineWidth  = (20 / 500) * panelWidth
					dottedLineHeight = (5  / 500) * panelHeight

					\SetPos  windowPosX  , windowPosY
					\SetSize windowWidth , windowHeight

					\SetBackgroundColor Color 12, 30, 12

					.PaintOver = (_, w, h) ->
						-- Engine.
						do
							-- Setup the rotation matrix.
							ltsx, ltsy = _\LocalToScreen 0, 0
							ltsv = Vector ltsx, ltsy, 0
							v = Vector w, h / 2

							m = with Matrix!
								\Translate ltsv
								\Translate v
								\Rotate Angle 0, 2.5 * theta, 0
								\Translate -v
								\Translate -ltsv

							surface.DisableClipping true
							cam.PushModelMatrix m, true

							-- Setup scissor.
							-- Garry's Mod is dumb and rotates the clipping area as well,
							-- so scissoring the engine sprite manually is a must.
							scissorX, scissorY = _\LocalToScreen 0, 0
							render.SetScissorRect scissorX, scissorY,
								scissorX + w, scissorY + h, true

							surface.SetDrawColor if submitTime and (SysTime! - submitTime > 1)
								0, 255, 0
							else
								255, 0, 0

							surface.SetMaterial ASSETS.engine
							surface.DrawTexturedRect -(engineSpriteWidth - windowWidth), h / 2 - engineSpriteHeight / 2,
								engineSpriteWidth, engineSpriteHeight

							render.SetScissorRect 0, 0, 0, 0, false
							cam.PopModelMatrix!
							surface.DisableClipping false

						-- Dotted line.
						do
							surface.SetDrawColor if SUBMIT_TRESHOLD > math.abs theta
								0, 255, 0
							else
								255, 0, 0

							offsetX = (SysTime!) % 1

							surface.SetMaterial ASSETS.dottedline
							surface.DrawTexturedRectUV 0, h / 2 - dottedLineHeight / 2,
								w, dottedLineHeight,
								offsetX, 0,
								offsetX + w / dottedLineWidth, 1

						-- Submit lines.
						if submitTime and (SysTime! - submitTime > 0.25) and (SysTime! - submitTime < 1)
							-- Blink
							return if (math.floor(SysTime! * 8) % 2 == 0)

							for i = 1, 2
								sign = (i == 1) and -1 or 1

								surface.SetDrawColor 255, 255, 255

								offsetX = (SysTime!) % 1

								surface.SetMaterial ASSETS.dottedline
								surface.DrawTexturedRectUV 0, h / 2 - dottedLineHeight / 2 + sign * engineSpriteHeight / 2,
									w, dottedLineHeight,
									offsetX, 0,
									offsetX + w / dottedLineWidth, 1

				overlay = with \Add "DImage"
					\Dock FILL
					\SetMaterial ASSETS.base
					\SetMouseInputEnabled true

					sliderArea = with \Add "DPanel"
						sliderAreaPosX   = (356  / 500) * panelWidth
						sliderAreaPosY   = (24  / 500)  * panelHeight
						sliderAreaWidth  = (124 / 500)  * panelWidth
						sliderAreaHeight = (450 / 500)  * panelHeight

						sliderHeight = (52  / 500) * panelHeight

						\SetPos  sliderAreaPosX  , sliderAreaPosY   - sliderHeight / 2
						\SetSize sliderAreaWidth , sliderAreaHeight + sliderHeight

						-- Create a slider.
						-- This is not the actual knob that's getting drawn, but instead
						-- a hitbox the player can interact with. The actual knob is being drawn
						-- as a part of the slider area.
						slider = with \Add "DButton"
							\SetText ""
							\SetSize sliderAreaWidth, sliderHeight
							.Paint = ->

							setPosition = (newY) ->
								currentX = \GetPos!

								newY = math.Clamp newY,
									sliderHeight / 2, sliderAreaHeight - sliderHeight / 2

								\SetPos currentX, newY
								@__sliderPosition = newY

							isDragged = false
							cursorClickOffsetY = 0

							-- Handle the slider being pressed.
							.OnDepressed = ->
								if not submitTime or (SysTime! - submitTime < 1)
									submitTime = nil
									isDragged = true
									_, cursorClickOffsetY = \LocalCursorPos!

							-- Handle the slider being released.
							.OnReleased = ->
								if not submitTime
									isDragged = false
									if SUBMIT_TRESHOLD > math.abs theta
										submitTime = SysTime!

							-- If the player is holding the slider, make it follow the cursor.
							.Think = ->
								if isDragged
									_, cursorPosY = sliderArea\LocalCursorPos!
									setPosition cursorPosY - cursorClickOffsetY

							-- Set the initial knob position.
							-- If the player has interacted with the UI before, use the last location.
							-- Otherwise toss a coin and pick a random position.
							setPosition if @__sliderPosition
								@__sliderPosition
							else
								coin = 0.5 > math.random!
								if coin
									math.random sliderHeight / 2, sliderAreaHeight / 2 - sliderHeight * 3
								else
									math.random sliderAreaHeight / 2 + sliderHeight * 3, sliderAreaHeight - sliderHeight / 2

							-- Try submit immediately in case the player has pre-fired closing the UI.
							\NewAnimation 0.25, 0, 0, ->
								\OnReleased!

						-- Slider area paint.
						circlePositionX = (700 / 500) * panelWidth
						circlePositionY = panelHeight / 2
						circleRadius    = panelWidth

						sliderSpriteHeight = sliderHeight * 0.8

						sliderSpriteWidth, sliderSpriteHeight = GAMEMODE.Render.FitMaterial ASSETS.slider,
							sliderAreaWidth, sliderSpriteHeight

						-- Draw the actual slider and calculate the theta value.
						-- The theta value is defined a couple scopes above, so
						-- the value will get exposed to every panel parented to the entire task UI.
						.Paint = (_, w, h) ->
							sliderPosX, sliderPosY = slider\GetPos!
							sliderPosX += sliderSpriteWidth
							sliderPosY += sliderHeight / 2

							theta = math.deg math.atan2 circlePositionY - sliderPosY,
								circlePositionX - sliderPosX

							-- Prepare the rotation matrix.
							ltsx, ltsy = _\LocalToScreen 0, 0
							ltsv = Vector ltsx, ltsy, 0
							v = Vector circlePositionX, circlePositionY

							m = with Matrix!
								\Translate ltsv
								\Translate v
								\Rotate Angle 0, theta, 0
								\Translate -v
								\Translate -ltsv

							surface.DisableClipping true
							cam.PushModelMatrix m, true

							surface.SetDrawColor 255, 255, 255

							-- Shadow.
							surface.SetMaterial ASSETS.slidershadow
							surface.DrawTexturedRect 0, sliderSpriteHeight * 0.1 + h / 2 - sliderSpriteHeight / 2,
									sliderSpriteWidth, sliderSpriteHeight

							-- Knob.
							surface.SetMaterial ASSETS.slider
							surface.DrawTexturedRect 0, h / 2 - sliderSpriteHeight / 2,
									sliderSpriteWidth, sliderSpriteHeight

							cam.PopModelMatrix!
							surface.DisableClipping false

			\Popup!

		return base

return taskTable
