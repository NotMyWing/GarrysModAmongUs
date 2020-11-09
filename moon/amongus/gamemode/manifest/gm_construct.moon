if SERVER
	buttons = {
		{
			Task: "swipeCard"
			Position: Vector(350, 15, -100)
			Model: "models/props_interiors/VendingMachineSoda01a.mdl"
		}
	}

	createButtons = ->
		for btn in *buttons
			with ent = ents.Create "prop_task_button"
				print btn.Position
				\SetPos btn.Position
				\SetModel btn.Model
				\Spawn!
				\Activate!

				\SetTaskName btn.Task
	
	hook.Add "Initialize", "NMW AU Construct Entities", createButtons
	hook.Add "PostCleanupMap", "NMW AU Construct Entities", createButtons

return {
	Tasks: {
		"swipeCard"
	}
	Map: {
		UI: if CLIENT
			{
				BackgroundMaterial: Material "au/gui/maps/gm_construct/base.png", "smooth"
				OverlayMaterial: Material "au/gui/maps/gm_construct/overlay.png", "smooth"

				Position: Vector -5724, 6554
				Scale: 11.00
				Resolution: 2187/1024
				Rotation: 90
			}
	}
}
