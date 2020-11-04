taskTable = {
	Type: GM.TaskType.Short
}

if CLIENT
	taskTable.CreateVGUI = =>
		base = vgui.Create "AmongUsTaskBase"

		with base
			\Setup with vgui.Create "DPanel"
				max_size = ScrH! * 0.5

				\SetSize max_size, max_size

				\SetBackgroundColor Color 64, 64, 64
				
				matrixSize = 3
				elementSize = max_size / 3

				-- Cursed things ahead.
				buttons = [ [false for i = 1, matrixSize] for i = 1, matrixSize ]

				-- Pick some random buttons...
				matrixElementCount = matrixSize * matrixSize
				num = math.floor math.random (math.floor matrixElementCount * 0.25), (math.floor matrixElementCount * 0.5)
				for i, e in ipairs GAMEMODE.Util.Shuffle [i for i = 1, matrixSize * matrixSize]
					if i <= num
						buttons[math.ceil e / matrixSize][((e-1) % matrixSize) + 1] = true
					else
						break

				for j = 1, matrixSize
					with \Add "DPanel"
						\SetTall elementSize
						\Dock TOP

						for i = 1, matrixSize
							with \Add "DPanel"
								\SetWide elementSize
								\Dock LEFT

								with \Add "DButton"
									\SetText ""
									\Dock FILL
									\SetIsToggle true
									\SetToggle buttons[j][i]
									.OnToggled = (_, state) ->
										num += state and 1 or -1
										if num == matrixElementCount
											base\Submit!
			\Popup!

return taskTable
