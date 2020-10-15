surface.CreateFont "NMW AU Eject Text", {
	font: "Arial"
	size: ScreenScale 20
	weight: 500
	outline: true
}

surface.CreateFont "NMW AU Eject Subtext", {
	font: "Arial"
	size: ScreenScale 12
	weight: 500
	outline: true
}

eject = {}

eject.Init = => with @
	\SetSize ScrW!, ScrH!
	\SetAlpha 0
	\AlphaTo 255, 0.5, 0
	\NewAnimation 8, 0, -1, ->
		\AlphaTo 0, 0.4, 0, ->
			\Remove!

	with @canvas = \Add "DPanel"
		\SetSize @GetWide!, @GetTall!
		\SetAlpha 255
		\AlphaTo 0, 0.4, 0, ->
			\Remove!

		.Paint = (_, w, h) ->
			surface.SetDrawColor 0, 0, 0
			surface.DrawRect 0, 0, w, h

eject.EjectText = (ply) =>

VGUI_STARRY = Material "au/gui/eject/starry.png", "noclamp smooth"
VGUI_CREWMATE = {
	Material "au/gui/eject/crewmate1.png", "smooth"
	Material "au/gui/eject/crewmate2.png", "smooth"
}

eject.Eject = (reason, ply, confirm, imposter, remaining, total) => with @
	size = 0.15 * math.min @GetTall!, @GetWide!

	label = @Add "DPanel"
	with label
		\SetSize @GetWide!, ScreenScale 22
		\SetPos 0, @GetTall!/2 - (ScreenScale 22)/2
		\SetContentAlignment 5

		color = Color 255, 255, 255
		.Text = ""
		.Paint = (_, w, h) ->
			draw.SimpleText .Text, "NMW AU Eject Text", w/2, h/2, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER

	local subLabel 
	if confirm
		subLabel = @Add "DPanel"
		with subLabel
			\SetSize @GetWide!, ScreenScale 14

			x, y = label\GetPos!
			\SetPos x, y + label\GetTall!
			\SetContentAlignment 5
			\SetAlpha 0
			\AlphaTo 255, 0.25, 4
			color = Color 255, 255, 255
			.Text = if remaining == 1
				string.format "1 Imposter remains."
			else
				string.format "%d Imposters remain.", remaining

			.Paint = (_, w, h) ->
				draw.SimpleText .Text, "NMW AU Eject Subtext", w/2, h/2, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER

	writeText = (text) ->
		i = 0
		callback = ->
			i += 1

			label.Text ..= text[i]
			surface.PlaySound "au/eject_text.wav"
			if i ~= #text
				\NewAnimation 1.5/#text, 0, 0, callback
		callback!

	if not ply
		\NewAnimation 2, 0, -1, ->
			switch reason
				when GAMEMODE.EjectReason.Tie
					writeText "Nobody was ejected. (Tie)"
				when GAMEMODE.EjectReason.Skipped
					writeText "Nobody was ejected. (Skipped)"
				else
					writeText "Nobody was ejected."
	else
		with crewmate = \Add "DPanel"
			\SetSize size, size
			\SetPos -size, @GetTall!/2 - size/2
			\MoveTo @GetWide! / 2 - size / 2, @GetTall!/2 - size/2, 2, 1, 1, ->
				\MoveTo @GetWide!, @GetTall!/2 - size/2, 3, 0, 1

				text = if confirm
					if imposter
						if total == 1
							"%s was The Imposter."
						else
							"%s was An Imposter."
					else
						if total == 1
							"%s was not The Imposter."
						else
							"%s was not An Imposter."
				else
					"%s was ejected."

				writeText string.format text, ply.nickname

			.accumulator = 0
			starttime = SysTime!
			endtime = SysTime! + 5

			.Paint = (_, w, h) ->
				curtime = math.max 0.1, (endtime - SysTime!) / (endtime - starttime)
				.accumulator += curtime * 1.5

				ltsx, ltsy = _\LocalToScreen 0, 0
				ltsv = Vector ltsx, ltsy, 0
				v = Vector w / 2, h / 2, 0

				m = Matrix!
				m\Translate ltsv
				m\Translate v
				m\Rotate Angle 0, .accumulator, 0
				m\Translate -v
				m\Translate -ltsv

				cam.PushModelMatrix m, true
				do
					surface.DisableClipping true
					surface.SetDrawColor ply.color
					surface.SetMaterial VGUI_CREWMATE[1]
					surface.DrawTexturedRect 0, 0, w, h
					
					surface.SetDrawColor 255, 255, 255
					surface.SetMaterial VGUI_CREWMATE[2]
					surface.DrawTexturedRect 0, 0, w, h
					surface.DisableClipping false
				cam.PopModelMatrix!

VGUI_STARRY = Material "au/gui/eject/starry.png", "noclamp smooth"

eject.Paint = (w, h) => with @
	surface.SetDrawColor 0, 0, 0
	surface.DrawRect 0, 0, w, h

	time = CurTime! / 4
	scale = 1
	alpha = 255

	surface.SetMaterial VGUI_STARRY
	for i = 1, 3
		surface.SetDrawColor Color 255, 255, 255, alpha
		surface.DrawTexturedRectUV 0, 0, w, h, -time * scale, 0, (-time + w/h) * scale, scale

		time /= 4
		scale *= 2
		alpha *= 0.5

return vgui.RegisterTable eject, "DPanel"