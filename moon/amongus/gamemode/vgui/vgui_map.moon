return vgui.RegisterTable {
	__tracking: {}

	SetupFromManifest: (manifest) =>
		@BaseClass.SetupFromManifest @, manifest

		innerPanel = @GetInnerPanel!
		if manifest.Sabotages
			with @sabotageOverlay = innerPanel\Add "DPanel"
				w, h = innerPanel\GetSize!
				\SetSize w, h
				\SetZPos 30000
				\Hide!
				.Paint = ->

				buttonSize = 0.085 * math.min w, h
				for id, sabotage in ipairs manifest.Sabotages
					if sabotage.UI
						with \Add "DImageButton"
							\SetMaterial sabotage.UI.Icon
							\SetSize buttonSize, buttonSize
							\SetPos w * sabotage.UI.Position.x - buttonSize/2, h * sabotage.UI.Position.y - buttonSize/2
							.DoClick = ->
								GAMEMODE\Net_SabotageRequest id

							.Think = ->
								instance = GAMEMODE.GameData.Sabotages[id]

								if instance
									enabled = \IsEnabled!
									canSetOff = not GAMEMODE\IsMeetingInProgress! and
										not GAMEMODE.UseHighlight and
										not GAMEMODE.GameData.Vented and
										instance\CanStart!

									if enabled and not canSetOff
										\SetEnabled false
									elseif not enabled and canSetOff
										\SetEnabled true

							with \Add "DLabel"
								\Dock FILL
								\SetContentAlignment 5
								\SetText "..."
								\SetFont "NMW AU Map Labels"
								\SetColor Color 255, 255, 255
								.Think = ->
									instance = GAMEMODE.GameData.Sabotages[id]
									if instance
										if instance\GetActive!
											\SetText "!"
										else
											time = if instance\GetCooldownOverride! ~= 0
												instance\GetCooldownOverride!
											else
												instance\GetNextUse! - CurTime!

											if not instance\GetDisabled! and time > 0
												\SetText math.floor time
											else
												\SetText ""

	Track: (entity, element, track = true) =>
		if IsValid entity
			innerPanel = @GetInnerPanel!

			if track
				@__tracking[entity] = element
				element\SetParent innerPanel
			else
				if IsValid @__tracking[entity]
					@__tracking[entity]\Remove!

				@__tracking[entity] = nil
		elseif IsValid element
			element\Remove!

	UnTrack: (entity) =>
		@Track entity, nil, false

	EnableSabotageOverlay: =>
		if IsValid @sabotageOverlay
			@sabotageOverlay\Show!

	Think: =>
		@BaseClass.Think and @BaseClass.Think @

		size = math.max @GetInnerPanel!\GetSize!
		baseW, baseH = @GetBackgroundMaterialSize!
		resolution = @GetResolution!
		scale = @GetScale!
		position = @GetPosition!

		for entity, element in pairs @__tracking
			if IsValid(entity) and IsValid(element)
				pos = entity\GetPos!
				w, h = element\GetSize!

				element\SetPos (pos.x - position.x) / (baseW * scale) * size * resolution - w/2,
					(position.y - pos.y) / (baseW * scale) * size * resolution - h/2
			else
				@UnTrack entity

}, "AmongUsMapBase"
