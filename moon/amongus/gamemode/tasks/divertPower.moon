taskTable = {
	Type: GM.TaskType.Short

	-- Called when the task is created, but not yet sent to the player.
	Initialize: =>
		@SetMaxSteps 2

		destinations = {}
		-- Find the task buttons.
		for _, button in ipairs GAMEMODE.Util.FindEntsByTaskName "divertPower"
			if button\GetCustomData! == "accept"
				table.insert destinations, button
			else
				@SetActivationButton button

		@destination = table.Random destinations
		@SetCustomName "divertPower.#{@destination\GetArea!}"

	-- Called whenever the player submits the task.
	Advance: =>
		@AdvanceInternal!

		if @GetCurrentStep! == 2
			@SetActivationButton @destination

		@NetworkTaskData!
}

if CLIENT
	taskTable.CreateVGUI = (task) =>
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
					if task.currentStep == 1
						\SetText "\n\nPress to divert power.\n"
					else
						\SetText "\n\nPress to accept power\n"
					\Dock TOP
					\SizeToContents!

				button = with \Add "DButton"
					margin = ScrH! * 0.01
					\DockMargin margin * 4, 0, margin * 4, margin * 4
					\SetTall ScrH! * 0.05
					\SetText if task.currentStep == 1
						"Divert"
					else
						"Accept Power"

					\Dock BOTTOM
					.DoClick = ->
						\SetEnabled false
						base\Submit!

			\Popup!

		return base

return taskTable
