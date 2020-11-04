taskTable = {
	Type: GM.TaskType.Common
	Time: 3
	Init: =>
		@Base.Init @

		if SERVER
			@SetMaxSteps 3

			@__taskButtons = GAMEMODE.Util.Shuffle GAMEMODE.Util.FindEntsByTaskName "fixWiring"

			btn = @__taskButtons[1]
			table.remove @__taskButtons, 1
			@SetActivationButton btn

	OnAdvance: =>
		currentStep = @GetCurrentStep!

		if currentStep == 3
			@SetCompleted true
		else
			@SetActivationButton @__taskButtons[1], true
			table.remove @__taskButtons, 1

			@SetCurrentStep currentStep + 1
}

if CLIENT
	taskTable.CreateVGUI = =>
		return with vgui.Create "AmongUsTaskBase"
			\Setup with vgui.Create "AmongUsTaskPlaceholder"
				\SetTime taskTable.Time + CurTime!
			\Popup!

return taskTable
