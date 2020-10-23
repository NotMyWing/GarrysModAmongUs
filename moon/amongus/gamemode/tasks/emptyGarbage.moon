taskTable = {
	Type: GM.TaskType.Long
	Time: 3
	Initialize: =>
		@SetMaxSteps 2

		@buttons = {}
		-- Remap buttons.
		for _, button in ipairs GAMEMODE.Util.FindEntsByTaskName "emptyGarbage"
			@buttons[button\GetCustomData!] = button

		@SetActivationButton if @buttons["chute"]
			math.random! > 0.5 and @buttons["chute"] or @buttons["garbage"]
		else
			@buttons["garbage"]

	Advance: =>
		step = @GetCurrentStep!

		if step == 1
			@SetCurrentStep 2
			@SetActivationButton @buttons["second"], true
		elseif step == 2
			@Complete!

		@NetworkTaskData!
}

if CLIENT
	taskTable.CreateVGUI = (task) =>
		state = task.currentState
		base = vgui.Create "AmongUsTaskBase"

		with base
			\Setup with vgui.Create "DPanel"
				max_size = ScrH! * 0.7

				\SetSize max_size, max_size * 0.4

				\SetBackgroundColor Color 64, 64, 64
				with \Add "DLabel"
					\SetFont "NMW AU PlaceholderText"
					\SetColor Color 255, 255, 255
					\SetContentAlignment 5
					\SetText "\n\nHold to empty garbage.\n"
					\Dock TOP
					\SizeToContents!

				local fuelbox

				amt = 0
				pressed = false
				finished = false
				button = with \Add "DButton"
					margin = ScrH! * 0.01
					\DockMargin margin * 4, 0, margin * 4, margin * 4
					\SetTall ScrH! * 0.05
					\SetText ""
					\Dock BOTTOM
					.OnMousePressed  = -> pressed = true
					.OnMouseReleased = -> pressed = false
					.OnCursorExited  = -> pressed = false
					.Think = ->
						if not finished and pressed
							amt += FrameTime!
							if amt >= taskTable.Time
								finished = true
								base\Submit!

				with \Add "DPanel"
					margin = ScrH! * 0.01
					\DockMargin margin * 4, 0, margin * 4, margin * 2
					\Dock FILL
					.Paint = (_, w, h) ->
						time = 1 - math.min 1, amt / taskTable.Time

						draw.RoundedBox 16, 0, 0, w, h, Color 32, 32, 32
						draw.RoundedBox 16, 0, 0, w * time, h, Color 221, 0, 0
			\Popup!

		return base

return taskTable
