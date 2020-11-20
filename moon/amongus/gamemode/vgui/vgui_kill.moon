KILLS = {
	include "kills/remover.lua"
}

ASSETS = {
	background: Material "au/gui/meeting/bg.png", "smooth"
}

ROTATION_MATRIX = Matrix!

return vgui.RegisterTable {
	PlayBackground: (callback) =>
		local shrinkAnim, rot
		with bg = @Add "DPanel"
			\SetSize @GetWide!, @GetTall!
			\SetPos 0, 0

			rot = 33
			\NewAnimation 0.1, 0, -1, ->
				rot = -33
				\NewAnimation 0.1, 0, -1, ->
					rot = 0
					if callback
						callback!
					@AlphaTo 0, 0.35, 3
					shrinkAnim = \NewAnimation 0.35, 3, -1, ->
						@Remove!

			aspect = 435/948

			.Paint = (_, w, h) ->
				ltsx, ltsy = _\LocalToScreen 0, 0
				ltsv = Vector ltsx, ltsy, 0
				v = Vector w / 2, h / 2, 0

				with ROTATION_MATRIX
					\Identity!
					\Translate ltsv
					\Translate v
					\Rotate Angle 0, rot, 0

					if rot ~= 0
						\Scale Vector 1.5, 1.5, 1.5
					if shrinkAnim
						\Scale Vector 1, (math.Clamp((shrinkAnim.EndTime - SysTime!) / (shrinkAnim.EndTime - shrinkAnim.StartTime), 0, 1)), 1

					\Translate -v
					\Translate -ltsv

				cam.PushModelMatrix ROTATION_MATRIX, true
				do
					surface.DisableClipping true
					surface.SetDrawColor 255, 255, 255
					surface.SetMaterial ASSETS.background
					render.PushFilterMag TEXFILTER.ANISOTROPIC
					render.PushFilterMin TEXFILTER.ANISOTROPIC
					surface.DrawTexturedRect 0, 0, w, h
					render.PopFilterMag!
					render.PopFilterMin!
					surface.DisableClipping false
				cam.PopModelMatrix!

	Init: =>
		@SetZPos 30010
		@SetSize ScrW!, ScrH!
		@NewAnimation 5, 0, 0, ->
			@Remove!

	Kill: (killer, victim) =>
		surface.PlaySound "au/impostor_killmusic.wav"
		@PlayBackground ->
			with @Add table.Random KILLS
				\SetWide ScrW! * 0.5
				\SetTall \GetWide! * 0.7
				\Center!
				if .Play
					\Play killer, victim

	Paint: ->

}, "DPanel"
