TRANSLATE = GM.Lang.GetEntry

surface.CreateFont "NMW AU Eject Text", {
	font: "Roboto"
	size: ScreenScale 20
	weight: 550
	outline: true
}

surface.CreateFont "NMW AU Eject Subtext", {
	font: "Roboto"
	size: ScreenScale 12
	weight: 550
	outline: true
}

MAT_STARRY = Material "au/gui/eject/starry.png", "noclamp smooth"

MAT_CREWMATE = {
	Material "au/gui/eject/crewmate1.png", "smooth"
	Material "au/gui/eject/crewmate2.png", "smooth"
}

ROTATION_MATRIX = Matrix!

eject = {}

eject.Init = => with @
	\AlphaTo 255, 0.5, 0
	\SetAlpha 0
	\SetSize ScrW!, ScrH!
	\NewAnimation 8, 0, -1, ->
		\AlphaTo 0, 0.4, 0, ->
			\Remove!

--- Writes text in the middle of the screen.
-- Much like in the original game.
-- @param text The text to write.
-- @param subtext Subtext. Optional.
eject.WriteText = (text, subtext) =>
	-- tostringify inputs
	-- TRANSLATE returns metatables which confuse things.
	text = tostring text
	if subtext ~= nil
		subtext = tostring subtext

	if IsValid @ejectTextLabel
		@ejectTextLabel\Remove!

	if IsValid @ejectTextSubLabel
		@ejectTextLabel\Remove!

	@ejectTextLabel = with @Add "DPanel"
		\SetContentAlignment 5
		\SetPos 0, @GetTall!/2 - (ScreenScale 22)/2
		\SetSize @GetWide!, ScreenScale 22

		color = Color 255, 255, 255
		.Text = ""
		.Paint = (_, w, h) ->
			draw.SimpleText .Text, "NMW AU Eject Text", w/2, h/2, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER

	if subtext
		@ejectTextSubLabel = with @Add "DPanel"
			x, y = @ejectTextLabel\GetPos!
			\SetPos x, y + @ejectTextLabel\GetTall!

			\SetAlpha 0
			\SetContentAlignment 5
			\SetSize @GetWide!, ScreenScale 14

			color = Color 255, 255, 255
			.Paint = (_, w, h) ->
				if \GetAlpha! ~= 0
					draw.SimpleText subtext, "NMW AU Eject Subtext", w/2, h/2, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER

	i = 0
	callback = ->
		i += 1

		@ejectTextLabel.Text ..= text[i]

		if text[i] ~= "" and text[i] ~= " "
			surface.PlaySound "au/eject_text.wav"

		if i ~= #text
			@ejectTextLabel\NewAnimation 1.5/#text, 0, 0, callback
		elseif @ejectTextSubLabel
			@ejectTextSubLabel\AlphaTo 255, 0.25, 1

	callback!

--- Ejects something.
-- @param reason Why are we ejecting? See GM.EjectReason in shared.moon
-- @param ply The person we're ejecting. Optional.
-- @param confirm Are confirm ejects on? Optional.
-- @param imposter Was the ejected person an imposter? Optional.
-- @param remaining How many imposters left? Optional, but total must be provided.
-- @param total How many imposters are there in the game? Optional.
eject.Eject = (reason, ply, confirm = false, imposter = false, remaining = 0, total = 0) => with @
	subtext = if confirm and total ~= 0
		TRANSLATE("eject.remaining") remaining

	if not ply
		-- If we're not ejecting anyone, print that nobody was ejected.
		\NewAnimation 2, 0, -1, ->
			@WriteText switch reason
				when GAMEMODE.EjectReason.Tie
					TRANSLATE("eject.reason.tie"), subtext
				when GAMEMODE.EjectReason.Skipped
					TRANSLATE("eject.reason.skipped"), subtext
				else
					TRANSLATE("eject.reason.generic"), subtext
	else
		-- However if we are, print the name and optionally the role of the ejected person.
		-- Create and animate a crewmate sprite flying across the screen.
		with crewmate = \Add "DPanel"
			size = 0.15 * math.min @GetTall!, @GetWide!
			\SetSize size, size
			\SetPos -size, @GetTall!/2 - size/2
			\SetZPos 1

			-- Split the animation in half and print the text
			-- when the crewmate is in the middle of the screen.
			\MoveTo @GetWide! / 2 - size / 2, @GetTall!/2 - size/2, 2, 1, 1, ->
				\MoveTo @GetWide!, @GetTall!/2 - size/2, 3, 0, 1

				text = TRANSLATE("eject.text") ply.nickname, confirm, imposter, total

				@WriteText text, subtext

			accumulator = 0
			starttime = SysTime!
			endtime = SysTime! + 5

			-- This is ever so slightly bad.
			-- Just a tiny bit.
			.Paint = (_, w, h) ->
				curtime = math.max 0.1, (endtime - SysTime!) / (endtime - starttime)
				accumulator += curtime * 2.5

				ltsx, ltsy = _\LocalToScreen 0, 0
				v = Vector ltsx + w / 2, ltsy + h / 2, 0

				with ROTATION_MATRIX
					\Identity!
					\Translate v
					\Rotate Angle 0, accumulator, 0
					\Translate -v

				cam.PushModelMatrix ROTATION_MATRIX, true
				do
					surface.DisableClipping true
					surface.SetDrawColor ply.color
					surface.SetMaterial MAT_CREWMATE[1]
					surface.DrawTexturedRect 0, 0, w, h

					surface.SetDrawColor 255, 255, 255
					surface.SetMaterial MAT_CREWMATE[2]
					surface.DrawTexturedRect 0, 0, w, h
					surface.DisableClipping false
				cam.PopModelMatrix!

--- Paints the starry sky.
-- Which is quite literally just three layers of the same star picture.
eject.Paint = (w, h) => with @
	surface.SetDrawColor 0, 0, 0
	surface.DrawRect 0, 0, w, h

	time = CurTime! / 4
	scale = 1
	alpha = 255

	surface.SetMaterial MAT_STARRY
	for i = 1, 3
		surface.SetDrawColor Color 255, 255, 255, alpha
		surface.DrawTexturedRectUV 0, 0, w, h, -time * scale, 0, (-time + w/h) * scale, scale

		time /= 4
		scale *= 2
		alpha *= 0.5

return vgui.RegisterTable eject, "DPanel"
