remover = {}

ASSETS = {
	crewmate: [Material("au/gui/kills/remover/crewmate#{i}.png", "smooth") for i = 1, 2]
	corpseSquish: [Material("au/gui/kills/remover/corpse_squish#{i}.png", "smooth") for i = 1, 2]
	corpseStand: [Material("au/gui/kills/remover/corpse_stand#{i}.png", "smooth") for i = 1, 2]
	corpseFall: [Material("au/gui/kills/remover/corpse_fall.png", "smooth") for i = 1, 1]
	corpse: [Material("au/gui/kills/remover/corpse#{i}.png", "smooth") for i = 1, 2]
	gun: [Material("au/gui/kills/remover/gun#{i}.png", "smooth") for i = 1, 2]
	beam: [Material("au/gui/kills/remover/beam#{i}.png", "smooth") for i = 1, 2]
	ring: Material "au/gui/kills/remover/remover_ring.png", "smooth"
}

remover.Play = (killer, victim) =>
	w, h = @GetSize!

	inputCrewmates = { killer, victim }
	crewmates = {}

	for i = 1, 2
		table.insert crewmates, with @Add "Panel"
			size = h * 0.4
			newW, newH = GAMEMODE.Render.FitMaterial ASSETS.crewmate[1], size, size

			\SetSize newW, newH
			\SetZPos 2

			if i == 1
				\AlignLeft w * 0.15
			else
				\AlignRight w * 0.15
			\CenterVertical!

			.SpriteBatch = ASSETS.crewmate
			.Paint = (_, w, h) ->
				for layer, mat in ipairs .SpriteBatch
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

				\SetPos w * 0.35, h * 0.5
				\SetAlpha 0
				\SetRotation -45

				-- Move the gun from behind the killer.
				\AlphaTo 255, 0.05
				\MoveTo w * 0.4, h * 0.5, 0.25

				\NewAnimation 0.15, 0, 0, ->
					-- Rotate the gun towards the victim.
					\SetRotation 0
					\NewAnimation 0.15, 0, 0, ->
						-- Move the gun in front of the killer.
						\MoveTo w * 0.475, h * 0.425, 0.05
						\NewAnimation 0.25, 0, 0, ->
							-- Pew. Rotate the gun upwards.
							\SetRotation 30
							if layer == 1
								crewmates[2].SpriteBatch = ASSETS.corpseStand
								surface.PlaySound table.Random {
									"weapons/airboat/airboat_gun_lastshot1.wav"
									"weapons/airboat/airboat_gun_lastshot2.wav"
								}

								-- Create a toolgun halo around the victim's head
								with crewmates[2]\Add "Panel"
									size = math.min crewmates[2]\GetSize!
									\SetSize size, size

									\AlignTop -size * 0.15
									\SetZPos 10

									startTime = SysTime!
									endTime = SysTime! + 0.15
									.Paint = (_, w, h) ->
										surface.SetMaterial ASSETS.ring
										surface.SetDrawColor 255, 255, 255, 255
										value = 1 - math.min 2, (endTime - SysTime!) / (endTime - startTime)

										render.PushFilterMag TEXFILTER.ANISOTROPIC
										render.PushFilterMin TEXFILTER.ANISOTROPIC
										surface.DisableClipping true
										surface.DrawTexturedRect w/2 - (w/2 * value), h/2 - (w/2 * value), w*value, h*value
										surface.DisableClipping false
										render.PopFilterMag!
										render.PopFilterMin!

									\SetAlpha 0
									\AlphaTo 255, 0.05, 0, ->
										\AlphaTo 0, 0.2, 0, ->
											\Remove!

								-- Create a beam between the victim's head and the toolgun.
								with @Add "Panel"
									size = 0.9 * math.min crewmates[2]\GetSize!

									newW, newH = GAMEMODE.Render.FitMaterial ASSETS.beam[1], size, size

									\SetSize newW, newH

									lx, ly = crewmates[2]\GetPos!
									\SetPos lx - newW * 0.41, ly + newH * 1.125
									\NoClipping true
									\SetZPos 10
									.Paint = (_, w, h) ->
										surface.SetMaterial if 0 == math.floor (CurTime! * 10) % 2
											ASSETS.beam[1]
										else
											ASSETS.beam[2]

										surface.SetDrawColor 255, 255, 255, 255

										render.PushFilterMag TEXFILTER.ANISOTROPIC
										render.PushFilterMin TEXFILTER.ANISOTROPIC
										surface.DisableClipping true
										surface.DrawTexturedRect 0, 0, w, h
										surface.DisableClipping false
										render.PopFilterMag!
										render.PopFilterMin!

									\SetAlpha 0
									\AlphaTo 255, 0.05, 0, ->
										\AlphaTo 0, 0.2, 0, ->
											\Remove!

							\NewAnimation 0.05, 0, 0, ->
								-- Rotate the gun back.
								\SetRotation 0
								\NewAnimation 0.45, 0, 0, ->
									-- Rotate the gun downwards and move back behind the killer.
									\SetRotation -15
									\MoveTo w * 0.4, h * 0.5, 0.15

									-- Animate the victim's corpse. Make it flop.
									if layer == 1
										\NewAnimation 0.15, 0, 0, ->
											crewmates[2].SpriteBatch = ASSETS.corpseFall
											\NewAnimation 0.1, 0, 0, ->
												crewmates[2].SpriteBatch = ASSETS.corpseSquish
												\NewAnimation 0.1, 0, 0, ->
													crewmates[2].SpriteBatch = ASSETS.corpse

									-- Finally, holster the weapon.
									\NewAnimation 0.25, 0, 0, ->
										\SetRotation -45
										\MoveTo w * 0.35, h * 0.5, 0.25
										\AlphaTo 0, 0.1

return vgui.RegisterTable remover, "Panel"
