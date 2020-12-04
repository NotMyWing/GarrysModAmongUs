taskTable = {
	Name: "cleanO2Filter"
	Type: GM.TaskType.Short
	Count: 6
	OnAdvance: =>
		if @GetCurrentState! == @Count
			@SetCompleted true
		else
			@SetCurrentState @GetCurrentState! + 1

}

if CLIENT
	ASSETS = {
		base: Material "au/gui/tasks/cleano2filter/o2_bgBase.png", "smooth"
		foreground: Material "au/gui/tasks/cleano2filter/o2_bgTop.png", "smooth"
		leaves: [Material("au/gui/tasks/cleano2filter/o2_leaf#{i}.png", "smooth") for i = 1, 7]
	}

	SOUNDS = {
		leaf: ["au/panel_o2_leaf#{i}.ogg" for i = 1, 4]
		suck: ["au/panel_o2_suck#{i}.ogg" for i = 1, 3]
	}

	ROTATION_MATRIX = Matrix!

	taskTable.CreateVGUI = =>
		state = @GetCurrentState!
		base = vgui.Create "AmongUsTaskBase"

		with base
			\Setup with parent = vgui.Create "DImage"
				max_size = ScrH! * 0.7
				\SetSize max_size, max_size
				\SetMaterial ASSETS.base

				with \Add "DImage"
					\SetZPos 1
					width = GAMEMODE.Render.FitMaterial ASSETS.foreground, max_size, max_size

					\SetSize width, max_size
					\SetMaterial ASSETS.foreground

				for i = 1, (taskTable.Count + 1) - state
					pressed = true
					rot = math.random -20, 20
					with \Add "Panel"
						\SetSize max_size * 0.25, max_size * 0.25
						\SetPos math.random(max_size * 0.25, max_size * 0.75), math.random(max_size * 0.25, max_size * 0.75)
						velocity = 0.005 * Vector math.random(-100, 100), math.random(-100, 100)

						\SetMouseInputEnabled true
						.OnMousePressed  = ->
							.__pressX, .__pressY = \LocalCursorPos!
							pressed = true

							surface.PlaySound table.Random SOUNDS.leaf

						.OnMouseReleased = -> pressed = false

						mat = ASSETS.leaves[i]
						fitMaterial = GAMEMODE.Render.FitMaterial
						leafW, leafH = fitMaterial mat, \GetSize!
						leafMin = math.min leafW, leafH
						rotVel = 0.01 * math.random -50, 50
						.__x, .__y = \GetPos!

						.Velocity = velocity
						.Think = ->
							w, h = max_size, max_size

							if pressed
								if not input.IsMouseDown MOUSE_LEFT
									pressed = false
								else
									lx, ly = \LocalCursorPos!
									lv = Vector(lx - .__pressX, ly - .__pressY, 0)
									lv\Normalize!

									velocity += lv * 0.1

							if (velocity.x < 0 and (.__x + leafMin/2 < w * 0.20) and
								(.__y < h*0.18 or .__y > h*0.5)) or
								(velocity.x > 0 and .__x + leafMin * 2 > w)
									velocity.x *= -1
									rotVel = math.Clamp -100 * rotVel, -2, 2

							if (velocity.y < 0 and .__y + leafMin/2 < 0) or
								(velocity.y > 0 and .__y + leafMin * 2 > h)
									velocity.y *= -1
									rotVel = math.Clamp -100 * rotVel, -2, 2

							if (.__x + leafMin/2 < w * 0.15)
								if (velocity.y < 0 and .__y < h*0.23) or
									(velocity.y > 0 and .__y > h*0.5)
										velocity.y *= -1
										rotVel = math.Clamp -100 * rotVel, -2, 2

								velocity.x -= 0.35

							.__x += velocity.x * FrameTime! * 100
							.__y += velocity.y * FrameTime! * 100

							if .__x < -w * 0.1
								surface.PlaySound table.Random SOUNDS.suck
								\Remove!
								base\Submit @GetCurrentState! == taskTable.Count
							else
								velocity *= 0.99

								if 0.02 < math.abs rotVel
									rotVel *= 0.99

								rot += rotVel * 100 * FrameTime!

								\SetPos .__x, .__y

						.Paint = (_, w, h) ->
							ltsx, ltsy = _\LocalToScreen 0, 0
							v = Vector ltsx + w / 2, ltsy + h / 2, 0

							with ROTATION_MATRIX
								\Identity!
								\Translate v
								\Rotate Angle 0, rot, 0
								\Translate -v

							scX1, scY1 = parent\LocalToScreen 0, 0
							scX2, scY2 = parent\LocalToScreen parent\GetSize!
							render.SetScissorRect scX1, scY1, scX2, scY2, true
							cam.PushModelMatrix ROTATION_MATRIX, true
							surface.DisableClipping true
							do
								surface.SetMaterial mat
								surface.SetDrawColor 255, 255, 255
								surface.DrawTexturedRect w/2 - leafW/2, h/2 - leafH/2, leafW, leafH

							surface.DisableClipping false
							cam.PopModelMatrix!
							render.SetScissorRect 0, 0, 0, 0, false

			\Popup!

		return base

return taskTable
