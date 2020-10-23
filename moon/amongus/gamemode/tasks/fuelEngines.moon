taskTable = {
	Type: GM.TaskType.Long

	-- The time it takes to fill/empty the jerry can.
	Time: 3

	-- Called when the task is created, but not yet sent to the player.
	Initialize: =>
		@SetMaxSteps 2

		@buttons = {}

		-- Find the task buttons.
		for _, button in ipairs GAMEMODE.Util.FindEntsByTaskName "fuelEngines"
			@buttons[button\GetCustomData!] = button

		-- The first button shall be the barrel in the storage.
		@SetActivationButton @buttons["barrel"]

	-- Called whenever the player submits the task.
	Advance: =>
		state = @GetCurrentState! + 1

		-- The player has filled the jerry can.
		-- Send him to the upper pipe.
		if state == 2
			@SetActivationButton @buttons["pipe2"]

		-- The player has filled the upper reactor.
		-- Send him back to the barrel.
		-- Update his task entry to (1/2).
		elseif state == 3
			@SetActivationButton @buttons["barrel"], true
			@SetCurrentStep 2

		-- The player has filled the jerry can again.
		-- Send him to the lower pipe.
		elseif state == 4
			@SetActivationButton @buttons["pipe1"], true

		-- The player has filled both engines.
		-- Complete the task.
		elseif state == 5
			@Complete!

		@SetCurrentState state
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
					if state == 1 or state == 3
						\SetText "\n\nHold to grab fuel.\n"
					else
						\SetText "\n\nHold to refuel the engine.\n"
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
						time = math.min 1, amt / taskTable.Time
						if state == 2 or state == 4
							time = 1 - time

						draw.RoundedBox 16, 0, 0, w, h, Color 32, 32, 32
						draw.RoundedBox 16, 0, 0, w * time, h, Color 0, 221, 0
			\Popup!

		return base

return taskTable
