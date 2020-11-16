taskTable = {
	Name: "unlockManifolds"
	Type: GM.TaskType.Short
}

if CLIENT
	surface.CreateFont "NMW AU Manifolds Text", {
		font: "Roboto"
		size: ScrH! * 0.5 / 8
		weight: 550
	}

	taskTable.CreateVGUI = =>
		base = vgui.Create "AmongUsTaskBase"

		with base
			\Setup with vgui.Create "DPanel"
				max_size = ScrH! * 0.5

				\SetBackgroundColor Color 64, 64, 64

				-- Slightly less cursed things ahead.
				buttons = GAMEMODE.Util.Shuffle [ i for i = 1, 10 ]
				rows = 2

				\SetSize max_size, rows * max_size / 5

				currentStep = 1
				for j = 1, rows
					with \Add "DPanel"
						\SetTall max_size / 5
						\Dock TOP
						for i = 1, #buttons/rows
							with \Add "DPanel"
								\SetWide max_size / 5
								\Dock LEFT
								.Paint = ->

								with btn = \Add "DButton"
									\SetText ""
									\Dock FILL
									\SetIsToggle true
									\SetToggle false
									\SetFont "NMW AU Manifolds Text"

									val = buttons[(j - 1) * (#buttons/rows) + i]
									\SetText val

									buttons[(j - 1) * (#buttons/rows) + i] = btn
									.OnToggled = (_, state) ->
										if val ~= currentStep
											for _, btn in ipairs buttons
												\SetToggle false
												\SetEnabled true

											currentStep = 1
										else
											if currentStep == #buttons
												base\Submit!
											else
												currentStep += 1
											\SetEnabled false
			\Popup!

return taskTable
