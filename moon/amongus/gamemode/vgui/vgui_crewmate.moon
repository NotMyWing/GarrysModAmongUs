CREW_LAYERS = {
	Material "au/gui/crewmateicon/crewmate1.png", "smooth"
	Material "au/gui/crewmateicon/crewmate2.png", "smooth"
}

COLOR_WHITE = Color 255, 255, 255

vgui.Register "AmongUsCrewmate", {
	Init: =>
		-- A slightly unreadable chunk of garbage code
		-- responsible for layering the crewmate sprite.
		layers = {}
		for i = 1, 2
			with layers[i] = @Add "DPanel"
				\SetZPos i
				\Dock FILL

				image = CREW_LAYERS[i]
				.Paint = (_, w, h) ->
					newWidth, newHeight = GAMEMODE.Render.FitMaterial image, w, h

					surface.SetMaterial image
					surface.SetDrawColor .Color or COLOR_WHITE

					render.PushFilterMag TEXFILTER.ANISOTROPIC
					render.PushFilterMin TEXFILTER.ANISOTROPIC

					surface.DrawTexturedRectUV w/2 - newWidth/2, h/2 - newHeight/2,
						newWidth, newHeight,
						@__flipX and 1 or 0, @__flipY and 1 or 0,
						@__flipX and 0 or 1, @__flipY and 0 or 1

					render.PopFilterMag!
					render.PopFilterMin!

		@__coloredLayer = layers[1]
		@__coloredLayer.Color = COLOR_WHITE

	SetColor: (value) => @__coloredLayer.Color = value
	GetColor: => @__coloredLayer.Color

	SetFlipX: (value) => @__flipX = value
	GetFlipX: => @__flipX or false

	SetFlipY: (value) => @__flipY = value
	GetFlipY: => @__flipY or false

	Paint: ->

}, "DPanel"

return
