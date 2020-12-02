CREW_LAYERS = {
	Material "au/gui/crewmateicon/crewmate1.png", "smooth"
	Material "au/gui/crewmateicon/crewmate2.png", "smooth"
}

COLOR_WHITE = Color 255, 255, 255

vgui.Register "AmongUsCrewmate", {
	SetColor: (value) => @__color = value
	GetColor: => @__color or COLOR_WHITE

	SetFlipX: (value) => @__flipX = value
	GetFlipX: => @__flipX or false

	SetFlipY: (value) => @__flipY = value
	GetFlipY: => @__flipY or false

	Paint: (w, h) =>
		newWidth, newHeight = GAMEMODE.Render.FitMaterial CREW_LAYERS[1], w, h

		render.PushFilterMag TEXFILTER.ANISOTROPIC
		render.PushFilterMin TEXFILTER.ANISOTROPIC

		for i = 1, 2
			surface.SetMaterial CREW_LAYERS[i]
			surface.SetDrawColor i == 1 and @GetColor! or COLOR_WHITE

			surface.DrawTexturedRectUV w/2 - newWidth/2, h/2 - newHeight/2,
				newWidth, newHeight,
				@__flipX and 1 or 0, @__flipY and 1 or 0,
				@__flipX and 0 or 1, @__flipY and 0 or 1

		render.PopFilterMag!
		render.PopFilterMin!

}, "DPanel"

return
