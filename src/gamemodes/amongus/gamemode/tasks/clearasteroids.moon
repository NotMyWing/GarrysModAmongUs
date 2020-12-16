taskTable = {
	Name: "clearAsteroids"
	Type: GM.TaskType.Long
	Count: 20
	Init: =>
		@Base.Init @

		if SERVER
			@SetMaxSteps @Count
}

if CLIENT
	TRANSLATE = GM.Lang.GetEntry

	SOUNDS = {
		hit: ["au/panel_weaponhit#{i}.ogg" for i = 1, 3]
		fire: "au/panel_weaponfire.ogg"
	}

	ASSETS = {
		meteors: [{
			Material "au/gui/tasks/clearasteroids/weapons_asteroid#{i}.png" , "smooth"
			Material "au/gui/tasks/clearasteroids/weapons_asteroid#{i}x.png", "smooth"
		} for i = 1, 5 ]

		bg: Material "au/gui/tasks/clearasteroids/base.png", "smooth"
		kil: Material "au/gui/tasks/clearasteroids/weapons_explosion.png", "smooth"
	}

	ROTATION_MATRIX = Matrix!

	taskTable.CreateVGUI = =>
		state = @GetCurrentState!
		base = vgui.Create "AmongUsTaskBase"

		with base
			\Setup with parent = vgui.Create "Panel"
				max_size = ScrH! * 0.7
				\SetSize max_size, max_size
				.Paint = (_, w, h) ->
					surface.SetMaterial ASSETS.bg
					surface.SetDrawColor 255, 255, 255, 160
					surface.DrawTexturedRect 0, 0, w, h

				asteroidCount = 0
				destroyed = 0

				pad = max_size * (28/506)
				\DockPadding pad, pad, pad, pad
				with innerPanel = \Add "Panel"
					inner_max_size = max_size - pad * 2
					local label

					\Dock FILL
					\SetMouseInputEnabled true
					.OnMousePressed = ->
						surface.PlaySound SOUNDS.fire

					nextSpawn = CurTime! + math.random!
					.Think = ->
						if asteroidCount < 3 and CurTime! > nextSpawn
							nextSpawn = CurTime! + math.random!
							asteroidCount += 1

							with\Add "DPanel"
								hit = false
								pos = inner_max_size * 0.01 * math.random 0, 100
								size = inner_max_size * 0.15

								posX = inner_max_size
								posY = pos

								-- chosen completely arbitrarily, but hey, it feels good
								velOffset = 3/8 * inner_max_size
								vel = math.random(300, 700) * Vector(
									inner_max_size/2 - posX,
									inner_max_size/2 - posY + math.random -velOffset, velOffset
								)\GetNormalized!

								rotation = math.random 0, 360
								rotVel = math.random -120, 120

								\SetMouseInputEnabled true
								\SetPos posX, posY - size/2
								\SetSize size, size
								.Think = ->
									if not hit
										posX += vel.x * FrameTime!
										posY += vel.y * FrameTime!
										rotation += rotVel * FrameTime!

										\SetPos posX, posY

										if posX <= -max_size * 0.25
											\Remove!

								.OnMousePressed = ->
									destroyed += 1
									if @GetCurrentStep! <= taskTable.Count
										base\Submit @GetCurrentStep! == taskTable.Count

									hit = true
									surface.PlaySound SOUNDS.fire
									\NewAnimation 0.1, 0, 0, ->
										surface.PlaySound table.Random SOUNDS.hit
									\SetMouseInputEnabled false
									\AlphaTo 0, 0.5, 0, ->
										\Remove!

								.OnRemove = ->
									asteroidCount -= 1

								mat = table.Random ASSETS.meteors
								.Paint = (_, w, h) ->
									ltsx, ltsy = _\LocalToScreen 0, 0
									v = Vector ltsx + w / 2, ltsy + h / 2, 0

									with ROTATION_MATRIX
										\Identity!
										\Translate v
										\Rotate Angle 0, rotation, 0
										\Translate -v

									scX1, scY1 = innerPanel\LocalToScreen 0, 0
									scX2, scY2 = innerPanel\LocalToScreen innerPanel\GetSize!
									render.SetScissorRect scX1, scY1, scX2, scY2, true
									cam.PushModelMatrix ROTATION_MATRIX, true
									surface.DisableClipping true
									do
										surface.SetDrawColor 255, 255, 255
										surface.SetMaterial not hit and mat[1] or mat[2]
										surface.DrawTexturedRect 0, 0, w, h

									surface.DisableClipping false
									cam.PopModelMatrix!

									if hit
										surface.SetMaterial ASSETS.kil
										surface.DrawTexturedRect 0, 0, w, h

									render.SetScissorRect 0, 0, 0, 0, false

					label = with \Add "DLabel"
						\SetFont "NMW AU PlaceholderText"
						\SetContentAlignment 5
						\Dock BOTTOM
						\SizeToContents!
						.Think = ->
							\SetText TRANSLATE("task.clearAsteroids.destroyed") destroyed
			\Popup!

		return base

return taskTable
