taskTable = {
	Name: "uploadData"
	Type: GM.TaskType.Long
	Time: 9

	-- Called when the task is created, but not yet sent to the player.
	Init: =>
		@Base.Init @

		if SERVER
			@SetMaxSteps 2

			destinations = {}
			-- Find the task buttons.
			for button in *GAMEMODE.Util.FindEntsByTaskName "uploadData"
				if button\GetCustomData! ~= "upload"
					table.insert destinations, button
				else
					@destination = button

			@SetActivationButton table.Random destinations

	-- Called whenever the player submits the task.
	OnAdvance: =>
		@Base.OnAdvance @

		@SetCustomName "uploadData.2"
		@SetActivationButton @destination
}

if CLIENT
	taskTable.CreateVGUI = (task) =>
		base = vgui.Create "AmongUsTaskBase"

		with base
			\Setup with vgui.Create "DPanel"
				max_size = ScrH! * 0.7

				\SetSize max_size, max_size * 0.4

				\SetBackgroundColor Color 64, 64, 64
				with \Add "DLabel"
					\SetFont "NMW AU PlaceholderText"
					\SetColor Color 255, 255, 255
					\SetContentAlignment 5
					if @GetCurrentStep! == 1
						\SetText "\n\nPress to download data.\n"
					else
						\SetText "\n\nPress to upload data.\n"
					\Dock TOP
					\SizeToContents!

				local uploadAnim
				button = with \Add "DButton"
					margin = ScrH! * 0.01
					\DockMargin margin * 4, 0, margin * 4, margin * 4
					\SetTall ScrH! * 0.05
					\SetText if @GetCurrentStep! == 1
						"Download"
					else
						"Upload"

					text = if @GetCurrentStep! == 1
						"Downloading... %ds"
					else
						"Uploading... %ds"

					\Dock BOTTOM
					.DoClick = ->
						\SetEnabled false
						uploadAnim = \NewAnimation 9, 0, 0, ->
							base\Submit!
					.Think = ->
						if uploadAnim
							\SetText string.format text, math.max 0, math.floor uploadAnim.EndTime - SysTime!

			\Popup!

		return base

return taskTable
