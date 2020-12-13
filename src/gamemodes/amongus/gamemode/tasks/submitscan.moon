taskTable = {
	Name: "submitScan"
	Init: =>
		@Base.Init @

	Type: GM.TaskType.Long
	Time: 10
	CanUse: => not IsValid(@GetActivationButton!\GetNWEntity "Scanning") and
		48 > @GetAssignedPlayer!.entity\GetPos!\Distance @GetActivationButton!\GetPos!

	-- We don't need the base class' "Advance" method.
	Advance: =>

	OnUse: (btn) =>
		@Base.OnUse @, btn

		if SERVER and not IsValid btn\GetNWEntity "Scanning"
			btn\SetNWEntity "Scanning", @GetAssignedPlayer!.entity
			btn\SetNWFloat "Completion", CurTime! + @Time

			handle = "medbay #{@GetID!}"
			GAMEMODE.GameData.Timers[handle] = true
			timer.Create handle, @Time, 1, ->
				if IsValid btn
					assigned = @GetAssignedPlayer!.entity
					if IsValid(assigned) and assigned == btn\GetNWEntity "Scanning"
						@SetCompleted true

					btn\SetNWEntity "Scanning", Entity 0

	OnCancel: (btn) =>
		if SERVER and @GetAssignedPlayer!.entity == btn\GetNWEntity "Scanning"
			btn\SetNWEntity "Scanning", Entity 0
}

if CLIENT
	taskTable.CreateVGUI = =>
		base = vgui.Create "AmongUsTaskBase"

		with base
			\Setup with vgui.Create "DPanel"
				max_size = ScrH! * 0.7

				\SetSize max_size, max_size * 0.2

				\SetBackgroundColor Color 64, 64, 64
				with \Add "DLabel"
					\SetFont "NMW AU PlaceholderText"
					\SetColor Color 255, 255, 255
					\SetContentAlignment 5
					\SetText "..."
					\Dock FILL
					\SizeToContents!

					.Think = ->
						time = @GetActivationButton!\GetNWFloat("Completion") or (CurTime! + @Time)
						\SetText string.format "We scanning boiz, %d s.", math.max 0, time - CurTime!
						if @GetCompleted!
							base\Submit!
							.Think = nil

			\Popup!

return taskTable
