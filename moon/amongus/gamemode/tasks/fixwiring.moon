taskTable = {
	Name: "fixWiring"
	Type: GM.TaskType.Common
	Time: 3
	Init: =>
		@Base.Init @

		if SERVER
			@SetMaxSteps 3

			@__taskButtons = [button for button in *GAMEMODE.Util.Shuffle(GAMEMODE.Util.FindEntsByTaskName @Name)[, 3]]
			table.sort @__taskButtons, (a, b) ->
				(tonumber(a\GetCustomData!) or 0) < (tonumber(b\GetCustomData!) or 0)

			btn = @__taskButtons[1]
			table.remove @__taskButtons, 1
			@SetActivationButton btn

	OnAdvance: =>
		currentStep = @GetCurrentStep!

		if currentStep == @GetMaxSteps!
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
