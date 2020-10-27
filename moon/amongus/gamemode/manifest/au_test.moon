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

				Position: Vector -1024, 1024, 0
				Scale: 1
			}
	}
}
