taskTable = {
	Type: GM.TaskType.Short
	Time: 3
	Init: =>
		@Base.Init @

		if SERVER
			@buttons = GAMEMODE.Util.FindEntsByTaskName "alignEngineOutput"
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
	taskTable.CreateVGUI = =>
		base = vgui.Create "AmongUsTaskBase"

		with base
			\Setup with vgui.Create "DPanel"
				max_size = ScrH! * 0.7

				\SetSize max_size * 0.15, max_size

				\SetBackgroundColor Color 64, 64, 64

				position = ((math.random! > 0.5) and (math.random 0, 30) or (math.random 70, 100)) / 100

				pressed = false

				treshold = 0.1
				with \Add "DPanel"
					margin = max_size * 0.05
					\DockMargin margin, margin, margin, margin
					\Dock FILL
					.Paint = (_, w, h) ->
						surface.SetDrawColor 32, 32, 32
						surface.DrawRect 0, 0, w, h

						surface.SetDrawColor 32, 221, 32
						surface.DrawRect 0, h/2 - h * treshold/2, w, h * treshold

				local pressed
				with \Add "DButton"
					\SetText ""
					setPos = (y) ->
						x = \GetPos!
						\SetPos x, math.Clamp y, 0, max_size - \GetTall!
					\SetWide  max_size * 0.15
					\SetTall max_size * 0.05
					.OnMousePressed  = -> pressed = true
					.OnMouseReleased = -> pressed = false
					.Think = ->
						if pressed and not input.IsMouseDown MOUSE_LEFT
							pressed = false

						if pressed
							_, y = \GetParent!\LocalCursorPos!
							newpos = y - \GetTall! / 2
							setPos newpos

							if .__oldpos ~= newpos
								.__nextCheck = SysTime! + 0.25
								.__oldpos = newpos
								.__y = y

						if SysTime! > (.__nextCheck or SysTime!) and
							(treshold / 2) >= 2 * math.abs 0.5 - (.__y/max_size)
								base\Submit!
								.Think = nil

					setPos max_size * position

			\Popup!

		return base

return taskTable
