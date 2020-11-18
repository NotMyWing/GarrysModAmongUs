taskTable = {
	Name: "fixWiring"
	Type: GM.TaskType.Common
	Init: =>
		@Base.Init @

		if SERVER
			-- Find all task buttons on the map, shuffle and select up to the first three.
			@__taskButtons = [button for button in *GAMEMODE.Util.Shuffle(GAMEMODE.Util.FindEntsByTaskName @Name)[, 3]]
			@SetMaxSteps #@__taskButtons

			-- Sort buttons depending on the custom data.
			table.sort @__taskButtons, (a, b) ->
				(tonumber(a\GetCustomData!) or 0) < (tonumber(b\GetCustomData!) or 0)

			-- Make the first button the activation button and pop it.
			@SetActivationButton @__taskButtons[1]
			table.remove @__taskButtons, 1

	OnAdvance: =>
		currentStep = @GetCurrentStep!

		-- The player has submitted all steps. Complete the task.
		if currentStep == @GetMaxSteps!
			@SetCompleted true

		-- The player has submitted a step. Pop a button and advance.
		else
			@SetActivationButton @__taskButtons[1], true
			table.remove @__taskButtons, 1

			@SetCurrentStep currentStep + 1
}

if CLIENT
	ASSETS = {
		bg: Material "au/gui/tasks/fixWiring/bg.png", "smooth"
		wire: Material "au/gui/tasks/fixWiring/wire.png", "smooth"
		wireEnd: Material "au/gui/tasks/fixWiring/wireTip.png", "smooth"
		wireEndBg: Material "au/gui/tasks/fixWiring/wireTipBg.png", "smooth"
	}

	WIRE_SOUND = ["au/panel_electrical_wire#{i}.wav" for i = 1, 3]

	taskTable.CreateVGUI = =>
		base = vgui.Create "AmongUsTaskBase"

		return with base
			\SetAppearSound "au/panel_electricalwiresopen.wav"
			\SetDisappearSound "au/panel_electricalwiresclose.wav"
			\Setup with vgui.Create "DImage"
				max_size = ScrH! * 0.8

				width, height = GAMEMODE.Render.FitMaterial ASSETS.bg, max_size, max_size

				\SetSize width, height
				\SetMaterial ASSETS.bg

				completed = false
				indicators = {}
				wires = {{}, {}}

				wireColors = {
					Color 255, 235, 4
					Color 0, 0, 255
					Color 255, 0, 0
					Color 255, 0, 255
				}

				wires = {
					GAMEMODE.Util.Shuffle { 1, 2, 3, 4 }
					GAMEMODE.Util.Shuffle { 1, 2, 3, 4 }
				}

				-- Create indicators.
				do
					-- Obligatory hard-coded stuff.
					indicatorWidth = (31 / 504)
					indicatorHeight = (12 / 504)
					colorA = Color 219, 202, 3
					colorB = Color 235, 217, 4
					colorOff = Color 33, 33, 33

					for i = 1, 4
						yOffset = (80 + (i - 1) * 104) / 504
						for j = 1, 2
							xOffset = if j == 1
								4/504
							else
								470/504

							with indicator = \Add "DPanel"
								\SetSize indicatorWidth * width, indicatorHeight * height
								\SetPos xOffset * width, yOffset * height

								-- Make all left indicators always active.
								.active = j == 1
								if j == 2
									indicators[wires[j][i]] = indicator

								.Paint = (_, w, h) ->
									-- Make the indicator flicker between two colors if it's active.
									surface.SetDrawColor if .active
										math.random! > 0.5 and colorA or colorB
									else
										colorOff

									surface.DrawRect 0, 0, w, h

				-- Create wires.
				do
					-- Obligatory hard-coded stuff.
					wireWidth  = (48 / 504) * width
					wireHeight = (18 / 504) * height

					hitboxWidth  = ((32 * 3) / 504) * width
					hitboxHeight = ((18 * 3) / 504) * height

					wireEndWidth  = (40 / 504) * width
					wireEndHeight = (27 / 504) * height

					wireEndBgWidth = (16 / 504) * width
					tipOffset = (4 / 504) * width

					local hover

					for i = 1, 4
						-- Determine the Y position of the wire.
						yOffset = (95 + (i - 1) * 104) / 504
						yOffset *= height

						for j = 1, 2
							local snap, wire

							-- Determine the X position of the wire.
							xOffset = if j == 1
								4/504
							else
								(504 - 50)/504

							xOffset *= width

							-- Determine the hitbox origin.
							originX = if j == 1
								wireWidth + wireEndBgWidth / 1.6 + wireEndWidth / 2
							else
								-wireEndBgWidth / 1.6 - wireEndWidth / 2

							originY = wireHeight / 2

							-- Create the hitbox.
							-- This is what you will click and drag.
							hitbox = with \Add "DButton"
								.__id = wires[j][i]

								\SetSize hitboxWidth, hitboxHeight
								\SetText ""

								hitX = originX + xOffset - (hitboxWidth / 2)
								hitY = originY + yOffset - (hitboxHeight / 2)

								\SetPos hitX, hitY
								\SetMouseInputEnabled true

								.Paint = ->

								if j == 1
									.OnMousePressed = (_) ->
										return if completed

										.__dragging = true

										-- Reset the hitbox position, snap and indicator state.
										hitbox\SetPos hitX, hitY
										indicators[.__id].active = false
										snap = nil

										-- Bubble both the wire and hitbox panels.
										wire\MoveToFront!
										hitbox\MoveToFront!

									.Think = ->
										if .__dragging and not input.IsMouseDown MOUSE_LEFT
											.__dragging = false

											if IsValid hover
												snap = hover

												-- Play a sound and move the hitbox to the new position.
												hitbox\SetPos snap\GetPos!
												hitbox\MoveToFront!
												surface.PlaySound table.Random WIRE_SOUND

												-- Update the indicator and submit if all indicators are active.
												indicators[.__id].active = .__id == snap.__id

												completed = true
												for i = 1, 4
													if not indicators[i].active
														completed = false

												if completed
													base\Submit!

								else
									oldInside = false
									.Think = (_) ->
										mouseX, mouseY = _\LocalCursorPos!
										width, height = \GetSize!

										inside = mouseX > 0 and mouseY > 0 and mouseX < width and mouseY < height

										if oldInside ~= inside
											if inside     and hover ~= hitbox then hover = hitbox
											if not inside and hover == hitbox then hover = nil

											oldInside = inside

							wire = with \Add "DPanel"
								\SetSize wireWidth, wireHeight
								\SetPos xOffset, yOffset
								if j == 1
									\SetZPos 1

								wireMat = ASSETS.wire
								wireEndMat = ASSETS.wireEnd
								wireEndBgMat = ASSETS.wireEndBg
								color = wireColors[wires[j][i]]

								.Paint = (_, w, h) ->
									dist = 0

									-- Draw the wire base.
									surface.DisableClipping true
									surface.SetDrawColor color
									surface.SetMaterial wireMat
									surface.DrawTexturedRect j == 1 and 0 or -w * 0.05, 0, w * 1.1, h

									local matrixPushed
									if IsValid(snap) or hitbox.__dragging
										ltsx, ltsy = _\LocalToScreen 0, 0

										local targetX, targetY

										-- Determine the target coordinate.
										-- The first found point is prioritized:
										-- 1) snapped hitbox
										-- 2) hovered hitbox
										-- 3) cursor pos
										if IsValid(snap) or IsValid(hover)
											hW, hH = (snap or hover)\GetSize!
											targetX, targetY = (snap or hover)\LocalToScreen hW/2, hH/2
										else
											targetX, targetY = input.GetCursorPos!

										-- Calculate the distance between the origin and target.
										-- Bail if under threshold.
										dist = math.sqrt math.pow(ltsx + w - targetX, 2) + math.pow(ltsy + originY - targetY, 2)
										if dist > max_size * 0.035
											m = Matrix!
											ltsv = Vector ltsx + w, ltsy + originY, 0

											-- Calculate the angle between the origin and target.
											th = math.deg math.atan2 targetX - ltsv.x, targetY - ltsv.y

											-- Rotate.
											m\Translate ltsv
											m\Rotate Angle 0, 360 - 0.995 * (th - 90), 0
											m\Translate -ltsv

											-- Push and tell the following code that a matrix has been pushed.
											cam.PushModelMatrix m
											matrixPushed = true
										else
											dist = 0

									-- This entire block is just bad, but https://i.imgur.com/U15slgm.png

									-- Left wires.
									if j == 1
										if dist ~= 0
											surface.DrawTexturedRect w, 0, dist - wireEndWidth / 2 + wireEndBgWidth / 1.6, h

										-- If the matrix has been pushed, draw the wire extending from the origin.
										if matrixPushed
											surface.SetMaterial wireEndBgMat
											surface.DrawTexturedRect w + dist - wireEndWidth / 2, 0,
												wireEndBgWidth, h

											surface.SetMaterial wireEndMat
											surface.SetDrawColor Color 255, 255, 255
											surface.DrawTexturedRect w + dist - wireEndWidth / 2 + wireEndBgWidth / 1.6, h/2 - wireEndHeight / 2,
												wireEndWidth, wireEndHeight

										-- Otherwise just draw it as usually.
										else
											surface.SetMaterial wireEndBgMat
											surface.DrawTexturedRect w + dist, 0,
												wireEndBgWidth, h

											surface.SetMaterial wireEndMat
											surface.SetDrawColor Color 255, 255, 255
											surface.DrawTexturedRect w + dist + wireEndBgWidth / 2, h/2 - wireEndHeight / 2,
												wireEndWidth, wireEndHeight

									-- Right wires.
									-- Yes, I already tried to reuse the code, but ended up littering it with
									-- so many ternaries it became completely unreadable.
									else
										surface.SetMaterial wireEndBgMat
										surface.DrawTexturedRectUV -wireEndBgWidth, 0,
											wireEndBgWidth, h, 1, 0, 0, 1

										surface.SetMaterial wireEndMat
										surface.SetDrawColor Color 255, 255, 255
										surface.DrawTexturedRectUV -wireEndWidth - wireEndBgWidth / 1.6, h/2 - wireEndHeight / 2,
											wireEndWidth, wireEndHeight, 1, 0, 0, 1

									surface.DisableClipping false

									if matrixPushed
										cam.PopModelMatrix!

			\Popup!

return taskTable
