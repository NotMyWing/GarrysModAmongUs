taskTable = {
	Name: "chartCourse"
	Type: GM.TaskType.Short
}

if CLIENT
	taskTable.CreateVGUI = =>
		state = @GetCurrentState!
		base = vgui.Create "AmongUsTaskBase"

		with base
			\Setup with vgui.Create "DPanel"
				max_size = ScrH! * 0.8

				\SetSize max_size, max_size * 0.15

				\SetBackgroundColor Color 64, 64, 64

				position = 0.025

				pressed = false

				positions = {}
				for i = 1, 5
					table.insert positions, i / 6

				activated = {}

				treshold = 0.1
				with \Add "DPanel"
					margin = max_size * 0.05
					\DockMargin margin, margin, margin, margin
					\Dock FILL
					.Paint = (_, w, h) ->
						surface.SetDrawColor 32, 32, 32
						surface.DrawRect 0, 0, w, h

						for i, pos in ipairs positions
							if activated[i]
								surface.SetDrawColor 32, 221, 32
							else 
								surface.SetDrawColor 32, 221, 32, 64
							surface.DrawRect w*pos - w*treshold/2, 0, w*treshold, h 

				local pressed
				with \Add "DButton"
					\SetText ""
					setPos = (x) ->
						_, y = \GetPos!
						\SetPos math.Clamp x, 0, max_size - \GetWide!, y
					\SetTall max_size * 0.15
					\SetWide max_size * 0.05
					.OnMousePressed  = -> pressed = true
					.OnMouseReleased = -> pressed = false
					.Think = ->
						if pressed and not input.IsMouseDown MOUSE_LEFT
							pressed = false

						if pressed
							x = \GetParent!\LocalCursorPos!
							newpos = x - \GetWide! / 2
							setPos newpos

							if .__oldpos ~= newpos
								.__nextCheck = SysTime! + 0.25
								.__oldpos = newpos
								.__x = x

						if SysTime! > (.__nextCheck or SysTime!)
							for i, pos in ipairs positions
								if activated[i]
									continue

								dist = math.abs pos - (.__x/max_size)

								if dist < treshold / 2
									if i == 1 or activated[i - 1]
										activated[i] = true

										if i == #positions
											base\Submit!

					setPos max_size * position

			\Popup!

		return base

return taskTable
