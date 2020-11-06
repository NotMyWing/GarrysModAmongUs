taskTable = {
	Name: "inspectSample"
	Type: GM.TaskType.Long
	Time: 60
	Init: =>
		@Base.Init @

		if SERVER
			@SetMaxSteps 2

	OnAdvance: =>
		if @GetTimeout! == 0
			@SetCurrentStep 2
			@SetTimeout CurTime! + @.Time

		elseif @GetTimeout! - CurTime! < 0
			@SetCompleted true
}

if CLIENT
	taskTable.CreateVGUI = =>
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

				button = with \Add "DButton"
					margin = ScrH! * 0.01
					\DockMargin margin * 4, 0, margin * 4, margin * 4
					\SetTall ScrH! * 0.05
					\SetFont "NMW AU PlaceholderText"
					\Dock BOTTOM
					\SetText "Submit"
					\SetEnabled @GetCurrentStep! == 1 or (@GetCurrentStep! == 2 and @GetTimeout! - CurTime! <= 0)
					.DoClick = ->
						base\Submit @GetCurrentStep! ~= 1
						\SetEnabled false

					.Think = ->
						if @GetCurrentStep! == 2
							\SetText if @GetTimeout! ~= 0 and @GetTimeout! - CurTime! > 0
								string.format "%ds", math.floor @GetTimeout! - CurTime!
							else
								\SetEnabled true
								.Think = nil
								"Submit"
			\Popup!

		return base

return taskTable
