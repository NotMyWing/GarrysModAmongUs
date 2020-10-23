taskTable = {
	Type: GM.TaskType.Long
	Time: 10
	Use: =>
		return 24 > @GetAssignedPlayer!.entity\GetPos!\Distance @GetActivationButton!\GetPos!
}

if CLIENT
	taskTable.CreateVGUI = =>
		return with vgui.Create "AmongUsTaskBase"
			\Setup with vgui.Create "AmongUsTaskPlaceholder"
				\SetTime taskTable.Time + CurTime!
			\Popup!

return taskTable
