taskTable = {
	Name: "calibrateDistributor"
	Type: GM.TaskType.Short
}

if CLIENT
	ROTATION_MATRIX = Matrix!
	circle = GM.Render.CreateCircle

	taskTable.CreateVGUI = =>
		state = @GetCurrentState!
		base = vgui.Create "AmongUsTaskBase"

		with base
			\Setup with vgui.Create "DPanel"
				max_size = ScrH! * 0.7

				height = max_size
				width = max_size

				\SetSize width, height
				.Paint = ->

				colors = {
					Color 255, 211, 58
					Color 13, 93, 255
					Color 165, 255, 255
				}

				dimColors = {}
				for _, color in ipairs colors
					with color
						table.insert dimColors, Color .r, .g, .b, 127

				left = with \Add "DPanel"
					\Dock LEFT
					\SetWide width * 0.64
					\SetBackgroundColor Color 64, 64, 64

				right = with \Add "DPanel"
					\Dock RIGHT
					\SetWide width * 0.31
					\SetBackgroundColor Color 64, 64, 64

				local rings
				local ringStatus
				local ringSubmit
				local rotations
				reset = ->
					rotations  = [math.random(180, 360) for i = 1, 3]
					rings      = [false for i = 1, 3]
					ringStatus = [false for i = 1, 3]
					ringSubmit = [false for i = 1, 3]

					rings[1] = true

				reset!

				for i = 1, 3
					with left\Add "DPanel"
						\Dock TOP
						\SetTall height / 3
						.Paint = ->

						with \Add "DPanel"
							\SetWide height / 3
							\Dock LEFT

							outerCirc      = circle height / 6, height / 6, height / 6.5, 64
							circ           = circle height / 6, height / 6, height / 7  , 64
							innerCirc      = circle height / 6, height / 6, height / 8.5, 64
							innerInnerCirc = circle height / 6, height / 6, height / 9.5, 64

							.Paint = (_, w, h) ->
								if rings[i]
									rotations[i] = (rotations[i] - FrameTime! * 120) % 360
								ringStatus[i] = 18 > math.abs 90 - rotations[i]

								draw.NoTexture!
								surface.DisableClipping true

								surface.SetDrawColor 96, 96, 96
								surface.DrawPoly outerCirc

								do
									acceptorW = w * 1.5
									acceptorH = w * 0.075

									surface.SetDrawColor 96, 96, 96
									surface.DrawRect w - w * 0.25, h/2 - acceptorH/2, acceptorW, acceptorH

									if ringStatus[i]
										acceptorH *= 0.5

										surface.SetDrawColor dimColors[i]
										surface.DrawRect w - w * 0.25, h/2 - acceptorH/2, acceptorW, acceptorH

								do
									acceptorW = w * 1.2
									acceptorH = w * 0.15

									surface.SetDrawColor 96, 96, 96
									surface.DrawRect w - w * 0.25, h/2 - acceptorH/2, acceptorW, acceptorH

									if ringStatus[i]
										acceptorH *= 0.75

										surface.SetDrawColor dimColors[i]
										surface.DrawRect w - w * 0.25, h/2 - acceptorH/2, acceptorW, acceptorH

								surface.SetDrawColor colors[i]
								surface.DrawPoly circ

								surface.SetDrawColor 96, 96, 96
								surface.DrawPoly innerCirc

								surface.SetDrawColor 64, 64, 64
								surface.DrawPoly innerInnerCirc

								ltsx, ltsy = _\LocalToScreen 0, 0
								ltsv = Vector ltsx, ltsy, 0
								v = Vector w / 2, h / 2, 0

								with ROTATION_MATRIX
									\Identity!
									\Translate ltsv
									\Translate v
									\Rotate Angle 0, rotations[i], 0
									\Translate -v
									\Translate -ltsv

								cam.PushModelMatrix ROTATION_MATRIX, true
								do
									knobW = w * 0.15
									knobH = w * 0.22

									origin = h/2 - (height/7 + height/8.5)/2

									surface.SetDrawColor 128, 128, 128
									surface.DrawRect w/2 - knobW/2, origin - knobH/2, knobW, knobH

								cam.PopModelMatrix!

								surface.DisableClipping false

					with right\Add "DPanel"
						\Dock TOP
						\SetTall height / 3
						.Paint = ->

						padding = height * 0.025
						with \Add "DPanel"
							\Dock TOP
							\DockPadding padding, padding, padding, padding
							\SetTall height / 6
							.Paint = ->
							with \Add "DPanel"
								\Dock FILL

								innerPadding = padding * 0.5
								\DockPadding innerPadding, innerPadding, innerPadding, innerPadding
								\SetBackgroundColor Color 16, 16, 16

								with \Add "DPanel"
									\Dock FILL
									.Paint = (_, w, h) ->
										w *= if ringSubmit[i]
											1
										elseif ringStatus[i]
											0.7
										else
											0.2

										w += w * 0.05 * (math.random! - 0.5)

										surface.SetDrawColor colors[i]
										surface.DrawRect 0, 0, w, h

						with \Add "DPanel"
							\Dock BOTTOM
							\DockPadding padding * 1.25, padding * 1.25, padding * 1.25, padding * 3
							\SetTall height / 6
							.Paint = ->
							with \Add "DButton"
								\SetText ""
								\Dock FILL
								.DoClick = ->
									if not ringStatus[i]
										reset!
									else
										ringSubmit[i] = true
										rings[i] = false

										if i ~= 3
											rings[i + 1] = true
										else
											base\Submit!
								.Think = ->
									\SetEnabled rings[i]


			\Popup!

		return base

return taskTable
