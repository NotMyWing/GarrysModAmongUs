{
	PrintName: "Test"
	Tasks: {
		"swipeCard"
		"chartCourse"
		"uploadData"
	}
	Map: {
		UI: if CLIENT
			{
				BackgroundMaterial: Material "au/gui/maps/au_test/background.png", "smooth"
				OverlayMaterial: Material "au/gui/maps/au_test/overlay.png", "smooth"

				Position: Vector -1792, 1024, 0
				Scale: 1.125
			}
	}
	Sabotages: {
		{
			Handler: "comms"
			UI: if CLIENT
				{
					Icon: Material "au/gui/map/sabotage_comms.png", "smooth"
					Position: Vector 0.21875 - 0.04, 0.21875, 0
				}
		}
		{
			Handler: "doors"
			UI: if CLIENT
				{
					Icon: Material "au/gui/map/sabotage_doors.png", "smooth"
					Position: Vector 0.21875 + 0.04, 0.21875, 0
				}
			CustomData: {
				Target: "sabotageDoor1"
			}
		}
		{
			Handler: "lights"
			UI: if CLIENT
				{
					Icon: Material "au/gui/map/sabotage_electricity.png", "smooth"
					Position: Vector 0.78125 - 0.05, 0.78125 - 0.04, 0
				}
		}
		{
			Handler: "reactor"
			UI: if CLIENT
				{
					Icon: Material "au/gui/map/sabotage_reactor.png", "smooth"
					Position: Vector 0.78125 + 0.05, 0.78125 - 0.04, 0
				}
		}
		{
			Handler: "doors"
			UI: if CLIENT
				{
					Icon: Material "au/gui/map/sabotage_doors.png", "smooth"
					Position: Vector 0.78125, 0.78125 + 0.04, 0
				}
			CustomData: {
				Target: "sabotageDoor2"
				Cooldown: 5
			}
		}
		{
			Handler: "o2"
			UI: if CLIENT
				{
					Icon: Material "au/gui/map/sabotage_o2.png", "smooth"
					Position: Vector 0.78125, 0.21875, 0
				}
		}
	}
}
