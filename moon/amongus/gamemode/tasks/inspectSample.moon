taskTable = {
	Type: GM.TaskType.Long
	Time: 60
	Initialize: =>
		@SetMaxSteps 2

	Advance: =>
		if @GetTimeout! == 0
			@SetCurrentStep 2
			@SetTimeout CurTime! + @.Time
			@NetworkTaskData!

		elseif @GetTimeout! - CurTime! < 0
			@Complete!
			@NetworkTaskData!
}

if CLIENT
	taskTable.CreateVGUI = (task) =>
		base = vgui.Create "AmongUsTaskBase"

		with base
			\Setup with vgui.Create "DPanel"
				max_size = ScrH! * 0.7

				\SetSize max_size, max_size * 0.55

				\SetBackgroundColor Color 64, 64, 64
				with \Add "DLabel"
					\SetFont "NMW AU PlaceholderText"
					\SetColor Color 255, 255, 255
					\SetContentAlignment 5
					\SetText "\n\nInspect sample let's go\n" ..
						"Please press submit"
					\Dock TOP
					\SizeToContents!

				submitted = task.currentStep ~= 1
				button = with \Add "DButton"
					margin = ScrH! * 0.01
					\DockMargin margin * 4, 0, margin * 4, margin * 4
					\SetTall ScrH! * 0.05
					\SetFont "NMW AU PlaceholderText"
					\Dock BOTTOM
					.DoClick = ->
						base\Submit submitted

						submitted = true
						\SetEnabled false
					.Think = ->
						\SetText if submitted
							\SetEnabled false
							if not task.timeout or task.timeout == 0
								"..."
							else
								if task.timeout - CurTime! > 0
									string.format "%ds", math.floor task.timeout - CurTime!
								else
									\SetEnabled true
									.Think = nil
									"Submit"
						else
							"Submit"
			\Popup!

		return base

return taskTable
