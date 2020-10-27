{
	PrintName: "The Skeld (Test)"
	Tasks: {
		"inspectSample"
		"fixWiring"
		"fuelEngines"
		"emptyGarbage"
		"chartCourse"
		"calibrateDistributor"
		"alignEngineOutput"
		"clearAsteroids"
		"cleanO2Filter"
		"divertPower"
		"stabilizeSteering"
		"primeShields"
		"submitScan"
		"startReactor"
		"unlockManifolds"
		"swipeCard"
		"uploadData"
	}
	Map: {
		UI: if CLIENT
			{
				BackgroundMaterial: Material "au/gui/maps/au_skeld_test/background.png", "smooth"
				OverlayMaterial: Material "au/gui/maps/au_skeld_test/overlay.png", "smooth"

				Position: Vector -1036, 150, 0
				Scale: 2.3

				Labels: {
					-- Positions are always [0..1, 0..1]
					-- and relative to 1024x1024.
					{
						Position: Vector 512/1024, 80/1024, 0
						Text: "area.cafeteria"
					}
					{
						Position: Vector 150/1024, 90/1024, 0
						Text: "area.upper_engine"
					}
					{
						Position: Vector 150/1024, 375/1024, 0
						Text: "area.lower_engine"
					}
					{
						Position: Vector 730/1024, 90/1024, 0
						Text: "area.weapons"
					}
					{
						Position: Vector 60/1024, 230/1024, 0
						Text: "area.reactor"
					}
					{
						Position: Vector 245/1024, 225/1024, 0
						Text: "area.security"
					}
					{
						Position: Vector 330/1024, 200/1024, 0
						Text: "area.medbay"
					}
					{
						Position: Vector 675/1024, 195/1024, 0
						Text: "area.o2"
					}
					{
						Position: Vector 960/1024, 260/1024, 0
						Text: "area.navigation"
					}
					{
						Position: Vector 360/1024, 310/1024, 0
						Text: "area.electrical"
					}
					{
						Position: Vector 660/1024, 260/1024, 0
						Text: "area.admin"
					}
					{
						Position: Vector 490/1024, 370/1024, 0
						Text: "area.storage"
					}
					{
						Position: Vector 730/1024, 400/1024, 0
						Text: "area.shields"
					}
					{
						Position: Vector 615/1024, 465/1024, 0
						Text: "area.communications"
					}
				}
			}
	}
}
