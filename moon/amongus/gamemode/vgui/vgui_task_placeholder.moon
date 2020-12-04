surface.CreateFont "NMW AU PlaceholderText", {
	font: "Roboto"
	size: ScreenScale 10
	weight: 550
}

placeholder = {}

placeholder.SetTime = (value) =>
	@__time = value
	@button\NewAnimation 0, value - CurTime! + 1, 0, ->
		@button\SetEnabled true

placeholder.Init = =>
	max_size = ScrH! * 0.7

	@SetSize max_size, max_size * 0.55

	@SetBackgroundColor Color 64, 64, 64
	with @Add "DLabel"
		\SetFont "NMW AU PlaceholderText"
		\SetColor Color 255, 255, 255
		\SetContentAlignment 5
		\SetText "\n\nThis task is not yet implemented, so...\n" ..
			"Congratulations!\n" ..
			"You get to stare at the task screen for...\n"
		\Dock TOP
		\SizeToContents!

	@button = with @Add "DButton"
		margin = ScrH! * 0.01
		\DockMargin margin * 4, 0, margin * 4, margin * 4
		\SetTall ScrH! * 0.05
		\SetText "Submit"
		\SetFont "NMW AU PlaceholderText"
		\SetEnabled false
		\Dock BOTTOM
		.DoClick = -> @GetParent!\Submit!

	with @Add "Panel"
		\Dock FILL

		clr = Color 255, 255, 255
		.Paint = (_, w, h) ->
			time = math.max 0, (@__time or 0) - CurTime!

			draw.SimpleTextOutlined string.format("%ds", time), "NMW AU PlaceholderText",
				w/2, h/2, clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color 0, 0, 0, 32

vgui.Register "AmongUsTaskPlaceholder", placeholder, "Panel"
