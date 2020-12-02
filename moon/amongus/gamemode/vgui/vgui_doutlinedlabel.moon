DEFAULT_OUTLINE_COLOR = Color 0, 0, 0
DEFAULT_COLOR = Color 255, 255, 255

vgui.Register "DOutlinedLabel", {
	SetOutlineRadius: (value) => @__outlineRadius = value
	GetOutlineRadius: => @__outlineRadius or 2

	SetFont: (value) => @__font = value
	GetFont: => @__font or "Default"

	SetText: (value) => @__text = value
	GetText: => @__text or "Label"

	SetOutlineColor: (value) => @__outlineColor = value
	GetOutlineColor: => @__outlineColor or DEFAULT_OUTLINE_COLOR

	SetColor: (value) => @__color = value
	GetColor: => @__color or DEFAULT_COLOR

	SetContentAlignment: (alignment) =>
		@__verticalAlignment = switch alignment
			when 7, 8, 9
				TEXT_ALIGN_TOP
			when 4, 5, 6
				TEXT_ALIGN_CENTER
			when 1, 2, 3
				TEXT_ALIGN_BOTTOM

		@__horizontalAlignment = switch alignment
			when 7, 4, 1
				TEXT_ALIGN_LEFT
			when 8, 5, 2
				TEXT_ALIGN_CENTER
			when 9, 6, 3
				TEXT_ALIGN_RIGHT

	Init: =>
		@SetContentAlignment 7

	Paint: (w, h) =>
		outlineRadius = @GetOutlineRadius!

		textPosX = switch @__horizontalAlignment
			when TEXT_ALIGN_LEFT
				0 + outlineRadius
			when TEXT_ALIGN_CENTER
				w / 2
			when TEXT_ALIGN_RIGHT
				w - outlineRadius

		textPosY = switch @__verticalAlignment
			when TEXT_ALIGN_TOP
				0 + outlineRadius
			when TEXT_ALIGN_CENTER
				h / 2
			when TEXT_ALIGN_BOTTOM
				h - outlineRadius

		text = @GetText!
		font = @GetFont!
		color = @GetColor!

		outlineColor = @GetOutlineColor!

		draw.SimpleTextOutlined text, font, textPosX, textPosY,
			color, @__horizontalAlignment, @__verticalAlignment,
			outlineRadius, outlineColor

}, "DPanel"
