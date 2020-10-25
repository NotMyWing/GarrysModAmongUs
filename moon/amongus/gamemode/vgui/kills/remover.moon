remover = {}

ASSETS = {
	crewmate: [Material("au/gui/kills/remover/layer#{i}.png", "smooth") for i = 1, 2]
	gun: [Material("au/gui/kills/remover/gun#{i}.png", "smooth") for i = 1, 2]
}

remover.Play = (killer, victim) =>
	w, h = @GetSize!

	inputCrewmates = { killer, victim }
	crewmates = {}

	for i = 1, 2
		with @Add "DPanel"
			size = h * 0.4
			newW, newH = GAMEMODE.Render.FitMaterial ASSETS.crewmate[1], size, size

			\SetSize newW, newH
			\SetZPos 2
			
			if i == 1
				\AlignLeft w * 0.1
			else
				\AlignRight w * 0.1
			\CenterVertical!
			
			.Paint = (_, w, h) ->
				for layer, mat in ipairs ASSETS.crewmate
					if layer == 1
						surface.SetDrawColor inputCrewmates[i].color
					else
						surface.SetDrawColor 255, 255, 255
					
					surface.SetMaterial mat
					render.PushFilterMag TEXFILTER.ANISOTROPIC
					render.PushFilterMin TEXFILTER.ANISOTROPIC
					surface.DrawTexturedRect 0, 0, w, h
					render.PopFilterMag!
					render.PopFilterMin!

	@NewAnimation 0.15, 0, 0, ->
		for layer, mat in ipairs ASSETS.gun
			with @Add "DSprite"
				\SetMaterial mat
				if layer == 1
					\SetColor Color 255, 255, 255
				else
					\SetColor killer.color

				size = h * 0.25
				newW, newH = GAMEMODE.Render.FitMaterial mat, size, size
				\SetSize newW, newH

				\SetAlpha 0
				\AlphaTo 255, 0.05

				\SetPos w * 0.3, h * 0.5
				\MoveTo w * 0.35, h * 0.5, 0.25

				\SetRotation -45
				\NewAnimation 0.15, 0, 0, ->
					\SetRotation 0
					\NewAnimation 0.15, 0, 0, ->
						\MoveTo w * 0.425, h * 0.425, 0.05
						\NewAnimation 0.25, 0, 0, ->
							\SetRotation 30
							\NewAnimation 0.05, 0, 0, ->
								\SetRotation 0
								\NewAnimation 0.45, 0, 0, ->
									\SetRotation -15
									\MoveTo w * 0.35, h * 0.5, 0.15
									\NewAnimation 0.25, 0, 0, ->
										\SetRotation -45
										\MoveTo w * 0.3, h * 0.5, 0.25
										\AlphaTo 0, 0.1

remover.Paint = ->

return vgui.RegisterTable remover, "DPanel"
