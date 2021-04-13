taskTable = {
	Name: "emptyGarbage"
	Type: GM.TaskType.Long
	Time: 3
	Init: =>
		@Base.Init @

		if SERVER
			@SetMaxSteps 2

			@buttons = {}
			-- Remap buttons.
			for button in *GAMEMODE.Util.FindEntsByTaskName "emptyGarbage"
				@buttons[button\GetCustomData!] = button

			@SetActivationButton if @buttons["chute"]
				math.random! > 0.5 and @buttons["chute"] or @buttons["garbage"]
			else
				@buttons["garbage"]

	OnAdvance: =>
		step = @GetCurrentStep!

		if step == 1
			@SetCurrentStep 2
			@SetActivationButton @buttons["second"], true
		elseif step == 2
			@SetCompleted true
}

if CLIENT
	ASSETS = {asset, Material("au/gui/tasks/emptygarbage/#{asset}.png", "smooth") for asset in *{
		"base"
		"leverbase"
		"leverhandle"
		"leverbars"
		"overlay"
	}}

	GARBAGE = [Material("au/gui/tasks/emptygarbage/garbage_#{i}.png", "smooth") for i = 1, 5]
	LEAVES = [Material("au/gui/tasks/cleano2filter/o2_leaf#{i}.png", "smooth") for i = 1, 7]

	VIBE_MATRIX = Matrix!
	COORDS = { "x", "y" }

	local sndStart, sndStop
	soundStart = ->
		if not sndStart
			sndStart = CreateSound LocalPlayer!, "au/panel_garb.wav"
			sndStart\Play!

		if sndStop
			sndStop\Stop!
			sndStop = nil

	soundStop = ->
		if sndStart
			sndStart\Stop!
			sndStart = nil

			sndStop = CreateSound LocalPlayer!, "au/panel_garbstop.wav"
			sndStop\Play!

	taskTable.CreateVGUI = =>
		if not @__isChute
			@__isChute = @GetActivationButton!\GetCustomData! == "chute"

		base = vgui.Create "AmongUsTaskBase"

		with base
			\Setup with vgui.Create "DImage"
				local latching, latched, returning

				max_size = ScrH! * 0.8

				\SetSize max_size, (max_size / 505) * 504
				\SetMaterial ASSETS.base

				.OnRemove = -> soundStop!

				-- Override the base think method and use it
				-- for vibes.
				vibin = 0
				maxVibe = max_size * 0.015

				oldThink = base.Think
				base.Think = (_) ->
					if oldThink
						oldThink _

					if vibin > 0
						_\SetPos ((math.random! * 2) - 1) * vibin * maxVibe,
							((math.random! * 2) - 1) * vibin * maxVibe

						if not latched
							vibin -= FrameTime!

				handleOriginX = (max_size / 505) * (356 + 146 / 2)
				handleOriginY = (max_size / 505) * (5 + 496 / 2)

				local lever
				leverBaseW = (max_size / 505) * 111
				leverBaseH = (max_size / 505) * 54

				leverMaxDistance = (max_size / 505) * 60
				leverHandleW = (max_size / 505) * 109
				leverHandleH = (max_size / 505) * 35

				leverBarsW = (max_size / 505) * 36
				leverBarsH = (max_size / 505) * 68

				leverMin = handleOriginY - leverMaxDistance - leverHandleH / 2
				leverMax = handleOriginY + leverMaxDistance - leverHandleH / 2

				boxX = (max_size / 505) * 5
				boxY = (max_size / 505) * 5
				boxW = (max_size / 505) * 340
				boxH = (max_size / 505) * 496

				trash = {}

				-- Tuned to feel right.
				trashScaleFactor = (max_size / 505) * 1.1
				trashHitboxScaleFactor = 0.4

				-- Box.
				with \Add "Panel"
					\SetPos boxX, boxY
					\SetZPos 2
					\SetSize boxW, boxH
					\SetMouseInputEnabled false

					rows = 5
					row = 0
					offsetY = boxY / rows

					while rows > row
						row += 1

						max = @__isChute and 6 or 10

						step = boxW / max
						startX = boxW / 2 - (step * (max - 1) / 2)

						for i = 1, max
							-- If not chute, fill with leaves.
							-- Otherwise both leaves and garbage.
							sprite = table.Random if @__isChute
								math.random! > 0.5 and GARBAGE or LEAVES
							else
								LEAVES

							-- Define dimensions.
							dim = Vector if texture = sprite\GetTexture "$basetexture"
								texture\GetMappingWidth!, texture\GetMappingHeight!
							else
								200, 100

							dim.x *= trashScaleFactor
							dim.y *= trashScaleFactor

							radius = trashHitboxScaleFactor * math.min dim.x, dim.y
							radiusSq = radius * radius
							pos = Vector startX + step * (i - 1), offsetY + radius * 2 * row

							-- sweet neptune
							piece =
								vel: Vector (math.random! * 2 - 1) * 10, math.random!, 0
								pos: pos
								displaypos: Vector pos
								:sprite
								:dim
								:radius
								:radiusSq
								rollSeed: math.random -boxW, boxW

							table.insert trash, piece

					trashCount = #trash
					nextCalculation = 0
					removed = {}
					shouldRemove = true

					.Think = ->
						if CurTime! > nextCalculation
							nextCalculation = 0.0156 + CurTime!
						else
							return

						-- ITERATE THE TRASH!!!!
						for i = 1, trashCount
							a = trash[i]

							continue if removed[a]

							rest = 0.25

							-- Outside. (Left)
							if a.pos.x < a.radius
								a.vel.x = math.abs(a.vel.x) * rest
								a.pos.x = a.radius

							-- Outside. (Right)
							elseif a.pos.x > boxW - a.radius
								a.vel.x = -math.abs(a.vel.x) * rest
								a.pos.x = boxW - a.radius

							-- Outside. (Top)
							if a.pos.y < a.radius
								a.vel.y = math.abs(a.vel.y) * rest
								a.pos.y = a.radius

							-- Outside. (Bottom)
							elseif not latched and a.pos.y > boxH - a.radius * 0.5
								a.vel.y = -math.abs(a.vel.y) * rest
								a.pos.y = boxH - a.radius * 0.5

							-- Outside. (Bottom) (Beyond render distance)
							elseif latched and a.displaypos.y - a.radius > boxH
								removed[a] = true
								if #trash == table.Count removed
									base\Submit!

							continue if removed[a]

							-- Iterate against every other trash object.
							for j = i + 1, trashCount
								b = trash[j]
								continue if removed[b]

								-- Get distance between both objects and
								-- determine whether there's a hit.
								dx = b.pos.x - a.pos.x
								dy = b.pos.y - a.pos.y
								distSq = (dx * dx) + (dy * dy)
								radiusSq = (a.radius + b.radius)
								radiusSq *= radiusSq

								if radiusSq >= distSq
									-- Determine the hit normal.
									dist = math.sqrt distSq
									normX = dx / dist
									normY = dy / dist

									-- Determine the hit speed.
									speed = math.max 0.5, (a.vel.x - b.vel.x) * normX +
										(a.vel.y - b.vel.y) * normY

									-- If >= 0, push objects away from each other.
									if speed >= 0
										impX = normX * speed
										impY = normY * speed

										a.vel.x -= impX
										a.vel.y -= impY
										b.vel.x += impX
										b.vel.y += impY

							-- Apply velocity.
							a.pos.x += a.vel.x
							a.pos.y += a.vel.y

							-- Apply gravity.
							a.vel.y += 0.5
							if latched
								a.vel.y += 0.075

					.Paint = (_, w, h) ->
						for piece in *trash
							continue if removed[piece]

							-- Dampen the position change to make things look less shaky.
							for coord in *COORDS
								piece.displaypos[coord] = math.Approach piece.displaypos[coord],
									piece.pos[coord], FrameTime! * 10 * math.max 0.1, math.abs piece.displaypos[coord] - piece.pos[coord]

							ang = (piece.displaypos.x - piece.rollSeed) * 0.4 % 360

							-- Rotation origins look really off here, but eh.
							surface.SetMaterial piece.sprite
							surface.DrawTexturedRectRotated piece.displaypos.x, piece.displaypos.y,
								piece.dim.x, piece.dim.y, ang

					-- Overlay
					with \Add "DImage"
						\Dock FILL
						\SetMaterial ASSETS.overlay
						\SetZPos 1

				-- Lever base.
				with \Add "DImage"
					\SetPos handleOriginX - leverBaseW / 2,
						handleOriginY - leverBaseH / 2
					\SetSize leverBaseW, leverBaseH

					\SetMaterial ASSETS.leverbase
					.PaintOver = (_, w, h) ->
						_, curY = lever\GetPos!
						dist = math.Round handleOriginY - (curY + leverHandleH / 2)
						if dist ~= 0
							old = DisableClipping true

							surface.SetMaterial ASSETS.leverbars
							surface.DrawTexturedRect if dist > 0
								-leverBarsW / 2 + leverBaseW / 2, leverBaseH / 2 - dist, leverBarsW, dist
							else
								-leverBarsW / 2 + leverBaseW / 2, leverBaseH / 2, leverBarsW, -dist

							DisableClipping old

				-- Lever.
				lever = with \Add "DImageButton"
					\SetPos handleOriginX - leverBaseW / 2,
						leverMin
					\SetSize leverHandleW, leverHandleH

					\SetMaterial ASSETS.leverhandle

					.OnDepressed = ->
					.OnReleased = ->
						returning = true
						latched = false
						latching = false
						soundStop!

					.Think = ->
						if returning
							curX, curY = \GetPos!
							curY = math.max leverMin, curY - FrameTime! * 2000

							\SetPos curX, curY
							returning = false if curY == leverMin

						elseif latching
							curX, curY = \GetPos!
							curY = math.min leverMax, curY + FrameTime! * 3000

							\SetPos curX, curY
							if curY == leverMax
								latching = false
								latched = true
								for piece in *trash
									piece.vel.y = -12

						elseif \IsDown! and not latched
							curX, curY = \GetPos!
							mX, mY = \GetParent!\LocalCursorPos!

							mY = (mY - leverMin - leverHandleH / 2) * 0.5 +
								(leverMin + leverHandleH / 2)

							latching = true if mY - leverHandleH / 2 > handleOriginY

							if latching
								soundStart!
							else
								\SetPos curX, math.Clamp mY - leverHandleH / 2, leverMin, leverMax

						elseif latched
							vibin = math.min 1, vibin + FrameTime! * 5

			\Popup!

		return base

return taskTable
